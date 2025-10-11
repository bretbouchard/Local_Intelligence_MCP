//
//  SummarizationToolTests.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-08.
//

import XCTest
@testable import LocalIntelligenceMCP

final class SummarizationToolTests: XCTestCase {

    // MARK: - Properties

    private var logger: Logger!
    private var securityManager: SecurityManager!
    private var summarizationTool: SummarizationTool!

    // MARK: - Setup and Teardown

    override func setUp() async throws {
        try await super.setUp()

        // Initialize test components
        let config = LoggingConfiguration.default
        logger = Logger(configuration: config)
        await logger.setupFileLoggingIfNeeded()

        securityManager = SecurityManager(logger: logger)
        summarizationTool = SummarizationTool(logger: logger, securityManager: securityManager)
    }

    override func tearDown() async throws {
        logger = nil
        securityManager = nil
        summarizationTool = nil

        try await super.tearDown()
    }

    // MARK: - Tool Initialization Tests

    func testSummarizationToolInitialization() async throws {
        XCTAssertNotNil(summarizationTool)
        XCTAssertEqual(summarizationTool.name, "apple.summarize")
        XCTAssertFalse(summarizationTool.description.isEmpty)
        XCTAssertNotNil(summarizationTool.inputSchema)
        XCTAssertEqual(summarizationTool.category, .textProcessing)
        XCTAssertTrue(summarizationTool.requiresPermission.contains(.systemInfo))
        XCTAssertTrue(summarizationTool.offlineCapable)
    }

    func testInputSchemaStructure() async throws {
        let schema = summarizationTool.inputSchema

        // Check basic schema structure
        XCTAssertEqual(schema["type"] as? String, "object")

        // Check properties exist
        let properties = schema["properties"]?.value as? [String: Any]
        XCTAssertNotNil(properties)
        XCTAssertNotNil(properties?["text"])
        XCTAssertNotNil(properties?["style"])
        XCTAssertNotNil(properties?["max_points"])

        // Check required fields
        let required = schema["required"]?.value as? [String]
        XCTAssertTrue(required?.contains("text") == true)
    }

    // MARK: - Execution Tests

    func testBasicSummarizationExecution() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: summarizationTool.name
        )

        let audioSessionText = """
        Session notes: Today we worked on mixing the vocals track. Applied some EQ to boost the highs around 8kHz.
        The compressor was set to 4:1 ratio with medium attack. The reverb adds nice space to the recording.
        We also adjusted the panning to center the vocals and added some automation for the chorus sections.
        Overall mix sounds good but needs more work on the low frequencies.
        """

        let parameters = [
            "text": audioSessionText
        ] as [String: AnyCodable]

        do {
            let result = try await summarizationTool.execute(parameters: parameters, context: context)
            XCTAssertTrue(result.success)
            XCTAssertNotNil(result.data)
            XCTAssertNil(result.error)

            if let data = result.data?.value as? [String: Any],
               let summaryText = data["text"] as? String {
                XCTAssertFalse(summaryText.isEmpty)
                XCTAssertTrue(summaryText.contains("Summary"))
                XCTAssertTrue(summaryText.contains("vocal"))
                XCTAssertTrue(summaryText.contains("mix"))
                XCTAssertTrue(summaryText.contains("EQ"))
            }
        } catch {
            XCTFail("Basic summarization should succeed: \(error.localizedDescription)")
        }
    }

    func testSummarizationWithBulletStyle() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: summarizationTool.name
        )

        let audioText = """
        Recording session: We set up microphones for the drum kit. Used a combination of dynamic mics for toms
        and condenser mics for overheads. Applied preamp gain carefully to avoid clipping. The studio monitors
        helped us hear the balance clearly. We recorded multiple takes and the producer was satisfied with the
        performance. The audio interface handled 16 channels without issues.
        """

        let parameters = [
            "text": audioText,
            "style": "bullet"
        ] as [String: AnyCodable]

        do {
            let result = try await summarizationTool.execute(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            if let data = result.data?.value as? [String: Any],
               let summaryText = data["text"] as? String {
                XCTAssertTrue(summaryText.contains("## Summary"))
                XCTAssertTrue(summaryText.contains("## Key Details"))
                XCTAssertTrue(summaryText.contains("1.") || summaryText.contains("•"))
            }
        } catch {
            XCTFail("Bullet style summarization should succeed: \(error.localizedDescription)")
        }
    }

    func testSummarizationWithAbstractStyle() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: summarizationTool.name
        )

        let audioText = """
        Mastering session: Applied EQ to enhance clarity and presence. Used multiband compression
        to control dynamics. Added stereo widening for better spatial imaging. Checked levels on multiple
        systems including studio monitors and headphones. The final track has improved impact and professional
        polish. Client feedback was positive about the improved sound quality.
        """

        let parameters = [
            "text": audioText,
            "style": "abstract"
        ] as [String: AnyCodable]

        do {
            let result = try await summarizationTool.execute(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            if let data = result.data?.value as? [String: Any],
               let summaryText = data["text"] as? String {
                XCTAssertTrue(summaryText.contains("## Abstract Summary"))
                XCTAssertTrue(summaryText.contains("## Context"))
                XCTAssertFalse(summaryText.contains("## Summary")) // Should not contain bullet format
            }
        } catch {
            XCTFail("Abstract style summarization should succeed: \(error.localizedDescription)")
        }
    }

    func testSummarizationWithExecutiveStyle() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: summarizationTool.name
        )

        let audioText = """
        Production meeting: Discussed project timeline and budget. Audio post-production is 75% complete.
        Sound design elements are finalized. Voiceover recording scheduled for next week. The mixing
        engineer requires additional time for quality control. Client approved initial sound design concepts.
        Final delivery deadline is in three weeks.
        """

        let parameters = [
            "text": audioText,
            "style": "executive"
        ] as [String: AnyCodable]

        do {
            let result = try await summarizationTool.execute(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            if let data = result.data?.value as? [String: Any],
               let summaryText = data["text"] as? String {
                XCTAssertTrue(summaryText.contains("# Executive Summary"))
                XCTAssertTrue(summaryText.contains("## Summary Statistics"))
                XCTAssertTrue(summaryText.contains("-"))
            }
        } catch {
            XCTFail("Executive style summarization should succeed: \(error.localizedDescription)")
        }
    }

    func testSummarizationWithCustomMaxPoints() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: summarizationTool.name
        )

        let audioText = """
        Long session: The recording session lasted 8 hours. We captured 12 different tracks.
        The drums were recorded first, followed by bass guitar. We used vintage microphones for vocals.
        The guitar amps were miked with both close and room positions. The keyboard was recorded direct.
        The producer made notes throughout the session. The studio acoustics were excellent.
        Audio engineer managed levels perfectly. All backup files were created properly.
        Session notes were documented in detail. Equipment was checked before recording.
        Everyone was satisfied with the progress made during the session.
        """

        let parameters = [
            "text": audioText,
            "max_points": 3
        ] as [String: AnyCodable]

        do {
            let result = try await summarizationTool.execute(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            if let data = result.data?.value as? [String: Any],
               let summaryText = data["text"] as? String {
                XCTAssertTrue(summaryText.contains("Key points extracted: 3"))
            }
        } catch {
            XCTFail("Custom max points summarization should succeed: \(error.localizedDescription)")
        }
    }

    // MARK: - Audio Content Relevance Tests

    func testAudioRelevantContentPrioritization() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: summarizationTool.name
        )

        let mixedText = """
        Today was a productive day. We went to the store and bought groceries.
        In the studio, we worked on mixing the audio track. The vocals needed EQ adjustment.
        The weather was nice. We used compression on the drums. Applied reverb for space.
        Had lunch at noon. The recording session went well overall.
        """

        let parameters = [
            "text": mixedText
        ] as [String: AnyCodable]

        do {
            let result = try await summarizationTool.execute(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            if let data = result.data?.value as? [String: Any],
               let summaryText = data["text"] as? String {
                // Should prioritize audio-related content
                XCTAssertTrue(summaryText.contains("mix") || summaryText.contains("audio") ||
                             summaryText.contains("vocals") || summaryText.contains("compression"))
            }
        } catch {
            XCTFail("Audio relevance prioritization should work: \(error.localizedDescription)")
        }
    }

    func testNonAudioContentHandling() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: summarizationTool.name
        )

        let nonAudioText = """
        Today I went to the grocery store and bought apples, bananas, and oranges.
        The weather was sunny and warm. I read a book in the afternoon.
        For dinner, I cooked pasta with tomato sauce. Watched a movie in the evening.
        It was a pleasant day overall.
        """

        let parameters = [
            "text": nonAudioText
        ] as [String: AnyCodable]

        do {
            let result = try await summarizationTool.execute(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            if let data = result.data?.value as? [String: Any],
               let summaryText = data["text"] as? String {
                XCTAssertFalse(summaryText.isEmpty)
                // Should still generate a summary even for non-audio content
                XCTAssertTrue(summaryText.contains("Summary"))
            }
        } catch {
            XCTFail("Non-audio content should still be processed: \(error.localizedDescription)")
        }
    }

    // MARK: - Parameter Validation Tests

    func testMissingRequiredTextParameter() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: summarizationTool.name
        )

        let parameters = [
            "style": "bullet"
            // Missing required "text" parameter
        ] as [String: AnyCodable]

        do {
            _ = try await summarizationTool.execute(parameters: parameters, context: context)
            XCTFail("Missing required text parameter should cause validation failure")
        } catch {
            // Expected behavior
            XCTAssertTrue(error.localizedDescription.contains("required") ||
                        error.localizedDescription.contains("validation") ||
                        error.localizedDescription.contains("text"))
        }
    }

    func testInvalidStyleParameter() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: summarizationTool.name
        )

        let parameters = [
            "text": "Test text for summarization",
            "style": "invalid_style"
        ] as [String: AnyCodable]

        do {
            _ = try await summarizationTool.execute(parameters: parameters, context: context)
            XCTFail("Invalid style parameter should cause validation failure")
        } catch {
            // Expected behavior
            XCTAssertTrue(error.localizedDescription.contains("style") ||
                        error.localizedDescription.contains("validation"))
        }
    }

    func testInvalidMaxPointsParameter() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: summarizationTool.name
        )

        let parameters = [
            "text": "Test text for summarization",
            "max_points": 20 // Exceeds maximum of 15
        ] as [String: AnyCodable]

        do {
            _ = try await summarizationTool.execute(parameters: parameters, context: context)
            XCTFail("Invalid max_points parameter should cause validation failure")
        } catch {
            // Expected behavior
            XCTAssertTrue(error.localizedDescription.contains("max_points") ||
                        error.localizedDescription.contains("validation"))
        }
    }

    func testEmptyTextParameter() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: summarizationTool.name
        )

        let parameters = [
            "text": ""
        ] as [String: AnyCodable]

        do {
            _ = try await summarizationTool.execute(parameters: parameters, context: context)
            XCTFail("Empty text parameter should cause validation failure")
        } catch {
            // Expected behavior
            XCTAssertTrue(error.localizedDescription.contains("empty") ||
                        error.localizedDescription.contains("validation"))
        }
    }

    // MARK: - Error Handling Tests

    func testVeryLongTextHandling() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: summarizationTool.name
        )

        // Create a very long text (over 20,000 characters)
        let longText = String(repeating: "This is a long audio session note. We worked on mixing and recording. ", count: 500)

        let parameters = [
            "text": longText
        ] as [String: AnyCodable]

        do {
            let result = try await summarizationTool.execute(parameters: parameters, context: context)
            // May succeed or fail depending on implementation - both are acceptable
            if result.success {
                XCTAssertNotNil(result.data)
            } else {
                XCTAssertNotNil(result.error)
            }
        } catch {
            // Acceptable if implementation limits text length
            XCTAssertTrue(error.localizedDescription.contains("length") ||
                        error.localizedDescription.contains("exceeds") ||
                        error.localizedDescription.contains("too large"))
        }
    }

    // MARK: - Performance Tests

    func testSummarizationPerformance() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: summarizationTool.name
        )

        let audioText = """
        Studio session: The recording went smoothly today. We captured multiple takes of the main vocals.
        The microphone setup was optimal for the singer's voice. Applied some gentle compression during recording.
        The headphone mix helped the performer hear themselves clearly. The producer gave helpful feedback between takes.
        The control room acoustics provided accurate monitoring. All equipment performed reliably throughout the session.
        The audio interface maintained clean signal path. The engineer managed levels carefully to avoid clipping.
        Backup drives were used for data safety. Session documentation was thorough and complete.
        """

        let parameters = [
            "text": audioText,
            "style": "bullet"
        ] as [String: AnyCodable]

        // Measure execution time
        measure {
            Task {
                do {
                    let result = try await summarizationTool.execute(parameters: parameters, context: context)
                    XCTAssertTrue(result.success)
                } catch {
                    XCTFail("Performance test should not fail: \(error.localizedDescription)")
                }
            }
        }
    }

    func testConcurrentSummarization() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: summarizationTool.name
        )

        let audioText = """
        Mixing session: Working on the final mix today. Adjusted EQ on various tracks.
        Applied automation to volume levels. Used compression on drums. Added reverb to vocals.
        The overall balance is improving. Client feedback has been positive.
        """

        let parameters = [
            "text": audioText,
            "style": "executive"
        ] as [String: AnyCodable]

        // Test concurrent executions
        await withTaskGroup(of: Bool.self) { group in
            for i in 0..<5 {
                group.addTask {
                    do {
                        let result = try await self.summarizationTool.execute(parameters: parameters, context: context)
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

            XCTAssertEqual(successCount, 5, "All concurrent summarizations should succeed")
        }
    }

    // MARK: - Edge Cases Tests

    func testSpecialCharacterHandling() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: summarizationTool.name
        )

        let specialCharText = """
        Session notes: 🎵 Recording went well! The singer's performance was excellent.
        We used a Neumann U87 microphone (€3000 value). The studio temperature was 22°C.
        Audio levels: -6dB peak, RMS at -18dB. The producer said "Great job!" 🎉
        """

        let parameters = [
            "text": specialCharText
        ] as [String: AnyCodable]

        do {
            let result = try await summarizationTool.execute(parameters: parameters, context: context)
            XCTAssertTrue(result.success, "Should handle special characters correctly")

            if let data = result.data?.value as? [String: Any],
               let summaryText = data["text"] as? String {
                XCTAssertFalse(summaryText.isEmpty)
                // Should preserve or redact special characters appropriately
            }
        } catch {
            XCTFail("Special characters should not cause failure: \(error.localizedDescription)")
        }
    }

    func testPIIRedaction() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: summarizationTool.name
        )

        let textWithPII = """
        Session with client John Doe (john.doe@email.com, 555-123-4567).
        Recorded vocals for the project. Access key: ABC123DEF456GHI789JKL.
        The producer was happy with the results. Contact client tomorrow for feedback.
        """

        let parameters = [
            "text": textWithPII,
            "pii_redact": true
        ] as [String: AnyCodable]

        do {
            let result = try await summarizationTool.execute(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            if let data = result.data?.value as? [String: Any],
               let summaryText = data["text"] as? String {
                // Should redact PII
                XCTAssertTrue(summaryText.contains("[REDACTED_EMAIL]") ||
                             summaryText.contains("[REDACTED_PHONE]") ||
                             summaryText.contains("[REDACTED_KEY]"))
                XCTAssertFalse(summaryText.contains("john.doe@email.com"))
                XCTAssertFalse(summaryText.contains("555-123-4567"))
            }
        } catch {
            XCTFail("PII redaction should work: \(error.localizedDescription)")
        }
    }

    // MARK: - Audio Domain Specific Tests

    func testDAWTerminologyRecognition() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: summarizationTool.name
        )

        let dawText = """
        Logic Pro session: Used Channel EQ for frequency adjustment. Applied Vintage EQ plugin
        on vocals. Set up Send/Return routing for reverb. Used Flex Time for timing correction.
        The track had 24-bit depth at 48kHz sample rate. Exported as WAV format.
        """

        let parameters = [
            "text": dawText
        ] as [String: AnyCodable]

        do {
            let result = try await summarizationTool.execute(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            if let data = result.data?.value as? [String: Any],
               let summaryText = data["text"] as? String {
                // Should recognize and prioritize DAW-specific content
                XCTAssertTrue(summaryText.contains("EQ") || summaryText.contains("Logic") ||
                             summaryText.contains("plugin") || summaryText.contains("WAV"))
            }
        } catch {
            XCTFail("DAW terminology recognition should work: \(error.localizedDescription)")
        }
    }
}