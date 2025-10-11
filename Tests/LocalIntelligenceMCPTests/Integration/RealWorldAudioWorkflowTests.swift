//
//  RealWorldAudioWorkflowTests.swift
//  LocalIntelligenceMCPTests
//
//  Created on 2025-10-09.
//

import XCTest
@testable import LocalIntelligenceMCP

/// Real-world integration tests for Local Intelligence MCP Tools
/// This test suite demonstrates end-to-end workflows using realistic audio session data,
/// transcripts, and documentation to validate the complete functionality of the advanced text tools.
final class RealWorldAudioWorkflowTests: XCTestCase {

    // MARK: - Test Properties

    var mockLogger: MockLogger!
    var mockSecurityManager: MockSecurityManager!
    var focusedSummarizationTool: FocusedSummarizationTool!
    var textChunkingTool: TextChunkingTool!
    var tokenCountUtility: TokenCountUtility!

    // MARK: - Test Lifecycle

    override func setUp() async throws {
        try await super.setUp()
        mockLogger = MockLogger()
        mockSecurityManager = MockSecurityManager()

        // Initialize tools
        focusedSummarizationTool = FocusedSummarizationTool(
            logger: mockLogger,
            securityManager: mockSecurityManager
        )
        textChunkingTool = TextChunkingTool(
            logger: mockLogger,
            securityManager: mockSecurityManager
        )
        tokenCountUtility = TokenCountUtility(
            logger: mockLogger,
            securityManager: mockSecurityManager
        )
    }

    override func tearDown() async throws {
        focusedSummarizationTool = nil
        textChunkingTool = nil
        tokenCountUtility = nil
        mockLogger = nil
        mockSecurityManager = nil
        try await super.tearDown()
    }

    // MARK: - Real Recording Session Tests

    func testCompleteRecordingSessionWorkflow() async throws {
        let recordingSession = """
        RECORDING SESSION NOTES - The Midnight Echoes
        Album: Electric Dreams
        Date: October 8, 2025
        Engineer: John Smith
        Assistant: Sarah Johnson
        Studio: Downtown Recording Studio, Room A

        SETUP (9:00 AM - 10:00 AM)
        ======================

        Vocal Setup:
        - Primary: Neumann U87 microphone, 6 inches from source
        - Preamp: API 312 preamp for warmth and character
        - Signal Chain: U87 → API 312 → dbx 160 compressor → Pro Tools HD
        - Position: Vocal booth, treated with acoustic panels
        - Monitoring: Genelec 8030 speakers in control room

        Backup Vocals Setup:
        - Harmony: AKG C414 for stereo harmonies
        - Preamp: Neve 1073 for classic analog warmth
        - Position: Same booth, 3 feet back for separation

        LEAD VOCAL RECORDING (10:00 AM - 1:30 PM)
        ===============================================

        Artist: Emily Johnson
        Song: "Midnight City Lights"
        Key: A minor, 120 BPM

        Take Analysis:
        - Take 1: Good start, slight pitch issues in bridge, emotional delivery 8/10
        - Take 2: Better pitch control, timing slightly rushed 7/10
        - Take 3: Excellent performance, perfect timing, great emotion 9/10
        - Take 4: Emotional but technical issues with breath control 6/10
        - Take 5: Good balance of technical and emotional, solid 8/10
        - Take 6: **SELECTED** - Best overall performance, great emotion and control 10/10
        - Take 7: Similar to take 6, slight variation in chorus 8/10
        - Take 8: Technical perfection, slightly less emotional 7/10

        Processing Applied:
        - EQ: +3dB boost at 2kHz for presence and clarity
        - High-pass filter: 80Hz to remove mud
        - Compression: dbx 160, 4:1 ratio, -10dB threshold, medium attack
        - De-esser: Applied to reduce sibilance on "s" sounds

        HARMONY VOCALS (2:00 PM - 4:00 PM)
        ======================================

        Three-part harmonies recorded:
        - Low harmony: A minor third below melody
        - Mid harmony: Perfect octave below melody
        - High harmony: Fifth above melody

        Processing:
        - Same EQ chain as lead vocal
        - Compression: Gentler settings (6:1 ratio, -8dB threshold)
        - Added slight reverb for blending

        Client Feedback:
        "Lead vocal performance is exceptional! Take 6 really captures the emotion of the song.
        The harmonies add great depth. Looking forward to hearing the final mix.
        Could we get a bit more low-end presence in the final mix?"

        NEXT SESSION:
        - Wednesday 10:00 AM: Bass guitar tracking
        - Thursday 2:00 PM: Electric guitar overdubs
        - Friday: Mixing session begins

        Technical Notes:
        - Pro Tools HD system running at 96kHz/24-bit
        - Total tracks recorded: 7 (1 lead vocal, 3 harmony vocals, 3 reference tracks)
        - Session completed: 4 hours including setup and breakdown
        - Client satisfaction: 10/10
        - Budget status: Within allocated $3,000 for tracking phase
        """

        // Step 1: Token Count Analysis
        let tokenParams: [String: Any] = [
            "text": recordingSession,
            "strategy": "audio_optimized",
            "content_type": "session_notes",
            "include_breakdown": true
        ]

        let tokenResult = try await tokenCountUtility.processAudioContent(recordingSession, with: tokenParams)

        XCTAssertFalse(tokenResult.isEmpty)
        XCTAssertTrue(tokenResult.contains("estimated") || tokenResult.lowercased().contains("token"))
        XCTAssertTrue(tokenResult.lowercased().contains("neumann"))
        XCTAssertTrue(tokenResult.lowercased().contains("pro tools"))

        // Step 2: Technical Summary Generation
        let summaryParams: [String: Any] = [
            "text": recordingSession,
            "focus_areas": ["recording", "technical", "equipment"],
            "style": "technical",
            "max_points": 12
        ]

        let summaryResult = try await focusedSummarizationTool.processAudioContent(recordingSession, with: summaryParams)

        XCTAssertFalse(summaryResult.isEmpty)
        let summaryLower = summaryResult.lowercased()
        XCTAssertTrue(summaryLower.contains("neumann"))
        XCTAssertTrue(summaryLower.contains("api"))
        XCTAssertTrue(summaryLower.contains("pro tools"))
        XCTAssertTrue(summaryLower.contains("96khz"))
        XCTAssertTrue(summaryLower.contains("24-bit"))

        // Step 3: Content Chunking for Reference
        let chunkingParams: [String: Any] = [
            "text": recordingSession,
            "strategy": "audio_session",
            "max_chunk_size": 1000,
            "preserve_audio_structure": true
        ]

        let chunkingResult = try await textChunkingTool.processAudioContent(recordingSession, with: chunkingParams)

        XCTAssertFalse(chunkingResult.isEmpty)
        XCTAssertTrue(chunkingResult.contains("chunks"))
        let chunkingLower = chunkingResult.lowercased()
        XCTAssertTrue(chunkingLower.contains("total_chunks"))

        // Step 4: Performance Validation
        let startTime = Date()

        // Run complete workflow
        let _ = try await tokenCountUtility.processAudioContent(recordingSession, with: tokenParams)
        let _ = try await focusedSummarizationTool.processAudioContent(recordingSession, with: summaryParams)
        let _ = try await textChunkingTool.processAudioContent(recordingSession, with: chunkingParams)

        let executionTime = Date().timeIntervalSince(startTime)

        // Performance requirements: complete workflow under 500ms
        XCTAssertLessThan(executionTime, 0.5, "Complete workflow should execute within 500ms")

        // Verify audio domain preservation
        XCTAssertTrue(mockLogger.loggedMessages.contains { $0.contains("audio") || $0.contains("technical") })
    }

    func testMixingSessionDocumentationWorkflow() async throws {
        let mixingDocs = """
        MIXING SESSION DOCUMENTATION
        =========================

        Project: "Midnight City Lights" - The Midnight Echoes
        Mixing Engineer: John Smith
        Date: October 10, 2025
        Studio: Downtown Recording Studio

        TRACK INVENTORY
        ==============

        Lead Vocal (Track 1):
        - Recording: Neumann U87 → API 312 → dbx 160 → Pro Tools HD
        - Takes: 6 selected performances comped
        - Processing: EQ boost at 2kHz, HPF at 80Hz, dbx 160 compression

        Harmony Vocals (Tracks 2-4):
        - Recording: AKG C414 → Neve 1073 → Pro Tools HD
        - Processing: Same chain as lead vocal, gentler compression
        - Arrangement: Low, mid, high harmonies

        Electric Guitar (Track 5):
        - Recording: Shure SM57 on Marshall JCM800 amplifier
        - Mic Position: 1 inch from speaker cone, off-axis
        - Processing: Basic EQ during recording

        Bass Guitar (Track 6):
        - Recording: Direct input with SansAmp GT-2 pedal
        - Processing: SansAmp tube amp simulation
        - Performance: Single take, excellent timing

        MIXING PROCESS
        =============

        Phase 1: Rough Mix (10:00 AM - 11:30 AM)
        ---------------------------------

        Lead Vocal Processing:
        - EQ: SSL Channel Strip (emulated)
        - High-pass: 80Hz at 12dB/octave
        - Low-mid: Cut 200Hz by 3dB for mud reduction
        - Presence: Boost 2.5kHz by 2dB
        - Air: Boost 10kHz by 1.5dB
        - De-esser: Waves DeEsser, threshold -6dB, ratio 4:1

        Compression:
        - Plugin: Waves CLA-76 (LA-2A style)
        - Ratio: 4:1
        - Attack: 30ms (fast enough for vocals)
        - Release: 100ms (natural decay)
        - Threshold: -12dB (4-6dB of gain reduction)
        - Makeup: +6dB to restore level

        Effects:
        - Reverb: Valhalla VintageVerb Plate
        - Decay time: 2.2 seconds
        - Pre-delay: 30ms
        - Wet/Dry mix: 30%
        - Low-pass filter: 8kHz

        Phase 2: Instrument Integration (11:30 AM - 1:00 PM)
        ===========================================

        Bass Guitar Processing:
        - EQ: Pultec EQ (emulated)
        - Low-frequency: Boost at 60Hz by 2dB
        - Mid-range: Cut 400Hz by 2dB for clarity
        - High-frequency: Cut 3kHz by 1dB for smoothness
        - Compression: API 2500 (Tube style)
        - Ratio: 3:1
        - Attack: 50ms
        - Release: 200ms
        - Threshold: -15dB

        Electric Guitar Processing:
        - EQ: SSL E-Channel (emulated)
        - Low-frequency: High-pass at 100Hz
        - Mid-range: Cut 500Hz by 2dB (amp resonances)
        - High-frequency: Boost at 4kHz by 3dB (presence)
        - Distortion: Built-in amp overdrive
        - Reverb: Same as vocal (for cohesion)

        Phase 3: Mix Balance (1:00 PM - 2:30 PM)
        ================================

        Initial Balance:
        - Lead Vocal: -3dB (sitting slightly above center)
        - Bass Guitar: -6dB (supporting role)
        - Electric Guitar: -8dB (filling mid-range)
        - Reverb Sends: Adjusted for depth

        Automation Planning:
        - Vocal volume: Slight increase in choruses
        - Bass level: Consistent throughout
        - Guitar level: Reduce during vocal sections

        MASTERING NOTES
        ==============

        - Target loudness: -14 LUFS (Spotify compatible)
        - Peak levels: -1.0 dBTP (maximizing headroom)
        - Dynamic range: 12dB RMS
        - Stereo width: 100% (full stereo image)

        Client Requirements:
        - Keep vocals prominent but not harsh
        - Maintain low-end punch without mud
        - Ensure translation to small speakers
        - Prepare for Spotify and Apple Music distribution

        Quality Control:
        - A/B testing on multiple systems
        - Mono compatibility check
        - Phase correlation verification
        - Spectral analysis validation

        DELIVERY FORMATS:
        ================

        - Master: WAV 24-bit/96kHz
        - Streaming: WAV 16-bit/44.1kHz
        - Archive: FLAC lossless compression

        FINAL NOTES
        ==========

        Mix successfully completed on October 10, 2025.
        Client expressed complete satisfaction with results.
        Mix maintains professional quality while meeting all streaming platform requirements.
        Ready for distribution to digital platforms.
        """

        // Step 1: Comprehensive Token Analysis
        let tokenParams: [String: Any] = [
            "text": mixingDocs,
            "strategy": "mixed",
            "content_type": "technical_spec",
            "include_breakdown": true,
            "chunk_analysis": true
        ]

        let tokenResult = try await tokenCountUtility.processAudioContent(mixingDocs, with: tokenParams)

        XCTAssertFalse(tokenResult.isEmpty)
        XCTAssertTrue(tokenResult.contains("estimated") || tokenResult.lowercased().contains("token"))

        // Step 2: Technical Mix Summary
        let mixSummaryParams: [String: Any] = [
            "text": mixingDocs,
            "focus_areas": ["mixing", "technical", "equipment", "workflow"],
            "style": "technical",
            "max_points": 15
        ]

        let mixSummaryResult = try await focusedSummarizationTool.processAudioContent(mixingDocs, with: mixSummaryParams)

        XCTAssertFalse(mixSummaryResult.isEmpty)
        let summaryLower = mixSummaryResult.lowercased()
        XCTAssertTrue(summaryLower.contains("mixing"))
        XCTAssertTrue(summaryLower.contains("eq") || summaryLower.contains("compression"))
        XCTAssertTrue(summaryLower.contains("reverb"))
        XCTAssertTrue(summaryLower.contains("neumann") || summaryLower.contains("ssl"))

        // Step 3: Document Chunking
        let docChunkingParams: [String: Any] = [
            "text": mixingDocs,
            "strategy": "semantic",
            "max_chunk_size": 800,
            "preserve_audio_structure": true
        ]

        let docChunkingResult = try await textChunkingTool.processAudioContent(mixingDocs, with: docChunkingParams)

        XCTAssertFalse(docChunkingResult.isEmpty)
        XCTAssertTrue(docChunkingResult.contains("chunks"))

        // Step 4: Audio Domain Technical Analysis
        let techAnalysisParams: [String: Any] = [
            "text": mixingDocs,
            "focus_areas": ["technical", "equipment"],
            "style": "technical",
            "max_points": 10
        ]

        let techAnalysisResult = try await focusedSummarizationTool.processAudioContent(mixingDocs, with: techAnalysisParams)

        let techLower = techAnalysisResult.lowercased()
        let technicalTerms = ["eq", "compression", "reverb", "frequency", "khz", "db"]
        let termsFound = technicalTerms.filter { techLower.contains($0) }
        XCTAssertGreaterThan(termsFound.count, 0, "Should identify multiple technical terms")

        // Step 5: Workflow Performance Testing
        let workflowStartTime = Date()

        // Complete mixing documentation workflow
        let _ = try await tokenCountUtility.processAudioContent(mixingDocs, with: tokenParams)
        let _ = try await focusedSummarizationTool.processAudioContent(mixingDocs, with: mixSummaryParams)
        let _ = try await focusedSummarizationTool.processAudioContent(mixingDocs, with: techAnalysisParams)
        let _ = try await textChunkingTool.processAudioContent(mixingDocs, with: docChunkingParams)

        let workflowTime = Date().timeIntervalSince(workflowStartTime)

        // Workflow should complete within 300ms for documentation
        XCTAssertLessThan(workflowTime, 0.3, "Documentation workflow should complete within 300ms")
    }

    func testMultiTrackRecordingSession() async throws {
        let multiTrackSession = """
        MULTI-TRACK RECORDING SESSION LOG
        ============================

        Date: October 12, 2025
        Project: Acoustic Folk Album - Various Artists
        Engineer: Sarah Johnson
        Studio: Sunset Recording Studio

        TRACK 1 - ACOUSTIC GUITAR
        Artist: Mark Thompson
        Time: 10:00 AM - 11:30 AM

        Equipment Setup:
        - Primary: Martin D-28 (vintage 1974)
        - Mics: Neumann KM184 (pair), spaced 18 inches apart
        - Preamp: Focusrite Scarlett 2i2
        - Interface: Apollo Twin MkII
        - DAW: Logic Pro X

        Recording Details:
        - Tuning: Standard EADGBE
        - Position: Player seated, guitar on lap, mics 12 inches away
        - Take 1: Good performance, timing consistent 8/10
        - Take 2: Better dynamic control, emotional delivery 9/10
        - Take 3: **SELECTED** - Perfect balance of technique and emotion 10/10
        - Take 4: Alternative version, slightly different chord voicing 8/10
        - Takes 5-8: Variations for arrangement flexibility

        Processing Applied:
        - Minimal EQ (natural sound preservation)
        - Stereo image: Wide stereo from KM184 pair
        - Room Acoustics: Utilized natural room reverb

        TRACK 2 - LEAD VOCAL (PART 1)
        Artist: Lisa Chen
        Time: 12:00 PM - 2:00 PM

        Equipment Setup:
        - Microphone: AKG C414 XLII
        - Preamp: Universal Audio Apollo Twin MkII
        - Compressor: LA-610 MkII (optical)
        - Interface: Same as Track 1

        Recording Details:
        - Song: "Autumn Leaves" in G major
        - Microphone Position: 8 inches from source, slight angle
        - Take 1: Solid performance, minor pitch issues in second verse 7/10
        - Take 2: Better pitch control, emotional connection improved 8/10
        - Take 3: Excellent performance, great emotional delivery 9/10
        - Take 4: **SELECTED** - Beautiful tone, perfect for folk style 10/10
        - Takes 5-7: Variations for arrangement options

        Processing Applied:
        - EQ: Gentle presence boost at 3kHz
        - Compression: LA-610 with 3:1 ratio, medium attack
        - Added: Touch of plate reverb for space

        TRACK 3 - FIDDLE
        Artist: Mike O'Brien
        Time: 2:30 PM - 3:30 PM

        Equipment Setup:
        - Microphone: Royer R-121 (ribbon microphone)
        - Preamp: Universal Audio Apollo Twin MkII
        - Position: 8 inches from F-hole, angled towards player

        Recording Details:
        - Instrument: 1940s Gibson F-5 Mandolin
        - Playing Style: Traditional folk with contemporary elements
        - Take 1: Great tone, some noise from movement 7/10
        - Take 2: **SELECTED** - Excellent tone, quiet performance 10/10
        - Take 3: Different arrangement, also good tone 9/10

        Processing Applied:
        - EQ: Natural ribbon character preserved
        - Position: Centered in stereo image

        TRACK 4 - DOUBLE BASS
        Artist: Dave Wilson
        Time: 4:00 PM - 5:00 PM

        Equipment Setup:
        - Instrument: 1950s Fender Precision Bass
        - DI Box: Radial J48 active DI
        - Interface: Universal Audio Apollo Twin MkII
        - Amp: Ampeg SVT-VR (reissue)

        Recording Details:
        - Style: Root notes with occasional walks
        - Take 1: Solid performance, consistent timing 8/10
        - Take 2: **SELECTED** - Great groove, excellent timing 10/10
        - Take 3: Alternative runs for arrangement variety 9/10

        Processing Applied:
        - DI clean recording with amp re-amping later
        - Plan: Use Ampeg SVT for classic rock bass tone

        SESSION COMPLETION
        =================

        Total Recording Time: 7 hours
        Tracks Recorded: 4
        Selected Takes: 4
        Client Satisfaction: Excellent
        Next Session: Overdubs and additional arrangement

        Technical Notes:
        - Sample Rate: 48kHz (selected for acoustic warmth)
        - Bit Depth: 24-bit
        - Format: WAV files for maximum quality
        - Storage: 25GB of raw recording data
        - Backup: Dual-drive redundancy implemented

        Artist Feedback:
        "The acoustic sounds are amazing! The vintage equipment really captures the warmth.
        Everyone performed exceptionally well today. Looking forward to hearing the arrangements
        come together in the mix."

        Production Notes:
        - Consider room acoustic treatment for future sessions
        - Plan additional microphone options for tonal variety
        - Schedule arrangement session for track layering decisions
        - Budget tracking: On schedule within allocated $2,500
        """

        // Comprehensive multi-track analysis
        let analysisParams: [String: Any] = [
            "text": multiTrackSession,
            "focus_areas": ["recording", "equipment", "workflow"],
            "style": "executive",
            "max_points": 10
        ]

        let analysisResult = try await focusedSummarizationTool.processAudioContent(multiTrackSession, with: analysisParams)

        XCTAssertFalse(analysisResult.isEmpty)
        let resultLower = analysisResult.lowercased()

        // Verify multi-track session elements
        XCTAssertTrue(resultLower.contains("track") || resultLower.contains("recording"))
        XCTAssertTrue(resultLower.contains("equipment") || resultLower.contains("microphone"))
        XCTAssertTrue(resultLower.contains("artist") || resultLower.contains("performance"))

        // Test chunking for large session
        let chunkingParams: [String: Any] = [
            "text": multiTrackSession,
            "strategy": "paragraph",
            "max_chunk_size": 600
        ]

        let chunkingResult = try await textCountUtility.processAudioContent(multiTrackSession, with: chunkingParams)
        XCTAssertFalse(chunkingResult.isEmpty)
    }

    func testStudioClientCommunicationScenario() async throws {
        let clientCommunication = """
        CLIENT COMMUNICATION SUMMARY
        =========================

        Email Thread: Studio Booking & Requirements
        From: Sarah Johnson (manager@sunsetrecordingstudio.com)
        To: John Smith (engineer@studio.com)
        Date: October 8, 2025
        Subject: Recording Session - The Midnight Echoes

        Email Content:
        Hi John,

        Hope you're doing well! I wanted to confirm our upcoming recording session for The Midnight Echoes.

        Details:
        - Project: "Electric Dreams" album
        - Dates: October 8-10, 2025
        - Times: 9:00 AM - 6:00 PM daily
        - Studio: Downtown Recording Studio, Room A
        - Budget: $4,500 allocated for tracking phase

        Artist Requirements:
        - Lead vocalist: Emily Johnson
        - Contact: emily@midnightechoes.com, 555-123-4567
        - Special requests: Neumann U87 microphone preferred, vintage analog sound

        Equipment Needs:
        - High-end vocal microphone chain
        - Professional console (SSL or Neve preferred)
        - Quality preamps for warmth
        - Pro Tools HD system with latest plugins

        Client Vision:
        Want classic rock sound with modern clarity. Looking for professional recording
        that captures the emotional intensity of their songs while maintaining excellent
        technical quality suitable for streaming platforms.

        Budget Discussion:
        Initial budget of $4,500 for tracking phase. Additional budget available for
        mixing if results are satisfactory. Will discuss mixing requirements after hearing
        rough mixes.

        Please confirm availability and provide any equipment recommendations or
        setup suggestions.

        Best regards,
        Sarah Johnson
        Manager
        Sunset Recording Studio

        Phone: 555-987-6543

        -- Original Message --

        Reply: Studio Confirmation and Setup
        From: John Smith (engineer@studio.com)
        To: Sarah Johnson (manager@sunsetrecordingstudio.com)
        Date: October 8, 2025
        Subject: Re: Recording Session - The Midnight Echoes

        Email Content:
        Hi Sarah,

        Great to hear from you! I'm excited about working with The Midnight Echoes.

        Studio Availability:
        - Room A available for October 8-10
        - SSL G-Series console booked and ready
        - Neumann U87 microphone available and calibrated
        - API 312 preamps warmed up and ready
        - Pro Tools HD system updated with latest plugins

        Equipment Recommendations:
        Microphone Chain:
        - Primary: Neumann U87 (available)
        - Preamp: API 312 (warm, vintage character)
        - Console: SSL G-Series (industry standard)
        - Converters: Apollo Twin MkII (high-quality AD/DA)

        Plugin Arsenal:
        - Waves: CLA-76, H-Delay, H-Reverb, SSL Channel Strip
        - UAD: LA-2A, Pultec EQ, Neve 1073
        - Valhalla: VintageVerb, VintageVerb
        - Plugin Alliance: Maag EQ4, SPL De-Verb

        Session Plan:
        Day 1: Lead vocal tracking with harmonies
        Day 2: Instrument overdubs (guitars, bass)
        Day 3: Rough mixes and client feedback

        Budget Confirmation:
        $4,500 for tracking phase is reasonable and within studio rates.
        Additional mixing costs depend on complexity:
        - Basic mix: $1,500-2,000
        - Advanced mix: $2,500-3,500
        - Mastering: $800-1,200

        I'll ensure we capture the emotional intensity you're looking for while maintaining the
        technical quality needed for modern streaming platforms.

        Looking forward to a productive session!

        Best regards,
        John Smith
        Lead Engineer
        Downtown Recording Studio

        Contact Info:
        Phone: 555-456-7890
        Studio Address: 123 Music Street, Studio A

        -- End Communication --

        Final Confirmation:
        Studio and artist confirmed for October 8-10.
        Equipment setup scheduled for 8:00 AM on first day.
        Contract and payment arrangements completed.
        All requirements documented and agreed upon.

        Post-Session Summary:
        Session successfully completed as planned.
        Artist extremely satisfied with recording quality.
        Within budget with professional results achieved.
        Client has requested mixing services for next phase.

        Technical Achievements:
        - Recorded 12 tracks across 3 days
        - Captured 8 lead vocal performances with harmonies
        - Multiple instrument overdubs completed
        - All audio recorded at 96kHz/24-bit quality
        - Professional SSL console workflow implemented
        - Vintage analog equipment character preserved
        """

        // Test token counting for long communication thread
        let tokenParams: [String: Any] = [
            "text": clientCommunication,
            "strategy": "word_based",
            "content_type": "general"
        ]

        let tokenResult = try await tokenCountUtility.processAudioContent(clientCommunication, with: tokenParams)
        XCTAssertFalse(tokenResult.isEmpty)

        // Test summarization of client communication
        let summaryParams: [String: Any] = [
            "text": clientCommunication,
            "focus_areas": ["production", "workflow", "budget"],
            "style": "executive",
            "max_points": 8
        ]

        let summaryResult = try await focusedSummarizationTool.processAudioContent(clientCommunication, with: summaryParams)

        XCTAssertFalse(summaryResult.isEmpty)
        let summaryLower = summaryResult.lowercased()
        XCTAssertTrue(summaryLower.contains("client") || summaryLower.contains("communication"))
        XCTAssertTrue(summaryLower.contains("budget") || summaryLower.contains("cost"))

        // Test chunking for reference documentation
        let chunkingParams: [String: Any] = [
            "text": clientCommunication,
            "strategy": "paragraph",
            "max_chunk_size": 500
        ]

        let chunkingResult = try await textChunkingTool.processAudioContent(clientCommunication, with: chunkingParams)
        XCTAssertFalse(chunkingResult.isEmpty)
    }

    // MARK: - Performance and Stress Tests

    func testLargeContentProcessingPerformance() async throws {
        // Create a large session notes document (simulating multiple sessions)
        let largeSession = String(repeating: """
        EXTENDED RECORDING SESSION - Professional Audio Production Pipeline
        ===========================================

        Equipment Inventory:
        - Microphones: Neumann U87, AKG C414, Shure SM57, Sennheiser 421
        - Preamps: API 312, Neve 1073, SSL Channel Strips, Focusrite Scarlett
        - Console: SSL G-Series, Neve 88R, Yamaha PM5D, Allen & Heath GLD-80
        - DAWs: Pro Tools HD, Logic Pro X, Cubase Pro, Nuendo
        - Plugins: Waves CLA-76, UAD LA-2A, Valhalla VintageVerb, Plugin Alliance

        Technical Specifications:
        - Sample Rates: 44.1kHz, 48kHz, 88.2kHz, 96kHz, 192kHz
        - Bit Depths: 16-bit, 24-bit, 32-bit float
        - File Formats: WAV, AIFF, FLAC, MP3, M4A, OGG
        - Buffer Sizes: 64, 128, 256, 512, 1024, 2048

        Processing Chain Details:
        - Input Stage: Microphone → Preamp → ADC → DAW
        - Processing Stage: EQ → Compression → Effects → Automation
        - Output Stage: Summing → Mastering → DAC → Monitoring

        Session Workflow:
        1. Setup and calibration (60 minutes)
        2. Microphone placement and testing (30 minutes)
        3. Artist performance recording (3-4 hours)
        4. Take evaluation and selection (30 minutes)
        5. Basic processing and rough mix (1 hour)
        6. Client review and feedback (30 minutes)
        7. Final adjustments and delivery (30 minutes)

        Quality Control:
        - Level monitoring throughout recording
        - Phase correlation checking
        - Spectral analysis validation
        - Peak level optimization
        - Dynamic range preservation
        Noise floor minimization

        """, count: 10)

        let startTime = Date()

        // Process large content with all tools
        let tokenParams: [String: Any] = [
            "text": largeSession,
            "strategy": "mixed",
            "content_type": "technical_spec",
            "chunk_analysis": true
        ]

        let tokenResult = try await tokenCountUtility.processAudioContent(largeSession, with: tokenParams)
        XCTAssertFalse(tokenResult.isEmpty)

        let summaryParams: [String: Any] = [
            "text": largeSession,
            "focus_areas": ["technical", "equipment", "workflow"],
            "style": "bullet",
            "max_points": 20
        ]

        let summaryResult = try await focusedSummarizationTool.processAudioContent(largeSession, with: summaryParams)
        XCTAssertFalse(summaryResult.isEmpty)

        let chunkingParams: [String: Any] = [
            "text": largeSession,
            "strategy": "semantic",
            "max_chunk_size": 1500
        ]

        let chunkingResult = try await textChunkingTool.processAudioContent(largeSession, with: chunkingParams)
        XCTAssertFalse(chunkingResult.isEmpty)

        let executionTime = Date().timeIntervalSince(startTime)

        // Large content should still process within 500ms
        XCTAssertLessThan(executionTime, 0.5, "Large content processing should complete within 500ms")
    }

    func testConcurrentToolExecution() async throws {
        let sessionContent = """
        CONCURRENT PROCESSING TEST
        =====================

        This test validates that multiple tools can run concurrently without conflicts,
        simulating a real-world scenario where multiple operations might be needed simultaneously.

        Audio Content:
        - Recording session with Neumann U87 microphone
        - SSL G-Series console for mixing
        - Waves CLA-76 compression processing
        - Pro Tools HD at 96kHz/24-bit

        Performance Requirements:
        - All tools should execute independently
        - No resource conflicts or memory leaks
        - Consistent performance under load
        - Proper error isolation between tools
        """

        // Create concurrent tasks
        let tokenTask = Task {
            let params: [String: Any] = [
                "text": sessionContent,
                "strategy": "audio_optimized"
            ]
            return try await self.tokenCountUtility.processAudioContent(sessionContent, with: params)
        }

        let summaryTask = Task {
            let params: [String: Any] = [
                "text": sessionContent,
                "focus_areas": ["recording", "technical"],
                "style": "bullet"
            ]
            return try await self.focusedSummarizationTool.processAudioContent(sessionContent, with: params)
        }

        let chunkingTask = Task {
            let params: [ [String: Any] = [
                "text": sessionContent,
                "strategy": "paragraph",
                "max_chunk_size": 300
            ]
            return try await self.textChunkingTool.processAudioContent(sessionContent, with: params)
        }

        // Execute all tasks concurrently
        async let results = try await [tokenTask, summaryTask, chunkingTask]

        // Verify all tasks completed successfully
        for result in results {
            XCTAssertFalse(result.isEmpty, "All concurrent tasks should produce non-empty results")
        }
    }

    // MARK: - Edge Case and Error Handling Tests

    func testMinimalContentHandling() async throws {
        let minimalContent = "Brief note: Used Neumann U87, good take."

        // Test with minimal content
        let tokenParams: [String: Any] = [
            "text": minimalContent,
            "strategy": "character_based"
        ]

        let tokenResult = try await tokenCountUtility.processAudioContent(minimalContent, with: tokenParams)
        XCTAssertFalse(tokenResult.isEmpty)

        let summaryParams: [String: Any] = [
            "text": minimalContent,
            "focus_areas": ["technical"],
            "style": "bullet",
            "max_points": 3
        ]

        let summaryResult = try await focusedSummarizationTool.processAudioContent(minimalContent, with: summaryParams)
        XCTAssertFalse(summaryResult.isEmpty)
    }

    func testSpecialCharacterHandling() async throws {
        let specialCharContent = """
        Special Characters & Symbols in Audio:

        • Frequency: 2kHz (2,000 Hz)
        • Levels: -12dBFS (digital full scale)
        • Sample Rate: 96kHz (96,000 Hz)
        • Bit Depth: 24-bit
        • Ratio: 4:1 compression

        Musical Symbols:
        ♪ Sharp, ♭ Flat, ♮ Natural
        Major: C, D, E, F, G, A, B
        Minor: Am, Em, Fm, Gm, Dm, Em

        Audio Brands:
        Neumann® • AKG • Shure • SSL • API
        Waves™ • UAD • Valhalla • Plugin Alliance

        Technical Notation:
        dBFS • kHz • BPM • RMS • LUFS
        Hz • ms • ms (milliseconds)
        """

        // Test that special characters don't break processing
        let tokenParams: [String: Any] = [
            "text": specialCharContent,
            "strategy": "word_based"
        ]

        let tokenResult = try await tokenCountUtility.processAudioContent(specialCharContent, with: tokenParams)
        XCTAssertFalse(tokenResult.isEmpty)

        let summaryParams: [String: Any] = [
            "text": specialCharContent,
            "focus_areas": ["technical"],
            "style": "bullet",
            "preserve_technical_terms": true
        ]

        let summaryResult = try await focusedSummarizationTool.processAudioContent(specialCharContent, with: summaryParams)
        XCTAssertFalse(summaryResult.isEmpty)

        // Should preserve technical symbols
        let resultLower = summaryResult.lowercased()
        XCTAssertTrue(resultLower.contains("khz") || resultLower.contains("db"))
    }

    // MARK: - Real-World Simulation Tests

    func testStudioDaySimulation() async throws {
        // Simulate a complete studio day workflow
        let dailySessions = [
            ("Morning Setup", """
            STUDIO MORNING SETUP - 8:00 AM
            ===========================

            Equipment Warm-up:
            - SSL G-Series console: 30 minutes to initialize
            - Neumann U87: 15 minutes to stabilize
            - API 312 preamps: 10 minutes each
            - Pro Tools HD: 5 minutes to load session

            Room Preparation:
            - Vocal booth acoustic treatment verification
            - Monitor calibration completed
            - headphone levels checked
            - talkback system tested

            First Artist: Emily Johnson arrives at 8:45 AM.
            """),

            ("Recording Session", """
            LEAD VOCAL RECORDING - 10:30 AM
            ================================

            Artist: Emily Johnson
            Song: "City Lights"
            Microphone: Neumann U87, positioned 8 inches from source

            Performance:
            - Take 1: Good start, some pitch issues in chorus
            - Take 2: Better control, emotional delivery improved
            - Take 3: **SELECTED** - Perfect balance achieved
            - Client: "That's the one! Beautiful emotion and control"

            Processing:
            - Applied EQ boost at 2kHz for presence
            - Added gentle compression for consistency
            - Recorded to Pro Tools HD at 96kHz/24-bit

            Artist Feedback:
            "I love how this captures the emotion of the song!"

            Status: Track 1 complete, moving to harmony vocals.
            """),

            ("Afternoon Session", """
        HARMONY AND OVERDUBS - 2:30 PM
        ==================================

        Three-part harmony vocals recorded using AKG C414.
        Bass guitar tracked using direct input with SansAmp.
        Electric guitar overdubs planned for tomorrow.

        Client Review:
        "Amazing progress! The vocal sounds incredible.
        Can't wait to hear the full arrangement."

        Next Steps:
        - Tomorrow: Electric guitar and final overdubs
        - Friday: Mixing session begins
        """)
        ]

        // Process each session segment
        for (sessionName, content) in dailySessions {
            let tokenParams: [String: Any] = [
                "text": content,
                "strategy": "audio_optimized",
                "content_type": "session_notes"
            ]

            let _ = try await tokenCountUtility.processAudioContent(content, with: tokenParams)

            let summaryParams: [String: Any] = [
                "text": content,
                "focus_areas": ["recording", "workflow"],
                "style": "bullet",
                "max_points": 5
            ]

            let _ = try await focusedSummarizationTool.processAudioContent(content, with: summaryParams)
        }
    }

    // MARK: - Data Quality and Consistency Tests

    func testDataConsistencyAcrossTools() async throws {
        let testContent = """
        Professional audio session with Neumann U87 microphone through API 312 preamp.
        SSL G-Series console for mixing, Waves CLA-76 compression.
        Recorded in Pro Tools HD at 96kHz/24-bit resolution.
        Client: Major Record Label, Contact: label@a&mrecord.com.
        Budget: $10,000 for complete production.
        """

        // All tools should recognize the same audio terminology
        let audioTerms = ["neumann", "api", "ssl", "waves", "pro tools"]

        // Test Token Counting
        let tokenParams: [String: Any] = [
            "text": testContent,
            "strategy": "audio_optimized"
        ]

        let tokenResult = try await tokenCountUtility.processAudioContent(testContent, with: tokenParams)
        let tokenLower = tokenResult.lowercased()

        // Test Summarization
        let summaryParams: [String: Any] = [
            "text": testContent,
            "focus_areas": ["equipment", "technical"],
            "style": "bullet"
        ]

        let summaryResult = try await focusedSummarizationTool.processAudioContent(testContent, with: summaryParams)
        let summaryLower = summaryResult.lowercased()

        // Verify consistency across tools
        for term in audioTerms {
            XCTAssertTrue(
                tokenLower.contains(term) || summaryLower.contains(term),
                "Audio term '\(term)' should be recognized by tools"
            )
        }
    }

    func testErrorRecoveryAndGracefulDegradation() async throws {
        let problematicContent = """
        Audio session with problematic sections:

        GOOD CONTENT:
        Professional recording session using Neumann U87 microphone.
        SSL G-Series console for mixing with Waves CLA-76 compression.
        Recorded at 96kHz/24-bit in Pro Tools HD.

        PROBLEMATIC SECTION:
        <corrupted-data>
        This section contains invalid characters and formatting that might cause issues.
        [MALFORMED_JSON{"invalid": structure}

        RECOVERY CONTENT:
        Session continued successfully after fixing formatting issues.
        Applied EQ and compression as planned.
        """

        // Tools should handle problematic content gracefully
        do {
            let tokenParams: [String: Any] = [
                "text": problematicContent,
                "strategy": "character_based"
            ]

            let tokenResult = try await tokenCountUtility.processAudioContent(problematicContent, with: tokenParams)

            // Should not crash and should provide some result
            XCTAssertFalse(tokenResult.isEmpty, "Should handle problematic content gracefully")
        } catch {
            // Error is acceptable for severely malformed content
            // Tool should not crash the entire system
            XCTAssertTrue(error is AudioProcessingError)
        }

        do {
            let summaryParams: [String: Any] = [
                "text": problematicContent,
                "focus_areas": ["technical"],
                "style": "bullet"
            ]

            let summaryResult = try await focusedSummarizationTool.processAudioContent(problematicContent, with: summaryParams)

            // Should attempt to provide summary even with some issues
            XCTAssertFalse(summaryResult.isEmpty, "Should provide summary despite issues")
        } catch {
            // Error is acceptable for severely malformed content
            XCTAssertTrue(error is AudioProcessingError)
        }
    }
}

// MARK: - Enhanced Mock Classes

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
    var shouldRejectPII = false

    override func validateInput(_ input: String) throws {
        if shouldReject {
            throw SecurityError.unauthorizedAccess
        }
        if shouldRejectPII && (input.contains("@") || input.contains("555-")) {
            throw SecurityError.sensitiveData
        }
    }

    override func validateOutput(_ output: String) throws {
        // Allow all output by default
    }
}