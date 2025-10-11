//
//  TagGenerationToolTests.swift
//  LocalIntelligenceMCPTests
//
//  Created on 2025-10-09.
//

import XCTest
@testable import LocalIntelligenceMCP

/// Comprehensive unit tests for TagGenerationTool
/// Tests tag generation, confidence scoring, categorization, and audio domain specialization
final class TagGenerationToolTests: XCTestCase {

    // MARK: - Test Properties

    var mockLogger: MockLogger!
    var mockSecurityManager: MockSecurityManager!
    var tagTool: TagGenerationTool!

    // MARK: - Test Lifecycle

    override func setUp() async throws {
        try await super.setUp()
        mockLogger = MockLogger()
        mockSecurityManager = MockSecurityManager()
        tagTool = TagGenerationTool(logger: mockLogger, securityManager: mockSecurityManager)
    }

    override func tearDown() async throws {
        mockLogger = nil
        mockSecurityManager = nil
        tagTool = nil
        try await super.tearDown()
    }

    // MARK: - Equipment Tag Generation Tests

    func testGenerateMicrophoneTags() async throws {
        let testCases = [
            "Recorded with Neumann U87 microphone",
            "Used AKG C414 for vocals",
            "SM57 on guitar cabinet",
            "Sennheiser MKH416 for voiceover"
        ]

        for testCase in testCases {
            let result = try await tagTool.processAudioContent(testCase, with: [:])
            XCTAssertFalse(result.isEmpty)

            // Verify microphone tag generation
            XCTAssertTrue(result.contains("tags"))
            let hasMicrophoneTag = testCase.contains("Neumann") || testCase.contains("AKG") || testCase.contains("SM57") || testCase.contains("Sennheiser")
            if hasMicrophoneTag {
                XCTAssertTrue(result.lowercased().contains("neumann") || result.lowercased().contains("akg") || result.lowercased().contains("sm57") || result.lowercased().contains("sennheiser"))
            }
        }
    }

    func testGenerateConsoleTags() async throws {
        let testCases = [
            "Mixed on SSL AWS console",
            "Used Neve 88RS for analog warmth",
            "API Vision console for tracking",
            "Focusrite Red 4 for preamps"
        ]

        for testCase in testCases {
            let result = try await tagTool.processAudioContent(testCase, with: [:])
            XCTAssertFalse(result.isEmpty)

            // Verify console tag generation
            let hasConsoleBrand = testCase.contains("SSL") || testCase.contains("Neve") || testCase.contains("API") || testCase.contains("Focusrite")
            if hasConsoleBrand {
                XCTAssertTrue(result.lowercased().contains("ssl") || result.lowercased().contains("neve") || result.lowercased().contains("api") || result.lowercased().contains("focusrite"))
            }
        }
    }

    func testGenerateDAWTags() async throws {
        let testCases = [
            "Edited in Pro Tools session",
            "Composed in Logic Pro X",
            "Production in Ableton Live",
            "Mixed in Cubase 12"
        ]

        for testCase in testCases {
            let result = try await tagTool.processAudioContent(testCase, with: [:])
            XCTAssertFalse(result.isEmpty)

            // Verify DAW tag generation
            let hasDAWName = testCase.contains("Pro Tools") || testCase.contains("Logic Pro") || testCase.contains("Ableton") || testCase.contains("Cubase")
            if hasDAWName {
                XCTAssertTrue(result.contains("Pro Tools") || result.contains("Logic Pro") || result.contains("Ableton") || result.contains("Cubase"))
            }
        }
    }

    // MARK: - Technical Tag Generation Tests

    func testGenerateProcessingTags() async throws {
        let testCases = [
            "Applied compression to vocals",
            "Used EQ on the bass track",
            "Added reverb to the drums",
            "Used delay on the guitars"
        ]

        for testCase in testCases {
            let result = try await tagTool.processAudioContent(testCase, with: [:])
            XCTAssertFalse(result.isEmpty)

            // Verify processing tag generation
            let hasProcessingTerm = testCase.contains("compression") || testCase.contains("EQ") || testCase.contains("reverb") || testCase.contains("delay")
            if hasProcessingTerm {
                XCTAssertTrue(result.lowercased().contains("compression") || result.lowercased().contains("eq") || result.lowercased().contains("reverb") || result.lowercased().contains("delay"))
            }
        }
    }

    func testGenerateFormatTags() async throws {
        let testCases = [
            "Exported as WAV file",
            "Compressed to MP3 format",
            "Used FLAC for high quality",
            "Delivered in AIFF format"
        ]

        for testCase in testCases {
            let result = try await tagTool.processAudioContent(testCase, with: [:])
            XCTAssertFalse(result.isEmpty)

            // Verify format tag generation
            let hasFormatName = testCase.contains("WAV") || testCase.contains("MP3") || testCase.contains("FLAC") || testCase.contains("AIFF")
            if hasFormatName {
                XCTAssertTrue(result.contains("WAV") || result.contains("MP3") || result.contains("FLAC") || result.contains("AIFF"))
            }
        }
    }

    func testGenerateTechnicalParameterTags() async throws {
        let testCases = [
            "Sample rate: 96kHz",
            "Bit depth: 24-bit",
            "Recording at 48kHz/16-bit",
            "High resolution 192kHz/32-bit"
        ]

        for testCase in testCases {
            let result = try await tagTool.processAudioContent(testCase, with: [:])
            XCTAssertFalse(result.isEmpty)

            // Verify technical parameter tag generation
            let hasParameter = testCase.contains("kHz") || testCase.contains("bit")
            if hasParameter {
                XCTAssertTrue(result.contains("96kHz") || result.contains("24-bit") || result.contains("48kHz") || result.contains("192kHz"))
            }
        }
    }

    // MARK: - Workflow Tag Generation Tests

    func testGenerateWorkflowStageTags() async throws {
        let testCases = [
            "Started recording the vocals",
            "Mixing the bass track",
            "Mastering the final album",
            "Editing the guitar parts"
        ]

        for testCase in testCases {
            let result = try await tagTool.processAudioContent(testCase, with: [:])
            XCTAssertFalse(result.isEmpty)

            // Verify workflow stage tag generation
            let hasWorkflowStage = testCase.contains("recording") || testCase.contains("mixing") || testCase.contains("mastering") || testCase.contains("editing")
            if hasWorkflowStage {
                XCTAssertTrue(result.lowercased().contains("recording") || result.lowercased().contains("mixing") || result.lowercased().contains("mastering") || result.lowercased().contains("editing"))
            }
        }
    }

    func testGenerateActionTags() async throws {
        let testCases = [
            "Compress the vocals",
            "Equalize the bass",
            "Record the drums",
            "Process the audio"
        ]

        for testCase in testCases {
            let result = try await tagTool.processAudioContent(testCase, with: [:])
            XCTAssertFalse(result.isEmpty)

            // Verify action tag generation
            let hasAction = testCase.contains("Compress") || testCase.contains("Equalize") || testCase.contains("Record") || testCase.contains("Process")
            if hasAction {
                XCTAssertTrue(result.lowercased().contains("compress") || result.lowercased().contains("equalize") || result.lowercased().contains("record") || result.lowercased().contains("process"))
            }
        }
    }

    // MARK: - Genre Tag Generation Tests

    func testGenerateMusicGenreTags() async throws {
        let testCases = [
            "Rock band recording session",
            "Jazz trio in the studio",
            "Electronic music production",
            "Classical orchestra recording"
        ]

        for testCase in testCases {
            let result = try await tagTool.processAudioContent(testCase, with: [:])
            XCTAssertFalse(result.isEmpty)

            // Verify genre tag generation
            let hasGenre = testCase.contains("Rock") || testCase.contains("Jazz") || testCase.contains("Electronic") || testCase.contains("Classical")
            if hasGenre {
                XCTAssertTrue(result.lowercased().contains("rock") || result.lowercased().contains("jazz") || result.lowercased().contains("electronic") || result.lowercased().contains("classical"))
            }
        }
    }

    func testGenerateInstrumentTags() async throws {
        let testCases = [
            "Vocal recording session",
            "Guitar amplifier setup",
            "Bass guitar tracking",
            "Drum kit recording",
            "Piano performance"
        ]

        for testCase in testCases {
            let result = try await tagTool.processAudioContent(testCase, with: [:])
            XCTAssertFalse(result.isEmpty)

            // Verify instrument tag generation
            let hasInstrument = testCase.contains("vocal") || testCase.contains("guitar") || testCase.contains("bass") || testCase.contains("drum") || testCase.contains("piano")
            if hasInstrument {
                XCTAssertTrue(result.lowercased().contains("vocal") || result.lowercased().contains("guitar") || result.lowercased().contains("bass") || result.lowercased().contains("drum") || result.lowercased().contains("piano"))
            }
        }
    }

    // MARK: - Business Tag Generation Tests

    func testGenerateRoleTags() async throws {
        let testCases = [
            "Producer is John Smith",
            "Engineer: Sarah Johnson",
            "Mixed by mixing engineer",
            "Artist performance"
        ]

        for testCase in testCases {
            let result = try await tagTool.processAudioContent(testCase, with: [:])
            XCTAssertFalse(result.isEmpty)

            // Verify role tag generation
            let hasRole = testCase.contains("producer") || testCase.contains("engineer") || testCase.contains("artist")
            if hasRole {
                XCTAssertTrue(result.lowercased().contains("producer") || result.lowercased().contains("engineer") || result.lowercased().contains("artist"))
            }
        }
    }

    func testGenerateBusinessTermTags() async throws {
        let testCases = [
            "Client review session",
            "Project deadline approaching",
            "Studio booking confirmed",
            "Budget constraints discussed"
        ]

        for testCase in testCases {
            let result = try await tagTool.processAudioContent(testCase, with: [:])
            XCTAssertFalse(result.isEmpty)

            // Verify business term tag generation
            let hasBusinessTerm = testCase.contains("client") || testCase.contains("project") || testCase.contains("studio") || testCase.contains("budget")
            if hasBusinessTerm {
                XCTAssertTrue(result.lowercased().contains("client") || result.lowercased().contains("project") || result.lowercased().contains("studio") || result.lowercased().contains("budget"))
            }
        }
    }

    // MARK: - Vocabulary-Based Tag Tests

    func testGenerateVocabularyTags() async throws {
        let testCase = "Recording session with vocals and mixing"
        let vocabulary = ["vocal", "mixing", "mastering", "production"]

        let result = try await tagTool.processAudioContent(testCase, with: ["vocabulary": vocabulary])

        XCTAssertFalse(result.isEmpty)

        // Should include vocabulary tags with high confidence
        XCTAssertTrue(result.contains("vocal") || result.contains("mixing"))

        // Should have vocabulary metadata
        XCTAssertTrue(result.contains("vocabularyUsed"))
        XCTAssertTrue(result.contains("true"))
    }

    func testVocabularyPriority() async throws {
        let testCase = "Audio production work"
        let vocabulary = ["production", "audio", "work", "session"]

        let result = try await tagTool.processAudioContent(testCase, with: ["vocabulary": vocabulary])

        XCTAssertFalse(result.isEmpty)

        // Vocabulary terms should have high confidence (0.9+)
        XCTAssertTrue(result.contains("0.9") || result.contains("1.0"))
    }

    // MARK: - Audio Context Tests

    func testRecordingDomainContext() async throws {
        let testCase = "Setup microphones and preamps for tracking"
        let audioContext = [
            "domain": "recording",
            "document_type": "session_notes"
        ]

        let result = try await tagTool.processAudioContent(testCase, with: ["audio_context": audioContext])

        XCTAssertFalse(result.isEmpty)

        // Should include recording-specific tags
        XCTAssertTrue(result.lowercased().contains("recording") || result.lowercased().contains("microphone") || result.lowercased().contains("tracking"))

        // Should have recording domain metadata
        XCTAssertTrue(result.contains("recording"))
    }

    func testMixingDomainContext() async throws {
        let testCase = "Apply EQ and compression to the mix"
        let audioContext = [
            "domain": "mixing",
            "document_type": "mix_notes"
        ]

        let result = try await tagTool.processAudioContent(testCase, with: ["audio_context": audioContext])

        XCTAssertFalse(result.isEmpty)

        // Should include mixing-specific tags
        XCTAssertTrue(result.lowercased().contains("mixing") || result.lowercased().contains("eq") || result.lowercased().contains("compression"))

        // Should have mixing domain metadata
        XCTAssertTrue(result.contains("mixing"))
    }

    func testMasteringDomainContext() async throws {
        let testCase = "Final limiting and EQ adjustments"
        let audioContext = [
            "domain": "mastering",
            "document_type": "mastering_notes"
        ]

        let result = try await tagTool.processAudioContent(testCase, with: ["audio_context": audioContext])

        XCTAssertFalse(result.isEmpty)

        // Should include mastering-specific tags
        XCTAssertTrue(result.lowercased().contains("mastering") || result.lowercased().contains("limiting") || result.lowercased().contains("eq"))

        // Should have mastering domain metadata
        XCTAssertTrue(result.contains("mastering"))
    }

    // MARK: - Tag Limit and Filtering Tests

    func testTagLimit() async throws {
        let testCase = "Recording session with Neumann U87, SSL console, Pro Tools, compression, EQ, reverb, delay, vocals, guitar, bass, drums, producer, engineer, client, project, studio, budget, deadline"

        let parameters = [
            "limit": 5,
            "audio_context": ["min_confidence": 0.1]
        ]

        let result = try await tagTool.processAudioContent(testCase, with: parameters)

        XCTAssertFalse(result.isEmpty)

        // Should limit to 5 tags
        let resultData = result.data(using: .utf8)!
        let json = try JSONSerialization.jsonObject(with: resultData) as! [String: Any]
        let tags = json["tags"] as! [[String: Any]]

        XCTAssertLessThanOrEqual(tags.count, 5, "Should limit tags to specified amount")
    }

    func testConfidenceThresholdFiltering() async throws {
        let testCase = "Some general audio work"
        let audioContext = [
            "min_confidence": 0.9
        ]

        let result = try await tagTool.processAudioContent(testCase, with: ["audio_context": audioContext])

        XCTAssertFalse(result.isEmpty)

        // All tags should have confidence >= 0.9
        let resultData = result.data(using: .utf8)!
        let json = try JSONSerialization.jsonObject(with: resultData) as! [String: Any]
        let tags = json["tags"] as! [[String: Any]]

        for tag in tags {
            let confidence = tag["confidence"] as! Double
            XCTAssertGreaterThanOrEqual(confidence, 0.9, "All tags should meet minimum confidence threshold")
        }
    }

    func testIncludeOptionsFiltering() async throws {
        let testCase = "Recording session with client and compression settings"

        // Test with only entities enabled
        let audioContext1 = [
            "include_entities": true,
            "include_technical": false,
            "include_business": false
        ]

        let result1 = try await tagTool.processAudioContent(testCase, with: ["audio_context": audioContext1])
        XCTAssertFalse(result1.isEmpty)

        // Test with only business enabled
        let audioContext2 = [
            "include_entities": false,
            "include_technical": false,
            "include_business": true
        ]

        let result2 = try await tagTool.processAudioContent(testCase, with: ["audio_context": audioContext2])
        XCTAssertFalse(result2.isEmpty)
    }

    // MARK: - Tag Category Tests

    func testEquipmentCategoryTags() async throws {
        let testCase = "Used Neumann U87 microphone and SSL console"

        let result = try await tagTool.processAudioContent(testCase, with: [:])
        XCTAssertFalse(result.isEmpty)

        // Should have equipment category tags
        let resultData = result.data(using: .utf8)!
        let json = try JSONSerialization.jsonObject(with: resultData) as! [String: Any]
        let tags = json["tags"] as! [[String: Any]]

        let hasEquipmentCategory = tags.contains { tag in
            (tag["category"] as! String) == "equipment"
        }

        XCTAssertTrue(hasEquipmentCategory, "Should include equipment category tags")
    }

    func testTechnicalCategoryTags() async throws {
        let testCase = "Applied compression and EQ at 24-bit/96kHz"

        let result = try await tagTool.processAudioContent(testCase, with: [:])
        XCTAssertFalse(result.isEmpty)

        // Should have technical category tags
        let resultData = result.data(using: .utf8)!
        let json = try JSONSerialization.jsonObject(with: resultData) as! [String: Any]
        let tags = json["tags"] as! [[String: Any]]

        let hasTechnicalCategory = tags.contains { tag in
            (tag["category"] as! String) == "technical"
        }

        XCTAssertTrue(hasTechnicalCategory, "Should include technical category tags")
    }

    func testWorkflowCategoryTags() async throws {
        let testCase = "Recording and mixing process"

        let result = try await tagTool.processAudioContent(testCase, with: [:])
        XCTAssertFalse(result.isEmpty)

        // Should have workflow category tags
        let resultData = result.data(using: .utf8)!
        let json = try JSONSerialization.jsonObject(with: resultData) as! [String: Any]
        let tags = json["tags"] as! [[String: Any]]

        let hasWorkflowCategory = tags.contains { tag in
            (tag["category"] as! String) == "workflow"
        }

        XCTAssertTrue(hasWorkflowCategory, "Should include workflow category tags")
    }

    // MARK: - Confidence Scoring Tests

    func testHighConfidenceTags() async throws {
        let testCase = "Neumann U87 microphone through API 312 preamp"

        let result = try await tagTool.processAudioContent(testCase, with: [:])
        XCTAssertFalse(result.isEmpty)

        // Should have high confidence for clear entity matches
        let resultData = result.data(using: .utf8)!
        let json = try JSONSerialization.jsonObject(with: resultData) as! [String: Any]
        let averageConfidence = json["metadata"] as! [String: Any]
        let avgConf = averageConfidence["averageConfidence"] as! Double

        XCTAssertGreaterThan(avgConf, 0.7, "Should have high average confidence for clear entities")
    }

    func testVocabularyHighConfidence() async throws {
        let testCase = "Audio production session"
        let vocabulary = ["audio", "production", "session"]

        let result = try await tagTool.processAudioContent(testCase, with: ["vocabulary": vocabulary])
        XCTAssertFalse(result.isEmpty)

        // Vocabulary terms should have very high confidence
        let resultData = result.data(using: .utf8)!
        let json = try JSONSerialization.jsonObject(with: resultData) as! [String: Any]
        let tags = json["tags"] as! [[String: Any]]

        let vocabularyTags = tags.filter { tag in
            (tag["source"] as! String) == "vocabulary"
        }

        for tag in vocabularyTags {
            let confidence = tag["confidence"] as! Double
            XCTAssertGreaterThanOrEqual(confidence, 0.9, "Vocabulary tags should have high confidence")
        }
    }

    // MARK: - Deduplication Tests

    func testTagDeduplication() async throws {
        let testCase = "Neumann U87 microphone and Neumann U87 setup"

        let result = try await tagTool.processAudioContent(testCase, with: [:])
        XCTAssertFalse(result.isEmpty)

        // Should not duplicate "Neumann U87" tag
        let resultData = result.data(using: .utf8)!
        let json = try JSONSerialization.jsonObject(with: resultData) as! [String: Any]
        let tags = json["tags"] as! [[String: Any]]
        let tagTexts = tags.map { $0["text"] as! String }

        let neumannCount = tagTexts.filter { $0.lowercased().contains("neumann u87") }.count
        XCTAssertEqual(neumannCount, 1, "Should deduplicate identical tags")
    }

    func testCaseInsensitiveDeduplication() async throws {
        let testCase = "Pro Tools session and pro tools editing"

        let result = try await tagTool.processAudioContent(testCase, with: [:])
        XCTAssertFalse(result.isEmpty)

        // Should treat "Pro Tools" and "pro tools" as the same tag
        let resultData = result.data(using: .utf8)!
        let json = try JSONSerialization.jsonObject(with: resultData) as! [String: Any]
        let tags = json["tags"] as! [[String: Any]]
        let tagTexts = tags.map { ($0["text"] as! String).lowercased() }

        let proToolsCount = tagTexts.filter { $0.contains("pro tools") }.count
        XCTAssertEqual(proToolsCount, 1, "Should deduplicate case-insensitive tags")
    }

    // MARK: - Performance Tests

    func testPerformanceWithShortInput() async throws {
        let testCase = "Neumann U87"
        let startTime = Date()
        let result = try await tagTool.processAudioContent(testCase, with: [:])
        let executionTime = Date().timeIntervalSince(startTime)

        XCTAssertFalse(result.isEmpty)
        XCTAssertLessThan(executionTime, 0.05, "Short input should process within 50ms")
    }

    func testPerformanceWithMediumInput() async throws {
        let testCase = """
        Recording session setup: Neumann U87 microphone for vocals, SM57 for guitar amp,
        API 312 preamps, SSL console for mixing, Pro Tools for recording at 24-bit/96kHz.
        Client wants warm vocal sound, project deadline is Friday.
        """

        let startTime = Date()
        let result = try await tagTool.processAudioContent(testCase, with: [:])
        let executionTime = Date().timeIntervalSince(startTime)

        XCTAssertFalse(result.isEmpty)
        XCTAssertLessThan(executionTime, 0.1, "Medium input should process within 100ms")
    }

    func testPerformanceWithLongInput() async throws {
        let longInput = String(repeating: "Recording session with Neumann U87, SSL console, Pro Tools, compression, EQ, reverb. ", count: 50)
        let startTime = Date()
        let result = try await tagTool.processAudioContent(longInput, with: [:])
        let executionTime = Date().timeIntervalSince(startTime)

        XCTAssertFalse(result.isEmpty)
        XCTAssertLessThan(executionTime, 0.2, "Long input should process within 200ms")
    }

    // MARK: - Error Handling Tests

    func testEmptyInput() async throws {
        do {
            _ = try await tagTool.processAudioContent("", with: [:])
            XCTFail("Should have thrown an error for empty input")
        } catch {
            XCTAssertTrue(error is AudioProcessingError)
        }
    }

    func testInvalidLimitParameter() async throws {
        let testCase = "Test content"

        // Test with limit exceeding maximum
        let parameters1 = ["limit": 25]
        let result1 = try await tagTool.processAudioContent(testCase, with: parameters1)
        XCTAssertFalse(result1.isEmpty) // Should handle gracefully

        // Test with limit below minimum
        let parameters2 = ["limit": 0]
        let result2 = try await tagTool.processAudioContent(testCase, with: parameters2)
        XCTAssertFalse(result2.isEmpty) // Should handle gracefully
    }

    func testInvalidConfidenceThreshold() async throws {
        let testCase = "Test content"
        let audioContext = ["min_confidence": 1.5] // Invalid: > 1.0

        let result = try await tagTool.processAudioContent(testCase, with: ["audio_context": audioContext])
        XCTAssertFalse(result.isEmpty) // Should handle gracefully
    }

    // MARK: - Integration Tests

    func testEndToEndTagGeneration() async throws {
        let realWorldInput = """
        Recording Session Notes:

        Setup:
        - Vocals: Neumann U87 → API 312 preamp → Universal Audio Apollo
        - Guitar: SM57 → amplifier
        - Bass: DI input

        Technical:
        - DAW: Pro Tools 2024
        - Sample Rate: 96kHz
        - Bit Depth: 24-bit
        - Format: WAV files

        Processing:
        - Compression: LA-2A style on vocals
        - EQ: SSL channel EQ
        - Reverb: Plate reverb on vocals

        Notes:
        Client: Indie Artist Productions
        Genre: Alternative Rock
        Producer: John Smith
        Engineer: Sarah Johnson

        Client feedback: "Want warm, intimate vocal sound with good presence"
        """

        let vocabulary = ["vocal", "intimate", "presence", "warm", "alternative rock"]
        let audioContext = [
            "domain": "recording",
            "document_type": "session_notes",
            "min_confidence": 0.3,
            "limit": 15
        ]

        let parameters: [String: Any] = [
            "vocabulary": vocabulary,
            "audio_context": audioContext
        ]

        let result = try await tagTool.processAudioContent(realWorldInput, with: parameters)

        XCTAssertFalse(result.isEmpty)

        // Verify comprehensive tag generation
        let resultData = result.data(using: .utf8)!
        let json = try JSONSerialization.jsonObject(with: resultData) as! [String: Any]

        let tags = json["tags"] as! [[String: Any]]
        let confidence = json["confidence"] as! [Double]
        let metadata = json["metadata"] as! [String: Any]

        // Should generate multiple tags
        XCTAssertGreaterThan(tags.count, 5, "Should generate multiple tags")
        XCTAssertEqual(tags.count, confidence.count, "Tags and confidence arrays should match")

        // Should have metadata
        XCTAssertNotNil(metadata["processingTime"])
        XCTAssertNotNil(metadata["textLength"])
        XCTAssertNotNil(metadata["totalTags"])
        XCTAssertNotNil(metadata["averageConfidence"])
        XCTAssertEqual(metadata["audioDomain"] as? String, "recording")
        XCTAssertEqual(metadata["vocabularyUsed"] as? Bool, true)

        // Should include multiple categories
        let categories = Set(tags.map { $0["category"] as! String })
        XCTAssertGreaterThan(categories.count, 2, "Should include multiple tag categories")

        // Should have reasonable confidence scores
        let avgConfidence = metadata["averageConfidence"] as! Double
        XCTAssertGreaterThan(avgConfidence, 0.4, "Should have reasonable average confidence")

        // Should include vocabulary terms
        let vocabularyTags = tags.filter { tag in
            (tag["source"] as! String) == "vocabulary"
        }
        XCTAssertGreaterThan(vocabularyTags.count, 0, "Should include vocabulary tags")
    }

    func testMultiDomainTagGeneration() async throws {
        let testCase = "Complete music production workflow from recording to mastering"

        // Test with different domains
        let domains = ["recording", "mixing", "mastering", "general"]

        for domain in domains {
            let audioContext = ["domain": domain]
            let result = try await tagTool.processAudioContent(testCase, with: ["audio_context": audioContext])

            XCTAssertFalse(result.isEmpty)

            let resultData = result.data(using: .utf8)!
            let json = try JSONSerialization.jsonObject(with: resultData) as! [String: Any]
            let metadata = json["metadata"] as! [String: Any]

            XCTAssertEqual(metadata["audioDomain"] as? String, domain, "Should set correct audio domain")
        }
    }

    // MARK: - Real-World Scenario Tests

    func testStudioDocumentationTagGeneration() async throws {
        let studioDocumentation = """
        Studio Equipment List:

        Microphones:
        - Neumann U87 (x2)
        - AKG C414 XLII
        - Shure SM57 (x3)
        - Sennheiser MKH416

        Preamps:
        - API 3124 (4 channels)
        - Focusrite Red 8

        Console:
        - SSL AWS 948 (24 channels)

        DAW:
        - Pro Tools Ultimate
        - Logic Pro X

        Plugins:
        - Waves Bundle
        - UAD Collection
        - Fabfilter Pro Bundle

        Monitoring:
        - Genelec 8040B
        - Yamaha NS-10M
        """

        let result = try await tagTool.processAudioContent(studioDocumentation, with: [
            "limit": 20,
            "audio_context": [
                "domain": "general",
                "document_type": "equipment_list"
            ]
        ])

        XCTAssertFalse(result.isEmpty)

        // Should extract equipment tags
        let resultData = result.data(using: .utf8)!
        let json = try JSONSerialization.jsonObject(with: resultData) as! [String: Any]
        let tags = json["tags"] as! [[String: Any]]

        let equipmentTags = tags.filter { tag in
            (tag["category"] as! String) == "equipment"
        }

        XCTAssertGreaterThan(equipmentTags.count, 5, "Should extract multiple equipment tags")

        // Should include specific brands
        let tagTexts = tags.map { $0["text"] as! String }.joined(separator: " ").lowercased()
        XCTAssertTrue(tagTexts.contains("neumann") || tagTexts.contains("akg") || tagTexts.contains("ssl"))
    }

    func testClientCommunicationTagGeneration() async throws {
        let clientCommunication = """
        Subject: Mix Feedback - Track 3

        Hi John,

        I've reviewed the latest mix and here are my thoughts:

        What I love:
        - Vocal sound is perfect, very warm and intimate
        - Bass has great punch and sits well in the mix
        - Overall balance is excellent

        Areas for improvement:
        - Could use more vocal presence in the chorus
        - Guitars feel a bit harsh around 2kHz
        - Reverb on vocals is too long

        Technical notes:
        - Target loudness: -14 LUFS integrated
        - Format: WAV 24-bit/96kHz
        - Delivery: Friday EOD

        Budget reminder: $1,500 total for mixing and mastering

        Best regards,
        Sarah Thompson
        Indie Artist Productions
        """

        let result = try await tagTool.processAudioContent(clientCommunication, with: [
            "limit": 15,
            "audio_context": [
                "domain": "mixing",
                "document_type": "client_communication",
                "min_confidence": 0.4
            ]
        ])

        XCTAssertFalse(result.isEmpty)

        // Should extract various tag types
        let resultData = result.data(using: .utf8)!
        let json = try JSONSerialization.jsonObject(with: resultData) as! [String: Any]
        let tags = json["tags"] as! [[String: Any]]

        let categories = Set(tags.map { $0["category"] as! String })

        // Should include multiple categories for client communication
        XCTAssertTrue(categories.contains("technical") || categories.contains("business") || categories.contains("quality"))
        XCTAssertTrue(tags.count >= 5, "Should generate multiple tags from detailed feedback")
    }
}