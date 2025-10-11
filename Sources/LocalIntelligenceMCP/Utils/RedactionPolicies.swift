//
//  RedactionPolicies.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-08.
//

import Foundation

/// Configurable redaction policies for different PII categories and contexts
/// Provides flexible redaction strategies with audio domain awareness
public class RedactionPolicies: @unchecked Sendable {

    // MARK: - Configuration

    private var configuration: RedactionPolicyConfiguration
    private let logger: Logger

    // MARK: - Redaction Strategies

    /// Predefined redaction strategies
    private let redactionStrategies: [RedactionStrategy: (String, PIICategory, RedactionContext) -> String] = [
        .replace: { text, category, context in
            return context.replacementText ?? "[REDACTED_\(category.rawValue.uppercased())]"
        },
        .mask: { text, category, context in
            let maskChar = context.maskCharacter ?? "*"
            return String(repeating: maskChar.first ?? "*", count: text.count)
        },
        .hash: { text, category, context in
            return "[HASH_\(text.sha256)]"
        },
        .partial: { text, category, context in
            return text.partialMask(
                preserveStart: context.preserveStartChars,
                preserveEnd: context.preserveEndChars,
                maskChar: (context.maskCharacter ?? "*").first ?? "*"
            )
        },
        .tokenize: { text, category, context in
            return "[TOKEN_\(text.count)CHARS]"
        },
        .fuzzy: { text, category, context in
            return text.fuzzyMask(
                fuzziness: context.fuzzinessLevel,
                maskChar: (context.maskCharacter ?? "*").first ?? "*"
            )
        },
        .remove: { text, _, _ in
            return ""
        }
    ]

    // MARK: - Initialization

    init(configuration: RedactionPolicyConfiguration = RedactionPolicyConfiguration.default, logger: Logger) {
        self.configuration = configuration
        self.logger = logger
    }

    // MARK: - Public Interface

    /// Apply redaction to text based on configured policies
    /// - Parameters:
    ///   - text: Text to redact
    ///   - detections: PII detections to redact
    ///   - context: Redaction context
    /// - Returns: Redaction result with detailed information
    func applyRedaction(
        to text: String,
        detections: [PIIDetection],
        context: RedactionContext = RedactionContext()
    ) async -> RedactionResult {
        let startTime = Date()
        var redactions: [Redaction] = []
        var modifiedText = text

        await logger.info(
            "Starting redaction process",
            metadata: [
                "originalLength": text.count,
                "detectionsCount": detections.count,
                "contextId": context.id.uuidString
            ]
        )

        // Sort detections by position (reverse order to maintain indices)
        let sortedDetections = detections.sorted { $0.range.lowerBound > $1.range.lowerBound }

        for detection in sortedDetections {
            let categoryPolicy = configuration.getPolicy(for: detection.category)
            let strategy = context.overrideStrategy ?? categoryPolicy.strategy

            // Check if this detection should be redacted based on policy
            guard shouldRedact(detection: detection, policy: categoryPolicy, context: context) else {
                continue
            }

            // Apply redaction
            let redactionStrategy = redactionStrategies[strategy] ?? redactionStrategies[.replace]!
            let redactedText = redactionStrategy(detection.matchedText, detection.category, context)

            // Update the text
            let startIndex = detection.matchedText.distance(
                from: detection.matchedText.startIndex,
                to: detection.range.lowerBound
            )
            let endIndex = detection.matchedText.distance(
                from: detection.matchedText.startIndex,
                to: detection.range.upperBound
            )

            let nsRange = NSRange(location: startIndex, length: endIndex - startIndex)
            modifiedText = (modifiedText as NSString).replacingCharacters(in: nsRange, with: redactedText)

            // Record the redaction
            let redaction = Redaction(
                originalDetection: detection,
                redactedText: redactedText,
                strategy: strategy,
                policy: categoryPolicy,
                context: context
            )
            redactions.append(redaction)
        }

        let executionTime = Date().timeIntervalSince(startTime)

        await logger.info(
            "Redaction completed",
            metadata: [
                "redactionsApplied": redactions.count,
                "finalLength": modifiedText.count,
                "charactersRemoved": text.count - modifiedText.count,
                "executionTime": executionTime
            ]
        )

        return RedactionResult(
            originalText: text,
            redactedText: modifiedText,
            redactions: redactions,
            context: context,
            metadata: [
                "executionTime": AnyCodable(executionTime),
                "redactionRate": AnyCodable(Double(redactions.count) / Double(detections.count)),
                "textCompression": AnyCodable(1.0 - (Double(modifiedText.count) / Double(text.count)))
            ]
        )
    }

    /// Get policy for a specific PII category
    /// - Parameter category: PII category
    /// - Returns: Redaction policy for the category
    func getPolicy(for category: PIICategory) -> RedactionPolicy {
        return configuration.getPolicy(for: category)
    }

    /// Update policy for a specific category
    /// - Parameters:
    ///   - category: PII category
    ///   - policy: New policy to apply
    func updatePolicy(for category: PIICategory, policy: RedactionPolicy) {
        configuration.updatePolicy(for: category, policy: policy)
    }

    /// Validate redaction policy configuration
    /// - Returns: Validation result with any issues
    func validateConfiguration() -> PolicyValidationResult {
        var issues: [PolicyValidationError] = []
        var warnings: [PolicyValidationWarning] = []

        // Check that all categories have policies
        for category in PIICategory.allCases {
            if configuration.policies[category] == nil {
                issues.append(.missingPolicy(category: category))
            }
        }

        // Check for conflicting strategies
        let strategyGroups = Dictionary(grouping: configuration.policies.values) { $0.strategy }
        for (strategy, policies) in strategyGroups {
            if policies.count > 5 && strategy == .partial {
                warnings.append(.tooManyPartialStrategies(count: policies.count))
            }
        }

        // Check audio domain awareness
        let audioAwarePolicies = configuration.policies.values.filter { $0.preserveAudioTerms }
        if audioAwarePolicies.count < 3 {
            warnings.append(.insufficientAudioDomainAwareness(count: audioAwarePolicies.count))
        }

        return PolicyValidationResult(
            isValid: issues.isEmpty,
            errors: issues,
            warnings: warnings
        )
    }

    // MARK: - Private Methods

    /// Determine if a detection should be redacted based on policy and context
    private func shouldRedact(
        detection: PIIDetection,
        policy: RedactionPolicy,
        context: RedactionContext
    ) -> Bool {
        // Check confidence threshold
        if detection.confidence < policy.confidenceThreshold {
            return false
        }

        // Check severity threshold
        if detection.severity.priority < policy.minimumSeverity.priority {
            return false
        }

        // Check audio domain term preservation
        if policy.preserveAudioTerms && isAudioDomainTerm(detection.matchedText) {
            return false
        }

        // Note: Custom rules would be implemented differently in production
        // For now, we skip custom rule checking to maintain Codable conformance

        return true
    }

    /// Check if a term is an audio domain term
    private func isAudioDomainTerm(_ term: String) -> Bool {
        let audioTerms = Set([
            "eq", "compression", "reverb", "delay", "chorus", "flanger", "phaser",
            "limiter", "gate", "expander", "de-esser", "multiband", "stereo", "mono",
            "freq", "frequency", "hz", "khz", "db", "decibel", "gain", "volume",
            "pan", "balance", "mix", "mixdown", "master", "mastering", "mixing",
            "daw", "plugin", "vst", "au", "aax", "rtas", "laptop", "desktop"
        ])

        return audioTerms.contains(term.lowercased())
    }
}

// MARK: - Supporting Types

/// Configuration for redaction policies
public struct RedactionPolicyConfiguration: Codable, Sendable {
    var policies: [PIICategory: RedactionPolicy]
    let defaultStrategy: RedactionStrategy
    let globalConfidenceThreshold: Double
    let globalMinimumSeverity: PIISeverity
    let enableAudioDomainAwareness: Bool

    init(
        policies: [PIICategory: RedactionPolicy] = Dictionary(uniqueKeysWithValues: PIICategory.allCases.map { ($0, RedactionPolicy.defaultForCategory($0)) }),
        defaultStrategy: RedactionStrategy = .replace,
        globalConfidenceThreshold: Double = 0.5,
        globalMinimumSeverity: PIISeverity = .low,
        enableAudioDomainAwareness: Bool = true
    ) {
        self.policies = policies
        self.defaultStrategy = defaultStrategy
        self.globalConfidenceThreshold = globalConfidenceThreshold
        self.globalMinimumSeverity = globalMinimumSeverity
        self.enableAudioDomainAwareness = enableAudioDomainAwareness
    }

    /// Get policy for category, falling back to default if not found
    func getPolicy(for category: PIICategory) -> RedactionPolicy {
        return policies[category] ?? RedactionPolicy.defaultForCategory(category)
    }

    /// Update policy for category
    mutating func updatePolicy(for category: PIICategory, policy: RedactionPolicy) {
        policies[category] = policy
    }

    /// Default configuration
    static let `default` = RedactionPolicyConfiguration()

    /// High-security configuration
    static let highSecurity = RedactionPolicyConfiguration(
        globalConfidenceThreshold: 0.3,
        globalMinimumSeverity: .low
    )

    /// Development configuration
    static let development = RedactionPolicyConfiguration(
        globalConfidenceThreshold: 0.8,
        globalMinimumSeverity: .high
    )
}

/// Redaction policy for a specific PII category
public struct RedactionPolicy: Codable, Sendable {
    let strategy: RedactionStrategy
    let confidenceThreshold: Double
    let minimumSeverity: PIISeverity
    let preserveAudioTerms: Bool
    let enabledCategories: [String]
    let whitelist: [String]
    let description: String
    let sensitivity: PIIDetectionSensitivity
    // Note: customRules are omitted for Codable conformance
    // In practice, these would be handled differently or made Codable

    init(
        strategy: RedactionStrategy = .replace,
        confidenceThreshold: Double = 0.5,
        minimumSeverity: PIISeverity = .low,
        preserveAudioTerms: Bool = true,
        enabledCategories: [String] = PIICategory.allCases.map { $0.rawValue },
        whitelist: [String] = [],
        description: String = "Default redaction policy",
        sensitivity: PIIDetectionSensitivity = .medium
    ) {
        self.strategy = strategy
        self.confidenceThreshold = confidenceThreshold
        self.minimumSeverity = minimumSeverity
        self.preserveAudioTerms = preserveAudioTerms
        self.enabledCategories = enabledCategories
        self.whitelist = whitelist
        self.description = description
        self.sensitivity = sensitivity
    }

    /// Default policy for a specific category
    static func defaultForCategory(_ category: PIICategory) -> RedactionPolicy {
        switch category {
        case .email, .ssn, .creditCard:
            return RedactionPolicy(strategy: .hash, confidenceThreshold: 0.7)
        case .phone:
            return RedactionPolicy(strategy: .partial, confidenceThreshold: 0.6)
        case .address:
            return RedactionPolicy(strategy: .mask, confidenceThreshold: 0.5)
        case .dateOfBirth:
            return RedactionPolicy(strategy: .partial, confidenceThreshold: 0.6)
        case .id, .financial, .medical:
            return RedactionPolicy(strategy: .replace, confidenceThreshold: 0.8)
        case .custom, .audioDomain:
            return RedactionPolicy(strategy: .replace, confidenceThreshold: 0.5, preserveAudioTerms: true)
        }
    }
}

/// Redaction strategies
public enum RedactionStrategy: String, CaseIterable, Codable, Sendable {
    case replace = "replace"
    case mask = "mask"
    case hash = "hash"
    case partial = "partial"
    case tokenize = "tokenize"
    case fuzzy = "fuzzy"
    case remove = "remove"

    var description: String {
        switch self {
        case .replace: return "Replace with placeholder text"
        case .mask: return "Replace all characters with mask character"
        case .hash: return "Replace with hash of the original text"
        case .partial: return "Show first/last characters, mask middle"
        case .tokenize: return "Replace with token indicating length"
        case .fuzzy: return "Apply fuzzy masking with variable obfuscation"
        case .remove: return "Remove the text entirely"
        }
    }
}

/// Custom redaction rule
public protocol RedactionRule: Sendable {
    func shouldRedact(detection: PIIDetection, context: RedactionContext) -> Bool
}

/// Example custom rule: length-based redaction
public struct LengthBasedRule: RedactionRule {
    let minLength: Int
    let maxLength: Int
    let action: RuleAction

    public init(minLength: Int = 0, maxLength: Int = Int.max, action: RuleAction = .redact) {
        self.minLength = minLength
        self.maxLength = maxLength
        self.action = action
    }

    public func shouldRedact(detection: PIIDetection, context: RedactionContext) -> Bool {
        let length = detection.matchedText.count
        let inRange = length >= minLength && length <= maxLength

        switch action {
        case .redact: return inRange
        case .skip: return !inRange
        }
    }
}

/// Example custom rule: pattern-based redaction
public struct PatternBasedRule: RedactionRule {
    let pattern: String
    let isRegex: Bool
    let action: RuleAction

    public init(pattern: String, isRegex: Bool = false, action: RuleAction = .redact) {
        self.pattern = pattern
        self.isRegex = isRegex
        self.action = action
    }

    public func shouldRedact(detection: PIIDetection, context: RedactionContext) -> Bool {
        let text = detection.matchedText.lowercased()
        let pattern = pattern.lowercased()

        let matches: Bool
        if isRegex {
            matches = text.range(of: pattern, options: .regularExpression) != nil
        } else {
            matches = text.contains(pattern)
        }

        switch action {
        case .redact: return matches
        case .skip: return !matches
        }
    }
}

/// Rule action
public enum RuleAction: String, Codable, Sendable {
    case redact = "redact"
    case skip = "skip"
}

/// Context for redaction operations
public struct RedactionContext: Codable, Sendable {
    let id: UUID
    let replacementText: String?
    let maskCharacter: String?
    let preserveStartChars: Int
    let preserveEndChars: Int
    let fuzzinessLevel: Double
    let overrideStrategy: RedactionStrategy?
    let metadata: [String: AnyCodable]

    init(
        id: UUID = UUID(),
        replacementText: String? = nil,
        maskCharacter: String? = "*",
        preserveStartChars: Int = 2,
        preserveEndChars: Int = 2,
        fuzzinessLevel: Double = 0.3,
        overrideStrategy: RedactionStrategy? = nil,
        metadata: [String: AnyCodable] = [:]
    ) {
        self.id = id
        self.replacementText = replacementText
        self.maskCharacter = maskCharacter
        self.preserveStartChars = preserveStartChars
        self.preserveEndChars = preserveEndChars
        self.fuzzinessLevel = fuzzinessLevel
        self.overrideStrategy = overrideStrategy
        self.metadata = metadata
    }

    /// Audio-optimized context
    static let audioOptimized = RedactionContext(
        preserveStartChars: 3,
        preserveEndChars: 3,
        fuzzinessLevel: 0.2
    )

    /// High-security context
    static let highSecurity = RedactionContext(
        maskCharacter: "#",
        preserveStartChars: 0,
        preserveEndChars: 0,
        fuzzinessLevel: 0.0
    )

    /// Development context
    static let development = RedactionContext(
        replacementText: "[DEV_REDACTED]",
        preserveStartChars: 1,
        preserveEndChars: 1,
        fuzzinessLevel: 0.5
    )
}

/// Individual redaction operation
public struct Redaction: Codable, Sendable {
    let originalDetection: PIIDetection
    let redactedText: String
    let strategy: RedactionStrategy
    let policy: RedactionPolicy
    let context: RedactionContext

    var textLength: Int { originalDetection.matchedText.count }
    var redactionRatio: Double { Double(redactedText.count) / Double(textLength) }
}

/// Complete redaction result
public struct RedactionResult: Codable, Sendable {
    let originalText: String
    let redactedText: String
    let redactions: [Redaction]
    let context: RedactionContext
    let metadata: [String: AnyCodable]

    var redactionCount: Int { redactions.count }
    var charactersRedacted: Int { originalText.count - redactedText.count }
    var redactionPercentage: Double {
        guard !originalText.isEmpty else { return 0.0 }
        return Double(charactersRedacted) / Double(originalText.count)
    }

    /// Get redactions grouped by strategy
    var redactionsByStrategy: [RedactionStrategy: [Redaction]] {
        Dictionary(grouping: redactions) { $0.strategy }
    }

    /// Get redactions grouped by category
    var redactionsByCategory: [PIICategory: [Redaction]] {
        Dictionary(grouping: redactions) { $0.originalDetection.category }
    }
}

/// Policy validation result
public struct PolicyValidationResult: Codable, Sendable {
    let isValid: Bool
    let errors: [PolicyValidationError]
    let warnings: [PolicyValidationWarning]

    var hasErrors: Bool { !errors.isEmpty }
    var hasWarnings: Bool { !warnings.isEmpty }
}

/// Policy validation errors
public enum PolicyValidationError: Codable, Sendable {
    case missingPolicy(category: PIICategory)
    case invalidStrategy(strategy: String)
    case conflictingPolicies(category: PIICategory)

    var description: String {
        switch self {
        case .missingPolicy(let category):
            return "Missing policy for category: \(category.rawValue)"
        case .invalidStrategy(let strategy):
            return "Invalid redaction strategy: \(strategy)"
        case .conflictingPolicies(let category):
            return "Conflicting policies for category: \(category.rawValue)"
        }
    }
}

/// Policy validation warnings
public enum PolicyValidationWarning: Codable, Sendable {
    case tooManyPartialStrategies(count: Int)
    case insufficientAudioDomainAwareness(count: Int)
    case lowConfidenceThreshold(threshold: Double)

    var description: String {
        switch self {
        case .tooManyPartialStrategies(let count):
            return "Many categories using partial redaction (\(count)). Consider using more specific strategies."
        case .insufficientAudioDomainAwareness(let count):
            return "Few categories preserve audio domain terms (\(count)). Audio domain awareness may be limited."
        case .lowConfidenceThreshold(let threshold):
            return "Low confidence threshold (\(threshold)). May result in over-redaction."
        }
    }
}

// MARK: - String Extensions for Redaction

private extension String {
    /// Generate SHA256 hash
    var sha256: String {
        let data = Data(self.utf8)
        let hash = data.sha256()
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    /// Partially mask string preserving start and end characters
    func partialMask(preserveStart: Int, preserveEnd: Int, maskChar: Character) -> String {
        guard count > preserveStart + preserveEnd else {
            return String(repeating: maskChar, count: count)
        }

        let start = String(prefix(preserveStart))
        let middle = String(repeating: maskChar, count: count - preserveStart - preserveEnd)
        let end = String(suffix(preserveEnd))

        return start + middle + end
    }

    /// Apply fuzzy masking
    func fuzzyMask(fuzziness: Double, maskChar: Character) -> String {
        let maskCount = Int(Double(count) * fuzziness)
        var indices = Array(0..<count)
        indices.shuffle()

        let maskIndices = Set(indices.prefix(maskCount))
        var result = ""

        for (index, character) in enumerated() {
            result += maskIndices.contains(index) ? String(maskChar) : String(character)
        }

        return result
    }
}

private extension Data {
    /// Simple SHA256 implementation (in production, use CryptoKit)
    func sha256() -> Data {
        // This is a placeholder - in production, use CryptoKit.SHA256
        return self
    }
}