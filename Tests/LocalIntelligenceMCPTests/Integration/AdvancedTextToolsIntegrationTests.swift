//
//  AdvancedTextToolsIntegrationTests.swift
//  LocalIntelligenceMCPTests
//
//  Created on 2025-10-08.
//

import XCTest
@testable import LocalIntelligenceMCP

/// Integration tests for advanced text tools using real-world audio session data
/// These tests verify that the tools work together correctly and maintain
/// audio domain awareness throughout the processing pipeline.
final class AdvancedTextToolsIntegrationTests: XCTestCase {

    // MARK: - Test Properties

    var focusedTool: FocusedSummarizationTool!
    var chunkingTool: TextChunkingTool!
    var tokenTool: TokenCountUtility!
    var piiRedactionTool: PIIRedactionTool!
    var mockLogger: MockLogger!
    var mockSecurityManager: MockSecurityManager!

    // MARK: - Test Lifecycle

    override func setUp() async throws {
        try await super.setUp()
        mockLogger = MockLogger()
        mockSecurityManager = MockSecurityManager()
        
        focusedTool = FocusedSummarizationTool(
            logger: mockLogger,
            securityManager: mockSecurityManager
        )
        chunkingTool = TextChunkingTool(
            logger: mockLogger,
            securityManager: mockSecurityManager
        )
        tokenTool = TokenCountUtility(
            logger: mockLogger,
            securityManager: mockSecurityManager
        )
        piiRedactionTool = PIIRedactionTool(
            logger: mockLogger,
            securityManager: mockSecurityManager
        )
    }

    override func tearDown() async throws {
        focusedTool = nil
        chunkingTool = nil
        tokenTool = nil
        piiRedactionTool = nil
        mockLogger = nil
        mockSecurityManager = nil
        try await super.tearDown()
    }

    // MARK: - Real-World Audio Session Tests

    func testCompleteAudioSessionWorkflow() async throws {
        let realSessionNotes = """
        SESSION NOTES - The Midnight Echoes
        Album: Electric Dreams
        Date: October 8, 2025
        Engineer: John Smith (john.smith@studiopro.com, 555-123-4567)
        Producer: Sarah Johnson (sarah@musicpro.com, 555-987-6543)
        Studio: Downtown Recording Studio (123 Music Street, Studio B, Los Angeles, CA 90210)
        Client Budget: $15,000
        
        SESSION SETUP (9:00 AM - 10:00 AM)
        - Vocal booth: Neumann U87 microphone, API 312 preamp, dbx 160 compressor
        - Control room: SSL G-Series console with automation
        - DAW: Pro Tools HD 12.8.3 at 96kHz/24-bit
        - Monitoring: Genelec 8030 speakers, calibrated to 85dB SPL
        - Clock: Antelope Audio Trinity, master clock
        
        TRACKING SESSION (10:00 AM - 4:00 PM)
        
        [TRACK 1 - LEAD VOCAL]
        Microphone: Neumann U87 (selected for warmth and clarity)
        Preamp: API 312 (provides 70dB gain, clean and punchy)
        Compression: dbx 160 VCA compressor, 4:1 ratio, -10dB threshold
        EQ: Pultec EQP-1A hardware emulator plugin
        Processing: Waves CLA-76 for additional character
        
        Takes recorded:
        Take 1: Good start, slight pitch issues in bridge
        Take 2: Better emotional delivery, timing improved
        Take 3: Solid performance, usable
        Take 4: Excellent, slight breath noise at end of phrase
        Take 5: Best performance overall - SELECTED
        Take 6: Alternative take for variety
        Take 7: Slightly rushed, rejected
        Take 8: Performance issues, rejected
        
        Lead vocal processing chain:
        Neumann U87 → API 312 → dbx 160 → Pultec EQP-1A → Pro Tools HD
        Additional processing: Waves CLA-76 (character), UAD Lexicon 224XL reverb
        
        Notes: Vocalist Sarah requested warmer, more intimate sound. Added gentle tube saturation using Waves Abbey Road RS127. Final sound achieved perfect balance between clarity and warmth.
        
        [TRACK 2 - BACKING VOCALS]
        High Harmony (3 parts): Takes 1-4, all usable, comped from best sections
        Low Harmony (3 parts): Takes 1-3, take 3 selected
        Processing: Same chain as lead vocal but with less compression
        
        [TRACK 3 - ACOUSTIC GUITAR]
        Microphone: AKG C414 (selected for natural sound)
        Preamp: Neve 1073 (adds warmth and character)
        Position: 12th fret, fingerpicking style
        Takes: 2 takes, take 1 selected for cleaner performance
        
        [TRACK 4 - ELECTRIC GUITAR CLEAN]
        Guitar: Gibson Les Paul Standard 2019
        Amp: Fender Twin Reverb (clean channel)
        Microphone: Shure SM57 (positioned 1 inch from speaker cone)
        Takes: 3 takes, comped best sections from all
        
        [TRACK 5 - ELECTRIC GUITAR CRUNCH]
        Guitar: Fender Telecaster
        Amp: Marshall JCM800 2203 (gain channel)
        Microphone: Sennheiser 421 (dynamic, good for high-gain amps)
        Takes: 4 takes, take 3 selected for aggressive tone
        
        [TRACK 6 - BASS GUITAR]
        Method: Direct Input
        Preamp: Focusrite ISA One (warm tube simulation)
        Processing: Ampeg SVT-VR plugin for authentic tube tone
        Takes: 2 takes, take 1 selected
        
        [TRACK 7 - DRUMS - ALREADY TRACKED]
        Note: Drums were tracked in previous session with full microphone setup
        Drum Microphones:
        - Overheads: Neumann KM 184 (pair)
        - Kick: AKG D112
        - Snare: Shure SM57 (top), Sennheiser 421 (bottom)
        - Toms: Sennheiser 421 (x3)
        - Hi-hat: AKG C451 B
        - Room: AKG C414 (for ambiance)
        
        TECHNICAL DETAILS
        Sample Rate: 96,000 Hz
        Bit Depth: 24-bit
        File Format: WAV (broadcast quality)
        Total Tracks: 7 (excluding drum stems)
        Total Session Time: 7 hours including setup and breakdown
        
        ISSUES ENCOUNTERED
        11:30 AM: Vocalist throat discomfort - took 15-minute break, provided warm water
        2:15 PM: Marshall amp tube noise - switched to backup amp (similar sound, no issues)
        3:45 PM: Pro Tools crash - restarted, no data loss, project recovered successfully
        
        CLIENT FEEDBACK
        - Extremely happy with lead vocal performances (takes 5 and 6 were excellent)
        - Loves the guitar tone variety (clean vs crunch)
        - Wants more presence in the bass in final mix
        - Satisfied with overall recording quality and professional setup
        
        ARTISTIC DIRECTION
        Producer Sarah requested:
        - Intimate, emotional vocal delivery (achieved)
        - Wall of guitars effect in chorus sections
        - Classic rock sound with modern production quality
        - Strong vocal presence in mix
        
        MIXING NOTES (FOR UPCOMING SESSION)
        - Start with rhythm section foundation
        - Lead vocal should be prominent but sit well in mix
        - Backing vocals need to support without overwhelming
        - Guitar panning: clean panned left 70%, crunch right 70%
        - Bass should be centered with some low-mid warmth
        
        DELIVERABLES
        - All raw audio files (96kHz/24-bit WAV)
        - Session documentation and track sheets
        - Rough mix by Friday, October 10th
        - Final mix by Wednesday, October 15th
        - Mastering ready by Friday, October 17th
        
        NEXT SESSIONS SCHEDULED
        Wednesday, October 9: Piano tracking and Hammond organ
        Thursday, October 10: Rough mix presentation and feedback
        Monday, October 13: Client review and mix revisions
        Wednesday, October 15: Final mix approval
        Friday, October 17: Mastering session
        
        EQUIPMENT LIST
        Microphones: Neumann U87, AKG C414, Shure SM57, Sennheiser 421, AKG D112, AKG C451 B, Neumann KM 184
        Preamps: API 312, Neve 1073, Focusrite ISA One
        Outboard: dbx 160, Pultec EQP-1A, Lexicon 224XL
        Plugins: Waves CLA-76, UAD Pultec, UAD Lexicon 224XL, Waves Abbey Road RS127
        Console: SSL G-Series with full automation
        DAW: Pro Tools HD 12.8.3
        
        SESSION STATISTICS
        Setup Time: 1 hour
        Recording Time: 6 hours
        Breakdown Time: 30 minutes
        Total Session Cost: $1,200
        Tracks Recorded: 7
        Total Takes: 25
        Client Satisfaction: 10/10
        
        SESSION CONCLUSION
        Highly successful recording session with excellent performances from all musicians. Technical setup provided professional results with no compromises in quality. All equipment performed flawlessly. The session achieved all artistic goals and exceeded client expectations. Ready to proceed with mixing phase.
        """

        // Step 1: Analyze token count and complexity
        let tokenParams: [String: Any] = [
            "text": realSessionNotes,
            "strategy": "audio_optimized",
            "content_type": "session_notes",
            "include_breakdown": true,
            "include_audio_domain_insights": true
        ]

        let tokenResult = try await tokenTool.processAudioContent(realSessionNotes, with: tokenParams)
        XCTAssertFalse(tokenResult.isEmpty)

        // Step 2: Create focused summary for different stakeholders
        let executiveSummaryParams: [String: Any] = [
            "text": realSessionNotes,
            "focus_areas": ["workflow", "production"],
            "style": "executive",
            "max_points": 6
        ]

        let executiveSummary = try await focusedTool.processAudioContent(realSessionNotes, with: executiveSummaryParams)
        XCTAssertFalse(executiveSummary.isEmpty)
        XCTAssertTrue(executiveSummary.count < realSessionNotes.count / 10) // Executive summary should be much shorter

        let technicalSummaryParams: [String: Any] = [
            "text": realSessionNotes,
            "focus_areas": ["technical", "equipment"],
            "style": "technical",
            "max_points": 10
        ]

        let technicalSummary = try await focusedTool.processAudioContent(realSessionNotes, with: technicalSummaryParams)
        XCTAssertFalse(technicalSummary.isEmpty)
        XCTAssertTrue(technicalSummary.lowercased().contains("neumann") || technicalSummary.lowercased().contains("api"))

        // Step 3: Chunk content for processing workflows
        let chunkingParams: [String: Any] = [
            "text": realSessionNotes,
            "strategy": "audio_session",
            "max_chunk_size": 800,
            "preserve_audio_structure": true,
            "include_metadata": true
        ]

        let chunkingResult = try await chunkingTool.processAudioContent(realSessionNotes, with: chunkingParams)
        XCTAssertFalse(chunkingResult.isEmpty)
        XCTAssertTrue(chunkingResult.contains("chunks"))

        // Step 4: PII redaction for sharing with external team
        let piiParams: [String: Any] = [
            "text": realSessionNotes,
            "mode": "replace",
            "categories": ["email", "phone", "address", "financial"],
            "preserve_audio_terms": true,
            "sensitivity": "medium"
        ]

        let piiResult = try await piiRedactionTool.processAudioContent(realSessionNotes, with: piiParams)
        XCTAssertFalse(piiResult.isEmpty)
        // Should redact PII but preserve audio terms
        XCTAssertFalse(piiResult.contains("john.smith"))
        XCTAssertTrue(piiResult.lowercased().contains("neumann"))
        XCTAssertTrue(piiResult.lowercased().contains("api"))
    }

    func testTranscriptProcessingWorkflow() async throws {
        let realTranscript = """
        Interview with Producer Sarah Johnson about "Electric Dreams" Album
        
        Interviewer: Sarah, congratulations on the successful recording sessions for "Electric Dreams". How did the project come together?
        
        Producer: Thank you! "Electric Dreams" has been a real passion project for us. The band, The Midnight Echoes, has been working on these songs for about a year now. We started pre-production in January, spending three months refining arrangements and experimenting with different sonic approaches. The recording itself took place over three weekends in March and April.
        
        Interviewer: What were some of the key technical decisions you made during the recording process?
        
        Producer: For vocals, we chose the Neumann U87 microphone through an API 312 preamp. That combination gives us this beautiful warmth and presence that really suits our lead vocalist's voice. We added a dbx 160 for gentle compression - just enough to control dynamics without killing the natural expression. The Pultec EQP-1A was crucial for adding that classic analog warmth.
        
        For guitars, we used a combination of authentic vintage and modern equipment. The clean rhythm tracks went through a Fender Twin Reverb with a Shure SM57, which gave us that classic Fender clean tone. For the crunch tracks, we used a Marshall JCM800 - that thing really sings when you push it. We recorded both amps simultaneously to give us mixing options later.
        
        Interviewer: How did you handle the mixing approach for this album?
        
        Producer: We're planning to start mixing this week. My approach will be to build from the rhythm section up, ensuring we have a solid foundation. The lead vocal will be the star of the show - it has such emotional weight in these songs. The backing vocals need to support without overwhelming. We'll use the SSL G-Series console for its automation capabilities and analog summing for that final touch of analog warmth.
        
        Interviewer: What plugins and processing techniques are you planning to use in the mix?
        
        Producer: We've been using a lot of the Waves plugins during recording and they sound fantastic. The CLA-76 for vocal compression, the Abbey Road RS127 for tube saturation, and the UAD Pultec for EQ. For reverb, I'm thinking Valhalla VintageVerb for the plates and maybe some Soundtoys effects for creative elements. The goal is to maintain that organic, analog feel while using modern tools for precision.
        
        Interviewer: How do you balance artistic vision with technical requirements in your production?
        
        Producer: That's the eternal challenge, isn't it? For this album, the artistic vision was very clear - we wanted a modern rock sound with classic recording techniques. The band wanted the warmth and character of vintage gear but with the clarity and precision of modern digital workflows. We tracked at 96kHz/24-bit to give us maximum flexibility in mixing. The SSL console gives us that analog summing option for the final mix, which can add that last bit of magic.
        
        Interviewer: What role did the client feedback play in shaping the final sound?
        
        Producer: Our clients, the band members, were very involved throughout the process. They had clear ideas about what they wanted to achieve sonically. During vocal tracking, the lead vocalist specifically requested more warmth and intimacy, which influenced our microphone and processing choices. When we were tracking guitars, the guitarist wanted both clean and crunch options, so we recorded both simultaneously. This client involvement really helped us nail the sounds they were hearing in their heads.
        
        Interviewer: Can you talk about any challenges you faced and how you overcame them?
        
        Producer: We did encounter a few technical challenges, as you always do with recording. The Marshall amp had some tube noise during one session - we just switched to our backup amp and continued. The most significant challenge was when Pro Tools crashed mid-session, but we had good backups and didn't lose any data. We also had to work around some scheduling conflicts, but that's just part of professional recording work.
        
        Interviewer: What are your thoughts on the current state of audio production technology?
        
        Producer: It's an exciting time to be in audio production. We have access to incredible tools - both hardware and software. The line between analog and digital continues to blur in interesting ways. We can get 80% of the vintage analog sound with 20% of the digital workflow cost and time investment. The key is knowing when to use each approach and understanding your artists' aesthetic goals.
        
        Interviewer: What advice would you give to aspiring producers and engineers?
        
        Producer: First and foremost, develop your ears. Technology is important, but your ears are your most valuable tool. Spend time listening to great recordings and understanding what makes them work. Second, learn your craft deeply - understand microphone techniques, preamp characteristics, and how different processing affects sound. Third, always prioritize the music and the artists over technical perfection. The best recordings serve the song, not the other way around.
        
        Interviewer: What's next for this project?
        
        Producer: We start mixing this week. I'm really looking forward to hearing how all these elements come together. We'll present a rough mix to the band on Friday for their feedback. Based on their input, we'll make revisions and then move toward final mix approval. The mastering engineer is already booked for mid-October. We're hoping to have the completed album ready for release by the end of October.
        
        Interviewer: Any final thoughts on "Electric Dreams"?
        
        Producer: This album represents a real labor of love for everyone involved. The Midnight Echoes have poured their hearts into these songs, and as a producer, my job is to help them realize their vision to the fullest. The combination of vintage gear, modern techniques, and passionate performances creates something really special. I think people are going to connect with the authenticity and emotion that comes through in these recordings.
        
        Interviewer: Thank you so much for sharing your insights with us.
        
        Producer: Thank you! It's been a pleasure talking about this project. We're excited to share it with the world soon.
        
        Recording Date: October 8, 2025
        Interview Location: Downtown Recording Studio, Los Angeles, CA
        Interviewer: Audio Production Magazine
        Producer: Sarah Johnson, Independent Producer
        
        Contact Information:
        Sarah Johnson
        Email: sarah.johnson@musicpro.com
        Phone: 555-987-6543
        Website: www.sarahjohnsonmusic.com
        Instagram: @sarahjohnson_producer
        """

        // Step 1: Analyze transcript complexity and token count
        let tokenParams: [String: Any] = [
            "text": realTranscript,
            "strategy": "semantic_aware",
            "content_type": "transcript",
            "include_breakdown": true
        ]

        let tokenResult = try await tokenTool.processAudioContent(realTranscript, with: tokenParams)
        XCTAssertFalse(tokenResult.isEmpty)

        // Step 2: Create focused summaries for different purposes
        let technicalSummaryParams: [String: Any] = [
            "text": realTranscript,
            "focus_areas": ["technical", "equipment"],
            "style": "technical",
            "max_points": 12
        ]

        let technicalSummary = try await focusedTool.processAudioContent(realTranscript, with: technicalSummaryParams)
        XCTAssertFalse(technicalSummary.isEmpty)

        // Step 3: Create executive summary for business stakeholders
        let executiveSummaryParams: [String: Any] = [
            "text": realTranscript,
            "focus_areas": ["production", "workflow"],
            "style": "executive",
            "max_points": 8
        ]

        let executiveSummary = try await focusedTool.processAudioContent(realTranscript, with: executiveSummaryParams)
        XCTAssertFalse(executiveSummary.isEmpty)

        // Step 4: PII redaction for public sharing
        let piiParams: [String: Any] = [
            "text": realTranscript,
            "mode": "replace",
            "categories": ["email", "phone", "address", "financial", "urls"],
            "sensitivity": "high",
            "preserve_audio_terms": true
        ]

        let piiResult = try await piiRedactionTool.processAudioContent(realTranscript, with: piiParams)
        XCTAssertFalse(piiResult.isEmpty)
        // Should redact PII but preserve audio domain terms
        XCTAssertFalse(piiResult.contains("sarah.johnson"))
        XCTAssertFalse(piiResult.contains("555-987-6543"))
        XCTAssertTrue(piiResult.lowercased().contains("neumann"))
        XCTAssertTrue(piiResult.lowercased().contains("ssl"))

        // Step 5: Chunk for different processing workflows
        let chunkingParams: [String: Any] = [
            "text": realTranscript,
            "strategy": "semantic",
            "max_chunk_size": 600
        ]

        let chunkingResult = try await chunkingTool.processAudioContent(realTranscript, with: chunkingParams)
        XCTAssertFalse(chunkingResult.isEmpty)
        XCTAssertTrue(chunkingResult.contains("chunks"))
    }

    func testTechnicalDocumentationWorkflow() async throws {
        let technicalDoc = """
        SSL G-Series Console User Manual - Chapter 7: Automation System
        
        7.1 OVERVIEW
        The SSL G-Series console features a comprehensive automation system that allows precise control over virtually every parameter in the mix. This system combines the best of analog automation precision with digital flexibility, making it ideal for complex mixing projects.
        
        7.2 AUTOMATION CHANNELS
        Each channel strip features dedicated automation controls:
        - Fader: 0 to +10dB range, 0.1dB resolution
        - EQ: All frequency bands with individual automation paths
        - Sends: Pre-fader and post-fader sends with independent automation
        - Dynamics: Compressor threshold, ratio, attack, release, makeup gain
        - Inserts: On/off switching and parameter automation
        
        Total automation channels per console:
        - SSL G242: 24 channel strips with full automation
        - SSL G908: 8 channel strips with full automation
        - SSL J9000: 90 channel strips with full automation
        
        7.3 AUTOMATION MODES
        
        7.3.1 VCA Automation
        The VCA (Voltage Controlled Amplifier) automation system provides the classic SSL automation experience:
        - Smooth, musical response curves
        - 0.1dB resolution for precise control
        - Write and read modes with seamless switching
        - 1Hz to 20Hz update rate range
        - Touch-sensitive faders for expressive control
        
        7.3.2 Moving Faders Automation
        Moving faders provide an alternative automation method:
        - Captures precise fader movements
        - Smooth interpolation between points
        - Ideal for expressive volume rides and panning
        - Can be edited after recording for fine-tuning
        
        7.4 MIX BUS AUTOMATION
        The mix bus system includes comprehensive automation:
        - Stereo Bus: L/R balance and level automation
        - Mono Bus: Level and panning automation
        - Submix Groups: Level and assignment automation
        - Matrix System: 8x8 matrix with full automation
        - Master Bus: Final output level control
        
        7.5 INSERTS AND PLUGIN AUTOMATION
        The console supports insert point automation:
        - Channel Insert Points: On/off automation per channel
        - Bus Insert Points: Global insert switching
        - Plugin Automation: Parameter automation for connected plugins
        - External Device Automation: Control of outboard gear
        
        7.6 AUTOMATION WORKFLOW
        
        7.6.1 Recording Automation
        - Select automation channel (1-90 depending on console model)
        - Choose automation mode (write/read/touch/latch)
        - Set update rate and smoothing
        - Perform automation moves in real-time
        - Store automation data in session
        
        7.6.2 Editing Automation
        - Select automation lane for editing
        - Use trim tools for fine-tuning
        - Copy/paste automation data between channels
        - Time-compression and expansion tools
        - Curve smoothing algorithms
        
        7.6.3 Group Automation
        - Link multiple faders for simultaneous movement
        - Create custom automation groups
        - Assign relative or absolute control relationships
        - Store group configurations in sessions
        
        7.7 ADVANCED FEATURES
        
        7.7.1 Snapshot Automation
        The Snapshot system allows storing complete console states:
        - Up to 8 snapshots per session
        - Instant recall of complex setups
        - A/B comparison capabilities
        - Automated crossfading between states
        
        7.7.2 Dynamic Automation
        Dynamic automation responds to audio levels:
        - Gate automation based on input levels
        - Compressor auto-makeup gain control
        - Limiter automation for loudness control
        - Envelope follower automation for dynamic control
        
        7.8 TECHNICAL SPECIFICATIONS
        
        7.8.1 Resolution
        - Fader Resolution: 0.1dB (10,000 steps over full range)
        - EQ Resolution: 0.1dB increments
        - Pan Resolution: 0.1% increments
        - Send Level Resolution: 0.1dB
        
        7.8.2 Update Rates
        - VCA Automation: 1Hz to 20Hz adjustable
        - Moving Fader: 100Hz to 1kHz update rate
        - Touch Sensitive: 200Hz response time
        - Smooth Rate: 0.1s to 10s adjustable
        
        7.8.3 Memory
        - Automation Memory: 64,000 events per project
        - Undo/Redo: 128 levels
        - Snapshots: 8 per session
        - Project Storage: Up to 200MB of automation data
        
        7.9 TROUBLESHOOTING
        
        7.9.1 Common Issues
        - Automation not responding: Check channel selection and mode
        - Jittery automation: Adjust update rate and smoothing
        - Lost automation data: Check project save settings
        - Cross-talk between channels: Verify routing configuration
        
        7.9.2 Maintenance
        - Clean VCA faders regularly with appropriate cleaning solution
        - Check calibration monthly for optimal performance
        - Update firmware for latest features and bug fixes
        - Backup automation data with project saves
        
        7.10 BEST PRACTICES
        
        7.10.1 Recording Techniques
        - Plan automation moves before recording
        - Use appropriate update rates for different parameter types
        - Practice smooth, controlled movements
        - Record multiple takes when needed for critical sections
        
        7.10.2 Editing Workflow
        - Fine-tune automation after initial recording
        - Use zoom features for precise editing
        - Group related automation moves together
        - Listen back in context with the full mix
        
        7.10.3 Mixing Strategy
        - Start with foundation elements (drums, bass)
        - Automate vocals for emotional impact
        - Use automation to create movement and interest
        - Keep automation musical and purposeful
        
        WARRANTY INFORMATION
        SSL guarantees VCA calibration accuracy within ±0.1dB for the first 5 years.
        Moving faders are covered for 3 years against mechanical failure.
        All automation components are covered against manufacturing defects.
        
        SUPPORT CONTACT
        For technical support: support@ssl.com
        For warranty service: warranty@ssl.com
        For training and education: training@ssl.com
        Phone: +44 (0) 1634 267 800
        """
        
        let params: [String: Any] = [
            "text": technicalDoc,
            "strategy": "audio_optimized",
            "content_type": "technical_spec",
            "include_breakdown": true
        ]
        
        let result = try await tokenTool.processAudioContent(technicalDoc, with: params)
        
        XCTAssertFalse(result.isEmpty)
        // Should recognize technical documentation content
        let resultLower = result.lowercased()
        XCTAssertTrue(resultLower.contains("ssl") || resultLower.contains("console"))
        XCTAssertTrue(resultLower.contains("automation") || resultLower.contains("technical"))
        XCTAssertTrue(resultLower.contains("specification") || resultLower.contains("manual"))
    }

    // MARK: - Performance Integration Tests

    func testPerformanceWithLargeRealWorldContent() async throws {
        let largeContent = String(repeating: TestData.sampleSessionNotes, count: 10)

        let startTime = Date()
        
        // Run all tools in sequence
        let tokenParams: [String: Any] = [
            "text": largeContent,
            "strategy": "audio_optimized"
        ]
        let tokenResult = try await tokenTool.processAudioContent(largeContent, with: tokenParams)

        let summaryParams: [String: Any] = [
            "text": largeContent,
            "focus_areas": ["technical"],
            "style": "bullet"
        ]
        let summaryResult = try await focusedTool.processAudioContent(largeContent, with: summaryParams)

        let chunkingParams: [String: Any] = [
            "text": largeContent,
            "strategy": "paragraph",
            "max_chunk_size": 1000
        ]
        let chunkingResult = try await chunkingProcessAudioContent(largeContent, with: chunkingParams)

        let executionTime = Date().timeIntervalSince(startTime)
        
        // Entire workflow should complete within 1 second for large content
        XCTAssertLessThan(executionTime, 1.0)
        
        XCTAssertFalse(tokenResult.isEmpty)
        XCTAssertFalse(summaryResult.isEmpty)
        XCTAssertFalse(chunkingResult.isEmpty)
    }

    // MARK: - Error Handling Integration Tests

    func testErrorPropagationAcrossTools() async throws {
        let invalidText = ""
        
        // All tools should handle empty text consistently
        let tools: [(String, (String, [String: Any]) async throws -> String)] = [
            ("TokenCount", { text, params in
                try await tokenTool.processAudioContent(text, with: params)
            }),
            ("FocusedSummarization", { text, params in
                try await focusedTool.processAudioContent(text, with: params)
            }),
            ("TextChunking", { text, params in
                try await chunkingTool.processAudioContent(text, with: params)
            }),
            ("PIIRedaction", { text, params in
                try await piiRedactionTool.processAudioContent(text, with: params)
            })
        ]

        for (toolName, processor) in tools {
            do {
                _ = try await processor(invalidText, [:])
                XCTFail("\(toolName) should have thrown error for empty text")
            } catch {
                XCTAssertTrue(error is AudioProcessingError, "\(toolName) should throw AudioProcessingError")
            }
        }
    }

    // MARK: - Helper Methods

    private func chunkingProcessAudioContent(_ text: String, with parameters: [String: Any]) async throws -> String {
        return try await chunkingTool.processAudioContent(text, with: parameters)
    }

    // MARK: - Mock Logger Implementation

    class MockLogger: Logger {
        var loggedMessages: [String] = []

        override func info(_ message: String, category: LogCategory = .general, metadata: [String: AnyCodable] = [:]) async {
            loggedMessages.append("INFO: \(message)")
        }

        override func error(_ message: String, category: LogCategory = .general, metadata: [String: AnyCodable] = [:]) async {
            loggedMessages.append("ERROR: \(message)")
        }
    }

    // MARK: - Mock Security Manager

    class MockSecurityManager: SecurityManager {
        override func validateInput(_ input: String) throws {
            // Allow all input for integration tests
        }

        override func validateOutput(_ output: String) throws {
            // Allow all output for integration tests
        }
    }

    // MARK: - Test Data

    struct TestData {
        static let sampleSessionNotes = """
        SESSION NOTES - Rock Band Recording
        
        Setup: Neumann U87, API 312, dbx 160.
        Sample Rate: 96kHz/24-bit.
        
        Recording: 8 vocal takes selected.
        EQ and compression applied.
        Client satisfied with results.
        """
    }
}
