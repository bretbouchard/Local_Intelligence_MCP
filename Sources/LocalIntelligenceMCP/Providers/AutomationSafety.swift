//
//  AutomationSafety.swift
//  LocalIntelligenceMCP
//
//  GSD Plan 2.4 — Automation safety: allow/deny policy by shortcut name,
//  destructive-action classification with explicit confirmation, timeout
//  clamping, and auditable policy decisions. Wraps any AutomationProvider;
//  the inner provider is never reached for denied requests.
//

import Foundation

/// Policy governing which automation actions may execute.
struct AutomationSafetyPolicy: Sendable {
    /// When set, ONLY these shortcut names may execute (case-insensitive).
    let allowlist: Set<String>?
    /// Shortcut names that may never execute (case-insensitive).
    let denylist: Set<String>
    /// Name fragments classifying a shortcut as potentially destructive;
    /// execution then requires explicit confirmation.
    let destructivePatterns: [String]
    let requireConfirmationForDestructive: Bool
    /// Upper bound clamped onto every requested timeout.
    let maxTimeout: TimeInterval

    static let destructiveDefaults: [String] = [
        "delete", "remove", "erase", "format", "shutdown", "restart", "sleep",
        "send", "post", "share", "tweet", "pay", "purchase", "buy", "purge",
        "clean", "drop", "kill", "uninstall", "empty trash",
    ]

    static let `default` = AutomationSafetyPolicy(
        allowlist: nil,
        denylist: [],
        destructivePatterns: destructiveDefaults,
        requireConfirmationForDestructive: true,
        maxTimeout: 300
    )

    /// Policy from environment (local-first config, no external services):
    ///   LI_AUTOMATION_ALLOWLIST  comma-separated names (empty = allow all)
    ///   LI_AUTOMATION_DENYLIST   comma-separated names
    static func fromEnvironment() -> AutomationSafetyPolicy {
        let env = ProcessInfo.processInfo.environment
        func names(_ key: String) -> Set<String> {
            Set((env[key] ?? "").split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces).lowercased() }.filter { !$0.isEmpty })
        }
        let allow = names("LI_AUTOMATION_ALLOWLIST")
        let deny = names("LI_AUTOMATION_DENYLIST")
        return AutomationSafetyPolicy(
            allowlist: allow.isEmpty ? nil : allow,
            denylist: deny,
            destructivePatterns: destructiveDefaults,
            requireConfirmationForDestructive: true,
            maxTimeout: 300
        )
    }
}

/// Decorator enforcing an AutomationSafetyPolicy around a real provider.
final class SafetyGatedAutomationProvider: AutomationProvider, @unchecked Sendable {

    let inner: any AutomationProvider
    let policy: AutomationSafetyPolicy
    let logger: Logger

    var metadata: ProviderMetadata { inner.metadata }

    init(inner: any AutomationProvider, policy: AutomationSafetyPolicy, logger: Logger) {
        self.inner = inner
        self.policy = policy
        self.logger = logger
    }

    func availability(for capability: StableCapability) async -> CapabilityStatus {
        await inner.availability(for: capability)
    }

    func listAutomation() async throws -> [String] {
        // Listing is read-only; no gate beyond the inner provider.
        try await inner.listAutomation()
    }

    func executeAutomation(name: String, input: String?, timeout: TimeInterval, confirm: Bool) async throws -> AutomationExecution {
        let lowercasedName = name.lowercased()

        func deny(_ reason: String) async throws -> Never {
            await logger.warning("Automation policy DENIED '\(name)': \(reason)", category: .security, metadata: ["shortcut": name])
            throw CapabilityError.policyDenied(reason: reason)
        }

        if let allowlist = policy.allowlist, !allowlist.contains(lowercasedName) {
            try await deny("'\(name)' is not on the automation allowlist")
        }
        if policy.denylist.contains(lowercasedName) {
            try await deny("'\(name)' is on the automation denylist")
        }

        let effectiveTimeout = min(timeout, policy.maxTimeout)

        let destructive = policy.destructivePatterns.contains { lowercasedName.contains($0) }
        if destructive && policy.requireConfirmationForDestructive && !confirm {
            try await deny("'\(name)' looks destructive (requires explicit confirm=true)")
        }

        await logger.info(
            "Automation policy ALLOWED '\(name)' (confirm=\(confirm), destructive=\(destructive), timeout=\(effectiveTimeout)s)",
            category: .security,
            metadata: [
                "shortcut": name,
                "destructive": AnyCodable(destructive),
                "confirmed": AnyCodable(confirm),
            ]
        )

        return try await inner.executeAutomation(name: name, input: input, timeout: effectiveTimeout, confirm: confirm)
    }
}
