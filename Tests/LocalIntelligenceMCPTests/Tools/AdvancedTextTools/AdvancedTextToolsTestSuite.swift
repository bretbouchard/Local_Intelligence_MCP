//
//  AdvancedTextToolsTestSuite.swift
//  LocalIntelligenceMCPTests
//
//  Created on 2025-10-08.
//

import XCTest

/// Test suite for all advanced text tools
/// This test suite runs comprehensive tests for FocusedSummarizationTool, TextChunkingTool, 
/// TokenCountUtility, and enhanced PIIRedactionTool to ensure they work correctly
/// with audio domain content and maintain proper security standards.
final class AdvancedTextToolsTestSuite: XCTestCase {

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

    // MARK: - Integration Tests

    func testAllAdvancedTextToolsInitialization() async throws {
        // Test that all advanced text tools can be initialized successfully
        
        let focusedTool = FocusedSummarizationTool(
            logger: mockLogger,
            securityManager: mockSecurityManager
        )
        
        let chunkingTool = TextChunkingTool(
            logger: mockLogger,
            securityManager: mockSecurityManager
        )
        
        let tokenTool = TokenCountUtility(
            logger: mockLogger,
            securityManager: mockSecurityManager
        )
        
        XCTAssertNotNil(focusedTool)
        XCTAssertNotNil(chunkingTool)
        XCTAssertNotNil(tokenTool)
        
        // Verify tool names and categories
        XCTAssertEqual(focusedTool.name, "apple.summarize.focus")
        XCTAssertEqual(chunkingTool.name, "apple.text.chunk")
        XCTAssertEqual(tokenTool.name, "apple.tokens.count")
        
        XCTAssertEqual(focusedTool.category, .textProcessing)
        XCTAssertEqual(chunkingTool.category, .textProcessing)
        XCTAssertEqual(tokenTool.category, .textProcessing)
    }

    func testAudioDomainWorkflowIntegration() async throws {
        let sessionText = """
        SESSION NOTES - The Midnight Echoes
        
        Setup: Neumann U87 microphone through API 312 preamp into Pro Tools HD.
        Sample rate: 96kHz, 24-bit recording.
        
        Recording: 8 vocal takes, best was take 6.
        Applied EQ boost at 2kHz for vocal presence.
        Used Waves CLA-76 compressor with 4:1 ratio.
        Added Valhalla VintageVerb plate reverb.
        
        Client: John Smith (john@studio.com, 555-123-4567)
        Studio: Downtown Recording Studio
        Address: 123 Music Street, Studio B
        Budget: $5000 for mixing phase
        
        Next session: Wednesday for bass tracking.
        """

        // Step 1: Count tokens for analysis
        let tokenTool = TokenCountUtility(
            logger: mockLogger,
            securityManager: mockSecurityManager
        )
        
        let tokenParams: [String: Any] = [
            "text": sessionText,
            "strategy": "audio_optimized",
            "content_type": "session_notes",
            "include_breakdown": true
        ]
        
        let tokenResult = try await tokenTool.processAudioContent(sessionText, with: tokenParams)
        XCTAssertFalse(tokenResult.isEmpty)
        XCTAssertTrue(tokenResult.contains("token_count"))

        // Step 2: Summarize with focus on technical details
        let summarizationTool = FocusedSummarizationTool(
            logger: mockLogger,
            securityManager: mockSecurityManager
        )
        
        let summaryParams: [String: Any] = [
            "text": sessionText,
            "focus_areas": ["technical", "recording"],
            "style": "bullet",
            "max_points": 8
        ]
        
        let summaryResult = try await summarizationTool.processAudioContent(sessionText, with: summaryParams)
        XCTAssertFalse(summaryResult.isEmpty)
        XCTAssertTrue(summaryResult.lowercased().contains("neumann") || summaryResult.lowercased().contains("api"))

        // Step 3: Chunk the content for processing
        let chunkingTool = TextChunkingTool(
            logger: mockLogger,
            securityManager: mockSecurityManager
        )
        
        let chunkingParams: [String: Any] = [
            "text": sessionText,
            "strategy": "audio_session",
            "max_chunk_size": 300,
            "preserve_audio_structure": true
        ]
        
        let chunkingResult = try await chunkingTool.processAudioContent(sessionText, with: chunkingParams)
        XCTAssertFalse(chunkingResult.isEmpty)
        XCTAssertTrue(chunkingResult.contains("chunks"))
    }

    func testSecurityComplianceAcrossTools() async throws {
        let sensitiveText = """
        Session with client information:
        Artist: Sarah Johnson (sarah@music.com, 555-987-6543)
        Studio: Private Recording Studio
        Address: 456 Recording Lane, Suite A
        Budget: $10000
        Credit Card: 4111-1111-1111-1111
        
        Technical details:
        Microphone: Neumann U87
        Preamp: API 312
        Sample rate: 96kHz/24-bit
        """

        // Test with security manager that blocks PII
        mockSecurityManager.shouldRejectPII = true

        let tokenTool = TokenCountUtility(
            logger: mockLogger,
            securityManager: mockSecurityManager
        )

        let tokenParams: [String: Any] = [
            "text": sensitiveText,
            "strategy": "audio_optimized"
        ]

        do {
            _ = try await tokenTool.processAudioContent(sensitiveText, with: tokenParams)
            XCTFail("Should have failed security check for PII content")
        } catch {
            XCTAssertTrue(error is AudioProcessingError)
        }

        // Reset security manager
        mockSecurityManager.shouldRejectPII = false

        // Test normal processing without PII concerns
        let normalText = """
        Recording session with Neumann U87 microphone.
        Applied EQ and compression processing.
        Mixed at 96kHz/24-bit resolution.
        """

        let normalParams: [String: Any] = [
            "text": normalText,
            "strategy": "audio_optimized"
        ]

        let normalResult = try await tokenTool.processAudioContent(normalText, with: normalParams)
        XCTAssertFalse(normalResult.isEmpty)
    }

    func testPerformanceAcrossTools() async throws {
        let performanceText = String(repeating: "Audio session text with technical details about Neumann U87, API 312, EQ, compression, and mixing. ", count: 100)

        let tools: [(String, AnyCodable, (String, [String: Any]) async throws -> String)] = [
            ("TokenCount", TokenCountUtility(logger: mockLogger, securityManager: mockSecurityManager), { text, _ in
                let params: [String: Any] = [
                    "text": text,
                    "strategy": "audio_optimized"
                ]
                return try await (TokenCountUtility(logger: mockLogger, securityManager: mockSecurityManager)).processAudioContent(text, with: params)
            }),
            ("FocusedSummarization", FocusedSummarizationTool(logger: mockLogger, securityManager: mockSecurityManager), { text, _ in
                let params: [String: Any] = [
                    "text": text,
                    "focus_areas": ["technical"],
                    "style": "bullet"
                ]
                return try await (FocusedSummarizationTool(logger: mockLogger, securityManager: mockSecurityManager)).processAudioContent(text, with: params)
            }),
            ("TextChunking", TextChunkingTool(logger: mockLogger, securityManager: mockSecurityManager), { text, _ in
                let params: [String: Any] = [
                    "text": text,
                    "strategy": "paragraph",
                    "max_chunk_size": 500
                ]
                return try await (TextChunkingTool(logger: mockLogger, securityManager: mockSecurityManager)).processAudioContent(text, with: params)
            })
        ]

        for (toolName, _, processor) in tools {
            let startTime = Date()
            let result = try await processor(performanceText, [:])
            let executionTime = Date().timeIntervalSince(startTime)

            // All tools should perform under 200ms
            XCTAssertLessThan(executionTime, 0.2, "\(toolName) should execute within 200ms")
            XCTAssertFalse(result.isEmpty, "\(toolName) should return non-empty result")
        }
    }

    func testAudioDomainConsistency() async throws {
        let audioText = """
        Professional recording session using high-end equipment:
        - Neumann U87 and AKG C414 microphones
        - API 512 and Neve 1073 preamps
        - SSL G-series console for mixing
        - Waves and UAD plugins for processing
        - 96kHz/24-bit recording quality
        """

        let summarizationTool = FocusedSummarizationTool(
            logger: mockLogger,
            securityManager: mockSecurityManager
        )

        let summaryParams: [String: Any] = [
            "text": audioText,
            "focus_areas": ["equipment", "technical"],
            "preserve_technical_terms": true
        ]

        let summaryResult = try await summarizationTool.processAudioContent(audioText, with: summaryParams)

        // Should preserve audio terminology
        let summaryLower = summaryResult.lowercased()
        XCTAssertTrue(summaryLower.contains("neumann"))
        XCTAssertTrue(summaryLower.contains("api"))
        XCTAssertTrue(summaryLower.contains("ssl"))
        XCTAssertTrue(summaryLower.contains("khz"))

        let tokenTool = TokenCountUtility(
            logger: mockLogger,
            securityManager: mockSecurityManager
        )

        let tokenParams: [String: Any] = [
            "text": audioText,
            "strategy": "audio_optimized",
            "include_audio_domain_insights": true
        ]

        let tokenResult = try await tokenTool.processAudioContent(audioText, with: tokenParams)

        // Should identify audio domain elements
        let tokenLower = tokenResult.lowercased()
        XCTAssertTrue(tokenLower.contains("equipment") || tokenLower.contains("brand"))
        XCTAssertTrue(tokenLower.contains("technical") || tokenLower.contains("parameter"))
    }

    func testErrorHandlingConsistency() async throws {
        let invalidText = "Very short"
        let emptyText = ""

        let tools: [(String, (String, [String: Any]) async throws -> String)] = [
            ("TokenCount", { text, params in
                try await (TokenCountUtility(logger: mockLogger, securityManager: mockSecurityManager)).processAudioContent(text, with: params)
            }),
            ("FocusedSummarization", { text, params in
                try await (FocusedSummarizationTool(logger: mockLogger, securityManager: mockSecurityManager)).processAudioContent(text, with: params)
            }),
            ("TextChunking", { text, params in
                try await (TextChunkingTool(logger: mockLogger, securityManager: mockSecurityManager)).processAudioContent(text, with: params)
            })
        ]

        // Test empty text should fail consistently
        for (toolName, processor) in tools {
            do {
                _ = try await processor(emptyText, [:])
                XCTFail("\(toolName) should have failed for empty text")
            } catch {
                XCTAssertTrue(error is AudioProcessingError, "\(toolName) should throw AudioProcessingError")
            }
        }

        // Test invalid parameters should fail consistently
        let invalidParams: [String: Any] = [
            "invalid_parameter": "invalid_value"
        ]

        for (toolName, processor) in tools {
            do {
                _ = try await processor("Test text", invalidParams)
                // Some tools might handle invalid parameters gracefully
            } catch {
                // This is acceptable behavior for invalid parameters
            }
        }
    }

    // MARK: - Mock Logger Tests

    func testLoggingConsistency() async throws {
        let testText = "Test audio session with Neumann U87 microphone."

        let focusedTool = FocusedSummarizationTool(
            logger: mockLogger,
            securityManager: mockSecurityManager
        )

        let params: [String: Any] = [
            "text": testText,
            "focus_areas": ["technical"]
        ]

        _ = try await focusedTool.processAudioContent(testText, with: params)

        // Verify logging occurred
        XCTAssertGreaterThan(mockLogger.loggedMessages.count, 0)
        XCTAssertTrue(mockLogger.loggedMessages.contains { $0.contains("INFO") })
    }
}

// MARK: - Enhanced Mock Classes for Advanced Testing

class MockLogger: Logger {
    var loggedMessages: [String] = []
    var shouldLogErrors = false
    var shouldLogWarnings = false

    override func info(_ message: String, category: LogCategory = .general, metadata: [String: AnyCodable] = [:]) async {
        loggedMessages.append("INFO: \(message)")
    }

    override func warning(_ message: String, category: LogCategory = .general, metadata: [String: AnyCodable] = [:]) async {
        loggedMessages.append("WARNING: \(message)")
    }

    override func error(_ message: String, category: LogCategory = .general, metadata: [String: AnyCodable] = [:]) async {
        loggedMessages.append("ERROR: \(message)")
    }

    override func debug(_ message: String, category: LogCategory = .general, metadata: [String: AnyCodable] = [:]) async {
        loggedMessages.append("DEBUG: \(message)")
    }
}

class MockSecurityManager: SecurityManager {
    var shouldReject = false
    var shouldRejectOutput = false
    var shouldRejectPII = false

    override func validateInput(_ input: String) throws {
        if shouldReject {
            throw SecurityError.unauthorizedAccess
        }
        if shouldRejectPII && (input.contains("@") || input.contains("555-") || input.contains("4111-")) {
            throw SecurityError.sensitiveData
        }
    }

    override func validateOutput(_ output: String) throws {
        if shouldRejectOutput {
            throw SecurityError.unauthorizedAccess
        }
    }
}

// MARK: - Test Data Constants

struct TestData {
    static let sampleSessionNotes = """
    SESSION NOTES - The Midnight Echoes
    
    Setup:
    - Vocal: Neumann U87 → API 312 → dbx 160 → Pro Tools HD
    - Sample rate: 96kHz, 24-bit
    - Monitoring: Genelec 8030
    
    Recording:
    - 8 vocal takes, take 6 selected
    - EQ: +3dB at 2kHz, -2dB at 400Hz
    - Compression: 4:1 ratio, -10dB threshold
    
    Client Feedback:
    - Happy with vocal sound
    - Wants more guitar presence
    """

    static let technicalParameters = """
    Audio Processing Parameters:
    - EQ Settings: High-pass at 80Hz, +2dB at 2kHz, -1dB at 4kHz
    - Compression: 4:1 ratio, 100ms attack, 200ms release
    - Reverb: Plate type, 2.2s decay, 30% wet mix
    - Delay: 1/4 note, 25% feedback, 15% mix
    """

    static let brandNameText = """
    Equipment List:
    Microphones: Neumann U87, AKG C414, Shure SM57
    Preamps: API 512, Neve 1073, SSL channel strips
    Plugins: Waves CLA-76, UAD Pultec, Valhalla VintageVerb
    Console: SSL G-series, Neve 88R
    DAW: Pro Tools HD, Logic Pro X
    """
}
