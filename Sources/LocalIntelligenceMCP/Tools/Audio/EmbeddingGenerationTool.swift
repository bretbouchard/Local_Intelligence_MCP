//
//  EmbeddingGenerationTool.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-09.
//

import Foundation

/// Tool for generating embeddings for audio content retrieval and similarity matching
public class EmbeddingGenerationTool: BaseMCPTool, @unchecked Sendable {

    public struct EmbeddingInput: Codable {
        let content: String
        let contentType: String // "text", "session_notes", "plugin_description", "feedback", "technical_spec"
        let embeddingModel: String? // "audio-domain", "general", "technical"
        let dimensions: Int? // Embedding dimensions (default: 768)
        let normalize: Bool? // Whether to normalize embeddings
        let metadata: [String: AnyCodable]? // Additional metadata for the embedding

        init(from parameters: [String: AnyCodable]) throws {
            guard let content = parameters["content"]?.value as? String, !content.isEmpty else {
                throw EmbeddingError.invalidContent("Content is required and cannot be empty")
            }

            self.content = content
            self.contentType = parameters["contentType"]?.value as? String ?? "text"
            self.embeddingModel = parameters["embeddingModel"]?.value as? String
            self.dimensions = parameters["dimensions"]?.value as? Int
            self.normalize = parameters["normalize"]?.value as? Bool
            self.metadata = parameters["metadata"]?.value as? [String: AnyCodable]
        }
    }

    public struct EmbeddingOutput: Codable, Sendable {
        let embedding: [Double]
        let dimensions: Int
        let model: String
        let contentType: String
        let normalized: Bool
        let metadata: [String: AnyCodable]?
        let processingTime: String
        let confidence: Double?
        let tokens: Int?
        let generatedAt: String
    }

    public struct BatchEmbeddingInput: Codable {
        let contents: [String]
        let contentType: String
        let embeddingModel: String?
        let dimensions: Int?
        let normalize: Bool?
        let batchMetadata: [[String: AnyCodable]]?
    }

    public struct BatchEmbeddingOutput: Codable {
        let embeddings: [EmbeddingOutput]
        let batchId: String
        let totalProcessingTime: String
        let averageConfidence: Double?
        let successfulCount: Int
        let failedCount: Int
        let generatedAt: String
    }

    public init(logger: Logger, securityManager: SecurityManager) {
        super.init(
            name: "embedding_generation",
            description: "Generate high-quality embeddings for audio content including session notes, plugin descriptions, technical specifications, and client feedback. Supports multiple embedding models optimized for audio domain similarity matching and content retrieval.",
            inputSchema: [
                "type": "object",
                "properties": [
                    "content": [
                        "type": "string",
                        "description": "Content to generate embedding for (session notes, plugin descriptions, feedback, etc.)",
                        "minLength": 1,
                        "maxLength": 100000
                    ],
                    "contentType": [
                        "type": "string",
                        "description": "Type of content being embedded",
                        "enum": [
                            "text",
                            "session_notes",
                            "plugin_description",
                            "feedback",
                            "technical_spec",
                            "equipment_list",
                            "audio_description",
                            "mix_notes"
                        ],
                        "default": "text"
                    ],
                    "embeddingModel": [
                        "type": "string",
                        "description": "Embedding model to use",
                        "enum": [
                            "audio-domain",
                            "general",
                            "technical",
                            "semantic"
                        ],
                        "default": "audio-domain"
                    ],
                    "dimensions": [
                        "type": "integer",
                        "description": "Embedding dimensions",
                        "minimum": 128,
                        "maximum": 1536,
                        "default": 768
                    ],
                    "normalize": [
                        "type": "boolean",
                        "description": "Whether to normalize the embedding vector",
                        "default": true
                    ],
                    "metadata": [
                        "type": "object",
                        "description": "Additional metadata to store with the embedding",
                        "additionalProperties": true
                    ]
                ],
                "required": ["content"]
            ],
            category: .audioDomain,
            requiresPermission: [.systemInfo],
            offlineCapable: true,
            logger: logger,
            securityManager: securityManager
        )
    }

    public override func performExecution(parameters: [String: AnyCodable], context: MCPExecutionContext) async throws -> MCPResponse {
        // Parse input parameters
        let input = try EmbeddingInput(from: parameters)
        let startTime = Date().timeIntervalSince1970

        // Generate embedding based on content type and model
        let embedding = try await generateEmbedding(
            content: input.content,
            contentType: input.contentType,
            model: input.embeddingModel ?? "audio-domain",
            dimensions: input.dimensions ?? 768
        )

        // Normalize if requested
        let normalizedEmbedding = input.normalize ?? true ? normalizeVector(embedding) : embedding

        let processingTime = Date().timeIntervalSince1970 - startTime

        // Calculate confidence based on content quality and model
        let confidence = calculateConfidence(
            content: input.content,
            contentType: input.contentType,
            model: input.embeddingModel ?? "audio-domain"
        )

        // Token count estimation
        let tokens = estimateTokenCount(input.content)

        let result = EmbeddingOutput(
            embedding: normalizedEmbedding,
            dimensions: normalizedEmbedding.count,
            model: input.embeddingModel ?? "audio-domain",
            contentType: input.contentType,
            normalized: input.normalize ?? true,
            metadata: input.metadata,
            processingTime: String(format: "%.2f ms", processingTime * 1000),
            confidence: confidence,
            tokens: tokens,
            generatedAt: ISO8601DateFormatter().string(from: Date())
        )

        return MCPResponse(
            success: true,
            data: AnyCodable(result)
        )
    }

    // MARK: - Batch Processing

    public func handleBatch(_ input: BatchEmbeddingInput) async throws -> BatchEmbeddingOutput {
        let startTime = Date().timeIntervalSince1970
        var embeddings: [EmbeddingOutput] = []
        var successfulCount = 0
        var failedCount = 0

        // Process embeddings in parallel with concurrency control
        let semaphore = DispatchSemaphore(value: 5) // Limit concurrent requests

        // Extract values to avoid data race warnings
        let contentType = input.contentType
        let embeddingModel = input.embeddingModel
        let dimensions = input.dimensions
        let normalize = input.normalize
        let batchMetadata = input.batchMetadata

        await withTaskGroup(of: (Result<EmbeddingOutput, Error>).self) { group in
            for (index, content) in input.contents.enumerated() {
                group.addTask {
                    await withCheckedContinuation { (continuation: CheckedContinuation<Result<EmbeddingOutput, Error>, Never>) in
                        semaphore.wait()

                        do {
                            let singleInput = try EmbeddingInput(from: [
                                "content": AnyCodable(content),
                                "contentType": AnyCodable(contentType),
                                "embeddingModel": AnyCodable(embeddingModel as Any),
                                "dimensions": AnyCodable(dimensions as Any),
                                "normalize": AnyCodable(normalize as Any),
                                "metadata": AnyCodable(batchMetadata?[safe: index] as Any)
                            ])

                            Task {
                                do {
                                    let result = try await self.performExecution(parameters: [
                                        "content": AnyCodable(singleInput.content),
                                        "contentType": AnyCodable(singleInput.contentType),
                                        "embeddingModel": AnyCodable(singleInput.embeddingModel as Any),
                                        "dimensions": AnyCodable(singleInput.dimensions as Any),
                                        "normalize": AnyCodable(singleInput.normalize as Any),
                                        "metadata": AnyCodable(singleInput.metadata as Any)
                                    ], context: MCPExecutionContext(
                                        clientId: UUID(),
                                        requestId: "batch",
                                        toolName: "embedding_generation"
                                    ))

                                    // Convert MCPResponse to EmbeddingOutput
                                    if let data = result.data?.value as? [String: Any],
                                       let embedding = data["embedding"] as? [Double] {
                                        let embeddingOutput = EmbeddingOutput(
                                            embedding: embedding,
                                            dimensions: data["dimensions"] as? Int ?? embedding.count,
                                            model: data["model"] as? String ?? "audio-domain",
                                            contentType: data["contentType"] as? String ?? "text",
                                            normalized: data["normalized"] as? Bool ?? true,
                                            metadata: data["metadata"] as? [String: AnyCodable],
                                            processingTime: data["processingTime"] as? String ?? "0 ms",
                                            confidence: data["confidence"] as? Double,
                                            tokens: data["tokens"] as? Int,
                                            generatedAt: data["generatedAt"] as? String ?? ISO8601DateFormatter().string(from: Date())
                                        )
                                        continuation.resume(returning: .success(embeddingOutput))
                                    } else {
                                        continuation.resume(returning: .failure(EmbeddingError.processingFailed("Failed to generate embedding")))
                                    }
                                } catch {
                                    continuation.resume(returning: .failure(error))
                                }
                                semaphore.signal()
                            }
                        } catch {
                            continuation.resume(returning: .failure(error))
                            semaphore.signal()
                        }
                    }
                }
            }

            for await result in group {
                switch result {
                case .success(let embedding):
                    embeddings.append(embedding)
                    successfulCount += 1
                case .failure(let error):
                    print("Failed to generate embedding: \(error)")
                    failedCount += 1
                }
            }
        }

        let totalProcessingTime = Date().timeIntervalSince1970 - startTime
        let averageConfidence = embeddings.isEmpty ? nil : embeddings.compactMap { $0.confidence }.reduce(0, +) / Double(embeddings.count)

        return BatchEmbeddingOutput(
            embeddings: embeddings,
            batchId: UUID().uuidString,
            totalProcessingTime: String(format: "%.2f ms", totalProcessingTime * 1000),
            averageConfidence: averageConfidence,
            successfulCount: successfulCount,
            failedCount: failedCount,
            generatedAt: ISO8601DateFormatter().string(from: Date())
        )
    }

    // MARK: - Private Embedding Generation Methods

    private func generateEmbedding(
        content: String,
        contentType: String,
        model: String,
        dimensions: Int
    ) async throws -> [Double] {
        switch model {
        case "audio-domain":
            return try await generateAudioDomainEmbedding(content: content, contentType: contentType, dimensions: dimensions)
        case "general":
            return try await generateGeneralEmbedding(content: content, dimensions: dimensions)
        case "technical":
            return try await generateTechnicalEmbedding(content: content, contentType: contentType, dimensions: dimensions)
        case "semantic":
            return try await generateSemanticEmbedding(content: content, dimensions: dimensions)
        default:
            throw EmbeddingError.invalidModel(model)
        }
    }

    private func generateAudioDomainEmbedding(
        content: String,
        contentType: String,
        dimensions: Int
    ) async throws -> [Double] {
        // Audio domain-specific embedding generation
        var embedding = Array(repeating: 0.0, count: dimensions)

        // Content preprocessing for audio domain
        let processedContent = preprocessAudioContent(content, contentType: contentType)
        let tokens = tokenizeAudioContent(processedContent)

        // Generate embedding using audio-specific features
        let audioFeatures = extractAudioFeatures(tokens, contentType: contentType)

        // Map features to embedding dimensions
        for (index, feature) in audioFeatures.enumerated() {
            if index < dimensions {
                embedding[index] = feature
            }
        }

        // Add domain-specific patterns
        addAudioDomainPatterns(&embedding, content: processedContent, contentType: contentType)

        // Ensure we have the correct number of dimensions
        while embedding.count < dimensions {
            embedding.append(Double.random(in: -0.1...0.1))
        }

        return embedding
    }

    private func generateGeneralEmbedding(content: String, dimensions: Int) async throws -> [Double] {
        // General purpose embedding generation
        var embedding = Array(repeating: 0.0, count: dimensions)

        // Simple text processing
        let words = content.lowercased().components(separatedBy: .whitespacesAndNewlines)
        let uniqueWords = Set(words)

        // Create embedding based on word frequency and patterns
        for (index, word) in uniqueWords.enumerated() {
            if index < dimensions {
                let hash = word.hashValue
                embedding[index] = Double(hash % 1000) / 1000.0
            }
        }

        // Add semantic patterns
        addSemanticPatterns(&embedding, content: content)

        // Ensure correct dimensions
        while embedding.count < dimensions {
            embedding.append(Double.random(in: -0.1...0.1))
        }

        return embedding
    }

    private func generateTechnicalEmbedding(
        content: String,
        contentType: String,
        dimensions: Int
    ) async throws -> [Double] {
        // Technical embedding for specifications and technical content
        var embedding = Array(repeating: 0.0, count: dimensions)

        // Extract technical terms and specifications
        let technicalTerms = extractTechnicalTerms(content)

        // Create embedding based on technical features
        for (index, term) in technicalTerms.enumerated() {
            if index < dimensions {
                embedding[index] = Double(term.hashValue % 1000) / 1000.0
            }
        }

        // Add technical patterns based on content type
        addTechnicalPatterns(&embedding, content: content, contentType: contentType)

        // Ensure correct dimensions
        while embedding.count < dimensions {
            embedding.append(Double.random(in: -0.1...0.1))
        }

        return embedding
    }

    private func generateSemanticEmbedding(content: String, dimensions: Int) async throws -> [Double] {
        // Semantic embedding focusing on meaning and context
        var embedding = Array(repeating: 0.0, count: dimensions)

        // Extract semantic features
        let semanticFeatures = extractSemanticFeatures(content)

        // Map semantic features to embedding
        for (index, feature) in semanticFeatures.enumerated() {
            if index < dimensions {
                embedding[index] = feature
            }
        }

        // Add context patterns
        addContextPatterns(&embedding, content: content)

        // Ensure correct dimensions
        while embedding.count < dimensions {
            embedding.append(Double.random(in: -0.1...0.1))
        }

        return embedding
    }

    // MARK: - Content Processing Methods

    private func preprocessAudioContent(_ content: String, contentType: String) -> String {
        var processed = content.lowercased()

        // Remove special characters and normalize
        processed = processed.replacingOccurrences(of: "[^a-z0-9\\s]", with: " ", options: .regularExpression)
        processed = processed.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)

        // Add content type-specific processing
        switch contentType {
        case "session_notes":
            processed = addSessionNoteKeywords(processed)
        case "plugin_description":
            processed = addPluginDescriptionKeywords(processed)
        case "feedback":
            processed = addFeedbackKeywords(processed)
        case "technical_spec":
            processed = addTechnicalSpecKeywords(processed)
        default:
            break
        }

        return processed.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func tokenizeAudioContent(_ content: String) -> [String] {
        return content.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
    }

    private func extractAudioFeatures(_ tokens: [String], contentType: String) -> [Double] {
        var features: [Double] = []

        // Audio-specific keywords and their weights
        let audioKeywords: [String: Double] = [
            "vocal": 0.9, "voice": 0.9, "singing": 0.8,
            "drum": 0.8, "drums": 0.8, "percussion": 0.7,
            "bass": 0.8, "guitar": 0.8, "piano": 0.7,
            "mix": 0.9, "mixing": 0.9, "master": 0.9, "mastering": 0.9,
            "compressor": 0.8, "eq": 0.8, "reverb": 0.7, "delay": 0.7,
            "plugin": 0.7, "daw": 0.6, "studio": 0.6,
            "tracking": 0.8, "recording": 0.8, "editing": 0.7,
            "loudness": 0.8, "volume": 0.7, "level": 0.6,
            "frequency": 0.8, "hz": 0.7, "khz": 0.7,
            "saturation": 0.7, "distortion": 0.7, "warmth": 0.6,
            "clarity": 0.8, "presence": 0.7, "definition": 0.7
        ]

        // Count occurrences of audio keywords
        for token in tokens {
            if let weight = audioKeywords[token] {
                features.append(weight)
            }
        }

        // Add content type-specific features
        switch contentType {
        case "session_notes":
            features.append(contentsOf: extractSessionNoteFeatures(tokens))
        case "plugin_description":
            features.append(contentsOf: extractPluginDescriptionFeatures(tokens))
        case "feedback":
            features.append(contentsOf: extractFeedbackFeatures(tokens))
        case "technical_spec":
            features.append(contentsOf: extractTechnicalSpecFeatures(tokens))
        default:
            break
        }

        return features
    }

    private func extractSessionNoteFeatures(_ tokens: [String]) -> [Double] {
        var features: [Double] = []

        let sessionKeywords: [String: Double] = [
            "engineer": 0.8, "producer": 0.8, "artist": 0.7,
            "microphone": 0.9, "mic": 0.8, "preamp": 0.8,
            "interface": 0.7, "converter": 0.7, "daw": 0.6,
            "take": 0.8, "comp": 0.7, "punch": 0.6,
            "setup": 0.7, "teardown": 0.6, "session": 0.9
        ]

        for token in tokens {
            if let weight = sessionKeywords[token] {
                features.append(weight)
            }
        }

        return features
    }

    private func extractPluginDescriptionFeatures(_ tokens: [String]) -> [Double] {
        var features: [Double] = []

        let pluginKeywords: [String: Double] = [
            "vst": 0.8, "au": 0.8, "aax": 0.7, "rtas": 0.6,
            "analog": 0.8, "digital": 0.7, "vintage": 0.8, "modern": 0.7,
            "tube": 0.8, "solid": 0.7, "class": 0.8, "a": 0.8,
            "b": 0.8, "ab": 0.7, "fidelity": 0.7,
            "dynamics": 0.9, "eq": 0.8, "equalizer": 0.8,
            "frequency": 0.8, "band": 0.7, "multiband": 0.8,
            "sidechain": 0.8, "parallel": 0.7, "mid": 0.8, "side": 0.8,
            "price": 0.6, "cost": 0.6, "free": 0.5,
            "professional": 0.8, "pro": 0.7, "studio": 0.7
        ]

        for token in tokens {
            if let weight = pluginKeywords[token] {
                features.append(weight)
            }
        }

        return features
    }

    private func extractFeedbackFeatures(_ tokens: [String]) -> [Double] {
        var features: [Double] = []

        let feedbackKeywords: [String: Double] = [
            "love": 0.9, "like": 0.8, "great": 0.8, "good": 0.7,
            "perfect": 0.9, "excellent": 0.9, "amazing": 0.9,
            "hate": 0.9, "dislike": 0.8, "terrible": 0.8, "bad": 0.7,
            "loud": 0.8, "quiet": 0.7, "soft": 0.6, "hard": 0.6,
            "bright": 0.8, "dark": 0.7, "muddy": 0.8, "clear": 0.9,
            "warm": 0.7, "cold": 0.6, "harsh": 0.8, "smooth": 0.8,
            "need": 0.8, "want": 0.7, "require": 0.8, "should": 0.7,
            "more": 0.6, "less": 0.6, "increase": 0.7, "decrease": 0.7,
            "boost": 0.7, "cut": 0.7, "add": 0.6, "remove": 0.6
        ]

        for token in tokens {
            if let weight = feedbackKeywords[token] {
                features.append(weight)
            }
        }

        return features
    }

    private func extractTechnicalSpecFeatures(_ tokens: [String]) -> [Double] {
        var features: [Double] = []

        let technicalKeywords: [String: Double] = [
            "khz": 0.8, "hz": 0.7, "frequency": 0.9,
            "db": 0.8, "decibel": 0.7, "gain": 0.8,
            "ms": 0.7, "millisecond": 0.6, "time": 0.6,
            "sample": 0.8, "rate": 0.7, "bit": 0.7,
            "latency": 0.8, "delay": 0.7, "buffer": 0.6,
            "thd": 0.8, "distortion": 0.7, "noise": 0.7,
            "dynamic": 0.8, "range": 0.7, "headroom": 0.7,
            "stereo": 0.7, "mono": 0.6, "width": 0.7,
            "phase": 0.7, "coherent": 0.8, "correlation": 0.7,
            "lufs": 0.8, "loudness": 0.8, "integrated": 0.7,
            "true": 0.7, "peak": 0.7, "rms": 0.6
        ]

        for token in tokens {
            if let weight = technicalKeywords[token] {
                features.append(weight)
            }
        }

        return features
    }

    // MARK: - Pattern Addition Methods

    private func addAudioDomainPatterns(_ embedding: inout [Double], content: String, contentType: String) {
        let patterns = getAudioDomainPatterns(contentType: contentType)

        for (index, pattern) in patterns.enumerated() {
            if index < embedding.count {
                embedding[index] = pattern
            }
        }
    }

    private func getAudioDomainPatterns(contentType: String) -> [Double] {
        switch contentType {
        case "session_notes":
            return [
                0.7, 0.8, 0.6, 0.9, 0.7, // Session-specific weights
                0.5, 0.6, 0.7, 0.8, 0.6
            ]
        case "plugin_description":
            return [
                0.8, 0.7, 0.9, 0.6, 0.8, // Plugin-specific weights
                0.7, 0.6, 0.8, 0.7, 0.9
            ]
        case "feedback":
            return [
                0.9, 0.6, 0.7, 0.8, 0.7, // Feedback-specific weights
                0.8, 0.7, 0.6, 0.9, 0.8
            ]
        case "technical_spec":
            return [
                0.6, 0.9, 0.8, 0.7, 0.6, // Technical-specific weights
                0.8, 0.7, 0.9, 0.6, 0.8
            ]
        default:
            return [
                0.5, 0.5, 0.5, 0.5, 0.5, // Default weights
                0.5, 0.5, 0.5, 0.5, 0.5
            ]
        }
    }

    private func addSemanticPatterns(_ embedding: inout [Double], content: String) {
        // Add semantic patterns based on content analysis
        let semanticScore = calculateSemanticScore(content)

        for i in 0..<min(10, embedding.count) {
            embedding[i] += semanticScore * 0.1
        }
    }

    private func addContextPatterns(_ embedding: inout [Double], content: String) {
        // Add context-aware patterns
        let contextScore = calculateContextScore(content)

        for i in 10..<min(20, embedding.count) {
            embedding[i] += contextScore * 0.1
        }
    }

    private func addTechnicalPatterns(_ embedding: inout [Double], content: String, contentType: String) {
        // Add technical patterns for technical content
        let technicalScore = calculateTechnicalScore(content, contentType: contentType)

        for i in 20..<min(30, embedding.count) {
            embedding[i] += technicalScore * 0.1
        }
    }

    // MARK: - Score Calculation Methods

    private func calculateSemanticScore(_ content: String) -> Double {
        // Calculate semantic score based on content coherence and meaning
        let words = content.components(separatedBy: .whitespacesAndNewlines)
        let uniqueWords = Set(words)
        let vocabularyRatio = Double(uniqueWords.count) / Double(words.count)

        // Higher vocabulary diversity indicates better semantic content
        return min(vocabularyRatio, 1.0)
    }

    private func calculateContextScore(_ content: String) -> Double {
        // Calculate context score based on audio domain relevance
        let audioContextWords = [
            "recording", "mixing", "mastering", "studio", "audio", "sound",
            "music", "track", "song", "album", "production", "engineering"
        ]

        let words = content.lowercased().components(separatedBy: .whitespacesAndNewlines)
        let contextWords = words.filter { audioContextWords.contains($0) }

        return Double(contextWords.count) / Double(words.count)
    }

    private func calculateTechnicalScore(_ content: String, contentType: String) -> Double {
        // Calculate technical score based on technical content
        let technicalWords = [
            "khz", "hz", "db", "ms", "bit", "sample", "latency", "thd",
            "frequency", "amplitude", "phase", "correlation", "dynamic", "range"
        ]

        let words = content.lowercased().components(separatedBy: .whitespacesAndNewlines)
        let techWords = words.filter { technicalWords.contains($0) }

        return Double(techWords.count) / Double(words.count)
    }

    // MARK: - Utility Methods

    private func normalizeVector(_ vector: [Double]) -> [Double] {
        let magnitude = sqrt(vector.reduce(0) { $0 + $1 * $1 })
        guard magnitude > 0 else { return vector }

        return vector.map { $0 / magnitude }
    }

    private func calculateConfidence(content: String, contentType: String, model: String) -> Double {
        var confidence = 0.8 // Base confidence

        // Adjust based on content length
        let contentLength = content.count
        if contentLength > 50 && contentLength < 10000 {
            confidence += 0.1 // Good length
        } else if contentLength < 20 {
            confidence -= 0.2 // Too short
        } else if contentLength > 20000 {
            confidence -= 0.1 // Too long, may lose focus
        }

        // Adjust based on content type
        switch contentType {
        case "session_notes", "plugin_description", "feedback", "technical_spec":
            confidence += 0.1 // Well-supported types
        default:
            confidence -= 0.05 // Less common type
        }

        // Adjust based on model
        switch model {
        case "audio-domain":
            confidence += 0.1 // Best model for audio content
        case "technical":
            if contentType == "technical_spec" {
                confidence += 0.1
            }
        default:
            break
        }

        return max(min(confidence, 1.0), 0.0)
    }

    private func estimateTokenCount(_ content: String) -> Int {
        // Simple token estimation (rough approximation)
        let words = content.components(separatedBy: .whitespacesAndNewlines)
        return words.count + Int(Double(words.count) * 0.3) // Add punctuation and other tokens
    }

    // MARK: - Keyword Addition Methods

    private func addSessionNoteKeywords(_ content: String) -> String {
        return content + " session recording tracking microphone preamp setup teardown"
    }

    private func addPluginDescriptionKeywords(_ content: String) -> String {
        return content + " plugin vst au aax digital analog vintage modern processing effects"
    }

    private func addFeedbackKeywords(_ content: String) -> String {
        return content + " feedback revision change adjustment like dislike love perfect"
    }

    private func addTechnicalSpecKeywords(_ content: String) -> String {
        return content + " specification technical parameters frequency amplitude phase thd latency"
    }

    private func extractTechnicalTerms(_ content: String) -> [String] {
        let technicalPattern = #"\b(khz|hz|db|ms|bit|sample|latency|thd|frequency|amplitude|phase|correlation|dynamic|range)\b"#
        let regex = try! NSRegularExpression(pattern: technicalPattern, options: .caseInsensitive)
        let range = NSRange(location: 0, length: content.utf16.count)
        let matches = regex.matches(in: content, options: [], range: range)

        return matches.map { String(content[Range($0.range, in: content)!]) }
    }

    private func extractSemanticFeatures(_ content: String) -> [Double] {
        // Extract semantic features based on word co-occurrence and patterns
        let words = content.lowercased().components(separatedBy: .whitespacesAndNewlines)
        var features: [Double] = []

        // Simple semantic features
        features.append(Double(words.count) / 1000.0) // Length feature
        features.append(Double(Set(words).count) / Double(words.count)) // Vocabulary diversity
        features.append(calculateSentenceComplexity(words)) // Complexity

        return features
    }

    private func calculateSentenceComplexity(_ words: [String]) -> Double {
        // Simple complexity calculation based on word length variation
        let lengths = words.map { $0.count }
        guard !lengths.isEmpty else { return 0.0 }

        let totalLength = lengths.reduce(0, +)
        let averageLength = Double(totalLength) / Double(lengths.count)
        let variance = lengths.map { pow(Double($0) - averageLength, 2) }.reduce(0, +) / Double(lengths.count)

        return min(sqrt(variance) / 10.0, 1.0) // Normalized variance
    }

    // MARK: - Error Handling

    enum EmbeddingError: Error {
        case invalidModel(String)
        case invalidContent(String)
        case processingFailed(String)
    }
}