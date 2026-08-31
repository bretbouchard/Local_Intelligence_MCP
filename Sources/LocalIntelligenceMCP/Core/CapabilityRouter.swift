//
//  CapabilityRouter.swift
//  LocalIntelligenceMCP
//
//  GSD Plan 1.2 — Routing independent of MCP presentation.
//  Deterministic priority rules; no hidden fallback across provider classes;
//  deadline propagation; test-injectable providers.
//

import Foundation

actor CapabilityRouter {

    // MARK: - Registration

    private struct IntelligenceEntry {
        let priority: Int
        let provider: any IntelligenceProvider
    }

    private struct AutomationEntry {
        let priority: Int
        let provider: any AutomationProvider
    }

    private var intelligenceProviders: [StableCapability: [IntelligenceEntry]] = [:]
    private var automationProviders: [AutomationEntry] = []

    /// Register an intelligence provider for capabilities. Higher priority wins.
    /// Ties break deterministically by provider type name.
    func register(_ provider: any IntelligenceProvider, for capabilities: [StableCapability], priority: Int) {
        for capability in capabilities {
            intelligenceProviders[capability, default: []].append(IntelligenceEntry(priority: priority, provider: provider))
        }
    }

    /// Register an automation provider. Higher priority wins; ties break by provider type name.
    func registerAutomation(_ provider: any AutomationProvider, priority: Int) {
        automationProviders.append(AutomationEntry(priority: priority, provider: provider))
    }

    /// Providers visible to the runtime snapshot (for `local_capabilities`).
    func registeredProviders() -> [ProviderMetadata] {
        var seen = Set<String>()
        var result: [ProviderMetadata] = []
        for entry in intelligenceProviders.values.flatMap({ $0 }) {
            if seen.insert(entry.provider.metadata.id).inserted { result.append(entry.provider.metadata) }
        }
        for entry in automationProviders {
            if seen.insert(entry.provider.metadata.id).inserted { result.append(entry.provider.metadata) }
        }
        return result.sorted { $0.id < $1.id }
    }

    // MARK: - Intelligence routing

    /// Route a generation request. Deterministic order; a pinned request is served only
    /// by the named provider; fallback only ever moves between registered providers.
    func execute(_ request: GenerationRequest) async throws -> GenerationResult {
        guard let candidates = intelligenceProviders[request.capability], !candidates.isEmpty else {
            throw CapabilityError.unsupported(reason: "No provider registered for capability '\(request.capability.rawValue)'")
        }

        var selected = Self.sorted(candidates.map { ($0.priority, $0.provider) })
        if let pinned = request.pinnedProvider {
            selected = selected.filter { $0.metadata.id == pinned }
            if selected.isEmpty {
                throw CapabilityError.unsupported(reason: "Provider '\(pinned)' is not registered for '\(request.capability.rawValue)'")
            }
        }

        var lastError: CapabilityError?
        for provider in selected {
            let status = await provider.availability(for: request.capability)
            guard status == .available else {
                lastError = Self.statusError(status, capability: request.capability, provider: provider)
                continue
            }
            do {
                return try await withDeadline(request.deadline) {
                    try await provider.generate(request)
                }
            } catch let error as CapabilityError where error.permitsFallback && request.fallbackAllowed {
                lastError = error
                continue
            }
        }

        if let error = lastError {
            throw error
        }
        throw CapabilityError.unavailable(reason: "No available provider for capability '\(request.capability.rawValue)'")
    }

    // MARK: - Automation routing

    /// Automation never falls through after a provider attempts execution: a failed
    /// attempt may be a real side effect, and silently retrying elsewhere would be unsafe.
    func listAutomation() async throws -> [String] {
        let sorted = Self.sorted(automationProviders.map { ($0.priority, $0.provider) })
        guard !sorted.isEmpty else {
            throw CapabilityError.unsupported(reason: "No automation provider registered")
        }
        var lastError: CapabilityError?
        for provider in sorted {
            let status = await provider.availability(for: .localAutomationList)
            guard status == .available else { continue }
            do {
                return try await provider.listAutomation().sorted()
            } catch let error as CapabilityError {
                lastError = error
            }
        }
        throw lastError ?? CapabilityError.unavailable(reason: "No available automation provider")
    }

    func executeAutomation(name: String, input: String?, timeout: TimeInterval) async throws -> AutomationExecution {
        let sorted = Self.sorted(automationProviders.map { ($0.priority, $0.provider) })
        guard !sorted.isEmpty else {
            throw CapabilityError.unsupported(reason: "No automation provider registered")
        }
        for provider in sorted {
            let status = await provider.availability(for: .localAutomationExecute)
            guard status == .available else { continue }
            // The provider owns its own timeout/cancellation for the side effect.
            return try await provider.executeAutomation(name: name, input: input, timeout: timeout)
        }
        throw CapabilityError.unavailable(reason: "No available automation provider")
    }

    // MARK: - Helpers

    /// Deterministic ordering: priority descending, then provider type name ascending.
    fileprivate static func sorted<T>(_ entries: [(priority: Int, provider: T)]) -> [T] {
        entries.sorted { lhs, rhs in
            if lhs.priority != rhs.priority { return lhs.priority > rhs.priority }
            return String(describing: type(of: lhs.provider)) < String(describing: type(of: rhs.provider))
        }.map { $0.provider }
    }

    private static func statusError(_ status: CapabilityStatus, capability: StableCapability, provider: any IntelligenceProvider) -> CapabilityError {
        let id = provider.metadata.id
        switch status {
        case .unsupported: return .unsupported(reason: "Provider '\(id)' does not support '\(capability.rawValue)'")
        case .unavailable: return .unavailable(reason: "Provider '\(id)' is unavailable for '\(capability.rawValue)'")
        case .disabled: return .disabled(reason: "Provider '\(id)' is disabled for '\(capability.rawValue)'")
        case .notReady: return .notReady(reason: "Provider '\(id)' is not ready for '\(capability.rawValue)'")
        case .permissionDenied: return .permissionDenied(reason: "Provider '\(id)' lacks permission for '\(capability.rawValue)'")
        case .available: return .providerFailure("Internal routing inconsistency")
        }
    }

    /// Deadline propagation: cancel the wrapped work when the deadline elapses.
    private func withDeadline<T: Sendable>(_ seconds: TimeInterval?, _ operation: @escaping @Sendable () async throws -> T) async throws -> T {
        guard let seconds else {
            return try await operation()
        }
        return try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask { try await operation() }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw CapabilityError.timeout(seconds)
            }
        guard let first = try await group.next() else {
            throw CapabilityError.providerFailure("Deadline group produced no result")
        }
            group.cancelAll()
            return first
        }
    }
}
