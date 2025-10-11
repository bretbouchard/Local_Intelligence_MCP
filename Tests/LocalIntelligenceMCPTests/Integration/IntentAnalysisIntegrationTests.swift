//
//  IntentAnalysisIntegrationTests.swift
//  LocalIntelligenceMCPTests
//
//  Created on 2025-10-09.
//

import XCTest
@testable import LocalIntelligenceMCP

/// Integration tests for Intent Analysis Tools
/// Tests end-to-end workflows with real-world audio domain scenarios
final class IntentAnalysisIntegrationTests: XCTestCase {

    // MARK: - Test Properties

    var mockLogger: MockLogger!
    var mockSecurityManager: MockSecurityManager!
    var intentRecognitionTool: IntentRecognitionTool!
    var queryAnalysisTool: QueryAnalysisTool!
    var contentPurposeDetector: ContentPurposeDetector!
    var classificationModels: AudioIntentClassificationModels!

    // MARK: - Test Lifecycle

    override func setUp() async throws {
        try await super.setUp()
        mockLogger = MockLogger()
        mockSecurityManager = MockSecurityManager()

        intentRecognitionTool = IntentRecognitionTool(logger: mockLogger, securityManager: mockSecurityManager)
        queryAnalysisTool = QueryAnalysisTool(logger: mockLogger, securityManager: mockSecurityManager)
        contentPurposeDetector = ContentPurposeDetector(logger: mockLogger, securityManager: mockSecurityManager)
        classificationModels = AudioIntentClassificationModels()
    }

    override func tearDown() async throws {
        mockLogger = nil
        mockSecurityManager = nil
        intentRecognitionTool = nil
        queryAnalysisTool = nil
        contentPurposeDetector = nil
        classificationModels = nil
        try await super.tearDown()
    }

    // MARK: - End-to-End Workflow Tests

    func testCompleteRecordingSessionWorkflow() async throws {
        let sessionContent = """
        Session Notes: Today we recorded lead vocals for the rock album track "Highway Blues".
        Setup: Neumann U87 microphone through API 312 preamp, positioned 8 inches from singer.
        SSL G+ console used with analog summing. Pro Tools HD session at 96kHz/24-bit.

        Client (Sarah) was present and very engaged in the process. We recorded 8 takes total,
        with take 5 selected as the primary performance. Client loved the emotional delivery
        and technical performance of take 5. Applied gentle EQ boost at 2kHz for presence
        and used LA-2A compression for subtle dynamic control.

        Technical settings: Preamp gain at 35dB, phantom power 48V engaged. Recording levels
        peaked at -12dB to avoid clipping while maintaining good signal-to-noise ratio.
        Used Avalon VT-737sp for vocal channel strip processing, adding tube warmth.

        Client feedback: "This is exactly what I was looking for! The energy is perfect and
        the technical quality is outstanding. Can we add some subtle reverb for space?"

        Next steps: Mix session scheduled for Tuesday at 2pm. Client wants to add backing
        vocals and acoustic guitar. Budget remaining: $2,000 for additional production.

        Decision needed: Should we hire background vocalists or have Sarah do harmonies?
        Client deadline for rough mix: Friday 5pm.
        """

        // Step 1: Content Purpose Analysis
        let contentResult = try await contentPurposeDetector.processAudioContent(sessionContent, with: [
            "content_hint": "session_notes",
            "analysis_depth": "comprehensive",
            "include_business_context": true,
            "include_urgency_assessment": true
        ])

        XCTAssertFalse(contentResult.isEmpty)
        XCTAssertTrue(contentResult.contains("session_notes"))
        XCTAssertTrue(contentResult.contains("informative"))
        XCTAssertTrue(contentResult.contains("scheduled_action"))
        XCTAssertTrue(contentResult.contains("client"))
        XCTAssertTrue(contentResult.contains("commercial"))

        // Step 2: Query Analysis for client communication
        let clientQuery = "What microphone should I use for recording rock vocals under $1000?"
        let queryResult = try await queryAnalysisTool.processAudioContent(clientQuery, with: [
            "context": [
                "expertise": "intermediate",
                "budget": "under $1000",
                "project_type": "music_production"
            ],
            "analysis_depth": "standard",
            "response_guidance": true
        ])

        XCTAssertFalse(queryResult.isEmpty)
        XCTAssertTrue(queryResult.contains("recommendation"))
        XCTAssertTrue(queryResult.contains("intermediate"))
        XCTAssertTrue(queryResult.contains("response_guidance"))

        // Step 3: Intent Recognition for action items
        let actionCommand = "Schedule mix session for Tuesday at 2pm with SSL console"
        let intentResult = try await intentRecognitionTool.processAudioContent(actionCommand, with: [
            "extract_context": true,
            "include_alternatives": false
        ])

        XCTAssertFalse(intentResult.isEmpty)
        // Should recognize as scheduling/planning intent
        XCTAssertTrue(intentResult.contains("confidence"))
        XCTAssertTrue(intentResult.contains("audio_context"))

        // Verify workflow integration
        let allResults = [contentResult, queryResult, intentResult]
        for result in allResults {
            XCTAssertFalse(result.isEmpty)
        }

        // Verify cross-tool consistency
        // Content should identify recording context, query should recommend equipment,
        // intent should recognize scheduling action
        XCTAssertTrue(contentResult.contains("recording") || contentResult.contains("mixing"))
        XCTAssertTrue(queryResult.contains("microphone"))
    }

    func testStudioClientCommunicationScenario() async throws {
        let clientEmail = """
        Hi Team,

        I've just reviewed the latest mix of "Midnight Dreams" and I wanted to share my thoughts.

        Overall, I'm really happy with the direction! The energy is great and the balance
        is much better than the previous version. The vocals are sitting perfectly in the mix
        now, and the drums have that punch I was looking for.

        I have a few specific requests:
        1. Could we add a bit more presence to the lead vocals? Maybe a small EQ boost around 3kHz?
        2. The bass could be a little more prominent in the chorus sections.
        3. I'd love to hear some subtle reverb on the vocals to give them more space.

        I know we're getting close to the deadline, but these changes are important for the
        final sound. Could we have the updated mix by Thursday at the latest? The label needs
        it for Friday morning.

        Budget-wise, we still have $800 remaining for any additional production work if needed.

        Thanks for all your hard work on this!
        Best regards,
        Jessica Chen
        A&R Manager, Sonic Wave Records
        """

        // Step 1: Content Purpose Analysis
        let contentResult = try await contentPurposeDetector.processAudioContent(clientEmail, with: [
            "content_hint": "client_communication",
            "context": [
                "author_role": "client",
                "business_context": [
                    "commercial_nature": "commercial",
                    "client_involvement": "high"
                ]
            ],
            "analysis_depth": "comprehensive",
            "include_sentiment_analysis": true,
            "include_urgency_assessment": true
        ])

        XCTAssertFalse(contentResult.isEmpty)
        XCTAssertTrue(contentResult.contains("client_communication"))
        XCTAssertTrue(contentResult.contains("communication"))
        XCTAssertTrue(contentResult.contains("decision_making"))
        XCTAssertTrue(contentResult.contains("scheduled_action"))
        XCTAssertTrue(contentResult.contains("positive")) // Positive sentiment

        // Step 2: Extract action items using query analysis
        let actionQuery = "What specific tasks need to be completed based on client feedback?"
        let queryResult = try await queryAnalysisTool.processAudioContent(actionQuery, with: [
            "analysis_depth": "standard",
            "response_guidance": true
        ])

        XCTAssertFalse(queryResult.isEmpty)
        XCTAssertTrue(queryResult.contains("procedural"))

        // Step 3: Intent Recognition for technical actions
        let technicalCommands = [
            "Apply EQ boost at 3kHz to lead vocals",
            "Increase bass level in chorus sections",
            "Add subtle reverb to vocal track"
        ]

        for command in technicalCommands {
            let intentResult = try await intentRecognitionTool.processAudioContent(command, with: [
                "extract_context": true
            ])
            XCTAssertFalse(intentResult.isEmpty)
            XCTAssertTrue(intentResult.contains("confidence"))
        }

        // Verify integration consistency
        XCTAssertTrue(contentResult.contains("urgency")) // Thursday deadline
        XCTAssertTrue(contentResult.contains("commercial")) // Label project
        XCTAssertTrue(contentResult.contains("budget_mentions")) // $800 remaining
    }

    func testTechnicalTroubleshootingWorkflow() async throws {
        let troubleshootingLog = """
        PROBLEM REPORT: Studio monitoring system issues

        Date: October 9, 2025
        Engineer: Mark Thompson
        Client: Independent musician

        Issue Description:
        Client reports that the studio monitors are producing a humming/buzzing sound
        that wasn't present during the previous session. The issue is most noticeable
        during quiet passages and when the main mix bus is inactive.

        Technical Investigation:
        1. Checked all cable connections - secure and properly seated
        2. Verified power connections - all grounded properly
        3. Tested with different audio sources - issue persists
        4. Measured with SPL meter - hum is at approximately 45dB in quiet room

        Equipment Chain:
        - Pro Tools HD 12.8
        - Antelope Audio Orion 32 HD Interface
        - Genelec 8030A monitors (active)
        - Mogami balanced XLR cables
        - Power conditioner: Furman PL-Plus C

        Root Cause Analysis:
        After extensive testing, identified that the issue occurs when the interface
        and monitors are connected to different power circuits. The ground potential
        difference is creating a ground loop hum at 60Hz.

        Solution Applied:
        1. Connected both interface and monitors to the same power circuit
        2. Added Ebtech Hum X ground loop isolator
        3. Verified with frequency analyzer - 60Hz hum eliminated

        Client Feedback:
        "Perfect! The hum is completely gone now. The monitoring sounds crystal clear.
        Thank you for quickly identifying and fixing the issue!"

        Follow-up Required:
        - Document solution for future reference
        - Consider upgrading to balanced power distribution
        - Schedule regular maintenance check
        """

        // Step 1: Content Purpose Analysis
        let contentResult = try await contentPurposeDetector.processAudioContent(troubleshootingLog, with: [
            "content_hint": "troubleshooting",
            "analysis_depth": "comprehensive",
            "include_quality_assessment": true,
            "include_technical_complexity": true
        ])

        XCTAssertFalse(contentResult.isEmpty)
        XCTAssertTrue(contentResult.contains("troubleshooting"))
        XCTAssertTrue(contentResult.contains("technical_log"))
        XCTAssertTrue(contentResult.contains("instructional")) // Solution documentation
        XCTAssertTrue(contentResult.contains("advanced")) // Technical complexity

        // Step 2: Safety Assessment
        let safetyQuery = "Is electrical ground loop dangerous for equipment or personnel?"
        let safetyResult = try await queryAnalysisTool.processAudioContent(safetyQuery, with: [
            "include_safety": true,
            "analysis_depth": "standard"
        ])

        XCTAssertFalse(safetyResult.isEmpty)
        XCTAssertTrue(safetyResult.contains("safety"))
        if safetyResult.contains("safety_assessment") {
            XCTAssertTrue(safetyResult.contains("electrical_safety"))
        }

        // Step 3: Intent Recognition for preventive actions
        let preventiveActions = [
            "Schedule regular maintenance check",
            "Document solution in knowledge base",
            "Upgrade power distribution system"
        ]

        for action in preventiveActions {
            let intentResult = try await intentRecognitionTool.processAudioContent(action, with: [
                "extract_context": true
            ])
            XCTAssertFalse(intentResult.isEmpty)
        }

        // Verify technical complexity extraction
        if contentResult.contains("technical_complexity") {
            XCTAssertTrue(contentResult.contains("professional") || contentResult.contains("expert"))
        }

        // Verify equipment extraction
        XCTAssertTrue(contentResult.contains("Pro Tools") || contentResult.contains("Genelec"))
    }

    func testMultiTrackRecordingSessionWorkflow() async throws {
        let recordingSessionNotes = """
        MULTI-TRACK RECORDING SESSION: "Summer Breeze" - Indie Folk Album

        Date: October 9, 2025
        Producer: Lisa Chen
        Engineer: Tom Rodriguez
        Studio: Sunset Sound Studios

        Session Overview:
        Full band recording session for 5 songs. Total of 24 tracks recorded across
        8 hours. Budget: $3,500 for session time.

        Track-by-Track Details:

        1. Lead Vocals (Track 1-3)
        - Microphone: Neumann U87 (primary), Shure SM7B (secondary)
        - Preamp: API 3124
        - Position: 8 inches from source, slight downward angle
        - Takes: 6 takes per song, selected best performances
        - Client feedback: "Love the warmth from the U87, SM7B adds nice edge"

        2. Acoustic Guitar (Track 4-6)
        - Microphone: AKG C414 (stereo pair)
        - Preamp: Focusrite ISA 428
        - Pattern: Cardioid, 12 inches apart
        - Additional: Room mic (Royer R121) for ambient sound

        3. Electric Guitar (Track 7-10)
        - Amplifier: Fender Twin Reverb (vintage)
        - Microphone: Shure SM57 on speaker, Sennheiser e906 for room
        - Effects: Tube screamer, delay, reverb

        4. Bass Guitar (Track 11-12)
        - Direct Input: Radial J48
        - Additional: Amp mic (Ampeg SVT with AKG D112)
        - Blended 60% DI / 40% amp

        5. Drums (Track 13-24)
        - Overheads: Neumann KM184 (stereo)
        - Kick: Shure Beta 52A inside, AKG D112 outside
        - Snare: Shure SM57 on top, Sennheiser e602 underneath
        - Toms: Sennheiser e604 (4 toms)
        - Room: Coles 4038 (mono)

        Technical Settings:
        - Sample Rate: 96kHz
        - Bit Depth: 24-bit
        - Interface: Antelope Audio Orion 32 HD
        - DAW: Pro Tools HD 12.8
        - Monitoring: Dynaudio BM15A

        Client Reactions:
        "The drum sounds are incredible! Exactly the vintage vibe we wanted."
        "Love the acoustic guitar tone - very rich and full."
        "Vocals are perfect, can't wait to hear them in the mix."

        Business Context:
        This is a commercial album project with Sonic Wave Records.
        Total budget: $25,000 (including mixing and mastering).
        Timeline: Mix by end of month, mastering by mid-November.

        Next Session:
        Saturday: Overdubs and additional instruments
        Timeline: 10am - 6pm
        Budget remaining: $8,000

        Decision Points:
        - Should we add strings to chorus sections? (Additional cost: $1,500)
        - Do we need additional vocal comping? (Time vs budget consideration)
        - Vintage compressor rental vs. plugin emulation? (Sound quality vs cost)
        """

        // Step 1: Comprehensive Content Analysis
        let contentResult = try await contentPurposeDetector.processAudioContent(recordingSessionNotes, with: [
            "content_hint": "session_notes",
            "context": [
                "author_role": "engineer",
                "project_type": "music_production",
                "workflow_stage": "recording"
            ],
            "analysis_depth": "comprehensive",
            "include_business_context": true,
            "include_quality_assessment": true
        ])

        XCTAssertFalse(contentResult.isEmpty)
        XCTAssertTrue(contentResult.contains("session_notes"))
        XCTAssertTrue(contentResult.contains("informative"))
        XCTAssertTrue(contentResult.contains("reference")) // Technical reference
        XCTAssertTrue(contentResult.contains("engineer"))
        XCTAssertTrue(contentResult.contains("commercial"))

        // Step 2: Query Analysis for decision points
        let decisionQuery = "Should we add strings to chorus sections within budget?"
        let queryResult = try await queryAnalysisTool.processAudioContent(decisionQuery, with: [
            "context": [
                "expertise": "professional",
                "budget": "$1,500"
            ],
            "analysis_depth": "standard",
            "response_guidance": true
        ])

        XCTAssertFalse(queryResult.isEmpty)
        XCTAssertTrue(queryResult.contains("decision_making"))
        XCTAssertTrue(queryResult.contains("cost"))

        // Step 3: Intent Recognition for setup actions
        let setupCommands = [
            "Setup Neumann U87 for lead vocals",
            "Configure AKG C414 stereo pair for acoustic guitar",
            "Position drum microphones for vintage sound"
        ]

        for command in setupCommands {
            let intentResult = try await intentRecognitionTool.processAudioContent(command, with: [
                "extract_context": true
            ])
            XCTAssertFalse(intentResult.isEmpty)
        }

        // Verify equipment extraction
        let expectedEquipment = ["Neumann", "AKG", "Shure", "API", "Fender", "Royer", "Pro Tools"]
        for equipment in expectedEquipment {
            XCTAssertTrue(contentResult.contains(equipment), "Missing equipment: \(equipment)")
        }

        // Verify business context extraction
        if contentResult.contains("business_context") {
            XCTAssertTrue(contentResult.contains("budget_mentions"))
            XCTAssertTrue(contentResult.contains("decision_points"))
        }
    }

    func testAudioProductionEducationalWorkflow() async throws {
        let educationalContent = """
        Audio Production Tutorial: Home Studio Setup Guide

        Chapter 1: Essential Equipment for Beginners

        Introduction:
        Welcome to your home studio setup journey! This guide will help you create
        a professional-sounding recording space without breaking the bank. We'll cover
        everything from basic equipment to advanced techniques.

        Section 1: Microphones

        For beginners starting with vocal recording, I recommend the following options:

        Budget Option ($100-300):
        - Audio-Technica AT2020: Excellent condenser mic for vocals and instruments
        - Rode NT1-A: Warm sound, low self-noise, great for home recording

        Mid-Range Option ($300-600):
        - AKG P220: Versatile for vocals and instruments
        - Rode NT1: Classic choice for home studios

        Professional Option ($600+):
        - Neumann TLM 102: Professional quality in compact form
        - AKG C414: Industry standard for various applications

        Section 2: Audio Interfaces

        Your audio interface is the heart of your home studio. It converts analog
        signals from your microphones into digital data for your computer.

        Entry Level (2-4 channels):
        - Focusrite Scarlett 2i2: Most popular choice for beginners
        - PreSonus AudioBox USB 96: Reliable and affordable

        Professional Level (8+ channels):
        - Universal Audio Apollo Twin: High-quality preamps and DSP
        - Antelope Audio Discrete 4: Professional conversion quality

        Section 3: Recording Software (DAW)

        Free Options:
        - GarageBand (Mac only): Surprisingly powerful for free software
        - Reaper: Highly customizable, affordable license

        Professional Options:
        - Pro Tools: Industry standard for professional studios
        - Logic Pro X: Mac-only, great value for the price
        - Ableton Live: Excellent for electronic music production

        Quick Setup Checklist:
        □ Connect interface to computer via USB/Thunderbolt
        □ Install necessary drivers and software
        □ Connect microphone to interface with XLR cable
        □ Enable 48V phantom power if using condenser mic
        □ Set input gain to proper level (-12dB to -6dB)
        □ Set buffer size for recording (128 or 256 samples)
        □ Test recording and adjust levels as needed

        Common Beginner Mistakes to Avoid:
        1. Recording too hot (levels too high)
        2. Not using proper microphone placement
        3. Ignoring room acoustics and treatment
        4. Using wrong buffer size for recording
        5. Not monitoring with proper headphones

        Next Steps:
        Once you have your basic setup working, you can explore:
        - Room treatment and acoustic panels
        - Additional microphones for different instruments
        - Studio monitors for accurate playback
        - Audio plugins and virtual instruments

        Remember: The most important thing is to start recording and learning!
        Don't get caught up in "gear acquisition syndrome" - make music with what you have.
        """

        // Step 1: Content Analysis
        let contentResult = try await contentPurposeDetector.processAudioContent(educationalContent, with: [
            "content_hint": "tutorial",
            "context": [
                "author_role": "educator",
                "audience": "student"
            ],
            "analysis_depth": "comprehensive",
            "include_quality_assessment": true
        ])

        XCTAssertFalse(contentResult.isEmpty)
        XCTAssertTrue(contentResult.contains("tutorial"))
        XCTAssertTrue(contentResult.contains("instructional"))
        XCTAssertTrue(contentResult.contains("student"))
        XCTAssertTrue(contentResult.contains("beginner")) // Technical complexity

        // Step 2: Query Analysis for student questions
        let studentQuestions = [
            "What's the best microphone for podcasting under $200?",
            "How do I connect my microphone to my computer?",
            "Why do I need an audio interface?",
            "What software should I use for recording music?"
        ]

        for question in studentQuestions {
            let queryResult = try await queryAnalysisTool.processAudioContent(question, with: [
                "context": [
                    "expertise": "beginner"
                ],
                "analysis_depth": "standard",
                "response_guidance": true
            ])
            XCTAssertFalse(queryResult.isEmpty)
            XCTAssertTrue(queryResult.contains("recommendation") || queryResult.contains("factual"))
        }

        // Step 3: Intent Recognition for setup actions
        let setupActions = [
            "Connect audio interface to computer",
            "Set up microphone for recording",
            "Configure recording software"
        ]

        for action in setupActions {
            let intentResult = try await intentRecognitionTool.processAudioContent(action, with: [
                "extract_context": true
            ])
            XCTAssertFalse(intentResult.isEmpty)
        }

        // Verify educational content characteristics
        XCTAssertTrue(contentResult.contains("basic"))
        if contentResult.contains("quality_indicators") {
            // Tutorial should have good organization
            XCTAssertTrue(contentResult.contains("organization"))
        }
    }

    func testRealWorldAudioProductionWorkflow() async throws {
        // This test simulates a complete real-world audio production workflow
        // from client brief through final delivery

        let clientBrief = """
        PROJECT BRIEF: "Neon Nights" - Electronic Pop Album

        Client: Alexandra Rivera (Independent Artist)
        Budget: $8,000 total
        Timeline: 2 months from start to delivery
        Release: Indie label distribution

        Artist Vision:
        "Neon Nights" is an electronic pop album with 10 tracks. I want a modern,
        polished sound with elements of synth-pop and dream pop. Vocals should be
        intimate and atmospheric, with lush harmonies and effects.

        Reference Artists:
        - CHVRCHES (synth-pop aesthetic)
        - Lykke Li (dream pop elements)
        - Billie Eilish (modern production techniques)

        Technical Requirements:
        - Genre: Electronic Pop / Dream Pop
        - Format: 24-bit/48kHz
        - Delivery: WAV files, streaming masters
        - Vocal processing: Heavy effects, harmonies, layers

        Budget Breakdown:
        - Recording & Production: $5,000
        - Mixing: $2,000
        - Mastering: $1,000

        Timeline:
        - Week 1-2: Vocal recording and production
        - Week 3-4: Instrumentation and arrangement
        - Week 5-6: Mixing
        - Week 7: Mastering and delivery

        Creative Notes:
        Want to experiment with vocal processing techniques like:
        - Telephone effect vocals
        - Heavy reverb and delay
        - Formant shifting
        - Glitchy vocal samples

        Safety Note: Will be working late hours during production phase.
        Need to ensure hearing protection is used during loud monitoring sessions.
        """

        // Step 1: Analyze Client Brief
        let briefAnalysis = try await contentPurposeDetector.processAudioContent(clientBrief, with: [
            "content_hint": "project_documentation",
            "context": [
                "author_role": "producer",
                "project_type": "music_production"
            ],
            "analysis_depth": "comprehensive",
            "include_business_context": true
        ])

        XCTAssertFalse(briefAnalysis.isEmpty)
        XCTAssertTrue(briefAnalysis.contains("project_documentation"))
        XCTAssertTrue(briefAnalysis.contains("planning"))
        XCTAssertTrue(briefAnalysis.contains("commercial"))
        XCTAssertTrue(briefAnalysis.contains("decision_making"))

        // Step 2: Production Phase Queries
        let productionQueries = [
            "What's the best microphone for dream pop vocals with heavy processing?",
            "How do I create telephone effect vocals using plugins?",
            "What settings for reverb and delay for atmospheric vocals?",
            "How to protect hearing during late night mixing sessions?"
        ]

        for query in productionQueries {
            let queryResult = try await queryAnalysisTool.processAudioContent(query, with: [
                "context": [
                    "expertise": "advanced",
                    "project_type": "music_production"
                ],
                "include_safety": query.contains("hearing"),
                "response_guidance": true
            ])
            XCTAssertFalse(queryResult.isEmpty)

            if query.contains("hearing") {
                XCTAssertTrue(queryResult.contains("safety"))
            }
        }

        // Step 3: Intent Recognition for Production Tasks
        let productionTasks = [
            "Set up vocal recording chain with tube preamp",
            "Create telephone effect using EQ and distortion",
            "Configure heavy reverb and delay processing",
            "Schedule mixing session for week 5"
        ]

        for task in productionTasks {
            let intentResult = try await intentRecognitionTool.processAudioContent(task, with: [
                "extract_context": true
            ])
            XCTAssertFalse(intentResult.isEmpty)
        }

        // Step 4: Verify Workflow Integration
        // Should identify project type and requirements
        XCTAssertTrue(briefAnalysis.contains("music_production"))

        // Should identify budget constraints
        if briefAnalysis.contains("business_context") {
            XCTAssertTrue(briefAnalysis.contains("budget_mentions"))
        }

        // Should identify safety considerations
        let safetyQuery = "How to protect hearing during loud monitoring sessions?"
        let safetyResult = try await queryAnalysisTool.processAudioContent(safetyQuery, with: [
            "include_safety": true
        ])
        XCTAssertFalse(safetyResult.isEmpty)
        if safetyResult.contains("safety_assessment") {
            XCTAssertTrue(safetyResult.contains("hearing_protection"))
        }

        // Verify comprehensive workflow coverage
        let allResults = [briefAnalysis] + productionQueries.compactMap { _ in try? await queryAnalysisTool.processAudioContent($0, with: [:]) }
        for result in allResults {
            XCTAssertFalse(result.isEmpty)
        }
    }

    // MARK: - Performance and Stress Tests

    func testPerformanceWithLargeContent() async throws {
        let largeContent = String(repeating: """
        Comprehensive session notes with detailed technical specifications, client feedback,
        equipment settings, mixing decisions, creative choices, business considerations,
        timeline requirements, budget constraints, and quality assessments.
        Recording session details including microphone placement, preamp settings,
        signal chain configuration, plugin parameters, automation data, and export settings.
        Client communication logs with feedback, requests, approvals, and decision points.
        Technical troubleshooting notes, problem solutions, and preventive measures.
        """, count: 20)

        let startTime = Date()
        let result = try await contentPurposeDetector.processAudioContent(largeContent, with: [
            "analysis_depth": "comprehensive"
        ])
        let executionTime = Date().timeIntervalSince(startTime)

        XCTAssertFalse(result.isEmpty)
        XCTAssertLessThan(executionTime, 0.5, "Large content analysis should complete within 500ms")
    }

    func testConcurrentToolExecution() async throws {
        let testInputs = [
            ("Start recording vocals with Neumann U87", intentRecognitionTool),
            ("What's the best microphone under $500?", queryAnalysisTool),
            ("Session notes: Recording complete, client happy", contentPurposeDetector)
        ]

        var results: [String] = []

        for (input, tool) in testInputs {
            let result = try await tool.processAudioContent(input, with: [:])
            results.append(result)
        }

        // Verify all tools executed successfully
        XCTAssertEqual(results.count, 3)
        for result in results {
            XCTAssertFalse(result.isEmpty)
        }

        // Verify each tool produced appropriate output
        XCTAssertTrue(results[0].contains("confidence")) // Intent recognition
        XCTAssertTrue(results[1].contains("category")) // Query analysis
        XCTAssertTrue(results[2].contains("content_type")) // Content purpose
    }

    func testCrossToolConsistency() async throws {
        let testQuery = "Apply EQ boost at 3kHz to vocals for better presence"

        // Analyze with different tools
        let intentResult = try await intentRecognitionTool.processAudioContent(testQuery, with: [:])
        let queryResult = try await queryAnalysisTool.processAudioContent(testQuery, with: [:])
        let contentResult = try await contentPurposeDetector.processAudioContent(testQuery, with: [
            "content_hint": "technical_log"
        ])

        // All should recognize the audio domain
        XCTAssertFalse(intentResult.isEmpty)
        XCTAssertFalse(queryResult.isEmpty)
        XCTAssertFalse(contentResult.isEmpty)

        // Should be consistent in audio domain recognition
        let allAudioDomain = [
            intentResult.contains("confidence"),
            queryResult.contains("technical") || queryResult.contains("procedural"),
            contentResult.contains("technical_log")
        ]
        XCTAssertTrue(allAudioDomain.allSatisfy { $0 })

        // Should extract common entities
        let hasEQ = intentResult.contains("EQ") || queryResult.contains("EQ") || contentResult.contains("EQ")
        let hasFrequency = intentResult.contains("3kHz") || queryResult.contains("3kHz") || contentResult.contains("3kHz")
        let hasVocals = intentResult.contains("vocals") || queryResult.contains("vocals") || contentResult.contains("vocals")

        XCTAssertTrue(hasEQ, "All tools should recognize EQ")
        XCTAssertTrue(hasFrequency, "All tools should extract frequency parameter")
        XCTAssertTrue(hasVocals, "All tools should recognize vocals")
    }
}

// MARK: - Mock Classes (Shared across tests)

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