//
//  TokenCountUtility.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-08.
//

import Foundation

/// Token Counting Utility for Audio Domain Content
///
/// Provides accurate token estimation for various types of audio-related content
/// including session notes, transcripts, plugin documentation, and technical specifications.
/// Implements multiple estimation strategies optimized for audio engineering terminology.
///
/// Features:
/// - Multiple estimation strategies (character-based, word-based, semantic-aware)
/// - Audio domain-specific token cost adjustment
/// - Detailed token breakdown and analysis
/// - Support for different content types (transcripts, notes, documentation)
/// - Chunking-aware token counting for large texts
///
/// Use Cases:
/// - Pre-flight token estimation for LLM processing
/// - Cost analysis for audio workflow operations
/// - Content size optimization for model limits
/// - Token budget planning for batch operations
public final class TokenCountUtility: AudioDomainTool, @unchecked Sendable {

    // MARK: - Tool Configuration
    // Note: name and description are set in super.init call

    // MARK: - Token Counting Strategies

    /// Supported token estimation strategies
    public enum TokenEstimationStrategy: String, CaseIterable {
        case characterBased = "character"
        case wordBased = "word"
        case semanticAware = "semantic"
        case audioOptimized = "audio"
        case mixed = "mixed"

        var description: String {
            switch self {
            case .characterBased: return "Character-based estimation (4 chars ≈ 1 token)"
            case .wordBased: return "Word-based estimation (0.75 words ≈ 1 token)"
            case .semanticAware: return "Semantic-aware estimation considers content complexity"
            case .audioOptimized: return "Audio-optimized estimation for technical terms and jargon"
            case .mixed: return "Mixed strategy combining multiple approaches"
            }
        }
    }

    /// Content types for specialized token counting
    public enum ContentType: String, CaseIterable {
        case transcript = "transcript"
        case sessionNotes = "session_notes"
        case pluginDocs = "plugin_docs"
        case technicalSpec = "technical_spec"
        case general = "general"

        var description: String {
            switch self {
            case .transcript: return "Spoken language transcripts with natural speech patterns"
            case .sessionNotes: return "Engineering session notes with technical terminology"
            case .pluginDocs: return "Plugin documentation with feature descriptions"
            case .technicalSpec: return "Technical specifications with structured data"
            case .general: return "General text content without domain specialization"
            }
        }
    }

    // MARK: - Initialization

    public init(logger: Logger, securityManager: SecurityManager) {
        let inputSchema: [String: AnyCodable] = [
            "type": AnyCodable("object"),
            "properties": AnyCodable([
                "text": AnyCodable([
                    "type": AnyCodable("string"),
                    "description": AnyCodable("Text to analyze for token count estimation")
                ]),
                "strategy": AnyCodable([
                    "type": AnyCodable("string"),
                    "description": AnyCodable("Token estimation strategy to use"),
                    "enum": AnyCodable(TokenEstimationStrategy.allCases.map(\.rawValue)),
                    "default": AnyCodable(TokenEstimationStrategy.audioOptimized.rawValue)
                ]),
                "content_type": AnyCodable([
                    "type": AnyCodable("string"),
                    "description": AnyCodable("Type of content for specialized estimation"),
                    "enum": AnyCodable(ContentType.allCases.map(\.rawValue)),
                    "default": AnyCodable(ContentType.general.rawValue)
                ]),
                "include_breakdown": AnyCodable([
                    "type": AnyCodable("boolean"),
                    "description": AnyCodable("Include detailed breakdown of token count"),
                    "default": AnyCodable(true)
                ]),
                "chunk_analysis": AnyCodable([
                    "type": AnyCodable("boolean"),
                    "description": AnyCodable("Analyze tokens in chunk-sized segments for processing insights"),
                    "default": AnyCodable(false)
                ]),
                "chunk_size": AnyCodable([
                    "type": AnyCodable("integer"),
                    "description": AnyCodable("Chunk size in characters for chunk analysis"),
                    "minimum": AnyCodable(100),
                    "maximum": AnyCodable(2000),
                    "default": AnyCodable(500)
                ])
            ]),
            "required": AnyCodable(["text"])
        ]

        super.init(
            name: "apple_tokens_count",
            description: "Estimates token count for audio domain content with multiple strategies and detailed analysis.",
            inputSchema: inputSchema,
            logger: logger,
            securityManager: securityManager
        )
    }

    // MARK: - Audio Processing

    /// Counts tokens in text using specified strategy and content type
    public override func processAudioContent(_ content: String, with parameters: [String: Any]) async throws -> String {
        guard let text = parameters["text"] as? String else {
            throw AudioProcessingError.invalidInput("text parameter is required")
        }

        // Parse estimation strategy
        let strategyString = parameters["strategy"] as? String ?? TokenEstimationStrategy.audioOptimized.rawValue
        guard let strategy = TokenEstimationStrategy(rawValue: strategyString.lowercased()) else {
            throw AudioProcessingError.invalidInput("Invalid token estimation strategy: \(strategyString)")
        }

        // Parse content type
        let contentTypeString = parameters["content_type"] as? String ?? ContentType.general.rawValue
        guard let contentType = ContentType(rawValue: contentTypeString.lowercased()) else {
            throw AudioProcessingError.invalidInput("Invalid content type: \(contentTypeString)")
        }

        // Parse options
        let includeBreakdown = parameters["include_breakdown"] as? Bool ?? true
        let chunkAnalysis = parameters["chunk_analysis"] as? Bool ?? false
        let chunkSize = min(max(100, parameters["chunk_size"] as? Int ?? 500), 2000)

        // Pre-security check
        try await performSecurityCheck(text)

        // Perform token counting
        let result = try await countTokens(
            text: text,
            strategy: strategy,
            contentType: contentType,
            includeBreakdown: includeBreakdown,
            chunkAnalysis: chunkAnalysis,
            chunkSize: chunkSize
        )

        // Post-security validation
        try await validateOutput(result)

        return formatTokenCountResult(result)
    }

    // MARK: - Private Implementation

    /// Result structure for token counting
    private struct TokenCountResult {
        let totalTokens: Int
        let strategy: TokenEstimationStrategy
        let contentType: ContentType
        let breakdown: TokenBreakdown?
        let chunkAnalysis: ChunkAnalysis?
        let metadata: [String: Any]
    }

    /// Detailed token breakdown
    private struct TokenBreakdown {
        let baseTokens: Int
        let audioAdjustment: Int
        let contentComplexityBonus: Int
        let technicalTerms: Int
        let adjustment: Int

        var totalTokens: Int {
            return baseTokens + audioAdjustment + contentComplexityBonus + technicalTerms + adjustment
        }
    }

    /// Chunk analysis for processing insights
    private struct ChunkAnalysis {
        let chunkCount: Int
        let averageTokensPerChunk: Int
        let maxTokensInChunk: Int
        let minTokensInChunk: Int
        let chunks: [ChunkInfo]

        struct ChunkInfo {
            let index: Int
            let startPosition: Int
            let endPosition: Int
            let tokenCount: Int
            let preview: String
        }
    }

    /// Count tokens using specified strategy and content type
    private func countTokens(
        text: String,
        strategy: TokenEstimationStrategy,
        contentType: ContentType,
        includeBreakdown: Bool,
        chunkAnalysis: Bool,
        chunkSize: Int
    ) async throws -> TokenCountResult {

        let baseTokens = calculateBaseTokens(text: text, strategy: strategy)
        let breakdown = includeBreakdown ? calculateBreakdown(
            text: text,
            baseTokens: baseTokens,
            strategy: strategy,
            contentType: contentType
        ) : nil

        let chunkResult = chunkAnalysis ? performChunkAnalysis(
            text: text,
            chunkSize: chunkSize,
            strategy: strategy
        ) : nil

        let totalTokens = breakdown?.totalTokens ?? baseTokens

        let metadata = buildTokenMetadata(
            text: text,
            totalTokens: totalTokens,
            strategy: strategy,
            contentType: contentType,
            breakdown: breakdown,
            chunkAnalysis: chunkResult
        )

        return TokenCountResult(
            totalTokens: totalTokens,
            strategy: strategy,
            contentType: contentType,
            breakdown: breakdown,
            chunkAnalysis: chunkResult,
            metadata: metadata
        )
    }

    /// Calculate base token count using specified strategy
    private func calculateBaseTokens(text: String, strategy: TokenEstimationStrategy) -> Int {
        switch strategy {
        case .characterBased:
            return Int(ceil(Double(text.count) / 4.0))

        case .wordBased:
            let wordCount = text.components(separatedBy: .whitespacesAndNewlines)
                .filter { !$0.isEmpty }
                .count
            return Int(ceil(Double(wordCount) / 0.75))

        case .semanticAware:
            // Semantic-aware considers sentence structure and content complexity
            let sentences = splitIntoSentences(text)
            let averageWordsPerSentence = sentences.isEmpty ? 0 : sentences.map { $0.components(separatedBy: .whitespaces).filter { !$0.isEmpty }.count }.reduce(0, +) / sentences.count
            let complexityBonus = calculateComplexityBonus(text: text, sentences: sentences)
            return Int(ceil(Double(averageWordsPerSentence * sentences.count) / 0.75)) + complexityBonus

        case .audioOptimized:
            // Audio-optimized strategy with domain-specific adjustments
            let baseTokens = Int(ceil(Double(text.count) / 3.8)) // Audio content typically denser
            let audioBonus = calculateAudioDomainBonus(text: text)
            return baseTokens + audioBonus

        case .mixed:
            // Mixed strategy uses character-based as base and applies content-specific adjustments
            let charTokens = Int(ceil(Double(text.count) / 4.0))
            let contentBonus = calculateContentSpecificBonus(text: text, contentType: .general)
            return charTokens + contentBonus
        }
    }

    /// Calculate detailed token breakdown
    private func calculateBreakdown(
        text: String,
        baseTokens: Int,
        strategy: TokenEstimationStrategy,
        contentType: ContentType
    ) -> TokenBreakdown {

        let audioAdjustment = calculateAudioDomainBonus(text: text)
        let complexityBonus = calculateComplexityBonus(text: text, sentences: splitIntoSentences(text))
        let technicalTerms = calculateTechnicalTermsBonus(text: text)
        let contentAdjustment = calculateContentSpecificBonus(text: text, contentType: contentType)

        return TokenBreakdown(
            baseTokens: baseTokens,
            audioAdjustment: audioAdjustment,
            contentComplexityBonus: complexityBonus,
            technicalTerms: technicalTerms,
            adjustment: contentAdjustment
        )
    }

    /// Calculate audio domain-specific token adjustment
    private func calculateAudioDomainBonus(text: String) -> Int {
        let audioKeywords = [
            // Audio processing terms
            "mixing", "mastering", "recording", "tracking", "editing", "compression",
            "eq", "reverb", "delay", "chorus", "flanger", "phaser", "distortion",
            // Technical terms
            "frequency", "amplitude", "waveform", "bitrate", "sample rate", "khz", "hz", "db", "dbfs",
            "rms", "peak", "clipping", "saturation", "headroom",
            // Equipment
            "microphone", "mic", "preamp", "interface", "converter", "ad/da", "clock",
            "monitor", "speaker", "headphone", "studio", "booth", "acoustic",
            // Audio formats
            "wav", "mp3", "aiff", "flac", "m4a", "aac", "ogg", "wma",
            "pcm", "floating-point", "32-bit", "24-bit", "16-bit",
            // DAW terminology
            "daw", "session", "project", "track", "channel", "bus", "send", "return",
            "automation", "plugin", "vst", "au", "aax", "rtas", "insert",
            // Music terms
            "tempo", "bpm", "time signature", "key", "scale", "chord", "melody",
            "harmony", "rhythm", "beat", "measure", "bar"
        ]

        let lowercaseText = text.lowercased()
        let keywordCount = audioKeywords.filter { lowercaseText.contains($0) }.count

        // Each audio keyword typically costs 1.2-1.5x more tokens
        let bonus = Int(Double(keywordCount) * 0.3)
        let currentBaseTokens = calculateBaseTokens(text: text, strategy: .characterBased)
        return min(bonus, currentBaseTokens / 2) // Cap at 50% of base tokens
    }

    /// Calculate complexity bonus based on content structure
    private func calculateComplexityBonus(text: String, sentences: [String]) -> Int {
        guard !sentences.isEmpty else { return 0 }

        let averageSentenceLength = Double(text.count) / Double(sentences.count)
        let complexityFactor = max(0.0, (averageSentenceLength - 50) / 50) // Bonus for longer sentences

        // Add bonus for technical patterns
        let technicalPatterns = [
            #"\d+[.,]\d+khz"#,  // Frequencies
            #"\d+[.,]\d+db"#,    // Decibels
            #"\d+[.,]\d+ms"#,    // Time values
            #"\d+/\d+"#,        // Ratios
            #"\d+bps"#         // Bitrates
        ]

        let patternBonus = technicalPatterns.reduce(0) { total, pattern in
            let regex = try? NSRegularExpression(pattern: pattern, options: [])
            let matches = regex?.numberOfMatches(in: text, options: [], range: NSRange(location: 0, length: text.count)) ?? 0
            return total + (matches * 2)
        }

        return Int(ceil(complexityFactor * 10)) + patternBonus
    }

    /// Calculate technical terms bonus
    private func calculateTechnicalTermsBonus(text: String) -> Int {
        let technicalPatterns = [
            #"\b[A-Z]{2,}\d*[a-z]*\b"#, // CamelCase technical terms
            #"\b[A-Z]{3,}\b"#,          // All caps acronyms
            #"\d+[.,]?\d*\s*(?:khz|hz|db|ms|bps|kb|mb|gb)"# // Technical measurements
        ]

        return technicalPatterns.reduce(0) { total, pattern in
            let regex = try? NSRegularExpression(pattern: pattern, options: [])
            let matches = regex?.numberOfMatches(in: text, options: [], range: NSRange(location: 0, length: text.count)) ?? 0
            return total + (matches * 1)
        }
    }

    /// Calculate content-specific bonus
    private func calculateContentSpecificBonus(text: String, contentType: ContentType) -> Int {
        switch contentType {
        case .transcript:
            // Transcripts often have natural speech patterns
            let fillerWords = ["um", "uh", "like", "you know", "actually", "basically", "sort of"]
            let fillerCount = fillerWords.reduce(0) { total, filler in
                return total + text.lowercased().components(separatedBy: .whitespacesAndNewlines)
                    .filter { $0 == filler }.count
            }
            return fillerCount / 3 // Each ~3 filler words ≈ 1 less token

        case .sessionNotes:
            // Session notes are typically dense with technical information
            return calculateAudioDomainBonus(text: text) / 2

        case .pluginDocs:
            // Plugin documentation often has structured technical terms
            return calculateTechnicalTermsBonus(text: text)

        case .technicalSpec:
            // Technical specifications are very dense
            return calculateAudioDomainBonus(text: text) + calculateTechnicalTermsBonus(text: text)

        case .general:
            // No specific adjustment for general content
            return 0
        }
    }

    /// Perform chunk analysis for processing insights
    private func performChunkAnalysis(text: String, chunkSize: Int, strategy: TokenEstimationStrategy) -> ChunkAnalysis {
        let chunks = createChunks(text: text, chunkSize: chunkSize)
        var chunkInfos: [ChunkAnalysis.ChunkInfo] = []

        for (index, chunk) in chunks.enumerated() {
            let tokenCount = calculateBaseTokens(text: chunk, strategy: strategy)
            let startPosition = text.distance(from: text.startIndex, to: chunk.startIndex)
            let endPosition = startPosition + chunk.count
            let preview = String(chunk.prefix(50))

            chunkInfos.append(ChunkAnalysis.ChunkInfo(
                index: index,
                startPosition: startPosition,
                endPosition: endPosition,
                tokenCount: tokenCount,
                preview: preview
            ))
        }

        let tokenCounts = chunkInfos.map { $0.tokenCount }
        let averageTokens = tokenCounts.isEmpty ? 0 : tokenCounts.reduce(0, +) / tokenCounts.count
        let maxTokens = tokenCounts.max() ?? 0
        let minTokens = tokenCounts.min() ?? 0

        return ChunkAnalysis(
            chunkCount: chunks.count,
            averageTokensPerChunk: averageTokens,
            maxTokensInChunk: maxTokens,
            minTokensInChunk: minTokens,
            chunks: chunkInfos
        )
    }

    /// Create text chunks for analysis
    private func createChunks(text: String, chunkSize: Int) -> [String] {
        var chunks: [String] = []
        var currentIndex = text.startIndex

        while currentIndex < text.endIndex {
            let endIndex = text.index(currentIndex, offsetBy: min(chunkSize, text.distance(from: currentIndex, to: text.endIndex)))
            let chunk = String(text[currentIndex..<endIndex])
            chunks.append(chunk)
            currentIndex = endIndex
        }

        return chunks
    }

    /// Split text into sentences
    private func splitIntoSentences(_ text: String) -> [String] {
        let pattern = #"[.!?]+[\s\n]+(?=[A-Z0-9])"#
        return text.components(separatedBy: pattern)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    /// Build metadata for token counting result
    private func buildTokenMetadata(
        text: String,
        totalTokens: Int,
        strategy: TokenEstimationStrategy,
        contentType: ContentType,
        breakdown: TokenBreakdown?,
        chunkAnalysis: ChunkAnalysis?
    ) -> [String: Any] {
        var metadata: [String: Any] = [
            "textLength": text.count,
            "estimatedTokens": totalTokens,
            "strategy": strategy.rawValue,
            "contentType": contentType.rawValue,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]

        // Add breakdown details if available
        if let breakdown = breakdown {
            metadata["breakdown"] = [
                "baseTokens": breakdown.baseTokens,
                "audioAdjustment": breakdown.audioAdjustment,
                "complexityBonus": breakdown.contentComplexityBonus,
                "technicalTerms": breakdown.technicalTerms,
                "contentAdjustment": breakdown.adjustment,
                "totalTokens": breakdown.totalTokens
            ]
        }

        // Add chunk analysis if available
        if let chunkAnalysis = chunkAnalysis {
            metadata["chunkAnalysis"] = [
                "chunkCount": chunkAnalysis.chunkCount,
                "averageTokensPerChunk": chunkAnalysis.averageTokensPerChunk,
                "maxTokensInChunk": chunkAnalysis.maxTokensInChunk,
                "minTokensInChunk": chunkAnalysis.minTokensInChunk
            ]

            // Add chunk details (limited to avoid too much data)
            let chunkDetails = chunkAnalysis.chunks.prefix(5).map { chunk in
                [
                    "index": chunk.index,
                    "tokenCount": chunk.tokenCount,
                    "preview": chunk.preview
                ]
            }
            metadata["chunkDetails"] = chunkDetails
        }

        // Add content analysis
        metadata["contentAnalysis"] = [
            "wordCount": text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count,
            "sentenceCount": splitIntoSentences(text).count,
            "paragraphCount": text.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count,
            "containsAudioTerms": containsAudioTerms(text),
            "estimatedReadingTime": Double(totalTokens) * 0.25, // ~4 tokens per second reading
            "estimatedCost": Double(totalTokens) * 0.00001 // $0.01 per 1000 tokens estimate
        ]

        return metadata
    }

    /// Check if text contains audio-related terms
    private func containsAudioTerms(_ text: String) -> Bool {
        let audioTerms = [
            "audio", "sound", "music", "recording", "mixing", "mastering",
            "track", "studio", "producer", "engineer", "session"
        ]

        let lowercaseText = text.lowercased()
        return audioTerms.contains { lowercaseText.contains($0) }
    }

    /// Format token counting result as structured JSON
    private func formatTokenCountResult(_ result: TokenCountResult) -> String {
        var response = ""
        response += "Token Count Analysis\n"
        response += "===================\n\n"

        // Main result
        response += "Total Estimated Tokens: \(result.totalTokens)\n"
        response += "Strategy: \(result.strategy.description)\n"
        response += "Content Type: \(result.contentType.description)\n"
        response += "Text Length: \(result.metadata["textLength"] ?? 0) characters\n\n"

        // Breakdown if available
        if let breakdown = result.breakdown {
            response += "Token Breakdown:\n"
            response += "  Base Tokens: \(breakdown.baseTokens)\n"
            response += "  Audio Domain Adjustment: +\(breakdown.audioAdjustment)\n"
            response += "  Complexity Bonus: +\(breakdown.contentComplexityBonus)\n"
            response += "  Technical Terms: +\(breakdown.technicalTerms)\n"
            response += "  Content Type Adjustment: +\(breakdown.adjustment)\n"
            response += "  Total: \(breakdown.totalTokens)\n\n"
        }

        // Content analysis
        if let contentAnalysis = result.metadata["contentAnalysis"] as? [String: Any] {
            response += "Content Analysis:\n"
            response += "  Words: \(contentAnalysis["wordCount"] ?? 0)\n"
            response += "  Sentences: \(contentAnalysis["sentenceCount"] ?? 0)\n"
            response += "  Paragraphs: \(contentAnalysis["paragraphCount"] ?? 0)\n"
            response += "  Contains Audio Terms: \((contentAnalysis["containsAudioTerms"] as? Bool) ?? false ? "Yes" : "No")\n"
            response += "  Est. Reading Time: \(String(format: "%.1f", contentAnalysis["estimatedReadingTime"] as? Double ?? 0.0))s\n"
            response += "  Est. Cost: $\(String(format: "%.4f", contentAnalysis["estimatedCost"] as? Double ?? 0.0))\n\n"
        }

        // Chunk analysis if available
        if let chunkAnalysis = result.chunkAnalysis {
            response += "Chunk Analysis:\n"
            response += "  Chunks: \(chunkAnalysis.chunkCount)\n"
            response += "  Avg Tokens/Chunk: \(chunkAnalysis.averageTokensPerChunk)\n"
            response += "  Max Tokens in Chunk: \(chunkAnalysis.maxTokensInChunk)\n"
            response += "  Min Tokens in Chunk: \(chunkAnalysis.minTokensInChunk)\n"

            if !chunkAnalysis.chunks.isEmpty {
                response += "\n  Sample Chunks:\n"
                for chunk in chunkAnalysis.chunks.prefix(3) {
                    response += "    Chunk \(chunk.index): \(chunk.tokenCount) tokens - \"\(chunk.preview)\"\n"
                }
                if chunkAnalysis.chunks.count > 3 {
                    response += "    ... (\(chunkAnalysis.chunks.count - 3) more chunks)\n"
                }
            }
        }

        return response
    }

    // MARK: - Security

    /// Validates input for security compliance
    private func performSecurityCheck(_ text: String) async throws {
        try TextValidationUtils.validateText(text)
        try TextValidationUtils.validateTextSecurity(text)
    }

    /// Validates output for security compliance
    private func validateOutput(_ result: TokenCountResult) async throws {
        // Basic sanity check on token count
        if result.totalTokens < 0 {
            throw AudioProcessingError.validationError("Token count cannot be negative")
        }

        // Validate reasonable token limits
        if result.totalTokens > 100000 {
            await logger.warning(
                "Unusually high token count estimated",
                category: .general,
                metadata: [
                    "tokenCount": AnyCodable(result.totalTokens),
                    "strategy": AnyCodable(result.strategy.rawValue),
                    "textLength": AnyCodable(result.metadata["textLength"] ?? 0)
                ]
            )
        }
    }
}