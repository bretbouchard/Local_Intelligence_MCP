//
//  TextChunkingTool.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-08.
//

import Foundation

/// Text Chunking Tool for Audio Domain Content
///
/// Implements apple.text.chunk specification:
/// - Intelligently chunks long audio texts while preserving context and meaning
/// - Multiple chunking strategies optimized for different audio content types
/// - Audio domain-aware chunking that respects session structure and technical terms
/// - Configurable chunk sizes with overlap for context preservation
/// - Metadata tracking for chunk relationships and content type detection
///
/// Use Cases:
/// - Processing long transcripts for AI analysis or summarization
/// - Breaking down session notes for documentation or sharing
/// - Preparing content for translation or localization workflows
/// - Creating manageable segments for review or collaboration
/// - Feeding content to language models with token limits
///
/// Performance Requirements:
/// - Execution: <100ms for 5000 words with intelligent chunking
/// - Memory: <5MB for text processing and chunk management
/// - Concurrency: Thread-safe for multiple simultaneous operations
/// - Audio domain: Enhanced detection of audio-specific content boundaries
public final class TextChunkingTool: AudioDomainTool, @unchecked Sendable {

    // No property overrides needed - values passed to super init

    // MARK: - Chunking Strategies

    /// Supported chunking strategies
    public enum ChunkingStrategy: String, CaseIterable {
        case sentence = "sentence"
        case paragraph = "paragraph"
        case semantic = "semantic"
        case audioSession = "audio_session"
        case fixed = "fixed"

        var description: String {
            switch self {
            case .sentence: return "Chunk by sentence boundaries, preserving complete sentences"
            case .paragraph: return "Chunk by paragraph boundaries, preserving complete paragraphs"
            case .semantic: return "Intelligent chunking based on semantic content and topic changes"
            case .audioSession: return "Audio-aware chunking that respects session structure (recording, mixing, etc.)"
            case .fixed: return "Fixed-size chunks with configurable overlap for context"
            }
        }
    }

    // MARK: - Initialization

    public init(logger: Logger, securityManager: SecurityManager) {
        super.init(
            name: "apple_text_chunk",
            description: "Intelligently chunks long audio texts while preserving context, session structure, and technical terms.",
            inputSchema: [
                "type": AnyCodable("object"),
                "properties": AnyCodable([
                    "text": AnyCodable([
                        "type": AnyCodable("string"),
                        "description": AnyCodable("Long audio session notes, transcripts, or documentation to chunk"),
                        "minLength": AnyCodable(100)
                    ]),
                    "strategy": AnyCodable([
                        "type": AnyCodable("string"),
                        "description": AnyCodable("Chunking strategy to use for segmenting the text"),
                        "enum": AnyCodable(ChunkingStrategy.allCases.map(\.rawValue)),
                        "default": AnyCodable(ChunkingStrategy.semantic.rawValue)
                    ]),
                    "max_chunk_size": AnyCodable([
                        "type": AnyCodable("integer"),
                        "description": AnyCodable("Maximum chunk size in words (varies by strategy)"),
                        "minimum": AnyCodable(50),
                        "maximum": AnyCodable(2000),
                        "default": AnyCodable(300)
                    ]),
                    "overlap": AnyCodable([
                        "type": AnyCodable("integer"),
                        "description": AnyCodable("Overlap size in words between consecutive chunks for context preservation"),
                        "minimum": AnyCodable(0),
                        "maximum": AnyCodable(100),
                        "default": AnyCodable(25)
                    ]),
                    "preserve_audio_structure": AnyCodable([
                        "type": AnyCodable("boolean"),
                        "description": AnyCodable("Preserve audio session structure (recording/mixing/mastering sections)"),
                        "default": AnyCodable(true)
                    ]),
                    "include_metadata": AnyCodable([
                        "type": AnyCodable("boolean"),
                        "description": AnyCodable("Include metadata about chunk content and relationships"),
                        "default": AnyCodable(true)
                    ]),
                    "min_chunk_size": AnyCodable([
                        "type": AnyCodable("integer"),
                        "description": AnyCodable("Minimum chunk size in words (varies by strategy)"),
                        "minimum": AnyCodable(10),
                        "maximum": AnyCodable(200),
                        "default": AnyCodable(30)
                    ])
                ]),
                "required": AnyCodable(["text"])
            ],
            logger: logger,
            securityManager: securityManager
        )
    }

    // MARK: - Audio Processing

    /// Chunks text according to specified strategy and parameters
    public override func processAudioContent(_ content: String, with parameters: [String: Any]) async throws -> String {
        guard let text = parameters["text"] as? String else {
            throw AudioProcessingError.invalidInput("text parameter is required")
        }

        // Parse chunking strategy
        let strategyString = parameters["strategy"] as? String ?? ChunkingStrategy.semantic.rawValue
        guard let strategy = ChunkingStrategy(rawValue: strategyString.lowercased()) else {
            throw AudioProcessingError.invalidInput("Invalid chunking strategy: \(strategyString)")
        }

        // Parse parameters
        let maxChunkSize = min(max(50, parameters["max_chunk_size"] as? Int ?? 300), 2000)
        let overlap = min(max(0, parameters["overlap"] as? Int ?? 25), 100)
        let preserveAudioStructure = parameters["preserve_audio_structure"] as? Bool ?? true
        let includeMetadata = parameters["include_metadata"] as? Bool ?? true
        let minChunkSize = min(max(10, parameters["min_chunk_size"] as? Int ?? 30), 200)

        // Pre-security check
        try await performSecurityCheck(text)

        // Apply chunking strategy
        let chunkingResult = try await chunkText(
            text: text,
            strategy: strategy,
            maxChunkSize: maxChunkSize,
            overlap: overlap,
            preserveAudioStructure: preserveAudioStructure,
            includeMetadata: includeMetadata,
            minChunkSize: minChunkSize
        )

        // Post-security validation
        try await validateOutput(chunkingResult.chunks)

        return formatChunksAsText(chunkingResult.chunks)
    }

    // MARK: - Private Implementation

    /// Result structure for text chunking
    private struct TextChunkingResult {
        let chunks: [TextChunk]
        let metadata: [String: Any]
    }

    /// Text chunk structure
    private struct TextChunk {
        let id: String
        let text: String
        let wordCount: Int
        let startIndex: Int
        let endIndex: Int
        let metadata: [String: Any]
    }

    /// Apply chunking strategy to text
    private func chunkText(
        text: String,
        strategy: ChunkingStrategy,
        maxChunkSize: Int,
        overlap: Int,
        preserveAudioStructure: Bool,
        includeMetadata: Bool,
        minChunkSize: Int
    ) async throws -> TextChunkingResult {

        var chunks: [TextChunk] = []

        switch strategy {
        case .sentence:
            chunks = try await chunkBySentence(
                text: text,
                maxChunkSize: maxChunkSize,
                overlap: overlap,
                minChunkSize: minChunkSize,
                preserveAudioStructure: preserveAudioStructure
            )
        case .paragraph:
            chunks = try await chunkByParagraph(
                text: text,
                maxChunkSize: maxChunkSize,
                overlap: overlap,
                minChunkSize: minChunkSize,
                preserveAudioStructure: preserveAudioStructure
            )
        case .semantic:
            chunks = try await chunkBySemantic(
                text: text,
                maxChunkSize: maxChunkSize,
                overlap: overlap,
                minChunkSize: minChunkSize,
                preserveAudioStructure: preserveAudioStructure
            )
        case .audioSession:
            chunks = try await chunkByAudioSession(
                text: text,
                maxChunkSize: maxChunkSize,
                overlap: overlap,
                minChunkSize: minChunkSize
            )
        case .fixed:
            chunks = try await chunkByFixedSize(
                text: text,
                maxChunkSize: maxChunkSize,
                overlap: overlap,
                preserveAudioStructure: preserveAudioStructure
            )
        }

        // Build metadata
        let metadata = buildChunkingMetadata(
            chunks: chunks,
            strategy: strategy,
            originalText: text,
            includeMetadata: includeMetadata
        )

        return TextChunkingResult(chunks: chunks, metadata: metadata)
    }

    /// Chunk text by sentence boundaries
    private func chunkBySentence(
        text: String,
        maxChunkSize: Int,
        overlap: Int,
        minChunkSize: Int,
        preserveAudioStructure: Bool
    ) async throws -> [TextChunk] {

        let sentences = extractSentences(from: text, preserveAudioStructure: preserveAudioStructure)
        var chunks: [TextChunk] = []
        var currentChunkSentences: [String] = []
        var currentWordCount = 0
        var chunkIndex = 0

        for (index, sentence) in sentences.enumerated() {
            let sentenceWordCount = sentence.split(separator: " ").count

            // Check if adding this sentence would exceed max chunk size
            if currentWordCount + sentenceWordCount > maxChunkSize && !currentChunkSentences.isEmpty {
                // Create chunk from accumulated sentences
                let chunkText = currentChunkSentences.joined(separator: " ")
                let startIndex = getChunkStartIndex(chunks: chunks, sentences: sentences, currentIndex: index - currentChunkSentences.count)
                let endIndex = startIndex + chunkText.count

                let chunk = TextChunk(
                    id: "chunk_\(chunkIndex)",
                    text: chunkText,
                    wordCount: currentWordCount,
                    startIndex: startIndex,
                    endIndex: endIndex,
                    metadata: buildChunkMetadata(
                        text: chunkText,
                        chunkIndex: chunkIndex,
                        strategy: .sentence,
                        audioContent: detectAudioContent(in: chunkText)
                    )
                )
                chunks.append(chunk)
                chunkIndex += 1

                // Start new chunk with overlap if needed
                currentChunkSentences = createOverlapSentences(
                    from: currentChunkSentences,
                    overlap,
                    targetWordCount: overlap
                )
                currentWordCount = currentChunkSentences.joined(separator: " ").split(separator: " ").count
            }

            // Add current sentence
            currentChunkSentences.append(sentence)
            currentWordCount += sentenceWordCount
        }

        // Add final chunk if there are remaining sentences
        if !currentChunkSentences.isEmpty && currentWordCount >= minChunkSize {
            let chunkText = currentChunkSentences.joined(separator: " ")
            let startIndex = getChunkStartIndex(chunks: chunks, sentences: sentences, currentIndex: sentences.count - currentChunkSentences.count)
            let endIndex = startIndex + chunkText.count

            let chunk = TextChunk(
                id: "chunk_\(chunkIndex)",
                text: chunkText,
                wordCount: currentWordCount,
                startIndex: startIndex,
                endIndex: endIndex,
                metadata: buildChunkMetadata(
                    text: chunkText,
                    chunkIndex: chunkIndex,
                    strategy: .sentence,
                    audioContent: detectAudioContent(in: chunkText)
                )
            )
            chunks.append(chunk)
        }

        return chunks
    }

    /// Chunk text by paragraph boundaries
    private func chunkByParagraph(
        text: String,
        maxChunkSize: Int,
        overlap: Int,
        minChunkSize: Int,
        preserveAudioStructure: Bool
    ) async throws -> [TextChunk] {

        let paragraphs = extractParagraphs(from: text, preserveAudioStructure: preserveAudioStructure)
        var chunks: [TextChunk] = []
        var currentChunkParagraphs: [String] = []
        var currentWordCount = 0
        var chunkIndex = 0

        for (index, paragraph) in paragraphs.enumerated() {
            let paragraphWordCount = paragraph.split(separator: " ").count

            // Handle paragraphs that are too long by themselves
            if paragraphWordCount > maxChunkSize {
                // Save current chunk if it has content
                if !currentChunkParagraphs.isEmpty {
                    let chunkText = currentChunkParagraphs.joined(separator: "\n\n")
                    let chunk = createChunk(
                        text: chunkText,
                        index: chunkIndex,
                        strategy: .paragraph,
                        startIndex: getChunkStartIndex(chunks: chunks, paragraphs: paragraphs, currentIndex: index - currentChunkParagraphs.count)
                    )
                    chunks.append(chunk)
                    chunkIndex += 1
                    currentChunkParagraphs = []
                    currentWordCount = 0
                }

                // Recursively chunk the long paragraph
                let subChunks = try await chunkBySentence(
                    text: paragraph,
                    maxChunkSize: maxChunkSize,
                    overlap: overlap,
                    minChunkSize: minChunkSize,
                    preserveAudioStructure: preserveAudioStructure
                )

                for subChunk in subChunks {
                    let adaptedChunk = TextChunk(
                        id: "chunk_\(chunkIndex)",
                        text: subChunk.text,
                        wordCount: subChunk.wordCount,
                        startIndex: subChunk.startIndex,
                        endIndex: subChunk.endIndex,
                        metadata: buildChunkMetadata(
                            text: subChunk.text,
                            chunkIndex: chunkIndex,
                            strategy: .paragraph,
                            audioContent: detectAudioContent(in: subChunk.text)
                        )
                    )
                    chunks.append(adaptedChunk)
                    chunkIndex += 1
                }
                continue
            }

            // Check if adding this paragraph would exceed max chunk size
            if currentWordCount + paragraphWordCount > maxChunkSize && !currentChunkParagraphs.isEmpty {
                let chunkText = currentChunkParagraphs.joined(separator: "\n\n")
                let startIndex = getChunkStartIndex(chunks: chunks, paragraphs: paragraphs, currentIndex: index - currentChunkParagraphs.count)

                let chunk = TextChunk(
                    id: "chunk_\(chunkIndex)",
                    text: chunkText,
                    wordCount: currentWordCount,
                    startIndex: startIndex,
                    endIndex: startIndex + chunkText.count,
                    metadata: buildChunkMetadata(
                        text: chunkText,
                        chunkIndex: chunkIndex,
                        strategy: .paragraph,
                        audioContent: detectAudioContent(in: chunkText)
                    )
                )
                chunks.append(chunk)
                chunkIndex += 1

                // Start new chunk with overlap
                currentChunkParagraphs = createOverlapParagraphs(
                    from: currentChunkParagraphs,
                    overlap,
                    targetWordCount: overlap
                )
                currentWordCount = currentChunkParagraphs.joined(separator: "\n\n").split(separator: " ").count
            }

            // Add current paragraph
            currentChunkParagraphs.append(paragraph)
            currentWordCount += paragraphWordCount
        }

        // Add final chunk
        if !currentChunkParagraphs.isEmpty && currentWordCount >= minChunkSize {
            let chunkText = currentChunkParagraphs.joined(separator: "\n\n")
            let startIndex = getChunkStartIndex(chunks: chunks, paragraphs: paragraphs, currentIndex: paragraphs.count - currentChunkParagraphs.count)

            let chunk = TextChunk(
                id: "chunk_\(chunkIndex)",
                text: chunkText,
                wordCount: currentWordCount,
                startIndex: startIndex,
                endIndex: startIndex + chunkText.count,
                metadata: buildChunkMetadata(
                    text: chunkText,
                    chunkIndex: chunkIndex,
                    strategy: .paragraph,
                    audioContent: detectAudioContent(in: chunkText)
                )
            )
            chunks.append(chunk)
        }

        return chunks
    }

    /// Chunk text by semantic content
    private func chunkBySemantic(
        text: String,
        maxChunkSize: Int,
        overlap: Int,
        minChunkSize: Int,
        preserveAudioStructure: Bool
    ) async throws -> [TextChunk] {

        // Extract semantic segments based on topic changes and audio structure
        let segments = extractSemanticSegments(from: text, preserveAudioStructure: preserveAudioStructure)
        var chunks: [TextChunk] = []
        var currentSegmentGroup: [String] = []
        var currentWordCount = 0
        var chunkIndex = 0

        for (index, segment) in segments.enumerated() {
            let segmentWordCount = segment.split(separator: " ").count

            // Handle segments that are too long
            if segmentWordCount > maxChunkSize {
                // Save current chunk if it has content
                if !currentSegmentGroup.isEmpty {
                    let chunkText = currentSegmentGroup.joined(separator: " ")
                    let chunk = createChunk(
                        text: chunkText,
                        index: chunkIndex,
                        strategy: .semantic,
                        startIndex: getChunkStartIndex(chunks: chunks, segments: segments, currentIndex: index - currentSegmentGroup.count)
                    )
                    chunks.append(chunk)
                    chunkIndex += 1
                    currentSegmentGroup = []
                    currentWordCount = 0
                }

                // Break down long segment using sentence chunking
                let subChunks = try await chunkBySentence(
                    text: segment,
                    maxChunkSize: maxChunkSize,
                    overlap: overlap,
                    minChunkSize: minChunkSize,
                    preserveAudioStructure: preserveAudioStructure
                )

                for subChunk in subChunks {
                    let adaptedChunk = TextChunk(
                        id: "chunk_\(chunkIndex)",
                        text: subChunk.text,
                        wordCount: subChunk.wordCount,
                        startIndex: subChunk.startIndex,
                        endIndex: subChunk.endIndex,
                        metadata: buildChunkMetadata(
                            text: subChunk.text,
                            chunkIndex: chunkIndex,
                            strategy: .semantic,
                            audioContent: detectAudioContent(in: subChunk.text)
                        )
                    )
                    chunks.append(adaptedChunk)
                    chunkIndex += 1
                }
                continue
            }

            // Check if adding this segment would exceed max chunk size or create semantic break
            let wouldExceedSize = currentWordCount + segmentWordCount > maxChunkSize && !currentSegmentGroup.isEmpty
            let semanticBreak = wouldExceedSize || (currentSegmentGroup.count > 0 && createsSemanticBreak(currentSegmentGroup.last!, segment))

            if semanticBreak && !currentSegmentGroup.isEmpty {
                let chunkText = currentSegmentGroup.joined(separator: " ")
                let startIndex = getChunkStartIndex(chunks: chunks, segments: segments, currentIndex: index - currentSegmentGroup.count)

                let chunk = TextChunk(
                    id: "chunk_\(chunkIndex)",
                    text: chunkText,
                    wordCount: currentWordCount,
                    startIndex: startIndex,
                    endIndex: startIndex + chunkText.count,
                    metadata: buildChunkMetadata(
                        text: chunkText,
                        chunkIndex: chunkIndex,
                        strategy: .semantic,
                        audioContent: detectAudioContent(in: chunkText)
                    )
                )
                chunks.append(chunk)
                chunkIndex += 1

                // Start new chunk with overlap
                currentSegmentGroup = createOverlapSegments(
                    from: currentSegmentGroup,
                    overlap,
                    targetWordCount: overlap
                )
                currentWordCount = currentSegmentGroup.joined(separator: " ").split(separator: " ").count
            }

            // Add current segment
            currentSegmentGroup.append(segment)
            currentWordCount += segmentWordCount
        }

        // Add final chunk
        if !currentSegmentGroup.isEmpty && currentWordCount >= minChunkSize {
            let chunkText = currentSegmentGroup.joined(separator: " ")
            let startIndex = getChunkStartIndex(chunks: chunks, segments: segments, currentIndex: segments.count - currentSegmentGroup.count)

            let chunk = TextChunk(
                id: "chunk_\(chunkIndex)",
                text: chunkText,
                wordCount: currentWordCount,
                startIndex: startIndex,
                endIndex: startIndex + chunkText.count,
                metadata: buildChunkMetadata(
                    text: chunkText,
                    chunkIndex: chunkIndex,
                    strategy: .semantic,
                    audioContent: detectAudioContent(in: chunkText)
                )
            )
            chunks.append(chunk)
        }

        return chunks
    }

    /// Chunk text by audio session structure
    private func chunkByAudioSession(
        text: String,
        maxChunkSize: Int,
        overlap: Int,
        minChunkSize: Int
    ) async throws -> [TextChunk] {

        let sessionSections = extractAudioSessionSections(from: text)
        var chunks: [TextChunk] = []
        var chunkIndex = 0

        for (_, section) in sessionSections.enumerated() {
            let sectionWordCount = section.content.split(separator: " ").count

            if sectionWordCount <= maxChunkSize {
                // Section fits in one chunk
                let chunk = TextChunk(
                    id: "chunk_\(chunkIndex)",
                    text: section.content,
                    wordCount: sectionWordCount,
                    startIndex: section.startIndex,
                    endIndex: section.endIndex,
                    metadata: buildAudioSessionChunkMetadata(
                        content: section.content,
                        chunkIndex: chunkIndex,
                        sectionType: section.type,
                        sectionTitle: section.title
                    )
                )
                chunks.append(chunk)
                chunkIndex += 1
            } else {
                // Section is too large, break it down further
                let subChunks = try await chunkBySemantic(
                    text: section.content,
                    maxChunkSize: maxChunkSize,
                    overlap: overlap,
                    minChunkSize: minChunkSize,
                    preserveAudioStructure: true
                )

                for (subIndex, subChunk) in subChunks.enumerated() {
                    let adaptedChunk = TextChunk(
                        id: "chunk_\(chunkIndex)",
                        text: subChunk.text,
                        wordCount: subChunk.wordCount,
                        startIndex: section.startIndex + subChunk.startIndex,
                        endIndex: section.startIndex + subChunk.endIndex,
                        metadata: buildAudioSessionChunkMetadata(
                            content: subChunk.text,
                            chunkIndex: chunkIndex,
                            sectionType: section.type,
                            sectionTitle: "\(section.title) - Part \(subIndex + 1)",
                            parentSection: section.title
                        )
                    )
                    chunks.append(adaptedChunk)
                    chunkIndex += 1
                }
            }
        }

        return chunks
    }

    /// Chunk text by fixed size with overlap
    private func chunkByFixedSize(
        text: String,
        maxChunkSize: Int,
        overlap: Int,
        preserveAudioStructure: Bool
    ) async throws -> [TextChunk] {

        let words = text.split(separator: " ")
        var chunks: [TextChunk] = []
        var chunkIndex = 0
        var currentIndex = 0

        while currentIndex < words.count {
            let endIndex = min(currentIndex + maxChunkSize, words.count)
            let chunkWords = Array(words[currentIndex..<endIndex])

            // Try to end at sentence boundary if preserving audio structure
            let adjustedEndIndex = preserveAudioStructure ?
                findSentenceBoundary(in: chunkWords, originalText: text, startIndex: currentIndex) : endIndex

            let finalChunkWords = Array(words[currentIndex..<adjustedEndIndex])
            let finalChunkText = finalChunkWords.joined(separator: " ")

            let chunk = TextChunk(
                id: "chunk_\(chunkIndex)",
                text: finalChunkText,
                wordCount: finalChunkWords.count,
                startIndex: words[..<currentIndex].joined(separator: " ").count,
                endIndex: words[..<adjustedEndIndex].joined(separator: " ").count,
                metadata: buildChunkMetadata(
                    text: finalChunkText,
                    chunkIndex: chunkIndex,
                    strategy: .fixed,
                    audioContent: detectAudioContent(in: finalChunkText)
                )
            )
            chunks.append(chunk)

            // Move to next chunk with overlap
            currentIndex = max(currentIndex + 1, adjustedEndIndex - overlap)
            chunkIndex += 1
        }

        return chunks
    }

    // MARK: - Helper Methods

    /// Extract sentences from text while preserving audio structure
    private func extractSentences(from text: String, preserveAudioStructure: Bool) -> [String] {
        if preserveAudioStructure {
            // Split by common sentence endings but preserve audio-specific formatting
            let patterns = [
                #"(?<=[.!?])\s+(?=[A-Z])"#,  // Standard sentence boundaries
                #"(?<=[.!?])\s*\n\s*(?=[A-Z0-9])"#,  // Cross-line sentences
                #"(?<=:)\s*\n\s*"#  // Audio session structure (setup:, recording:, etc.)
            ]

            var sentences = [text]
            for pattern in patterns {
                var newSentences: [String] = []
                for sentence in sentences {
                    let parts = sentence.components(separatedBy: pattern)
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }
                    newSentences.append(contentsOf: parts)
                }
                sentences = newSentences
            }
            return sentences
        } else {
            // Simple sentence splitting
            return text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }
    }

    /// Extract paragraphs from text
    private func extractParagraphs(from text: String, preserveAudioStructure: Bool) -> [String] {
        return text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    /// Extract semantic segments from text
    private func extractSemanticSegments(from text: String, preserveAudioStructure: Bool) -> [String] {
        var segments: [String] = []

        if preserveAudioStructure {
            // Look for audio session transitions
            let audioTransitionPatterns = [
                #"(?i)(?:setup|recording|mixing|mastering|editing):"#,
                #"(?i)(?:take \d+|track \d+):"#,
                #"(?i)(?:microphone|mic|preamp|eq|compression|reverb):"#
            ]

            let regex = try? NSRegularExpression(pattern: audioTransitionPatterns.joined(separator: "|"), options: [])
            let fullTextRange = NSRange(location: 0, length: text.count)
            let matches = regex?.matches(in: text, options: [], range: fullTextRange) ?? []

            if matches.isEmpty {
                // No audio transitions found, use paragraph-based segmentation
                segments = extractParagraphs(from: text, preserveAudioStructure: false)
            } else {
                // Split at audio transition points
                var lastIndex = 0
                let nsString = text as NSString

                for match in matches {
                    let range = match.range
                    if range.location > lastIndex {
                        let segment = nsString.substring(with: NSRange(location: lastIndex, length: range.location - lastIndex))
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                        if !segment.isEmpty {
                            segments.append(segment)
                        }
                    }
                    lastIndex = range.location
                }

                // Add final segment
                if lastIndex < nsString.length {
                    let finalSegment = nsString.substring(from: lastIndex)
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    if !finalSegment.isEmpty {
                        segments.append(finalSegment)
                    }
                }
            }
        } else {
            // Use paragraph-based semantic segmentation
            segments = extractParagraphs(from: text, preserveAudioStructure: false)
        }

        return segments.isEmpty ? [text] : segments
    }

    /// Audio session section structure
    private struct AudioSessionSection {
        let type: String
        let title: String
        let content: String
        let startIndex: Int
        let endIndex: Int
    }

    /// Extract audio session sections
    private func extractAudioSessionSections(from text: String) -> [AudioSessionSection] {
        var sections: [AudioSessionSection] = []

        // Define patterns for different audio session sections
        let sectionPatterns = [
            ("setup", #"(?i)(?:setup|preparation|equipment):"#),
            ("recording", #"(?i)(?:recording|tracking|takes?):"#),
            ("mixing", #"(?i)(?:mixing|mix|balance):"#),
            ("mastering", #"(?i)(?:mastering|master|final):"#),
            ("editing", #"(?i)(?:editing|edit|comp):"#),
            ("notes", #"(?i)(?:notes|comments|observations):"#)
        ]

        let nsString = text as NSString
        var currentIndex = 0

        for (sectionType, pattern) in sectionPatterns {
            let regex = try? NSRegularExpression(pattern: pattern, options: [])
            let searchRange = NSRange(location: currentIndex, length: nsString.length - currentIndex)
            let matches = regex?.matches(in: text, options: [], range: searchRange) ?? []

            for match in matches {
                let matchRange = match.range

                // Extract section title
                let titleEnd = nsString.range(of: ":", range: matchRange).location
                let title = nsString.substring(with: NSRange(location: matchRange.location, length: titleEnd - matchRange.location + 1))

                // Find section end (next section or end of text)
                let nextSectionStart = findNextSectionStart(in: text, from: matchRange.location + matchRange.length)
                let contentEnd = nextSectionStart ?? nsString.length

                // Extract content
                let contentStart = matchRange.location + matchRange.length
                let content = nsString.substring(with: NSRange(location: contentStart, length: contentEnd - contentStart))
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                let section = AudioSessionSection(
                    type: sectionType,
                    title: title,
                    content: content,
                    startIndex: contentStart,
                    endIndex: contentEnd
                )
                sections.append(section)

                currentIndex = contentEnd
            }
        }

        // If no structured sections found, treat entire text as one section
        if sections.isEmpty {
            sections.append(AudioSessionSection(
                type: "general",
                title: "Session Notes",
                content: text,
                startIndex: 0,
                endIndex: text.count
            ))
        }

        return sections
    }

    /// Find the start of the next section
    private func findNextSectionStart(in text: String, from startIndex: Int) -> Int? {
        let sectionPattern = #"(?i)(?:setup|recording|mixing|mastering|editing|notes):"#
        let regex = try? NSRegularExpression(pattern: sectionPattern, options: [])

        let searchRange = NSRange(location: startIndex, length: text.count - startIndex)
        let matches = regex?.matches(in: text, options: [], range: searchRange)

        return matches?.first?.range.location
    }

    /// Create overlap sentences for context preservation
    private func createOverlapSentences(from sentences: [String], _: Int, targetWordCount: Int) -> [String] {
        guard !sentences.isEmpty && targetWordCount > 0 else { return [] }

        var overlapSentences: [String] = []
        var currentWordCount = 0

        // Take sentences from the end, working backwards
        for sentence in sentences.reversed() {
            let sentenceWordCount = sentence.split(separator: " ").count
            if currentWordCount + sentenceWordCount <= targetWordCount {
                overlapSentences.insert(sentence, at: 0)
                currentWordCount += sentenceWordCount
            } else {
                break
            }
        }

        return overlapSentences
    }

    /// Create overlap paragraphs
    private func createOverlapParagraphs(from paragraphs: [String], _: Int, targetWordCount: Int) -> [String] {
        guard !paragraphs.isEmpty && targetWordCount > 0 else { return [] }

        var overlapParagraphs: [String] = []
        var currentWordCount = 0

        for paragraph in paragraphs.reversed() {
            let paragraphWordCount = paragraph.split(separator: " ").count
            if currentWordCount + paragraphWordCount <= targetWordCount {
                overlapParagraphs.insert(paragraph, at: 0)
                currentWordCount += paragraphWordCount
            } else {
                break
            }
        }

        return overlapParagraphs
    }

    /// Create overlap segments
    private func createOverlapSegments(from segments: [String], _: Int, targetWordCount: Int) -> [String] {
        guard !segments.isEmpty && targetWordCount > 0 else { return [] }

        var overlapSegments: [String] = []
        var currentWordCount = 0

        for segment in segments.reversed() {
            let segmentWordCount = segment.split(separator: " ").count
            if currentWordCount + segmentWordCount <= targetWordCount {
                overlapSegments.insert(segment, at: 0)
                currentWordCount += segmentWordCount
            } else {
                break
            }
        }

        return overlapSegments
    }

    /// Check if creating a semantic break between two segments
    private func createsSemanticBreak(_ segment1: String, _ segment2: String) -> Bool {
        // Check for topic changes
        let audioTopics1 = extractAudioTopics(from: segment1)
        let audioTopics2 = extractAudioTopics(from: segment2)

        // If topics are completely different, it's a semantic break
        let commonTopics = Set(audioTopics1).intersection(Set(audioTopics2))
        return commonTopics.isEmpty && (!audioTopics1.isEmpty || !audioTopics2.isEmpty)
    }

    /// Extract audio topics from text
    private func extractAudioTopics(from text: String) -> [String] {
        let audioKeywords = [
            "recording", "mixing", "mastering", "editing", "tracking",
            "microphone", "mic", "preamp", "eq", "compression", "reverb", "delay",
            "setup", "equipment", "studio", "session", "take", "track",
            "producer", "engineer", "artist", "musician", "vocal", "instrument"
        ]

        let lowercaseText = text.lowercased()
        return audioKeywords.filter { lowercaseText.contains($0) }
    }

    /// Find sentence boundary in chunk words
    private func findSentenceBoundary(in chunkWords: [Substring], originalText: String, startIndex: Int) -> Int {
        var bestEndIndex = chunkWords.count

        // Try to find the last sentence ending within the chunk
        for i in (0..<chunkWords.count).reversed() {
            let word = String(chunkWords[i])
            if word.hasSuffix(".") || word.hasSuffix("!") || word.hasSuffix("?") {
                bestEndIndex = i + 1
                break
            }
        }

        return bestEndIndex
    }

    /// Get chunk start index in original text
    private func getChunkStartIndex(chunks: [TextChunk], sentences: [String], currentIndex: Int) -> Int {
        guard !chunks.isEmpty else { return 0 }

        // Calculate based on accumulated text
        let precedingText = sentences[..<currentIndex].joined(separator: " ")
        return precedingText.count
    }

    /// Get chunk start index for paragraphs
    private func getChunkStartIndex(chunks: [TextChunk], paragraphs: [String], currentIndex: Int) -> Int {
        guard !chunks.isEmpty else { return 0 }

        let precedingText = paragraphs[..<currentIndex].joined(separator: "\n\n")
        return precedingText.count + (currentIndex > 0 ? (currentIndex - 1) * 2 : 0) // Account for newlines
    }

    /// Get chunk start index for segments
    private func getChunkStartIndex(chunks: [TextChunk], segments: [String], currentIndex: Int) -> Int {
        guard !chunks.isEmpty else { return 0 }

        let precedingText = segments[..<currentIndex].joined(separator: " ")
        return precedingText.count
    }

    /// Create a chunk with metadata
    private func createChunk(text: String, index: Int, strategy: ChunkingStrategy, startIndex: Int) -> TextChunk {
        return TextChunk(
            id: "chunk_\(index)",
            text: text,
            wordCount: text.split(separator: " ").count,
            startIndex: startIndex,
            endIndex: startIndex + text.count,
            metadata: buildChunkMetadata(
                text: text,
                chunkIndex: index,
                strategy: strategy,
                audioContent: detectAudioContent(in: text)
            )
        )
    }

    /// Build metadata for a chunk
    private func buildChunkMetadata(text: String, chunkIndex: Int, strategy: ChunkingStrategy, audioContent: [String]) -> [String: Any] {
        return [
            "chunk_index": chunkIndex,
            "strategy": strategy.rawValue,
            "word_count": text.split(separator: " ").count,
            "character_count": text.count,
            "audio_content": audioContent,
            "has_technical_terms": audioContent.contains("technical"),
            "has_session_structure": audioContent.contains("session_structure"),
            "content_type": detectContentType(text: text, audioContent: audioContent)
        ]
    }

    /// Build metadata for audio session chunk
    private func buildAudioSessionChunkMetadata(
        content: String,
        chunkIndex: Int,
        sectionType: String,
        sectionTitle: String,
        parentSection: String? = nil
    ) -> [String: Any] {
        var metadata = buildChunkMetadata(
            text: content,
            chunkIndex: chunkIndex,
            strategy: .audioSession,
            audioContent: detectAudioContent(in: content)
        )

        metadata["section_type"] = sectionType
        metadata["section_title"] = sectionTitle
        if let parentSection = parentSection {
            metadata["parent_section"] = parentSection
        }

        return metadata
    }

    /// Build overall chunking metadata
    private func buildChunkingMetadata(
        chunks: [TextChunk],
        strategy: ChunkingStrategy,
        originalText: String,
        includeMetadata: Bool
    ) -> [String: Any] {
        var metadata: [String: Any] = [
            "strategy": strategy.rawValue,
            "total_chunks": chunks.count,
            "original_word_count": originalText.split(separator: " ").count,
            "original_character_count": originalText.count,
            "processing_timestamp": ISO8601DateFormatter().string(from: Date())
        ]

        if includeMetadata {
            let chunkSummaries = chunks.map { chunk in
                [
                    "id": chunk.id,
                    "word_count": chunk.wordCount,
                    "character_count": chunk.text.count,
                    "start_index": chunk.startIndex,
                    "end_index": chunk.endIndex,
                    "metadata": chunk.metadata
                ]
            }
            metadata["chunks"] = chunkSummaries
        }

        // Add statistics
        let wordCounts = chunks.map { $0.wordCount }
        metadata["average_chunk_size"] = wordCounts.isEmpty ? 0 : wordCounts.reduce(0, +) / wordCounts.count
        metadata["min_chunk_size"] = wordCounts.min() ?? 0
        metadata["max_chunk_size"] = wordCounts.max() ?? 0

        // Audio content statistics
        let allAudioContent = chunks.flatMap { chunk in
            chunk.metadata["audio_content"] as? [String] ?? []
        }
        metadata["audio_topics_detected"] = Array(Set(allAudioContent)).sorted()

        return metadata
    }

    /// Detect audio content in text
    private func detectAudioContent(in text: String) -> [String] {
        var content: [String] = []

        let lowercaseText = text.lowercased()

        // Check for various types of audio content
        if lowercaseText.contains("recording") || lowercaseText.contains("track") || lowercaseText.contains("take") {
            content.append("recording")
        }
        if lowercaseText.contains("mix") || lowercaseText.contains("balance") || lowercaseText.contains("eq") {
            content.append("mixing")
        }
        if lowercaseText.contains("master") || lowercaseText.contains("final") || lowercaseText.contains("loudness") {
            content.append("mastering")
        }
        if lowercaseText.contains("edit") || lowercaseText.contains("comp") || lowercaseText.contains("cleanup") {
            content.append("editing")
        }
        if lowercaseText.contains("microphone") || lowercaseText.contains("mic") || lowercaseText.contains("preamp") {
            content.append("equipment")
        }
        if lowercaseText.contains("setup") || lowercaseText.contains("session") || lowercaseText.contains("workflow") {
            content.append("session_structure")
        }
        if lowercaseText.contains("hz") || lowercaseText.contains("khz") || lowercaseText.contains("db") || lowercaseText.contains("ms") {
            content.append("technical")
        }

        return content
    }

    /// Detect content type
    private func detectContentType(text: String, audioContent: [String]) -> String {
        if audioContent.contains("session_structure") {
            return "session_notes"
        } else if audioContent.contains("technical") {
            return "technical_specifications"
        } else if audioContent.contains("equipment") {
            return "equipment_notes"
        } else if audioContent.isEmpty {
            return "general_text"
        } else {
            return "audio_content"
        }
    }

    /// Format chunks as text
    private func formatChunksAsText(_ chunks: [TextChunk]) -> String {
        var formattedText = ""

        for (index, chunk) in chunks.enumerated() {
            formattedText += "=== CHUNK \(index + 1)/\(chunks.count) ===\n"
            formattedText += "ID: \(chunk.id)\n"
            formattedText += "Words: \(chunk.wordCount)\n"

            if let contentType = chunk.metadata["content_type"] as? String {
                formattedText += "Type: \(contentType)\n"
            }

            formattedText += "\n\(chunk.text)\n\n"
        }

        return formattedText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Security

    /// Validates input for security compliance
    private func performSecurityCheck(_ text: String) async throws {
        try TextValidationUtils.validateText(text)
    }

    /// Validates output chunks for security compliance
    private func validateOutput(_ chunks: [TextChunk]) async throws {
        for chunk in chunks {
            try TextValidationUtils.validateText(chunk.text)
        }
    }
}