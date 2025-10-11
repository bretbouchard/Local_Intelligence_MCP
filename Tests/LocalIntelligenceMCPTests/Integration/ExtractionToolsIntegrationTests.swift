//
//  ExtractionToolsIntegrationTests.swift
//  LocalIntelligenceMCPTests
//
//  Created on 2025-10-09.
//

import XCTest
@testable import LocalIntelligenceMCP

/// Comprehensive integration tests for extraction tools
/// Tests real-world audio production scenarios with both schema extraction and tag generation
final class ExtractionToolsIntegrationTests: XCTestCase {

    // MARK: - Test Properties

    var mockLogger: MockLogger!
    var mockSecurityManager: MockSecurityManager!
    var schemaTool: SchemaExtractionTool!
    var tagTool: TagGenerationTool!

    // MARK: - Test Lifecycle

    override func setUp() async throws {
        try await super.setUp()
        mockLogger = MockLogger()
        mockSecurityManager = MockSecurityManager()
        schemaTool = SchemaExtractionTool(logger: mockLogger, securityManager: mockSecurityManager)
        tagTool = TagGenerationTool(logger: mockLogger, securityManager: mockSecurityManager)
    }

    override func tearDown() async throws {
        mockLogger = nil
        mockSecurityManager = nil
        schemaTool = nil
        tagTool = nil
        try await super.tearDown()
    }

    // MARK: - Recording Session Integration Tests

    func testCompleteRecordingSessionWorkflow() async throws {
        let sessionNotes = """
        Recording Session - October 9, 2025
        Client: Sunset Sound Productions
        Project: "Urban Dreams" Album - Track 2 "Midnight City"
        Engineer: Michael Chen

        Session Setup:
        - Lead Vocals: Neumann U87 → API 312 preamp → Universal Audio Apollo Channel 1
        - Backing Vocals: AKG C414 → API 512 → Apollo Channel 2
        - Electric Guitar: SM57 → Mesa Boogie Rectifier → API 512 → Apollo Channel 3
        - Bass Guitar: DI → Avalon U5 → Apollo Channel 4
        - Drums: Overhead pair (Neumann KM184) → SSL Alpha VHD → Apollo Channels 5-6

        Technical Settings:
        - Sample Rate: 96kHz
        - Bit Depth: 24-bit
        - DAW: Pro Tools 2024.9
        - Buffer Size: 128 samples
        - Monitoring: Genelec 8040B in stereo

        Recording Notes:
        - Vocal takes: 8 comped to final performance
        - Client wants warm, intimate vocal sound with slight air
        - Guitar needs to cut through mix without being harsh
        - Bass should be solid foundation with punchy attack
        - Drums recorded in large room for natural ambience

        Client Feedback:
        "Love the vocal sound, exactly what I was looking for. The guitar has great tone.
        Can we get more definition in the bass low end? The drum overheads sound amazing."

        Session Duration: 6 hours
        Budget: $1,200
        Next Session: Friday for overdubs and editing
        """

        // Test schema extraction
        let recordingSchema = [
            "type": "object",
            "properties": [
                "client": ["type": "string"],
                "project": ["type": "string"],
                "engineer": ["type": "string"],
                "equipment": ["type": "array"],
                "technical_specs": ["type": "object"],
                "duration": ["type": "number"],
                "budget": ["type": "number"],
                "next_session": ["type": "string"]
            ],
            "required": ["client", "project", "equipment"]
        ] as [String: Any]

        let schemaResult = try await schemaTool.processAudioContent(sessionNotes, with: [
            "schema": recordingSchema,
            "audio_context": [
                "domain": "recording",
                "document_type": "session_notes",
                "confidence_threshold": 0.7
            ]
        ])

        XCTAssertFalse(schemaResult.isEmpty)

        // Test tag generation
        let tagResult = try await tagTool.processAudioContent(sessionNotes, with: [
            "limit": 15,
            "audio_context": [
                "domain": "recording",
                "document_type": "session_notes",
                "min_confidence": 0.4
            ]
        ])

        XCTAssertFalse(tagResult.isEmpty)

        // Verify comprehensive extraction
        let schemaData = schemaResult.data(using: .utf8)!
        let schemaJson = try JSONSerialization.jsonObject(with: schemaData) as! [String: Any]

        let extractedObject = schemaJson["extractedObject"] as! [String: Any]
        let extractedEntities = schemaJson["extractedEntities"] as! [[String: Any]]
        let validity = schemaJson["validity"] as! Double
        let confidence = schemaJson["confidence"] as! Double

        XCTAssertGreaterThan(extractedEntities.count, 10, "Should extract multiple entities")
        XCTAssertGreaterThan(validity, 0.7, "Should have high validity for comprehensive content")
        XCTAssertGreaterThan(confidence, 0.6, "Should have good overall confidence")

        // Verify equipment extraction
        let equipmentEntities = extractedEntities.filter { entity in
            let type = entity["type"] as! String
            return type == "microphone" || type == "preamplifier" || type == "console"
        }
        XCTAssertGreaterThan(equipmentEntities.count, 5, "Should extract multiple equipment entities")

        // Verify tag generation results
        let tagData = tagResult.data(using: .utf8)!
        let tagJson = try JSONSerialization.jsonObject(with: tagData) as! [String: Any]

        let tags = tagJson["tags"] as! [[String: Any]]
        let tagMetadata = tagJson["metadata"] as! [String: Any]

        XCTAssertGreaterThan(tags.count, 8, "Should generate multiple tags")
        XCTAssertEqual(tagMetadata["audioDomain"] as? String, "recording")
        XCTAssertEqual(tagMetadata["vocabularyUsed"] as? Bool, false)

        // Verify tag categories
        let tagCategories = Set(tags.map { $0["category"] as! String })
        XCTAssertTrue(tagCategories.contains("equipment"), "Should include equipment tags")
        XCTAssertTrue(tagCategories.contains("technical"), "Should include technical tags")
        XCTAssertTrue(tagCategories.contains("business"), "Should include business tags")
    }

    // MARK: - Mixing Session Integration Tests

    func testMixingSessionAnalysisWorkflow() async throws {
        let mixingNotes = """
        Mix Session - "Electric Dreams" - Indie Rock Band

        Console Setup: SSL AWS 948 with Total Recall
        DAW: Pro Tools 2024, 48 tracks

        Vocal Mix:
        - Lead Vocal: LA-2A compression (4:1 ratio, -18dB threshold)
        - EQ: +2dB at 3kHz for presence, -1dB at 200Hz to reduce mud
        - Reverb: Lexicon 224XL, 2.2s decay, predelay 45ms
        - Delay: 1/8 note, 25% feedback, filtered at 8kHz

        Instrument Processing:
        - Electric Guitars: Waves CLA-76, -12dB threshold, fast attack
        - Bass: API 550A EQ, +3dB at 80Hz, -2dB at 400Hz
        - Drums: SSL G-Series bus compressor, 2:1 ratio, -20dB threshold

        Automation:
        - Vocal riding completed, +3dB in chorus
        - Guitar automation for dynamic sections
        - Reverb sends automated for buildups

        Master Bus Processing:
        - SSL G-Series bus comp: 1.5:1 ratio, -15dB threshold
        - EQ: +1dB high shelf at 8kHz for air
        - Limiter: Waves L2, -0.3dB ceiling

        Client Feedback:
        "Love the vocal processing! Guitars have great energy.
        Can we get more punch in the kick drum? The overall mix feels a bit dark."

        Processing Notes:
        - Mix referenced on Genelec 8040B and Yamaha NS-10M
        - Check on multiple systems: car, iPhone, studio monitors
        - Target loudness: -12 LUFS integrated for streaming
        - Peak levels: -1.2dBTP maximum
        - Export format: WAV 24-bit/96kHz for mastering
        """

        // Schema for mixing session
        let mixingSchema = [
            "type": "object",
            "properties": [
                "console": ["type": "string"],
                "software": ["type": "string"],
                "processing": ["type": "object"],
                "automation": ["type": "array"],
                "master_bus": ["type": "object"],
                "technical_specs": ["type": "object"],
                "client_feedback": ["type": "string"]
            ],
            "required": ["console", "software"]
        ] as [String: Any]

        let schemaResult = try await schemaTool.processAudioContent(mixingNotes, with: [
            "schema": mixingSchema,
            "audio_context": [
                "domain": "mixing",
                "document_type": "mix_notes",
                "confidence_threshold": 0.6
            ]
        ])

        let tagResult = try await tagTool.processAudioContent(mixingNotes, with: [
            "limit": 20,
            "vocabulary": ["compression", "EQ", "reverb", "automation", "mastering"],
            "audio_context": [
                "domain": "mixing",
                "document_type": "mix_notes",
                "min_confidence": 0.3
            ]
        ])

        XCTAssertFalse(schemaResult.isEmpty)
        XCTAssertFalse(tagResult.isEmpty)

        // Verify mixing-specific extraction
        let schemaData = schemaResult.data(using: .utf8)!
        let schemaJson = try JSONSerialization.jsonObject(with: schemaData) as! [String: Any]
        let extractedEntities = schemaJson["extractedEntities"] as! [[String: Any]]

        // Should extract processing parameters
        let technicalEntities = extractedEntities.filter { entity in
            let type = entity["type"] as! String
            return type == "decibel" || type == "frequency"
        }
        XCTAssertGreaterThan(technicalEntities.count, 3, "Should extract multiple technical parameters")

        // Should extract equipment
        let equipmentEntities = extractedEntities.filter { entity in
            let type = entity["type"] as! String
            return type == "console" || type == "plugin"
        }
        XCTAssertGreaterThan(equipmentEntities.count, 2, "Should extract mixing equipment")

        // Verify tag generation includes processing terms
        let tagData = tagResult.data(using: .utf8)!
        let tagJson = try JSONSerialization.jsonObject(with: tagData) as! [String: Any]
        let tags = tagJson["tags"] as! [[String: Any]]

        let tagTexts = tags.map { $0["text"] as! String }.joined(separator: " ").lowercased()
        XCTAssertTrue(tagTexts.contains("compression") || tagTexts.contains("eq") || tagTexts.contains("reverb"))
        XCTAssertTrue(tagTexts.contains("ssl") || tagTexts.contains("waves") || tagTexts.contains("automation"))
    }

    // MARK: - Mastering Session Integration Tests

    func testMasteringSessionWorkflow() async throws {
        let masteringNotes = """
        Mastering Session - "Summer Vibes" EP - Indie Pop Artist

        Source Files: 5 tracks, all WAV 24-bit/96kHz from mix engineer

        Equipment Chain:
        - DAC: Prism Sound ADA-8XR
        - EQ: Manley Massive Passive
        - Compressor: Fairchild 670 (emulation)
        - Limiter: Weiss DS1-MK3
        - Converter: Prism Sound ADA-8XR back to digital

        Track-by-Track Processing:

        1. "Beach Days" (3:24)
        - Manley EQ: +1.5dB @ 60Hz, -0.8dB @ 250Hz, +1.2dB @ 8kHz
        - Fairchild: 2:1 ratio, -18dB threshold, medium attack
        - Final level: -0.1dBTP, -9.5 LUFS integrated

        2. "Ocean Waves" (4:15)
        - Manley EQ: +2dB @ 40Hz, -1.2dB @ 400Hz, +1.8dB @ 12kHz
        - Fairchild: 1.8:1 ratio, -16dB threshold, slow attack
        - Final level: -0.2dBTP, -10.2 LUFS integrated

        3. "Sunset Drive" (3:48)
        - Manley EQ: +1.8dB @ 80Hz, -0.6dB @ 300Hz, +1.5dB @ 10kHz
        - Fairchild: 2.2:1 ratio, -17dB threshold, fast attack
        - Final level: -0.1dBTP, -11.0 LUFS integrated

        Quality Control:
        - All tracks checked for clipping and distortion
        - Phase correlation verified (>0.8 throughout)
        - Dynamic range preserved (DR10-DR12)
        - Frequency balance consistent across EP

        Delivery Formats:
        - High Resolution: WAV 24-bit/96kHz
        - Streaming: WAV 16-bit/44.1kHz
        - CD: WAV 16-bit/44.1kHz with CD text
        - Vinyl: 24-bit/96kHz for vinyl mastering engineer

        Notes:
        Client requested "warm, analog sound" with "modern clarity"
        All tracks maintain consistent sonic character
        EP flows well with consistent loudness and tonal balance
        """

        let masteringSchema = [
            "type": "object",
            "properties": [
                "equipment": ["type": "array"],
                "processing": ["type": "object"],
                "technical_specs": ["type": "object"],
                "delivery_formats": ["type": "array"],
                "quality_control": ["type": "array"]
            ],
            "required": ["equipment", "processing"]
        ] as [String: Any]

        let schemaResult = try await schemaTool.processAudioContent(masteringNotes, with: [
            "schema": masteringSchema,
            "audio_context": [
                "domain": "mastering",
                "document_type": "mastering_notes",
                "confidence_threshold": 0.7
            ]
        ])

        let tagResult = try await tagTool.processAudioContent(masteringNotes, with: [
            "limit": 18,
            "vocabulary": ["mastering", "EQ", "compression", "limiting", "analog"],
            "audio_context": [
                "domain": "mastering",
                "document_type": "mastering_notes",
                "min_confidence": 0.4
            ]
        ])

        XCTAssertFalse(schemaResult.isEmpty)
        XCTAssertFalse(tagResult.isEmpty)

        // Verify mastering-specific extraction
        let schemaData = schemaResult.data(using: .utf8)!
        let schemaJson = try JSONSerialization.jsonObject(with: schemaData) as! [String: Any]
        let extractedEntities = schemaJson["extractedEntities"] as! [[String: Any]]

        // Should extract technical parameters with high precision
        let parameterEntities = extractedEntities.filter { entity in
            let type = entity["type"] as! String
            return type == "decibel" || type == "frequency"
        }
        XCTAssertGreaterThan(parameterEntities.count, 5, "Should extract precise mastering parameters")

        // Should extract high-end equipment
        let equipmentEntities = extractedEntities.filter { entity in
            let text = (entity["text"] as! String).lowercased()
            return text.contains("manley") || text.contains("fairchild") || text.contains("prism")
        }
        XCTAssertGreaterThan(equipmentEntities.count, 2, "Should extract mastering equipment")

        // Verify tag generation includes mastering terms
        let tagData = tagResult.data(using: .utf8)!
        let tagJson = try JSONSerialization.jsonObject(with: tagData) as! [String: Any]
        let tags = tagJson["tags"] as! [[String: Any]]
        let tagMetadata = tagJson["metadata"] as! [String: Any]

        XCTAssertEqual(tagMetadata["audioDomain"] as? String, "mastering")
        XCTAssertEqual(tagMetadata["vocabularyUsed"] as? Bool, true)
    }

    // MARK: - Live Sound Integration Tests

    func testLiveSoundSetupWorkflow() async throws {
        let liveSoundNotes = """
        Live Sound Setup - "Summer Music Festival" - Main Stage

        Venue: Outdoor amphitheater, 2,000 capacity
        Stage Dimensions: 60' x 40' with cover

        Front of House (FOH) Setup:
        - Console: DiGiCo SD10 at FOH position (150' from stage)
        - EQ: BSS DPR-901II (31-band graphic) on main L/R
        - Dynamics: dbx 166XL on subgroups
        - Processing: TC Electronic M3000 reverb, Sennheiser e906 drum mics

        Monitor Setup:
        - Console: Yamaha CL1 at stage left
        - Monitors: 6 x Shure PSM1000 in-ear systems
        - 2 x QSC K12.2 floor wedges for drummers
        - Shure P6T personal monitor transmitters

        Microphone Inventory:
        - Vocals: 4 x Shure SM58, 2 x Sennheiser e945
        - Drums: Sennheiser e904 kick, e906 toms, e902 overheads
        - Instruments: 2 x Sennheiser e906 guitar amps, AKG D112 bass
        - Ambient: 2 x Neumann KM184 for crowd/ambience

        Speaker System:
        - Main L/R: 4 x QSC Wideline 10 per side
        - Subwoofers: 8 x QSC KS118 per side
        - Delay towers: 2 x QSC K12.2 per side
        - Fill speakers: 6 x QSC K8.2 for front fill

        Technical Settings:
        - Sample Rate: 48kHz (digital console)
        - Gain Structure: +18dBu nominal at consoles
        - SPL Limits: 102dB(A) average, 110dB(A) peak
        - System Delay: 25ms total (digital processing path)

        Weather Considerations:
        - Rain cover for all electronics
        - Wind screens on all microphones
        - Cable management with waterproof covers

        Notes:
        - Check RF coordination with 8 wireless frequencies
        - Ground loop isolation on all power connections
        - Backup power: 2 x Honda EU7000 generators
        """

        let liveSoundSchema = [
            "type": "object",
            "properties": [
                "venue": ["type": "string"],
                "foh_equipment": ["type": "array"],
                "monitor_equipment": ["type": "array"],
                "microphones": ["type": "array"],
                "speaker_system": ["type": "array"],
                "technical_settings": ["type": "object"],
                "weather_protection": ["type": "array"]
            ],
            "required": ["venue", "foh_equipment", "microphones"]
        ] as [String: Any]

        let schemaResult = try await schemaTool.processAudioContent(liveSoundNotes, with: [
            "schema": liveSoundSchema,
            "audio_context": [
                "domain": "live_sound",
                "document_type": "technical_rider",
                "confidence_threshold": 0.6
            ]
        ])

        let tagResult = try await tagTool.processAudioContent(liveSoundNotes, with: [
            "limit": 20,
            "audio_context": [
                "domain": "live_sound",
                "document_type": "technical_rider",
                "min_confidence": 0.3
            ]
        ])

        XCTAssertFalse(schemaResult.isEmpty)
        XCTAssertFalse(tagResult.isEmpty)

        // Verify live sound specific extraction
        let schemaData = schemaResult.data(using: .utf8)!
        let schemaJson = try JSONSerialization.jsonObject(with: schemaData) as! [String: Any]
        let extractedObject = schemaJson["extractedObject"] as! [String: Any]

        // Should extract venue information
        XCTAssertTrue(extractedObject.keys.contains("venue") || schemaResult.lowercased().contains("outdoor"))

        // Verify tag generation includes live sound terms
        let tagData = tagResult.data(using: .utf8)!
        let tagJson = try JSONSerialization.jsonObject(with: tagData) as! [String: Any]
        let tags = tagJson["tags"] as! [[String: Any]]

        let tagTexts = tags.map { $0["text"] as! String }.joined(separator: " ").lowercased()
        XCTAssertTrue(tagTexts.contains("live") || tagTexts.contains("foh") || tagTexts.contains("monitor"))
    }

    // MARK: - Equipment Catalog Integration Tests

    func testEquipmentCatalogProcessing() async throws {
        let equipmentCatalog = """
        Professional Audio Equipment Catalog - 2025 Collection

        Microphones:

        Neumann U87 Ai Studio Set
        - Price: $3,199
        - Pattern: Cardioid, Figure-8, Omnidirectional
        - Frequency Response: 20Hz - 20kHz
        - Applications: Studio vocals, overheads, acoustic instruments
        - Includes: Shock mount, wooden case, power supply

        AKG C414 XLII Stereo Pair
        - Price: $1,099
        - Patterns: 9 selectable polar patterns
        - Frequency Response: 20Hz - 20kHz
        - Applications: Studio recording, broadcast, location sound
        - Includes: Stereo shock mount, road case

        Shure SM7B Vocal Microphone
        - Price: $399
        - Pattern: Cardioid
        - Frequency Response: 50Hz - 20kHz
        - Applications: Broadcast, vocals, instruments
        - Includes: Windscreen, shock mount

        Preamplifiers:

        API 3124+ Four-Channel Preamp
        - Price: $2,899
        - Type: Discrete, transformer-based
        - Gain: +65dB maximum
        - Applications: Recording, broadcast
        - Features: Front panel inputs, meter bridge

        Universal Audio 4-710d
        - Price: $1,999
        - Type: Hybrid tube/solid-state
        - Gain: +70dB maximum
        - Applications: Studio recording, tracking
        - Features: 4 channels, digital output, tone blending

        Consoles:

        SSL AWS 948 Delta
        - Price: $125,000
        - Channels: 24
        - Automation: Total Recall VCA
        - Applications: Professional recording, mixing
        - Features: SuperAnalog processing, DAW control

        Focusrite Red 8Pre
        - Price: $2,499
        - Channels: 8
        - Type: Desktop/19" rack mountable
        - Applications: Project studio, location recording
        - Features: Thunderbolt/USB connectivity, remote control
        """

        let catalogSchema = [
            "type": "object",
            "properties": [
                "equipment_categories": ["type": "array"],
                "products": ["type": "array"],
                "price_ranges": ["type": "object"],
                "technical_specs": ["type": "object"]
            ],
            "required": ["equipment_categories", "products"]
        ] as [String: Any]

        let schemaResult = try await schemaTool.processAudioContent(equipmentCatalog, with: [
            "schema": catalogSchema,
            "audio_context": [
                "domain": "general",
                "document_type": "equipment_catalog",
                "confidence_threshold": 0.8
            ]
        ])

        let tagResult = try await tagTool.processAudioContent(equipmentCatalog, with: [
            "limit": 25,
            "vocabulary": ["microphone", "preamp", "console", "price", "studio"],
            "audio_context": [
                "domain": "general",
                "document_type": "equipment_catalog",
                "min_confidence": 0.5
            ]
        ])

        XCTAssertFalse(schemaResult.isEmpty)
        XCTAssertFalse(tagResult.isEmpty)

        // Should extract multiple product information
        let schemaData = schemaResult.data(using: .utf8)!
        let schemaJson = try JSONSerialization.jsonObject(with: schemaData) as! [String: Any]
        let extractedEntities = schemaJson["extractedEntities"] as! [[String: Any]]

        // Should extract price information
        let priceEntities = extractedEntities.filter { entity in
            entity["type"] as! String == "price"
        }
        XCTAssertGreaterThan(priceEntities.count, 3, "Should extract multiple price points")

        // Should extract brand information
        let resultText = schemaResult.lowercased()
        XCTAssertTrue(resultText.contains("neumann") || resultText.contains("akg") || resultText.contains("shure") || resultText.contains("ssl"))

        // Verify comprehensive tag generation
        let tagData = tagResult.data(using: .utf8)!
        let tagJson = try JSONSerialization.jsonObject(with: tagData) as! [String: Any]
        let tags = tagJson["tags"] as! [[String: Any]]
        let tagMetadata = tagJson["metadata"] as! [String: Any]

        XCTAssertEqual(tagMetadata["vocabularyUsed"] as? Bool, true)
        XCTAssertGreaterThan(tags.count, 10, "Should generate comprehensive tags from catalog")
    }

    // MARK: - Client Communication Integration Tests

    func testClientCommunicationAnalysis() async throws {
        let clientEmail = """
        Subject: Mix Feedback and Revisions Needed

        Hi John,

        Hope you're having a good week. I've had a chance to listen through the latest mixes
        for the "Urban Dreams" album, and I wanted to share my thoughts.

        Overall Impressions:
        The production quality is excellent, and I can hear all the hard work you've put in.
        The vocal sound is fantastic - exactly the warm, intimate quality we discussed.
        Great work on the bass too, it really anchors the tracks well.

        Specific Track Feedback:

        Track 1 - "Midnight City":
        • Lead vocal is perfect, don't change anything
        • Could the electric guitar be a bit brighter in the chorus? It feels a little dark
        • The drums sound great, but maybe a bit more room mic for ambience

        Track 2 - "Neon Lights":
        • Love the compression on the vocals
        • The bass could use more low-end presence around 60Hz
        • Synth pads feel a bit loud in the second verse

        Track 3 - "Downtown Dreams":
        • This one is really close to perfect
        • Maybe just a touch more high-end air on the vocals
        • The reverb tail on the last word feels a bit long

        Technical Notes:
        - We'll need these for vinyl mastering, so please avoid digital clipping
        - Target level around -14 LUFS for streaming would be great
        - Please keep the 24-bit files for archival
        - Can you also create 16-bit versions for CD?

        Timeline:
        I need to deliver these to the mastering engineer by Friday, October 15th.
        Is that realistic for these revisions?

        Budget:
        We have $800 remaining in the mixing budget. Will these changes fit within that?

        Let me know your thoughts on these notes. Really excited to hear the final versions!

        Best regards,
        Sarah Thompson
        Producer
        Sunset Sound Productions
        (555) 123-4567
        """

        let communicationSchema = [
            "type": "object",
            "properties": [
                "sender": ["type": "string"],
                "company": ["type": "string"],
                "feedback_type": ["type": "string"],
                "specific_tracks": ["type": "array"],
                "technical_requirements": ["type": "array"],
                "deadline": ["type": "string"],
                "budget": ["type": "number"],
                "contact": ["type": "string"]
            ],
            "required": ["sender", "feedback_type"]
        ] as [String: Any]

        let schemaResult = try await schemaTool.processAudioContent(clientEmail, with: [
            "schema": communicationSchema,
            "audio_context": [
                "domain": "mixing",
                "document_type": "client_communication",
                "confidence_threshold": 0.6
            ]
        ])

        let tagResult = try await tagTool.processAudioContent(clientEmail, with: [
            "limit": 15,
            "vocabulary": ["feedback", "revision", "deadline", "budget", "mastering"],
            "audio_context": [
                "domain": "mixing",
                "document_type": "client_communication",
                "min_confidence": 0.3
            ]
        ])

        XCTAssertFalse(schemaResult.isEmpty)
        XCTAssertFalse(tagResult.isEmpty)

        // Should extract contact information
        let schemaData = schemaResult.data(using: .utf8)!
        let schemaJson = try JSONSerialization.jsonObject(with: schemaData) as! [String: Any]
        let extractedObject = schemaJson["extractedObject"] as! [String: Any]

        // Should extract business information
        let resultText = schemaResult.lowercased()
        XCTAssertTrue(resultText.contains("sarah") || resultText.contains("sunset") || resultText.contains("producer"))

        // Verify tag generation captures communication context
        let tagData = tagResult.data(using: .utf8)!
        let tagJson = try JSONSerialization.jsonObject(with: tagData) as! [String: Any]
        let tags = tagJson["tags"] as! [[String: Any]]

        let tagTexts = tags.map { $0["text"] as! String }.joined(separator: " ").lowercased()
        XCTAssertTrue(tagTexts.contains("feedback") || tagTexts.contains("revision") || tagTexts.contains("deadline"))
        XCTAssertTrue(tagTexts.contains("mixing") || tagTexts.contains("production") || tagTexts.contains("vocal"))
    }

    // MARK: - Performance Integration Tests

    func testPerformanceWithRealWorldContent() async throws {
        let complexContent = String(repeating: """
        Professional recording session setup with Neumann U87, AKG C414, SSL AWS console,
        Pro Tools 2024, 24-bit/96kHz recording, LA-2A compression, SSL EQ processing,
        client feedback and budget considerations for mixing and mastering workflow.
        """, count: 20)

        let startTime = Date()

        // Test schema extraction performance
        let performanceSchema = [
            "type": "object",
            "properties": [
                "equipment": ["type": "array"],
                "technical": ["type": "object"],
                "workflow": ["type": "array"]
            ]
        ] as [String: Any]

        let schemaResult = try await schemaTool.processAudioContent(complexContent, with: [
            "schema": performanceSchema
        ])
        let schemaTime = Date().timeIntervalSince(startTime)

        XCTAssertFalse(schemaResult.isEmpty)
        XCTAssertLessThan(schemaTime, 0.5, "Schema extraction should complete within 500ms for large content")

        // Test tag generation performance
        let tagStartTime = Date()
        let tagResult = try await tagTool.processAudioContent(complexContent, with: [
            "limit": 20,
            "audio_context": ["min_confidence": 0.2]
        ])
        let tagTime = Date().timeIntervalSince(tagStartTime)

        XCTAssertFalse(tagResult.isEmpty)
        XCTAssertLessThan(tagTime, 0.3, "Tag generation should complete within 300ms for large content")
    }

    // MARK: - Sequential Processing Integration Tests

    func testSequentialExtractionWorkflow() async throws {
        let sessionContent = """
        Recording session: Neumann U87 vocals through API 312 preamp at 24-bit/96kHz in Pro Tools.
        Client wants warm sound for indie rock project. Budget $1,500, deadline Friday.
        """

        // First, extract structured data
        let schema = [
            "type": "object",
            "properties": [
                "equipment": ["type": "array"],
                "technical_specs": ["type": "object"],
                "project_info": ["type": "object"]
            ]
        ] as [String: Any]

        let schemaResult = try await schemaTool.processAudioContent(sessionContent, with: [
            "schema": schema,
            "audio_context": [
                "domain": "recording",
                "confidence_threshold": 0.6
            ]
        ])

        // Then, generate tags using the extracted entities as vocabulary
        let schemaData = schemaResult.data(using: .utf8)!
        let schemaJson = try JSONSerialization.jsonObject(with: schemaData) as! [String: Any]
        let extractedEntities = schemaJson["extractedEntities"] as! [[String: Any]]

        let vocabulary = extractedEntities.compactMap { entity -> String? in
            let text = entity["text"] as? String
            let confidence = entity["confidence"] as? Double
            return confidence ?? 0 > 0.7 ? text : nil
        }

        let tagResult = try await tagTool.processAudioContent(sessionContent, with: [
            "vocabulary": vocabulary,
            "limit": 10,
            "audio_context": [
                "domain": "recording",
                "min_confidence": 0.4
            ]
        ])

        XCTAssertFalse(schemaResult.isEmpty)
        XCTAssertFalse(tagResult.isEmpty)

        // Should have improved tag generation with vocabulary from schema extraction
        let tagData = tagResult.data(using: .utf8)!
        let tagJson = try JSONSerialization.jsonObject(with: tagData) as! [String: Any]
        let tagMetadata = tagJson["metadata"] as! [String: Any]

        XCTAssertEqual(tagMetadata["vocabularyUsed"] as? Bool, true)
    }

    // MARK: - Cross-Domain Integration Tests

    func testCrossDomainContentProcessing() async throws {
        let crossDomainContent = """
        Project started with recording vocals using Neumann U87, then moved to mixing on SSL console,
        and finally completed with analog mastering using Manley Massive Passive EQ and Fairchild compression.
        """

        // Test with different domains
        let domains = ["recording", "mixing", "mastering", "general"]
        var results: [String: String] = [:]

        for domain in domains {
            let schema = [
                "type": "object",
                "properties": [
                    "domain": ["type": "string"],
                    "equipment": ["type": "array"]
                ]
            ] as [String: Any]

            let schemaResult = try await schemaTool.processAudioContent(crossDomainContent, with: [
                "schema": schema,
                "audio_context": ["domain": domain]
            ])

            let tagResult = try await tagTool.processAudioContent(crossDomainContent, with: [
                "audio_context": ["domain": domain]
            ])

            results[domain] = "Schema: \(schemaResult.count), Tags: \(tagResult.count)"
        }

        // Each domain should produce results but with different focus
        XCTAssertEqual(results.count, 4)
        for (domain, result) in results {
            XCTAssertFalse(result.isEmpty, "\(domain) domain should produce results")
        }
    }
}

// MARK: - Mock Classes (shared from other test files)

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