//
//  CatalogSessionIntegrationTests.swift
//  LocalIntelligenceMCPTests
//
//  Created on 2025-10-09.
//

import XCTest
@testable import LocalIntelligenceMCP

final class CatalogSessionIntegrationTests: XCTestCase {

    var catalogTool: CatalogSummarizationTool!
    var sessionTool: SessionNotesTool!
    var feedbackTool: FeedbackAnalysisTool!

    override func setUp() {
        super.setUp()
        catalogTool = CatalogSummarizationTool()
        sessionTool = SessionNotesTool()
        feedbackTool = FeedbackAnalysisTool()
    }

    override func tearDown() {
        catalogTool = nil
        sessionTool = nil
        feedbackTool = nil
        super.tearDown()
    }

    // MARK: - Test Data Creation

    private func createRealisticPluginCatalog() -> CatalogSummarizationTool.PluginCatalog {
        let plugins = [
            CatalogSummarizationTool.PluginItem(
                id: "fabfilter-pro-q-3",
                name: "FabFilter Pro-Q 3",
                vendor: "FabFilter",
                category: "Equalizer",
                price: 179.0,
                format: "VST3,AU,AAX",
                description: "Professional equalizer with pristine sound quality, up to 24 bands, and intuitive interface. Features dynamic EQ, linear phase mode, and spectrum analyzer.",
                tags: ["eq", "equalizer", "professional", "mixing", "mastering", "dynamic", "linear-phase", "spectrum-analyzer"],
                features: ["24 Bands", "Dynamic EQ", "Linear Phase", "Spectrum Analyzer", "Match EQ", "Auto Gain"]
            ),
            CatalogSummarizationTool.PluginItem(
                id: "waves-CLA-76",
                name: "Waves CLA-76",
                vendor: "Waves",
                category: "Dynamics",
                price: 249.0,
                format: "VST3,AU,AAX",
                description: "Classic FET-style compressor modeled after the legendary Universal Audio 1176. Provides fast attack, characteristic sound, and easy operation.",
                tags: ["compressor", "dynamics", "vintage", "analog", "FET", "mixing", "vocal", "drums"],
                features: ["FET Modeling", "Fast Attack", "All Buttons Mode", "Ratio 4:1-20:1", "Sidechain"]
            ),
            CatalogSummarizationTool.PluginItem(
                id: "valhalla-vintageverb",
                name: "Valhalla VintageVerb",
                vendor: "Valhalla DSP",
                category: "Reverb",
                price: 50.0,
                format: "VST3,AU,AAX",
                description: "Vintage reverb plugin inspired by classic digital reverbs from the 1970s and 1980s. Features 18 reverb modes and comprehensive filtering options.",
                tags: ["reverb", "vintage", "digital", "plate", "hall", "room", "vocal", "mixing"],
                features: ["18 Modes", "3 Eras", "Filtering", "Early/Late", "Mix Lock", "Undo"]
            ),
            CatalogSummarizationTool.PluginItem(
                id: "soundtoys-decapitator",
                name: "Soundtoys Decapitator",
                vendor: "Soundtoys",
                category: "Distortion",
                price: 199.0,
                format: "VST3,AU,AAX",
                description: "Analog saturation plugin that models the warmth and character of vintage analog gear. Perfect for adding warmth, grit, and character to tracks.",
                tags: ["saturation", "distortion", "analog", "vintage", "tube", "tape", "mixing", "mastering"],
                features: ["5 Styles", "Tone", "Filter", "Mix", "Punish", "Auto Gain"]
            ),
            CatalogSummarizationTool.PluginItem(
                id: "uad-studer-a800",
                name: "UAD Studer A800",
                vendor: "Universal Audio",
                category: "Tape",
                price: 349.0,
                format: "VST3,AU,AAX",
                description: "Professional tape machine emulation with stunning realism. Models the legendary Studer A800 multitrack recorder with tape saturation and wow/flutter.",
                tags: ["tape", "emulation", "analog", "vintage", "saturation", "mastering", "mixing", "professional"],
                features: ["Tape Emulation", "Wow/Flutter", "Tape Formulations", "Bias", "Speed", "Calibration"]
            ),
            CatalogSummarizationTool.PluginItem(
                id: "native-instruments-guitar-rig-6",
                name: "Native Instruments Guitar Rig 6 Pro",
                vendor: "Native Instruments",
                category: "Multi-Effects",
                price: 199.0,
                format: "VST3,AU,AAX",
                description: "Multi-effects studio for guitar and bass with unlimited creative possibilities. Features amps, effects, and routing options.",
                tags: ["guitar", "bass", "multi-effects", "amps", "simulation", "recording", "live", "effects"],
                features: ["Amp Modeling", "Effects Rack", "IR Loader", "Looper", "Cabinet Emulation", "Routing"]
            ),
            CatalogSummarizationTool.PluginItem(
                id: "izotope-ozone-9",
                name: "iZotope Ozone 9",
                vendor: "iZotope",
                category: "Mastering",
                price: 399.0,
                format: "VST3,AU,AAX",
                description: "Comprehensive mastering suite with intelligent signal processing. Includes EQ, dynamics, exciter, imaging, and maximizer modules.",
                tags: ["mastering", "comprehensive", "eq", "dynamics", "imaging", "limiter", "loudness", "professional"],
                features: ["EQ", "Dynamics", "Exciter", "Imager", "Maximizer", "Master Assistant", "Vintage Modules"]
            ),
            CatalogSummarizationTool.PluginItem(
                id: "reaper-stock-plugins",
                name: "Reaper Stock Plugins",
                vendor: "Cockos",
                category: "Bundle",
                price: 0.0,
                format: "VST3,AU",
                description: "Complete set of stock plugins included with Reaper DAW. EQ, compression, reverb, and utility effects for all mixing needs.",
                tags: ["free", "bundle", "utilities", "mixing", "eq", "dynamics", "effects", "reaper"],
                features: ["ReaEQ", "ReaComp", "ReaVerb", "ReaDelay", "ReaGate", "ReaFIR", "Utilities"]
            ),
            CatalogSummarizationTool.PluginItem(
                id: "slate-digital-vtm",
                name: "Slate Digital VTM",
                vendor: "Slate Digital",
                category: "Tape",
                price: 149.0,
                format: "VST3,AU,AAX",
                description: "Virtual tape machine emulator that accurately models the behavior of analog tape. Multiple tape formulations and machine types.",
                tags: ["tape", "emulation", "analog", "vintage", "saturation", "mixing", "mastering", "vtm"],
                features: ["2 Machines", "Tape Formulations", "Speed", "Bias", "Flux", "Calibration"]
            ),
            CatalogSummarizationTool.PluginItem(
                id: "eventide-h910",
                name: "Eventide H910 Harmonizer",
                vendor: "Eventide",
                category: "Effects",
                price: 99.0,
                format: "VST3,AU,AAX",
                description: "Faithful recreation of the world's first digital effects processor. Features pitch shifting, delay, modulation, and unique character.",
                tags: ["harmonizer", "pitch", "delay", "modulation", "vintage", "effects", "studio", "character"],
                features: ["Pitch Shift", "Delay", "Feedback", "Anti-Feedback", "Pitch Bend", "Presets"]
            )
        ]

        return CatalogSummarizationTool.PluginCatalog(
            name: "Professional Studio Plugin Collection",
            plugins: plugins
        )
    }

    private func createRealisticSessionNotes() -> SessionNotesTool.SessionNotes {
        return SessionNotesTool.SessionNotes(
            date: "2025-10-09",
            startTime: "10:00 AM",
            endTime: "6:00 PM",
            engineer: "John Smith",
            assistant: "Sarah Davis",
            studio: "Electric Lady Studios - Room A",
            project: "Indie Rock Album - Track 4 'Midnight Echoes'",
            musicians: [
                "Lead Vocal: Emily Chen (performance)",
                "Electric Guitar: Mike Johnson (rhythm/lead)",
                "Bass Guitar: Tom Wilson (bass lines)",
                "Drums: Alex Rivera (drum recording, replacement)",
                "Backing Vocals: Emily Chen (harmonies)"
            ],
            equipment: [
                "Microphones: Neumann U87 (vocal), SM57 (guitar amp), RE20 (bass cab), AKG C414 (overheads), Sennheiser e604 (toms)",
                "Preamps: API 512c (vocal), Neve 1073 (guitar), Avalon 737 (bass)",
                "Converters: Universal Audio Apollo X8",
                "DAW: Pro Tools 2024.9",
                "Interface: Universal Audio Apollo X8",
                "Outboard: LA-2A (vocal), 1176 (guitar), Pultec EQP-1A (bass)"
            ],
            technicalDetails: SessionNotesTool.TechnicalDetails(
                sampleRate: "48kHz",
                bitDepth: "24-bit",
                buffer: "128 samples",
                recordingFormat: "WAV 24-bit",
                driveConfiguration: "SSD RAID 0 for recording, external HDD for backup",
                pluginsUsed: [
                    "Waves CLA-76 (vocal compression)",
                    "Valhalla VintageVerb (vocal space)",
                    "FabFilter Pro-Q 3 (EQ shaping)",
                    "Soundtoys Decapitator (guitar saturation)",
                    "UAD Studer A800 (mix bus)"
                ]
            ),
            notes: """
            SESSION OVERVIEW:
            Today focused on tracking lead vocals, guitar overdubs, and bass recording for 'Midnight Echoes'. Session ran smoothly with excellent performances from Emily and Mike.

            VOCAL RECORDING (10:00 AM - 1:00 PM):
            Emily delivered outstanding lead vocal performance with exceptional emotional range and control. Used Neumann U87 through API 512c with gentle compression from LA-2A. Captured 5 complete takes with minimal punch-ins required.

            Key vocal moments:
            - Verse 1: Intimate, breathy tone with emotional vulnerability
            - Chorus: Powerful, soaring vocals with excellent sustain
            - Bridge: Dynamic performance with perfect control of build-up
            - Final chorus: Outstanding peak performance with full emotional impact

            Processing during recording: LA-2A set to 3dB gain reduction, slight high-pass at 80Hz, subtle presence boost at 4kHz.

            GUITAR OVERDUBS (1:30 PM - 3:30 PM):
            Mike tracked rhythm guitar parts using Gibson Les Paul through Marshall JCM800. SM57 positioned slightly off-center capturing the classic rock tone. Applied gentle compression from 1176 for consistency.

            Guitar details:
            - Rhythm verses: Chord progression with dynamic control
            - Rhythm choruses: Power chords with consistent tone
            - Lead guitar: Melodic solo with excellent phrasing and sustain
            - Additional textures: Arpeggiated parts for atmosphere

            Technical issues: Initial guitar tone was too bright - solved by moving mic slightly further from speaker cone and adding tape emulation.

            BASS RECORDING (3:45 PM - 5:00 PM):
            Tom recorded direct input and amp DI simultaneously. Used Fender Precision Bass with Avalon 737 preamp. Bass tone is warm and defined with perfect articulation.

            Bass approach:
            - Foundation: Solid root notes driving the song forward
            - Verses: Eighth-note patterns with dynamic variation
            - Chorus: Power and energy with octave doubling in second chorus
            - Bridge: Melodic counterpoint supporting vocal melody

            Backing vocals tracked at the end (5:15 PM - 5:45 PM). Emily recorded three-part harmonies with tight timing and beautiful blend.

            TECHNICAL NOTES:
            - Studio temperature maintained at 70°F for optimal equipment performance
            - All tracks recorded at -18dBFS for optimal headroom
            - Backup verification completed on all files
            - Session files organized with clear naming convention

            FILES CREATED:
            - MidnightEchoes_Vocal_Lead_01.wav (comp from takes 1-5)
            - MidnightEchoes_Vocal_Lead_02.wav (harmony part)
            - MidnightEchoes_Guitar_Rhythm_01.wav (main rhythm)
            - MidnightEchoes_Guitar_Lead_01.wav (solo)
            - MidnightEchoes_Bass_Main_01.wav (DI)
            - MidnightEchoes_Bass_Amp_01.wav (amp mic)
            - MidnightEchoes_BV_Harmony_01.wav (3-part harmony)
            """,
            actionItems: [
                SessionNotesTool.ActionItem(
                    task: "Comp and edit lead vocal takes for optimal performance",
                    priority: "high",
                    assignedTo: "John Smith",
                    dueDate: "2025-10-10"
                ),
                SessionNotesTool.ActionItem(
                    task: "Print guitar amp settings for future recall",
                    priority: "medium",
                    assignedTo: "Sarah Davis",
                    dueDate: "2025-10-10"
                ),
                SessionNotesTool.ActionItem(
                    task: "Schedule drum tracking session for rhythm tracks",
                    priority: "high",
                    assignedTo: "John Smith",
                    dueDate: "2025-10-12"
                ),
                SessionNotesTool.ActionItem(
                    task: "Prepare rough mix for client review",
                    priority: "high",
                    assignedTo: "John Smith",
                    dueDate: "2025-10-15"
                )
            ],
            nextSession: "Drum tracking and rough mix preparation",
            weather: "Partly cloudy, 68°F, perfect studio atmosphere"
        )
    }

    private func createRealisticClientFeedback() -> FeedbackAnalysisTool.FeedbackData {
        return FeedbackAnalysisTool.FeedbackData(
            feedbackText: """
            Hi John,

            I've had a chance to listen to the rough mix of 'Midnight Echoes' and I'm really impressed with the direction we're heading! There's some fantastic work here.

            WHAT'S WORKING PERFECTLY:
            - Emily's vocal performance is absolutely stunning - you've captured the emotion beautifully
            - The guitar tone is exactly what I was going for - that vintage Marshall sound is perfect
            - The overall energy and feel of the track are spot-on
            - The bass sits perfectly and drives the song forward

            MINOR ADJUSTMENTS NEEDED:
            1. Lead vocal level - Could we raise it by about 1-2dB in the choruses? Emily's voice should really soar there
            2. Guitar EQ - Slight brightness boost around 8kHz might help it cut through a bit more
            3. Reverb - The vocal reverb feels a bit long for this intimate track, maybe shorten the decay time?
            4. Low end - The chorus sections could use a little more weight, perhaps +2dB around 80Hz

            TECHNICAL NOTES:
            I'm listening on my studio monitors (Adam A7X) and also checked in my car. The mix translates well across systems.

            The vocal compression sounds great - that LA-2A character really suits Emily's voice. The guitar saturation is perfect too.

            REFERENCE COMPARISON:
            I compared it to some of our reference tracks (Fleet Foxes, My Morning Jacket) and our mix holds up really well in terms of clarity and warmth.

            DEADLINE:
            We're on track for the album deadline. If we can get these revisions done by early next week, we'll be perfectly positioned for the mastering schedule on the 15th.

            OVERALL IMPRESSION:
            This is shaping up to be one of the strongest tracks on the album. The arrangement is great, the performances are stellar, and the mix direction is perfect.

            Really looking forward to hearing the updated version!

            Best regards,
            Michael Thompson
            Producer
            """,
            source: "email",
            clientName: "Michael Thompson",
            projectName: "Indie Rock Album",
            mixVersion: "v1_rough",
            timestamp: "2025-10-11T09:30:00Z",
            context: FeedbackAnalysisTool.FeedbackContext(
                previousFeedback: [
                    "Loved the initial guitar tone in tracking",
                    "Requested more vocal presence in overdub stage",
                    "Approved bass DI choice"
                ],
                sessionType: "mix_review",
                referenceTracks: ["Fleet Foxes - Mykonos", "My Morning Jacket - Victory Dance"],
                targetGenre: "Indie Rock",
                deliveryFormat: "Album"
            ),
            metadata: [
                "reviewer_role": "producer",
                "listening_environment": "studio_monitors",
                "volume_level": "-12dB",
                "priority": "high",
                "deadline_sensitivity": "medium"
            ]
        )
    }

    // MARK: - End-to-End Workflow Tests

    func testCompletePluginToSessionWorkflow() async throws {
        // Step 1: Analyze plugin catalog to inform session setup
        let pluginCatalog = createRealisticPluginCatalog()
        let catalogInput = CatalogSummarizationTool.CatalogSummarizationInput(
            catalog: pluginCatalog,
            includeMetadata: true,
            clusteringMethod: "category",
            includeVendorAnalysis: true,
            generateRecommendations: true
        )

        let catalogResult = try await catalogTool.handle(catalogInput)
        XCTAssertNotNil(catalogResult.summary)

        // Step 2: Use catalog insights to create session notes
        let sessionNotes = createRealisticSessionNotes()
        let sessionInput = SessionNotesTool.SessionNotesInput(
            sessionNotes: sessionNotes,
            summaryType: "comprehensive",
            focusAreas: ["technical", "creative", "workflow"],
            wordCount: 500
        )

        let sessionResult = try await sessionTool.handle(sessionInput)
        XCTAssertNotNil(sessionResult.summary)

        // Step 3: Process client feedback on the mix
        let feedback = createRealisticClientFeedback()
        let feedbackInput = FeedbackAnalysisTool.FeedbackAnalysisInput(
            feedback: feedback,
            analysisDepth: "detailed",
            includeActionItems: true,
            extractTechnicalDetails: true
        )

        let feedbackResult = try await feedbackTool.handle(feedbackInput)
        XCTAssertNotNil(feedbackResult.analysis)

        // Step 4: Verify workflow integration
        // Catalog analysis should provide context for session decisions
        let catalogPlugins = catalogResult.summary?.overview.totalCategories ?? 0
        XCTAssertGreaterThan(catalogPlugins, 0)

        // Session summary should reflect technical choices informed by catalog
        let sessionTechnical = sessionResult.summary?.technicalHighlights.joined(separator: " ")
        XCTAssertNotNil(sessionTechnical)

        // Feedback analysis should connect to session decisions
        let feedbackActions = feedbackResult.analysis?.actionItems ?? []
        XCTAssertGreaterThan(feedbackActions.count, 0)

        // Verify action items are properly prioritized
        let highPriorityActions = feedbackActions.filter { $0.priority.lowercased() == "high" }
        XCTAssertGreaterThan(highPriorityActions.count, 0)
    }

    func testPluginCatalogInformsSessionSetup() async throws {
        // Step 1: Get plugin catalog recommendations
        let pluginCatalog = createRealisticPluginCatalog()
        let catalogInput = CatalogSummarizationTool.CatalogSummarizationInput(
            catalog: pluginCatalog,
            includeMetadata: true,
            clusteringMethod: "use_case",
            generateRecommendations: true,
            maxRecommendations: 5
        )

        let catalogResult = try await catalogTool.handle(catalogInput)
        XCTAssertNotNil(catalogResult.summary)

        // Step 2: Verify catalog provides useful insights for session
        let vendorAnalysis = catalogResult.summary?.vendorAnalysis
        XCTAssertNotNil(vendorAnalysis)

        let recommendations = catalogResult.summary?.recommendations ?? []
        XCTAssertGreaterThan(recommendations.count, 0)

        // Step 3: Create session notes that reflect catalog insights
        var sessionNotes = createRealisticSessionNotes()

        // Add a note about plugin choices informed by catalog
        let pluginsUsed = sessionNotes.technicalDetails.pluginsUsed.joined(separator: ", ")
        sessionNotes.notes += "\n\nPLUGIN SELECTION INSIGHTS:\nBased on catalog analysis, selected plugins provide optimal workflow efficiency and sonic character.\nUsed plugins: \(pluginsUsed)"

        // Step 4: Generate session summary
        let sessionInput = SessionNotesTool.SessionNotesInput(
            sessionNotes: sessionNotes,
            summaryType: "detailed",
            focusAreas: ["technical"],
            wordCount: 400
        )

        let sessionResult = try await sessionTool.handle(sessionInput)
        XCTAssertNotNil(sessionResult.summary)

        // Verify integration points
        let sessionContent = sessionResult.summary?.overview ?? ""
        XCTAssertTrue(sessionContent.contains("plugin") || sessionContent.contains("Plugin"))
    }

    func testFeedbackInformsNextSession() async throws {
        // Step 1: Analyze client feedback
        let feedback = createRealisticClientFeedback()
        let feedbackInput = FeedbackAnalysisTool.FeedbackAnalysisInput(
            feedback: feedback,
            analysisDepth: "comprehensive",
            includeActionItems: true,
            extractTechnicalDetails: true,
            useTemplate: true,
            templateType: "client_feedback"
        )

        let feedbackResult = try await feedbackTool.handle(feedbackInput)
        XCTAssertNotNil(feedbackResult.analysis)

        // Step 2: Extract key action items from feedback
        let actionItems = feedbackResult.analysis?.actionItems ?? []
        XCTAssertGreaterThan(actionItems.count, 0)

        let technicalDetails = feedbackResult.analysis?.technicalDetails
        XCTAssertNotNil(technicalDetails)

        // Step 3: Create next session notes incorporating feedback insights
        var nextSessionNotes = createRealisticSessionNotes()
        nextSessionNotes.date = "2025-10-12"
        nextSessionNotes.nextSession = "Mix revisions based on client feedback"

        // Add feedback-informed content
        let feedbackInsights = """

        FEEDBACK-INFORMED REVISIONS:
        - Raise lead vocal level by 1-2dB in choruses
        - Add brightness boost to guitar around 8kHz
        - Shorten vocal reverb decay time for intimacy
        - Add +2dB at 80Hz in choruses for weight

        CLIENT PRIORITIES:
        \(actionItems.map { "- \($0.task)" }.joined(separator: "\n"))
        """

        nextSessionNotes.notes += feedbackInsights

        // Step 4: Generate next session summary
        let sessionInput = SessionNotesTool.SessionNotesInput(
            sessionNotes: nextSessionNotes,
            summaryType: "template",
            templateType: "tracking",
            focusAreas: ["workflow", "technical"],
            wordCount: 300
        )

        let sessionResult = try await sessionTool.handle(sessionInput)
        XCTAssertNotNil(sessionResult.summary)

        // Verify feedback integration
        let sessionContent = sessionResult.summary?.overview ?? ""
        XCTAssertTrue(sessionContent.contains("feedback") || sessionContent.contains("revision"))
    }

    func testMultiToolAnalysisWorkflow() async throws {
        // Create comprehensive test data
        let pluginCatalog = createRealisticPluginCatalog()
        let sessionNotes = createRealisticSessionNotes()
        let feedback = createRealisticClientFeedback()

        // Step 1: Plugin catalog analysis
        let catalogInput = CatalogSummarizationTool.CatalogSummarizationInput(
            catalog: pluginCatalog,
            includeMetadata: true,
            clusteringMethod: "vendor",
            includeVendorAnalysis: true,
            generateRecommendations: true
        )

        let catalogResult = try await catalogTool.handle(catalogInput)

        // Step 2: Session summarization
        let sessionInput = SessionNotesTool.SessionNotesInput(
            sessionNotes: sessionNotes,
            summaryType: "comprehensive",
            focusAreas: ["technical", "creative", "workflow"],
            wordCount: 600
        )

        let sessionResult = try await sessionTool.handle(sessionInput)

        // Step 3: Feedback analysis
        let feedbackInput = FeedbackAnalysisTool.FeedbackAnalysisInput(
            feedback: feedback,
            analysisDepth: "comprehensive",
            includeActionItems: true,
            extractTechnicalDetails: true,
            useTemplate: true,
            templateType: "internal_review"
        )

        let feedbackResult = try await feedbackTool.handle(feedbackInput)

        // Verify all analyses completed successfully
        XCTAssertNotNil(catalogResult.summary)
        XCTAssertNotNil(sessionResult.summary)
        XCTAssertNotNil(feedbackResult.analysis)

        // Verify data consistency across tools
        let catalogPlugins = catalogResult.summary?.overview.totalPlugins ?? 0
        XCTAssertGreaterThan(catalogPlugins, 0)

        let sessionActionItems = sessionResult.summary?.actionItems?.count ?? 0
        let feedbackActionItems = feedbackResult.analysis?.actionItems?.count ?? 0
        XCTAssertGreaterThan(sessionActionItems + feedbackActionItems, 0)

        // Verify technical detail extraction
        let sessionTechnical = sessionResult.summary?.technicalHighlights.joined(separator: " ")
        let feedbackTechnical = feedbackResult.analysis?.technicalDetails?.mentionedComponents.joined(separator: " ") ?? ""
        XCTAssertFalse(sessionTechnical.isEmpty)
        XCTAssertFalse(feedbackTechnical.isEmpty)
    }

    // MARK: - Template Integration Tests

    func testEngineeringTemplateIntegration() async throws {
        // Test session notes with engineering templates
        let sessionNotes = createRealisticSessionNotes()

        // Generate session summary using tracking template
        let trackingInput = SessionNotesTool.SessionNotesInput(
            sessionNotes: sessionNotes,
            summaryType: "template",
            templateType: "tracking",
            focusAreas: ["technical", "workflow"],
            wordCount: 400
        )

        let trackingResult = try await sessionTool.handle(trackingInput)
        XCTAssertNotNil(trackingResult.summary)
        XCTAssertEqual(trackingResult.summary?.templateUsed, "tracking")

        // Generate feedback analysis using internal review template
        let feedback = createRealisticClientFeedback()
        let feedbackInput = FeedbackAnalysisTool.FeedbackAnalysisInput(
            feedback: feedback,
            analysisDepth: "detailed",
            includeActionItems: true,
            extractTechnicalDetails: true,
            useTemplate: true,
            templateType: "internal_review"
        )

        let feedbackResult = try await feedbackTool.handle(feedbackInput)
        XCTAssertNotNil(feedbackResult.analysis)
        XCTAssertEqual(feedbackResult.analysis?.templateUsed, "internal_review")

        // Verify template integration
        let trackingContent = trackingResult.summary?.overview ?? ""
        let feedbackContent = feedbackResult.analysis->technicalAssessment?.clarityAndDefinition ?? ""

        XCTAssertFalse(trackingContent.isEmpty)
        XCTAssertFalse(feedbackContent.isEmpty)
    }

    func testVendorAnalysisIntegration() async throws {
        // Test vendor-neutral analysis integration
        let pluginCatalog = createRealisticPluginCatalog()

        // Analyze catalog with vendor analysis
        let catalogInput = CatalogSummarizationTool.CatalogSummarizationInput(
            catalog: pluginCatalog,
            includeMetadata: true,
            clusteringMethod: "vendor",
            includeVendorAnalysis: true,
            generateRecommendations: true,
            maxRecommendations: 3
        )

        let catalogResult = try await catalogTool.handle(catalogInput)
        XCTAssertNotNil(catalogResult.summary)

        // Verify vendor analysis was performed
        let vendorAnalysis = catalogResult.summary?.vendorAnalysis
        XCTAssertNotNil(vendorAnalysis)

        let vendorInsights = vendorAnalysis?.vendorInsights ?? []
        let alternatives = vendorAnalysis?.alternativeSuggestions ?? []

        XCTAssertGreaterThan(vendorInsights.count + alternatives.count, 0)

        // Test that vendor analysis provides actionable insights
        let recommendations = catalogResult.summary?.recommendations ?? []
        if !recommendations.isEmpty {
            let topRecommendation = recommendations.first!
            XCTAssertNotNil(topRecommendation.plugin)
            XCTAssertGreaterThan(topRecommendation.similarityScore, 0.0)
            XCTAssertFalse(topRecommendation.reasons.isEmpty)
        }
    }

    // MARK: - Real-world Scenario Tests

    func testStudioWorkflowScenario() async throws {
        // Simulate a real studio workflow scenario

        // Phase 1: Plugin inventory and setup planning
        let pluginCatalog = createRealisticPluginCatalog()
        let inventoryInput = CatalogSummarizationTool.CatalogSummarizationInput(
            catalog: pluginCatalog,
            includeMetadata: true,
            clusteringMethod: "category",
            includeVendorAnalysis: true
        )

        let inventoryResult = try await catalogTool.handle(inventoryInput)

        // Phase 2: Recording session documentation
        let sessionNotes = createRealisticSessionNotes()
        let recordingInput = SessionNotesTool.SessionNotesInput(
            sessionNotes: sessionNotes,
            summaryType: "comprehensive",
            focusAreas: ["technical", "creative"],
            wordCount: 500
        )

        let recordingResult = try await sessionTool.handle(recordingInput)

        // Phase 3: Client feedback processing
        let feedback = createRealisticClientFeedback()
        let feedbackInput = FeedbackAnalysisTool.FeedbackAnalysisInput(
            feedback: feedback,
            analysisDepth: "detailed",
            includeActionItems: true,
            extractTechnicalDetails: true
        )

        let feedbackResult = try await feedbackTool.handle(feedbackInput)

        // Phase 4: Integration verification
        // Inventory should inform plugin choices
        let pluginCount = inventoryResult.summary?.overview.totalPlugins ?? 0
        XCTAssertGreaterThan(pluginCount, 0)

        // Recording should capture technical details
        let recordingTechnical = recordingResult.summary?.technicalHighlights.joined(separator: " ")
        XCTAssertFalse(recordingTechnical.isEmpty)

        // Feedback should generate actionable items
        let feedbackActions = feedbackResult.analysis?.actionItems ?? []
        XCTAssertGreaterThan(feedbackActions.count, 0)

        // All phases should produce coherent, actionable results
        XCTAssertNotNil(inventoryResult.summary)
        XCTAssertNotNil(recordingResult.summary)
        XCTAssertNotNil(feedbackResult.analysis)
    }

    func testProjectManagementScenario() async throws {
        // Simulate project management workflow

        // Step 1: Catalog resource assessment
        let pluginCatalog = createRealisticPluginCatalog()
        let assessmentInput = CatalogSummarizationTool.CatalogSummarizationInput(
            catalog: pluginCatalog,
            includeMetadata: true,
            clusteringMethod: "price_range",
            includeVendorAnalysis: true,
            generateRecommendations: true
        )

        let assessmentResult = try await catalogTool.handle(assessmentInput)

        // Step 2: Session progress tracking
        let sessionNotes = createRealisticSessionNotes()
        var sessionInput = SessionNotesTool.SessionNotesInput(
            sessionNotes: sessionNotes,
            summaryType: "template",
            templateType: "daily_summary",
            focusAreas: ["workflow"],
            wordCount: 300
        )

        let sessionResult = try await sessionTool.handle(sessionInput)

        // Step 3: Stakeholder feedback analysis
        let feedback = createRealisticClientFeedback()
        let stakeholderInput = FeedbackAnalysisTool.FeedbackAnalysisInput(
            feedback: feedback,
            analysisDepth: "comprehensive",
            includeActionItems: true,
            extractTechnicalDetails: true,
            useTemplate: true,
            templateType: "client_feedback"
        )

        let stakeholderResult = try await feedbackTool.handle(stakeholderInput)

        // Verify project management insights
        let resourceAnalysis = assessmentResult.summary?.overview
        let progressSummary = sessionResult.summary?.overview
        let stakeholderFeedback = stakeholderResult.analysis?.sentimentAnalysis

        XCTAssertNotNil(resourceAnalysis)
        XCTAssertNotNil(progressSummary)
        XCTAssertNotNil(stakeholderFeedback)

        // Verify actionable project information
        let actionItems = stakeholderResult.analysis?.actionItems ?? []
        let nextSteps = sessionResult.summary?.nextSteps.joined(separator: " ")

        XCTAssertGreaterThan(actionItems.count, 0)
        XCTAssertFalse(nextSteps.isEmpty)
    }

    // MARK: - Performance and Scale Tests

    func testLargeScaleIntegrationPerformance() async throws {
        let startTime = CFAbsoluteTimeGetCurrent()

        // Create larger dataset
        var largePluginCatalog = createRealisticPluginCatalog()
        let plugins = largePluginCatalog.plugins

        // Duplicate plugins to simulate large catalog
        for _ in 1...5 {
            largePluginCatalog.plugins.append(contentsOf: plugins)
        }

        // Create comprehensive session data
        var largeSessionNotes = createRealisticSessionNotes()
        largeSessionNotes.notes += String(repeating: "Additional session details for performance testing. ", count: 20)

        // Create detailed feedback
        var largeFeedback = createRealisticClientFeedback()
        largeFeedback.feedbackText += String(repeating: "Additional feedback details for performance testing. ", count: 10)

        // Run all analyses
        let catalogInput = CatalogSummarizationTool.CatalogSummarizationInput(
            catalog: largePluginCatalog,
            includeMetadata: true,
            clusteringMethod: "category",
            includeVendorAnalysis: true,
            generateRecommendations: true
        )

        let sessionInput = SessionNotesTool.SessionNotesInput(
            sessionNotes: largeSessionNotes,
            summaryType: "comprehensive",
            focusAreas: ["technical", "creative", "workflow"],
            wordCount: 600
        )

        let feedbackInput = FeedbackAnalysisTool.FeedbackAnalysisInput(
            feedback: largeFeedback,
            analysisDepth: "comprehensive",
            includeActionItems: true,
            extractTechnicalDetails: true,
            useTemplate: true,
            templateType: "internal_review"
        )

        // Execute all analyses
        async let catalogResult = catalogTool.handle(catalogInput)
        async let sessionResult = sessionTool.handle(sessionInput)
        async let feedbackResult = feedbackTool.handle(feedbackInput)

        let (catalogRes, sessionRes, feedbackRes) = await (catalogResult, sessionResult, feedbackResult)

        let processingTime = CFAbsoluteTimeGetCurrent() - startTime

        // Verify all analyses completed
        XCTAssertNotNil(catalogRes.summary)
        XCTAssertNotNil(sessionRes.summary)
        XCTAssertNotNil(feedbackRes.analysis)

        // Verify performance expectations
        XCTAssertLessThan(processingTime, 5.0, "Large-scale integration should complete within 5 seconds")

        // Verify data integrity
        XCTAssertEqual(catalogRes.summary?.overview.totalPlugins, largePluginCatalog.plugins.count)
        XCTAssertFalse(sessionRes.summary?.overview.isEmpty ?? true)
        XCTAssertGreaterThan(feedbackRes.analysis?.actionItems?.count ?? 0, 0)
    }

    // MARK: - Error Handling and Edge Cases

    func testIntegrationWithIncompleteData() async throws {
        // Test integration with minimal/missing data

        // Minimal plugin catalog
        let minimalCatalog = CatalogSummarizationTool.PluginCatalog(
            name: "Minimal Catalog",
            plugins: []
        )

        let catalogInput = CatalogSummarizationTool.CatalogSummarizationInput(
            catalog: minimalCatalog,
            includeMetadata: true,
            clusteringMethod: "category"
        )

        let catalogResult = try await catalogTool.handle(catalogInput)
        XCTAssertNotNil(catalogResult.summary)

        // Minimal session notes
        let minimalSession = SessionNotesTool.SessionNotes(
            date: "",
            startTime: "",
            endTime: "",
            engineer: "",
            assistant: "",
            studio: "",
            project: "",
            musicians: [],
            equipment: [],
            technicalDetails: SessionNotesTool.TechnicalDetails(
                sampleRate: "",
                bitDepth: "",
                buffer: "",
                recordingFormat: "",
                driveConfiguration: "",
                pluginsUsed: []
            ),
            notes: "",
            actionItems: [],
            nextSession: "",
            weather: ""
        )

        let sessionInput = SessionNotesTool.SessionNotesInput(
            sessionNotes: minimalSession,
            summaryType: "brief",
            focusAreas: ["technical"],
            wordCount: 100
        )

        let sessionResult = try await sessionTool.handle(sessionInput)
        XCTAssertNotNil(sessionResult.summary)

        // Minimal feedback
        let minimalFeedback = FeedbackAnalysisTool.FeedbackData(
            feedbackText: "",
            source: "",
            clientName: "",
            projectName: "",
            mixVersion: "",
            timestamp: "",
            context: nil,
            metadata: [:]
        )

        let feedbackInput = FeedbackAnalysisTool.FeedbackAnalysisInput(
            feedback: minimalFeedback,
            analysisDepth: "brief",
            includeActionItems: true,
            extractTechnicalDetails: false
        )

        let feedbackResult = try await feedbackTool.handle(feedbackInput)
        XCTAssertNotNil(feedbackResult.analysis)

        // Verify graceful handling of minimal data
        XCTAssertNotNil(catalogResult.summary?.overview)
        XCTAssertNotNil(sessionResult.summary?.title)
        XCTAssertNotNil(feedbackResult.analysis?.sentimentAnalysis)
    }

    func testIntegrationConsistency() async throws {
        // Test that results are consistent across multiple runs

        let pluginCatalog = createRealisticPluginCatalog()
        let sessionNotes = createRealisticSessionNotes()
        let feedback = createRealisticClientFeedback()

        // Run analyses twice
        let catalogInput1 = CatalogSummarizationTool.CatalogSummarizationInput(
            catalog: pluginCatalog,
            includeMetadata: true,
            clusteringMethod: "category"
        )

        let sessionInput1 = SessionNotesTool.SessionNotesInput(
            sessionNotes: sessionNotes,
            summaryType: "detailed",
            focusAreas: ["technical"],
            wordCount: 300
        )

        let feedbackInput1 = FeedbackAnalysisTool.FeedbackAnalysisInput(
            feedback: feedback,
            analysisDepth: "detailed",
            includeActionItems: true,
            extractTechnicalDetails: true
        )

        let catalogInput2 = catalogInput1
        let sessionInput2 = sessionInput1
        let feedbackInput2 = feedbackInput1

        // Execute both sets
        async let catalogResult1 = catalogTool.handle(catalogInput1)
        async let sessionResult1 = sessionTool.handle(sessionInput1)
        async let feedbackResult1 = feedbackTool.handle(feedbackInput1)

        async let catalogResult2 = catalogTool.handle(catalogInput2)
        async let sessionResult2 = sessionTool.handle(sessionInput2)
        async let feedbackResult2 = feedbackTool.handle(feedbackInput2)

        let (catalogRes1, sessionRes1, feedbackRes1) = await (catalogResult1, sessionResult1, feedbackResult1)
        let (catalogRes2, sessionRes2, feedbackRes2) = await (catalogResult2, sessionRes2, feedbackResult2)

        // Verify consistency
        XCTAssertEqual(catalogRes1.summary?.overview.totalPlugins, catalogRes2.summary?.overview.totalPlugins)
        XCTAssertEqual(sessionRes1.summary?.wordCount, sessionRes2.summary?.wordCount)
        XCTAssertEqual(feedbackRes1.analysis?.sentimentAnalysis.overall, feedbackRes2.analysis?.sentimentAnalysis.overall)
    }
}