//
//  SimilarityRankingToolTests.swift
//  LocalIntelligenceMCPTests
//
//  Created on 2025-10-09.
//

import XCTest
@testable import LocalIntelligenceMCP

final class SimilarityRankingToolTests: XCTestCase {

    var similarityTool: SimilarityRankingTool!

    override func setUp() async throws {
        try await super.setUp()
        similarityTool = SimilarityRankingTool()
    }

    override func tearDown() async throws {
        similarityTool = nil
        try await super.tearDown()
    }

    // MARK: - Tool Initialization Tests

    func testToolInitialization() throws {
        XCTAssertEqual(similarityTool.name, "similarity_ranking")
        XCTAssertFalse(similarityTool.description.isEmpty)

        // Verify input schema structure
        let schema = similarityTool.inputSchema
        XCTAssertEqual(schema["type"] as? String, "object")

        let properties = schema["properties"] as? [String: Any]
        XCTAssertNotNil(properties)

        // Check required properties
        let requiredProperties = schema["required"] as? [String]
        XCTAssertEqual(requiredProperties, ["query", "candidates"])

        // Check optional properties
        XCTAssertNotNil(properties?["query"])
        XCTAssertNotNil(properties?["candidates"])
        XCTAssertNotNil(properties?["contentType"])
        XCTAssertNotNil(properties?["rankingMethod"])
        XCTAssertNotNil(properties?["maxResults"])
        XCTAssertNotNil(properties?["threshold"])
        XCTAssertNotNil(properties?["weights"])
        XCTAssertNotNil(properties?["includeDetails"])
    }

    func testInputSchemaDefaults() throws {
        let schema = similarityTool.inputSchema
        let properties = schema["properties"] as? [String: Any]

        // Test default values
        XCTAssertEqual(properties?["contentType"] as? [String: Any]?["default"] as? String, "text")
        XCTAssertEqual(properties?["rankingMethod"] as? [String: Any]?["default"] as? String, "cosine")
        XCTAssertEqual(properties?["maxResults"] as? [String: Any]?["default"] as? Int, 10)
        XCTAssertEqual(properties?["threshold"] as? [String: Any]?["default"] as? Double, 0.0)
        XCTAssertEqual(properties?["includeDetails"] as? [String: Any]?["default"] as? Bool, false)
    }

    func testContentTypeEnumValues() throws {
        let schema = similarityTool.inputSchema
        let properties = schema["properties"] as? [String: Any]

        let contentTypeProperty = properties?["contentType"] as? [String: Any]
        let enumValues = contentTypeProperty?["enum"] as? [String]

        let expectedTypes = [
            "session_notes",
            "plugin_description",
            "feedback",
            "technical_spec",
            "equipment_list",
            "audio_description",
            "mix_notes"
        ]

        XCTAssertEqual(enumValues, expectedTypes)
    }

    func testRankingMethodEnumValues() throws {
        let schema = similarityTool.inputSchema
        let properties = schema["properties"] as? [String: Any]

        let methodProperty = properties?["rankingMethod"] as? [String: Any]
        let enumValues = methodProperty?["enum"] as? [String]

        let expectedMethods = ["cosine", "euclidean", "jaccard", "weighted"]
        XCTAssertEqual(enumValues, expectedMethods)
    }

    func testMaxResultsConstraints() throws {
        let schema = similarityTool.inputSchema
        let properties = schema["properties"] as? [String: Any]

        let maxResultsProperty = properties?["maxResults"] as? [String: Any]
        XCTAssertEqual(maxResultsProperty?["minimum"] as? Int, 1)
        XCTAssertEqual(maxResultsProperty?["maximum"] as? Int, 100)
    }

    func testThresholdConstraints() throws {
        let schema = similarityTool.inputSchema
        let properties = schema["properties"] as? [String: Any]

        let thresholdProperty = properties?["threshold"] as? [String: Any]
        XCTAssertEqual(thresholdProperty?["minimum"] as? Double, 0.0)
        XCTAssertEqual(thresholdProperty?["maximum"] as? Double, 1.0)
    }

    // MARK: - Basic Execution Tests

    func testBasicSimilarityRanking() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "query": AnyCodable("Vintage compressor with warm character for vocals"),
            "candidates": AnyCodable([
                "Modern digital compressor with transparent sound",
                "Analog tube compressor emulation with saturation",
                "Multiband compressor for mastering",
                "Free compressor plugin with basic controls"
            ])
        ] as [String: AnyCodable]

        do {
            let result = try await similarityTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)
            XCTAssertNotNil(result.data)
            XCTAssertNil(result.error)
        } catch {
            XCTFail("Basic similarity ranking should succeed: \(error.localizedDescription)")
        }
    }

    func testSimilarityRankingWithDefaultParameters() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "query": AnyCodable("Audio recording session with vintage equipment"),
            "candidates": AnyCodable([
                "Modern digital recording setup",
                "Analog tape recording session",
                "Home studio configuration",
                "Professional studio recording"
            ])
        ] as [String: AnyCodable]

        do {
            let result = try await similarityTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            XCTAssertNotNil(data)

            // Verify ranking output structure
            XCTAssertNotNil(data?["query"])
            XCTAssertNotNil(data?["rankings"])
            XCTAssertNotNil(data?["method"])
            XCTAssertNotNil(data?["contentType"])
            XCTAssertNotNil(data?["totalCandidates"])
            XCTAssertNotNil(data?["processedCandidates"])
            XCTAssertNotNil(data?["averageSimilarity"])
            XCTAssertNotNil(data?["processingTime"])
            XCTAssertNotNil(data?["generatedAt"])

            // Verify default values
            XCTAssertEqual(data?["method"] as? String, "cosine")
            XCTAssertEqual(data?["contentType"] as? String, "text")
            XCTAssertEqual(data?["totalCandidates"] as? Int, 4)

            // Verify rankings array
            let rankings = data?["rankings"] as? [[String: Any]]
            XCTAssertNotNil(rankings)
            XCTAssertGreaterThan(rankings?.count ?? 0, 0)
        } catch {
            XCTFail("Similarity ranking with default parameters should succeed: \(error.localizedDescription)")
        }
    }

    // MARK: - Input Parameter Tests

    func testSimilarityRankingInputParsing() throws {
        let parameters = [
            "query": AnyCodable("Test query"),
            "candidates": AnyCodable(["Candidate 1", "Candidate 2", "Candidate 3"]),
            "contentType": AnyCodable("plugin_description"),
            "rankingMethod": AnyCodable("euclidean"),
            "maxResults": AnyCodable(5),
            "threshold": AnyCodable(0.5),
            "weights": AnyCodable(["technical": 0.8, "semantic": 0.6]),
            "includeDetails": AnyCodable(true)
        ] as [String: AnyCodable]

        let input = try SimilarityRankingTool.SimilarityRankingInput(from: parameters)

        XCTAssertEqual(input.query, "Test query")
        XCTAssertEqual(input.candidates.count, 3)
        XCTAssertEqual(input.contentType, "plugin_description")
        XCTAssertEqual(input.rankingMethod, "euclidean")
        XCTAssertEqual(input.maxResults, 5)
        XCTAssertEqual(input.threshold, 0.5)
        XCTAssertEqual(input.weights?["technical"], 0.8)
        XCTAssertEqual(input.weights?["semantic"], 0.6)
        XCTAssertTrue(input.includeDetails)
    }

    func testSimilarityRankingInputWithRequiredOnly() throws {
        let parameters = [
            "query": AnyCodable("Minimal query"),
            "candidates": AnyCodable(["Candidate 1"])
        ] as [String: AnyCodable]

        let input = try SimilarityRankingTool.SimilarityRankingInput(from: parameters)

        XCTAssertEqual(input.query, "Minimal query")
        XCTAssertEqual(input.candidates.count, 1)
        XCTAssertEqual(input.contentType, "text") // Default
        XCTAssertEqual(input.rankingMethod, "cosine") // Default
        XCTAssertEqual(input.maxResults, 10) // Default
        XCTAssertNil(input.threshold)
        XCTAssertNil(input.weights)
        XCTAssertFalse(input.includeDetails) // Default
    }

    // MARK: - Ranking Method Tests

    func testCosineSimilarityRanking() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "query": AnyCodable("Vintage analog compressor with warm tube saturation"),
            "candidates": AnyCodable([
                "Modern digital compressor plugin",
                "Tube compressor emulation with vintage character",
                "Multiband compressor for mastering purposes",
                "Free basic compressor with simple controls"
            ]),
            "rankingMethod": AnyCodable("cosine")
        ] as [String: AnyCodable]

        do {
            let result = try await similarityTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            XCTAssertEqual(data?["method"] as? String, "cosine")

            let rankings = data?["rankings"] as? [[String: Any]]
            XCTAssertNotNil(rankings)

            // Verify rankings are sorted by similarity score (descending)
            if let rankings = rankings, rankings.count > 1 {
                for i in 0..<rankings.count - 1 {
                    let currentScore = rankings[i]["similarityScore"] as? Double ?? 0.0
                    let nextScore = rankings[i + 1]["similarityScore"] as? Double ?? 0.0
                    XCTAssertGreaterThanOrEqual(currentScore, nextScore, "Rankings should be sorted by similarity score")
                }
            }
        } catch {
            XCTFail("Cosine similarity ranking should succeed: \(error.localizedDescription)")
        }
    }

    func testEuclideanSimilarityRanking() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "query": AnyCodable("Professional audio mixing session"),
            "candidates": AnyCodable([
                "Home recording setup",
                "Studio mixing workflow",
                "Live sound engineering",
                "Podcast production"
            ]),
            "rankingMethod": AnyCodable("euclidean")
        ] as [String: AnyCodable]

        do {
            let result = try await similarityTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            XCTAssertEqual(data?["method"] as? String, "euclidean")

            let rankings = data?["rankings"] as? [[String: Any]]
            XCTAssertNotNil(rankings)
        } catch {
            XCTFail("Euclidean similarity ranking should succeed: \(error.localizedDescription)")
        }
    }

    func testJaccardSimilarityRanking() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "query": AnyCodable("Audio plugin with compressor and EQ features"),
            "candidates": AnyCodable([
                "Simple compressor plugin",
                "EQ plugin with multiple bands",
                "Dynamics processor with compression",
                "Multi-effects plugin with various tools"
            ]),
            "rankingMethod": AnyCodable("jaccard")
        ] as [String: AnyCodable]

        do {
            let result = try await similarityTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            XCTAssertEqual(data?["method"] as? String, "jaccard")

            let rankings = data?["rankings"] as? [[String: Any]]
            XCTAssertNotNil(rankings)
        } catch {
            XCTFail("Jaccard similarity ranking should succeed: \(error.localizedDescription)")
        }
    }

    func testWeightedSimilarityRanking() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "query": AnyCodable("Technical audio specifications and measurements"),
            "candidates": AnyCodable([
                "General audio overview",
                "Detailed technical specifications with frequency response",
                "Simple description of audio equipment",
                "Comprehensive technical analysis with measurements"
            ]),
            "rankingMethod": AnyCodable("weighted"),
            "weights": AnyCodable(["technical": 0.9, "semantic": 0.3])
        ] as [String: AnyCodable]

        do {
            let result = try await similarityTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            XCTAssertEqual(data?["method"] as? String, "weighted")

            let rankings = data?["rankings"] as? [[String: Any]]
            XCTAssertNotNil(rankings)
        } catch {
            XCTFail("Weighted similarity ranking should succeed: \(error.localizedDescription)")
        }
    }

    // MARK: - Content Type Tests

    func testPluginDescriptionContentType() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "query": AnyCodable("Vintage compressor plugin with tube emulation"),
            "candidates": AnyCodable([
                "Modern digital compressor with transparent sound",
                "Analog tube compressor for professional mixing",
                "Free basic compressor plugin",
                "Premium mastering compressor with precision control"
            ]),
            "contentType": AnyCodable("plugin_description")
        ] as [String: AnyCodable]

        do {
            let result = try await similarityTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            XCTAssertEqual(data?["contentType"] as? String, "plugin_description")

            let rankings = data?["rankings"] as? [[String: Any]]
            XCTAssertNotNil(rankings)

            // Verify metadata for plugin descriptions
            if let rankings = rankings, let firstRanking = rankings.first {
                let metadata = firstRanking["metadata"] as? [String: Any]
                XCTAssertNotNil(metadata?["pluginType"])
                XCTAssertNotNil(metadata?["vendor"])
                XCTAssertNotNil(metadata?["priceRange"])
            }
        } catch {
            XCTFail("Plugin description content type should succeed: \(error.localizedDescription)")
        }
    }

    func testSessionNotesContentType() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "query": AnyCodable("Recording session setup with vintage microphones"),
            "candidates": AnyCodable([
                "Mixing session notes with EQ settings",
                "Mastering session documentation",
                "Tracking session with microphone placement details",
                "Live sound setup checklist"
            ]),
            "contentType": AnyCodable("session_notes")
        ] as [String: AnyCodable]

        do {
            let result = try await similarityTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            XCTAssertEqual(data?["contentType"] as? String, "session_notes")

            let rankings = data?["rankings"] as? [[String: Any]]
            XCTAssertNotNil(rankings)
        } catch {
            XCTFail("Session notes content type should succeed: \(error.localizedDescription)")
        }
    }

    func testFeedbackContentType() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "query": AnyCodable("Client feedback about vocal mix"),
            "candidates": AnyCodable([
                "Positive review of instrumental arrangement",
                "Negative comments about drum balance",
                "Mixed feedback on overall production",
                "Specific requests for vocal adjustments"
            ]),
            "contentType": AnyCodable("feedback")
        ] as [String: AnyCodable]

        do {
            let result = try await similarityTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            XCTAssertEqual(data?["contentType"] as? String, "feedback")

            let rankings = data?["rankings"] as? [[String: Any]]
            XCTAssertNotNil(rankings)
        } catch {
            XCTFail("Feedback content type should succeed: \(error.localizedDescription)")
        }
    }

    // MARK: - Threshold Tests

    func testThresholdFiltering() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "query": AnyCodable("Vintage audio equipment"),
            "candidates": AnyCodable([
                "Modern digital plugin",
                "Analog vintage compressor",
                "Computer software",
                "Tube microphone from 1960s",
                "Audio interface",
                "Vintage tape machine"
            ]),
            "threshold": AnyCodable(0.3)
        ] as [String: AnyCodable]

        do {
            let result = try await similarityTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            XCTAssertEqual(data?["threshold"] as? Double, 0.3)

            let totalCandidates = data?["totalCandidates"] as? Int ?? 0
            let processedCandidates = data?["processedCandidates"] as? Int ?? 0

            // Some candidates might be filtered out by threshold
            XCTAssertLessThanOrEqual(processedCandidates, totalCandidates)

            // Verify all results meet threshold
            let rankings = data?["rankings"] as? [[String: Any]]
            for ranking in rankings ?? [] {
                let similarityScore = ranking["similarityScore"] as? Double ?? 0.0
                XCTAssertGreaterThanOrEqual(similarityScore, 0.3)
            }
        } catch {
            XCTFail("Threshold filtering should succeed: \(error.localizedDescription)")
        }
    }

    func testHighThresholdFiltering() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "query": AnyCodable("Specific audio plugin feature"),
            "candidates": AnyCodable([
                "Unrelated content",
                "Different topic entirely",
                "Completely different subject"
            ]),
            "threshold": AnyCodable(0.9) // Very high threshold
        ] as [String: AnyCodable]

        do {
            let result = try await similarityTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            let processedCandidates = data?["processedCandidates"] as? Int ?? 0

            // With high threshold and unrelated content, few or no results
            XCTAssertLessThanOrEqual(processedCandidates, 3)
        } catch {
            XCTFail("High threshold filtering should succeed: \(error.localizedDescription)")
        }
    }

    // MARK: - Max Results Tests

    func testMaxResultsLimiting() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "query": AnyCodable("Audio equipment"),
            "candidates": AnyCodable([
                "Microphone",
                "Audio interface",
                "Headphones",
                "Studio monitors",
                "Cables",
                "Computer",
                "Software",
                "MIDI controller",
                "Mixing console",
                "Compressor plugin",
                "EQ plugin",
                "Reverb plugin"
            ]),
            "maxResults": AnyCodable(5)
        ] as [String: AnyCodable]

        do {
            let result = try await similarityTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            let totalCandidates = data?["totalCandidates"] as? Int ?? 0
            let rankings = data?["rankings"] as? [[String: Any]]

            XCTAssertEqual(totalCandidates, 12)
            XCTAssertLessThanOrEqual(rankings?.count ?? 0, 5)
        } catch {
            XCTFail("Max results limiting should succeed: \(error.localizedDescription)")
        }
    }

    // MARK: - Detailed Similarity Tests

    func testIncludeDetailsTrue() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "query": AnyCodable("Vintage audio compressor"),
            "candidates": AnyCodable([
                "Modern digital compressor",
                "Analog tube compressor emulation"
            ]),
            "includeDetails": AnyCodable(true)
        ] as [String: AnyCodable]

        do {
            let result = try await similarityTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            let rankings = data?["rankings"] as? [[String: Any]]

            // Verify similarity details are included
            for ranking in rankings ?? [] {
                let similarityDetails = ranking["similarityDetails"] as? [String: Any]
                XCTAssertNotNil(similarityDetails)

                if let details = similarityDetails {
                    XCTAssertNotNil(details["cosineSimilarity"])
                    XCTAssertNotNil(details["analysisText"])
                }
            }
        } catch {
            XCTFail("Include details should succeed: \(error.localizedDescription)")
        }
    }

    func testIncludeDetailsFalse() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "query": AnyCodable("Audio plugin"),
            "candidates": AnyCodable([
                "Compressor plugin",
                "EQ plugin"
            ]),
            "includeDetails": AnyCodable(false)
        ] as [String: AnyCodable]

        do {
            let result = try await similarityTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            let rankings = data?["rankings"] as? [[String: Any]]

            // Verify similarity details are not included
            for ranking in rankings ?? [] {
                let similarityDetails = ranking["similarityDetails"]
                XCTAssertNil(similarityDetails)
            }
        } catch {
            XCTFail("Exclude details should succeed: \(error.localizedDescription)")
        }
    }

    // MARK: - Output Structure Tests

    func testSimilarityRankingOutputStructure() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "query": AnyCodable("Complete test query for output structure validation"),
            "candidates": AnyCodable([
                "Test candidate 1",
                "Test candidate 2",
                "Test candidate 3"
            ]),
            "contentType": AnyCodable("session_notes"),
            "rankingMethod": AnyCodable("cosine"),
            "maxResults": AnyCodable(10),
            "threshold": AnyCodable(0.1),
            "includeDetails": AnyCodable(true)
        ] as [String: AnyCodable]

        do {
            let result = try await similarityTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]

            // Verify all required fields exist
            let requiredFields = ["query", "rankings", "method", "contentType", "totalCandidates", "processedCandidates", "averageSimilarity", "processingTime", "generatedAt"]
            for field in requiredFields {
                XCTAssertNotNil(data?[field], "Required field '\(field)' should not be nil")
            }

            // Verify field types
            XCTAssertTrue(data?["query"] is String)
            XCTAssertTrue(data?["rankings"] is [[String: Any]])
            XCTAssertTrue(data?["method"] is String)
            XCTAssertTrue(data?["contentType"] is String)
            XCTAssertTrue(data?["totalCandidates"] is Int)
            XCTAssertTrue(data?["processedCandidates"] is Int)
            XCTAssertTrue(data?["averageSimilarity"] is Double)
            XCTAssertTrue(data?["processingTime"] is String)
            XCTAssertTrue(data?["generatedAt"] is String)

            // Verify specific values
            XCTAssertEqual(data?["query"] as? String, "Complete test query for output structure validation")
            XCTAssertEqual(data?["method"] as? String, "cosine")
            XCTAssertEqual(data?["contentType"] as? String, "session_notes")
            XCTAssertEqual(data?["totalCandidates"] as? Int, 3)

            // Verify rankings structure
            let rankings = data?["rankings"] as? [[String: Any]]
            XCTAssertNotNil(rankings)

            for ranking in rankings ?? [] {
                // Verify ranking result structure
                XCTAssertNotNil(ranking["id"])
                XCTAssertNotNil(ranking["content"])
                XCTAssertNotNil(ranking["similarityScore"])
                XCTAssertNotNil(ranking["rank"])
                XCTAssertNotNil(ranking["metadata"])
                XCTAssertNotNil(ranking["confidence"])

                // Verify field types
                XCTAssertTrue(ranking["id"] is String)
                XCTAssertTrue(ranking["content"] is String)
                XCTAssertTrue(ranking["similarityScore"] is Double)
                XCTAssertTrue(ranking["rank"] is Int)
                XCTAssertTrue(ranking["metadata"] is [String: Any])
                XCTAssertTrue(ranking["confidence"] is Double)

                // Verify score range
                let score = ranking["similarityScore"] as? Double ?? 0.0
                XCTAssertGreaterThanOrEqual(score, -1.0)
                XCTAssertLessThanOrEqual(score, 1.0)

                // Verify confidence range
                let confidence = ranking["confidence"] as? Double ?? 0.0
                XCTAssertGreaterThanOrEqual(confidence, 0.0)
                XCTAssertLessThanOrEqual(confidence, 1.0)
            }
        } catch {
            XCTFail("Similarity ranking output structure should be valid: \(error.localizedDescription)")
        }
    }

    // MARK: - Processing Time Tests

    func testProcessingTimeFormat() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "query": AnyCodable("Test query for processing time validation"),
            "candidates": AnyCodable(["Candidate 1", "Candidate 2"])
        ] as [String: AnyCodable]

        do {
            let result = try await similarityTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            let processingTime = data?["processingTime"] as? String

            XCTAssertNotNil(processingTime)
            XCTAssertTrue(processingTime?.contains("ms") ?? false)

            // Verify processing time is reasonable
            let timeValue = Double(processingTime?.replacingOccurrences(of: " ms", with: "") ?? "0") ?? 0
            XCTAssertGreaterThan(timeValue, 0)
            XCTAssertLessThan(timeValue, 10000) // Should be less than 10 seconds
        } catch {
            XCTFail("Processing time format should be valid: \(error.localizedDescription)")
        }
    }

    // MARK: - Average Similarity Tests

    func testAverageSimilarityCalculation() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "query": AnyCodable("Audio equipment test"),
            "candidates": AnyCodable([
                "Related audio content",
                "Similar audio equipment",
                "Different topic"
            ])
        ] as [String: AnyCodable]

        do {
            let result = try await similarityTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            let averageSimilarity = data?["averageSimilarity"] as? Double
            let rankings = data?["rankings"] as? [[String: Any]]

            XCTAssertNotNil(averageSimilarity)
            XCTAssertGreaterThanOrEqual(averageSimilarity ?? -1, 0.0)
            XCTAssertLessThanOrEqual(averageSimilarity ?? 2, 1.0)

            // Verify average similarity matches calculated average
            if let rankings = rankings, !rankings.isEmpty {
                let calculatedAverage = rankings.compactMap { $0["similarityScore"] as? Double }.reduce(0, +) / Double(rankings.count)
                XCTAssertEqual(abs((averageSimilarity ?? 0) - calculatedAverage), 0.01, accuracy: 0.01)
            }
        } catch {
            XCTFail("Average similarity calculation should be valid: \(error.localizedDescription)")
        }
    }

    // MARK: - Metadata Tests

    func testMetadataGeneration() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "query": AnyCodable("Test query"),
            "candidates": AnyCodable([
                "Waves compressor plugin for professional mixing",
                "Recording session notes with vintage microphone setup",
                "Client feedback about mix - love the warmth but need more clarity",
                "Technical specifications: Frequency response 20Hz-20kHz, THD 0.005%"
            ]),
            "contentType": AnyCodable("plugin_description")
        ] as [String: AnyCodable]

        do {
            let result = try await similarityTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            let rankings = data?["rankings"] as? [[String: Any]]

            // Verify metadata is generated for each ranking
            for ranking in rankings ?? [] {
                let metadata = ranking["metadata"] as? [String: Any]
                XCTAssertNotNil(metadata)

                if let metadata = metadata {
                    XCTAssertNotNil(metadata["contentType"])
                    XCTAssertNotNil(metadata["length"])
                    XCTAssertNotNil(metadata["wordCount"])
                }
            }
        } catch {
            XCTFail("Metadata generation should succeed: \(error.localizedDescription)")
        }
    }

    // MARK: - Timestamp Tests

    func testGeneratedAtTimestamp() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "query": AnyCodable("Test query"),
            "candidates": AnyCodable(["Test candidate"])
        ] as [String: AnyCodable]

        do {
            let result = try await similarityTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            let generatedAt = data?["generatedAt"] as? String

            XCTAssertNotNil(generatedAt)
            XCTAssertFalse(generatedAt?.isEmpty ?? true)

            // Verify ISO8601 format
            let formatter = ISO8601DateFormatter()
            let parsedDate = formatter.date(from: generatedAt ?? "")
            XCTAssertNotNil(parsedDate)

            // Verify timestamp is recent (within 1 minute)
            if let date = parsedDate {
                let timeDifference = Date().timeIntervalSince(date)
                XCTAssertLessThan(timeDifference, 60)
            }
        } catch {
            XCTFail("Generated timestamp should be valid: \(error.localizedDescription)")
        }
    }

    // MARK: - Error Handling Tests

    func testEmptyQueryError() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "query": AnyCodable(""),
            "candidates": AnyCodable(["Candidate 1"])
        ] as [String: AnyCodable]

        do {
            let result = try await similarityTool.performExecution(parameters: parameters, context: context)
            XCTFail("Empty query should throw an error")
        } catch {
            XCTAssertTrue(error is SimilarityRankingTool.SimilarityError)
            if let similarityError = error as? SimilarityRankingTool.SimilarityError {
                switch similarityError {
                case .invalidEmbedding(let message):
                    XCTAssertTrue(message.contains("Query is required"))
                default:
                    XCTFail("Expected invalidEmbedding error")
                }
            }
        }
    }

    func testMissingQueryError() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "candidates": AnyCodable(["Candidate 1"])
        ] as [String: AnyCodable]

        do {
            let result = try await similarityTool.performExecution(parameters: parameters, context: context)
            XCTFail("Missing query should throw an error")
        } catch {
            XCTAssertTrue(error is SimilarityRankingTool.SimilarityError)
        }
    }

    func testEmptyCandidatesError() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "query": AnyCodable("Test query"),
            "candidates": AnyCodable([String]())
        ] as [String: AnyCodable]

        do {
            let result = try await similarityTool.performExecution(parameters: parameters, context: context)
            XCTFail("Empty candidates should throw an error")
        } catch {
            XCTAssertTrue(error is SimilarityRankingTool.SimilarityError)
            if let similarityError = error as? SimilarityRankingTool.SimilarityError {
                switch similarityError {
                case .invalidEmbedding(let message):
                    XCTAssertTrue(message.contains("Candidates are required"))
                default:
                    XCTFail("Expected invalidEmbedding error")
                }
            }
        }
    }

    func testMissingCandidatesError() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "query": AnyCodable("Test query")
        ] as [String: AnyCodable]

        do {
            let result = try await similarityTool.performExecution(parameters: parameters, context: context)
            XCTFail("Missing candidates should throw an error")
        } catch {
            XCTAssertTrue(error is SimilarityRankingTool.SimilarityError)
        }
    }

    func testInvalidRankingMethodError() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "query": AnyCodable("Test query"),
            "candidates": AnyCodable(["Candidate 1"]),
            "rankingMethod": AnyCodable("invalid_method")
        ] as [String: AnyCodable]

        do {
            let result = try await similarityTool.performExecution(parameters: parameters, context: context)
            XCTFail("Invalid ranking method should throw an error")
        } catch {
            XCTAssertTrue(error is SimilarityRankingTool.SimilarityError)
            if let similarityError = error as? SimilarityRankingTool.SimilarityError {
                switch similarityError {
                case .invalidMethod(let method):
                    XCTAssertEqual(method, "invalid_method")
                default:
                    XCTFail("Expected invalidMethod error")
                }
            }
        }
    }

    // MARK: - Edge Cases Tests

    func testSimilarityRankingWithContextMetadata() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [
                "requestSource": "unit_test",
                "testType": "edge_case",
                "timestamp": ISO8601DateFormatter().string(from: Date())
            ]
        )

        let parameters = [
            "query": AnyCodable("Test query with context metadata"),
            "candidates": AnyCodable(["Test candidate"])
        ] as [String: AnyCodable]

        do {
            let result = try await similarityTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)
            XCTAssertNotNil(result.data)
        } catch {
            XCTFail("Similarity ranking with context metadata should succeed: \(error.localizedDescription)")
        }
    }

    func testSingleCandidate() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "query": AnyCodable("Test query"),
            "candidates": AnyCodable(["Single candidate"])
        ] as [String: AnyCodable]

        do {
            let result = try await similarityTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            XCTAssertEqual(data?["totalCandidates"] as? Int, 1)

            let rankings = data?["rankings"] as? [[String: Any]]
            XCTAssertEqual(rankings?.count, 1)

            if let firstRanking = rankings?.first {
                XCTAssertEqual(firstRanking["rank"] as? Int, 1)
                XCTAssertEqual(firstRanking["content"] as? String, "Single candidate")
            }
        } catch {
            XCTFail("Single candidate should succeed: \(error.localizedDescription)")
        }
    }

    func testLargeNumberOfCandidates() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let candidates = (1...50).map { "Test candidate \($0)" }

        let parameters = [
            "query": AnyCodable("Test query for large candidate set"),
            "candidates": AnyCodable(candidates),
            "maxResults": AnyCodable(20)
        ] as [String: AnyCodable]

        do {
            let result = try await similarityTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            XCTAssertEqual(data?["totalCandidates"] as? Int, 50)

            let rankings = data?["rankings"] as? [[String: Any]]
            XCTAssertLessThanOrEqual(rankings?.count ?? 0, 20)
        } catch {
            XCTFail("Large number of candidates should succeed: \(error.localizedDescription)")
        }
    }

    func testSpecialCharactersInContent() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "query": AnyCodable("Audio session @ 20Hz-20kHz ±0.5dB with THD <0.005%"),
            "candidates": AnyCodable([
                "Frequency response: 20Hz-20kHz (+/-0.5dB), THD: 0.005%",
                "Sample rate: 192kHz, Bit depth: 24-bit, Latency: <2ms",
                "Dynamic range: 120dB, SNR: 115dB, Channel: stereo"
            ])
        ] as [String: AnyCodable]

        do {
            let result = try await similarityTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            let rankings = data?["rankings"] as? [[String: Any]]
            XCTAssertNotNil(rankings)
        } catch {
            XCTFail("Special characters in content should succeed: \(error.localizedDescription)")
        }
    }

    // MARK: - Performance Tests

    func testSimilarityRankingPerformance() {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "query": AnyCodable("Test query for performance measurement"),
            "candidates": AnyCodable([
                "Test candidate 1",
                "Test candidate 2",
                "Test candidate 3",
                "Test candidate 4",
                "Test candidate 5"
            ])
        ] as [String: AnyCodable]

        measure {
            let expectation = XCTestExpectation(description: "Similarity ranking performance")
            Task {
                do {
                    let result = try await similarityTool.performExecution(parameters: parameters, context: context)
                    XCTAssertTrue(result.success)
                } catch {
                    XCTFail("Performance test should not fail: \(error.localizedDescription)")
                }
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 15.0)
        }
    }

    func testConcurrentSimilarityRanking() {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let concurrentRequests = 3

        measure {
            let expectation = XCTestExpectation(description: "Concurrent similarity ranking")
            expectation.expectedFulfillmentCount = concurrentRequests

            for i in 0..<concurrentRequests {
                let parameters = [
                    "query": AnyCodable("Test query \(i) for concurrent similarity ranking"),
                    "candidates": AnyCodable([
                        "Candidate 1 for query \(i)",
                        "Candidate 2 for query \(i)",
                        "Candidate 3 for query \(i)"
                    ])
                ] as [String: AnyCodable]

                Task {
                    do {
                        let result = try await similarityTool.performExecution(parameters: parameters, context: context)
                        XCTAssertTrue(result.success, "Request \(i) should succeed")
                    } catch {
                        XCTFail("Concurrent request \(i) should not fail: \(error.localizedDescription)")
                    }
                    expectation.fulfill()
                }
            }

            wait(for: [expectation], timeout: 20.0)
        }
    }

    // MARK: - Different Content Types Performance

    func testAllContentTypesPerformance() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let contentTypes = [
            "session_notes",
            "plugin_description",
            "feedback",
            "technical_spec",
            "equipment_list",
            "audio_description",
            "mix_notes"
        ]

        for contentType in contentTypes {
            let parameters = [
                "query": AnyCodable("Test query for \(contentType)"),
                "candidates": AnyCodable([
                    "Test candidate 1 for \(contentType)",
                    "Test candidate 2 for \(contentType)"
                ]),
                "contentType": AnyCodable(contentType)
            ] as [String: AnyCodable]

            do {
                let result = try await similarityTool.performExecution(parameters: parameters, context: context)
                XCTAssertTrue(result.success, "Content type \(contentType) should succeed")

                let data = result.data?.value as? [String: Any]
                XCTAssertEqual(data?["contentType"] as? String, contentType)
            } catch {
                XCTFail("Content type \(contentType) should succeed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Ranking Method Performance

    func testAllRankingMethodsPerformance() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let rankingMethods = ["cosine", "euclidean", "jaccard", "weighted"]

        for method in rankingMethods {
            let parameters = [
                "query": AnyCodable("Test query for \(method) method"),
                "candidates": AnyCodable([
                    "Test candidate 1",
                    "Test candidate 2",
                    "Test candidate 3"
                ]),
                "rankingMethod": AnyCodable(method)
            ] as [String: AnyCodable]

            do {
                let result = try await similarityTool.performExecution(parameters: parameters, context: context)
                XCTAssertTrue(result.success, "Ranking method \(method) should succeed")

                let data = result.data?.value as? [String: Any]
                XCTAssertEqual(data?["method"] as? String, method)
            } catch {
                XCTFail("Ranking method \(method) should succeed: \(error.localizedDescription)")
            }
        }
    }
}