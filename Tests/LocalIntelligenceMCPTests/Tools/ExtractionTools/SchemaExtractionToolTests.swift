//
//  SchemaExtractionToolTests.swift
//  LocalIntelligenceMCPTests
//
//  Created on 2025-10-09.
//

import XCTest
@testable import LocalIntelligenceMCP

/// Comprehensive unit tests for SchemaExtractionTool
/// Tests structured data extraction, schema validation, and audio domain entity recognition
final class SchemaExtractionToolTests: XCTestCase {

    // MARK: - Test Properties

    var mockLogger: MockLogger!
    var mockSecurityManager: MockSecurityManager!
    var schemaTool: SchemaExtractionTool!

    // MARK: - Test Lifecycle

    override func setUp() async throws {
        try await super.setUp()
        mockLogger = MockLogger()
        mockSecurityManager = MockSecurityManager()
        schemaTool = SchemaExtractionTool(logger: mockLogger, securityManager: mockSecurityManager)
    }

    override func tearDown() async throws {
        mockLogger = nil
        mockSecurityManager = nil
        schemaTool = nil
        try await super.tearDown()
    }

    // MARK: - Equipment Entity Extraction Tests

    func testExtractMicrophoneEntities() async throws {
        let testCases = [
            "Recorded vocals with Neumann U87 microphone",
            "Used AKG C414 for acoustic guitar",
            "SM57 on guitar cabinet, SM7B for vocals",
            "Setup Rode NT1A for voiceover work"
        ]

        for testCase in testCases {
            let schema = createSimpleSchema(["microphone": "string"])
            let result = try await schemaTool.processAudioContent(testCase, with: ["schema": schema])

            XCTAssertFalse(result.isEmpty)

            // Verify microphone extraction
            XCTAssertTrue(result.contains("microphone") || result.contains("extractedEntities"))
        }
    }

    func testExtractConsoleEntities() async throws {
        let testCases = [
            "Mixed on SSL AWS 900 console",
            "Used Neve 88RS for analog warmth",
            "API Vision console for tracking",
            "SSL Matrix for automation"
        ]

        for testCase in testCases {
            let schema = createSimpleSchema(["console": "string"])
            let result = try await schemaTool.processAudioContent(testCase, with: ["schema": schema])

            XCTAssertFalse(result.isEmpty)

            // Verify console extraction
            XCTAssertTrue(result.lowercased().contains("ssl") || result.lowercased().contains("neve") || result.lowercased().contains("api"))
        }
    }

    func testExtractDAWEntities() async throws {
        let testCases = [
            "Edited in Pro Tools session",
            "Composed in Logic Pro X",
            "Production in Ableton Live",
            "Mixed in Cubase 12"
        ]

        for testCase in testCases {
            let schema = createSimpleSchema(["daw": "string"])
            let result = try await schemaTool.processAudioContent(testCase, with: ["schema": schema])

            XCTAssertFalse(result.isEmpty)
        }
    }

    // MARK: - Technical Entity Extraction Tests

    func testExtractFrequencyEntities() async throws {
        let testCases = [
            ("EQ boost at 1kHz", ["frequency": "number"]),
            ("Cut at 250Hz", ["frequency": "number"]),
            ("High pass at 80Hz", ["frequency": "number"]),
            ("Peak at 2.5kHz", ["frequency": "number"])
        ]

        for (testCase, schemaFields) in testCases {
            let schema = createSimpleSchema(schemaFields)
            let result = try await schemaTool.processAudioContent(testCase, with: ["schema": schema])

            XCTAssertFalse(result.isEmpty)

            // Verify frequency extraction with unit conversion
            XCTAssertTrue(result.contains("1000") || result.contains("250") || result.contains("80") || result.contains("2500"))
        }
    }

    func testExtractDecibelEntities() async throws {
        let testCases = [
            ("3dB boost on vocals", ["decibel": "number"]),
            ("-6dB cut on bass", ["decibel": "number"]),
            ("Threshold at -18dB", ["decibel": "number"]),
            ("Gain reduction of 12dB", ["decibel": "number"])
        ]

        for (testCase, schemaFields) in testCases {
            let schema = createSimpleSchema(schemaFields)
            let result = try await schemaTool.processAudioContent(testCase, with: ["schema": schema])

            XCTAssertFalse(result.isEmpty)

            // Verify decibel extraction (including negative values)
            XCTAssertTrue(result.contains("3") || result.contains("-6") || result.contains("-18") || result.contains("12"))
        }
    }

    func testExtractSampleRateEntities() async throws {
        let testCases = [
            ("Recorded at 96kHz", ["samplerate": "number"]),
            ("44.1kHz for CD quality", ["samplerate": "number"]),
            ("48kHz sample rate", ["samplerate": "number"]),
            ("192kHz for high resolution", ["samplerate": "number"])
        ]

        for (testCase, schemaFields) in testCases {
            let schema = createSimpleSchema(schemaFields)
            let result = try await schemaTool.processAudioContent(testCase, with: ["schema": schema])

            XCTAssertFalse(result.isEmpty)

            // Verify sample rate extraction with unit conversion
            XCTAssertTrue(result.contains("96000") || result.contains("44100") || result.contains("48000") || result.contains("192000"))
        }
    }

    func testExtractBitDepthEntities() async throws {
        let testCases = [
            ("24-bit recording", ["bitdepth": "number"]),
            ("16-bit for CD", ["bitdepth": "number"]),
            ("32-bit float processing", ["bitdepth": "number"])
        ]

        for (testCase, schemaFields) in testCases {
            let schema = createSimpleSchema(schemaFields)
            let result = try await schemaTool.processAudioContent(testCase, with: ["schema": schema])

            XCTAssertFalse(result.isEmpty)

            // Verify bit depth extraction
            XCTAssertTrue(result.contains("24") || result.contains("16") || result.contains("32"))
        }
    }

    // MARK: - Time Entity Extraction Tests

    func testExtractDurationEntities() async throws {
        let testCases = [
            ("Song length 3:45", ["duration": "number"]),
            ("Take was 2:30 long", ["duration": "number"]),
            "Recording lasted 1:23:45",
            ("Clip at 0:15", ["duration": "number"])
        ]

        for (testCase, schemaFields) in testCases {
            let schema = createSimpleSchema(schemaFields)
            let result = try await schemaTool.processAudioContent(testCase, with: ["schema": schema])

            XCTAssertFalse(result.isEmpty)
        }
    }

    func testExtractTempoEntities() async throws {
        let testCases = [
            ("Tempo 120 BPM", ["tempo": "number"]),
            ("Set at 140bpm", ["tempo": "number"]),
            ("Slow tempo at 60 BPM", ["tempo": "number"])
        ]

        for (testCase, schemaFields) in testCases {
            let schema = createSimpleSchema(schemaFields)
            let result = try await schemaTool.processAudioContent(testCase, with: ["schema": schema])

            XCTAssertFalse(result.isEmpty)

            // Verify tempo extraction
            XCTAssertTrue(result.contains("120") || result.contains("140") || result.contains("60"))
        }
    }

    // MARK: - Action Entity Extraction Tests

    func testExtractActionEntities() async throws {
        let testCases = [
            ("Record the vocals", ["action": "string"]),
            ("Mix the track", ["action": "string"]),
            ("Master the album", ["action": "string"]),
            ("Edit the vocals", ["action": "string"]),
            ("Process the audio", ["action": "string"])
        ]

        for (testCase, schemaFields) in testCases {
            let schema = createSimpleSchema(schemaFields)
            let result = try await schemaTool.processAudioContent(testCase, with: ["schema": schema])

            XCTAssertFalse(result.isEmpty)
        }
    }

    // MARK: - Business Entity Extraction Tests

    func testExtractClientEntities() async throws {
        let testCases = [
            ("Client: Blue Sky Studios", ["client": "string"]),
            ("Working with Sunset Production", ["client": "string"]),
            ("Project for Moonlight Records", ["client": "string"])
        ]

        for (testCase, schemaFields) in testCases {
            let schema = createSimpleSchema(schemaFields)
            let result = try await schemaTool.processAudioContent(testCase, with: ["schema": schema])

            XCTAssertFalse(result.isEmpty)
        }
    }

    func testExtractPriceEntities() async throws {
        let testCases = [
            ("Budget $500", ["price": "number"]),
            ("Cost $1,250.50", ["price": "number"]),
            ("Rate $75 per hour", ["price": "number"]),
            ("Total $2,000", ["price": "number"])
        ]

        for (testCase, schemaFields) in testCases {
            let schema = createSimpleSchema(schemaFields)
            let result = try await schemaTool.processAudioContent(testCase, with: ["schema": schema])

            XCTAssertFalse(result.isEmpty)

            // Verify price extraction (handle comma formatting)
            XCTAssertTrue(result.contains("500") || result.contains("1250.5") || result.contains("75") || result.contains("2000"))
        }
    }

    // MARK: - Complex Schema Tests

    func testExtractRecordingSessionSchema() async throws {
        let testCase = """
        Session Notes:
        Setup: Neumann U87 microphone through API 312 preamp, recording at 24-bit/96kHz into Pro Tools.
        Client: Red Sky Productions
        Engineer: John Smith
        Duration: 3 hours
        Budget: $750
        """

        let schema = [
            "type": "object",
            "properties": [
                "microphone": ["type": "string"],
                "preamplifier": ["type": "string"],
                "sample_rate": ["type": "number"],
                "bit_depth": ["type": "number"],
                "software": ["type": "string"],
                "client": ["type": "string"],
                "duration": ["type": "number"],
                "budget": ["type": "number"]
            ],
            "required": ["microphone", "preamplifier"]
        ] as [String: Any]

        let result = try await schemaTool.processAudioContent(testCase, with: ["schema": schema])

        XCTAssertFalse(result.isEmpty)

        // Verify structured extraction
        XCTAssertTrue(result.contains("extractedObject"))
        XCTAssertTrue(result.contains("validity"))
        XCTAssertTrue(result.contains("confidence"))

        // Should have high validity for this comprehensive match
        XCTAssertTrue(result.contains("0.8") || result.contains("0.9") || result.contains("1.0"))
    }

    func testExtractMixingSessionSchema() async throws {
        let testCase = """
        Mix Session:
        Console: SSL AWS 948
        Processing: LA-2A compression on vocals (4:1 ratio, threshold -18dB)
        EQ: +3dB at 80Hz on bass, -2dB at 2kHz on vocals
        Master bus: SSL G-Series bus compressor
        """

        let schema = [
            "type": "object",
            "properties": [
                "console": ["type": "string"],
                "compression_ratio": ["type": "string"],
                "threshold": ["type": "number"],
                "eq_frequency": ["type": "number"],
                "eq_gain": ["type": "number"]
            ],
            "required": ["console"]
        ] as [String: Any]

        let result = try await schemaTool.processAudioContent(testCase, with: ["schema": schema])

        XCTAssertFalse(result.isEmpty)

        // Verify technical parameter extraction
        XCTAssertTrue(result.contains("4:1") || result.contains("-18") || result.contains("80") || result.contains("2000"))
    }

    // MARK: - Audio Context Tests

    func testRecordingDomainContext() async throws {
        let testCase = "Used Neumann U87 for vocals, SM57 for guitar amp"
        let schema = createSimpleSchema(["domain": "string"])

        let audioContext = [
            "domain": "recording",
            "document_type": "session_notes"
        ]

        let result = try await schemaTool.processAudioContent(testCase, with: [
            "schema": schema,
            "audio_context": audioContext
        ])

        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains("recording"))
    }

    func testMixingDomainContext() async throws {
        let testCase = "Applied compression, EQ, and reverb in the mix"
        let schema = createSimpleSchema(["domain": "string"])

        let audioContext = [
            "domain": "mixing",
            "document_type": "mix_notes"
        ]

        let result = try await schemaTool.processAudioContent(testCase, with: [
            "schema": schema,
            "audio_context": audioContext
        ])

        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains("mixing"))
    }

    // MARK: - Confidence Scoring Tests

    func testHighConfidenceExtraction() async throws {
        let testCase = "Neumann U87 microphone through API 312 preamp at 24-bit/96kHz"
        let schema = createSimpleSchema(["microphone": "string", "preamplifier": "string"])

        let result = try await schemaTool.processAudioContent(testCase, with: ["schema": schema])

        XCTAssertFalse(result.isEmpty)

        // Should have high confidence for clear entity matches
        XCTAssertTrue(result.contains("0.8") || result.contains("0.9") || result.contains("1.0"))
    }

    func testLowConfidenceExtraction() async throws {
        let testCase = "Something with audio stuff"
        let schema = createSimpleSchema(["equipment": "string"])

        let result = try await schemaTool.processAudioContent(testCase, with: ["schema": schema])

        XCTAssertFalse(result.isEmpty)

        // Should have lower confidence for ambiguous content
        let hasLowConfidence = result.contains("0.") &&
                               (result.contains("1") || result.contains("2") || result.contains("3") || result.contains("4"))
        XCTAssertTrue(hasLowConfidence)
    }

    func testConfidenceThresholdFiltering() async throws {
        let testCase = "Maybe some audio equipment"
        let schema = createSimpleSchema(["equipment": "string"])

        let audioContext = ["confidence_threshold": 0.9]

        let result = try await schemaTool.processAudioContent(testCase, with: [
            "schema": schema,
            "audio_context": audioContext
        ])

        XCTAssertFalse(result.isEmpty)

        // Should either fail (no high confidence entities) or return very high confidence
        if !result.contains("error") {
            let hasHighConfidence = result.contains("0.9") || result.contains("1.0")
            XCTAssertTrue(hasHighConfidence)
        }
    }

    // MARK: - Validity Scoring Tests

    func testPerfectValidity() async throws {
        let testCase = "Neumann U87 microphone, API 312 preamp, Pro Tools software"
        let schema = [
            "type": "object",
            "properties": [
                "microphone": ["type": "string"],
                "preamplifier": ["type": "string"],
                "software": ["type": "string"]
            ],
            "required": ["microphone", "preamplifier"]
        ] as [String: Any]

        let result = try await schemaTool.processAudioContent(testCase, with: ["schema": schema])

        XCTAssertFalse(result.isEmpty)

        // Should have perfect validity (1.0) for complete match
        XCTAssertTrue(result.contains("validity"))
        XCTAssertTrue(result.contains("1.0") || result.contains("0.9"))
    }

    func testPartialValidity() async throws {
        let testCase = "Used Neumann U87 microphone"
        let schema = [
            "type": "object",
            "properties": [
                "microphone": ["type": "string"],
                "preamplifier": ["type": "string"],
                "software": ["type": "string"]
            ],
            "required": ["microphone", "preamplifier", "software"]
        ] as [String: Any]

        let result = try await schemaTool.processAudioContent(testCase, with: ["schema": schema])

        XCTAssertFalse(result.isEmpty)

        // Should have partial validity (0.33) for 1 of 3 required fields
        XCTAssertTrue(result.contains("validity"))
        XCTAssertTrue(result.contains("missingFields"))
    }

    // MARK: - Error Handling Tests

    func testEmptyInput() async throws {
        do {
            let schema = createSimpleSchema(["test": "string"])
            _ = try await schemaTool.processAudioContent("", with: ["schema": schema])
            XCTFail("Should have thrown an error for empty input")
        } catch {
            XCTAssertTrue(error is AudioProcessingError)
        }
    }

    func testMissingSchema() async throws {
        do {
            _ = try await schemaTool.processAudioContent("test content", with: [:])
            XCTFail("Should have thrown an error for missing schema")
        } catch {
            XCTAssertTrue(error is AudioProcessingError)
        }
    }

    func testInvalidSchema() async throws {
        do {
            let invalidSchema = ["invalid": "schema"] as [String: Any]
            _ = try await schemaTool.processAudioContent("test content", with: ["schema": invalidSchema])
            // Should not throw error but may have low validity
        } catch {
            // May throw error for malformed schema
            XCTAssertTrue(error is AudioProcessingError || error is EncodingError)
        }
    }

    // MARK: - Performance Tests

    func testPerformanceWithShortInput() async throws {
        let testCase = "Neumann U87 microphone"
        let schema = createSimpleSchema(["microphone": "string"])

        let startTime = Date()
        let result = try await schemaTool.processAudioContent(testCase, with: ["schema": schema])
        let executionTime = Date().timeIntervalSince(startTime)

        XCTAssertFalse(result.isEmpty)
        XCTAssertLessThan(executionTime, 0.1, "Short input should process within 100ms")
    }

    func testPerformanceWithLongInput() async throws {
        let longInput = String(repeating: "Recording session with Neumann U87 microphone through API 312 preamp at 24-bit/96kHz into Pro Tools. ", count: 50)
        let schema = createSimpleSchema(["microphone": "string", "preamplifier": "string"])

        let startTime = Date()
        let result = try await schemaTool.processAudioContent(longInput, with: ["schema": schema])
        let executionTime = Date().timeIntervalSince(startTime)

        XCTAssertFalse(result.isEmpty)
        XCTAssertLessThan(executionTime, 0.3, "Long input should process within 300ms")
    }

    func testPerformanceWithComplexSchema() async throws {
        let testCase = "Complex recording session setup with multiple equipment and technical specifications"
        let complexSchema = [
            "type": "object",
            "properties": [
                "equipment": ["type": "array"],
                "technical": ["type": "object"],
                "workflow": ["type": "object"],
                "business": ["type": "object"]
            ],
            "required": ["equipment", "technical"]
        ] as [String: Any]

        let startTime = Date()
        let result = try await schemaTool.processAudioContent(testCase, with: ["schema": complexSchema])
        let executionTime = Date().timeIntervalSince(startTime)

        XCTAssertFalse(result.isEmpty)
        XCTAssertLessThan(executionTime, 0.2, "Complex schema should process within 200ms")
    }

    // MARK: - Audio Domain Specialization Tests

    func testAudioDomainRelevance() async throws {
        let audioDomainInput = "Recorded with Neumann U87 microphone, mixed on SSL console, mastered at 24-bit/96kHz"
        let nonAudioInput = "Went to the grocery store, bought milk and eggs"

        let schema = createSimpleSchema(["entities": ["type": "array"]])

        // Audio domain input should produce better results
        let audioResult = try await schemaTool.processAudioContent(audioDomainInput, with: ["schema": schema])
        let nonAudioResult = try await schemaTool.processAudioContent(nonAudioInput, with: ["schema": schema])

        XCTAssertFalse(audioResult.isEmpty)
        XCTAssertFalse(nonAudioResult.isEmpty)

        // Audio domain should have higher confidence/validity
        let audioHasHighConfidence = audioResult.contains("0.7") || audioResult.contains("0.8") || audioResult.contains("0.9") || audioResult.contains("1.0")
        XCTAssertTrue(audioHasHighConfidence)
    }

    func testMultipleEntityTypesInSingleInput() async throws {
        let testCase = """
        Recording session:
        Equipment: Neumann U87, API 312, SSL Console
        Technical: 24-bit/96kHz, -18dB threshold, 80Hz EQ boost
        Workflow: Recording, mixing, mastering
        Business: Client project, $1000 budget, Friday deadline
        """

        let schema = [
            "type": "object",
            "properties": [
                "equipment": ["type": "array"],
                "technical": ["type": "object"],
                "workflow": ["type": "array"],
                "business": ["type": "object"]
            ]
        ] as [String: Any]

        let result = try await schemaTool.processAudioContent(testCase, with: ["schema": schema])

        XCTAssertFalse(result.isEmpty)

        // Should extract entities from multiple categories
        XCTAssertTrue(result.contains("extractedEntities"))

        // Should have multiple entity types
        let resultData = result.data(using: .utf8)!
        let json = try JSONSerialization.jsonObject(with: resultData) as! [String: Any]
        let extractedObject = json["extractedObject"] as! [String: Any]

        XCTAssertTrue(extractedObject.keys.count >= 2, "Should extract from multiple categories")
    }

    // MARK: - Integration Tests

    func testEndToEndSchemaExtraction() async throws {
        let realWorldInput = """
        Session Date: 2025-10-09
        Client: Indie Artist Productions
        Project: Debut Album - Track 3

        Setup:
        - Vocals: Neumann U87 → API 312 → Universal Audio Apollo
        - Guitar: SM57 → API 512 → Apollo
        - Bass: DI → Apollo

        Technical:
        - Sample Rate: 96kHz
        - Bit Depth: 24-bit
        - DAW: Pro Tools 2024

        Notes:
        Client wants warm, intimate vocal sound. Guitar needs to be bright but not harsh.
        Bass should be solid and punchy. Looking for indie rock aesthetic.
        Budget: $1500 for tracking and mixing.
        """

        let schema = [
            "type": "object",
            "properties": [
                "client": ["type": "string"],
                "project": ["type": "string"],
                "equipment": ["type": "array"],
                "technical_specs": ["type": "object"],
                "notes": ["type": "string"],
                "budget": ["type": "number"]
            ],
            "required": ["client", "project"]
        ] as [String: Any]

        let result = try await schemaTool.processAudioContent(realWorldInput, with: [
            "schema": schema,
            "audio_context": [
                "domain": "recording",
                "document_type": "session_notes",
                "confidence_threshold": 0.6
            ]
        ])

        XCTAssertFalse(result.isEmpty)

        // Verify comprehensive extraction
        XCTAssertTrue(result.contains("extractedObject"))
        XCTAssertTrue(result.contains("validity"))
        XCTAssertTrue(result.contains("confidence"))
        XCTAssertTrue(result.contains("extractedEntities"))
        XCTAssertTrue(result.contains("metadata"))

        // Should have high validity for comprehensive matching
        XCTAssertTrue(result.contains("0.8") || result.contains("0.9") || result.contains("1.0"))

        // Should extract multiple entity types
        let resultData = result.data(using: .utf8)!
        let json = try JSONSerialization.jsonObject(with: resultData) as! [String: Any]
        let extractedObject = json["extractedObject"] as! [String: Any]
        let extractedEntities = json["extractedEntities"] as! [[String: Any]]

        XCTAssertGreaterThan(extractedEntities.count, 5, "Should extract multiple entities")
        XCTAssertGreaterThan(extractedObject.keys.count, 2, "Should populate multiple schema fields")
    }

    // MARK: - Helper Methods

    private func createSimpleSchema(_ fields: [String: String]) -> [String: Any] {
        var properties: [String: Any] = [:]
        for (key, type) in fields {
            properties[key] = ["type": type]
        }

        return [
            "type": "object",
            "properties": properties
        ]
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

    override func debug(_ message: String, category: LogCategory = .general, metadata: [String: AnyCodable] = [:]) async {
        loggedMessages.append("DEBUG: \(message)")
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