//
//  AudioToolsConfiguration.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-08.
//

import Foundation

/// Configuration management for audio domain tools
/// Provides centralized configuration for all audio processing capabilities
struct AudioToolsConfiguration: Codable, Sendable {

    // MARK: - Text Processing Configuration

    struct TextProcessing: Codable, Sendable {
        let maxInputLength: Int
        let defaultMaxOutputTokens: Int
        let enablePIIRedaction: Bool
        let supportedLanguages: [String]
        let customVocabulary: [String: String]

        init(
            maxInputLength: Int = 20_000,
            defaultMaxOutputTokens: Int = 512,
            enablePIIRedaction: Bool = true,
            supportedLanguages: [String] = ["en"],
            customVocabulary: [String: String] = [:]
        ) {
            self.maxInputLength = maxInputLength
            self.defaultMaxOutputTokens = defaultMaxOutputTokens
            self.enablePIIRedaction = enablePIIRedaction
            self.supportedLanguages = supportedLanguages
            self.customVocabulary = customVocabulary
        }
    }

    // MARK: - Summarization Configuration

    struct Summarization: Codable, Sendable {
        let defaultSummaryLength: SummaryLength
        let enableFocusedSummarization: Bool
        let supportedFocusAreas: [FocusArea]
        let maxSummaryTokens: Int

        enum SummaryLength: String, Codable, CaseIterable {
            case short = "short"
            case medium = "medium"
            case long = "long"
            case detailed = "detailed"

            var tokenRange: ClosedRange<Int> {
                switch self {
                case .short: return 50...150
                case .medium: return 150...300
                case .long: return 300...500
                case .detailed: return 500...1000
                }
            }

            var displayName: String {
                switch self {
                case .short: return "Short"
                case .medium: return "Medium"
                case .long: return "Long"
                case .detailed: return "Detailed"
                }
            }
        }

        enum FocusArea: String, Codable, CaseIterable {
            case technical = "technical"
            case creative = "creative"
            case business = "business"
            case mixing = "mixing"
            case mastering = "mastering"
            case arrangement = "arrangement"
            case production = "production"
            case performance = "performance"

            var displayName: String {
                switch self {
                case .technical: return "Technical Details"
                case .creative: return "Creative Elements"
                case .business: return "Business Aspects"
                case .mixing: return "Mixing Decisions"
                case .mastering: return "Mastering Notes"
                case .arrangement: return "Arrangement Details"
                case .production: return "Production Techniques"
                case .performance: return "Performance Notes"
                }
            }

            var description: String {
                switch self {
                case .technical: return "Focus on technical specifications, equipment, and settings"
                case .creative: return "Focus on creative decisions, artistic choices, and inspiration"
                case .business: return "Focus on business aspects, deadlines, and client requirements"
                case .mixing: return "Focus on mixing decisions, balance, and processing"
                case .mastering: return "Focus on mastering choices, loudness, and final processing"
                case .arrangement: return "Focus on song structure, instrumentation, and arrangement"
                case .production: return "Focus on production techniques, recording methods"
                case .performance: return "Focus on performance details, musician contributions"
                }
            }
        }

        init(
            defaultSummaryLength: SummaryLength = .medium,
            enableFocusedSummarization: Bool = true,
            supportedFocusAreas: [FocusArea] = FocusArea.allCases,
            maxSummaryTokens: Int = 1000
        ) {
            self.defaultSummaryLength = defaultSummaryLength
            self.enableFocusedSummarization = enableFocusedSummarization
            self.supportedFocusAreas = supportedFocusAreas
            self.maxSummaryTokens = maxSummaryTokens
        }
    }

    // MARK: - Text Rewriting Configuration

    struct TextRewriting: Codable, Sendable {
        let rewritingStyles: [RewritingStyle]
        let enableStylePreservation: Bool
        let maxRewriteLength: Int

        enum RewritingStyle: String, Codable, CaseIterable {
            case formal = "formal"
            case casual = "casual"
            case technical = "technical"
            case creative = "creative"
            case concise = "concise"
            case detailed = "detailed"
            case neutral = "neutral"

            var displayName: String {
                switch self {
                case .formal: return "Formal"
                case .casual: return "Casual"
                case .technical: return "Technical"
                case .creative: return "Creative"
                case .concise: return "Concise"
                case .detailed: return "Detailed"
                case .neutral: return "Neutral"
                }
            }

            var description: String {
                switch self {
                case .formal: return "Professional and formal language"
                case .casual: return "Informal and conversational tone"
                case .technical: return "Technical terminology and precision"
                case .creative: return "Artistic and expressive language"
                case .concise: return "Brief and to the point"
                case .detailed: return "Comprehensive and thorough"
                case .neutral: return "Objective and unbiased tone"
                }
            }
        }

        init(
            rewritingStyles: [RewritingStyle] = RewritingStyle.allCases,
            enableStylePreservation: Bool = true,
            maxRewriteLength: Int = 2000
        ) {
            self.rewritingStyles = rewritingStyles
            self.enableStylePreservation = enableStylePreservation
            self.maxRewriteLength = maxRewriteLength
        }
    }

    // MARK: - PII Redaction Configuration

    struct PIIRedaction: Codable, Sendable {
        let enableEmailRedaction: Bool
        let enablePhoneRedaction: Bool
        let enableNameRedaction: Bool
        let enableAddressRedaction: Bool
        let enableCustomPatterns: Bool
        let customPatterns: [String: String] // Pattern name -> regex pattern

        init(
            enableEmailRedaction: Bool = true,
            enablePhoneRedaction: Bool = true,
            enableNameRedaction: Bool = false, // Disabled by default as it's aggressive
            enableAddressRedaction: Bool = false, // Disabled by default
            enableCustomPatterns: Bool = false,
            customPatterns: [String: String] = [:]
        ) {
            self.enableEmailRedaction = enableEmailRedaction
            self.enablePhoneRedaction = enablePhoneRedaction
            self.enableNameRedaction = enableNameRedaction
            self.enableAddressRedaction = enableAddressRedaction
            self.enableCustomPatterns = enableCustomPatterns
            self.customPatterns = customPatterns
        }
    }

    // MARK: - Text Chunking Configuration

    struct TextChunking: Codable, Sendable {
        let defaultChunkSize: Int
        let maxChunkSize: Int
        let overlapSize: Int
        let chunkingStrategies: [ChunkingStrategy]

        enum ChunkingStrategy: String, Codable, CaseIterable {
            case sentence = "sentence"
            case paragraph = "paragraph"
            case semantic = "semantic"
            case fixed = "fixed"
            case sliding = "sliding"

            var displayName: String {
                switch self {
                case .sentence: return "Sentence-based"
                case .paragraph: return "Paragraph-based"
                case .semantic: return "Semantic"
                case .fixed: return "Fixed-size"
                case .sliding: return "Sliding window"
                }
            }

            var description: String {
                switch self {
                case .sentence: return "Chunk at sentence boundaries"
                case .paragraph: return "Chunk at paragraph boundaries"
                case .semantic: return "Chunk based on semantic similarity"
                case .fixed: return "Fixed-size chunks"
                case .sliding: return "Overlapping sliding window chunks"
                }
            }
        }

        init(
            defaultChunkSize: Int = 1000,
            maxChunkSize: Int = 2000,
            overlapSize: Int = 100,
            chunkingStrategies: [ChunkingStrategy] = [.paragraph, .semantic]
        ) {
            self.defaultChunkSize = defaultChunkSize
            self.maxChunkSize = maxChunkSize
            self.overlapSize = overlapSize
            self.chunkingStrategies = chunkingStrategies
        }
    }

    // MARK: - Intent Parsing Configuration

    struct IntentParsing: Codable, Sendable {
        let supportedIntents: [AudioIntent]
        let confidenceThreshold: Double
        let enableFallbackParsing: Bool

        enum AudioIntent: String, Codable, CaseIterable {
            case summarize = "summarize"
            case rewrite = "rewrite"
            case normalize = "normalize"
            case extract = "extract"
            case analyze = "analyze"
            case compare = "compare"
            case organize = "organize"
            case format = "format"

            var displayName: String {
                switch self {
                case .summarize: return "Summarize"
                case .rewrite: return "Rewrite"
                case .normalize: return "Normalize"
                case .extract: return "Extract"
                case .analyze: return "Analyze"
                case .compare: return "Compare"
                case .organize: return "Organize"
                case .format: return "Format"
                }
            }

            var description: String {
                switch self {
                case .summarize: return "Create a summary of the content"
                case .rewrite: return "Rewrite content in a different style"
                case .normalize: return "Normalize and clean up text formatting"
                case .extract: return "Extract specific information"
                case .analyze: return "Analyze content characteristics"
                case .compare: return "Compare multiple pieces of content"
                case .organize: return "Organize and structure content"
                case .format: return "Format content according to specifications"
                }
            }
        }

        init(
            supportedIntents: [AudioIntent] = AudioIntent.allCases,
            confidenceThreshold: Double = 0.7,
            enableFallbackParsing: Bool = true
        ) {
            self.supportedIntents = supportedIntents
            self.confidenceThreshold = confidenceThreshold
            self.enableFallbackParsing = enableFallbackParsing
        }
    }

    // MARK: - Performance Configuration

    struct Performance: Codable, Sendable {
        let enableCaching: Bool
        let maxCacheSize: Int
        let cacheExpirationTime: TimeInterval
        let enableMetrics: Bool
        let metricsRetentionPeriod: TimeInterval
        let enablePerformanceLogging: Bool

        init(
            enableCaching: Bool = true,
            maxCacheSize: Int = 100,
            cacheExpirationTime: TimeInterval = 3600, // 1 hour
            enableMetrics: Bool = true,
            metricsRetentionPeriod: TimeInterval = 86400, // 24 hours
            enablePerformanceLogging: Bool = true
        ) {
            self.enableCaching = enableCaching
            self.maxCacheSize = maxCacheSize
            self.cacheExpirationTime = cacheExpirationTime
            self.enableMetrics = enableMetrics
            self.metricsRetentionPeriod = metricsRetentionPeriod
            self.enablePerformanceLogging = enablePerformanceLogging
        }
    }

    // MARK: - System Integration Configuration

    struct SystemIntegration: Codable, Sendable {
        let enableHealthChecks: Bool
        let enableModelInfo: Bool
        let enableCapabilitiesList: Bool
        let enableEmbeddingGeneration: Bool
        let enableSimilarityRanking: Bool
        let embeddingDimensions: Int
        let similarityThreshold: Double
        let healthCheckInterval: TimeInterval

        init(
            enableHealthChecks: Bool = true,
            enableModelInfo: Bool = true,
            enableCapabilitiesList: Bool = true,
            enableEmbeddingGeneration: Bool = true,
            enableSimilarityRanking: Bool = true,
            embeddingDimensions: Int = 1536,
            similarityThreshold: Double = 0.7,
            healthCheckInterval: TimeInterval = 60 // 1 minute
        ) {
            self.enableHealthChecks = enableHealthChecks
            self.enableModelInfo = enableModelInfo
            self.enableCapabilitiesList = enableCapabilitiesList
            self.enableEmbeddingGeneration = enableEmbeddingGeneration
            self.enableSimilarityRanking = enableSimilarityRanking
            self.embeddingDimensions = embeddingDimensions
            self.similarityThreshold = similarityThreshold
            self.healthCheckInterval = healthCheckInterval
        }
    }

    // MARK: - Main Configuration Properties

    let textProcessing: TextProcessing
    let summarization: Summarization
    let textRewriting: TextRewriting
    let piiRedaction: PIIRedaction
    let textChunking: TextChunking
    let intentParsing: IntentParsing
    let performance: Performance
    let systemIntegration: SystemIntegration

    // MARK: - Initialization

    init(
        textProcessing: TextProcessing = TextProcessing(),
        summarization: Summarization = Summarization(),
        textRewriting: TextRewriting = TextRewriting(),
        piiRedaction: PIIRedaction = PIIRedaction(),
        textChunking: TextChunking = TextChunking(),
        intentParsing: IntentParsing = IntentParsing(),
        performance: Performance = Performance(),
        systemIntegration: SystemIntegration = SystemIntegration()
    ) {
        self.textProcessing = textProcessing
        self.summarization = summarization
        self.textRewriting = textRewriting
        self.piiRedaction = piiRedaction
        self.textChunking = textChunking
        self.intentParsing = intentParsing
        self.performance = performance
        self.systemIntegration = systemIntegration
    }

    // MARK: - Default Configurations

    /// Default configuration for audio tools
    static let `default` = AudioToolsConfiguration()

    /// Development configuration with relaxed constraints
    static let development = AudioToolsConfiguration(
        textProcessing: TextProcessing(
            maxInputLength: 50_000,
            defaultMaxOutputTokens: 1024,
            enablePIIRedaction: false
        ),
        summarization: Summarization(
            maxSummaryTokens: 2000
        ),
        performance: Performance(
            enableCaching: false,
            enableMetrics: true,
            enablePerformanceLogging: true
        ),
        systemIntegration: SystemIntegration(
            similarityThreshold: 0.6, // More permissive matching in development
            healthCheckInterval: 30 // More frequent checks in development
        )
    )

    /// Production configuration with strict constraints
    static let production = AudioToolsConfiguration(
        textProcessing: TextProcessing(
            maxInputLength: 20_000,
            defaultMaxOutputTokens: 512,
            enablePIIRedaction: true
        ),
        summarization: Summarization(
            maxSummaryTokens: 1000
        ),
        piiRedaction: PIIRedaction(
            enableEmailRedaction: true,
            enablePhoneRedaction: true,
            enableCustomPatterns: true
        ),
        performance: Performance(
            enableCaching: true,
            enableMetrics: true,
            enablePerformanceLogging: false // Reduce logging in production
        ),
        systemIntegration: SystemIntegration(
            similarityThreshold: 0.8, // More strict matching in production
            healthCheckInterval: 120 // Less frequent checks in production
        )
    )

    // MARK: - Configuration Management

    /// Load configuration from file
    /// - Parameter url: URL of the configuration file
    /// - Returns: Loaded configuration
    /// - Throws: ConfigurationError if loading fails
    static func loadFromFile(at url: URL) throws -> AudioToolsConfiguration {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(AudioToolsConfiguration.self, from: data)
    }

    /// Save configuration to file
    /// - Parameter url: URL to save the configuration to
    /// - Throws: ConfigurationError if saving fails
    func saveToFile(at url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(self)
        try data.write(to: url)
    }

    /// Validate configuration
    /// - Returns: Validation result
    func validate() -> ValidationResult {
        var errors: [ValidationError] = []

        // Validate text processing configuration
        if textProcessing.maxInputLength <= 0 {
            errors.append(ValidationError(
                code: "INVALID_MAX_INPUT_LENGTH",
                message: "Max input length must be positive",
                field: "textProcessing.maxInputLength",
                value: textProcessing.maxInputLength
            ))
        }

        if textProcessing.defaultMaxOutputTokens <= 0 {
            errors.append(ValidationError(
                code: "INVALID_MAX_OUTPUT_TOKENS",
                message: "Default max output tokens must be positive",
                field: "textProcessing.defaultMaxOutputTokens",
                value: textProcessing.defaultMaxOutputTokens
            ))
        }

        // Validate summarization configuration
        if summarization.maxSummaryTokens <= 0 {
            errors.append(ValidationError(
                code: "INVALID_MAX_SUMMARY_TOKENS",
                message: "Max summary tokens must be positive",
                field: "summarization.maxSummaryTokens",
                value: summarization.maxSummaryTokens
            ))
        }

        // Validate intent parsing configuration
        if intentParsing.confidenceThreshold < 0 || intentParsing.confidenceThreshold > 1 {
            errors.append(ValidationError(
                code: "INVALID_CONFIDENCE_THRESHOLD",
                message: "Confidence threshold must be between 0 and 1",
                field: "intentParsing.confidenceThreshold",
                value: intentParsing.confidenceThreshold
            ))
        }

        // Validate text chunking configuration
        if textChunking.defaultChunkSize <= 0 {
            errors.append(ValidationError(
                code: "INVALID_CHUNK_SIZE",
                message: "Default chunk size must be positive",
                field: "textChunking.defaultChunkSize",
                value: textChunking.defaultChunkSize
            ))
        }

        if textChunking.overlapSize < 0 || textChunking.overlapSize >= textChunking.defaultChunkSize {
            errors.append(ValidationError(
                code: "INVALID_OVERLAP_SIZE",
                message: "Overlap size must be non-negative and less than chunk size",
                field: "textChunking.overlapSize",
                value: textChunking.overlapSize
            ))
        }

        // Validate performance configuration
        if performance.maxCacheSize < 0 {
            errors.append(ValidationError(
                code: "INVALID_CACHE_SIZE",
                message: "Max cache size must be non-negative",
                field: "performance.maxCacheSize",
                value: performance.maxCacheSize
            ))
        }

        return ValidationResult(errors: errors)
    }

    /// Merge with another configuration (other takes precedence)
    /// - Parameter other: Configuration to merge with
    /// - Returns: Merged configuration
    func merged(with other: AudioToolsConfiguration) -> AudioToolsConfiguration {
        return AudioToolsConfiguration(
            textProcessing: other.textProcessing,
            summarization: other.summarization,
            textRewriting: other.textRewriting,
            piiRedaction: other.piiRedaction,
            textChunking: other.textChunking,
            intentParsing: other.intentParsing,
            performance: other.performance,
            systemIntegration: other.systemIntegration
        )
    }
}

