//
//  PIIDetectionPatterns.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-08.
//

import Foundation

// MARK: - PII Category Enum

/// Categories of personally identifiable information that can be detected
public enum PIICategory: String, CaseIterable, Codable, Sendable {
    case email = "email"
    case phone = "phone"
    case ssn = "ssn"
    case creditCard = "credit_card"
    case address = "address"
    case dateOfBirth = "date_of_birth"
    case id = "id"
    case financial = "financial"
    case medical = "medical"
    case custom = "custom"
    case audioDomain = "audio_domain"

    var description: String {
        switch self {
        case .email: return "Email addresses"
        case .phone: return "Phone numbers"
        case .ssn: return "Social Security Numbers"
        case .creditCard: return "Credit card numbers"
        case .address: return "Physical addresses"
        case .dateOfBirth: return "Dates of birth"
        case .id: return "Identification numbers"
        case .financial: return "Financial information"
        case .medical: return "Medical information"
        case .custom: return "Custom patterns"
        case .audioDomain: return "Audio domain-specific PII"
        }
    }

    var priority: Int {
        switch self {
        case .ssn, .creditCard: return 10
        case .financial, .medical: return 8
        case .email, .phone: return 6
        case .address, .dateOfBirth: return 5
        case .id: return 4
        case .custom: return 3
        case .audioDomain: return 2
        }
    }

    var replacementText: String {
        switch self {
        case .email: return "[EMAIL]"
        case .phone: return "[PHONE]"
        case .ssn: return "[SSN]"
        case .creditCard: return "[CREDIT_CARD]"
        case .address: return "[ADDRESS]"
        case .dateOfBirth: return "[DOB]"
        case .id: return "[ID]"
        case .financial: return "[FINANCIAL]"
        case .medical: return "[MEDICAL]"
        case .custom: return "[REDACTED]"
        case .audioDomain: return "[AUDIO_PII]"
        }
    }
}

/// Comprehensive PII detection patterns library for audio domain content
/// Provides configurable detection patterns with different sensitivity levels
public class PIIDetectionPatterns: @unchecked Sendable {

    // MARK: - Configuration

    private let configuration: PIIDetectionConfiguration
    private let logger: Logger

    // MARK: - Pattern Libraries

    /// Email detection patterns with different strictness levels
    private let emailPatterns = [
        // Standard email pattern
        #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#,
        // More permissive email pattern (allows uncommon domains)
        #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{1,}$"#,
        // Strict email pattern (common domains only)
        #"^[a-zA-Z0-9._%+-]+@(gmail|yahoo|outlook|hotmail|icloud|protonmail)\.(com|org|net|io|gov|edu)$"#
    ]

    /// Phone number patterns for different formats
    private let phonePatterns = [
        // US phone numbers with area code
        #"\b\d{3}[-.\s]?\d{3}[-.\s]?\d{4}\b"#,
        // International format
        #"\+\d{1,3}[-.\s]?\d{1,4}[-.\s]?\d{1,4}[-.\s]?\d{1,9}\b"#,
        // 10-digit continuous
        #"\b\d{10}\b"#,
        // Phone with extension
        #"\b\d{3}[-.\s]?\d{3}[-.\s]?\d{4}\s*(ext|x|extension)\s*\d+\b"#,
        // UK format
        #"\b\d{2,4}[-.\s]?\d{3,4}[-.\s]?\d{4}\b"#,
        // European format
        #"\b\d{1,4}[-.\s]?\d{1,4}[-.\s]?\d{1,4}[-.\s]?\d{1,4}\b"#
    ]

    /// Social Security Number patterns
    private let ssnPatterns = [
        // Standard SSN format: XXX-XX-XXXX
        #"\b\d{3}-\d{2}-\d{4}\b"#,
        // SSN with spaces: XXX XX XXXX
        #"\b\d{3}\s\d{2}\s\d{4}\b"#,
        // SSN without separators (9 digits)
        #"\b\d{9}\b"#,
        // SSN with invalid area codes (000, 666, 900-999) - for detection
        #"\b(000|666|9\d{2})-\d{2}-\d{4}\b"#
    ]

    /// Credit card patterns for different card types
    private let creditCardPatterns = [
        // Visa (13 or 16 digits, starts with 4)
        #"\b4\d{3}[-.\s]?\d{4}[-.\s]?\d{4}[-.\s]?\d{4}\b"#,
        #"\b4\d{12}(\d{3})?\b"#,
        // MasterCard (16 digits, starts with 51-55 or 2221-2720)
        #"\b(5[1-5]\d{2}|2[2-7]\d{2})[-.\s]?\d{4}[-.\s]?\d{4}[-.\s]?\d{4}\b"#,
        #"\b(5[1-5]\d{2}|2[2-7]\d{2})\d{12}\b"#,
        // American Express (15 digits, starts with 34 or 37)
        #"\b3[47]\d{2}[-.\s]?\d{6}[-.\s]?\d{5}\b"#,
        #"\b3[47]\d{13}\b"#,
        // Discover (16 digits, starts with 6011, 65, 644-649)
        #"\b(6011\d{2}|65\d{2}|64[4-9]\d|62212[6-9]|6221[3-9]\d|622[2-8]\d{2}|6229[01]\d|62292[0-5])[-.\s]?\d{4}[-.\s]?\d{4}\b"#
    ]

    /// Address patterns
    private let addressPatterns = [
        // US street address (number + street name)
        #"\b\d+\s+([A-Z][a-z]*\s*)+(st|street|ave|avenue|rd|road|blvd|boulevard|ln|lane|dr|drive|ct|court|pl|place|way|terrace|tpke|turnpike)\.?\s*$"#,
        // Address with apartment/suite number
        #"\b\d+\s+([A-Z][a-z]*\s*)+(st|street|ave|avenue|rd|road|blvd|boulevard|ln|lane|dr|drive|ct|court|pl|place|way)\s*(apt|apartment|suite|ste|unit|fl|floor|#)\s*[\w-]+\b"#,
        // ZIP+4 codes
        #"\b\d{5}(-\d{4})?\b"#,
        // Canadian postal codes
        #"\b[A-Z]\d[A-Z]\s?\d[A-Z]\d\b"#,
        // UK postal codes
        #"\b[A-Z]{1,2}\d[A-Z\d]?\s?\d[A-Z]{2}\b"#
    ]

    /// Date of birth patterns
    private let dobPatterns = [
        // MM/DD/YYYY
        #"\b(0[1-9]|1[0-2])/(0[1-9]|[12]\d|3[01])/(19|20)\d{2}\b"#,
        // MM-DD-YYYY
        #"\b(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])-(19|20)\d{2}\b"#,
        // DD/MM/YYYY (European)
        #"\b(0[1-9]|[12]\d|3[01])/(0[1-9]|1[0-2])/(19|20)\d{2}\b"#,
        // YYYY-MM-DD (ISO)
        #"\b(19|20)\d{2}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])\b"#,
        // Month DD, YYYY
        #"\b(January|February|March|April|May|June|July|August|September|October|November|December)\s+\d{1,2},\s+(19|20)\d{2}\b"#,
        // Mon DD, YYYY
        #"\b(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+\d{1,2},\s+(19|20)\d{2}\b"#
    ]

    /// ID patterns (driver's license, passport, etc.)
    private let idPatterns = [
        // US Driver's License (varies by state)
        #"\b[A-Z]\d{7,8}\b"#,
        #"\b\d{8,9}\b"#,
        #"\b[A-Z]{1,2}\d{5,7}\b"#,
        // Passport numbers
        #"\b[A-Z]\d{8}\b"#,
        #"\b[A-Z]{2}\d{7}\b"#,
        #"\b\d{9}[A-Z]\d{1}\b"#,
        // Employee ID
        #"\bEMP\d{4,8}\b"#,
        #"\bE\d{6}\b"#,
        #"\b(ID|Employee)\s*#?\s*[\w-]+\b"#
    ]

    /// Financial account patterns
    private let financialPatterns = [
        // Bank account numbers (8-17 digits)
        #"\b\d{8,17}\b"#,
        // Routing numbers (9 digits)
        #"\b\d{9}\b"#,
        // SWIFT codes
        #"\b[A-Z]{6}[A-Z0-9]{2}([A-Z0-9]{3})?\b"#,
        // IBAN patterns
        #"\b[A-Z]{2}\d{2}[A-Z0-9]{4}\d{7}([A-Z0-9]{0,2})?\b"#,
        // Investment account numbers
        #"\b(Acct|Account)\s*#?\s*[\w-]+\b"#,
        #"\b\d{4}-\d{4}-\d{4}-\d{4}\b"#
    ]

    /// Medical information patterns (HIPAA)
    private let medicalPatterns = [
        // Medical record numbers
        #"\b(MRN|Medical\s*Record)\s*#?\s*[\w-]+\b"#,
        #"\b(MR|Med\s*Rec)\s*#?\s*[\w-]+\b"#,
        // Patient IDs
        #"\b(Patient\s*ID|PID)\s*#?\s*[\w-]+\b"#,
        #"\bPt\s*ID\s*#?\s*[\w-]+\b"#,
        // NPI numbers (National Provider Identifier)
        #"\b\d{10}\b"#,
        // Insurance numbers
        #"\b(Insurance|Ins)\s*#?\s*[\w-]+\b"#,
        #"\b(Member\s*ID|Group\s*#)\s*#?\s*[\w-]+\b"#
    ]

    /// Custom patterns for audio domain
    private let audioDomainPatterns = [
        // Client information
        #"(client|customer|artist|band)\s*[:\-]?\s*([A-Z][a-z]+\s){1,2}[A-Z][a-z]+"#,
        // Studio contact info
        #"(studio|engineer|producer)\s*[:\-]?\s*([A-Z][a-z]+\s){1,2}[A-Z][a-z]+"#,
        // Session codes that might contain PII
        #"(session|project|track)\s*#?\s*([A-Z0-9]{8,})"#,
        // Payment information in audio context
        #"(payment|rate|fee)\s*[:\-]?\s*\$?\d+[.,]?\d*"#,
        // Contract information
        #"(contract|agreement)\s*#?\s*([A-Z0-9]{6,})"#
    ]

    // MARK: - Audio Domain Whitelist

    /// Audio domain terms that should NOT be flagged as PII
    private let audioDomainWhitelist: Set<String> = [
        // Technical terms
        "eq", "compression", "reverb", "delay", "chorus", "flanger", "phaser",
        "limiter", "gate", "expander", "de-esser", "multiband", "stereo", "mono",
        "freq", "frequency", "hz", "khz", "db", "decibel", "gain", "volume",
        "pan", "balance", "mix", "mixdown", "master", "mastering", "mixing",
        "daw", "plugin", "vst", "au", "aax", "rtas", "laptop", "desktop",

        // File formats and standards
        "wav", "mp3", "aiff", "flac", "m4a", "aac", "ogg", "wma", "mp4",
        "44.1", "48", "96", "192", "16-bit", "24-bit", "32-bit", "float",
        "midi", "usb", "firewire", "thunderbolt", "bluetooth", "xlr", "tsr",

        // Brand names (audio companies)
        "neumann", "akg", "shure", "sennheiser", "beyerdynamic", "audio-technica",
        "royer", "coles", "brauner", "telefunken", "api", "neve", "ssl", "focusrite",
        "universal audio", "waves", "fabfilter", "soundtoys", "valhalla", "izerotope",

        // Musical terms
        "tempo", "bpm", "key", "scale", "chord", "melody", "harmony", "rhythm",
        "verse", "chorus", "bridge", "intro", "outro", "solo", "section",

        // Professional roles
        "engineer", "producer", "mixer", "mastering", "assistant", "intern",

        // Common studio terms
        "booth", "control room", "live room", "iso", "overdub", "tracking",
        "take", "comp", "edit", "crossfade", "automation", "punch in"
    ]

    // MARK: - Initialization

    init(configuration: PIIDetectionConfiguration = PIIDetectionConfiguration.default, logger: Logger) {
        self.configuration = configuration
        self.logger = logger
    }

    // MARK: - Public Interface

    /// Detect PII in text using configured patterns and sensitivity
    /// - Parameters:
    ///   - text: Text to analyze for PII
    ///   - categories: PII categories to detect (nil for all configured categories)
    ///   - sensitivity: Detection sensitivity level
    ///   - preserveAudioTerms: Whether to preserve audio domain terms
    /// - Returns: PII detection result with detailed findings
    func detectPII(
        in text: String,
        categories: [PIICategory]? = nil,
        sensitivity: PIIDetectionSensitivity = .medium,
        preserveAudioTerms: Bool = true
    ) async -> PIIDetectionResult {
        let startTime = Date()
        var detections: [PIIDetection] = []
        let categoriesToCheck = categories ?? configuration.enabledCategories

        await logger.info(
            "Starting PII detection",
            metadata: [
                "textLength": text.count,
                "categoriesToCheck": categoriesToCheck.count,
                "sensitivity": sensitivity.rawValue,
                "preserveAudioTerms": preserveAudioTerms
            ]
        )

        // Check each enabled category
        for category in categoriesToCheck {
            if configuration.categoriesEnabled[category] == true {
                let categoryDetections = await detectCategory(
                    category,
                    in: text,
                    sensitivity: sensitivity,
                    preserveAudioTerms: preserveAudioTerms
                )
                detections.append(contentsOf: categoryDetections)
            }
        }

        // Remove duplicates and sort by confidence
        detections = removeDuplicateDetections(detections)
        detections.sort { $0.confidence > $1.confidence }

        let executionTime = Date().timeIntervalSince(startTime)

        await logger.info(
            "PII detection completed",
            metadata: [
                "detectionsFound": detections.count,
                "executionTime": executionTime,
                "categoriesWithDetections": Set(detections.map { $0.category }).count
            ]
        )

        return PIIDetectionResult(
            originalText: text,
            detections: detections,
            categories: Set(detections.map { $0.category }),
            sensitivity: sensitivity,
            preserveAudioTerms: preserveAudioTerms,
            metadata: [
                "executionTime": AnyCodable(executionTime),
                "patternsUsed": AnyCodable(configuration.enabledCategories.count),
                "textLength": AnyCodable(text.count),
                "detectionDensity": AnyCodable(Double(detections.count) / Double(max(text.count, 1)))
            ]
        )
    }

    /// Get all available patterns for a specific category
    /// - Parameter category: PII category
    /// - Returns: Array of regex patterns for the category
    func getPatterns(for category: PIICategory) -> [String] {
        switch category {
        case .email:
            return emailPatterns
        case .phone:
            return phonePatterns
        case .ssn:
            return ssnPatterns
        case .creditCard:
            return creditCardPatterns
        case .address:
            return addressPatterns
        case .dateOfBirth:
            return dobPatterns
        case .id:
            return idPatterns
        case .financial:
            return financialPatterns
        case .medical:
            return medicalPatterns
        case .custom:
            return configuration.customPatterns
        case .audioDomain:
            return audioDomainPatterns
        }
    }

    /// Check if a term is in the audio domain whitelist
    /// - Parameter term: Term to check
    /// - Returns: True if term should be preserved (not flagged as PII)
    func isAudioDomainTerm(_ term: String) -> Bool {
        let normalizedTerm = term.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return audioDomainWhitelist.contains(normalizedTerm)
    }

    // MARK: - Private Detection Methods

    /// Detect PII for a specific category
    private func detectCategory(
        _ category: PIICategory,
        in text: String,
        sensitivity: PIIDetectionSensitivity,
        preserveAudioTerms: Bool
    ) async -> [PIIDetection] {
        var detections: [PIIDetection] = []
        let patterns = getPatterns(for: category)

        for (patternIndex, pattern) in patterns.enumerated() {
            do {
                let regex = try NSRegularExpression(
                    pattern: pattern,
                    options: [.caseInsensitive, .dotMatchesLineSeparators]
                )

                let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.count))

                for match in matches {
                    let matchRange = Range(match.range, in: text)
                    guard let range = matchRange else { continue }

                    let matchedText = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)

                    // Skip if this is an audio domain term and preservation is enabled
                    if preserveAudioTerms && isAudioDomainTerm(matchedText) {
                        continue
                    }

                    // Calculate confidence based on pattern strength and sensitivity
                    let baseConfidence = calculateBaseConfidence(for: category, patternIndex: patternIndex, totalPatterns: patterns.count)
                    let adjustedConfidence = adjustConfidenceForSensitivity(baseConfidence, sensitivity: sensitivity)

                    // Skip if confidence is below threshold
                    if adjustedConfidence < sensitivity.confidenceThreshold {
                        continue
                    }

                    let detection = PIIDetection(
                        category: category,
                        matchedText: matchedText,
                        range: range,
                        pattern: pattern,
                        confidence: adjustedConfidence,
                        severity: calculateSeverity(category: category, confidence: adjustedConfidence),
                        metadata: [
                            "patternIndex": AnyCodable(patternIndex),
                            "sensitivity": AnyCodable(sensitivity.rawValue),
                            "preserveAudioTerms": AnyCodable(preserveAudioTerms),
                            "patternStrength": AnyCodable(baseConfidence)
                        ]
                    )

                    detections.append(detection)
                }
            } catch {
                await logger.warning(
                    "Invalid regex pattern in category \(category.rawValue)",
                    metadata: [
                        "pattern": pattern,
                        "error": error.localizedDescription
                    ]
                )
            }
        }

        return detections
    }

    /// Calculate base confidence score for a detection
    private func calculateBaseConfidence(for category: PIICategory, patternIndex: Int, totalPatterns: Int) -> Double {
        // First patterns in each category are typically more specific/reliable
        let patternStrength = 1.0 - (Double(patternIndex) / Double(totalPatterns))

        // Category-specific base confidence adjustments
        let categoryConfidence: Double
        switch category {
        case .email:
            categoryConfidence = 0.95 // Email patterns are very reliable
        case .ssn:
            categoryConfidence = 0.90 // SSN patterns are quite specific
        case .creditCard:
            categoryConfidence = 0.85 // Credit card patterns are mostly reliable
        case .phone:
            categoryConfidence = 0.80 // Phone patterns can have false positives
        case .address:
            categoryConfidence = 0.75 // Address patterns are less specific
        case .dateOfBirth:
            categoryConfidence = 0.70 // Date patterns can be ambiguous
        case .id, .financial, .medical:
            categoryConfidence = 0.65 // These patterns vary widely
        case .custom:
            categoryConfidence = 0.60 // Custom patterns need validation
        case .audioDomain:
            categoryConfidence = 0.50 // Audio domain patterns are context-dependent
        }

        return patternStrength * categoryConfidence
    }

    /// Adjust confidence based on sensitivity level
    private func adjustConfidenceForSensitivity(_ baseConfidence: Double, sensitivity: PIIDetectionSensitivity) -> Double {
        switch sensitivity {
        case .high:
            return min(1.0, baseConfidence + 0.2)
        case .medium:
            return baseConfidence
        case .low:
            return max(0.0, baseConfidence - 0.3)
        case .strict:
            return min(1.0, baseConfidence + 0.3)
        }
    }

    /// Calculate severity level based on category and confidence
    private func calculateSeverity(category: PIICategory, confidence: Double) -> PIISeverity {
        let highRiskCategories: Set<PIICategory> = [.ssn, .creditCard, .financial, .medical]

        if highRiskCategories.contains(category) && confidence > 0.8 {
            return .critical
        } else if confidence > 0.8 {
            return .high
        } else if confidence > 0.6 {
            return .medium
        } else {
            return .low
        }
    }

    /// Remove duplicate detections (overlapping ranges in same category)
    private func removeDuplicateDetections(_ detections: [PIIDetection]) -> [PIIDetection] {
        var uniqueDetections: [PIIDetection] = []

        for detection in detections {
            let hasOverlap = uniqueDetections.contains { existing in
                existing.category == detection.category &&
                existing.range.overlaps(detection.range) &&
                max(existing.range.lowerBound, detection.range.lowerBound) <
                min(existing.range.upperBound, detection.range.upperBound)
            }

            if !hasOverlap {
                uniqueDetections.append(detection)
            } else {
                // If overlapping, keep the one with higher confidence
                if let index = uniqueDetections.firstIndex(where: { existing in
                    existing.category == detection.category && existing.range.overlaps(detection.range)
                }) {
                    if detection.confidence > uniqueDetections[index].confidence {
                        uniqueDetections[index] = detection
                    }
                }
            }
        }

        return uniqueDetections
    }
}

// MARK: - Supporting Types

/// Configuration for PII detection patterns and behavior
public struct PIIDetectionConfiguration: Codable, Sendable {
    let enabledCategories: [PIICategory]
    let categoriesEnabled: [PIICategory: Bool]
    let customPatterns: [String]
    let confidenceThreshold: Double
    let maxDetectionsPerCategory: Int
    let enableAudioDomainAwareness: Bool

    init(
        enabledCategories: [PIICategory] = PIICategory.allCases,
        categoriesEnabled: [PIICategory: Bool] = Dictionary(uniqueKeysWithValues: PIICategory.allCases.map { ($0, true) }),
        customPatterns: [String] = [],
        confidenceThreshold: Double = 0.5,
        maxDetectionsPerCategory: Int = 100,
        enableAudioDomainAwareness: Bool = true
    ) {
        self.enabledCategories = enabledCategories
        self.categoriesEnabled = categoriesEnabled
        self.customPatterns = customPatterns
        self.confidenceThreshold = confidenceThreshold
        self.maxDetectionsPerCategory = maxDetectionsPerCategory
        self.enableAudioDomainAwareness = enableAudioDomainAwareness
    }

    /// Default configuration with all categories enabled
    static let `default` = PIIDetectionConfiguration()

    /// Strict configuration for high-security environments
    static let strict = PIIDetectionConfiguration(
        confidenceThreshold: 0.7,
        maxDetectionsPerCategory: 50
    )

    /// Lenient configuration for development/testing
    static let lenient = PIIDetectionConfiguration(
        confidenceThreshold: 0.3,
        maxDetectionsPerCategory: 200
    )
}

/// Sensitivity levels for PII detection
public enum PIIDetectionSensitivity: String, CaseIterable, Codable, Sendable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case strict = "strict"

    var confidenceThreshold: Double {
        switch self {
        case .low: return 0.3
        case .medium: return 0.5
        case .high: return 0.2
        case .strict: return 0.8
        }
    }

    var threshold: Double {
        return confidenceThreshold
    }

    var description: String {
        switch self {
        case .low: return "Low sensitivity - fewer false positives, may miss some PII"
        case .medium: return "Medium sensitivity - balanced approach"
        case .high: return "High sensitivity - catches more potential PII, more false positives"
        case .strict: return "Strict mode - only high-confidence detections"
        }
    }
}

/// Severity levels for PII detections
public enum PIISeverity: String, CaseIterable, Codable, Sendable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"

    var color: String {
        switch self {
        case .low: return "🟢"
        case .medium: return "🟡"
        case .high: return "🟠"
        case .critical: return "🔴"
        }
    }

    var priority: Int {
        switch self {
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        case .critical: return 4
        }
    }
}

/// Individual PII detection result
public struct PIIDetection: Codable, Sendable {
    let category: PIICategory
    let matchedText: String
    let range: Range<String.Index>
    let pattern: String
    let confidence: Double
    let severity: PIISeverity
    let metadata: [String: AnyCodable]

    init(
        category: PIICategory,
        matchedText: String,
        range: Range<String.Index>,
        pattern: String,
        confidence: Double,
        severity: PIISeverity,
        metadata: [String: AnyCodable] = [:]
    ) {
        self.category = category
        self.matchedText = matchedText
        self.range = range
        self.pattern = pattern
        self.confidence = confidence
        self.severity = severity
        self.metadata = metadata
    }

    // MARK: - Codable Implementation

    enum CodingKeys: String, CodingKey {
        case category, matchedText, range, pattern, confidence, severity, metadata
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        category = try container.decode(PIICategory.self, forKey: .category)
        matchedText = try container.decode(String.self, forKey: .matchedText)
        pattern = try container.decode(String.self, forKey: .pattern)
        confidence = try container.decode(Double.self, forKey: .confidence)
        severity = try container.decode(PIISeverity.self, forKey: .severity)
        metadata = try container.decode([String: AnyCodable].self, forKey: .metadata)

        // Decode range as indices and reconstruct Range<String.Index>
        let rangeData = try container.decode([String: Int].self, forKey: .range)
        let lowerBound = matchedText.index(matchedText.startIndex, offsetBy: rangeData["lowerBound"] ?? 0)
        let upperBound = matchedText.index(matchedText.startIndex, offsetBy: rangeData["upperBound"] ?? matchedText.count)
        range = lowerBound..<upperBound
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(category, forKey: .category)
        try container.encode(matchedText, forKey: .matchedText)
        try container.encode(pattern, forKey: .pattern)
        try container.encode(confidence, forKey: .confidence)
        try container.encode(severity, forKey: .severity)
        try container.encode(metadata, forKey: .metadata)

        // Encode range as indices
        let rangeData: [String: Int] = [
            "lowerBound": matchedText.distance(from: matchedText.startIndex, to: range.lowerBound),
            "upperBound": matchedText.distance(from: matchedText.startIndex, to: range.upperBound)
        ]
        try container.encode(rangeData, forKey: .range)
    }

    /// Convert range to string indices for serialization
    var rangeData: [String: Int] {
        return [
            "lowerBound": matchedText.distance(from: matchedText.startIndex, to: range.lowerBound),
            "upperBound": matchedText.distance(from: matchedText.startIndex, to: range.upperBound)
        ]
    }
}

/// Complete PII detection result
public struct PIIDetectionResult: Sendable {
    let originalText: String
    let detections: [PIIDetection]
    let categories: Set<PIICategory>
    let sensitivity: PIIDetectionSensitivity
    let preserveAudioTerms: Bool
    let metadata: [String: AnyCodable]

    var hasDetections: Bool { !detections.isEmpty }
    var detectionCount: Int { detections.count }
    var criticalDetections: [PIIDetection] { detections.filter { $0.severity == .critical } }
    var highDetections: [PIIDetection] { detections.filter { $0.severity == .high } }

    /// Get detections grouped by category
    var detectionsByCategory: [PIICategory: [PIIDetection]] {
        Dictionary(grouping: detections) { $0.category }
    }

    /// Get detections grouped by severity
    var detectionsBySeverity: [PIISeverity: [PIIDetection]] {
        Dictionary(grouping: detections) { $0.severity }
    }

    /// Calculate overall risk score
    var riskScore: Double {
        guard !detections.isEmpty else { return 0.0 }

        let weightedScore = detections.reduce(0.0) { total, detection in
            total + (detection.confidence * Double(detection.severity.priority))
        }

        return min(1.0, weightedScore / Double(detections.count))
    }
}