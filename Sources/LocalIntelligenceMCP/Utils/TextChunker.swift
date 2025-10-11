//
//  TextChunker.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-08.
//

import Foundation

/// Utility class for chunking large text into manageable pieces
/// Provides multiple chunking strategies optimized for audio-related content
class TextChunker: @unchecked Sendable {

    // MARK: - Properties

    private let logger: Logger
    private let configuration: AudioToolsConfiguration.TextChunking

    // MARK: - Initialization

    init(logger: Logger, configuration: AudioToolsConfiguration.TextChunking) {
        self.logger = logger
        self.configuration = configuration
    }

    // MARK: - Public Interface

    /// Chunk text using the specified strategy
    /// - Parameters:
    ///   - text: Text to chunk
    ///   - strategy: Chunking strategy to use
    ///   - customChunkSize: Optional custom chunk size (overrides configuration)
    /// - Returns: Array of text chunks
    /// - Throws: ChunkingError if chunking fails
    func chunk(
        _ text: String,
        strategy: AudioToolsConfiguration.TextChunking.ChunkingStrategy = .paragraph,
        customChunkSize: Int? = nil
    ) async throws -> [TextChunk] {
        await logger.debug(
            "Chunking text with strategy: \(strategy.rawValue)",
            metadata: [
                "textLength": text.count,
                "strategy": strategy.rawValue,
                "customChunkSize": customChunkSize ?? configuration.defaultChunkSize
            ]
        )

        let chunkSize = customChunkSize ?? configuration.defaultChunkSize
        let effectiveChunkSize = min(chunkSize, configuration.maxChunkSize)

        do {
            let chunks = try await performChunking(
                text: text,
                strategy: strategy,
                chunkSize: effectiveChunkSize
            )

            await logger.info(
                "Text chunked successfully",
                metadata: [
                    "originalLength": text.count,
                    "chunkCount": chunks.count,
                    "strategy": strategy.rawValue,
                    "averageChunkLength": chunks.isEmpty ? 0 : text.count / chunks.count
                ]
            )

            return chunks
        } catch {
            await logger.error("Text chunking failed", error: error, metadata: [:])
            throw ChunkingError.chunkingFailed(reason: error.localizedDescription)
        }
    }

    /// Reconstruct text from chunks
    /// - Parameter chunks: Array of text chunks
    /// - Returns: Reconstructed text
    /// - Throws: ReconstructionError if reconstruction fails
    func reconstruct(from chunks: [TextChunk]) async throws -> String {
        guard !chunks.isEmpty else {
            return ""
        }

        // Sort chunks by index to ensure proper order
        let sortedChunks = chunks.sorted { $0.index < $1.index }

        // Check for gaps in indices
        for i in 0..<sortedChunks.count {
            if sortedChunks[i].index != i {
                throw ChunkingError.reconstructionFailed(
                    reason: "Gap in chunk indices at position \(i)"
                )
            }
        }

        // Reconstruct text by concatenating chunks
        let reconstructedText = sortedChunks.map { $0.text }.joined()

        await logger.debug(
            "Text reconstructed from chunks",
            metadata: [
                "chunkCount": chunks.count,
                "reconstructedLength": reconstructedText.count
            ]
        )

        return reconstructedText
    }

    /// Get optimal chunking strategy for the given text
    /// - Parameter text: Text to analyze
    /// - Returns: Recommended chunking strategy
    func recommendStrategy(for text: String) -> AudioToolsConfiguration.TextChunking.ChunkingStrategy {
        let textLength = text.count

        // For very short text, use fixed chunking
        if textLength < 500 {
            return .fixed
        }

        // For medium text with clear structure, use paragraph chunking
        if textLength < 5000 && hasClearParagraphStructure(text) {
            return .paragraph
        }

        // For longer text with semantic content, use semantic chunking
        if textLength >= 5000 && hasSemanticStructure(text) {
            return .semantic
        }

        // Default to paragraph chunking
        return .paragraph
    }

    /// Estimate number of chunks for given text and strategy
    /// - Parameters:
    ///   - text: Text to analyze
    ///   - strategy: Chunking strategy
    ///   - chunkSize: Chunk size to use
    /// - Returns: Estimated number of chunks
    func estimateChunkCount(
        for text: String,
        strategy: AudioToolsConfiguration.TextChunking.ChunkingStrategy,
        chunkSize: Int? = nil
    ) -> Int {
        let effectiveChunkSize = chunkSize ?? configuration.defaultChunkSize
        let textLength = text.count

        switch strategy {
        case .fixed:
            return max(1, (textLength + effectiveChunkSize - 1) / effectiveChunkSize)

        case .sentence:
            let sentenceCount = countSentences(in: text)
            let sentencesPerChunk = max(1, effectiveChunkSize / 100) // Rough estimate
            return max(1, (sentenceCount + sentencesPerChunk - 1) / sentencesPerChunk)

        case .paragraph:
            let paragraphCount = countParagraphs(in: text)
            return max(1, paragraphCount)

        case .semantic:
            // Semantic chunking is harder to estimate, use a rough heuristic
            let semanticUnits = estimateSemanticUnits(in: text)
            return max(1, semanticUnits)

        case .sliding:
            let stepSize = effectiveChunkSize - configuration.overlapSize
            return max(1, (textLength - effectiveChunkSize + stepSize) / stepSize)
        }
    }

    // MARK: - Private Chunking Methods

    /// Perform chunking based on the specified strategy
    /// - Parameters:
    ///   - text: Text to chunk
    ///   - strategy: Chunking strategy
    ///   - chunkSize: Target chunk size
    /// - Returns: Array of text chunks
    /// - Throws: ChunkingError if chunking fails
    private func performChunking(
        text: String,
        strategy: AudioToolsConfiguration.TextChunking.ChunkingStrategy,
        chunkSize: Int
    ) async throws -> [TextChunk] {
        switch strategy {
        case .fixed:
            return try await chunkFixedSize(text: text, chunkSize: chunkSize)
        case .sentence:
            return try await chunkBySentences(text: text, chunkSize: chunkSize)
        case .paragraph:
            return try await chunkByParagraphs(text: text, chunkSize: chunkSize)
        case .semantic:
            return try await chunkBySemanticUnits(text: text, chunkSize: chunkSize)
        case .sliding:
            return try await chunkWithSlidingWindow(text: text, chunkSize: chunkSize)
        }
    }

    /// Fixed-size chunking
    private func chunkFixedSize(text: String, chunkSize: Int) async throws -> [TextChunk] {
        var chunks: [TextChunk] = []
        let textLength = text.count

        for startIndex in stride(from: 0, to: textLength, by: chunkSize) {
            let endIndex = min(startIndex + chunkSize, textLength)
            let chunkText = String(text[text.index(text.startIndex, offsetBy: startIndex)..<text.index(text.startIndex, offsetBy: endIndex)])

            let chunk = TextChunk(
                text: chunkText,
                index: chunks.count,
                metadata: [
                    "strategy": AnyCodable("fixed"),
                    "startIndex": AnyCodable(startIndex),
                    "endIndex": AnyCodable(endIndex),
                    "originalLength": AnyCodable(chunkText.count)
                ]
            )

            chunks.append(chunk)
        }

        return chunks
    }

    /// Sentence-based chunking
    private func chunkBySentences(text: String, chunkSize: Int) async throws -> [TextChunk] {
        let sentences = splitIntoSentences(text)
        var chunks: [TextChunk] = []
        var currentChunk = ""
        var currentSentences: [String] = []

        for sentence in sentences {
            let potentialChunk = currentChunk.isEmpty ? sentence : currentChunk + " " + sentence

            if potentialChunk.count <= chunkSize {
                currentChunk = potentialChunk
                currentSentences.append(sentence)
            } else {
                // Add current chunk if not empty
                if !currentChunk.isEmpty {
                    let chunk = TextChunk(
                        text: currentChunk,
                        index: chunks.count,
                        metadata: [
                            "strategy": AnyCodable("sentence"),
                            "sentenceCount": AnyCodable(currentSentences.count),
                            "originalLength": AnyCodable(currentChunk.count)
                        ]
                    )
                    chunks.append(chunk)
                }

                // Start new chunk with current sentence
                currentChunk = sentence
                currentSentences = [sentence]
            }
        }

        // Add final chunk if not empty
        if !currentChunk.isEmpty {
            let chunk = TextChunk(
                text: currentChunk,
                index: chunks.count,
                metadata: [
                    "strategy": AnyCodable("sentence"),
                    "sentenceCount": AnyCodable(currentSentences.count),
                    "originalLength": AnyCodable(currentChunk.count)
                ]
            )
            chunks.append(chunk)
        }

        return chunks
    }

    /// Paragraph-based chunking
    private func chunkByParagraphs(text: String, chunkSize: Int) async throws -> [TextChunk] {
        let paragraphs = splitIntoParagraphs(text)
        var chunks: [TextChunk] = []
        var currentChunk = ""
        var currentParagraphs: [String] = []

        for paragraph in paragraphs {
            let potentialChunk = currentChunk.isEmpty ? paragraph : currentChunk + "\n\n" + paragraph

            if potentialChunk.count <= chunkSize {
                currentChunk = potentialChunk
                currentParagraphs.append(paragraph)
            } else {
                // Add current chunk if not empty
                if !currentChunk.isEmpty {
                    let chunk = TextChunk(
                        text: currentChunk,
                        index: chunks.count,
                        metadata: [
                            "strategy": AnyCodable("paragraph"),
                            "paragraphCount": AnyCodable(currentParagraphs.count),
                            "originalLength": AnyCodable(currentChunk.count)
                        ]
                    )
                    chunks.append(chunk)
                }

                // Handle single paragraph that's too long
                if paragraph.count > chunkSize {
                    let subChunks = try await chunkFixedSize(text: paragraph, chunkSize: chunkSize)
                    for (index, subChunk) in subChunks.enumerated() {
                        let chunk = TextChunk(
                            text: subChunk.text,
                            index: chunks.count,
                            metadata: [
                                "strategy": AnyCodable("paragraph_fixed_fallback"),
                                "originalLength": AnyCodable(subChunk.text.count),
                                "parentParagraphIndex": AnyCodable(index)
                            ]
                        )
                        chunks.append(chunk)
                    }
                    currentChunk = ""
                    currentParagraphs = []
                } else {
                    // Start new chunk with current paragraph
                    currentChunk = paragraph
                    currentParagraphs = [paragraph]
                }
            }
        }

        // Add final chunk if not empty
        if !currentChunk.isEmpty {
            let chunk = TextChunk(
                text: currentChunk,
                index: chunks.count,
                metadata: [
                    "strategy": AnyCodable("paragraph"),
                    "paragraphCount": AnyCodable(currentParagraphs.count),
                    "originalLength": AnyCodable(currentChunk.count)
                ]
            )
            chunks.append(chunk)
        }

        return chunks
    }

    /// Semantic chunking (simplified implementation)
    private func chunkBySemanticUnits(text: String, chunkSize: Int) async throws -> [TextChunk] {
        // This is a simplified semantic chunking implementation
        // In a production system, you might use embeddings or NLP models

        let sections = splitIntoSemanticSections(text)
        var chunks: [TextChunk] = []

        for (sectionIndex, section) in sections.enumerated() {
            if section.count <= chunkSize {
                let chunk = TextChunk(
                    text: section,
                    index: chunks.count,
                    metadata: [
                        "strategy": AnyCodable("semantic"),
                        "sectionIndex": AnyCodable(sectionIndex),
                        "originalLength": AnyCodable(section.count)
                    ]
                )
                chunks.append(chunk)
            } else {
                // Section is too large, split it further
                let subChunks = try await chunkByParagraphs(text: section, chunkSize: chunkSize)
                for subChunk in subChunks {
                    let updatedMetadata = subChunk.metadata.merging([
                        "strategy": AnyCodable("semantic_paragraph_fallback"),
                        "parentSectionIndex": AnyCodable(sectionIndex)
                    ]) { _, new in new }

                    let chunk = TextChunk(
                        text: subChunk.text,
                        index: chunks.count,
                        metadata: updatedMetadata
                    )
                    chunks.append(chunk)
                }
            }
        }

        return chunks
    }

    /// Sliding window chunking
    private func chunkWithSlidingWindow(text: String, chunkSize: Int) async throws -> [TextChunk] {
        let overlapSize = configuration.overlapSize
        let stepSize = max(1, chunkSize - overlapSize)
        var chunks: [TextChunk] = []
        let textLength = text.count

        for startIndex in stride(from: 0, to: textLength - stepSize, by: stepSize) {
            let endIndex = min(startIndex + chunkSize, textLength)
            let chunkText = String(text[text.index(text.startIndex, offsetBy: startIndex)..<text.index(text.startIndex, offsetBy: endIndex)])

            let chunk = TextChunk(
                text: chunkText,
                index: chunks.count,
                metadata: [
                    "strategy": AnyCodable("sliding"),
                    "startIndex": AnyCodable(startIndex),
                    "endIndex": AnyCodable(endIndex),
                    "overlapSize": AnyCodable(startIndex > 0 ? overlapSize : 0),
                    "originalLength": AnyCodable(chunkText.count)
                ]
            )

            chunks.append(chunk)

            // Break if we've reached the end
            if endIndex >= textLength {
                break
            }
        }

        return chunks
    }

    // MARK: - Text Analysis Helpers

    /// Split text into sentences
    private func splitIntoSentences(_ text: String) -> [String] {
        // Simple sentence splitting - could be enhanced with NLP
        let pattern = #"[.!?]+\s+"#
        return text.components(separatedBy: pattern)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    /// Split text into paragraphs
    private func splitIntoParagraphs(_ text: String) -> [String] {
        return text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    /// Split text into semantic sections (simplified)
    private func splitIntoSemanticSections(_ text: String) -> [String] {
        // This is a simplified semantic splitting
        // Look for common section indicators in audio-related text
        let sectionIndicators = [
            "##", "###", // Markdown headers
            "Introduction", "Overview", "Background",
            "Recording", "Mixing", "Mastering",
            "Equipment", "Settings", "Techniques",
            "Analysis", "Conclusion", "Summary",
            "Verse", "Chorus", "Bridge", "Outro"
        ]

        var sections: [String] = []
        var currentSection = ""
        let lines = text.components(separatedBy: .newlines)

        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)

            // Check if this line starts a new section
            let isNewSection = sectionIndicators.contains { indicator in
                trimmedLine.lowercased().contains(indicator.lowercased())
            }

            if isNewSection && !currentSection.isEmpty {
                sections.append(currentSection.trimmingCharacters(in: .whitespacesAndNewlines))
                currentSection = trimmedLine
            } else {
                currentSection += (currentSection.isEmpty ? "" : "\n") + trimmedLine
            }
        }

        // Add final section
        if !currentSection.isEmpty {
            sections.append(currentSection.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        // Fallback: if no sections were found, return the whole text
        if sections.isEmpty {
            sections = [text]
        }

        return sections
    }

    /// Check if text has clear paragraph structure
    private func hasClearParagraphStructure(_ text: String) -> Bool {
        let paragraphs = splitIntoParagraphs(text)
        return paragraphs.count > 1 && paragraphs.allSatisfy { $0.count > 50 }
    }

    /// Check if text has semantic structure
    private func hasSemanticStructure(_ text: String) -> Bool {
        let sections = splitIntoSemanticSections(text)
        return sections.count > 1
    }

    /// Count sentences in text
    private func countSentences(in text: String) -> Int {
        return splitIntoSentences(text).count
    }

    /// Count paragraphs in text
    private func countParagraphs(in text: String) -> Int {
        return splitIntoParagraphs(text).count
    }

    /// Estimate semantic units in text
    private func estimateSemanticUnits(in text: String) -> Int {
        let sections = splitIntoSemanticSections(text)
        if sections.isEmpty { return 1 }

        let averageSectionLength = sections.reduce(0) { $0 + $1.count } / sections.count
        let targetChunkSize = configuration.defaultChunkSize

        return max(1, sections.count * averageSectionLength / targetChunkSize)
    }
}

// MARK: - Chunking Errors

enum ChunkingError: Error, LocalizedError {
    case invalidText(String)
    case invalidChunkSize(Int)
    case chunkingFailed(reason: String)
    case reconstructionFailed(reason: String)
    case unsupportedStrategy(String)

    var errorDescription: String? {
        switch self {
        case .invalidText(let reason):
            return "Invalid text for chunking: \(reason)"
        case .invalidChunkSize(let size):
            return "Invalid chunk size: \(size)"
        case .chunkingFailed(let reason):
            return "Chunking failed: \(reason)"
        case .reconstructionFailed(let reason):
            return "Text reconstruction failed: \(reason)"
        case .unsupportedStrategy(let strategy):
            return "Unsupported chunking strategy: \(strategy)"
        }
    }
}