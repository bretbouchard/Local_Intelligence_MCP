//
//  TextRewriteToolTests.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-08.
//

import XCTest
@testable import LocalIntelligenceMCP

final class TextRewriteToolTests: XCTestCase {

    // MARK: - Properties

    private var logger: Logger!
    private var securityManager: SecurityManager!
    private var textRewriteTool: TextRewriteTool!

    // MARK: - Setup and Teardown

    override func setUp() async throws {
        try await super.setUp()

        // Initialize test components
        let config = LoggingConfiguration.default
        logger = Logger(configuration: config)
        await logger.setupFileLoggingIfNeeded()

        securityManager = SecurityManager(logger: logger)
        textRewriteTool = TextRewriteTool(logger: logger, securityManager: securityManager)
    }

    override func tearDown() async throws {
        logger = nil
        securityManager = nil
        textRewriteTool = nil

        try await super.tearDown()
    }

    // MARK: - Tool Initialization Tests

    func testTextRewriteToolInitialization() async throws {
        XCTAssertNotNil(textRewriteTool)
        XCTAssertEqual(textRewriteTool.name, "apple.text.rewrite")
        XCTAssertFalse(textRewriteTool.description.isEmpty)
        XCTAssertNotNil(textRewriteTool.inputSchema)
        XCTAssertEqual(textRewriteTool.category, .textProcessing)
        XCTAssertTrue(textRewriteTool.requiresPermission.contains(.systemInfo))
        XCTAssertTrue(textRewriteTool.offlineCapable)
    }

    func testInputSchemaStructure() async throws {
        let schema = textRewriteTool.inputSchema

        // Check basic schema structure
        XCTAssertEqual(schema["type"] as? String, "object")

        // Check properties exist
        let properties = schema["properties"]?.value as? [String: Any]
        XCTAssertNotNil(properties)
        XCTAssertNotNil(properties?["text"])
        XCTAssertNotNil(properties?["tone"])
        XCTAssertNotNil(properties?["length"])

        // Check required fields
        let required = schema["required"]?.value as? [String]
        XCTAssertTrue(required?.contains("text") == true)
    }

    // MARK: - Tone Transformation Tests

    func testTechnicalToneTransformation() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: textRewriteTool.name
        )

        let casualAudioText = """
        I need to fix the vocals in the mix. The sound is kinda muddy. Let's make it better by adjusting the EQ.
        We should work on the recording to make it sound more professional. The track needs some help.
        """

        let parameters = [
            "text": casualAudioText,
            "tone": "technical"
        ] as [String: AnyCodable]

        do {
            let result = try await textRewriteTool.execute(parameters: parameters, context: context)
            XCTAssertTrue(result.success)
            XCTAssertNotNil(result.data)

            if let data = result.data?.value as? [String: Any],
               let rewrittenText = data["text"] as? String {
                XCTAssertFalse(rewrittenText.isEmpty)
                // Should contain technical terminology
                XCTAssertTrue(rewrittenText.contains("rectify") || rewrittenText.contains("optimize") ||
                             rewrittenText.contains("audio signal") || rewrittenText.contains("modify"))
                // Should avoid casual language
                XCTAssertFalse(rewrittenText.contains("kinda"))
            }
        } catch {
            XCTFail("Technical tone transformation should succeed: \(error.localizedDescription)")
        }
    }

    func testFriendlyToneTransformation() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: textRewriteTool.name
        )

        let technicalAudioText = """
        The audio signal requires optimization. We need to rectify the frequency response issues
        by implementing equalization adjustments. The recording will be processed to enhance quality.
        """

        let parameters = [
            "text": technicalAudioText,
            "tone": "friendly"
        ] as [String: AnyCodable]

        do {
            let result = try await textRewriteTool.execute(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            if let data = result.data?.value as? [String: Any],
               let rewrittenText = data["text"] as? String {
                XCTAssertFalse(rewrittenText.isEmpty)
                // Should contain friendly language
                XCTAssertTrue(rewrittenText.contains("make better") || rewrittenText.contains("fix") ||
                             rewrittenText.contains("help"))
                // Should avoid overly technical terms
                XCTAssertFalse(rewrittenText.contains("rectify"))
            }
        } catch {
            XCTFail("Friendly tone transformation should succeed: \(error.localizedDescription)")
        }
    }

    func testExecutiveToneTransformation() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: textRewriteTool.name
        )

        let casualAudioText = """
        We gotta fix the mix problems. The vocals need work and the bass is too loud.
        Let's start working on this track to get it done right.
        """

        let parameters = [
            "text": casualAudioText,
            "tone": "executive"
        ] as [String: AnyCodable]

        do {
            let result = try await textRewriteTool.execute(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            if let data = result.data?.value as? [String: Any],
               let rewrittenText = data["text"] as? String {
                XCTAssertFalse(rewrittenText.isEmpty)
                // Should contain executive/business language
                XCTAssertTrue(rewrittenText.contains("resolve") || rewrittenText.contains("address") ||
                             rewrittenText.contains("challenge") || rewrittenText.contains("enhance"))
                // Should avoid overly casual language
                XCTAssertFalse(rewrittenText.contains("gotta"))
            }
        } catch {
            XCTFail("Executive tone transformation should succeed: \(error.localizedDescription)")
        }
    }

    func testNeutralToneTransformation() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: textRewriteTool.name
        )

        let emotionalAudioText = """
        This recording is absolutely amazing! The sound is perfect and wonderful.
        The mix is brilliant and the performance is fantastic. I love this track!
        However, there's a terrible problem with the low end that needs fixing.
        """

        let parameters = [
            "text": emotionalAudioText,
            "tone": "neutral"
        ] as [String: AnyCodable]

        do {
            let result = try await textRewriteTool.execute(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            if let data = result.data?.value as? [String: Any],
               let rewrittenText = data["text"] as? String {
                XCTAssertFalse(rewrittenText.isEmpty)
                // Should use neutral, objective language
                XCTAssertTrue(rewrittenText.contains("good") || rewrittenText.contains("effective") ||
                             rewrittenText.contains("positive") || rewrittenText.contains("notable"))
                // Should avoid overly emotional terms
                XCTAssertFalse(rewrittenText.contains("amazing") || rewrittenText.contains("fantastic") ||
                             rewrittenText.contains("terrible"))
            }
        } catch {
            XCTFail("Neutral tone transformation should succeed: \(error.localizedDescription)")
        }
    }

    // MARK: - Length Transformation Tests

    func testShortLengthTransformation() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: textRewriteTool.name
        )

        let longAudioText = """
        Session Notes: Today we worked extensively on the vocal mix. The recording was done using a Neumann U87 microphone
        running through a Neve preamp. We applied EQ to boost the highs around 8kHz and cut some mud around 200Hz.
        The compressor was set to a 4:1 ratio with medium attack and fast release. We added a touch of reverb using a Lexicon
        plugin for spatial enhancement. The vocals were panned center and we automated volume for the chorus sections.
        The producer suggested additional doubling for the bridge, which we implemented. Overall, the vocal track is
        sounding much clearer and sits well in the mix.
        """

        let parameters = [
            "text": longAudioText,
            "length": "short"
        ] as [String: AnyCodable]

        do {
            let result = try await textRewriteTool.execute(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            if let data = result.data?.value as? [String: Any],
               let rewrittenText = data["text"] as? String {
                XCTAssertFalse(rewrittenText.isEmpty)
                // Should be significantly shorter than original
                XCTAssertLessThan(rewrittenText.count, longAudioText.count / 2)
                // Should focus on key points
                XCTAssertTrue(rewrittenText.contains("vocal") || rewrittenText.contains("mix") ||
                             rewrittenText.contains("EQ") || rewrittenText.contains("compressor"))
            }
        } catch {
            XCTFail("Short length transformation should succeed: \(error.localizedDescription)")
        }
    }

    func testLongLengthTransformation() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: textRewriteTool.name
        )

        let shortAudioText = """
        Fixed the vocal mix with EQ and compression.
        """

        let parameters = [
            "text": shortAudioText,
            "length": "long"
        ] as [String: AnyCodable]

        do {
            let result = try await textRewriteTool.execute(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            if let data = result.data?.value as? [String: Any],
               let rewrittenText = data["text"] as? String {
                XCTAssertFalse(rewrittenText.isEmpty)
                // Should be longer than original with added details
                XCTAssertGreaterThan(rewrittenText.count, shortAudioText.count)
                // Should include audio-specific details
                XCTAssertTrue(rewrittenText.contains("frequency") || rewrittenText.contains("dynamic range") ||
                             rewrittenText.contains("audio") || rewrittenText.contains("processing"))
            }
        } catch {
            XCTFail("Long length transformation should succeed: \(error.localizedDescription)")
        }
    }

    func testMediumLengthTransformation() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: textRewriteTool.name
        )

        let audioText = """
        Recording session: Used U87 mic, applied EQ, compressed vocals, added reverb.
        """

        let parameters = [
            "text": audioText,
            "length": "medium"
        ] as [String: AnyCodable]

        do {
            let result = try await textRewriteTool.execute(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            if let data = result.data?.value as? [String: Any],
               let rewrittenText = data["text"] as? String {
                XCTAssertFalse(rewrittenText.isEmpty)
                // Should be moderately detailed, balanced length
                XCTAssertGreaterThan(rewrittenText.count, audioText.count)
                XCTAssertLessThan(rewrittenText.count, audioText.count * 3)
            }
        } catch {
            XCTFail("Medium length transformation should succeed: \(error.localizedDescription)")
        }
    }

    // MARK: - Combined Tone and Length Tests

    func testTechnicalToneWithLongLength() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: textRewriteTool.name
        )

        let audioText = """
        Mixed the drums today.
        """

        let parameters = [
            "text": audioText,
            "tone": "technical",
            "length": "long"
        ] as [String: AnyCodable]

        do {
            let result = try await textRewriteTool.execute(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            if let data = result.data?.value as? [String: Any],
               let rewrittenText = data["text"] as? String {
                XCTAssertFalse(rewrittenText.isEmpty)
                // Should combine technical language with detailed expansion
                XCTAssertTrue(rewrittenText.contains("technical") || rewrittenText.contains("precise") ||
                             rewrittenText.contains("frequency") || rewrittenText.contains("dynamic"))
                // Should be significantly longer than original
                XCTAssertGreaterThan(rewrittenText.count, audioText.count * 2)
            }
        } catch {
            XCTFail("Technical tone with long length should succeed: \(error.localizedDescription)")
        }
    }

    func testExecutiveToneWithShortLength() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: textRewriteTool.name
        }

        let longAudioText = """
        The mixing session was productive today. We worked on multiple tracks including vocals, drums, bass, and guitars.
        Applied various signal processing techniques including equalization, compression, reverb, and delay.
        The producer provided valuable feedback which we incorporated into the mix. The client reviewed the progress
        and expressed satisfaction with the direction. We documented all settings and created backup files.
        The session concluded with a balanced mix that meets professional standards.
        """

        let parameters = [
            "text": longAudioText,
            "tone": "executive",
            "length": "short"
        ] as [String: AnyCodable]

        do {
            let result = try await textRewriteTool.execute(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            if let data = result.data?.value as? [String: Any],
               let rewrittenText = data["text"] as? String {
                XCTAssertFalse(rewrittenText.isEmpty)
                // Should combine business language with conciseness
                XCTAssertTrue(rewrittenText.contains("enhance") || rewrittenText.contains("resolve") ||
                             rewrittenText.contains("outcome") || rewrittenText.contains("deliverable"))
                // Should be significantly shorter than original
                XCTAssertLessThan(rewrittenText.count, longAudioText.count / 2)
            }
        } catch {
            XCTFail("Executive tone with short length should succeed: \(error.localizedDescription)")
        }
    }

    // MARK: - Audio Domain Enhancement Tests

    func testAudioSpecificTechnicalEnhancement() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: textRewriteTool.name
        )

        let audioText = """
        The volume was too loud. We need to fix the sound quality.
        """

        let parameters = [
            "text": audioText,
            "tone": "technical"
        ] as [String: AnyCodable]

        do {
            let result = try await textRewriteTool.execute(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            if let data = result.data?.value as? [String: Any],
               let rewrittenText = data["text"] as? String {
                XCTAssertFalse(rewrittenText.isEmpty)
                // Should enhance with audio-specific technical terms
                XCTAssertTrue(rewrittenText.contains("signal level") || rewrittenText.contains("audio signal") ||
                             rewrittenText.contains("enhance") || rewrittenText.contains("optimize"))
            }
        } catch {
            XCTFail("Audio-specific technical enhancement should work: \(error.localizedDescription)")
        }
    }

    func testAudioSpecificExecutiveEnhancement() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: textRewriteTool.name
        )

        let audioText = """
        The recording sounds good. Client is happy with the mix.
        """

        let parameters = [
            "text": audioText,
            "tone": "executive"
        ] as [String: AnyCodable]

        do {
            let result = try await textRewriteTool.execute(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            if let data = result.data?.value as? [String: Any],
               let rewrittenText = data["text"] as? String {
                XCTAssertFalse(rewrittenText.isEmpty)
                // Should add business outcome focus for audio projects
                XCTAssertTrue(rewrittenText.contains("outcome") || rewrittenText.contains("deliverable") ||
                             rewrittenText.contains("quality") || rewrittenText.contains("objective"))
            }
        } catch {
            XCTFail("Audio-specific executive enhancement should work: \(error.localizedDescription)")
        }
    }

    // MARK: - Parameter Validation Tests

    func testInvalidToneParameter() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: textRewriteTool.name
        )

        let parameters = [
            "text": "Test text for rewriting",
            "tone": "invalid_tone"
        ] as [String: AnyCodable]

        do {
            _ = try await textRewriteTool.execute(parameters: parameters, context: context)
            XCTFail("Invalid tone parameter should cause validation failure")
        } catch {
            // Expected behavior
            XCTAssertTrue(error.localizedDescription.contains("tone") ||
                        error.localizedDescription.contains("validation"))
        }
    }

    func testInvalidLengthParameter() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: textRewriteTool.name
        )

        let parameters = [
            "text": "Test text for rewriting",
            "length": "invalid_length"
        ] as [String: AnyCodable]

        do {
            _ = try await textRewriteTool.execute(parameters: parameters, context: context)
            XCTFail("Invalid length parameter should cause validation failure")
        } catch {
            // Expected behavior
            XCTAssertTrue(error.localizedDescription.contains("length") ||
                        error.localizedDescription.contains("validation"))
        }
    }

    func testMissingRequiredTextParameter() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: textRewriteTool.name
        )

        let parameters = [
            "tone": "technical",
            "length": "medium"
            // Missing required "text" parameter
        ] as [String: AnyCodable]

        do {
            _ = try await textRewriteTool.execute(parameters: parameters, context: context)
            XCTFail("Missing required text parameter should cause validation failure")
        } catch {
            // Expected behavior
            XCTAssertTrue(error.localizedDescription.contains("required") ||
                        error.localizedDescription.contains("validation") ||
                        error.localizedDescription.contains("text"))
        }
    }

    // MARK: - Error Handling Tests

    func testEmptyTextHandling() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: textRewriteTool.name
        )

        let parameters = [
            "text": ""
        ] as [String: AnyCodable]

        do {
            _ = try await textRewriteTool.execute(parameters: parameters, context: context)
            XCTFail("Empty text parameter should cause validation failure")
        } catch {
            // Expected behavior
            XCTAssertTrue(error.localizedDescription.contains("empty") ||
                        error.localizedDescription.contains("validation"))
        }
    }

    // MARK: - Performance Tests

    func testRewritePerformance() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: textRewriteTool.name
        )

        let audioText = """
        Studio session: Applied EQ to enhance vocal clarity. Used compression for dynamic control.
        Added reverb for spatial depth. The mix sounds professional and polished.
        """

        let parameters = [
            "text": audioText,
            "tone": "technical",
            "length": "medium"
        ] as [String: AnyCodable]

        // Measure execution time
        measure {
            Task {
                do {
                    let result = try await textRewriteTool.execute(parameters: parameters, context: context)
                    XCTAssertTrue(result.success)
                } catch {
                    XCTFail("Performance test should not fail: \(error.localizedDescription)")
                }
            }
        }
    }

    func testConcurrentRewrite() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: textRewriteTool.name
        )

        let audioText = """
        Audio processing: Used equalization and compression. The recording quality improved significantly.
        """

        let parameters = [
            "text": audioText,
            "tone": "friendly",
            "length": "short"
        ] as [String: AnyCodable]

        // Test concurrent executions
        await withTaskGroup(of: Bool.self) { group in
            for i in 0..<5 {
                group.addTask {
                    do {
                        let result = try await self.textRewriteTool.execute(parameters: parameters, context: context)
                        return result.success
                    } catch {
                        return false
                    }
                }
            }

            var successCount = 0
            for await success in group {
                if success {
                    successCount += 1
                }
            }

            XCTAssertEqual(successCount, 5, "All concurrent rewrites should succeed")
        }
    }

    // MARK: - Edge Cases Tests

    func testSpecialCharacterHandling() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: textRewriteTool.name
        )

        let specialCharText = """
        Recording 🎵 went well! The engineer said "Great job!" 🎉.
        Levels were set to -6dB peak. Studio temp was 22°C.
        """

        let parameters = [
            "text": specialCharText,
            "tone": "neutral"
        ] as [String: AnyCodable]

        do {
            let result = try await textRewriteTool.execute(parameters: parameters, context: context)
            XCTAssertTrue(result.success, "Should handle special characters correctly")

            if let data = result.data?.value as? [String: Any],
               let rewrittenText = data["text"] as? String {
                XCTAssertFalse(rewrittenText.isEmpty)
                // Should preserve or appropriately handle special characters
            }
        } catch {
            XCTFail("Special characters should not cause failure: \(error.localizedDescription)")
        }
    }

    func testNonAudioContentHandling() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: textRewriteTool.name
        )

        let nonAudioText = """
        Today I went shopping and bought groceries. The weather was nice.
        I cooked dinner and watched a movie in the evening.
        """

        let parameters = [
            "text": nonAudioText,
            "tone": "friendly",
            "length": "medium"
        ] as [String: AnyCodable]

        do {
            let result = try await textRewriteTool.execute(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            if let data = result.data?.value as? [String: Any],
               let rewrittenText = data["text"] as? String {
                XCTAssertFalse(rewrittenText.isEmpty)
                // Should still process non-audio content
                XCTAssertTrue(rewrittenText.contains("shopping") || rewrittenText.contains("weather") ||
                             rewrittenText.contains("dinner"))
            }
        } catch {
            XCTFail("Non-audio content should still be processed: \(error.localizedDescription)")
        }
    }

    func testVeryShortTextHandling() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: textRewriteTool.name
        )

        let parameters = [
            "text": "OK",
            "tone": "technical",
            "length": "long"
        ] as [String: AnyCodable]

        do {
            let result = try await textRewriteTool.execute(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            if let data = result.data?.value as? [String: Any],
               let rewrittenText = data["text"] as? String {
                XCTAssertFalse(rewrittenText.isEmpty)
                // Should expand even very short input
                XCTAssertGreaterThan(rewrittenText.count, 2)
            }
        } catch {
            XCTFail("Very short text should still be processed: \(error.localizedDescription)")
        }
    }
}