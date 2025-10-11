//
//  EmbeddingGenerationToolTests.swift
//  LocalIntelligenceMCPTests
//
//  Created on 2025-10-09.
//

import XCTest
@testable import LocalIntelligenceMCP

final class EmbeddingGenerationToolTests: XCTestCase {

    var embeddingTool: EmbeddingGenerationTool!

    override func setUp() async throws {
        try await super.setUp()
        embeddingTool = EmbeddingGenerationTool()
    }

    override func tearDown() async throws {
        embeddingTool = nil
        try await super.tearDown()
    }

    // MARK: - Tool Initialization Tests

    func testToolInitialization() throws {
        XCTAssertEqual(embeddingTool.name, "embedding_generation")
        XCTAssertFalse(embeddingTool.description.isEmpty)

        // Verify input schema structure
        let schema = embeddingTool.inputSchema
        XCTAssertEqual(schema["type"] as? String, "object")

        let properties = schema["properties"] as? [String: Any]
        XCTAssertNotNil(properties)

        // Check required properties
        let requiredProperties = schema["required"] as? [String]
        XCTAssertEqual(requiredProperties, ["content"])

        // Check optional properties
        XCTAssertNotNil(properties?["content"])
        XCTAssertNotNil(properties?["contentType"])
        XCTAssertNotNil(properties?["embeddingModel"])
        XCTAssertNotNil(properties?["dimensions"])
        XCTAssertNotNil(properties?["normalize"])
        XCTAssertNotNil(properties?["metadata"])
    }

    func testInputSchemaDefaults() throws {
        let schema = embeddingTool.inputSchema
        let properties = schema["properties"] as? [String: Any]

        // Test default values
        XCTAssertEqual(properties?["contentType"] as? [String: Any]?["default"] as? String, "text")
        XCTAssertEqual(properties?["embeddingModel"] as? [String: Any]?["default"] as? String, "audio-domain")
        XCTAssertEqual(properties?["dimensions"] as? [String: Any]?["default"] as? Int, 768)
        XCTAssertEqual(properties?["normalize"] as? [String: Any]?["default"] as? Bool, true)
    }

    func testContentTypeEnumValues() throws {
        let schema = embeddingTool.inputSchema
        let properties = schema["properties"] as? [String: Any]

        let contentTypeProperty = properties?["contentType"] as? [String: Any]
        let enumValues = contentTypeProperty?["enum"] as? [String]

        let expectedTypes = [
            "text",
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

    func testEmbeddingModelEnumValues() throws {
        let schema = embeddingTool.inputSchema
        let properties = schema["properties"] as? [String: Any]

        let modelProperty = properties?["embeddingModel"] as? [String: Any]
        let enumValues = modelProperty?["enum"] as? [String]

        let expectedModels = ["audio-domain", "general", "technical", "semantic"]
        XCTAssertEqual(enumValues, expectedModels)
    }

    func testDimensionsConstraints() throws {
        let schema = embeddingTool.inputSchema
        let properties = schema["properties"] as? [String: Any]

        let dimensionsProperty = properties?["dimensions"] as? [String: Any]
        XCTAssertEqual(dimensionsProperty?["minimum"] as? Int, 128)
        XCTAssertEqual(dimensionsProperty?["maximum"] as? Int, 1536)
    }

    // MARK: - Basic Execution Tests

    func testBasicEmbeddingGeneration() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "content": AnyCodable("Test audio session content for embedding generation")
        ] as [String: AnyCodable]

        do {
            let result = try await embeddingTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)
            XCTAssertNotNil(result.data)
            XCTAssertNil(result.error)
        } catch {
            XCTFail("Basic embedding generation should succeed: \(error.localizedDescription)")
        }
    }

    func testEmbeddingWithDefaultParameters() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "content": AnyCodable("Recording session with vintage microphone and warm compression")
        ] as [String: AnyCodable]

        do {
            let result = try await embeddingTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            XCTAssertNotNil(data)

            // Verify embedding output structure
            XCTAssertNotNil(data?["embedding"])
            XCTAssertNotNil(data?["dimensions"])
            XCTAssertNotNil(data?["model"])
            XCTAssertNotNil(data?["contentType"])
            XCTAssertNotNil(data?["normalized"])
            XCTAssertNotNil(data?["processingTime"])
            XCTAssertNotNil(data?["confidence"])
            XCTAssertNotNil(data?["tokens"])
            XCTAssertNotNil(data?["generatedAt"])

            // Verify default values
            XCTAssertEqual(data?["model"] as? String, "audio-domain")
            XCTAssertEqual(data?["contentType"] as? String, "text")
            XCTAssertEqual(data?["normalized"] as? Bool, true)
            XCTAssertEqual(data?["dimensions"] as? Int, 768)
        } catch {
            XCTFail("Embedding with default parameters should succeed: \(error.localizedDescription)")
        }
    }

    // MARK: - Input Parameter Tests

    func testEmbeddingInputParsing() throws {
        let parameters = [
            "content": AnyCodable("Test content"),
            "contentType": AnyCodable("session_notes"),
            "embeddingModel": AnyCodable("technical"),
            "dimensions": AnyCodable(512),
            "normalize": AnyCodable(false),
            "metadata": AnyCodable(["source": "test"])
        ] as [String: AnyCodable]

        let input = try EmbeddingGenerationTool.EmbeddingInput(from: parameters)

        XCTAssertEqual(input.content, "Test content")
        XCTAssertEqual(input.contentType, "session_notes")
        XCTAssertEqual(input.embeddingModel, "technical")
        XCTAssertEqual(input.dimensions, 512)
        XCTAssertFalse(input.normalize ?? false)
        XCTAssertEqual(input.metadata?["source"]?.value as? String, "test")
    }

    func testEmbeddingInputWithRequiredOnly() throws {
        let parameters = [
            "content": AnyCodable("Minimal content")
        ] as [String: AnyCodable]

        let input = try EmbeddingGenerationTool.EmbeddingInput(from: parameters)

        XCTAssertEqual(input.content, "Minimal content")
        XCTAssertEqual(input.contentType, "text") // Default
        XCTAssertNil(input.embeddingModel)
        XCTAssertNil(input.dimensions)
        XCTAssertNil(input.normalize)
        XCTAssertNil(input.metadata)
    }

    // MARK: - Content Type Tests

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
            "content": AnyCodable("Recording session with Neumann U87 microphone, API preamp, tracking vocals for 4 hours"),
            "contentType": AnyCodable("session_notes")
        ] as [String: AnyCodable]

        do {
            let result = try await embeddingTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            XCTAssertEqual(data?["contentType"] as? String, "session_notes")
            XCTAssertNotNil(data?["embedding"])
            XCTAssertEqual(data?["dimensions"] as? Int, 768)
        } catch {
            XCTFail("Session notes content type should succeed: \(error.localizedDescription)")
        }
    }

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
            "content": AnyCodable("Vintage analog compressor emulation with tube saturation, warm character, professional VST plugin"),
            "contentType": AnyCodable("plugin_description")
        ] as [String: AnyCodable]

        do {
            let result = try await embeddingTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            XCTAssertEqual(data?["contentType"] as? String, "plugin_description")
            XCTAssertNotNil(data?["embedding"])
        } catch {
            XCTFail("Plugin description content type should succeed: \(error.localizedDescription)")
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
            "content": AnyCodable("Love the warm vocal sound but need more clarity in the high frequencies. Great compression character!"),
            "contentType": AnyCodable("feedback")
        ] as [String: AnyCodable]

        do {
            let result = try await embeddingTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            XCTAssertEqual(data?["contentType"] as? String, "feedback")
            XCTAssertNotNil(data?["embedding"])
        } catch {
            XCTFail("Feedback content type should succeed: \(error.localizedDescription)")
        }
    }

    func testTechnicalSpecContentType() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "content": AnyCodable("Frequency response: 20Hz-20kHz (+/-0.5dB), THD: 0.005%, Sample rate: 192kHz, Bit depth: 24-bit"),
            "contentType": AnyCodable("technical_spec")
        ] as [String: AnyCodable]

        do {
            let result = try await embeddingTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            XCTAssertEqual(data?["contentType"] as? String, "technical_spec")
            XCTAssertNotNil(data?["embedding"])
        } catch {
            XCTFail("Technical spec content type should succeed: \(error.localizedDescription)")
        }
    }

    // MARK: - Embedding Model Tests

    func testAudioDomainModel() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "content": AnyCodable("Mixing vocals with vintage compression and EQ processing"),
            "embeddingModel": AnyCodable("audio-domain")
        ] as [String: AnyCodable]

        do {
            let result = try await embeddingTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            XCTAssertEqual(data?["model"] as? String, "audio-domain")
            XCTAssertNotNil(data?["embedding"])
        } catch {
            XCTFail("Audio domain model should succeed: \(error.localizedDescription)")
        }
    }

    func testGeneralModel() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "content": AnyCodable("General text content for embedding generation"),
            "embeddingModel": AnyCodable("general")
        ] as [String: AnyCodable]

        do {
            let result = try await embeddingTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            XCTAssertEqual(data?["model"] as? String, "general")
            XCTAssertNotNil(data?["embedding"])
        } catch {
            XCTFail("General model should succeed: \(error.localizedDescription)")
        }
    }

    func testTechnicalModel() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "content": AnyCodable("Technical specifications with frequency response and THD measurements"),
            "embeddingModel": AnyCodable("technical")
        ] as [String: AnyCodable]

        do {
            let result = try await embeddingTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            XCTAssertEqual(data?["model"] as? String, "technical")
            XCTAssertNotNil(data?["embedding"])
        } catch {
            XCTFail("Technical model should succeed: \(error.localizedDescription)")
        }
    }

    func testSemanticModel() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "content": AnyCodable("Semantic content focusing on meaning and context"),
            "embeddingModel": AnyCodable("semantic")
        ] as [String: AnyCodable]

        do {
            let result = try await embeddingTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            XCTAssertEqual(data?["model"] as? String, "semantic")
            XCTAssertNotNil(data?["embedding"])
        } catch {
            XCTFail("Semantic model should succeed: \(error.localizedDescription)")
        }
    }

    // MARK: - Dimensions Tests

    func testCustomDimensions() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "content": AnyCodable("Test content for custom dimensions"),
            "dimensions": AnyCodable(512)
        ] as [String: AnyCodable]

        do {
            let result = try await embeddingTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            XCTAssertEqual(data?["dimensions"] as? Int, 512)

            let embedding = data?["embedding"] as? [Double]
            XCTAssertEqual(embedding?.count, 512)
        } catch {
            XCTFail("Custom dimensions should succeed: \(error.localizedDescription)")
        }
    }

    func testMinimumDimensions() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "content": AnyCodable("Test content"),
            "dimensions": AnyCodable(128)
        ] as [String: AnyCodable]

        do {
            let result = try await embeddingTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            XCTAssertEqual(data?["dimensions"] as? Int, 128)

            let embedding = data?["embedding"] as? [Double]
            XCTAssertEqual(embedding?.count, 128)
        } catch {
            XCTFail("Minimum dimensions should succeed: \(error.localizedDescription)")
        }
    }

    func testMaximumDimensions() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "content": AnyCodable("Test content for maximum dimensions"),
            "dimensions": AnyCodable(1536)
        ] as [String: AnyCodable]

        do {
            let result = try await embeddingTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            XCTAssertEqual(data?["dimensions"] as? Int, 1536)

            let embedding = data?["embedding"] as? [Double]
            XCTAssertEqual(embedding?.count, 1536)
        } catch {
            XCTFail("Maximum dimensions should succeed: \(error.localizedDescription)")
        }
    }

    // MARK: - Normalization Tests

    func testNormalizationEnabled() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "content": AnyCodable("Test content for normalization"),
            "normalize": AnyCodable(true)
        ] as [String: AnyCodable]

        do {
            let result = try await embeddingTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            XCTAssertEqual(data?["normalized"] as? Bool, true)

            // Verify embedding is normalized (magnitude should be ~1.0)
            let embedding = data?["embedding"] as? [Double]
            XCTAssertNotNil(embedding)

            if let embedding = embedding {
                let magnitude = sqrt(embedding.reduce(0) { $0 + $1 * $1 })
                XCTAssertLessThan(abs(magnitude - 1.0), 0.01) // Should be very close to 1.0
            }
        } catch {
            XCTFail("Normalization enabled should succeed: \(error.localizedDescription)")
        }
    }

    func testNormalizationDisabled() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "content": AnyCodable("Test content without normalization"),
            "normalize": AnyCodable(false)
        ] as [String: AnyCodable]

        do {
            let result = try await embeddingTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            XCTAssertEqual(data?["normalized"] as? Bool, false)

            // Embedding should not be normalized
            let embedding = data?["embedding"] as? [Double]
            XCTAssertNotNil(embedding)
        } catch {
            XCTFail("Normalization disabled should succeed: \(error.localizedDescription)")
        }
    }

    // MARK: - Output Structure Tests

    func testEmbeddingOutputStructure() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "content": AnyCodable("Complete test content for output structure validation"),
            "contentType": AnyCodable("session_notes"),
            "embeddingModel": AnyCodable("audio-domain"),
            "dimensions": AnyCodable(768),
            "normalize": AnyCodable(true),
            "metadata": AnyCodable(["test": true, "source": "unit_test"])
        ] as [String: AnyCodable]

        do {
            let result = try await embeddingTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]

            // Verify all required fields exist
            let requiredFields = ["embedding", "dimensions", "model", "contentType", "normalized", "processingTime", "confidence", "tokens", "generatedAt"]
            for field in requiredFields {
                XCTAssertNotNil(data?[field], "Required field '\(field)' should not be nil")
            }

            // Verify field types
            XCTAssertTrue(data?["embedding"] is [Double])
            XCTAssertTrue(data?["dimensions"] is Int)
            XCTAssertTrue(data?["model"] is String)
            XCTAssertTrue(data?["contentType"] is String)
            XCTAssertTrue(data?["normalized"] is Bool)
            XCTAssertTrue(data?["processingTime"] is String)
            XCTAssertTrue(data?["confidence"] is Double)
            XCTAssertTrue(data?["tokens"] is Int)
            XCTAssertTrue(data?["generatedAt"] is String)

            // Verify specific values
            XCTAssertEqual(data?["model"] as? String, "audio-domain")
            XCTAssertEqual(data?["contentType"] as? String, "session_notes")
            XCTAssertEqual(data?["dimensions"] as? Int, 768)
            XCTAssertEqual(data?["normalized"] as? Bool, true)

            // Verify embedding dimensions
            let embedding = data?["embedding"] as? [Double]
            XCTAssertEqual(embedding?.count, 768)

            // Verify metadata is preserved
            let metadata = data?["metadata"] as? [String: Any]
            XCTAssertNotNil(metadata)
        } catch {
            XCTFail("Embedding output structure should be valid: \(error.localizedDescription)")
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
            "content": AnyCodable("Test content for processing time validation")
        ] as [String: AnyCodable]

        do {
            let result = try await embeddingTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            let processingTime = data?["processingTime"] as? String

            XCTAssertNotNil(processingTime)
            XCTAssertTrue(processingTime?.contains("ms") ?? false)

            // Verify processing time is reasonable
            let timeValue = Double(processingTime?.replacingOccurrences(of: " ms", with: "") ?? "0") ?? 0
            XCTAssertGreaterThan(timeValue, 0)
            XCTAssertLessThan(timeValue, 5000) // Should be less than 5 seconds
        } catch {
            XCTFail("Processing time format should be valid: \(error.localizedDescription)")
        }
    }

    // MARK: - Confidence Score Tests

    func testConfidenceScoreRange() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "content": AnyCodable("Test content for confidence score validation")
        ] as [String: AnyCodable]

        do {
            let result = try await embeddingTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            let confidence = data?["confidence"] as? Double

            XCTAssertNotNil(confidence)
            XCTAssertGreaterThanOrEqual(confidence ?? -1, 0.0)
            XCTAssertLessThanOrEqual(confidence ?? 2, 1.0)
        } catch {
            XCTFail("Confidence score should be valid: \(error.localizedDescription)")
        }
    }

    func testTokenCountEstimation() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "content": AnyCodable("This is a test sentence with multiple words for token counting.")
        ] as [String: AnyCodable]

        do {
            let result = try await embeddingTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            let tokens = data?["tokens"] as? Int

            XCTAssertNotNil(tokens)
            XCTAssertGreaterThan(tokens ?? 0, 0)
            // Should be approximately word count plus some overhead
            XCTAssertGreaterThan(tokens ?? 0, 10) // More than 10 words
            XCTAssertLessThan(tokens ?? 0, 20) // Less than 20 tokens
        } catch {
            XCTFail("Token count estimation should be valid: \(error.localizedDescription)")
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
            "content": AnyCodable("Test content for timestamp validation")
        ] as [String: AnyCodable]

        do {
            let result = try await embeddingTool.performExecution(parameters: parameters, context: context)
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

    func testEmptyContentError() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "content": AnyCodable("")
        ] as [String: AnyCodable]

        do {
            let result = try await embeddingTool.performExecution(parameters: parameters, context: context)
            XCTFail("Empty content should throw an error")
        } catch {
            XCTAssertTrue(error is EmbeddingGenerationTool.EmbeddingError)
            if let embeddingError = error as? EmbeddingGenerationTool.EmbeddingError {
                switch embeddingError {
                case .invalidContent(let message):
                    XCTAssertTrue(message.contains("Content is required"))
                default:
                    XCTFail("Expected invalidContent error")
                }
            }
        }
    }

    func testMissingContentError() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [:] as [String: AnyCodable]

        do {
            let result = try await embeddingTool.performExecution(parameters: parameters, context: context)
            XCTFail("Missing content should throw an error")
        } catch {
            XCTAssertTrue(error is EmbeddingGenerationTool.EmbeddingError)
        }
    }

    func testInvalidModelError() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "content": AnyCodable("Test content"),
            "embeddingModel": AnyCodable("invalid_model")
        ] as [String: AnyCodable]

        do {
            let result = try await embeddingTool.performExecution(parameters: parameters, context: context)
            XCTFail("Invalid model should throw an error")
        } catch {
            XCTAssertTrue(error is EmbeddingGenerationTool.EmbeddingError)
            if let embeddingError = error as? EmbeddingGenerationTool.EmbeddingError {
                switch embeddingError {
                case .invalidModel(let model):
                    XCTAssertEqual(model, "invalid_model")
                default:
                    XCTFail("Expected invalidModel error")
                }
            }
        }
    }

    // MARK: - Edge Cases Tests

    func testEmbeddingWithContextMetadata() async throws {
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
            "content": AnyCodable("Test content with context metadata")
        ] as [String: AnyCodable]

        do {
            let result = try await embeddingTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)
            XCTAssertNotNil(result.data)
        } catch {
            XCTFail("Embedding with context metadata should succeed: \(error.localizedDescription)")
        }
    }

    func testVeryLongContent() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let longContent = String(repeating: "This is a long content for testing embedding generation with lengthy text. ", count: 100)

        let parameters = [
            "content": AnyCodable(longContent)
        ] as [String: AnyCodable]

        do {
            let result = try await embeddingTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            XCTAssertNotNil(data?["embedding"])
        } catch {
            XCTFail("Very long content should succeed: \(error.localizedDescription)")
        }
    }

    func testSpecialCharactersContent() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "content": AnyCodable("Audio session @ 20Hz-20kHz ±0.5dB with THD <0.005% & latency <2ms")
        ] as [String: AnyCodable]

        do {
            let result = try await embeddingTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            XCTAssertNotNil(data?["embedding"])
        } catch {
            XCTFail("Special characters content should succeed: \(error.localizedDescription)")
        }
    }

    func testUnicodeContent() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "content": AnyCodable("Recording session with microphone 🎤 and compression 🔥 for audio production 🎵")
        ] as [String: AnyCodable]

        do {
            let result = try await embeddingTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            XCTAssertNotNil(data?["embedding"])
        } catch {
            XCTFail("Unicode content should succeed: \(error.localizedDescription)")
        }
    }

    // MARK: - Performance Tests

    func testEmbeddingGenerationPerformance() {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "content": AnyCodable("Test content for performance measurement")
        ] as [String: AnyCodable]

        measure {
            let expectation = XCTestExpectation(description: "Embedding generation performance")
            Task {
                do {
                    let result = try await embeddingTool.performExecution(parameters: parameters, context: context)
                    XCTAssertTrue(result.success)
                } catch {
                    XCTFail("Performance test should not fail: \(error.localizedDescription)")
                }
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 10.0)
        }
    }

    func testConcurrentEmbeddingGeneration() {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let concurrentRequests = 5

        measure {
            let expectation = XCTestExpectation(description: "Concurrent embedding generation")
            expectation.expectedFulfillmentCount = concurrentRequests

            for i in 0..<concurrentRequests {
                let parameters = [
                    "content": AnyCodable("Test content \(i) for concurrent embedding generation")
                ] as [String: AnyCodable]

                Task {
                    do {
                        let result = try await embeddingTool.performExecution(parameters: parameters, context: context)
                        XCTAssertTrue(result.success, "Request \(i) should succeed")
                    } catch {
                        XCTFail("Concurrent request \(i) should not fail: \(error.localizedDescription)")
                    }
                    expectation.fulfill()
                }
            }

            wait(for: [expectation], timeout: 15.0)
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
            "text", "session_notes", "plugin_description", "feedback",
            "technical_spec", "equipment_list", "audio_description", "mix_notes"
        ]

        for contentType in contentTypes {
            let parameters = [
                "content": AnyCodable("Test content for \(contentType)"),
                "contentType": AnyCodable(contentType)
            ] as [String: AnyCodable]

            do {
                let result = try await embeddingTool.performExecution(parameters: parameters, context: context)
                XCTAssertTrue(result.success, "Content type \(contentType) should succeed")

                let data = result.data?.value as? [String: Any]
                XCTAssertEqual(data?["contentType"] as? String, contentType)
            } catch {
                XCTFail("Content type \(contentType) should succeed: \(error.localizedDescription)")
            }
        }
    }
}