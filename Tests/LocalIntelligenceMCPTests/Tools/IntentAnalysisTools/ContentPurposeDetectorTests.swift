//
//  ContentPurposeDetectorTests.swift
//  LocalIntelligenceMCPTests
//
//  Created on 2025-10-09.
//

import XCTest
@testable import LocalIntelligenceMCP

/// Comprehensive unit tests for ContentPurposeDetector
/// Tests content type classification, purpose detection, actionability assessment, and business context analysis
final class ContentPurposeDetectorTests: XCTestCase {

    // MARK: - Test Properties

    var mockLogger: MockLogger!
    var mockSecurityManager: MockSecurityManager!
    var contentPurposeDetector: ContentPurposeDetector!

    // MARK: - Test Lifecycle

    override func setUp() async throws {
        try await super.setUp()
        mockLogger = MockLogger()
        mockSecurityManager = MockSecurityManager()
        contentPurposeDetector = ContentPurposeDetector(logger: mockLogger, securityManager: mockSecurityManager)
    }

    override func tearDown() async throws {
        mockLogger = nil
        mockSecurityManager = nil
        contentPurposeDetector = nil
        try await super.tearDown()
    }

    // MARK: - Content Type Classification Tests

    func testSessionNotesClassification() async throws {
        let sessionNotesContent = [
            "Session Notes: Today we recorded lead vocals using Neumann U87 through API 312 preamp. Client was happy with take 3. Applied gentle EQ with 2kHz boost.",
            "Recording session log: Setup drums at 10am, used AKG C414 overheads. Bass tracking complete by 2pm. Guitar overdubs scheduled for tomorrow.",
            "Today's session focused on mixing. Applied EQ to vocals, added compression to bass. Client reviewed and approved initial mix."
        ]

        for content in sessionNotesContent {
            let result = try await contentPurposeDetector.processAudioContent(content, with: [:])
            XCTAssertFalse(result.isEmpty)
            XCTAssertTrue(result.contains("session_notes"))
        }
    }

    func testTranscriptClassification() async throws {
        let transcriptContent = [
            "Speaker 1: We should start with the vocals. Speaker 2: I agree, let's set up the Neumann first. Speaker 1: What about the microphone placement?",
            "Interview with Producer Q: How do you approach mixing? A: I always start with the foundation elements like drums and bass.",
            "Meeting transcript: Client discussed wanting more presence in vocals. Engineer suggested EQ boost at 3kHz. Producer agreed with approach."
        ]

        for content in transcriptContent {
            let result = try await contentPurposeDetector.processAudioContent(content, with: [:])
            XCTAssertFalse(result.isEmpty)
            XCTAssertTrue(result.contains("transcript"))
        }
    }

    func testTechnicalLogClassification() async throws {
        let technicalLogContent = [
            "Technical Log: SSL G+ Console, Pro Tools HD, 96kHz/24-bit. Used Waves CLA-76 compressor with 4:1 ratio, -18dB threshold. Applied high-pass filter at 80Hz.",
            "Equipment Settings: API 312 preamp gain at 35dB, Neumann U87 with 48V phantom power. Recorded to Pro Tools at 24-bit/96kHz.",
            "Signal Chain: Neumann TLM 103 → Focusrite Scarlett 2i2 → Logic Pro X. Used Fabfilter Pro-Q 3 for EQ, followed by Valhalla VintageVerb."
        ]

        for content in technicalLogContent {
            let result = try await contentPurposeDetector.processAudioContent(content, with: [:])
            XCTAssertFalse(result.isEmpty)
            XCTAssertTrue(result.contains("technical_log"))
        }
    }

    func testClientCommunicationClassification() async throws {
        let clientCommContent = [
            "Hi team, I've reviewed the latest mix and overall it sounds great. Could we add a bit more presence to the vocals? Also, the bass could be more prominent.",
            "Client feedback: The energy is good but I'd like more low-end impact. Can we boost the kick drum around 60Hz? Deadline is Friday.",
            "Thank you for the quick turnaround! The vocals sound much better now. One small request - can we reduce the reverb slightly? It feels a bit too much."
        ]

        for content in clientCommContent {
            let result = try await contentPurposeDetector.processAudioContent(content, with: [:])
            XCTAssertFalse(result.isEmpty)
            XCTAssertTrue(result.contains("client_communication"))
        }
    }

    func testProjectDocumentationClassification() async throws {
        let projectDocContent = [
            "Project Specification: This album requires 10 tracks with consistent sonic character. Target loudness: -14 LUFS. Delivery formats: WAV 24-bit/96kHz and MP3 320kbps.",
            "Technical Requirements: All recordings must be done at minimum 24-bit/96kHz. Use of vintage equipment encouraged but not required. Mastering engineer: Bob Ludwig.",
            "Documentation Guidelines: Each session must include track sheets with microphone settings, plugin chains documented, and backup procedures followed."
        ]

        for content in projectDocContent {
            let result = try await contentPurposeDetector.processAudioContent(content, with: [:])
            XCTAssertFalse(result.isEmpty)
            XCTAssertTrue(result.contains("project_documentation"))
        }
    }

    func testTroubleshootingClassification() async throws {
        let troubleshootingContent = [
            "Problem: The vocal track has a lot of background noise. I've tried using noise reduction plugins but the vocal sounds unnatural. The recording was done in a treated room.",
            "Issue: There's a ground loop hum in the signal chain. Checked all cable connections, tried different outlets, but the hum persists at 60Hz.",
            "Troubleshooting: The mix sounds muddy even after EQ. Suspect phase issues between overhead mics. Need to check phase correlation and alignment."
        ]

        for content in troubleshootingContent {
            let result = try await contentPurposeDetector.processAudioContent(content, with: [:])
            XCTAssertFalse(result.isEmpty)
            XCTAssertTrue(result.contains("troubleshooting"))
        }
    }

    // MARK: - Purpose Detection Tests

    func testInformationalPurpose() async throws {
        let informationalContent = [
            "Session status: Recording complete, 8 takes recorded. Mix session scheduled for tomorrow at 2pm.",
            "Update: Client has approved the rough mix. Proceeding with final mix as discussed.",
            "Current project status: All drums tracked, bass tracked, guitars in progress. Estimated completion: end of week."
        ]

        for content in informationalContent {
            let result = try await contentPurposeDetector.processAudioContent(content, with: [:])
            XCTAssertFalse(result.isEmpty)
            XCTAssertTrue(result.contains("informative"))
        }
    }

    func testInstructionalPurpose() async throws {
        let instructionalContent = [
            "How to set up vocal recording: 1. Position microphone 6 inches from singer, 2. Set phantom power to 48V, 3. Set preamp gain to proper level, 4. Record test take and adjust.",
            "Tutorial: To apply parallel compression, send vocals to bus, add compressor with aggressive settings, blend with dry signal for punch.",
            "Step-by-step mastering process: 1. Apply EQ, 2. Add compression, 3. Set limiting, 4. Check loudness, 5. Export final master."
        ]

        for content in instructionalContent {
            let result = try await contentPurposeDetector.processAudioContent(content, with: [:])
            XCTAssertFalse(result.isEmpty)
            XCTAssertTrue(result.contains("instructional"))
        }
    }

    func testDecisionMakingPurpose() async throws {
        let decisionContent = [
            "Decision needed: Client wants warmer vocal tone. Option A: Use tube preamp. Option B: Add saturation plugin. Option C: Record with different microphone. Please advise by Friday.",
            "Approval required: Budget allows for either Neumann U87 or AKG C414. Neumann more expensive but better for vocals. AKG more versatile. Need client decision.",
            "Choice to make: Should we record drums first or bass? Recording drums first gives better foundation but bass first helps with timing. Producer leaning towards drums first."
        ]

        for content in decisionContent {
            let result = try await contentPurposeDetector.processAudioContent(content, with: [:])
            XCTAssertFalse(result.isEmpty)
            XCTAssertTrue(result.contains("decision_making"))
        }
    }

    func testCommunicationPurpose() async throws {
        let communicationContent = [
            "Hi Sarah, just wanted to let you know that the vocals are sounding great. I think we're ready for you to come in and do your final takes.",
            "Team update: The mixing session went well. Client very happy with results. Moving to mastering phase next week.",
            "FYI: We've found a great guitar tone using the vintage Marshall amp. I think you'll love the sound we're getting."
        ]

        for content in communicationContent {
            let result = try await contentPurposeDetector.processAudioContent(content, with: [:])
            XCTAssertFalse(result.isEmpty)
            XCTAssertTrue(result.contains("communication"))
        }
    }

    // MARK: - Actionability Assessment Tests

    func testImmediateActionAssessment() async throws {
        let immediateActionContent = [
            "URGENT: Client needs mix revisions by tomorrow morning. The vocals need to be louder and the bass less muddy.",
            "Emergency: Recording session cancelled due to equipment failure. Need to reschedule immediately.",
            "Critical: Hard drive failure on main recording system. All data lost. Need immediate recovery action."
        ]

        for content in immediateActionContent {
            let result = try await contentPurposeDetector.processAudioContent(content, with: [:])
            XCTAssertFalse(result.isEmpty)
            XCTAssertTrue(result.contains("immediate_action"))
        }
    }

    func testScheduledActionAssessment() async throws {
        let scheduledActionContent = [
            "Schedule mixing session for next Tuesday at 2pm. Ensure all tracks are edited and organized.",
            "Deadline: Client review required by Friday EOD. Please have rough mix ready by Thursday.",
            "Timeline: Mastering to be completed by June 15th. All final mixes must be approved by June 10th."
        ]

        for content in scheduledActionContent {
            let result = try await contentPurposeDetector.processAudioContent(content, with: [:])
            XCTAssertFalse(result.isEmpty)
            XCTAssertTrue(result.contains("scheduled_action"))
        }
    }

    func testConditionalActionAssessment() async throws {
        let conditionalActionContent = [
            "If client approves the current mix, proceed with mastering. If not, schedule revision session.",
            "Should the vocal take need editing, comp the best parts. Otherwise, move forward with mixing.",
            "In case of technical issues during recording, switch to backup equipment and continue session."
        ]

        for content in conditionalActionContent {
            let result = try await contentPurposeDetector.processAudioContent(content, with: [:])
            XCTAssertFalse(result.isEmpty)
            XCTAssertTrue(result.contains("conditional_action"))
        }
    }

    func testReferenceOnlyAssessment() async throws {
        let referenceContent = [
            "Reference notes: SSL console settings used on previous project: Low EQ at 80Hz, High EQ at 12kHz, compression ratio 4:1.",
            "Documentation: Microphone placement techniques that worked well: 6 inches from source, slight angle off-axis.",
            "Archive: Plugin chain for vocal processing: EQ → Compression → De-esser → Reverb. Keep for future reference."
        ]

        for content in referenceContent {
            let result = try await contentPurposeDetector.processAudioContent(content, with: [:])
            XCTAssertFalse(result.isEmpty)
            XCTAssertTrue(result.contains("reference_only"))
        }
    }

    // MARK: - Audience Analysis Tests

    func testEngineerAudience() async throws {
        let engineerContent = [
            "Technical setup: Using API 312 preamps with 65dB of gain, sending to Pro Tools HD at 96kHz/24-bit via HDX cards.",
            "Mixing approach: Start with drums and bass foundation, then add vocals, apply parallel compression on drums bus.",
            "Signal flow: Neumann U87 → Neve 1073 → LA-2A → Pro Tools. Apply high-pass at 80Hz before compression."
        ]

        for content in engineerContent {
            let result = try await contentPurposeDetector.processAudioContent(content, with: [:])
            XCTAssertFalse(result.isEmpty)
            XCTAssertTrue(result.contains("engineer"))
        }
    }

    func testClientAudience() async throws {
        let clientContent = [
            "The recording sounds great! I love the energy in the drums. Can we make the vocals a bit more present?",
            "Thank you for the quick work on the mix. The guitars sound much better now. Ready to move forward.",
            "I'm not sure about the reverb on the vocals. Could we try something a bit more subtle?"
        ]

        for content in clientContent {
            let result = try await contentPurposeDetector.processAudioContent(content, with: [:])
            XCTAssertFalse(result.isEmpty)
            XCTAssertTrue(result.contains("client"))
        }
    }

    func testProducerAudience() async throws {
        let producerContent = [
            "Creative direction: Want a warm, vintage sound for this track. Consider using tube compression and analog EQ.",
            "Song structure: Need to build energy in the chorus. Consider adding more instruments and raising levels.",
            "Artistic vision: The vocals should feel intimate but powerful. Use close miking technique with warm preamp."
        ]

        for content in producerContent {
            let result = try await contentPurposeDetector.processAudioContent(content, with: [:])
            XCTAssertFalse(result.isEmpty)
            XCTAssertTrue(result.contains("producer"))
        }
    }

    func testStudentAudience() async throws {
        let studentContent = [
            "Beginner question: What's the difference between condenser and dynamic microphones?",
            "Learning: How do I set up my first home studio on a budget?",
            "Help needed: Why does my recording sound muddy? What basic EQ should I apply?"
        ]

        for content in studentContent {
            let result = try await contentPurposeDetector.processAudioContent(content, with: [:])
            XCTAssertFalse(result.isEmpty)
            XCTAssertTrue(result.contains("student"))
        }
    }

    // MARK: - Technical Complexity Analysis Tests

    func testBasicComplexityLevel() async throws {
        let basicContent = [
            "Recorded vocals today. Used a microphone. Sounded good.",
            "Mix is done. Made the drums louder. vocals are clear.",
            "Need to record guitar tomorrow. Use the good microphone."
        ]

        for content in basicContent {
            let result = try await contentPurposeDetector.processAudioContent(content, with: [:])
            XCTAssertFalse(result.isEmpty)
            XCTAssertTrue(result.contains("basic"))
        }
    }

    func testAdvancedComplexityLevel() async throws {
        let advancedContent = [
            "Implemented parallel compression on drum bus using SSL G+ bus compressor with 4:1 ratio, fastest attack, 100ms release, blending 30% wet signal.",
            "Applied M/S EQ processing to enhance stereo width. Used mid-side compression with different settings for mid and side channels.",
            "Configured multi-band distortion with frequency splitting at 800Hz and 4kHz, each band processed through different saturation algorithms."
        ]

        for content in advancedContent {
            let result = try await contentPurposeDetector.processAudioContent(content, with: [:])
            XCTAssertFalse(result.isEmpty)
            XCTAssertTrue(result.contains("advanced") || result.contains("professional"))
        }
    }

    func testTechnicalTermsExtraction() async throws {
        let technicalContent = [
            "Used SSL console with EQ at 2kHz boost, compression with 4:1 ratio, threshold at -18dB.",
            "Pro Tools HD session at 96kHz/24-bit, using HDX cards for low latency.",
            "Neumann U87 microphone with API 312 preamp, 48V phantom power engaged."
        ]

        for content in technicalContent {
            let result = try await contentPurposeDetector.processAudioContent(content, with: [:])
            XCTAssertFalse(result.isEmpty)
            XCTAssertTrue(result.contains("technical_terms"))
        }
    }

    // MARK: - Business Context Analysis Tests

    func testCommercialProjectType() async throws {
        let commercialContent = [
            "Client: Major record label. Budget: $50,000. Timeline: 6 weeks. Deliverables: 10 mastered tracks.",
            "Commercial project for TV advertisement. Need high impact sound with brand consistency.",
            "Corporate training video requiring professional voice-over and background music. Budget: $5,000."
        ]

        for content in commercialContent {
            let result = try await contentPurposeDetector.processAudioContent(content, with: [:])
            XCTAssertFalse(result.isEmpty)
            XCTAssertTrue(result.contains("commercial"))
        }
    }

    func testBudgetMentions() async throws {
        let budgetContent = [
            "Project budget: $10,000 for full album production.",
            "Client can spend $500 on microphone rental.",
            "Total cost breakdown: Studio time $2000, engineer $1500, mastering $800.",
            "Budget constraints require using stock plugins instead of third-party."
        ]

        for content in budgetContent {
            let result = try await contentPurposeDetector.processAudioContent(content, with: [:])
            XCTAssertFalse(result.isEmpty)
            if result.contains("business_context") {
                XCTAssertTrue(result.contains("budget_mentions"))
            }
        }
    }

    func testTimelineMentions() async throws {
        let timelineContent = [
            "Deadline: Mix must be delivered by Friday 5pm.",
            "Project timeline: Recording 2 weeks, mixing 1 week, mastering 3 days.",
            "Client needs final tracks by end of month for release.",
            "Schedule: Recording session tomorrow at 2pm, mix review on Thursday."
        ]

        for content in timelineContent {
            let result = try await contentPurposeDetector.processAudioContent(content, with: [:])
            XCTAssertFalse(result.isEmpty)
            if result.contains("business_context") {
                XCTAssertTrue(result.contains("timeline_mentions"))
            }
        }
    }

    func testDecisionPointsExtraction() async throws {
        let decisionContent = [
            "Decision needed: Should we use analog or digital summing? Client prefers analog warmth but budget is tight.",
            "Approval required: Microphone choice between Neumann U87 ($3000) and AKG C414 ($1000). Need client decision.",
            "Choice to make: Mix in the box or use analog console? Analog has better sound but digital is more flexible."
        ]

        for content in decisionContent {
            let result = try await contentPurposeDetector.processAudioContent(content, with: [:])
            XCTAssertFalse(result.isEmpty)
            if result.contains("business_context") {
                XCTAssertTrue(result.contains("decision_points"))
            }
        }
    }

    // MARK: - Quality Assessment Tests

    func testCompletenessAssessment() async throws {
        let completeContent = [
            "Full session notes: Recording setup, microphone placement, all takes recorded, client feedback, mix decisions, final approval.",
            "Complete documentation: Equipment list, signal chain diagram, plugin settings for each track, backup procedures, delivery specs.",
            "Comprehensive log: All technical settings, creative decisions, client interactions, problem solutions, final outcomes."
        ]

        let incompleteContent = [
            "Recording notes: Used mic, sounded good.",
            "Mix notes: Made changes.",
            "Session: Recorded vocals."
        ]

        // Complete content should have higher completeness scores
        for content in completeContent {
            let result = try await contentPurposeDetector.processAudioContent(content, with: [:])
            XCTAssertFalse(result.isEmpty)
            if result.contains("quality_indicators") {
                // Should indicate higher completeness
                XCTAssertTrue(result.contains("completeness"))
            }
        }

        // Incomplete content should have lower completeness scores
        for content in incompleteContent {
            let result = try await contentPurposeDetector.processAudioContent(content, with: [:])
            XCTAssertFalse(result.isEmpty)
            if result.contains("quality_indicators") {
                // Should indicate lower completeness
                XCTAssertTrue(result.contains("completeness"))
            }
        }
    }

    func testOrganizationAssessment() async throws {
        let organizedContent = [
            "1. Setup: Neumann U87, API 312, Pro Tools HD. 2. Recording: 8 takes, selected take 3. 3. Processing: EQ, compression. 4. Client review: Approved.",
            "Section A: Equipment. Section B: Signal Chain. Section C: Recording Process. Section D: Client Feedback. Section E: Final Mix.",
            "Phase 1: Preparation. Phase 2: Recording. Phase 3: Editing. Phase 4: Mixing. Phase 5: Mastering. Phase 6: Delivery."
        ]

        let disorganizedContent = [
            "Recording done. Used mic. Client happy. Need to mix tomorrow. Settings were good. Bass sounds nice.",
            "Vocals recorded. Drums need work. Guitar solo planned. Client feedback pending. Mix almost done.",
            "Setup microphone. Recording tracks. Add effects. Send to client. Make changes. Export final."
        ]

        // Organized content should have higher organization scores
        for content in organizedContent {
            let result = try await contentPurposeDetector.processAudioContent(content, with: [:])
            XCTAssertFalse(result.isEmpty)
            if result.contains("quality_indicators") {
                XCTAssertTrue(result.contains("organization"))
            }
        }

        // Disorganized content should have lower organization scores
        for content in disorganizedContent {
            let result = try await contentPurposeDetector.processAudioContent(content, with: [:])
            XCTAssertFalse(result.isEmpty)
            if result.contains("quality_indicators") {
                XCTAssertTrue(result.contains("organization"))
            }
        }
    }

    // MARK: - Sentiment Analysis Tests

    func testPositiveSentiment() async throws {
        let positiveContent = [
            "The recording sounds amazing! Client absolutely loves the vocal performance. Great energy in the drums.",
            "Excellent work on the mix! The balance is perfect and the clarity is outstanding. Client is thrilled.",
            "Wonderful session today. The musicians were fantastic, the equipment worked perfectly, and we captured some magic."
        ]

        for content in positiveContent {
            let result = try await contentPurposeDetector.processAudioContent(content, with: [:])
            XCTAssertFalse(result.isEmpty)
            if result.contains("sentiment") {
                XCTAssertTrue(result.contains("positive"))
            }
        }
    }

    func testNegativeSentiment() async throws {
        let negativeContent = [
            "The recording is disappointing. There's too much noise and the performance lacks energy.",
            "Client is unhappy with the mix. It sounds muddy and unclear. Major changes needed.",
            "Terrible session today. Equipment malfunctioned, musician was late, and we wasted valuable time."
        ]

        for content in negativeContent {
            let result = try await contentPurposeDetector.processAudioContent(content, with: [:])
            XCTAssertFalse(result.isEmpty)
            if result.contains("sentiment") {
                XCTAssertTrue(result.contains("negative"))
            }
        }
    }

    func testNeutralSentiment() async throws {
        let neutralContent = [
            "Recording session completed. 8 takes recorded. Client to review tomorrow.",
            "Mix applied with EQ and compression. Levels adjusted. Ready for client feedback.",
            "Microphone setup: Neumann U87, 6 inches from source. Phantom power on."
        ]

        for content in neutralContent {
            let result = try await contentPurposeDetector.processAudioContent(content, with: [:])
            XCTAssertFalse(result.isEmpty)
            if result.contains("sentiment") {
                XCTAssertTrue(result.contains("neutral"))
            }
        }
    }

    // MARK: - Urgency Assessment Tests

    func testHighUrgencyAssessment() async throws {
        let urgentContent = [
            "URGENT: Client needs revisions by tomorrow morning at 9am sharp. Mix must be ready for executive review.",
            "EMERGENCY: Studio equipment failure. All recording sessions cancelled. Need immediate solution.",
            "CRITICAL: Hard drive crashed with all project data. Recovery needed immediately. Client deadline in 2 days."
        ]

        for content in urgentContent {
            let result = try await contentPurposeDetector.processAudioContent(content, with: [:])
            XCTAssertFalse(result.isEmpty)
            if result.contains("urgency") {
                XCTAssertTrue(result.contains("immediate"))
            }
        }
    }

    func testLowUrgencyAssessment() async throws {
        let lowUrgencyContent = [
            "Reference notes for future projects: SSL console settings that worked well.",
            "Archive: Microphone placement techniques that produced good results.",
            "Documentation: Plugin chains used for various instruments. Keep for reference."
        ]

        for content in lowUrgencyContent {
            let result = try await contentPurposeDetector.processAudioContent(content, with: [:])
            XCTAssertFalse(result.isEmpty)
            if result.contains("urgency") {
                XCTAssertTrue(result.contains("routine") || result.contains("no_deadline"))
            }
        }
    }

    // MARK: - Parameter Validation Tests

    func testContentHintParameter() async throws {
        let content = "Recording session notes"
        let hints = [
            "session_notes",
            "technical_log",
            "client_communication",
            "transcript"
        ]

        for hint in hints {
            let parameters: [String: Any] = ["content_hint": hint]
            let result = try await contentPurposeDetector.processAudioContent(content, with: parameters)
            XCTAssertFalse(result.isEmpty)
            XCTAssertTrue(result.contains(hint))
        }
    }

    func testContextParameter() async throws {
        let content = "Recording session completed successfully"
        let context: [String: Any] = [
            "author_role": "engineer",
            "project_type": "music_production",
            "workflow_stage": "recording",
            "audience": "client"
        ]

        let result = try await contentPurposeDetector.processAudioContent(content, with: context)
        XCTAssertFalse(result.isEmpty)

        // Should incorporate context into analysis
        XCTAssertTrue(result.contains("engineer"))
    }

    func testAnalysisDepthParameter() async throws {
        let content = "Complex recording session with multiple technical details"
        let depths = ["basic", "standard", "comprehensive"]

        for depth in depths {
            let parameters: [String: Any] = ["analysis_depth": depth]
            let result = try await contentPurposeDetector.processAudioContent(content, with: parameters)
            XCTAssertFalse(result.isEmpty)
            XCTAssertTrue(result.contains("analysis_depth"))
        }
    }

    // MARK: - Error Handling Tests

    func testEmptyContent() async throws {
        do {
            _ = try await contentPurposeDetector.processAudioContent("", with: [:])
            XCTFail("Should have thrown an error for empty content")
        } catch {
            XCTAssertTrue(error is AudioProcessingError)
        }
    }

    func testContentTooShort() async throws {
        do {
            _ = try await contentPurposeDetector.processAudioContent("Hi", with: [:])
            XCTFail("Should have thrown an error for content too short")
        } catch {
            XCTAssertTrue(error is AudioProcessingError)
        }
    }

    func testInvalidAnalysisDepth() async throws {
        let content = "Test content for analysis"
        let parameters: [String: Any] = ["analysis_depth": "invalid"]

        do {
            _ = try await contentPurposeDetector.processAudioContent(content, with: parameters)
            XCTFail("Should have thrown an error for invalid analysis depth")
        } catch {
            XCTAssertTrue(error is AudioProcessingError)
        }
    }

    // MARK: - Performance Tests

    func testPerformanceWithShortContent() async throws {
        let shortContent = "Session notes: Recording complete."

        let startTime = Date()
        let result = try await contentPurposeDetector.processAudioContent(shortContent, with: [:])
        let executionTime = Date().timeIntervalSince(startTime)

        XCTAssertFalse(result.isEmpty)
        XCTAssertLessThan(executionTime, 0.15, "Short content analysis should complete within 150ms")
    }

    func testPerformanceWithLongContent() async throws {
        let longContent = String(repeating: "Comprehensive session notes with detailed technical specifications, client feedback, and creative decisions. ", count: 50)

        let startTime = Date()
        let result = try await contentPurposeDetector.processAudioContent(longContent, with: [:])
        let executionTime = Date().timeIntervalSince(startTime)

        XCTAssertFalse(result.isEmpty)
        XCTAssertLessThan(executionTime, 0.3, "Long content analysis should complete within 300ms")
    }

    // MARK: - Integration Tests

    func testEndToEndContentAnalysis() async throws {
        let content = """
        Session Notes: Today we recorded lead vocals for the rock album. Used Neumann U87 microphone through API 312 preamp.
        Client was very happy with take 5 - great emotional delivery and solid technical performance. Applied gentle EQ
        with 2kHz boost for presence and subtle compression using LA-2A. Mix session scheduled for next Tuesday.

        Decision point: Client wants to add backing vocals but budget is getting tight. Need to decide whether to
        hire additional vocalists or use the lead vocalist's harmonies. Deadline for album delivery is end of month.

        Urgent: Client requested rough mix by Friday for promotional material. Need to prioritize vocal mix
        before other instruments.
        """

        let parameters: [String: Any] = [
            "content_hint": "session_notes",
            "context": [
                "author_role": "engineer",
                "project_type": "music_production",
                "workflow_stage": "recording",
                "business_context": [
                    "commercial_nature": "commercial",
                    "client_involvement": "high"
                ]
            ],
            "analysis_depth": "comprehensive",
            "include_quality_assessment": true,
            "include_business_context": true,
            "include_sentiment_analysis": true,
            "include_urgency_assessment": true
        ]

        let result = try await contentPurposeDetector.processAudioContent(content, with: parameters)
        XCTAssertFalse(result.isEmpty)

        // Should identify as session notes
        XCTAssertTrue(result.contains("session_notes"))

        // Should identify as informational purpose
        XCTAssertTrue(result.contains("informative"))

        // Should identify as scheduled action
        XCTAssertTrue(result.contains("scheduled_action"))

        // Should include technical complexity analysis
        XCTAssertTrue(result.contains("technical_complexity"))

        // Should include business context
        XCTAssertTrue(result.contains("business_context"))

        // Should include quality indicators
        XCTAssertTrue(result.contains("quality_indicators"))

        // Should include sentiment analysis
        XCTAssertTrue(result.contains("sentiment"))

        // Should include urgency assessment
        XCTAssertTrue(result.contains("urgency"))

        // Should extract entities (equipment, parameters)
        XCTAssertTrue(result.contains("entities"))

        // Should identify client as audience
        XCTAssertTrue(result.contains("client"))
    }
}