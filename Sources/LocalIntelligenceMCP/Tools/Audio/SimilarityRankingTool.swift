//
//  SimilarityRankingTool.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-09.
//

import Foundation

/// Tool for ranking similar audio content, plugins, and sessions based on embeddings and similarity metrics
public class SimilarityRankingTool: BaseMCPTool, @unchecked Sendable {

    public struct SimilarityRankingInput: Codable {
        let query: String // Query content to find similarities for
        let candidates: [String] // Candidate content to compare against
        let contentType: String // Type of content being compared
        let rankingMethod: String // "cosine", "euclidean", "jaccard", "weighted"
        let maxResults: Int // Maximum number of results to return
        let threshold: Double? // Minimum similarity threshold
        let weights: [String: Double]? // Feature weights for ranking
        let includeDetails: Bool // Include detailed similarity analysis

        init(from parameters: [String: AnyCodable]) throws {
            guard let query = parameters["query"]?.value as? String, !query.isEmpty else {
                throw SimilarityError.invalidEmbedding("Query is required and cannot be empty")
            }

            guard let candidates = parameters["candidates"]?.value as? [String], !candidates.isEmpty else {
                throw SimilarityError.invalidEmbedding("Candidates are required and cannot be empty")
            }

            self.query = query
            self.candidates = candidates
            self.contentType = parameters["contentType"]?.value as? String ?? "text"
            self.rankingMethod = parameters["rankingMethod"]?.value as? String ?? "cosine"
            self.maxResults = parameters["maxResults"]?.value as? Int ?? 10
            self.threshold = parameters["threshold"]?.value as? Double
            self.weights = parameters["weights"]?.value as? [String: Double]
            self.includeDetails = parameters["includeDetails"]?.value as? Bool ?? false
        }
    }

    public struct SimilarityRankingOutput: Codable {
        let query: String
        let rankings: [SimilarityResult]
        let method: String
        let contentType: String
        let totalCandidates: Int
        let processedCandidates: Int
        let threshold: Double?
        let averageSimilarity: Double
        let processingTime: String
        let generatedAt: String
    }

    public struct SimilarityResult: Codable {
        let id: String
        let content: String
        let similarityScore: Double
        let rank: Int
        let similarityDetails: SimilarityDetails?
        let metadata: [String: AnyCodable]?
        let confidence: Double
    }

    public struct SimilarityDetails: Codable {
        let cosineSimilarity: Double?
        let euclideanDistance: Double?
        let jaccardSimilarity: Double?
        let overlappingFeatures: [String]
        let uniqueFeatures: [String]
        let featureWeights: [String: Double]
        let analysisText: String
    }

    public struct BatchRankingInput: Codable {
        let queries: [String]
        let candidates: [String]
        let contentType: String
        let rankingMethod: String
        let maxResults: Int
        let threshold: Double?
        let batchId: String?
    }

    public struct BatchRankingOutput: Codable {
        let batchId: String
        let queryRankings: [QueryRankingResult]
        let method: String
        let contentType: String
        let totalQueries: Int
        let totalCandidates: Int
        let averageProcessingTime: String
        let generatedAt: String
    }

    public struct QueryRankingResult: Codable {
        let query: String
        let rankings: [SimilarityResult]
        let averageSimilarity: Double
        let processingTime: String
    }

    public init(logger: Logger, securityManager: SecurityManager) {
        super.init(
            name: "similarity_ranking",
            description: "Advanced similarity ranking tool for audio content, plugins, and sessions. Supports multiple similarity metrics (cosine, euclidean, jaccard, weighted) and provides detailed analysis for audio engineering workflows including plugin recommendations, session matching, and content retrieval.",
            inputSchema: [
                "type": "object",
                "properties": [
                    "query": [
                        "type": "string",
                        "description": "Query content to find similarities for (session notes, plugin descriptions, feedback, etc.)",
                        "minLength": 1,
                        "maxLength": 5000
                    ],
                    "candidates": [
                        "type": "array",
                        "description": "Array of candidate content to compare against",
                        "items": ["type": "string"],
                        "minItems": 1,
                        "maxItems": 1000
                    ],
                    "contentType": [
                        "type": "string",
                        "description": "Type of content being compared",
                        "enum": [
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
                    "rankingMethod": [
                        "type": "string",
                        "description": "Similarity calculation method",
                        "enum": ["cosine", "euclidean", "jaccard", "weighted"],
                        "default": "cosine"
                    ],
                    "maxResults": [
                        "type": "integer",
                        "description": "Maximum number of results to return",
                        "minimum": 1,
                        "maximum": 100,
                        "default": 10
                    ],
                    "threshold": [
                        "type": "number",
                        "description": "Minimum similarity threshold (0.0-1.0)",
                        "minimum": 0.0,
                        "maximum": 1.0,
                        "default": 0.0
                    ],
                    "weights": [
                        "type": "object",
                        "description": "Feature weights for weighted similarity calculation",
                        "additionalProperties": ["type": "number"]
                    ],
                    "includeDetails": [
                        "type": "boolean",
                        "description": "Include detailed similarity analysis",
                        "default": false
                    ]
                ],
                "required": ["query", "candidates"]
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
        let input = try SimilarityRankingInput(from: parameters)
        let startTime = Date().timeIntervalSince1970

        // Generate embeddings for query and candidates
        let queryEmbedding = try await generateEmbedding(
            content: input.query,
            contentType: input.contentType
        )

        let candidateEmbeddings = try await generateBatchEmbeddings(
            contents: input.candidates,
            contentType: input.contentType
        )

        // Calculate similarities
        var similarities: [(index: Int, score: Double, details: SimilarityDetails?)] = []

        for (index, candidateEmbedding) in candidateEmbeddings.enumerated() {
            let similarity = try await calculateSimilarity(
                queryEmbedding: queryEmbedding,
                candidateEmbedding: candidateEmbedding,
                method: input.rankingMethod,
                weights: input.weights,
                includeDetails: input.includeDetails
            )

            // Apply threshold filter
            let threshold = input.threshold ?? 0.0
            if similarity.score >= threshold {
                similarities.append((index: index, score: similarity.score, details: similarity.details))
            }
        }

        // Sort by similarity score (descending)
        similarities.sort { $0.score > $1.score }

        // Limit results
        let limitedSimilarities = Array(similarities.prefix(input.maxResults))

        // Create ranking results
        let rankings = limitedSimilarities.enumerated().map { (index, similarity) in
            SimilarityResult(
                id: "candidate_\(similarity.index)",
                content: input.candidates[similarity.index],
                similarityScore: similarity.score,
                rank: index + 1,
                similarityDetails: similarity.details,
                metadata: createMetadata(for: input.candidates[similarity.index], contentType: input.contentType),
                confidence: calculateConfidence(score: similarity.score, method: input.rankingMethod)
            )
        }

        let processingTime = Date().timeIntervalSince1970 - startTime
        let averageSimilarity = rankings.isEmpty ? 0.0 : rankings.map(\.similarityScore).reduce(0, +) / Double(rankings.count)

        let result = SimilarityRankingOutput(
            query: input.query,
            rankings: rankings,
            method: input.rankingMethod,
            contentType: input.contentType,
            totalCandidates: input.candidates.count,
            processedCandidates: similarities.count,
            threshold: input.threshold,
            averageSimilarity: averageSimilarity,
            processingTime: String(format: "%.2f ms", processingTime * 1000),
            generatedAt: ISO8601DateFormatter().string(from: Date())
        )

        return MCPResponse(
            success: true,
            data: AnyCodable(result)
        )
    }

    // MARK: - Batch Processing

    public func handleBatch(_ input: BatchRankingInput) async throws -> BatchRankingOutput {
        let startTime = Date().timeIntervalSince1970
        var queryRankings: [QueryRankingResult] = []

        // Process each query
        for query in input.queries {
            let singleInput = try SimilarityRankingInput(from: [
                "query": AnyCodable(query),
                "candidates": AnyCodable(input.candidates),
                "contentType": AnyCodable(input.contentType),
                "rankingMethod": AnyCodable(input.rankingMethod),
                "maxResults": AnyCodable(input.maxResults),
                "threshold": AnyCodable(input.threshold),
                "weights": AnyCodable(Optional<[String: Double]>.none),
                "includeDetails": AnyCodable(false)
            ])

            let result = try await performExecution(
            parameters: [
                "query": AnyCodable(singleInput.query),
                "candidates": AnyCodable(singleInput.candidates),
                "contentType": AnyCodable(singleInput.contentType),
                "rankingMethod": AnyCodable(singleInput.rankingMethod),
                "maxResults": AnyCodable(singleInput.maxResults),
                "threshold": AnyCodable(singleInput.threshold),
                "weights": AnyCodable(singleInput.weights),
                "includeDetails": AnyCodable(singleInput.includeDetails)
            ],
            context: MCPExecutionContext(
                clientId: UUID(),
                requestId: UUID().uuidString,
                toolName: "similarity_ranking"
            )
        )

        guard let similarityOutput = result.data?.value as? SimilarityRankingOutput else {
            throw SimilarityError.processingFailed("Failed to process similarity ranking")
        }

            queryRankings.append(QueryRankingResult(
                query: query,
                rankings: similarityOutput.rankings,
                averageSimilarity: similarityOutput.averageSimilarity,
                processingTime: similarityOutput.processingTime
            ))
        }

        let totalProcessingTime = Date().timeIntervalSince1970 - startTime
        let averageProcessingTime = String(format: "%.2f ms", totalProcessingTime / Double(input.queries.count) * 1000)

        return BatchRankingOutput(
            batchId: input.batchId ?? UUID().uuidString,
            queryRankings: queryRankings,
            method: input.rankingMethod,
            contentType: input.contentType,
            totalQueries: input.queries.count,
            totalCandidates: input.candidates.count,
            averageProcessingTime: averageProcessingTime,
            generatedAt: ISO8601DateFormatter().string(from: Date())
        )
    }

    // MARK: - Embedding Generation

    private func generateEmbedding(content: String, contentType: String) async throws -> [Double] {
        // Use the EmbeddingGenerationTool to generate embeddings
        let embeddingTool = EmbeddingGenerationTool(logger: Logger(configuration: .default), securityManager: SecurityManager())
        let embeddingInput = try EmbeddingGenerationTool.EmbeddingInput(from: [
            "content": AnyCodable(content),
            "contentType": AnyCodable(contentType),
            "embeddingModel": AnyCodable("audio-domain"),
            "dimensions": AnyCodable(768),
            "normalize": AnyCodable(true),
            "metadata": AnyCodable(Optional<[String: AnyCodable]>.none)
        ])

        let result = try await embeddingTool.performExecution(
            parameters: [
                "content": AnyCodable(embeddingInput.content),
                "contentType": AnyCodable(embeddingInput.contentType),
                "embeddingModel": AnyCodable(embeddingInput.embeddingModel),
                "dimensions": AnyCodable(embeddingInput.dimensions),
                "normalize": AnyCodable(embeddingInput.normalize),
                "metadata": AnyCodable(embeddingInput.metadata)
            ],
            context: MCPExecutionContext(
                clientId: UUID(),
                requestId: UUID().uuidString,
                toolName: "similarity_ranking"
            )
        )

        guard let embeddingOutput = result.data?.value as? EmbeddingGenerationTool.EmbeddingOutput else {
            throw SimilarityError.invalidEmbedding("Failed to generate embedding")
        }

        return embeddingOutput.embedding
    }

    private func generateBatchEmbeddings(contents: [String], contentType: String) async throws -> [[Double]] {
        // Generate embeddings for all candidates
        var embeddings: [[Double]] = []

        for content in contents {
            let embedding = try await generateEmbedding(content: content, contentType: contentType)
            embeddings.append(embedding)
        }

        return embeddings
    }

    // MARK: - Similarity Calculation Methods

    private func calculateSimilarity(
        queryEmbedding: [Double],
        candidateEmbedding: [Double],
        method: String,
        weights: [String: Double]?,
        includeDetails: Bool
    ) async throws -> (score: Double, details: SimilarityDetails?) {
        switch method {
        case "cosine":
            return calculateCosineSimilarity(
                queryEmbedding: queryEmbedding,
                candidateEmbedding: candidateEmbedding,
                includeDetails: includeDetails
            )
        case "euclidean":
            return calculateEuclideanSimilarity(
                queryEmbedding: queryEmbedding,
                candidateEmbedding: candidateEmbedding,
                includeDetails: includeDetails
            )
        case "jaccard":
            return calculateJaccardSimilarity(
                queryEmbedding: queryEmbedding,
                candidateEmbedding: candidateEmbedding,
                includeDetails: includeDetails
            )
        case "weighted":
            return calculateWeightedSimilarity(
                queryEmbedding: queryEmbedding,
                candidateEmbedding: candidateEmbedding,
                weights: weights ?? [:],
                includeDetails: includeDetails
            )
        default:
            throw SimilarityError.invalidMethod(method)
        }
    }

    private func calculateCosineSimilarity(
        queryEmbedding: [Double],
        candidateEmbedding: [Double],
        includeDetails: Bool
    ) -> (score: Double, details: SimilarityDetails?) {
        guard queryEmbedding.count == candidateEmbedding.count else {
            return (score: 0.0, details: nil)
        }

        // Calculate cosine similarity
        let dotProduct = zip(queryEmbedding, candidateEmbedding).map(*).reduce(0, +)
        let queryMagnitude = sqrt(queryEmbedding.map { $0 * $0 }.reduce(0, +))
        let candidateMagnitude = sqrt(candidateEmbedding.map { $0 * $0 }.reduce(0, +))

        guard queryMagnitude > 0 && candidateMagnitude > 0 else {
            return (score: 0.0, details: nil)
        }

        let similarity = dotProduct / (queryMagnitude * candidateMagnitude)
        let clampedSimilarity = max(-1.0, min(1.0, similarity))

        let details = includeDetails ? SimilarityDetails(
            cosineSimilarity: clampedSimilarity,
            euclideanDistance: nil,
            jaccardSimilarity: nil,
            overlappingFeatures: [],
            uniqueFeatures: [],
            featureWeights: [:],
            analysisText: "Cosine similarity measures the cosine of the angle between two vectors. Higher values indicate greater similarity."
        ) : nil

        return (score: clampedSimilarity, details: details)
    }

    private func calculateEuclideanSimilarity(
        queryEmbedding: [Double],
        candidateEmbedding: [Double],
        includeDetails: Bool
    ) -> (score: Double, details: SimilarityDetails?) {
        guard queryEmbedding.count == candidateEmbedding.count else {
            return (score: 0.0, details: nil)
        }

        // Calculate Euclidean distance
        let distance = zip(queryEmbedding, candidateEmbedding)
            .map { pow($0 - $1, 2) }
            .reduce(0, +)

        let maxDistance = sqrt(Double(queryEmbedding.count) * 2.0) // Maximum possible distance
        let similarity = 1.0 - (distance / maxDistance)

        let details = includeDetails ? SimilarityDetails(
            cosineSimilarity: nil,
            euclideanDistance: distance,
            jaccardSimilarity: nil,
            overlappingFeatures: [],
            uniqueFeatures: [],
            featureWeights: [:],
            analysisText: "Euclidean similarity measures the straight-line distance between two points. Lower distances indicate higher similarity."
        ) : nil

        return (score: similarity, details: details)
    }

    private func calculateJaccardSimilarity(
        queryEmbedding: [Double],
        candidateEmbedding: [Double],
        includeDetails: Bool
    ) -> (score: Double, details: SimilarityDetails?) {
        // Convert embeddings to binary features (based on threshold)
        let threshold = 0.5
        let queryFeatures = Set(queryEmbedding.enumerated().filter { $0.element > threshold }.map { $0.offset })
        let candidateFeatures = Set(candidateEmbedding.enumerated().filter { $0.element > threshold }.map { $0.offset })

        // Calculate Jaccard similarity
        let intersection = queryFeatures.intersection(candidateFeatures)
        let union = queryFeatures.union(candidateFeatures)

        guard !union.isEmpty else {
            return (score: 0.0, details: nil)
        }

        let similarity = Double(intersection.count) / Double(union.count)

        let details = includeDetails ? SimilarityDetails(
            cosineSimilarity: nil,
            euclideanDistance: nil,
            jaccardSimilarity: similarity,
            overlappingFeatures: Array(intersection).map { String($0) },
            uniqueFeatures: Array(union.subtracting(intersection)).map { String($0) },
            featureWeights: [:],
            analysisText: "Jaccard similarity measures the ratio of intersection to union of two sets. Higher values indicate greater similarity."
        ) : nil

        return (score: similarity, details: details)
    }

    private func calculateWeightedSimilarity(
        queryEmbedding: [Double],
        candidateEmbedding: [Double],
        weights: [String: Double],
        includeDetails: Bool
    ) -> (score: Double, details: SimilarityDetails?) {
        guard queryEmbedding.count == candidateEmbedding.count else {
            return (score: 0.0, details: nil)
        }

        // Apply weights to embeddings (simplified approach)
        let weightVector = generateWeightVector(count: queryEmbedding.count, weights: weights)

        let weightedQuery = zip(queryEmbedding, weightVector).map { $0 * $1 }
        let weightedCandidate = zip(candidateEmbedding, weightVector).map { $0 * $1 }

        // Calculate weighted cosine similarity
        let dotProduct = zip(weightedQuery, weightedCandidate).map(*).reduce(0, +)
        let queryMagnitude = sqrt(weightedQuery.map { $0 * $0 }.reduce(0, +))
        let candidateMagnitude = sqrt(weightedCandidate.map { $0 * $0 }.reduce(0, +))

        guard queryMagnitude > 0 && candidateMagnitude > 0 else {
            return (score: 0.0, details: nil)
        }

        let similarity = dotProduct / (queryMagnitude * candidateMagnitude)
        let clampedSimilarity = max(-1.0, min(1.0, similarity))

        let details = includeDetails ? SimilarityDetails(
            cosineSimilarity: clampedSimilarity,
            euclideanDistance: nil,
            jaccardSimilarity: nil,
            overlappingFeatures: [],
            uniqueFeatures: [],
            featureWeights: weights,
            analysisText: "Weighted similarity applies custom weights to different dimensions, allowing domain-specific emphasis."
        ) : nil

        return (score: clampedSimilarity, details: details)
    }

    // MARK: - Helper Methods

    private func generateWeightVector(count: Int, weights: [String: Double]) -> [Double] {
        var weightVector = Array(repeating: 1.0, count: count)

        // Apply audio domain-specific weights
        for (key, weight) in weights {
            switch key {
            case "technical":
                // First quarter of dimensions get technical weight
                for i in 0..<min(count / 4, count) {
                    weightVector[i] = weight
                }
            case "semantic":
                // Second quarter gets semantic weight
                for i in (count / 4)..<min(count / 2, count) {
                    weightVector[i] = weight
                }
            case "context":
                // Third quarter gets context weight
                for i in (count / 2)..<min(count * 3 / 4, count) {
                    weightVector[i] = weight
                }
            default:
                break
            }
        }

        return weightVector
    }

    private func createMetadata(for content: String, contentType: String) -> [String: AnyCodable] {
        var metadata: [String: AnyCodable] = [:]

        metadata["contentType"] = AnyCodable(contentType)
        metadata["length"] = AnyCodable(content.count)
        metadata["wordCount"] = AnyCodable(content.components(separatedBy: .whitespacesAndNewlines).count)

        // Add content-type specific metadata
        switch contentType {
        case "plugin_description":
            metadata["pluginType"] = AnyCodable(extractPluginType(from: content))
            metadata["vendor"] = AnyCodable(extractVendor(from: content))
            metadata["priceRange"] = AnyCodable(extractPriceRange(from: content))
        case "session_notes":
            metadata["sessionType"] = AnyCodable(extractSessionType(from: content))
            metadata["duration"] = AnyCodable(extractDuration(from: content))
            metadata["engineer"] = AnyCodable(extractEngineer(from: content))
        case "feedback":
            metadata["sentiment"] = AnyCodable(extractSentiment(from: content))
            metadata["priority"] = AnyCodable(extractPriority(from: content))
            metadata["client"] = AnyCodable(extractClient(from: content))
        case "technical_spec":
            metadata["specType"] = AnyCodable(extractSpecType(from: content))
            metadata["complexity"] = AnyCodable(extractComplexity(from: content))
        default:
            break
        }

        return metadata
    }

    private func calculateConfidence(score: Double, method: String) -> Double {
        var confidence = 0.5

        // Base confidence depends on similarity score
        confidence += score * 0.4

        // Adjust confidence based on method
        switch method {
        case "cosine":
            confidence += 0.2 // Cosine is generally reliable
        case "weighted":
            confidence += 0.1 // Weighted may be more variable
        case "euclidean":
            confidence += 0.1 // Euclidean can be less reliable for high dimensions
        case "jaccard":
            confidence += 0.05 // Jaccard can be less sensitive
        default:
            confidence += 0.0
        }

        return max(min(confidence, 1.0), 0.0)
    }

    // MARK: - Content Analysis Methods

    private func extractPluginType(from content: String) -> String {
        let types = ["compressor", "eq", "reverb", "delay", "distortion", "saturation", "limiter", "gate"]
        let lowercaseContent = content.lowercased()

        for type in types {
            if lowercaseContent.contains(type) {
                return type
            }
        }

        return "unknown"
    }

    private func extractVendor(from content: String) -> String {
        let vendors = ["waves", "fabfilter", "valhalla", "uad", "native", "soundtoys", "slate", "eventide"]
        let lowercaseContent = content.lowercased()

        for vendor in vendors {
            if lowercaseContent.contains(vendor) {
                return vendor
            }
        }

        return "unknown"
    }

    private func extractPriceRange(from content: String) -> String {
        if content.lowercased().contains("free") {
            return "free"
        } else if content.lowercased().contains("$") || content.lowercased().contains("dollar") {
            return "paid"
        }

        return "unknown"
    }

    private func extractSessionType(from content: String) -> String {
        let types = ["tracking", "mixing", "mastering", "editing", "rehearsal"]
        let lowercaseContent = content.lowercased()

        for type in types {
            if lowercaseContent.contains(type) {
                return type
            }
        }

        return "unknown"
    }

    private func extractDuration(from content: String) -> String {
        // Extract duration from content (simplified)
        let durationPattern = #"(\d+)\s*(hours?|hrs?|hour?|minutes?|mins?)"#

        if let regex = try? NSRegularExpression(pattern: durationPattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: content, range: NSRange(location: 0, length: content.utf16.count)) {
            return String(content[Range(match.range, in: content)!])
        }

        return "unknown"
    }

    private func extractEngineer(from content: String) -> String {
        let roles = ["engineer", "producer", "assistant", "mix engineer", "mastering engineer"]
        let lowercaseContent = content.lowercased()

        for role in roles {
            if lowercaseContent.contains(role) {
                return role
            }
        }

        return "unknown"
    }

    private func extractSentiment(from content: String) -> String {
        let positiveWords = ["love", "great", "perfect", "excellent", "amazing", "fantastic"]
        let negativeWords = ["hate", "terrible", "bad", "awful", "horrible", "dislike"]
        let lowercaseContent = content.lowercased()

        let positiveCount = positiveWords.filter { lowercaseContent.contains($0) }.count
        let negativeCount = negativeWords.filter { lowercaseContent.contains($0) }.count

        if positiveCount > negativeCount * 2 {
            return "positive"
        } else if negativeCount > positiveCount * 2 {
            return "negative"
        } else {
            return "neutral"
        }
    }

    private func extractPriority(from content: String) -> String {
        let priorities = ["urgent", "high", "medium", "low"]
        let lowercaseContent = content.lowercased()

        for priority in priorities {
            if lowercaseContent.contains(priority) {
                return priority
            }
        }

        return "normal"
    }

    private func extractClient(from content: String) -> String {
        let clientPattern = #"client\s+([A-Za-z]+)"#

        if let regex = try? NSRegularExpression(pattern: clientPattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: content, range: NSRange(location: 0, length: content.utf16.count)) {
            return String(content[Range(match.range, in: content)!])
        }

        return "unknown"
    }

    private func extractSpecType(from content: String) -> String {
        let types = ["technical", "requirement", "specification", "manual", "guide"]
        let lowercaseContent = content.lowercased()

        for type in types {
            if lowercaseContent.contains(type) {
                return type
            }
        }

        return "general"
    }

    private func extractComplexity(from content: String) -> String {
        if content.count > 5000 {
            return "high"
        } else if content.count > 1000 {
            return "medium"
        } else {
            return "low"
        }
    }

    // MARK: - Error Handling

    enum SimilarityError: Error {
        case invalidMethod(String)
        case invalidEmbedding(String)
        case processingFailed(String)
    }
}