//
//  RuntimeCapabilities.swift
//  LocalIntelligenceMCP
//
//  GSD Plan 1.1 — Single authoritative runtime capability snapshot.
//  Privacy rule: report only state required for capability routing; no machine fingerprinting.
//

import Foundation
import ApplicationServices

#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - Feature tiers

/// Compatibility tier of the running system (Master Plan compatibility matrix).
enum APIFeatureLevel: String, Codable, Sendable {
    /// macOS 13–14: portable Tier 0/1 features only.
    case tier1
    /// macOS 15+: newer system APIs; Foundation Models still requires macOS 26.
    case tier2
}

// MARK: - Model availability

/// Distinguishable model states for the on-device system language model.
enum ModelAvailability: Equatable, Sendable {
    case available
    case downloading(progress: Double)
    case notReady
    case unavailable
}

// MARK: - Automation permission snapshot

/// Permission states relevant to automation routing.
/// `accessibility` is a genuine AX API query; `automation` reports whether an
/// Apple Events grant has been made to this process (false until proven true).
struct AutomationPermissions: Codable, Sendable {
    /// Shortcuts automation mechanism (CLI) is present on this OS.
    let shortcuts: Bool
    /// AXIsProcessTrusted() result.
    let accessibility: Bool
    /// Apple Events grant to this process; false until a grant exists.
    let automation: Bool
}

// MARK: - Runtime capabilities snapshot

/// One object that answers "what can this machine actually do now?"
struct RuntimeCapabilities: Codable, Sendable {

    let osVersionString: String
    let architecture: String
    let apiFeatureLevel: APIFeatureLevel
    /// nil only where genuinely undeterminable; false on Intel and pre-15 systems.
    let appleIntelligenceEligible: Bool?
    let modelAvailability: ModelAvailability
    let automationPermissions: AutomationPermissions
    /// Providers registered with the router, if supplied by the collector.
    let providers: [ProviderMetadata]

    private enum CodingKeys: String, CodingKey {
        case osVersion = "osVersion"
        case architecture
        case apiFeatureLevel
        case appleIntelligenceEligible
        case modelAvailability
        case automationPermissions
        case providers
    }

    // MARK: Init (collects live state)

    init(providers: [ProviderMetadata] = []) {
        let os = ProcessInfo.processInfo.operatingSystemVersion
        self.osVersionString = "\(os.majorVersion).\(os.minorVersion).\(os.patchVersion)"
        self.architecture = RuntimeCapabilities.currentArchitecture()
        self.apiFeatureLevel = os.majorVersion >= 15 ? .tier2 : .tier1
        self.appleIntelligenceEligible = RuntimeCapabilities.detectAppleIntelligenceEligibility(osVersion: os)
        self.modelAvailability = RuntimeCapabilities.detectModelAvailability(osVersion: os)
        self.automationPermissions = AutomationPermissions(
            shortcuts: ShortcutsProvider.isInstalled(),
            accessibility: AXIsProcessTrusted(),
            automation: false
        )
        self.providers = providers
    }

    // MARK: Decoded init

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        osVersionString = try container.decode(String.self, forKey: .osVersion)
        architecture = try container.decode(String.self, forKey: .architecture)
        apiFeatureLevel = try container.decode(APIFeatureLevel.self, forKey: .apiFeatureLevel)
        appleIntelligenceEligible = try container.decodeIfPresent(Bool.self, forKey: .appleIntelligenceEligible)
        modelAvailability = try RuntimeCapabilities.decodeModelAvailability(container: container)
        automationPermissions = try container.decode(AutomationPermissions.self, forKey: .automationPermissions)
        providers = try container.decodeIfPresent([ProviderMetadata].self, forKey: .providers) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(osVersionString, forKey: .osVersion)
        try container.encode(architecture, forKey: .architecture)
        try container.encode(apiFeatureLevel, forKey: .apiFeatureLevel)
        try container.encodeIfPresent(appleIntelligenceEligible, forKey: .appleIntelligenceEligible)
        try RuntimeCapabilities.encodeModelAvailability(modelAvailability, container: &container)
        try container.encode(automationPermissions, forKey: .automationPermissions)
        try container.encode(providers, forKey: .providers)
    }

    // MARK: Derived views

    var osVersion: OperatingSystemVersion {
        let parts = osVersionString.split(separator: ".").compactMap { Int($0) }
        return OperatingSystemVersion(
            majorVersion: parts.count > 0 ? parts[0] : 0,
            minorVersion: parts.count > 1 ? parts[1] : 0,
            patchVersion: parts.count > 2 ? parts[2] : 0
        )
    }

    /// Capabilities genuinely supported on this system right now.
    var supportedCapabilities: [StableCapability] {
        StableCapability.allCases.filter { status(for: $0) != .unsupported }
    }

    /// Status for one stable capability, derived from live runtime state.
    func status(for capability: StableCapability) -> CapabilityStatus {
        switch capability {
        case .localCapabilities:
            return .available
        case .localSummarize, .localExtract, .localClassify:
            // Deterministic providers: genuine on every supported OS tier.
            return .available
        case .localImageUnderstand:
            // Vision OCR is deterministic and present on every supported tier.
            return .available
        case .localAutomationList, .localAutomationExecute:
            return automationPermissions.shortcuts ? .available : .unsupported
        case .localGenerate:
            switch modelAvailability {
            case .available:
                return .available
            case .downloading:
                return .notReady
            case .notReady:
                return .notReady
            case .unavailable:
                if osVersion.majorVersion < 26 || appleIntelligenceEligible == false {
                    return .unsupported
                }
                return .disabled
            }
        }
    }

    // MARK: Detection

    private static func currentArchitecture() -> String {
        #if arch(arm64)
        return "arm64"
        #elseif arch(x86_64)
        return "x86_64"
        #else
        return "unknown"
        #endif
    }

    private static func detectAppleIntelligenceEligibility(osVersion: OperatingSystemVersion) -> Bool? {
        guard osVersion.majorVersion >= 15 else { return false }
        guard osVersion.majorVersion >= 26 else {
            // Provisional on 15–25: Apple Silicon eligibility without a queryable API.
            return currentArchitecture() == "arm64"
        }
        #if canImport(FoundationModels)
        if #available(macOS 26.0, *) {
            switch SystemLanguageModel.default.availability {
            case .available:
                return true
            case .unavailable(let reason):
                return reason != .deviceNotEligible
            @unknown default:
                return currentArchitecture() == "arm64"
            }
        }
        #endif
        return currentArchitecture() == "arm64"
    }

    private static func detectModelAvailability(osVersion: OperatingSystemVersion) -> ModelAvailability {
        guard osVersion.majorVersion >= 26 else { return .unavailable }
        #if canImport(FoundationModels)
        if #available(macOS 26.0, *) {
            switch SystemLanguageModel.default.availability {
            case .available:
                return .available
            case .unavailable(let reason):
                switch reason {
                case .modelNotReady:
                    return .notReady
                case .deviceNotEligible, .appleIntelligenceNotEnabled:
                    return .unavailable
                @unknown default:
                    return .unavailable
                }
            }
        }
        #endif
        return .unavailable
    }

    // MARK: ModelAvailability coding

    private static func encodeModelAvailability(_ value: ModelAvailability, container: inout KeyedEncodingContainer<CodingKeys>) throws {
        switch value {
        case .available:
            try container.encode("available", forKey: .modelAvailability)
        case .downloading(let progress):
            try container.encode(
                ["state": AnyCodable("downloading"), "progress": AnyCodable(progress)],
                forKey: .modelAvailability
            )
        case .notReady:
            try container.encode("notReady", forKey: .modelAvailability)
        case .unavailable:
            try container.encode("unavailable", forKey: .modelAvailability)
        }
    }

    private static func decodeModelAvailability(container: KeyedDecodingContainer<CodingKeys>) throws -> ModelAvailability {
        if let state = try? container.decode(String.self, forKey: .modelAvailability) {
            switch state {
            case "available": return .available
            case "notReady": return .notReady
            case "unavailable": return .unavailable
            default: return .unavailable
            }
        }
        if let dict = try? container.decode([String: AnyCodable].self, forKey: .modelAvailability),
           dict["state"]?.value as? String == "downloading" {
            return .downloading(progress: dict["progress"]?.value as? Double ?? 0)
        }
        return .unavailable
    }
}
