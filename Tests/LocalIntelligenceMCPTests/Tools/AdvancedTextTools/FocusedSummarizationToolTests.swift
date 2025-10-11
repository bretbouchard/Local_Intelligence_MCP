//
//  FocusedSummarizationToolTests.swift
//  LocalIntelligenceMCPTests
//
//  Created on 2025-10-08.
//

import XCTest
@testable import LocalIntelligenceMCP

final class FocusedSummarizationToolTests: XCTestCase {

    // MARK: - Test Properties

    var tool: FocusedSummarizationTool!
    var mockLogger: MockLogger!
    var mockSecurityManager: MockSecurityManager!

    // MARK: - Test Lifecycle

    override func setUp() async throws {
        try await super.setUp()
        mockLogger = MockLogger()
        mockSecurityManager = MockSecurityManager()
        tool = FocusedSummarizationTool(
            logger: mockLogger,
            securityManager: mockSecurityManager
        )
    }

    override func tearDown() async throws {
        tool = nil
        mockLogger = nil
        mockSecurityManager = nil
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func testToolInitialization() async throws {
        // Test that tool initializes correctly
        XCTAssertNotNil(tool)
        XCTAssertEqual(tool.name, "apple.summarize.focus")
        XCTAssertTrue(tool.description.contains("focused summaries"))
        XCTAssertEqual(tool.category, .textProcessing)
    }

    // MARK: - Basic Summarization Tests

    func testBasicSummarization() async throws {
        let inputText = """
        Today's recording session focused on lead vocals. We started with microphone selection,
        choosing the Neumann U87 for its warmth and clarity. The preamp chain was API 312
        followed by a dbx 160 compressor for gentle control. The vocalist, Sarah, performed
        exceptionally well, requiring only 3 takes to get the perfect performance. We tracked
        both main vocals and doubles for choruses. The session took approximately 4 hours
        including setup and breakdown. Client was very satisfied with the raw tracks.
        """

        let parameters: [String: Any] = [
            "text": inputText,
            "focus_areas": ["recording", "technical"],
            "style": "bullet",
            "max_points": 8
        ]

        let result = try await tool.processAudioContent(inputText, with: parameters)

        // Verify basic structure
        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains("•") || result.contains("-")) // Bullet points
        XCTAssertTrue(result.lowercased().contains("neumann"))
        XCTAssertTrue(result.lowercased().contains("vocal"))
    }

    // MARK: - Focus Area Tests

    func testRecordingFocusArea() async throws {
        let inputText = """
        Session setup took 45 minutes. Microphones: Neumann U87 for vocals, AKG C414 for acoustic
        guitar, Sennheiser 421 for guitar amp, Shure SM57 for snare, AKG D112 for kick.
        Preamps: API 312 for vocals, API 512 for guitars, Neve 1073 for drums.
        Recording chain: microphones → preamps → converters → Pro Tools HD.
        Sample rate: 96kHz, bit depth: 24-bit. Total of 12 tracks recorded.
        Performance was excellent, minimal retakes needed. Session completed on time.
        """

        let parameters: [String: Any] = [
            "text": inputText,
            "focus_areas": ["recording", "equipment"],
            "style": "bullet"
        ]

        let result = try await tool.processAudioContent(inputText, with: parameters)

        XCTAssertTrue(result.lowercased().contains("microphone"))
        XCTAssertTrue(result.lowercased().contains("neumann"))
        XCTAssertTrue(result.lowercased().contains("preamp"))
        XCTAssertTrue(result.lowercased().contains("recording"))
    }

    // MARK: - Parameter Validation Tests

    func testMissingRequiredParameter() async throws {
        let parameters: [String: Any] = [
            "focus_areas": ["mixing"],
            "style": "bullet"
        ]

        do {
            _ = try await tool.processAudioContent("", with: parameters)
            XCTFail("Should have thrown an error for missing text parameter")
        } catch {
            XCTAssertTrue(error is AudioProcessingError)
        }
    }

    // MARK: - Performance Tests

    func testPerformanceWithLargeText() async throws {
        let largeText = String(repeating: "This is a test sentence for audio session notes. ", count: 100)

        let parameters: [String: Any] = [
            "text": largeText,
            "focus_areas": ["general"],
            "style": "bullet"
        ]

        let startTime = Date()
        let result = try await tool.processAudioContent(largeText, with: parameters)
        let executionTime = Date().timeIntervalSince(startTime)

        // Performance should be under 200ms
        XCTAssertLessThan(executionTime, 0.2)
        XCTAssertFalse(result.isEmpty)
    }

    // MARK: - Audio Domain Tests

    func testAudioTechnicalTermsPreservation() async throws {
        let inputText = """
        Applied EQ boost at 2kHz for vocal presence. Used 4:1 compression ratio on drums.
        Added plate reverb with 2.2 second decay. Mixed through SSL G-series console.
        Processed with Pro Tools HD at 96kHz/24-bit. Used Waves CLA-76 for vocal compression.
        """

        let parameters: [String: Any] = [
            "text": inputText,
            "focus_areas": ["technical"],
            "style": "bullet",
            "preserve_technical_terms": true
        ]

        let result = try await tool.processAudioContent(inputText, with: parameters)

        // Verify technical terms are preserved
        XCTAssertTrue(result.lowercased().contains("eq"))
        XCTAssertTrue(result.lowercased().contains("compression"))
        XCTAssertTrue(result.lowercased().contains("reverb"))
        XCTAssertTrue(result.lowercased().contains("khz"))
        XCTAssertTrue(result.lowercased().contains("bit"))
    }
}

// MARK: - Mock Classes

class MockLogger: Logger {
    var loggedMessages: [String] = []

    override func info(_ message: String, category: LogCategory = .general, metadata: [String: AnyCodable] = [:]) async {
        loggedMessages.append("INFO: \(message)")
    }
}

class MockSecurityManager: SecurityManager {
    var shouldReject = false

    override func validateInput(_ input: String) throws {
        if shouldReject {
            throw SecurityError.unauthorizedAccess
        }
    }
}
