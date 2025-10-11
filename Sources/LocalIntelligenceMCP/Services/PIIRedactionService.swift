//
//  PIIRedactionService.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-09.
//

import Foundation

/// Centralized PII detection and redaction service
/// Consolidates all PII-related functionality across the codebase
public actor PIIRedactionService {

    // MARK: - Properties

    private let patternCache: PatternCache
    private let streamingProcessor: StreamingTextProcessor
    private let memoryMonitor: MemoryMonitor
    private let logger: Logger

    // MARK: - Initialization

    public init(logger: Logger) {
        self.patternCache = PatternCache.shared
        self.streamingProcessor = StreamingTextProcessor()
        self.memoryMonitor = MemoryMonitor()
        self.logger = logger
    }

    // MARK: - Main Redaction Methods

    /// Redact PII from text using specified policy
    /// - Parameters:
    ///   - text: Text to process
    ///   - policy: Redaction policy to apply
    ///   - preserveAudioTerms: Whether to preserve audio-specific terms
    ///   - context: Execution context for logging
    /// - Returns: RedactionResult with detailed information
    public func redactPII(
        from text: String,
        policy: RedactionPolicy,
        preserveAudioTerms: Bool = true,
        context: MCPExecutionContext
    ) async -> RedactionResult {

        let startTime = Date()

        // Check memory usage before processing
        let memoryCheck = await memoryMonitor.quickMemoryCheck()
        if memoryCheck.needsOptimization {
            await logger.info(
                "Memory optimization needed before PII processing",
                category: .performance,
                metadata: ["memoryUsage": memoryCheck.snapshot.usedMemory]
            )
        }

        // Detect all PII instances using streaming for large texts
        let detectionResult = await detectPII(
            in: text,
            policy: policy,
            preserveAudioTerms: preserveAudioTerms,
            useStreaming: text.utf8.count > 8192 // Use streaming for texts > 8KB
        )

        // Apply redaction based on policy using streaming replacement for large texts
        let redactedText = await applyRedaction(
            to: text,
            detections: detectionResult.detections,
            policy: policy,
            useStreaming: text.utf8.count > 8192
        )

        let duration = Date().timeIntervalSince(startTime)

        // Log PII operation
        // Log performance metrics
        await logger.info(
            "PII redaction performance",
            category: .performance,
            metadata: [
                "operation": "redact_pii",
                "detections": detectionResult.detections.count,
                "categories": detectionResult.categories.map { $0.rawValue }.joined(separator: ", ")
            ]
        )

        await logger.debug(
            "PII redaction completed",
            category: .security,
            metadata: [
                "originalLength": text.count,
                "redactedLength": redactedText.count,
                "detections": detectionResult.detections.count,
                "duration": duration,
                "preserveAudioTerms": preserveAudioTerms
            ]
        )

        let redactions = detectionResult.detections.map { detection in
            Redaction(
                originalDetection: detection,
                redactedText: detection.category.replacementText,
                strategy: policy.strategy,
                policy: policy,
                context: RedactionContext.audioOptimized
            )
        }
        
        return RedactionResult(
            originalText: text,
            redactedText: redactedText,
            redactions: redactions,
            context: RedactionContext.audioOptimized,
            metadata: [
                "detections": AnyCodable(detectionResult.detections.count),
                "categories": AnyCodable(detectionResult.categories.map { $0.rawValue }),
                "processedAt": AnyCodable(Date().timeIntervalSince1970)
            ]
        )
    }

    /// Detect PII in text without redaction
    /// - Parameters:
    ///   - text: Text to analyze
    ///   - policy: Detection policy to use
    ///   - preserveAudioTerms: Whether to preserve audio-specific terms
    ///   - useStreaming: Whether to use streaming processing for large texts
    /// - Returns: PIIDetectionResult with detailed information
    public func detectPII(
        in text: String,
        policy: RedactionPolicy,
        preserveAudioTerms: Bool = true,
        useStreaming: Bool = false
    ) async -> PIIDetectionResult {

        var detections: [PIIDetection] = []
        var categories: Set<String> = []

        // Get patterns for all enabled categories
        let allPatterns = policy.enabledCategories.compactMap { category in
            PIICategory(rawValue: category).map { category in
                (category: category, patterns: getPatterns(for: category))
            }
        }

        let patternStrings = allPatterns.flatMap { $0.patterns.map { $0.regex } }

        do {
            if useStreaming {
                // Use streaming processor for large texts
                let streamResult = try await streamingProcessor.processLargeText(
                    text,
                    patterns: patternStrings,
                    context: MCPExecutionContext(
                        clientId: UUID(),
                        requestId: "pii_detection",
                        toolName: "PIIRedactionService"
                    )
                )

                // Convert streaming matches to PIIDetection objects
                for match in streamResult.matches {
                    if let category = findCategoryForPattern(match.pattern, in: allPatterns) {
                        let pattern = findPattern(match.pattern, in: allPatterns)
                        let confidence = calculateConfidence(
                            for: pattern,
                            match: match.matchedText,
                            sensitivity: policy.sensitivity
                        )

                        if confidence >= policy.sensitivity.threshold {
                            // Skip if preserving audio terms and this is an audio term
                            if preserveAudioTerms && isAudioTerm(match.matchedText) {
                                continue
                            }

                            // Need to convert NSRange to String.Index range
                            guard let stringRange = Range(match.range, in: text) else { continue }
                            detections.append(PIIDetection(
                                category: category,
                                matchedText: match.matchedText,
                                range: stringRange,
                                pattern: pattern.regex,
                                confidence: confidence,
                                severity: .medium
                            ))
                            categories.insert(category.rawValue)
                        }
                    }
                }
            } else {
                // Use traditional processing for smaller texts
                for (category, patterns) in allPatterns {
                    let categoryDetections = await detectPIICategory(
                        in: text,
                        category: category,
                        patterns: patterns,
                        sensitivity: policy.sensitivity,
                        preserveAudioTerms: preserveAudioTerms
                    )

                    detections.append(contentsOf: categoryDetections)
                    if !categoryDetections.isEmpty {
                        categories.insert(category.rawValue)
                    }
                }
            }
        } catch {
            await logger.error(
                "PII detection failed",
                error: error,
                metadata: [
                    "textLength": text.count,
                    "useStreaming": useStreaming,
                    "policy": policy.description
                ]
            )
            // Fall back to traditional processing
            return await detectPII(
                in: text,
                policy: policy,
                preserveAudioTerms: preserveAudioTerms,
                useStreaming: false
            )
        }

        // Filter detections based on whitelist
        let filteredDetections = detections.filter { detection in
            !isWhitelisted(detection.matchedText, categories: policy.whitelist)
        }

        return PIIDetectionResult(
            originalText: text,
            detections: filteredDetections,
            categories: Set(filteredDetections.map { $0.category }),
            sensitivity: policy.sensitivity,
            preserveAudioTerms: preserveAudioTerms,
            metadata: [
                "processingTime": AnyCodable(Date().timeIntervalSinceNow),
                "patternCount": AnyCodable(allPatterns.count),
                "textLength": AnyCodable(text.count)
            ]
        )
    }

    /// Apply redaction to text based on detections
    /// - Parameters:
    ///   - text: Original text
    ///   - detections: PII detections to redact
    ///   - policy: Redaction policy to use
    ///   - useStreaming: Whether to use streaming replacement for large texts
    /// - Returns: Redacted text
    private func applyRedaction(
        to text: String,
        detections: [PIIDetection],
        policy: RedactionPolicy,
        useStreaming: Bool = false
    ) async -> String {

        guard !detections.isEmpty else { return text }

        if useStreaming {
            // Create replacement dictionary for streaming processor
            var replacements: [String: String] = [:]
            for detection in detections {
                let redactionText = generateRedactionText(
                    for: detection,
                    strategy: policy.strategy,
                    preserveAudioTerms: policy.preserveAudioTerms
                )

                // Use the actual matched text as key for replacement
                replacements[detection.matchedText] = redactionText
            }

            do {
                let result = try await streamingProcessor.streamReplace(
                    text,
                    replacements: replacements,
                    context: MCPExecutionContext(
                        clientId: UUID(),
                        requestId: "pii_redaction",
                        toolName: "PIIRedactionService"
                    )
                )
                return result.processedText
            } catch {
                await logger.error(
                    "Streaming redaction failed, falling back to traditional method",
                    error: error,
                    metadata: [
                        "textLength": text.count,
                        "detectionsCount": detections.count
                    ]
                )
                // Fall back to traditional method
            }
        }

        // Traditional redaction method
        var redactedText = text

        // Sort detections by position (reverse order to maintain indices)
        let sortedDetections = detections.sorted(by: { $0.range.lowerBound > $1.range.lowerBound })

        for detection in sortedDetections {
            let redactionText = generateRedactionText(
                for: detection,
                strategy: policy.strategy,
                preserveAudioTerms: policy.preserveAudioTerms
            )

            // Validate range bounds
            let startOffset = text.distance(from: text.startIndex, to: detection.range.lowerBound)
            let rangeLength = text.distance(from: detection.range.lowerBound, to: detection.range.upperBound)
            let endOffset = startOffset + rangeLength

            guard startOffset >= 0,
                  endOffset <= redactedText.utf8.count,
                  startOffset < redactedText.utf8.count else {
                await logger.warning(
                    "Invalid detection range, skipping redaction",
                    metadata: [
                        "range": "\(detection.range)",
                        "textLength": redactedText.utf8.count
                    ]
                )
                continue
            }

            let startIndex = redactedText.index(
                redactedText.startIndex,
                offsetBy: startOffset
            )
            let endIndex = redactedText.index(
                startIndex,
                offsetBy: rangeLength
            )

            redactedText.replaceSubrange(startIndex..<endIndex, with: redactionText)
        }

        return redactedText
    }

    // MARK: - Category-Specific Detection

    /// Detect PII for a specific category
    private func detectPIICategory(
        in text: String,
        category: PIICategory,
        patterns: [PIIPattern],
        sensitivity: PIIDetectionSensitivity,
        preserveAudioTerms: Bool
    ) async -> [PIIDetection] {

        var detections: [PIIDetection] = []

        for pattern in patterns {
            do {
                let nsRegularExpression = try await patternCache.getPattern(pattern.regex, options: pattern.options)

                let matches = nsRegularExpression.matches(
                    in: text,
                    range: NSRange(text.startIndex..<text.endIndex, in: text)
                )

                for match in matches {
                    let range = match.range
                    guard let stringRange = Range(range, in: text) else { continue }
                    let matchedText = String(text[stringRange])

                    // Skip if preserving audio terms and this is an audio term
                    if preserveAudioTerms && isAudioTerm(matchedText) {
                        continue
                    }

                    // Check confidence based on pattern and sensitivity
                    let confidence = calculateConfidence(
                        for: pattern,
                        match: matchedText,
                        sensitivity: sensitivity
                    )

                    if confidence >= sensitivity.threshold {
                        detections.append(PIIDetection(
                            category: category,
                            matchedText: matchedText,
                            range: stringRange,
                            pattern: pattern.regex,
                            confidence: confidence,
                            severity: .medium
                        ))
                    }
                }
            } catch {
                await logger.warning(
                    "Pattern compilation failed for category \(category.rawValue): \(error.localizedDescription)",
                    category: .security,
                    metadata: ["pattern": pattern.regex]
                )
                continue
            }
        }

        return detections
    }

    // MARK: - Redaction Text Generation

    /// Generate redaction text based on strategy
    private func generateRedactionText(
        for detection: PIIDetection,
        strategy: RedactionStrategy,
        preserveAudioTerms: Bool
    ) -> String {

        switch strategy {
        case .replace:
            return generateReplacementText(for: detection)

        case .hash:
            return generateHashText(for: detection)

        case .mask:
            return generateMaskText(for: detection)

        case .partial:
            return generatePartialText(for: detection)

        case .tokenize:
            return generateTokenText(for: detection)

        case .fuzzy:
            return generateFuzzyText(for: detection)

        case .remove:
            return "" // Remove completely
        }
    }

    /// Generate replacement text
    private func generateReplacementText(for detection: PIIDetection) -> String {
        return detection.category.replacementText
    }

    /// Generate hash text
    private func generateHashText(for detection: PIIDetection) -> String {
        let data = detection.matchedText.data(using: .utf8) ?? Data()
        let hash = data.simpleHash
        return String(hash.prefix(8)) // Short hash for readability
    }

    /// Generate mask text
    private func generateMaskText(for detection: PIIDetection) -> String {
        return String(repeating: "*", count: detection.matchedText.count)
    }

    /// Generate partial text (show first and last characters)
    private func generatePartialText(for detection: PIIDetection) -> String {
        let text = detection.matchedText
        let preserveChars = 3

        if text.count <= preserveChars * 2 {
            return String(repeating: "*", count: text.count)
        }

        let prefix = String(text.prefix(preserveChars))
        let suffix = String(text.suffix(preserveChars))
        let maskLength = text.count - (prefix.count + suffix.count)

        return prefix + String(repeating: "*", count: maskLength) + suffix
    }

    /// Generate token text
    private func generateTokenText(for detection: PIIDetection) -> String {
        return "[TOKEN_\(detection.matchedText.count)CHARS]"
    }

    /// Generate fuzzy text with variable obfuscation
    private func generateFuzzyText(for detection: PIIDetection) -> String {
        let text = detection.matchedText
        var result = ""

        for (index, character) in text.enumerated() {
            if index % 2 == 0 {
                result += String(character)
            } else {
                result += "*"
            }
        }

        return result
    }

    // MARK: - Helper Methods

    /// Check if text is whitelisted
    private func isWhitelisted(_ text: String, categories: [String]) -> Bool {
        let lowercaseText = text.lowercased()
        return categories.contains { category in
            lowercaseText.contains(category.lowercased())
        }
    }

    /// Check if text is an audio term
    private func isAudioTerm(_ text: String) -> Bool {
        let audioTerms = [
            "mix", "master", "track", "audio", "sound", "music", "recording",
            "studio", "production", "engineer", "producer", "session",
            "DAW", "plugin", "EQ", "compressor", "reverb", "delay",
            "frequency", "amplitude", "waveform", "bitrate", "sample rate",
            "microphone", "preamp", "interface", "monitor", "speaker",
            "compression", "format", "bit depth", "channel", "sample",
            "gain", "volume", "pan", "automation", "MIDI", "tempo"
        ]

        let lowercaseText = text.lowercased()
        return audioTerms.contains { lowercaseText.contains($0) }
    }

    /// Get patterns for a specific category
    private func getPatterns(for category: PIICategory) -> [PIIPattern] {
        // Basic patterns - simplified for now
        switch category {
        case .email:
            return [PIIPattern(regex: "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}", category: .email, description: "Email pattern")]
        case .phone:
            return [PIIPattern(regex: "\\b\\d{3}-\\d{3}-\\d{4}\\b", category: .phone, description: "Phone pattern")]
        default:
            return []
        }
    }

    /// Find category for a pattern string
    private func findCategoryForPattern(_ pattern: String, in allPatterns: [(PIICategory, [PIIPattern])]) -> PIICategory? {
        for (category, patterns) in allPatterns {
            if patterns.contains(where: { $0.regex == pattern }) {
                return category
            }
        }
        return nil
    }

    /// Find pattern object for pattern string
    private func findPattern(_ pattern: String, in allPatterns: [(PIICategory, [PIIPattern])]) -> PIIPattern {
        for (_, patterns) in allPatterns {
            if let found = patterns.first(where: { $0.regex == pattern }) {
                return found
            }
        }
        // Return a default pattern if not found
        return PIIPattern(
            regex: pattern,
            category: .custom,
            description: "Unknown pattern"
        )
    }

    /// Calculate confidence score for detection
    private func calculateConfidence(
        for pattern: PIIPattern,
        match: String,
        sensitivity: PIIDetectionSensitivity
    ) -> Double {

        var confidence = pattern.baseConfidence

        // Adjust based on pattern specificity
        if pattern.regex.count > 20 {
            confidence += 0.2
        }

        // Adjust based on match length
        if match.count >= 8 {
            confidence += 0.1
        }

        // Adjust based on sensitivity
        switch sensitivity {
        case .low:
            confidence *= 0.6
        case .medium:
            confidence *= 0.8
        case .high:
            confidence *= 0.9
        case .strict:
            confidence *= 1.0
        }

        return min(confidence, 1.0)
    }
}

// MARK: - Supporting Types


/// PII pattern configuration
public struct PIIPattern {
    public let regex: String
    public let options: NSRegularExpression.Options
    public let category: PIICategory
    public let baseConfidence: Double
    public let description: String

    public init(
        regex: String,
        options: NSRegularExpression.Options = [.caseInsensitive],
        category: PIICategory,
        baseConfidence: Double = 0.8,
        description: String
    ) {
        self.regex = regex
        self.options = options
        self.category = category
        self.baseConfidence = baseConfidence
        self.description = description
    }
}

/// Pattern cache for pre-compiled regex patterns
public actor PIIPatternCache {
    private static let shared = PIIPatternCache()
    private var patterns: [PIICategory: [PIIPattern]] = [:]

    /// Get shared instance
    public static var sharedInstance: PIIPatternCache { shared }

    /// Get patterns for a category
    /// - Parameter category: PII category
    /// - Returns: Array of patterns for the category
    public func patterns(for category: PIICategory) -> [PIIPattern] {
        if patterns[category] == nil {
            patterns[category] = createPatterns(for: category)
        }
        return patterns[category] ?? []
    }

    /// Create patterns for a category
    /// - Parameter category: PII category
    /// - Returns: Array of patterns for the category
    private func createPatterns(for category: PIICategory) -> [PIIPattern] {
        switch category {
        case .audioDomain:
            return [
                PIIPattern(
                    regex: "session\\s+notes?\\s+(?:for|from|on)\\s+[A-Za-z\\s]+",
                    category: .audioDomain,
                    description: "Audio session notes"
                )
            ]
        case .email:
            return [
                PIIPattern(
                    regex: #"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}"#,
                    category: .email,
                    description: "Email address"
                ),
                PIIPattern(
                    regex: #"[a-zA-Z0-9._%+-]+@.*\.(com|org|net|edu|gov)"#,
                    category: .email,
                    description: "Email with common domains"
                )
            ]

        case .phone:
            return [
                PIIPattern(
                    regex: #"\b\d{3}[-.]?\d{3}[-.]?\d{4}\b"#,
                    category: .phone,
                    description: "US phone number"
                ),
                PIIPattern(
                    regex: #"\b\+?1?[-.\s]?\(?:(?:\(?=\d{3}\))\d{3}[-.\s]?\d{3}[-.\s]?\d{4}"#,
                    category: .phone,
                    description: "International phone number"
                )
            ]

        case .ssn:
            return [
                PIIPattern(
                    regex: #"\b\d{3}[-]?\d{2}[-]?\d{4}\b"#,
                    category: .ssn,
                    description: "SSN format"
                ),
                PIIPattern(
                    regex: #"\b\d{3}\s\d{2}\s\d{4}\b"#,
                    category: .ssn,
                    description: "SSN with spaces"
                )
            ]

        case .creditCard:
            return [
                PIIPattern(
                    regex: #"\b(?:4[0-9]{12}(?:[0-9]{3})?|5[1-5][0-9]{14}|2(?:2(?:2[1-9][0-9]|[3-9][0-9])[0-9]{12}|3[47][0-9]{13}|3(?:0[0-5]|[68][0-9])[0-9]{14})\b"#,
                    category: .creditCard,
                    description: "Credit card number"
                ),
                PIIPattern(
                    regex: #"\b\d{4}[-\s]?\d{4}[-\s]?\d{4}[-\s]?\d{4}\b"#,
                    category: .creditCard,
                    description: "Credit card groups"
                )
            ]

        case .address:
            return [
                PIIPattern(
                    regex: #"\b\d+\s+([A-Za-z]+\s)+,\s*[A-Za-z]{2}\s*\d{5}(?:-\d{4})?\b"#,
                    category: .address,
                    description: "US address"
                ),
                PIIPattern(
                    regex: #"\b\d+\s+[A-Za-z]+\s+(?:Street|St|Avenue|Ave|Road|Rd|Drive|Dr|Lane|Ln|Boulevard|Blvd)\b"#,
                    category: .address,
                    description: "Street address"
                )
            ]

        case .dateOfBirth:
            return [
                PIIPattern(
                    regex: #"\b(?:0[1-9]|1[0-2])[-/.](?:0?[1-9]|[12][0-9])[-/.](?:3[01]|[12][0-9])\b"#,
                    category: .dateOfBirth,
                    description: "Date of birth MM/DD/YYYY"
                ),
                PIIPattern(
                    regex: #"\b(?:0[1-9]|1[0-2])[-/.](?:0?[1-9]|[12][0-9])[-/.](?:3[01]|[12][0-9])[-/.]\d{2}\b"#,
                    category: .dateOfBirth,
                    description: "Date of birth with 2-digit year"
                )
            ]

        case .id:
            return [
                PIIPattern(
                    regex: #"\b[A-Z]\d{3}\b"#,
                    category: .id,
                    description: "Driver's license"
                ),
                PIIPattern(
                    regex: #"\b\d{3}[-\s]?\d{2}[-\s]?\d{4}\b"#,
                    category: .id,
                    description: "ID number format"
                )
            ]

        case .financial:
            return [
                PIIPattern(
                    regex: #"\b(?:\$|USD|€|£|¥)\s*\d{1,3}(?:,\d{3})*(?:\.\d{2})?\b"#,
                    category: .financial,
                    description: "Currency amount"
                ),
                PIIPattern(
                    regex: #"\b(?:USD|EUR|GBP|JPY|CAD|AUD)\s*\d+(?:\.\d{2})?\b"#,
                    category: .financial,
                    description: "Currency with code"
                )
            ]

        case .medical:
            return [
                PIIPattern(
                    regex: #"\b(?:MRN|Medical Record Number)\s*:\s*\d+\b"#,
                    category: .medical,
                    description: "Medical record number"
                ),
                PIIPattern(
                    regex: #"\b(?:HIPAA|Health Insurance)\s*#\s*\d+\b"#,
                    category: .medical,
                    description: "HIPAA identifier"
                )
            ]

        case .custom:
            return [] // Would be populated with custom patterns
        }
    }
}

// MARK: - Data Extensions

private extension Data {
    var simpleHash: String {
        // Simple cross-platform hash function
        var hash: UInt64 = 5381
        for byte in self {
            hash = ((hash << 5) &+ hash) &+ UInt64(byte)
        }
        return String(format: "%016llx", hash)
    }
}