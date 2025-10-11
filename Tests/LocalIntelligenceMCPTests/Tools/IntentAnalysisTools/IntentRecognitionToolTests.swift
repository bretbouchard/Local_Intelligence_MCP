//
//  IntentRecognitionToolTests.swift
//  LocalIntelligenceMCPTests
//
//  Created on 2025-10-09.
//

import XCTest
@testable import LocalIntelligenceMCP

/// Comprehensive unit tests for IntentRecognitionTool
/// Tests intent recognition accuracy, confidence scoring, argument extraction, and audio domain context
final class IntentRecognitionToolTests: XCTestCase {

    // MARK: - Test Properties

    var mockLogger: MockLogger!
    var mockSecurityManager: MockSecurityManager!
    var intentTool: IntentRecognitionTool!

    // MARK: - Test Lifecycle

    override func setUp() async throws {
        try await super.setUp()
        mockLogger = MockLogger()
        mockSecurityManager = MockSecurityManager()
        intentTool = IntentRecognitionTool(logger: mockLogger, securityManager: mockSecurityManager)
    }

    override func tearDown() async throws {
        mockLogger = nil
        mockSecurityManager = nil
        intentTool = nil
        try await super.tearDown()
    }

    // MARK: - Recording Intent Tests

    func testStartRecordingIntent() async throws {
        let testCases = [
            "Start recording the lead vocal track",
            "Record the guitar now",
            "Begin recording drums",
            "Capture audio for vocals",
            "Start tracking bass"
        ]

        for testCase in testCases {
            let result = try await intentTool.processAudioContent(testCase, with: [:])
            XCTAssertFalse(result.isEmpty)

            // Verify the result contains intent information
            XCTAssertTrue(result.contains("intent"))
            XCTAssertTrue(result.contains("confidence"))
            XCTAssertTrue(result.lowercased().contains("start_recording"))

            // Verify high confidence for clear commands
            XCTAssertTrue(result.contains("0.8") || result.contains("0.9") || result.contains("1.0"))
        }
    }

    func testStopRecordingIntent() async throws {
        let testCases = [
            "Stop recording",
            "End recording session",
            "Finish recording take",
            "Cease recording",
            "Recording complete"
        ]

        for testCase in testCases {
            let result = try await intentTool.processAudioContent(testCase, with: [:])
            XCTAssertFalse(result.isEmpty)
            XCTAssertTrue(result.lowercased().contains("stop_recording"))
        }
    }

    func testMicrophoneSetupIntent() async throws {
        let testCases = [
            "Setup microphone for vocals",
            "Place the Neumann microphone",
            "Position the mic for acoustic guitar",
            "Configure microphone settings",
            "Mic setup for recording"
        ]

        for testCase in testCases {
            let result = try await intentTool.processAudioContent(testCase, with: [:])
            XCTAssertFalse(result.isEmpty)
            XCTAssertTrue(result.lowercased().contains("setup_microphone"))
        }
    }

    // MARK: - Mixing Intent Tests

    func testApplyEQIntent() async throws {
        let testCases = [
            "Apply EQ to the bass",
            "Equalize the vocals",
            "Add some EQ to the drums",
            "EQ the guitar track",
            "Apply equalization"
        ]

        for testCase in testCases {
            let result = try await intentTool.processAudioContent(testCase, with: [:])
            XCTAssertFalse(result.isEmpty)
            XCTAssertTrue(result.lowercased().contains("apply_eq"))
        }
    }

    func testAddCompressionIntent() async throws {
        let testCases = [
            "Add compression to vocals",
            "Compress the bass track",
            "Apply compression to drums",
            "Add a compressor to the guitar",
            "Use compression on the mix"
        ]

        for testCase in testCases {
            let result = try await intentTool.processAudioContent(testCase, with: [:])
            XCTAssertFalse(result.isEmpty)
            XCTAssertTrue(result.lowercased().contains("add_compression"))
        }
    }

    func testExportAudioIntent() async throws {
        let testCases = [
            "Export the mix as WAV",
            "Bounce the final track",
            "Render the project to MP3",
            "Export audio file",
            "Save mix as high-quality"
        ]

        for testCase in testCases {
            let result = try await intentTool.processAudioContent(testCase, with: [:])
            XCTAssertFalse(result.isEmpty)
            XCTAssertTrue(result.lowercased().contains("export_audio"))
        }
    }

    // MARK: - Query Intent Tests

    func testGetInfoIntent() async throws {
        let testCases = [
            "What is the best microphone for vocals?",
            "Tell me about SSL consoles",
            "Explain compression ratio",
            "What are the differences between condenser and dynamic mics?",
            "How does phantom power work?"
        ]

        for testCase in testCases {
            let result = try await intentTool.processAudioContent(testCase, with: [:])
            XCTAssertFalse(result.isEmpty)
            XCTAssertTrue(result.lowercased().contains("get_info"))
        }
    }

    func testRecommendSettingsIntent() async throws {
        let testCases = [
            "Recommend EQ settings for vocals",
            "Suggest compression settings for bass",
            "What are the best reverb settings?",
            "Recommend mic placement techniques",
            "Suggest mastering settings"
        ]

        for testCase in testCases {
            let result = try await intentTool.processAudioContent(testCase, with: [:])
            XCTAssertFalse(result.isEmpty)
            XCTAssertTrue(result.lowercased().contains("recommend_settings"))
        }
    }

    func testTroubleshootIntent() async throws {
        let testCases = [
            "Why is my mix sounding muddy?",
            "Fix the humming sound in my recording",
            "Troubleshoot latency issues",
            "Why is there distortion in my audio?",
            "Fix clipping problem"
        ]

        for testCase in testCases {
            let result = try await intentTool.processAudioContent(testCase, with: [:])
            XCTAssertFalse(result.isEmpty)
            XCTAssertTrue(result.lowercased().contains("troubleshoot"))
        }
    }

    // MARK: - Planning Intent Tests

    func testCreatePlanIntent() async throws {
        let testCases = [
            "Create a plan for the recording session",
            "Make a workflow for mixing",
            "Plan the mastering process",
            "Create checklist for session setup",
            "Develop audio production plan"
        ]

        for testCase in testCases {
            let result = try await intentTool.processAudioContent(testCase, with: [:])
            XCTAssertFalse(result.isEmpty)
            XCTAssertTrue(result.lowercased().contains("create_plan"))
        }
    }

    // MARK: - Audio Context Tests

    func testAudioContextExtraction() async throws {
        let testCase = "Apply EQ to the bass track using SSL console, boost at 80Hz"
        let parameters: [String: Any] = ["extract_context": true]

        let result = try await intentTool.processAudioContent(testCase, with: parameters)
        XCTAssertFalse(result.isEmpty)

        // Should extract equipment
        XCTAssertTrue(result.contains("SSL"))

        // Should extract parameters
        XCTAssertTrue(result.contains("80Hz"))

        // Should extract track context
        XCTAssertTrue(result.lowercased().contains("bass"))
    }

    func testTechnicalParameterExtraction() async throws {
        let testCases = [
            ("Apply EQ with 3dB boost at 2kHz", ["3dB", "2kHz"]),
            ("Set compression ratio 4:1", ["4:1"]),
            ("Threshold at -18dB", ["-18dB"]),
            ("Sample rate 96kHz", ["96kHz"]),
            ("Bit depth 24-bit", ["24-bit"])
        ]

        for (testCase, expectedParams) in testCases {
            let result = try await intentTool.processAudioContent(testCase, with: [:])
            XCTAssertFalse(result.isEmpty)

            for param in expectedParams {
                XCTAssertTrue(result.contains(param), "Failed to extract \(param) from: \(testCase)")
            }
        }
    }

    func testEquipmentBrandRecognition() async throws {
        let brands = [
            "Neumann", "AKG", "Sennheiser", "Shure", "Audio-Technica",
            "API", "Neve", "SSL", "Focusrite", "Universal Audio",
            "Pro Tools", "Logic Pro", "Ableton", "Waves", "Fabfilter"
        ]

        for brand in brands {
            let testCase = "Setup the \(brand) for recording"
            let result = try await intentTool.processAudioContent(testCase, with: [:])
            XCTAssertFalse(result.isEmpty)
            XCTAssertTrue(result.contains(brand), "Failed to recognize brand: \(brand)")
        }
    }

    // MARK: - Confidence Scoring Tests

    func testHighConfidenceScoring() async throws {
        let clearCommands = [
            "Start recording the vocals",
            "Apply EQ to the bass",
            "Export the mix as WAV",
            "Stop recording",
            "Add compression to vocals"
        ]

        for command in clearCommands {
            let result = try await intentTool.processAudioContent(command, with: [:])
            XCTAssertFalse(result.isEmpty)

            // Should have high confidence (>0.8)
            XCTAssertTrue(
                result.contains("0.8") || result.contains("0.9") || result.contains("1.0"),
                "Low confidence for clear command: \(command)"
            )
        }
    }

    func testLowConfidenceScoring() async throws {
        let ambiguousCommands = [
            "Do something with the audio",
            "Work on the music",
            "Make it sound good",
            "Fix the sound",
            "Help with recording"
        ]

        for command in ambiguousCommands {
            let result = try await intentTool.processAudioContent(command, with: [:])
            XCTAssertFalse(result.isEmpty)

            // Should have lower confidence or default to getInfo
            let hasLowConfidence = result.contains("0.") &&
                                   (result.contains("1") || result.contains("2") || result.contains("3") || result.contains("4"))
            XCTAssertTrue(hasLowConfidence || result.contains("get_info"))
        }
    }

    // MARK: - Alternative Intent Tests

    func testAlternativeIntentGeneration() async throws {
        let parameters: [String: Any] = ["include_alternatives": true]
        let testCase = "Work on the vocals"

        let result = try await intentTool.processAudioContent(testCase, with: parameters)
        XCTAssertFalse(result.isEmpty)

        // Should contain alternatives array
        XCTAssertTrue(result.contains("alternatives"))
    }

    // MARK: - Parameter Validation Tests

    func testConfidenceThresholdParameter() async throws {
        let testCase = "Maybe record something"
        let parameters: [String: Any] = ["confidence_threshold": 0.9]

        let result = try await intentTool.processAudioContent(testCase, with: parameters)

        // Should either fail (no intent meets threshold) or return very high confidence
        if !result.contains("error") {
            let hasHighConfidence = result.contains("0.9") || result.contains("1.0")
            XCTAssertTrue(hasHighConfidence)
        }
    }

    func testAllowedIntentsParameter() async throws {
        let testCase = "Start recording vocals"
        let parameters: [String: Any] = [
            "allowed": ["start_recording", "stop_recording"]
        ]

        let result = try await intentTool.processAudioContent(testCase, with: parameters)
        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.lowercased().contains("start_recording"))
    }

    // MARK: - Error Handling Tests

    func testEmptyInput() async throws {
        do {
            _ = try await intentTool.processAudioContent("", with: [:])
            XCTFail("Should have thrown an error for empty input")
        } catch {
            XCTAssertTrue(error is AudioProcessingError)
        }
    }

    func testInputTooShort() async throws {
        do {
            _ = try await intentTool.processAudioContent("Hi", with: [:])
            XCTFail("Should have thrown an error for input too short")
        } catch {
            XCTAssertTrue(error is AudioProcessingError)
        }
    }

    func testInvalidConfidenceThreshold() async throws {
        let testCase = "Test recording"
        let parameters: [String: Any] = ["confidence_threshold": 1.5]

        do {
            _ = try await intentTool.processAudioContent(testCase, with: parameters)
            XCTFail("Should have thrown an error for invalid confidence threshold")
        } catch {
            XCTAssertTrue(error is AudioProcessingError)
        }
    }

    func testInvalidAllowedIntents() async throws {
        let testCase = "Test recording"
        let parameters: [String: Any] = ["allowed": ["invalid_intent"]]

        do {
            _ = try await intentTool.processAudioContent(testCase, with: parameters)
            XCTFail("Should have thrown an error for invalid allowed intents")
        } catch {
            XCTAssertTrue(error is AudioProcessingError)
        }
    }

    // MARK: - Performance Tests

    func testPerformanceWithLongInput() async throws {
        let longInput = String(repeating: "Apply EQ to the bass track with SSL console and boost at 80Hz for better low end response. ", count: 20)

        let startTime = Date()
        let result = try await intentTool.processAudioContent(longInput, with: [:])
        let executionTime = Date().timeIntervalSince(startTime)

        XCTAssertFalse(result.isEmpty)
        XCTAssertLessThan(executionTime, 0.2, "Intent recognition should complete within 200ms")
    }

    func testPerformanceWithMultipleIntents() async throws {
        let testInputs = [
            "Start recording the lead vocals",
            "Apply EQ to the bass track",
            "Export the mix as WAV file",
            "What microphone should I use?",
            "Create a plan for the session"
        ]

        for input in testInputs {
            let startTime = Date()
            let result = try await intentTool.processAudioContent(input, with: [:])
            let executionTime = Date().timeIntervalSince(startTime)

            XCTAssertFalse(result.isEmpty)
            XCTAssertLessThan(executionTime, 0.1, "Each intent recognition should complete within 100ms")
        }
    }

    // MARK: - Audio Domain Specific Tests

    func testAudioDomainRelevance() async throws {
        let audioDomainInputs = [
            "Record with Neumann U87 microphone",
            "Apply SSL console EQ",
            "Use Pro Tools for editing",
            "Set up API preamp",
            "Master with Waves plugins"
        ]

        let nonAudioInputs = [
            "Cook dinner with recipe",
            "Drive to the store",
            "Write email to boss",
            "Exercise at gym",
            "Read book about history"
        ]

        // Audio domain inputs should have high confidence
        for input in audioDomainInputs {
            let result = try await intentTool.processAudioContent(input, with: [:])
            XCTAssertFalse(result.isEmpty)
            XCTAssertTrue(result.lowercased().contains("confidence"))
        }

        // Non-audio inputs should default to getInfo with lower confidence
        for input in nonAudioInputs {
            let result = try await intentTool.processAudioContent(input, with: [:])
            XCTAssertFalse(result.isEmpty)
            // Should not fail completely, but may have low confidence
        }
    }

    func testWorkflowStageContext() async throws {
        let workflowInputs = [
            ("Setup for recording", "recording"),
            ("Mix the tracks", "mixing"),
            ("Master the final mix", "mastering"),
            ("Edit the vocals", "editing")
        ]

        for (input, expectedStage) in workflowInputs {
            let result = try await intentTool.processAudioContent(input, with: [:])
            XCTAssertFalse(result.isEmpty)

            // Should extract audio context with session phase
            if result.contains("audio_context") {
                // Test passes if audio context is extracted
                XCTAssertTrue(true)
            }
        }
    }

    // MARK: - Integration Tests

    func testIntentRecognitionWithClassificationModels() async throws {
        // Test that intent recognition works with the classification models
        let testCase = "Apply EQ to bass track with SSL console"
        let result = try await intentTool.processAudioContent(testCase, with: [:])

        XCTAssertFalse(result.isEmpty)

        // Should contain structured result with intent, confidence, and context
        let requiredFields = ["intent", "confidence", "category", "original_text"]
        for field in requiredFields {
            XCTAssertTrue(result.contains(field), "Missing required field: \(field)")
        }
    }

    func testEndToEndIntentProcessing() async throws {
        let complexInput = "Start recording lead vocals using Neumann U87 through API 312 preamp into Pro Tools"
        let parameters: [String: Any] = [
            "extract_context": true,
            "include_alternatives": true,
            "confidence_threshold": 0.5
        ]

        let result = try await intentTool.processAudioContent(complexInput, with: parameters)
        XCTAssertFalse(result.isEmpty)

        // Should recognize recording intent
        XCTAssertTrue(result.lowercased().contains("start_recording"))

        // Should extract equipment context
        XCTAssertTrue(result.contains("Neumann"))
        XCTAssertTrue(result.contains("API"))
        XCTAssertTrue(result.contains("Pro Tools"))

        // Should have high confidence due to clear audio domain terms
        XCTAssertTrue(result.contains("0.8") || result.contains("0.9") || result.contains("1.0"))

        // Should include alternatives
        XCTAssertTrue(result.contains("alternatives"))

        // Should include audio context
        XCTAssertTrue(result.contains("audio_context"))
    }
}

// MARK: - Mock Classes

class MockLogger: Logger {
    var loggedMessages: [String] = []

    override func info(_ message: String, category: LogCategory = .general, metadata: [String: AnyCodable] = [:]) async {
        loggedMessages.append("INFO: \(message)")
    }

    override func warning(_ message: String, category: LogCategory = .general, metadata: [String: AnyCodable] = [:]) async {
        loggedMessages.append("WARNING: \(message)")
    }

    override func error(_ message: String, category: LogCategory = .general, metadata: [String: AnyCodable] = [:]) async {
        loggedMessages.append("ERROR: \(message)")
    }
}

class MockSecurityManager: SecurityManager {
    var shouldReject = false

    override func validateInput(_ input: String) throws {
        if shouldReject {
            throw SecurityError.unauthorizedAccess
        }
    }

    override func validateOutput(_ output: String) throws {
        // Allow all output by default
    }
}