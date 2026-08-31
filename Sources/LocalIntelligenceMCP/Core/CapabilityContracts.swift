//
//  CapabilityContracts.swift
//  LocalIntelligenceMCP
//
//  GSD Plan 1.3 — Provider protocols, result envelopes, and normalized error taxonomy.
//  Capability names outlive providers: MCP clients request stable `local_*` capabilities,
//  and providers are implementations behind these contracts, not the architecture.
//

import Foundation

// MARK: - Stable capability IDs

/// Stable capability identifiers exposed through MCP tools.
/// These names are the public contract; providers come and go behind them.
enum StableCapability: String, Codable, CaseIterable, Sendable {
    case localCapabilities = "local_capabilities"
    case localGenerate = "local_generate"
    case localSummarize = "local_summarize"
    case localExtract = "local_extract"
    case localClassify = "local_classify"
    case localAutomationList = "local_automation_list"
    case localAutomationExecute = "local_automation_execute"
}

// MARK: - Capability status

/// Distinguishable runtime states per the truthfulness invariant.
/// A tool may never report `available` for a capability that would simulate a side effect.
enum CapabilityStatus: String, Codable, Sendable {
    case available
    case unavailable
    case disabled
    case notReady
    case permissionDenied
    case unsupported
}

// MARK: - Error taxonomy (GSD Plan 1.3)

/// Normalized error families so clients can reason about failure without parsing prose.
enum CapabilityError: Error, LocalizedError {
    case unsupported(reason: String)
    case unavailable(reason: String)
    case disabled(reason: String)
    case notReady(reason: String)
    case permissionDenied(reason: String)
    case invalidRequest(String)
    case timeout(TimeInterval)
    case cancelled
    case providerFailure(String)
    case policyDenied(reason: String)

    var errorDescription: String? {
        switch self {
        case .unsupported(let reason): return "Unsupported: \(reason)"
        case .unavailable(let reason): return "Unavailable: \(reason)"
        case .disabled(let reason): return "Disabled: \(reason)"
        case .notReady(let reason): return "Not ready: \(reason)"
        case .permissionDenied(let reason): return "Permission denied: \(reason)"
        case .invalidRequest(let message): return "Invalid request: \(message)"
        case .timeout(let seconds): return "Operation timed out after \(seconds)s"
        case .cancelled: return "Operation cancelled"
        case .providerFailure(let message): return "Provider failure: \(message)"
        case .policyDenied(let reason): return "Policy denied: \(reason)"
        }
    }

    /// Stable machine-readable error codes surfaced in MCP error envelopes.
    var code: String {
        switch self {
        case .unsupported: return "UNSUPPORTED"
        case .unavailable: return "UNAVAILABLE"
        case .disabled: return "DISABLED"
        case .notReady: return "NOT_READY"
        case .permissionDenied: return "PERMISSION_DENIED"
        case .invalidRequest: return "INVALID_REQUEST"
        case .timeout: return "TIMEOUT"
        case .cancelled: return "CANCELLED"
        case .providerFailure: return "PROVIDER_FAILURE"
        case .policyDenied: return "POLICY_DENIED"
        }
    }

    var localMCPError: LocalMCPError {
        var details: [String: AnyCodable] = [:]
        switch self {
        case .unsupported(let reason), .unavailable(let reason), .disabled(let reason),
             .notReady(let reason), .permissionDenied(let reason), .policyDenied(let reason):
            details["reason"] = AnyCodable(reason)
        case .timeout(let seconds):
            details["timeoutSeconds"] = AnyCodable(seconds)
        case .invalidRequest, .cancelled, .providerFailure:
            break
        }
        return LocalMCPError(code: code, message: errorDescription ?? code, details: details.isEmpty ? nil : details)
    }

    /// Errors that mean "this provider cannot serve this request" and permit routing
    /// to the next provider when fallback is allowed. All other failures terminate routing.
    var permitsFallback: Bool {
        switch self {
        case .unsupported, .unavailable, .disabled, .notReady, .providerFailure:
            return true
        case .permissionDenied, .invalidRequest, .timeout, .cancelled, .policyDenied:
            return false
        }
    }
}

// MARK: - Provider metadata

/// Provider implementation class. Routing must never silently cross from a
/// local/private class to a remote class.
enum ProviderClass: String, Codable, Sendable {
    case deterministic
    case appleAutomation
    case appleFoundationModel
}

/// Observable provider metadata reported with every result (no sensitive machine state).
struct ProviderMetadata: Codable, Equatable, Sendable {
    let id: String
    let displayName: String
    let providerClass: ProviderClass
    let modelId: String?

    init(id: String, displayName: String, providerClass: ProviderClass, modelId: String? = nil) {
        self.id = id
        self.displayName = displayName
        self.providerClass = providerClass
        self.modelId = modelId
    }
}

// MARK: - Generation contracts

/// Request envelope for intelligence capabilities.
struct GenerationRequest: Sendable {
    let capability: StableCapability
    /// Instruction for generation capabilities (required for `.localGenerate`).
    let prompt: String?
    /// Primary text the capability operates on.
    let input: String
    let maxOutputTokens: Int?
    let temperature: Double?
    /// Wall-clock deadline in seconds for this request.
    let deadline: TimeInterval?
    /// When set, only this provider ID may serve the request (no cross-provider fallback).
    let pinnedProvider: String?
    /// When false, an unavailable/pinned provider surfaces its real status instead of
    /// falling through to the next provider.
    let fallbackAllowed: Bool
    /// GSD Plan 3.3: allowlist of capability IDs the model may call during this
    /// generation. nil/empty = no model-callable tools.
    let toolAllowlist: [String]?

    init(
        capability: StableCapability,
        prompt: String? = nil,
        input: String = "",
        maxOutputTokens: Int? = nil,
        temperature: Double? = nil,
        deadline: TimeInterval? = nil,
        pinnedProvider: String? = nil,
        fallbackAllowed: Bool = true,
        toolAllowlist: [String]? = nil
    ) {
        self.capability = capability
        self.prompt = prompt
        self.input = input
        self.maxOutputTokens = maxOutputTokens
        self.temperature = temperature
        self.deadline = deadline
        self.pinnedProvider = pinnedProvider
        self.fallbackAllowed = fallbackAllowed
        self.toolAllowlist = toolAllowlist
    }
}

/// Structured generation request: a JSON Schema (draft 2020-12) the result must satisfy.
/// Output is validated again at the MCP boundary even when the provider guides generation.
struct StructuredGenerationRequest: Sendable {
    let request: GenerationRequest
    let schemaName: String
    let jsonSchema: [String: Any]

    init(request: GenerationRequest, schemaName: String, jsonSchema: [String: Any]) {
        self.request = request
        self.schemaName = schemaName
        self.jsonSchema = jsonSchema
    }
}

/// Result envelope. Always reports the provider that actually produced the output.
struct GenerationResult: Sendable {
    let text: String
    /// Present when a structured schema was requested and the output validated against it.
    let structured: [String: AnyCodable]?
    let provider: ProviderMetadata
    let duration: TimeInterval

    init(text: String, structured: [String: AnyCodable]? = nil, provider: ProviderMetadata, duration: TimeInterval) {
        self.text = text
        self.structured = structured
        self.provider = provider
        self.duration = duration
    }
}

/// Result of an automation execution. `didRun` is true only when the external side
/// effect actually occurred (no simulated success).
struct AutomationExecution: Sendable {
    let name: String
    let didRun: Bool
    let output: String?
    let errorMessage: String?
    let duration: TimeInterval
    let provider: ProviderMetadata
}

// MARK: - Provider protocols

/// Common surface for capability providers.
protocol CapabilityProvider: Sendable {
    var metadata: ProviderMetadata { get }
    /// Truthful availability of this provider for the given capability right now.
    func availability(for capability: StableCapability) async -> CapabilityStatus
}

/// Providers that perform intelligence work (generation-class capabilities).
protocol IntelligenceProvider: CapabilityProvider {
    func generate(_ request: GenerationRequest) async throws -> GenerationResult
}

/// Providers that perform real Apple automation side effects.
protocol AutomationProvider: CapabilityProvider {
    func listAutomation() async throws -> [String]
    func executeAutomation(name: String, input: String?, timeout: TimeInterval, confirm: Bool) async throws -> AutomationExecution
}

extension AutomationProvider {
    /// Convenience overload preserving the pre-confirmation call shape;
    /// confirmation defaults to false (safest).
    func executeAutomation(name: String, input: String?, timeout: TimeInterval) async throws -> AutomationExecution {
        try await executeAutomation(name: name, input: input, timeout: timeout, confirm: false)
    }
}
