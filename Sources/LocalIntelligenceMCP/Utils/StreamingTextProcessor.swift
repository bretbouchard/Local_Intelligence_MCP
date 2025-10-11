//
//  StreamingTextProcessor.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-09.
//

import Foundation

/// High-performance streaming text processor for large inputs
/// Processes text in chunks to optimize memory usage and enable real-time processing
public actor StreamingTextProcessor {

    // MARK: - Configuration

    public struct Configuration {
        public let chunkSize: Int
        public let overlapSize: Int
        public let maxConcurrency: Int
        public let memoryThreshold: Int

        public init(
            chunkSize: Int = 8192,
            overlapSize: Int = 512,
            maxConcurrency: Int = 4,
            memoryThreshold: Int = 1024 * 1024 * 64 // 64MB
        ) {
            self.chunkSize = chunkSize
            self.overlapSize = overlapSize
            self.maxConcurrency = maxConcurrency
            self.memoryThreshold = memoryThreshold
        }
    }

    // MARK: - Properties

    private let configuration: Configuration
    private let patternCache: PatternCache

    // MARK: - Initialization

    public init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
        self.patternCache = PatternCache.shared
    }

    // MARK: - Public Interface

    /// Process large text input with streaming PII detection
    /// - Parameters:
    ///   - text: Input text to process
    ///   - patterns: Patterns to search for
    ///   - context: Execution context
    /// - Returns: Stream processing result with matches and metadata
    public func processLargeText(
        _ text: String,
        patterns: [String],
        context: MCPExecutionContext
    ) async throws -> StreamProcessingResult {
        let startTime = Date()
        let textSize = text.utf8.count

        // Check if text needs streaming processing
        guard textSize > configuration.chunkSize else {
            // For small texts, use regular processing
            return try await processSmallText(text, patterns: patterns, context: context)
        }

        // Preload patterns for optimal performance
        try await patternCache.preloadCommonPatterns(patterns)

        // Create text chunks
        let chunks = createChunks(from: text)
        var allMatches: [TextMatch] = []
        var processingStats = ProcessingStats()

        // Process chunks with controlled concurrency using withTaskGroup with proper isolation
        await withTaskGroup(of: Optional<ChunkResult>.self) { group in
            var activeTasks = 0
            
            for (index, chunk) in chunks.enumerated() {
                // Control concurrency
                if activeTasks >= configuration.maxConcurrency {
                    if let result = await group.next(), let actualResult = result {
                        allMatches.append(contentsOf: actualResult.matches)
                        processingStats.merge(with: actualResult.stats)
                    }
                    activeTasks -= 1
                }
                
                // Add task with sendable closure
                group.addTask { @Sendable in
                    // Process chunk directly within task group with isolated access
                    return await StreamingTextProcessor.processChunkConcurrently(
                        chunk,
                        index: index,
                        patterns: patterns,
                        context: context,
                        patternCache: PatternCache.shared
                    )
                }
                activeTasks += 1
            }
            
            // Collect remaining results
            while let result = await group.next(), let actualResult = result {
                allMatches.append(contentsOf: actualResult.matches)
                processingStats.merge(with: actualResult.stats)
            }
        }

        // Merge overlapping matches
        let mergedMatches = mergeOverlappingMatches(allMatches)

        let processingTime = Date().timeIntervalSince(startTime)

        return StreamProcessingResult(
            matches: mergedMatches,
            stats: processingStats,
            processingTime: processingTime,
            textSize: textSize,
            chunkCount: chunks.count,
            usedStreaming: true
        )
    }

    /// Stream text replacement for large inputs
    /// - Parameters:
    ///   - text: Input text
    ///   - replacements: Dictionary of patterns to replacement strings
    ///   - context: Execution context
    /// - Returns: Processed text with replacements applied
    public func streamReplace(
        _ text: String,
        replacements: [String: String],
        context: MCPExecutionContext
    ) async throws -> StringProcessingResult {
        let startTime = Date()
        let textSize = text.utf8.count

        guard textSize > configuration.chunkSize else {
            return try await processSmallReplacement(text, replacements: replacements, context: context)
        }

        let chunks = createChunks(from: text)
        var processedChunks: [ProcessedChunk] = []
        var totalReplacements = 0

        // Process chunks sequentially to maintain text continuity
        for (index, chunk) in chunks.enumerated() {
            let result = try await processChunkReplacement(
                chunk,
                index: index,
                replacements: replacements,
                context: context
            )
            processedChunks.append(result)
            totalReplacements += result.replacementCount
        }

        // Reconstruct text from processed chunks
        let reconstructedText = reconstructText(from: processedChunks)

        let processingTime = Date().timeIntervalSince(startTime)

        return StringProcessingResult(
            processedText: reconstructedText,
            replacementCount: totalReplacements,
            processingTime: processingTime,
            textSize: textSize,
            chunkCount: chunks.count,
            usedStreaming: true
        )
    }

    // MARK: - Private Methods

    /// Process small text without streaming
    private func processSmallText(
        _ text: String,
        patterns: [String],
        context: MCPExecutionContext
    ) async throws -> StreamProcessingResult {
        let startTime = Date()
        var matches: [TextMatch] = []

        for pattern in patterns {
            let regex = try await patternCache.getPattern(pattern)
            let range = NSRange(text.startIndex..<text.endIndex, in: text)

            let patternMatches = regex.matches(in: text, range: range)
            for match in patternMatches {
                if let range = Range(match.range, in: text) {
                    let matchedText = String(text[range])
                    matches.append(TextMatch(
                        pattern: pattern,
                        matchedText: matchedText,
                        range: match.range,
                        confidence: calculateConfidence(matchedText, pattern: pattern)
                    ))
                }
            }
        }

        let processingTime = Date().timeIntervalSince(startTime)

        return StreamProcessingResult(
            matches: matches,
            stats: ProcessingStats(matchCount: matches.count),
            processingTime: processingTime,
            textSize: text.utf8.count,
            chunkCount: 1,
            usedStreaming: false
        )
    }

    /// Process a single chunk of text
    private func processChunk(
        _ chunk: StreamingTextChunk,
        index: Int,
        patterns: [String],
        context: MCPExecutionContext
    ) async -> ChunkResult {
        let startTime = Date()
        var matches: [TextMatch] = []

        for pattern in patterns {
            do {
                let regex = try await patternCache.getPattern(pattern)
                let range = NSRange(chunk.content.startIndex..<chunk.content.endIndex, in: chunk.content)

                let patternMatches = regex.matches(in: chunk.content, range: range)
                for match in patternMatches {
                    if let range = Range(match.range, in: chunk.content) {
                        let matchedText = String(chunk.content[range])
                        let globalRange = NSRange(
                            location: chunk.globalOffset + match.range.location,
                            length: match.range.length
                        )

                        matches.append(TextMatch(
                            pattern: pattern,
                            matchedText: matchedText,
                            range: globalRange,
                            confidence: calculateConfidence(matchedText, pattern: pattern)
                        ))
                    }
                }
            } catch {
                // Continue processing other patterns on error
                // Error handling should be done by the calling context
                continue
            }
        }

        let processingTime = Date().timeIntervalSince(startTime)

        return ChunkResult(
            chunkIndex: index,
            matches: matches,
            stats: ProcessingStats(
                matchCount: matches.count,
                processingTime: processingTime,
                chunkSize: chunk.content.utf8.count
            )
        )
    }

    /// Process text replacement for a single chunk
    private func processChunkReplacement(
        _ chunk: StreamingTextChunk,
        index: Int,
        replacements: [String: String],
        context: MCPExecutionContext
    ) async throws -> ProcessedChunk {
        var processedContent = chunk.content
        var replacementCount = 0

        for (pattern, replacement) in replacements {
            let regex = try await patternCache.getPattern(pattern)
            let matches = regex.matches(in: processedContent, range: NSRange(processedContent.startIndex..<processedContent.endIndex, in: processedContent))

            // Apply replacements in reverse order to maintain offsets
            for match in matches.reversed() {
                if let range = Range(match.range, in: processedContent) {
                    processedContent.replaceSubrange(range, with: replacement)
                    replacementCount += 1
                }
            }
        }

        return ProcessedChunk(
            originalChunk: chunk,
            processedContent: processedContent,
            replacementCount: replacementCount
        )
    }

    /// Process small replacement without streaming
    private func processSmallReplacement(
        _ text: String,
        replacements: [String: String],
        context: MCPExecutionContext
    ) async throws -> StringProcessingResult {
        let startTime = Date()
        var processedText = text
        var totalReplacements = 0

        for (pattern, replacement) in replacements {
            let regex = try await patternCache.getPattern(pattern)
            let matches = regex.matches(in: processedText, range: NSRange(processedText.startIndex..<processedText.endIndex, in: processedText))

            for match in matches.reversed() {
                if let range = Range(match.range, in: processedText) {
                    processedText.replaceSubrange(range, with: replacement)
                    totalReplacements += 1
                }
            }
        }

        let processingTime = Date().timeIntervalSince(startTime)

        return StringProcessingResult(
            processedText: processedText,
            replacementCount: totalReplacements,
            processingTime: processingTime,
            textSize: text.utf8.count,
            chunkCount: 1,
            usedStreaming: false
        )
    }

    /// Create overlapping chunks from text
    private func createChunks(from text: String) -> [StreamingTextChunk] {
        var chunks: [StreamingTextChunk] = []
        let textLength = text.utf8.count

        var offset = 0
        var chunkIndex = 0

        while offset < textLength {
            let chunkEnd = min(offset + configuration.chunkSize, textLength)
            let actualChunkSize = chunkEnd - offset

            // Calculate overlap for non-last chunks
            let overlapEnd = chunkEnd < textLength ?
                min(chunkEnd + configuration.overlapSize, textLength) : chunkEnd

            let chunkStartIndex = text.index(text.startIndex, offsetBy: offset)
            let chunkEndIndex = text.index(text.startIndex, offsetBy: overlapEnd)
            let chunkContent = String(text[chunkStartIndex..<chunkEndIndex])

            chunks.append(StreamingTextChunk(
                index: chunkIndex,
                content: chunkContent,
                globalOffset: offset,
                size: actualChunkSize,
                overlapSize: overlapEnd - chunkEnd
            ))

            offset = chunkEnd
            chunkIndex += 1
        }

        return chunks
    }

    /// Merge overlapping matches from different chunks
    private func mergeOverlappingMatches(_ matches: [TextMatch]) -> [TextMatch] {
        guard !matches.isEmpty else { return [] }

        // Sort by range location
        let sortedMatches = matches.sorted { $0.range.location < $1.range.location }
        var mergedMatches: [TextMatch] = []
        var currentMatch = sortedMatches.first!

        for match in sortedMatches.dropFirst() {
            let currentEnd = currentMatch.range.location + currentMatch.range.length
            let nextStart = match.range.location

            // Check for overlap
            if nextStart <= currentEnd {
                // Merge matches
                let newEnd = max(currentEnd, match.range.location + match.range.length)
                currentMatch = TextMatch(
                    pattern: currentMatch.pattern,
                    matchedText: currentMatch.matchedText + match.matchedText,
                    range: NSRange(location: currentMatch.range.location, length: newEnd - currentMatch.range.location),
                    confidence: max(currentMatch.confidence, match.confidence)
                )
            } else {
                mergedMatches.append(currentMatch)
                currentMatch = match
            }
        }

        mergedMatches.append(currentMatch)
        return mergedMatches
    }

    /// Reconstruct text from processed chunks
    private func reconstructText(from chunks: [ProcessedChunk]) -> String {
        guard !chunks.isEmpty else { return "" }

        var result = chunks.first!.processedContent

        for i in 1..<chunks.count {
            let currentChunk = chunks[i]

            // Remove overlap from current chunk
            let overlapStart = currentChunk.originalChunk.overlapSize
            if overlapStart < currentChunk.processedContent.utf8.count {
                let startIndex = currentChunk.processedContent.index(currentChunk.processedContent.startIndex, offsetBy: overlapStart)
                result += String(currentChunk.processedContent[startIndex...])
            }
        }

        return result
    }

    /// Static helper for processing chunks in concurrent tasks
    private static func processChunkConcurrently(
        _ chunk: StreamingTextChunk,
        index: Int,
        patterns: [String],
        context: MCPExecutionContext,
        patternCache: PatternCache
    ) async -> ChunkResult {
        let startTime = Date()
        var matches: [TextMatch] = []

        for pattern in patterns {
            do {
                let regex = try await patternCache.getPattern(pattern)
                let range = NSRange(chunk.content.startIndex..<chunk.content.endIndex, in: chunk.content)

                let patternMatches = regex.matches(in: chunk.content, range: range)
                for match in patternMatches {
                    if let range = Range(match.range, in: chunk.content) {
                        let matchedText = String(chunk.content[range])
                        let globalRange = NSRange(
                            location: chunk.globalOffset + match.range.location,
                            length: match.range.length
                        )

                        matches.append(TextMatch(
                            pattern: pattern,
                            matchedText: matchedText,
                            range: globalRange,
                            confidence: calculateConfidenceStatic(matchedText, pattern: pattern)
                        ))
                    }
                }
            } catch {
                // Continue processing other patterns on error
                continue
            }
        }

        let processingTime = Date().timeIntervalSince(startTime)
        let stats = ProcessingStats(
            matchCount: matches.count,
            processingTime: processingTime,
            chunkSize: chunk.content.utf8.count
        )

        return ChunkResult(chunkIndex: index, matches: matches, stats: stats)
    }
    
    /// Static version of confidence calculation
    private static func calculateConfidenceStatic(_ matchedText: String, pattern: String) -> Double {
        // Simple confidence calculation based on pattern complexity and match characteristics
        let baseConfidence: Double = 0.8

        // Adjust based on pattern complexity
        let complexityBonus = Double(pattern.count) / 100.0

        // Adjust based on match length
        let lengthBonus = Double(matchedText.count) / 50.0

        return min(baseConfidence + complexityBonus + lengthBonus, 1.0)
    }

    /// Calculate confidence score for a match
    private func calculateConfidence(_ matchedText: String, pattern: String) -> Double {
        // Simple confidence calculation based on pattern complexity and match characteristics
        let baseConfidence: Double = 0.8

        // Adjust based on pattern complexity
        let complexityBonus = Double(pattern.count) / 100.0

        // Adjust based on match length
        let lengthBonus = Double(matchedText.count) / 50.0

        return min(1.0, baseConfidence + complexityBonus + lengthBonus)
    }
}

// MARK: - Data Structures

/// Represents a chunk of text for streaming processing
public struct StreamingTextChunk: Sendable {
    public let index: Int
    public let content: String
    public let globalOffset: Int
    public let size: Int
    public let overlapSize: Int
}

/// Represents a text match found during processing
public struct TextMatch: Sendable {
    public let pattern: String
    public let matchedText: String
    public let range: NSRange
    public let confidence: Double
}

/// Result of processing a single chunk
private struct ChunkResult: Sendable {
    let chunkIndex: Int
    let matches: [TextMatch]
    let stats: ProcessingStats
}

/// Result of processing a chunk for replacement
private struct ProcessedChunk {
    let originalChunk: StreamingTextChunk
    let processedContent: String
    let replacementCount: Int
}

/// Processing statistics
public struct ProcessingStats: Sendable {
    public var matchCount: Int
    public var processingTime: TimeInterval
    public var chunkSize: Int

    public init(matchCount: Int = 0, processingTime: TimeInterval = 0, chunkSize: Int = 0) {
        self.matchCount = matchCount
        self.processingTime = processingTime
        self.chunkSize = chunkSize
    }

    public mutating func merge(with other: ProcessingStats) {
        self.matchCount += other.matchCount
        self.processingTime += other.processingTime
        self.chunkSize = max(self.chunkSize, other.chunkSize)
    }
}

/// Result of streaming text processing
public struct StreamProcessingResult: Sendable {
    public let matches: [TextMatch]
    public let stats: ProcessingStats
    public let processingTime: TimeInterval
    public let textSize: Int
    public let chunkCount: Int
    public let usedStreaming: Bool
}

/// Result of string processing with replacements
public struct StringProcessingResult: Sendable {
    public let processedText: String
    public let replacementCount: Int
    public let processingTime: TimeInterval
    public let textSize: Int
    public let chunkCount: Int
    public let usedStreaming: Bool
}