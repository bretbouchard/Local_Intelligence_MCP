//
//  TextChunkingToolTests.swift
//  LocalIntelligenceMCPTests
//
//  Created on 2025-10-08.
//

import XCTest
@testable import LocalIntelligenceMCP

final class TextChunkingToolTests: XCTestCase {

    // MARK: - Test Properties

    var tool: TextChunkingTool!
    var mockLogger: MockLogger!
    var mockSecurityManager: MockSecurityManager!

    // MARK: - Test Lifecycle

    override func setUp() async throws {
        try await super.setUp()
        mockLogger = MockLogger()
        mockSecurityManager = MockSecurityManager()
        tool = TextChunkingTool(
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
        XCTAssertEqual(tool.name, "apple.text.chunk")
        XCTAssertTrue(tool.description.contains("chunks"))
        XCTAssertEqual(tool.category, .textProcessing)
    }

    // MARK: - Basic Chunking Tests

    func testBasicParagraphChunking() async throws {
        let longText = """
        This is the first paragraph of audio session notes. It contains information about the recording setup and equipment used. The microphone selection was important for capturing the right sound.

        This is the second paragraph. It discusses the performance details and any issues encountered during the recording process. The vocalist performed exceptionally well.

        This is the third paragraph covering post-recording activities. It includes notes about editing, comping, and any additional processing that might be needed.
        """

        let parameters: [String: Any] = [
            "text": longText,
            "strategy": "paragraph",
            "max_chunk_size": 200
        ]

        let result = try await tool.processAudioContent(longText, with: parameters)

        // Should contain chunk information
        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains("chunks"))
        XCTAssertTrue(result.contains("total_chunks"))
    }

    func testFixedChunking() async throws {
        let longText = String(repeating: "This is test content for chunking. ", count: 50)

        let parameters: [String: Any] = [
            "text": longText,
            "strategy": "fixed",
            "max_chunk_size": 100
        ]

        let result = try await tool.processAudioContent(longText, with: parameters)

        XCTAssertFalse(result.isEmpty)
        // Should split text into roughly equal chunks
        XCTAssertTrue(result.contains("chunks"))
    }

    func testSentenceChunking() async throws {
        let longText = """
        This is the first sentence. The second sentence adds more information. Third sentence provides details.
        Fourth sentence continues the narrative. Fifth sentence concludes this paragraph.
        Here starts a new paragraph with more content. Additional sentences follow.
        Final sentence wraps up the content nicely.
        """

        let parameters: [String: Any] = [
            "text": longText,
            "strategy": "sentence",
            "max_chunk_size": 150
        ]

        let result = try await tool.processAudioContent(longText, with: parameters)

        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains("chunks"))
    }

    // MARK: - Audio Session Chunking Tests

    func testAudioSessionChunking() async throws {
        let sessionText = """
        [TRACK 1 - LEAD VOCAL]
        Take 1: Good start, slight pitch issues in second verse
        Take 2: Better emotional delivery, timing improved
        Take 3: Perfect performance selected for final take
        Notes: Used Neumann U87, API 312 preamp, dbx 160 compressor

        [TRACK 2 - ACOUSTIC GUITAR]
        Take 1: Clean performance, good timing
        Take 2: Slight buzz on fret change, kept Take 1
        Notes: AKG C414, Neve 1073 EQ, recorded in mono

        [TRACK 3 - ELECTRIC GUITAR]
        Take 1: Marshall JCM800 tone, aggressive playing
        Take 2: Fender Twin Reverb, cleaner tone
        Notes: SM57 on amp, double-tracked for width

        [TRACK 4 - BASS]
        Take 1: Direct input with SansAmp pedal
        Notes: Solid performance, minimal editing needed
        """

        let parameters: [String: Any] = [
            "text": sessionText,
            "strategy": "audio_session",
            "preserve_audio_structure": true
        ]

        let result = try await tool.processAudioContent(sessionText, with: parameters)

        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains("chunks"))
        // Should preserve track structure
        XCTAssertTrue(result.lowercased().contains("track"))
    }

    func testSemanticChunking() async throws {
        let technicalText = """
        Recording Setup and Configuration
        ================================
        The recording session began with careful microphone placement. We selected the Neumann U87 for vocals due to its warmth and clarity. The preamp chain consisted of an API 312 preamp feeding into a dbx 160 compressor for gentle dynamics control. The signal path then went through high-quality converters into Pro Tools HD.

        Technical Parameters and Settings
        ================================
        Sample rate was set to 96kHz with 24-bit resolution for maximum quality. All tracks were recorded with proper gain staging to ensure optimal signal-to-noise ratio. The monitoring setup used Genelec 8030 speakers positioned according to ITU standards for accurate sound reproduction.

        Performance Analysis
        ==================
        The vocalist delivered an exceptional performance across all takes. We tracked both lead vocals and harmonies to provide mixing options. The acoustic guitar performance was clean and precise, requiring minimal editing. Overall session productivity was high with excellent results achieved in minimal time.
        """

        let parameters: [String: Any] = [
            "text": technicalText,
            "strategy": "semantic",
            "max_chunk_size": 300
        ]

        let result = try await tool.processAudioContent(technicalText, with: parameters)

        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains("chunks"))
        // Should preserve semantic sections
        XCTAssertTrue(result.lowercased().contains("setup") || result.lowercased().contains("technical"))
    }

    // MARK: - Parameter Validation Tests

    func testMissingTextParameter() async throws {
        let parameters: [String: Any] = [
            "strategy": "paragraph",
            "max_chunk_size": 1000
        ]

        do {
            _ = try await tool.processAudioContent("", with: parameters)
            XCTFail("Should have thrown an error for missing text parameter")
        } catch {
            XCTAssertTrue(error is AudioProcessingError)
        }
    }

    func testInvalidStrategy() async throws {
        let parameters: [String: Any] = [
            "text": "Test text for chunking",
            "strategy": "invalid_strategy",
            "max_chunk_size": 1000
        ]

        do {
            _ = try await tool.processAudioContent("Test text", with: parameters)
            XCTFail("Should have thrown an error for invalid strategy")
        } catch {
            XCTAssertTrue(error is AudioProcessingError)
        }
    }

    func testInvalidChunkSize() async throws {
        let parameters: [String: Any] = [
            "text": "Test text",
            "strategy": "paragraph",
            "max_chunk_size": 50 // Below minimum
        ]

        do {
            _ = try await tool.processAudioContent("Test text", with: parameters)
            XCTFail("Should have thrown an error for invalid chunk size")
        } catch {
            XCTAssertTrue(error is AudioProcessingError)
        }
    }

    // MARK: - Edge Case Tests

    func testEmptyText() async throws {
        let parameters: [String: Any] = [
            "text": "",
            "strategy": "paragraph",
            "max_chunk_size": 1000
        ]

        do {
            _ = try await tool.processAudioContent("", with: parameters)
            XCTFail("Should have thrown an error for empty text")
        } catch {
            XCTAssertTrue(error is AudioProcessingError)
        }
    }

    func testVeryShortText() async throws {
        let shortText = "Short text."
        let parameters: [String: Any] = [
            "text": shortText,
            "strategy": "paragraph",
            "max_chunk_size": 1000
        ]

        let result = try await tool.processAudioContent(shortText, with: parameters)

        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains("chunks"))
        // Should have only one chunk for short text
        XCTAssertTrue(result.contains("\"total_chunks\":1"))
    }

    func testTextTooShortForChunkSize() async throws {
        let shortText = "This text is shorter than the requested chunk size."
        let parameters: [String: Any] = [
            "text": shortText,
            "strategy": "fixed",
            "max_chunk_size": 1000
        ]

        let result = try await tool.processAudioContent(shortText, with: parameters)

        XCTAssertFalse(result.isEmpty)
        // Should handle gracefully with one chunk
        XCTAssertTrue(result.contains("chunks"))
    }

    // MARK: - Overlap Tests

    func testChunkingWithOverlap() async throws {
        let longText = String(repeating: "This is test content for overlap testing. ", count: 20)

        let parameters: [String: Any] = [
            "text": longText,
            "strategy": "paragraph",
            "max_chunk_size": 200,
            "overlap": 50
        ]

        let result = try await tool.processAudioContent(longText, with: parameters)

        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains("chunks"))
        // Should have overlapping content between chunks
        XCTAssertTrue(result.lowercased().contains("overlap"))
    }

    func testZeroOverlap() async throws {
        let longText = String(repeating: "This is test content. ", count: 30)

        let parameters: [String: Any] = [
            "text": longText,
            "strategy": "fixed",
            "max_chunk_size": 150,
            "overlap": 0
        ]

        let result = try await tool.processAudioContent(longText, with: parameters)

        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains("chunks"))
    }

    // MARK: - Audio Domain Tests

    func testPreserveAudioStructure() async throws {
        let sessionText = """
        [TRACK 1] LEAD VOCAL - Take 3 selected
        Microphone: Neumann U87
        Preamp: API 312
        Processing: dbx 160 compression
        
        [TRACK 2] ACOUSTIC GUITAR - Take 1 selected
        Microphone: AKG C414
        Preamp: Neve 1073
        Position: 12th fret
        
        [MARKER] Chorus begins at 2:45
        [MARKER] Bridge section at 4:12
        """

        let parameters: [String: Any] = [
            "text": sessionText,
            "strategy": "audio_session",
            "preserve_audio_structure": true,
            "max_chunk_size": 200
        ]

        let result = try await tool.processAudioContent(sessionText, with: parameters)

        XCTAssertFalse(result.isEmpty)
        // Should preserve track and marker information
        XCTAssertTrue(result.lowercased().contains("track"))
        XCTAssertTrue(result.lowercased().contains("marker") || result.lowercased().contains("chorus"))
    }

    func testAudioTerminologyPreservation() async throws {
        let technicalText = """
        Applied EQ boost at 2kHz for vocal presence. Used 4:1 compression ratio on drums.
        Added plate reverb with 2.2 second decay. Mixed through SSL G-series console.
        Processed with Pro Tools HD at 96kHz/24-bit. Used Waves CLA-76 for vocal compression.
        """

        let parameters: [String: Any] = [
            "text": technicalText,
            "strategy": "semantic",
            "preserve_audio_structure": true
        ]

        let result = try await tool.processAudioContent(technicalText, with: parameters)

        XCTAssertFalse(result.isEmpty)
        // Should preserve audio terminology across chunks
        XCTAssertTrue(result.lowercased().contains("eq") || result.lowercased().contains("compression"))
    }

    // MARK: - Performance Tests

    func testPerformanceWithLargeText() async throws {
        let largeText = String(repeating: "This is a test sentence for performance testing with large text content. ", count: 200)

        let parameters: [String: Any] = [
            "text": largeText,
            "strategy": "paragraph",
            "max_chunk_size": 500
        ]

        let startTime = Date()
        let result = try await tool.processAudioContent(largeText, with: parameters)
        let executionTime = Date().timeIntervalSince(startTime)

        // Performance should be under 100ms
        XCTAssertLessThan(executionTime, 0.1)
        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains("chunks"))
    }

    func testMemoryUsageWithVeryLargeText() async throws {
        let veryLargeText = String(repeating: "Performance testing with very large text content to ensure memory usage stays reasonable. ", count: 1000)

        let parameters: [String: Any] = [
            "text": veryLargeText,
            "strategy": "fixed",
            "max_chunk_size": 1000
        ]

        let startTime = Date()
        let result = try await tool.processAudioContent(veryLargeText, with: parameters)
        let executionTime = Date().timeIntervalSince(startTime)

        // Should handle large text efficiently
        XCTAssertLessThan(executionTime, 0.2)
        XCTAssertFalse(result.isEmpty)
    }

    // MARK: - Metadata Tests

    func testChunkingMetadata() async throws {
        let sampleText = """
        First paragraph of sample text for testing metadata generation and chunk analysis.
        
        Second paragraph with additional content to test chunk size calculations.
        
        Third paragraph to ensure multiple chunks are created for proper testing.
        """

        let parameters: [String: Any] = [
            "text": sampleText,
            "strategy": "paragraph",
            "max_chunk_size": 150,
            "include_metadata": true
        ]

        let result = try await tool.processAudioContent(sampleText, with: parameters)

        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains("chunks"))
        // Should include metadata about the chunking process
        XCTAssertTrue(result.lowercased().contains("metadata") || result.lowercased().contains("statistics"))
    }

    func testChunkSizeAnalysis() async throws {
        let longText = String(repeating: "Testing chunk size analysis and distribution. ", count: 50)

        let parameters: [String: Any] = [
            "text": longText,
            "strategy": "fixed",
            "max_chunk_size": 200
        ]

        let result = try await tool.processAudioContent(longText, with: parameters)

        XCTAssertFalse(result.isEmpty)
        // Should provide information about chunk sizes
        XCTAssertTrue(result.contains("chunks"))
        XCTAssertTrue(result.lowercased().contains("length") || result.lowercased().contains("size"))
    }

    // MARK: - Integration Tests

    func testRealWorldSessionNotes() async throws {
        let realSessionText = """
        SESSION NOTES - The Midnight Echoes - "Electric Dreams" Album
        Date: October 8, 2025
        Engineer: John Smith
        Assistant: Sarah Johnson

        SETUP (9:00 AM - 10:00 AM)
        - Vocal booth: Neumann U87, API 312 preamp, dbx 160 compressor
        - Guitar amp room: Marshall JCM800, 4x12 cabinet, SM57 microphone
        - Bass: Direct input with SansAmp GT-2
        - Drums: Already tracked in previous session
        - Pro Tools HD system at 96kHz/24-bit
        
        LEAD VOCAL TRACKING (10:00 AM - 12:30 PM)
        - Track 1: Main vocal - Take 1 to 8
        - Best take: Take 6 (selected for final)
        - Notes: Slight pitch correction needed in second verse
        - Processing: EQ boost at 2kHz, de-esser at 4kHz
        
        HARMONY VOCALS (1:30 PM - 3:00 PM)
        - Track 2: High harmony - 3-part harmony, 4 takes
        - Track 3: Low harmony - 3-part harmony, 3 takes
        - Notes: Excellent blend, minimal editing needed
        - Reference: Beatles-style harmonies
        
        GUITAR OVERDUBS (3:30 PM - 5:30 PM)
        - Track 4: Lead guitar solo - 6 takes, best is take 4
        - Track 5: Rhythm guitar clean - 2 takes, both usable
        - Track 6: Rhythm guitar crunch - 3 takes, best is take 2
        - Notes: Used Gibson Les Paul, Marshall tone
        - Effects: Tube screamer, digital delay
        
        BASS ADDITIONS (5:30 PM - 6:30 PM)
        - Track 7: Bass fill-ins - 4 takes, comped best sections
        - Notes: Fender Precision Bass, direct with tube DI
        - Processing: SansAmp simulation, gentle compression
        
        ISSUES AND SOLUTIONS
        - Vocalist had throat discomfort at 2:15 PM - took 15 min break
        - Guitar amp buzz at 4:00 PM - changed power tubes, resolved
        - Pro Tools crash at 5:45 PM - restarted, no data loss
        
        CLIENT FEEDBACK
        - Very happy with vocal performances
        - Wants more guitar variety in final mix
        - Requested rough mix by end of week
        
        NEXT SESSION
        - Wednesday: Piano tracking and Hammond organ
        - Friday: Rough mix presentation
        - Monday: Client review and feedback session
        
        TOTAL TRACKS: 7
        SESSION TIME: 9.5 hours
        STATUS: Recording complete, ready for mixing phase
        """

        let parameters: [String: Any] = [
            "text": realSessionText,
            "strategy": "audio_session",
            "preserve_audio_structure": true,
            "max_chunk_size": 1000
        ]

        let result = try await tool.processAudioContent(realSessionText, with: parameters)

        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains("chunks"))
        // Should preserve session structure and technical details
        XCTAssertTrue(result.lowercased().contains("track"))
        XCTAssertTrue(result.lowercased().contains("vocal") || result.lowercased().contains("sing"))
        XCTAssertTrue(result.lowercased().contains("guitar") || result.lowercased().contains("amp"))
    }

    // MARK: - Security Tests

    func testSecurityCheckOnInput() async throws {
        let normalText = "Normal session text for testing."
        let parameters: [String: Any] = [
            "text": normalText,
            "strategy": "paragraph"
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
        let normalText = "Normal session text for testing."
        let parameters: [String: Any] = [
            "text": normalText,
            "strategy": "paragraph"
        ]

        mockSecurityManager.shouldRejectOutput = true

        do {
            _ = try await tool.processAudioContent(normalText, with: parameters)
            XCTFail("Should have failed output security check")
        } catch {
            XCTAssertTrue(error is AudioProcessingError)
        }
    }
}
