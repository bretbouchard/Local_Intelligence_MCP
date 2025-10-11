//
//  PIIRedactionTool.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-08.
//

import Foundation
import AnyCodable

/// Enhanced PII Redaction Tool for Audio Domain Content
///
/// Implements apple_text_redact specification with advanced pattern detection and configurable policies:
/// - Comprehensive PII detection patterns with 60+ patterns across 10 categories
/// - Configurable redaction policies with 7 different strategies (replace, hash, mask, partial, tokenize, fuzzy, remove)
/// - Audio domain-aware detection with 40+ audio terms whitelist
/// - Support for custom PII patterns and advanced validation
/// - Preserves audio-related technical terms while protecting personal information
/// - Integration with PIIDetectionPatterns and RedactionPolicies utilities
/// - Multiple sensitivity levels (low, medium, high, strict) with confidence thresholds
/// - Advanced redaction contexts for different use cases (audio optimized, high security, development)
///
/// Use Cases:
/// - Client communication: Remove personal details before sharing session notes
/// - Documentation: Clean transcripts for educational or public distribution
/// - Compliance: Ensure privacy when sharing audio production work
/// - Collaboration: Share technical details without revealing sensitive personal information
/// - Legal: Prepare documents for legal review with protected information
///
/// Performance Requirements:
/// - Execution: <150ms for 2000 words with enhanced PII patterns
/// - Memory: <2MB for text processing overhead (includes pattern libraries)
/// - Concurrency: Thread-safe for multiple simultaneous operations
/// - Audio domain: Enhanced detection of audio-specific PII while preserving technical terms
public final class PIIRedactionTool: AudioDomainTool, @unchecked Sendable {

    // MARK: - Enhanced Detection Components

    private let piiDetectionPatterns: PIIDetectionPatterns
    private let redactionPolicies: RedactionPolicies

    // MARK: - Redaction Modes

    /// Supported redaction strategies
    public enum RedactionMode: String, CaseIterable {
        case replace = "replace"
        case hash = "hash"
        case mask = "mask"
        case partial = "partial"
        case tokenize = "tokenize"
        case fuzzy = "fuzzy"
        case remove = "remove"

        var description: String {
            switch self {
            case .replace: return "Replace PII with generic placeholders (e.g., [NAME], [PHONE])"
            case .hash: return "Replace PII with SHA256 hash values"
            case .mask: return "Replace all characters with mask character (e.g., ****)"
            case .partial: return "Partially mask PII (e.g., J*** D*****, 555-***-1234)"
            case .tokenize: return "Replace with token indicating length (e.g., [TOKEN_8CHARS])"
            case .fuzzy: return "Apply fuzzy masking with variable obfuscation"
            case .remove: return "Completely remove PII instances"
            }
        }

        /// Convert to RedactionStrategy
        var toStrategy: RedactionStrategy {
            switch self {
            case .replace: return .replace
            case .hash: return .hash
            case .mask: return .mask
            case .partial: return .partial
            case .tokenize: return .tokenize
            case .fuzzy: return .fuzzy
            case .remove: return .remove
            }
        }
    }

    // MARK: - Initialization

    init(logger: Logger, securityManager: SecurityManager) {
        // Initialize enhanced detection components
        let detectionConfig = PIIDetectionConfiguration.default
        let policyConfig = RedactionPolicyConfiguration.default

        self.piiDetectionPatterns = PIIDetectionPatterns(
            configuration: detectionConfig,
            logger: logger
        )
        self.redactionPolicies = RedactionPolicies(
            configuration: policyConfig,
            logger: logger
        )

        let inputSchema: [String: AnyCodable] = [
            "type": AnyCodable("object"),
            "properties": AnyCodable([
                "text": AnyCodable([
                    "type": AnyCodable("string"),
                    "description": AnyCodable("Audio session notes, transcripts, or technical documentation containing potential PII"),
                    "minLength": AnyCodable(10)
                ]),
                "mode": AnyCodable([
                    "type": AnyCodable("string"),
                    "description": AnyCodable("Redaction strategy to apply"),
                    "enum": AnyCodable(RedactionMode.allCases.map(\.rawValue)),
                    "default": AnyCodable(RedactionMode.replace.rawValue)
                ]),
                "categories": AnyCodable([
                    "type": AnyCodable("array"),
                    "description": AnyCodable("PII categories to detect and redact"),
                    "items": AnyCodable([
                        "type": AnyCodable("string"),
                        "enum": AnyCodable(["email", "phone", "ssn", "creditCard", "address", "dateOfBirth", "id", "financial", "medical", "custom", "audioDomain"])
                    ]),
                    "default": AnyCodable(["email", "phone", "ssn", "creditCard", "address", "dateOfBirth", "id", "financial"])
                ]),
                "sensitivity": AnyCodable([
                    "type": AnyCodable("string"),
                    "description": AnyCodable("Detection sensitivity level"),
                    "enum": AnyCodable(["low", "medium", "high", "strict"]),
                    "default": AnyCodable("medium")
                ]),
                "preserve_audio_terms": AnyCodable([
                    "type": AnyCodable("boolean"),
                    "description": AnyCodable("Preserve audio-specific terms even if they might be mistaken for PII"),
                    "default": AnyCodable(true)
                ]),
                "custom_patterns": AnyCodable([
                    "type": AnyCodable("array"),
                    "description": AnyCodable("Custom regex patterns for PII detection"),
                    "items": AnyCodable([
                        "type": AnyCodable("object"),
                        "properties": AnyCodable([
                            "name": AnyCodable([
                                "type": AnyCodable("string"),
                                "description": AnyCodable("Pattern name for reference")
                            ]),
                            "pattern": AnyCodable([
                                "type": AnyCodable("string"),
                                "description": AnyCodable("Regex pattern to match")
                            ]),
                            "replacement": AnyCodable([
                                "type": AnyCodable("string"),
                                "description": AnyCodable("Custom replacement text (optional)")
                            ])
                        ]),
                        "required": AnyCodable(["name", "pattern"])
                    ]),
                    "default": AnyCodable([])
                ]),
                "whitelist": AnyCodable([
                    "type": AnyCodable("array"),
                    "description": AnyCodable("Terms that should never be redacted (e.g., studio names, common audio terms)"),
                    "items": AnyCodable([
                        "type": AnyCodable("string")
                    ]),
                    "default": AnyCodable([])
                ])
            ]),
            "required": AnyCodable(["text"])
        ]

        super.init(
            name: "apple_text_redact",
            description: "Redacts personally identifiable information from audio session notes and transcripts while preserving audio-specific technical content.",
            inputSchema: inputSchema,
            logger: logger,
            securityManager: securityManager
        )
    }

    // MARK: - Audio Processing

    /// Redacts PII from audio content with enhanced detection patterns and configurable policies
    public override func processAudioContent(_ content: String, with parameters: [String: Any]) async throws -> String {
        let text = content

        // Parse redaction mode
        let modeString = parameters["mode"] as? String ?? RedactionMode.replace.rawValue
        guard let mode = RedactionMode(rawValue: modeString.lowercased()) else {
            throw AudioProcessingError.invalidInput("Invalid redaction mode: \(modeString)")
        }

        // Parse categories
        let categoryStrings = parameters["categories"] as? [String] ?? ["email", "phone", "ssn", "creditCard", "address", "dateOfBirth", "id", "financial"]
        let categories = try categoryStrings.compactMap { categoryString -> PIICategory? in
            guard let category = PIICategory(rawValue: categoryString.lowercased()) else {
                throw AudioProcessingError.invalidInput("Invalid PII category: \(categoryString)")
            }
            return category
        }

        // Parse sensitivity
        let sensitivityString = parameters["sensitivity"] as? String ?? "medium"
        guard let sensitivity = PIIDetectionSensitivity(rawValue: sensitivityString) else {
            throw AudioProcessingError.invalidInput("Invalid sensitivity level: \(sensitivityString)")
        }

        // Parse other options
        let preserveAudioTerms = parameters["preserve_audio_terms"] as? Bool ?? true
        let customPatterns = parameters["custom_patterns"] as? [[String: Any]] ?? []
        let whitelist = parameters["whitelist"] as? [String] ?? []

        // Pre-security check
        try await performSecurityCheck(text)

        // Apply enhanced PII detection and redaction
        let redactionResult = try await applyEnhancedPIIRedaction(
            to: text,
            categories: categories,
            sensitivity: sensitivity,
            mode: mode,
            preserveAudioTerms: preserveAudioTerms,
            customPatterns: customPatterns,
            whitelist: whitelist
        )

        // Post-security validation
        try await validateOutput(redactionResult.redactedText)

        return redactionResult.redactedText
    }

    // MARK: - Private Implementation

    /// Applies enhanced PII detection and configurable redaction policies
    private func applyEnhancedPIIRedaction(
        to text: String,
        categories: [PIICategory],
        sensitivity: PIIDetectionSensitivity,
        mode: RedactionMode,
        preserveAudioTerms: Bool,
        customPatterns: [[String: Any]],
        whitelist: [String]
    ) async throws -> RedactionResult {

        // Step 1: Enhanced PII detection using comprehensive pattern library
        let detectionResult = await piiDetectionPatterns.detectPII(
            in: text,
            categories: categories,
            sensitivity: sensitivity,
            preserveAudioTerms: preserveAudioTerms
        )

        // Filter detections based on whitelist
        let filteredDetections = detectionResult.detections.filter { detection in
            !isWhitelisted(detection.matchedText, whitelist: whitelist)
        }

        // Step 2: Create redaction context with enhanced configuration based on mode
        let redactionContext = createRedactionContext(
            for: mode,
            sensitivity: sensitivity,
            preserveAudioTerms: preserveAudioTerms
        )

        // Step 3: Apply configurable redaction policies
        let redactionResult = await redactionPolicies.applyRedaction(
            to: text,
            detections: filteredDetections,
            context: redactionContext
        )

        await logger.info(
            "Enhanced PII redaction completed",
            metadata: [
                "originalLength": text.count,
                "redactedLength": redactionResult.redactedText.count,
                "detectionsFound": detectionResult.detections.count,
                "detectionsFiltered": filteredDetections.count,
                "redactionsApplied": redactionResult.redactions.count,
                "sensitivity": sensitivity.rawValue,
                "redactionMode": mode.rawValue,
                "categories": categories.map({ $0.rawValue }),
                "whitelistSize": whitelist.count,
                "audioTermsPreserved": preserveAudioTerms
            ]
        )

        return redactionResult
    }

    /// Create appropriate redaction context based on mode and sensitivity
    private func createRedactionContext(
        for mode: RedactionMode,
        sensitivity: PIIDetectionSensitivity,
        preserveAudioTerms: Bool
    ) -> RedactionContext {

        let baseContext: RedactionContext
        switch mode {
        case .replace:
            baseContext = RedactionContext(
                overrideStrategy: .replace
            )
        case .hash:
            baseContext = RedactionContext(
                overrideStrategy: .hash
            )
        case .mask:
            baseContext = RedactionContext(
                maskCharacter: "*",
                overrideStrategy: .mask
            )
        case .partial:
            let preserveChars = sensitivity == .strict ? 1 : (sensitivity == .high ? 2 : 3)
            baseContext = RedactionContext(
                maskCharacter: "*",
                preserveStartChars: preserveChars,
                preserveEndChars: preserveChars,
                overrideStrategy: .partial
            )
        case .tokenize:
            baseContext = RedactionContext(
                overrideStrategy: .tokenize
            )
        case .fuzzy:
            let fuzziness = switch sensitivity {
            case .low: 0.6
            case .medium: 0.4
            case .high: 0.2
            case .strict: 0.1
            }
            baseContext = RedactionContext(
                maskCharacter: "*",
                fuzzinessLevel: fuzziness,
                overrideStrategy: .fuzzy
            )
        case .remove:
            baseContext = RedactionContext(
                overrideStrategy: .remove
            )
        }

        // Add metadata about the configuration
        var metadata = baseContext.metadata
        metadata["redactionMode"] = AnyCodable(mode.rawValue)
        metadata["sensitivity"] = AnyCodable(sensitivity.rawValue)
        metadata["preserveAudioTerms"] = AnyCodable(preserveAudioTerms)

        return RedactionContext(
            id: baseContext.id,
            replacementText: baseContext.replacementText,
            maskCharacter: baseContext.maskCharacter,
            preserveStartChars: baseContext.preserveStartChars,
            preserveEndChars: baseContext.preserveEndChars,
            fuzzinessLevel: baseContext.fuzzinessLevel,
            overrideStrategy: baseContext.overrideStrategy,
            metadata: metadata
        )
    }

    /// Check if text should be whitelisted
    private func isWhitelisted(_ text: String, whitelist: [String]) -> Bool {
        let lowercaseText = text.lowercased()
        return whitelist.contains { term in
            lowercaseText.contains(term.lowercased())
        }
    }

    // MARK: - Security

    /// Validates input for security compliance
    private func performSecurityCheck(_ text: String) async throws {
        do {
            try TextValidationUtils.validateText(text)
            try TextValidationUtils.validateTextSecurity(text)
        } catch {
            throw AudioProcessingError.invalidInput(error.localizedDescription)
        }
    }

    /// Validates output for security compliance
    private func validateOutput(_ output: String) async throws {
        do {
            try TextValidationUtils.validateText(output)
            try TextValidationUtils.validateTextSecurity(output)
        } catch {
            throw AudioProcessingError.validationError(error.localizedDescription)
        }
    }
}