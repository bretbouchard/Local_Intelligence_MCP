//
//  TokenCountUtilityTests.swift
//  LocalIntelligenceMCPTests
//
//  Created on 2025-10-08.
//

import XCTest
@testable import LocalIntelligenceMCP

final class TokenCountUtilityTests: XCTestCase {

    // MARK: - Test Properties

    var tool: TokenCountUtility!
    var mockLogger: MockLogger!
    var mockSecurityManager: MockSecurityManager!

    // MARK: - Test Lifecycle

    override func setUp() async throws {
        try await super.setUp()
        mockLogger = MockLogger()
        mockSecurityManager = MockSecurityManager()
        tool = TokenCountUtility(
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
        XCTAssertNotNil(tool)
        XCTAssertEqual(tool.name, "apple.tokens.count")
        XCTAssertTrue(tool.description.contains("token"))
        XCTAssertEqual(tool.category, .textProcessing)
    }

    // MARK: - Basic Token Counting Tests

    func testBasicTokenCounting() async throws {
        let sampleText = """
        Applied EQ boost at 2kHz for vocal presence. Used Waves CLA-76 compressor with 4:1 ratio.
        Added plate reverb using Valhalla VintageVerb. Mixed through SSL console.
        """

        let parameters: [String: Any] = [
            "text": sampleText,
            "strategy": "audio_optimized",
            "content_type": "session_notes"
        ]

        let result = try await tool.processAudioContent(sampleText, with: parameters)

        XCTAssertFalse(result.isEmpty)
        // Should contain token count information
        XCTAssertTrue(result.contains("token_count"))
        XCTAssertTrue(result.contains("analysis"))
    }

    func testCharacterBasedStrategy() async throws {
        let text = "This is a simple test text for token counting analysis."

        let parameters: [String: Any] = [
            "text": text,
            "strategy": "character_based",
            "include_breakdown": true
        ]

        let result = try await tool.processAudioContent(text, with: parameters)

        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains("token_count"))
        // Character-based strategy should be noted in analysis
        XCTAssertTrue(result.lowercased().contains("character"))
    }

    func testWordBasedStrategy() async throws {
        let text = "Applied compression with 4:1 ratio and medium attack setting."

        let parameters: [String: Any] = [
            "text": text,
            "strategy": "word_based",
            "include_breakdown": true
        ]

        let result = try await tool.processAudioContent(text, with: parameters)

        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains("token_count"))
        XCTAssertTrue(result.lowercased().contains("word"))
    }

    // MARK: - Content Type Tests

    func testTranscriptContentType() async throws {
        let transcriptText = """
        Interviewer: So tell me about your approach to mixing vocals.
        Engineer: Well, I start with EQ for clarity, then compression for control.
        I typically use a Pultec EQP-1A for warmth and an LA-2A for smooth compression.
        """

        let parameters: [String: Any] = [
            "text": transcriptText,
            "strategy": "semantic_aware",
            "content_type": "transcript",
            "include_breakdown": true
        ]

        let result = try await tool.processAudioContent(transcriptText, with: parameters)

        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains("token_count"))
        // Should recognize transcript content type
        XCTAssertTrue(result.lowercased().contains("transcript"))
    }

    func testSessionNotesContentType() async throws {
        let sessionText = """
        Session Notes:
        - Microphone: Neumann U87
        - Preamp: API 312
        - Processing: dbx 160 compression
        - Sample Rate: 96kHz
        - Bit Depth: 24-bit
        """

        let parameters: [String: Any] = [
            "text": sessionText,
            "strategy": "audio_optimized",
            "content_type": "session_notes"
        ]

        let result = try await tool.processAudioContent(sessionText, with: parameters)

        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains("token_count"))
        // Should detect session notes format
        XCTAssertTrue(result.lowercased().contains("session"))
    }

    func testPluginDocsContentType() async throws {
        let pluginText = """
        Waves CLA-76 Manual:
        
        The CLA-76 is modeled after the classic UREI 1176 limiting amplifier.
        
        Parameters:
        - Ratio: 4:1 (default), 8:1, 12:1, 20:1
        - Attack: Fast (default), Medium, Slow
        - Release: Auto (default), Fast, Medium, Slow
        - Input Gain: 0dB to +20dB
        """

        let parameters: [String: Any] = [
            "text": pluginText,
            "strategy": "audio_optimized",
            "content_type": "plugin_docs"
        ]

        let result = try await tool.processAudioContent(pluginText, with: parameters)

        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains("token_count"))
        // Should detect plugin documentation
        XCTAssertTrue(result.lowercased().contains("plugin"))
    }

    // MARK: - Audio Domain Vocabulary Tests

    func testAudioTechnicalTerms() async throws {
        let technicalText = """
        Applied EQ boost at 2kHz and 4kHz cut. Used 4:1 compression ratio.
        Added plate reverb with 2.2 second decay. Processed at 96kHz/24-bit.
        Used Neumann U87 microphone through API 312 preamp.
        Mixed on SSL G-series console with Waves plugins.
        """

        let parameters: [String: Any] = [
            "text": technicalText,
            "strategy": "audio_optimized",
            "include_breakdown": true
        ]

        let result = try await tool.processAudioContent(technicalText, with: parameters)

        XCTAssertFalse(result.isEmpty)
        // Should detect and count audio technical terms
        let resultLower = result.lowercased()
        XCTAssertTrue(resultLower.contains("eq"))
        XCTAssertTrue(resultLower.contains("compression"))
        XCTAssertTrue(resultLower.contains("reverb"))
        XCTAssertTrue(resultLower.contains("khz"))
        XCTAssertTrue(resultLower.contains("bit"))
    }

    func testAudioBrandNames() async throws {
        let brandText = """
        Equipment list: Neumann U87, AKG C414, Shure SM57, Sennheiser 421.
        Preamps: API 512, Neve 1073, SSL channel strips.
        Plugins: Waves CLA-76, UAD Pultec, Valhalla VintageVerb.
        DAW: Pro Tools HD, Logic Pro X.
        Monitoring: Genelec speakers.
        """

        let parameters: [String: Any] = [
            "text": brandText,
            "strategy": "audio_optimized",
            "include_breakdown": true
        ]

        let result = try await tool.processAudioContent(brandText, with: parameters)

        XCTAssertFalse(result.isEmpty)
        // Should detect brand names in audio domain insights
        let resultLower = result.lowercased()
        XCTAssertTrue(resultLower.contains("neumann"))
        XCTAssertTrue(resultLower.contains("api"))
        XCTAssertTrue(resultLower.contains("ssl"))
        XCTAssertTrue(resultLower.contains("waves"))
        XCTAssertTrue(resultLower.contains("pro tools"))
    }

    func testAudioParametersAndSettings() async throws {
        let parameterText = """
        EQ Settings: +3dB at 2kHz, -2dB at 400Hz, high-pass at 80Hz.
        Compression: 4:1 ratio, -10dB threshold, 2dB makeup gain.
        Reverb: Plate type, 2.2s decay, 30% wet mix.
        Delay: 1/4 note, 25% feedback, 15% mix.
        """

        let parameters: [String: Any] = [
            "text": parameterText,
            "strategy": "audio_optimized",
            "include_breakdown": true
        ]

        let result = try await tool.processAudioContent(parameterText, with: parameters)

        XCTAssertFalse(result.isEmpty)
        // Should detect numeric parameters and settings
        let resultLower = result.lowercased()
        XCTAssertTrue(resultLower.contains("db"))
        XCTAssertTrue(resultLower.contains("khz"))
        XCTAssertTrue(resultLower.contains("ratio"))
        XCTAssertTrue(resultLower.contains("threshold"))
    }

    // MARK: - Strategy Comparison Tests

    func testStrategyComparison() async throws {
        let testText = """
        Recording session with Neumann U87 microphone. Applied EQ processing
        and compression. Mixed through SSL console with Waves plugins.
        """

        let strategies = ["character_based", "word_based", "semantic_aware", "audio_optimized", "mixed"]
        var tokenCounts: [String: Int] = [:]

        for strategy in strategies {
            let parameters: [String: Any] = [
                "text": testText,
                "strategy": strategy,
                "include_breakdown": true
            ]

            let result = try await tool.processAudioContent(testText, with: parameters)
            
            // Extract token count from result (simplified extraction)
            if let range = result.range(of: "\"token_count\":") {
                let startIndex = result.index(range.upperBound, offsetBy: 1)
                let endIndex = result.index(startIndex, offsetBy: 10)
                let tokenCountString = String(result[startIndex..<endIndex]).trimmingCharacters(in: .whitespacesAndPunctuation + "\"")
                if let count = Int(tokenCountString) {
                    tokenCounts[strategy] = count
                }
            }
        }

        // Audio-optimized should account for audio domain complexity
        XCTAssertGreaterThan(tokenCounts["audio_optimized"] ?? 0, tokenCounts["character_based"] ?? 0)
        // Mixed should be most comprehensive
        XCTAssertGreaterThanOrEqual(tokenCounts["mixed"] ?? 0, tokenCounts["audio_optimized"] ?? 0)
    }

    // MARK: - Chunk Analysis Tests

    func testChunkAnalysisEnabled() async throws {
        let longText = String(repeating: "Audio session text with technical details about EQ and compression. ", count: 50)

        let parameters: [String: Any] = [
            "text": longText,
            "strategy": "audio_optimized",
            "include_chunk_analysis": true,
            "chunk_size": 500
        ]

        let result = try await tool.processAudioContent(longText, with: parameters)

        XCTAssertFalse(result.isEmpty)
        // Should include chunk analysis section
        XCTAssertTrue(result.lowercased().contains("chunk"))
    }

    func testChunkAnalysisDisabled() async throws {
        let longText = String(repeating: "Test text for analysis without chunks. ", count: 30)

        let parameters: [String: Any] = [
            "text": longText,
            "strategy": "word_based",
            "include_chunk_analysis": false
        ]

        let result = try await tool.processAudioContent(longText, with: parameters)

        XCTAssertFalse(result.isEmpty)
        // Should not include chunk analysis when disabled
        XCTAssertFalse(result.lowercased().contains("chunk"))
    }

    // MARK: - Performance Tests

    func testPerformanceWithLargeText() async throws {
        let largeText = String(repeating: "Technical audio processing with EQ, compression, and reverb. ", count: 200)

        let parameters: [String: Any] = [
            "text": largeText,
            "strategy": "audio_optimized"
        ]

        let startTime = Date()
        let result = try await tool.processAudioContent(largeText, with: parameters)
        let executionTime = Date().timeIntervalSince(startTime)

        // Performance should be under 50ms
        XCTAssertLessThan(executionTime, 0.05)
        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains("token_count"))
    }

    func testPerformanceWithComplexStrategy() async throws {
        let complexText = """
        Neumann U87 microphone through API 312 preamp, dbx 160 compressor.
        EQ with Pultec EQP-1A for warmth and SSL channel strip for color.
        Processing at 96kHz/24-bit in Pro Tools HD.
        Mixed through SSL G-series console with Waves plugins.
        Used Valhalla VintageVerb for reverb and Soundtoys EchoBoy for delay.
        """

        let parameters: [String: Any] = [
            "text": complexText,
            "strategy": "mixed",
            "include_breakdown": true,
            "include_chunk_analysis": true
        ]

        let startTime = Date()
        let result = try await tool.processAudioContent(complexText, with: parameters)
        let executionTime = Date().timeIntervalSince(startTime)

        // Even complex strategy should be fast
        XCTAssertLessThan(executionTime, 0.1)
        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains("token_count"))
    }

    // MARK: - Edge Case Tests

    func testEmptyText() async throws {
        let parameters: [String: Any] = [
            "text": "",
            "strategy": "character_based"
        ]

        do {
            _ = try await tool.processAudioContent("", with: parameters)
            XCTFail("Should have thrown an error for empty text")
        } catch {
            XCTAssertTrue(error is AudioProcessingError)
        }
    }

    func testVeryShortText() async throws {
        let shortText = "Test"
        let parameters: [String: Any] = [
            "text": shortText,
            "strategy": "word_based",
            "include_breakdown": true
        ]

        let result = try await tool.processAudioContent(shortText, with: parameters)

        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains("token_count"))
        // Should handle short text gracefully
        let tokenCount = extractTokenCount(from: result)
        XCTAssertGreaterThan(tokenCount, 0)
    }

    func testTextWithOnlyNumbers() async throws {
        let numberText = "96 24 4.1 2000 44.1"

        let parameters: [String: Any] = [
            "text": numberText,
            "strategy": "audio_optimized",
            "include_breakdown": true
        ]

        let result = try await tool.processAudioContent(numberText, with: parameters)

        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains("token_count"))
        // Should handle numeric-only text
    }

    func testTextWithOnlyPunctuation() async throws {
        let punctuationText = "...---!@#$%^&*()"

        let parameters: [String: Any] = [
            "text": punctuationText,
            "strategy": "character_based",
            "include_breakdown": true
        ]

        let result = try await tool.processAudioContent(punctuationText, with: parameters)

        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains("token_count"))
        // Should handle punctuation-only text
    }

    // MARK: - Audio Domain Complexity Tests

    func testLowComplexityContent() async throws {
        let simpleText = "Recording session went well. Basic setup with microphone and preamp."

        let parameters: [String: Any] = [
            "text": simpleText,
            "strategy": "audio_optimized",
            "include_breakdown": true
        ]

        let result = try await tool.processAudioContent(simpleText, with: parameters)

        XCTAssertFalse(result.isEmpty)
        // Should identify low complexity audio content
        let resultLower = result.lowercased()
        XCTAssertTrue(resultLower.contains("low") || resultLower.contains("basic"))
    }

    func testHighComplexityContent() async throws {
        let complexText = """
        Advanced mixing session: Neumann U87 → API 312 → dbx 160 → Pultec EQP-1A → SSL G-Series.
        Parallel processing: Waves CLA-76 (4:1, -10dB threshold), UAD Fairchild 670 (bus compression),
        Valhalla VintageVerb (plate, 2.2s decay, pre-delay 35ms), Soundtoys Decapitator (saturation).
        Mid/Side processing: EQ on mid channel, stereo widening on sides.
        Automation: Volume rides on vocals, panning automation on instruments.
        """

        let parameters: [String: Any] = [
            "text": complexText,
            "strategy": "audio_optimized",
            "include_breakdown": true
        ]

        let result = try await tool.processAudioContent(complexText, with: parameters)

        XCTAssertFalse(result.isEmpty)
        // Should identify high complexity content
        let resultLower = result.lowercased()
        XCTAssertTrue(resultLower.contains("high") || resultLower.contains("complex") || resultLower.contains("advanced"))
    }

    // MARK: - Parameter Validation Tests

    func testInvalidStrategy() async throws {
        let parameters: [String: Any] = [
            "text": "Test text",
            "strategy": "invalid_strategy"
        ]

        do {
            _ = try await tool.processAudioContent("Test text", with: parameters)
            XCTFail("Should have thrown an error for invalid strategy")
        } catch {
            XCTAssertTrue(error is AudioProcessingError)
        }
    }

    func testInvalidContentType() async throws {
        let parameters: [String: Any] = [
            "text": "Test text",
            "strategy": "word_based",
            "content_type": "invalid_type"
        ]

        do {
            _ = try await tool.processAudioContent("Test text", with: parameters)
            XCTFail("Should have thrown an error for invalid content type")
        } catch {
            XCTAssertTrue(error is AudioProcessingError)
        }
    }

    func testInvalidChunkSize() async throws {
        let parameters: [String: Any] = [
            "text": "Test text",
            "strategy": "audio_optimized",
            "include_chunk_analysis": true,
            "chunk_size": 500 // Below minimum of 1000
        ]

        do {
            _ = try await tool.processAudioContent("Test text", with: parameters)
            XCTFail("Should have thrown an error for invalid chunk size")
        } catch {
            XCTAssertTrue(error is AudioProcessingError)
        }
    }

    // MARK: - Integration Tests

    func testRealWorldSessionNotes() async throws {
        let sessionText = """
        Session: The Midnight Echoes - Track "Electric Dreams"
        Date: October 8, 2025
        
        Setup:
        - Vocal: Neumann U87 → API 312 → dbx 160 → Pro Tools HD
        - Sample rate: 96kHz, 24-bit
        - Monitoring: Genelec 8030, calibrated to 85dB SPL
        
        Vocal Recording:
        - 8 takes recorded, take 6 selected
        - Processing: EQ boost at 2kHz, de-esser at 4kHz
        - Plugin chain: Waves CLA-76, Pultec EQP-1A
        
        Guitar Tracking:
        - Gibson Les Paul → Marshall JCM800 → SM57
        - Double-tracked for stereo width
        - Amp settings: Volume 7, Treble 6, Bass 5, Presence 4
        
        Issues:
        - Vocalist pitch issues in bridge, used Melodyne
        - Guitar amp buzz, changed tubes
        
        Client Feedback:
        - Very happy with vocal sound
        - Wants more aggression in guitar tone
        
        Next Steps:
        - Piano tracking on Wednesday
        - Rough mix by Friday
        """

        let parameters: [String: Any] = [
            "text": sessionText,
            "strategy": "audio_optimized",
            "content_type": "session_notes",
            "include_breakdown": true,
            "include_audio_domain_insights": true
        ]

        let result = try await tool.processAudioContent(sessionText, with: parameters)

        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains("token_count"))
        // Should detect various audio domain elements
        let resultLower = result.lowercased()
        XCTAssertTrue(resultLower.contains("neumann") || resultLower.contains("microphone"))
        XCTAssertTrue(resultLower.contains("api") || resultLower.contains("preamp"))
        XCTAssertTrue(resultLower.contains("plugin") || resultLower.contains("waves"))
        XCTAssertTrue(resultLower.contains("khz") || resultLower.contains("bit"))
    }

    // MARK: - Security Tests

    func testSecurityCheckOnInput() async throws {
        let normalText = "Normal audio session text for testing."
        let parameters: [String: Any] = [
            "text": normalText,
            "strategy": "audio_optimized"
        ]

        mockSecurityManager.shouldReject = true

        do {
            _ = try await tool.processAudioContent(normalText, with: parameters)
            XCTFail("Should have failed security check")
        } catch {
            XCTAssertTrue(error is AudioProcessingError)
        }
    }

    func testSecurityCheckOnOutput() async throws {
        let normalText = "Normal audio session text for testing."
        let parameters: [String: Any] = [
            "text": normalText,
            "strategy": "word_based"
        ]

        mockSecurityManager.shouldRejectOutput = true

        do {
            _ = try await tool.processAudioContent(normalText, with: parameters)
            XCTFail("Should have failed output security check")
        } catch {
            XCTAssertTrue(error is AudioProcessingError)
        }
    }

    // MARK: - Helper Methods

    private func extractTokenCount(from result: String) -> Int {
        if let range = result.range(of: "\"token_count\":") {
            let startIndex = result.index(range.upperBound, offsetBy: 1)
            let endIndex = result.index(startIndex, offsetBy: 10)
            let substring = String(result[startIndex..<endIndex])
            let cleaned = substring.trimmingCharacters(in: .whitespacesAndPunctuation + "\"")
            return Int(cleaned) ?? 0
        }
        return 0
    }
}
