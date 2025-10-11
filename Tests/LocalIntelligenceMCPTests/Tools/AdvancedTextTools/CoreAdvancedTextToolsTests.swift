//
//  CoreAdvancedTextToolsTests.swift
//  LocalIntelligenceMCPTests
//
//  Created on 2025-10-09.
//

import XCTest
@testable import LocalIntelligenceMCP

/// Core tests for advanced text tools focusing on the main functionality
/// This test suite verifies the core functionality of the advanced text tools
/// without the complex PII detection patterns that may have compilation issues
final class CoreAdvancedTextToolsTests: XCTestCase {

    // MARK: - Test Properties

    var mockLogger: MockLogger!
    var mockSecurityManager: MockSecurityManager!

    // MARK: - Test Lifecycle

    override func setUp() async throws {
        try await super.setUp()
        mockLogger = MockLogger()
        mockSecurityManager = MockSecurityManager()
    }

    override func tearDown() async throws {
        mockLogger = nil
        mockSecurityManager = nil
        try await super.tearDown()
    }

    // MARK: - FocusedSummarizationTool Tests

    func testFocusedSummarizationToolBasicFunctionality() async throws {
        let tool = FocusedSummarizationTool(
            logger: mockLogger,
            securityManager: mockSecurityManager
        )

        // Test basic initialization
        XCTAssertNotNil(tool)
        XCTAssertEqual(tool.name, "apple.summarize.focus")
        XCTAssertEqual(tool.category, .textProcessing)

        // Test basic summarization
        let sessionText = """
        Today's recording session focused on lead vocals. We used a Neumann U87 microphone
        through an API 312 preamp. The singer performed 8 takes and we selected take 6
        as the best performance. Applied EQ with a 2kHz boost and used an LA-2A compressor
        for gentle dynamic control. Added plate reverb for space.
        """

        let parameters: [String: Any] = [
            "text": sessionText,
            "focus_areas": ["recording", "technical"],
            "style": "bullet",
            "max_points": 8
        ]

        let result = try await tool.processAudioContent(sessionText, with: parameters)

        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.lowercased().contains("neumann") || result.lowercased().contains("microphone"))
        XCTAssertTrue(result.lowercased().contains("api") || result.lowercased().contains("preamp"))
    }

    func testFocusedSummarizationToolDifferentStyles() async throws {
        let tool = FocusedSummarizationTool(
            logger: mockLogger,
            securityManager: mockSecurityManager
        )

        let sessionText = """
        Mixing session: Applied EQ boost at 2kHz for vocal presence. Used Waves CLA-76
        compressor with 4:1 ratio. Added Valhalla VintageVerb plate reverb. Overall
        vocal now sits perfectly in the mix.
        """

        let styles = ["bullet", "paragraph", "executive", "technical"]

        for style in styles {
            let parameters: [String: Any] = [
                "text": sessionText,
                "focus_areas": ["mixing", "technical"],
                "style": style,
                "max_points": 5
            ]

            let result = try await tool.processAudioContent(sessionText, with: parameters)
            XCTAssertFalse(result.isEmpty, "Style \(style) should produce non-empty result")
        }
    }

    // MARK: - TextChunkingTool Tests

    func testTextChunkingToolBasicFunctionality() async throws {
        let tool = TextChunkingTool(
            logger: mockLogger,
            securityManager: mockSecurityManager
        )

        // Test basic initialization
        XCTAssertNotNil(tool)
        XCTAssertEqual(tool.name, "apple.text.chunk")
        XCTAssertEqual(tool.category, .textProcessing)

        // Test basic chunking
        let longText = String(repeating: "This is a test paragraph for text chunking. ", count: 20)

        let parameters: [String: Any] = [
            "text": longText,
            "strategy": "paragraph",
            "max_chunk_size": 200
        ]

        let result = try await tool.processAudioContent(longText, with: parameters)

        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains("chunks"))
    }

    func testTextChunkingToolDifferentStrategies() async throws {
        let tool = TextChunkingTool(
            logger: mockLogger,
            securityManager: mockSecurityManager
        )

        let sessionText = """
        [TRACK 1 - LEAD VOCAL]
        Take 1: Good performance, slight pitch issues
        Take 2: Better emotional delivery
        Take 3: Perfect performance selected

        [TRACK 2 - ACOUSTIC GUITAR]
        Take 1: Clean performance, good timing
        Notes: Used AKG C414 microphone
        """

        let strategies = ["paragraph", "sentence", "fixed", "audio_session"]

        for strategy in strategies {
            let parameters: [String: Any] = [
                "text": sessionText,
                "strategy": strategy,
                "max_chunk_size": 300
            ]

            let result = try await tool.processAudioContent(sessionText, with: parameters)
            XCTAssertFalse(result.isEmpty, "Strategy \(strategy) should produce non-empty result")
        }
    }

    // MARK: - TokenCountUtility Tests

    func testTokenCountUtilityBasicFunctionality() async throws {
        let tool = TokenCountUtility(
            logger: mockLogger,
            securityManager: mockSecurityManager
        )

        // Test basic initialization
        XCTAssertNotNil(tool)
        XCTAssertEqual(tool.name, "apple.tokens.count")
        XCTAssertEqual(tool.category, .textProcessing)

        // Test basic token counting
        let audioText = """
        Recording session: Neumann U67 microphone through API 312 preamp to SSL console.
        Applied EQ boost at 2kHz, used LA-2A compression, added plate reverb.
        Mixed at 96kHz/24-bit resolution in Pro Tools HD.
        """

        let parameters: [String: Any] = [
            "text": audioText,
            "strategy": "audio_optimized",
            "content_type": "session_notes",
            "include_breakdown": true
        ]

        let result = try await tool.processAudioContent(audioText, with: parameters)

        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains("token") || result.lowercased().contains("estimated"))
    }

    func testTokenCountUtilityDifferentStrategies() async throws {
        let tool = TokenCountUtility(
            logger: mockLogger,
            securityManager: mockSecurityManager
        )

        let testText = "Applied 3dB boost at 2kHz using SSL Channel strip. Used Waves CLA-76 compressor."

        let strategies = ["character_based", "word_based", "audio_optimized", "mixed"]

        for strategy in strategies {
            let parameters: [String: Any] = [
                "text": testText,
                "strategy": strategy
            ]

            let result = try await tool.processAudioContent(testText, with: parameters)
            XCTAssertFalse(result.isEmpty, "Strategy \(strategy) should produce non-empty result")
        }
    }

    // MARK: - Integration Tests

    func testAudioDomainWorkflow() async throws {
        let sessionText = """
        Today's session focused on recording lead vocals. Setup: Neumann U87 microphone
        through API 312 preamp into SSL G-Series console. Recorded 8 takes, selected take 6.
        Applied EQ with 2kHz boost for presence, used LA-2A compressor for control.
        Client was happy with the results.
        """

        // Test Token Count
        let tokenTool = TokenCountUtility(
            logger: mockLogger,
            securityManager: mockSecurityManager
        )

        let tokenParams: [String: Any] = [
            "text": sessionText,
            "strategy": "audio_optimized",
            "include_breakdown": true
        ]

        let tokenResult = try await tokenTool.processAudioContent(sessionText, with: tokenParams)
        XCTAssertFalse(tokenResult.isEmpty)

        // Test Summarization
        let summaryTool = FocusedSummarizationTool(
            logger: mockLogger,
            securityManager: mockSecurityManager
        )

        let summaryParams: [String: Any] = [
            "text": sessionText,
            "focus_areas": ["recording", "technical"],
            "style": "bullet",
            "max_points": 6
        ]

        let summaryResult = try await summaryTool.processAudioContent(sessionText, with: summaryParams)
        XCTAssertFalse(summaryResult.isEmpty)
        XCTAssertTrue(summaryResult.lowercased().contains("neumann") || summaryResult.lowercased().contains("api"))

        // Test Chunking
        let chunkingTool = TextChunkingTool(
            logger: mockLogger,
            securityManager: mockSecurityManager
        )

        let chunkingParams: [String: Any] = [
            "text": sessionText,
            "strategy": "paragraph",
            "max_chunk_size": 200
        ]

        let chunkingResult = try await chunkingTool.processAudioContent(sessionText, with: chunkingParams)
        XCTAssertFalse(chunkingResult.isEmpty)
    }

    func testPerformanceRequirements() async throws {
        let performanceText = String(repeating: "Audio session with Neumann U87, API 312, SSL console, Pro Tools HD. ", count: 50)

        let tools: [(String, (String, [String: Any]) async throws -> String)] = [
            ("TokenCount", { text, params in
                let tool = TokenCountUtility(logger: self.mockLogger, securityManager: self.mockSecurityManager)
                let toolParams: [String: Any] = [
                    "text": text,
                    "strategy": "audio_optimized"
                ]
                return try await tool.processAudioContent(text, with: toolParams)
            }),
            ("FocusedSummarization", { text, params in
                let tool = FocusedSummarizationTool(logger: self.mockLogger, securityManager: self.mockSecurityManager)
                let toolParams: [String: Any] = [
                    "text": text,
                    "focus_areas": ["technical"],
                    "style": "bullet"
                ]
                return try await tool.processAudioContent(text, with: toolParams)
            }),
            ("TextChunking", { text, params in
                let tool = TextChunkingTool(logger: self.mockLogger, securityManager: self.mockSecurityManager)
                let toolParams: [String: Any] = [
                    "text": text,
                    "strategy": "paragraph",
                    "max_chunk_size": 500
                ]
                return try await tool.processAudioContent(text, with: toolParams)
            })
        ]

        for (toolName, processor) in tools {
            let startTime = Date()
            let result = try await processor(performanceText, [:])
            let executionTime = Date().timeIntervalSince(startTime)

            // Performance requirements: all tools should execute within 200ms
            XCTAssertLessThan(executionTime, 0.2, "\(toolName) should execute within 200ms")
            XCTAssertFalse(result.isEmpty, "\(toolName) should return non-empty result")
        }
    }

    func testAudioDomainTerminologyPreservation() async throws {
        let audioText = """
        Professional recording session with Neumann U87 microphone, API 312 preamp,
        SSL G-Series console, Waves CLA-76 compressor, LA-2A limiting, and Pro Tools HD
        at 96kHz/24-bit resolution. Used Valhalla VintageVerb for reverb.
        """

        // Test that audio terminology is preserved in summaries
        let summaryTool = FocusedSummarizationTool(
            logger: mockLogger,
            securityManager: mockSecurityManager
        )

        let summaryParams: [String: Any] = [
            "text": audioText,
            "focus_areas": ["equipment", "technical"],
            "preserve_technical_terms": true
        ]

        let summaryResult = try await summaryTool.processAudioContent(audioText, with: summaryParams)
        let summaryLower = summaryResult.lowercased()

        let audioTerms = ["neumann", "api", "ssl", "waves", "pro tools", "khz"]
        let termsFound = audioTerms.filter { summaryLower.contains($0) }
        XCTAssertGreaterThan(termsFound.count, 0, "Summary should preserve some audio terminology")

        // Test that audio domain is recognized in token counting
        let tokenTool = TokenCountUtility(
            logger: mockLogger,
            securityManager: mockSecurityManager
        )

        let tokenParams: [String: Any] = [
            "text": audioText,
            "strategy": "audio_optimized",
            "content_type": "session_notes"
        ]

        let tokenResult = try await tokenTool.processAudioContent(audioText, with: tokenParams)
        XCTAssertFalse(tokenResult.isEmpty)
    }

    // MARK: - Error Handling Tests

    func testEmptyTextHandling() async throws {
        let tools: [(String, (String, [String: Any]) async throws -> String)] = [
            ("TokenCount", { text, params in
                let tool = TokenCountUtility(logger: self.mockLogger, securityManager: self.mockSecurityManager)
                return try await tool.processAudioContent(text, with: [:])
            }),
            ("FocusedSummarization", { text, params in
                let tool = FocusedSummarizationTool(logger: self.mockLogger, securityManager: self.mockSecurityManager)
                return try await tool.processAudioContent(text, with: [:])
            }),
            ("TextChunking", { text, params in
                let tool = TextChunkingTool(logger: self.mockLogger, securityManager: self.mockSecurityManager)
                return try await tool.processAudioContent(text, with: [:])
            })
        ]

        for (toolName, processor) in tools {
            do {
                _ = try await processor("", [:])
                XCTFail("\(toolName) should handle empty text gracefully")
            } catch {
                // This is expected behavior
                XCTAssertTrue(error is AudioProcessingError, "\(toolName) should throw AudioProcessingError for empty text")
            }
        }
    }

    func testInvalidParameterHandling() async throws {
        let tool = FocusedSummarizationTool(
            logger: mockLogger,
            securityManager: mockSecurityManager
        )

        let invalidParams: [String: Any] = [
            "text": "Test text",
            "focus_areas": ["invalid_category"],
            "style": "invalid_style"
        ]

        do {
            _ = try await tool.processAudioContent("Test text", with: invalidParams)
            XCTFail("Should have failed with invalid parameters")
        } catch {
            XCTAssertTrue(error is AudioProcessingError)
        }
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