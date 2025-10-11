//
//  SessionNotesToolTests.swift
//  LocalIntelligenceMCPTests
//
//  Created on 2025-10-09.
//

import XCTest
@testable import LocalIntelligenceMCP

final class SessionNotesToolTests: XCTestCase {

    var sessionTool: SessionNotesTool!

    override func setUp() {
        super.setUp()
        sessionTool = SessionNotesTool()
    }

    override func tearDown() {
        sessionTool = nil
        super.tearDown()
    }

    // MARK: - Test Data Creation

    private func createTestSessionNotes() -> SessionNotesTool.SessionNotes {
        return SessionNotesTool.SessionNotes(
            date: "2025-10-09",
            startTime: "10:00 AM",
            endTime: "2:00 PM",
            engineer: "John Smith",
            assistant: "Jane Doe",
            studio: "Studio A",
            project: "Rock Album - Track 3",
            musicians: ["Vocalist: Sarah Johnson", "Guitarist: Mike Wilson", "Bassist: Tom Davis"],
            equipment: [
                "Microphones: Neumann U87, SM57",
                "Preamps: API 512, Neve 1073",
                "Interface: Universal Audio Apollo",
                "DAW: Pro Tools 2023.9"
            ],
            technicalDetails: SessionNotesTool.TechnicalDetails(
                sampleRate: "48kHz",
                bitDepth: "24-bit",
                buffer: "128 samples",
                recordingFormat: "WAV",
                driveConfiguration: "RAID 0 for recording, RAID 1 for backup",
                pluginsUsed: ["Waves CLA-76", "UAD Studer", "FabFilter Pro-Q 3"]
            ),
            notes: """
            Great tracking session today. Sarah delivered an outstanding vocal performance with excellent emotional range.
            The lead vocal was tracked through the Neumann U87 with the API 512 preamp, providing clarity and presence.

            Mike tried three different guitars before settling on the Fender Stratocaster with the Marshall amp.
            The rhythm guitar part required some punch-in work on the bridge section due to timing issues.

            Tom's bass performance was solid from the start. Used direct input and amp DI for flexibility in mixing.

            Technical issues: Had some ground hum that was resolved by checking cable connections and using proper power isolation.

            Files created:
            - Track03_Vocal_Lead_01.wav
            - Track03_Vocal_Harmony_01.wav (3 takes)
            - Track03_Guitar_Rhythm_01.wav (2 takes)
            - Track03_Bass_Main_01.wav
            - Track03_Drums_Overhead.wav
            """,
            actionItems: [
                SessionNotesTool.ActionItem(
                    task: "Comp vocal takes from the 3 harmony recordings",
                    priority: "high",
                    assignedTo: "John Smith",
                    dueDate: "2025-10-10"
                ),
                SessionNotesTool.ActionItem(
                    task: "Print guitar amp settings for future sessions",
                    priority: "medium",
                    assignedTo: "Jane Doe",
                    dueDate: "2025-10-11"
                ),
                SessionNotesTool.ActionItem(
                    task: "Schedule drum tracking for next week",
                    priority: "high",
                    assignedTo: "John Smith",
                    dueDate: "2025-10-15"
                )
            ],
            nextSession: "Drum tracking and vocal comping",
            weather: "Partly cloudy, 72°F"
        )
    }

    private func createTestMixingSessionNotes() -> SessionNotesTool.SessionNotes {
        return SessionNotesTool.SessionNotes(
            date: "2025-10-08",
            startTime: "1:00 PM",
            endTime: "6:00 PM",
            engineer: "Alex Turner",
            assistant: "Chris Martin",
            studio: "Studio B",
            project: "Pop Single - Summer Vibes",
            musicians: ["Artist: Emily Chen"],
            equipment: [
                "Monitors: Genelec 8040",
                "Processing: API 2500, Manley Massive Passive",
                "Plugins: Soundtoys, FabFilter, Valhalla"
            ],
            technicalDetails: SessionNotesTool.TechnicalDetails(
                sampleRate: "96kHz",
                bitDepth: "32-bit float",
                buffer: "512 samples",
                recordingFormat: "None (mixing session)",
                driveConfiguration: "SSD RAID for project files",
                pluginsUsed: ["Soundtoys Decapitator", "Valhalla VintageVerb", "FabFilter Pro-MB", "Ozone 9"]
            ),
            notes: """
            Mix session focused on vocal clarity and drum impact. Emily requested a modern pop sound with warm analog character.

            Vocal processing: Used CLA-76 for compression, followed by EQ for presence, and Valhalla for subtle space.
            Drums: Added parallel compression to glue the kit together, used SSL G-series EQ for punch.

            Client feedback: Wants more low end in the chorus section and less reverb on the lead vocal.
            Made adjustments and client approved the rough mix.

            Reference tracks used: "Blinding Lights" by The Weeknd, "Levitating" by Dua Lipa

            Exported rough mix for client approval.
            """,
            actionItems: [
                SessionNotesTool.ActionItem(
                    task: "Apply final automation and export master mix",
                    priority: "high",
                    assignedTo: "Alex Turner",
                    dueDate: "2025-10-09"
                ),
                SessionNotesTool.ActionItem(
                    task: "Prepare instrumental version for licensing",
                    priority: "medium",
                    assignedTo: "Chris Martin",
                    dueDate: "2025-10-10"
                )
            ],
            nextSession: "Final mix revisions and mastering prep",
            weather: "Sunny, 78°F"
        )
    }

    // MARK: - Session Summary Tests

    func testSummarizeSessionBasic() async throws {
        let sessionNotes = createTestSessionNotes()
        let input = SessionNotesTool.SessionNotesInput(
            sessionNotes: sessionNotes,
            summaryType: "detailed",
            focusAreas: ["technical", "creative"],
            wordCount: 300
        )

        let result = try await sessionTool.handle(input)

        XCTAssertNotNil(result.summary)
        XCTAssertNotNil(result.summary?.title)
        XCTAssertNotNil(result.summary?.overview)
        XCTAssertNotNil(result.summary?.technicalHighlights)
        XCTAssertNotNil(result.summary?.creativeHighlights)
        XCTAssertNotNil(result.summary?.keyDecisions)
        XCTAssertNotNil(result.summary?.actionItems)
        XCTAssertNotNil(result.summary?.nextSteps)
        XCTAssertNotNil(result.summary?.recommendations)

        // Verify content contains expected elements
        let summaryText = result.summary?.overview ?? ""
        XCTAssertTrue(summaryText.contains("Rock Album") || summaryText.contains("Sarah"))
        XCTAssertTrue((result.summary?.wordCount ?? 0) > 100)
    }

    func testSummarizeSessionBrief() async throws {
        let sessionNotes = createTestSessionNotes()
        let input = SessionNotesTool.SessionNotesInput(
            sessionNotes: sessionNotes,
            summaryType: "brief",
            focusAreas: ["technical"],
            wordCount: 150
        )

        let result = try await sessionTool.handle(input)

        XCTAssertNotNil(result.summary)
        XCTAssertLessThanOrEqual(result.summary?.wordCount ?? 0, 200)
        XCTAssertEqual(result.summary?.summaryType, "brief")
    }

    func testSummarizeSessionComprehensive() async throws {
        let sessionNotes = createTestSessionNotes()
        let input = SessionNotesTool.SessionNotesInput(
            sessionNotes: sessionNotes,
            summaryType: "comprehensive",
            focusAreas: ["technical", "creative", "workflow"],
            wordCount: 500
        )

        let result = try await sessionTool.handle(input)

        XCTAssertNotNil(result.summary)
        XCTAssertEqual(result.summary?.summaryType, "comprehensive")
        XCTAssertGreaterThanOrEqual(result.summary?.wordCount ?? 0, 300)
        XCTAssertFalse((result.summary?.technicalHighlights?.isEmpty ?? true))
        XCTAssertFalse((result.summary?.creativeHighlights?.isEmpty ?? true))
    }

    func testSummarizeEmptySessionNotes() async throws {
        let emptySession = SessionNotesTool.SessionNotes(
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

        let input = SessionNotesTool.SessionNotesInput(
            sessionNotes: emptySession,
            summaryType: "detailed",
            focusAreas: ["technical"],
            wordCount: 200
        )

        let result = try await sessionTool.handle(input)

        XCTAssertNotNil(result.summary)
        XCTAssertNotNil(result.summary?.title)
        XCTAssertEqual(result.summary?.summaryType, "detailed")
    }

    // MARK: - Template Tests

    func testSummarizeWithTrackingTemplate() async throws {
        let sessionNotes = createTestSessionNotes()
        let input = SessionNotesTool.SessionNotesInput(
            sessionNotes: sessionNotes,
            summaryType: "template",
            templateType: "tracking",
            focusAreas: ["technical", "creative"],
            wordCount: 400
        )

        let result = try await sessionTool.handle(input)

        XCTAssertNotNil(result.summary)
        XCTAssertEqual(result.summary?.summaryType, "template")
        XCTAssertEqual(result.summary?.templateUsed, "tracking")
        XCTAssertTrue(result.summary?.title?.contains("TRACKING SESSION") == true)

        // Verify template-specific content
        let content = result.summary?.overview ?? ""
        XCTAssertTrue(content.contains("INSTRUMENTS TRACKED") || content.contains("PERFORMANCES"))
        XCTAssertTrue(content.contains("EQUIPMENT USED") || content.contains("TECHNICAL SETTINGS"))
    }

    func testSummarizeWithMixingTemplate() async throws {
        let sessionNotes = createTestMixingSessionNotes()
        let input = SessionNotesTool.SessionNotesInput(
            sessionNotes: sessionNotes,
            summaryType: "template",
            templateType: "mixing",
            focusAreas: ["technical", "creative"],
            wordCount: 400
        )

        let result = try await sessionTool.handle(input)

        XCTAssertNotNil(result.summary)
        XCTAssertEqual(result.summary?.summaryType, "template")
        XCTAssertEqual(result.summary?.templateUsed, "mixing")
        XCTAssertTrue(result.summary?.title?.contains("MIXING SESSION") == true)

        // Verify template-specific content
        let content = result.summary?.overview ?? ""
        XCTAssertTrue(content.contains("SIGNAL CHAIN") || content.contains("MIX SETTINGS"))
        XCTAssertTrue(content.contains("REFERENCE TRACKS") || content.contains("AUTOMATION"))
    }

    func testSummarizeWithMasteringTemplate() async throws {
        let masteringSession = SessionNotesTool.SessionNotes(
            date: "2025-10-07",
            startTime: "10:00 AM",
            endTime: "1:00 PM",
            engineer: "Bob Ludwig",
            assistant: "Emily Watson",
            studio: "Mastering Suite",
            project: "Jazz Album - Mastering",
            musicians: ["Artist: John Coltrane Quartet"],
            equipment: [
                "Monitors: B&W 802 D3",
                "Converter: Prism Sound",
                "EQ: Manley Massive Passive",
                "Compressor: Pendulum OCL-2"
            ],
            technicalDetails: SessionNotesTool.TechnicalDetails(
                sampleRate: "96kHz",
                bitDepth: "24-bit",
                buffer: "1024 samples",
                recordingFormat: "WAV",
                driveConfiguration: "SSD",
                pluginsUsed: ["FabFilter Pro-L 2", "Sonnox Oxford EQ", "UAD Precision Limiter"]
            ),
            notes: """
            Mastering session for jazz album. Focus on preserving dynamic range while achieving competitive loudness.

            Source analysis: Mixes have good balance but need some low-end control and high-frequency enhancement.
            EQ applied: Gentle boost at 60Hz for warmth, slight cut at 400Hz to reduce mud, +1dB at 10kHz for air.
            Compression: 1.5:1 ratio with 2dB gain reduction maximum, preserving transients.

            Reference tracks: Kind of Blue, A Love Supreme, Blue Train

            Target loudness: -14 LUFS integrated, -1.0 dBTP true peak.
            """,
            actionItems: [
                SessionNotesTool.ActionItem(
                    task: "Create DDP image for CD production",
                    priority: "high",
                    assignedTo: "Bob Ludwig",
                    dueDate: "2025-10-08"
                )
            ],
            nextSession: "Quality control and delivery preparation",
            weather: "Overcast, 65°F"
        )

        let input = SessionNotesTool.SessionNotesInput(
            sessionNotes: masteringSession,
            summaryType: "template",
            templateType: "mastering",
            focusAreas: ["technical"],
            wordCount: 400
        )

        let result = try await sessionTool.handle(input)

        XCTAssertNotNil(result.summary)
        XCTAssertEqual(result.summary?.summaryType, "template")
        XCTAssertEqual(result.summary?.templateUsed, "mastering")
        XCTAssertTrue(result.summary?.title?.contains("MASTERING SESSION") == true)

        // Verify template-specific content
        let content = result.summary?.overview ?? ""
        XCTAssertTrue(content.contains("SOURCE ANALYSIS") || content.contains("CHAIN CONFIGURATION"))
        XCTAssertTrue(content.contains("FINAL SETTINGS") || content.contains("DELIVERY FORMATS"))
    }

    func testSummarizeWithDailySummaryTemplate() async throws {
        let sessionNotes = createTestSessionNotes()
        let input = SessionNotesTool.SessionNotesInput(
            sessionNotes: sessionNotes,
            summaryType: "template",
            templateType: "daily_summary",
            focusAreas: ["workflow", "technical"],
            wordCount: 300
        )

        let result = try await sessionTool.handle(input)

        XCTAssertNotNil(result.summary)
        XCTAssertEqual(result.summary?.summaryType, "template")
        XCTAssertEqual(result.summary?.templateUsed, "daily_summary")
        XCTAssertTrue(result.summary?.title?.contains("DAILY SESSION SUMMARY") == true)

        // Verify template-specific content
        let content = result.summary?.overview ?? ""
        XCTAssertTrue(content.contains("SESSIONS COMPLETED") || content.contains("ACCOMPLISHMENTS"))
    }

    func testSummarizeWithFeedbackTemplate() async throws {
        let sessionNotes = createTestMixingSessionNotes()
        let input = SessionNotesTool.SessionNotesInput(
            sessionNotes: sessionNotes,
            summaryType: "template",
            templateType: "feedback",
            focusAreas: ["creative", "client"],
            wordCount: 300
        )

        let result = try await sessionTool.handle(input)

        XCTAssertNotNil(result.summary)
        XCTAssertEqual(result.summary?.summaryType, "template")
        XCTAssertEqual(result.summary?.templateUsed, "feedback")
        XCTAssertTrue(result.summary?.title?.contains("CLIENT FEEDBACK") == true)

        // Verify template-specific content
        let content = result.summary?.overview ?? ""
        XCTAssertTrue(content.contains("SPECIFIC FEEDBACK") || content.contains("PRIORITY ACTION ITEMS"))
    }

    func testSummarizeWithInvalidTemplate() async throws {
        let sessionNotes = createTestSessionNotes()
        let input = SessionNotesTool.SessionNotesInput(
            sessionNotes: sessionNotes,
            summaryType: "template",
            templateType: "invalid_template",
            focusAreas: ["technical"],
            wordCount: 200
        )

        let result = try await sessionTool.handle(input)

        XCTAssertNotNil(result.summary)
        // Should fall back to default template type
        XCTAssertEqual(result.summary?.templateUsed, "tracking")
    }

    // MARK: - Focus Areas Tests

    func testSummarizeWithTechnicalFocus() async throws {
        let sessionNotes = createTestSessionNotes()
        let input = SessionNotesTool.SessionNotesInput(
            sessionNotes: sessionNotes,
            summaryType: "detailed",
            focusAreas: ["technical"],
            wordCount: 250
        )

        let result = try await sessionTool.handle(input)

        XCTAssertNotNil(result.summary)
        XCTAssertNotNil(result.summary?.technicalHighlights)

        let highlights = result.summary?.technicalHighlights ?? []
        XCTAssertFalse(highlights.isEmpty)

        // Verify technical content is included
        let content = (highlights.joined(separator: " ") + (result.summary?.overview ?? "")).lowercased()
        XCTAssertTrue(content.contains("microphone") || content.contains("preamp") || content.contains("plugin"))
    }

    func testSummarizeWithCreativeFocus() async throws {
        let sessionNotes = createTestSessionNotes()
        let input = SessionNotesTool.SessionNotesInput(
            sessionNotes: sessionNotes,
            summaryType: "detailed",
            focusAreas: ["creative"],
            wordCount: 250
        )

        let result = try await sessionTool.handle(input)

        XCTAssertNotNil(result.summary)
        XCTAssertNotNil(result.summary?.creativeHighlights)

        let highlights = result.summary?.creativeHighlights ?? []
        XCTAssertFalse(highlights.isEmpty)

        // Verify creative content is included
        let content = (highlights.joined(separator: " ") + (result.summary?.overview ?? "")).lowercased()
        XCTAssertTrue(content.contains("performance") || content.contains("emotional") || content.contains("artistic"))
    }

    func testSummarizeWithWorkflowFocus() async throws {
        let sessionNotes = createTestSessionNotes()
        let input = SessionNotesTool.SessionNotesInput(
            sessionNotes: sessionNotes,
            summaryType: "detailed",
            focusAreas: ["workflow"],
            wordCount: 250
        )

        let result = try await sessionTool.handle(input)

        XCTAssertNotNil(result.summary)

        // Verify workflow-related content is included
        let content = result.summary?.overview ?? ""
        let hasWorkflowContent = content.lowercased().contains("session") ||
                               content.lowercased().contains("process") ||
                               content.lowercased().contains("schedule") ||
                               !(result.summary?.keyDecisions?.isEmpty ?? true)
        XCTAssertTrue(hasWorkflowContent)
    }

    func testSummarizeWithMultipleFocusAreas() async throws {
        let sessionNotes = createTestSessionNotes()
        let input = SessionNotesTool.SessionNotesInput(
            sessionNotes: sessionNotes,
            summaryType: "detailed",
            focusAreas: ["technical", "creative", "workflow"],
            wordCount: 400
        )

        let result = try await sessionTool.handle(input)

        XCTAssertNotNil(result.summary)
        XCTAssertFalse(result.summary?.technicalHighlights?.isEmpty ?? true)
        XCTAssertFalse(result.summary?.creativeHighlights?.isEmpty ?? true)
        XCTAssertFalse(result.summary?.keyDecisions?.isEmpty ?? true)
    }

    // MARK: - Action Items Processing Tests

    func testActionItemsProcessing() async throws {
        let sessionNotes = createTestSessionNotes()
        let input = SessionNotesTool.SessionNotesInput(
            sessionNotes: sessionNotes,
            summaryType: "detailed",
            focusAreas: ["workflow"],
            wordCount: 200
        )

        let result = try await sessionTool.handle(input)

        XCTAssertNotNil(result.summary)
        XCTAssertNotNil(result.summary?.actionItems)

        let actionItems = result.summary?.actionItems ?? []
        XCTAssertEqual(actionItems.count, 3)

        // Verify action items are properly processed
        for item in actionItems {
            XCTAssertFalse(item.task.isEmpty)
            XCTAssertFalse(item.priority.isEmpty)
            XCTAssertFalse(item.assignedTo.isEmpty)
            XCTAssertFalse(item.dueDate.isEmpty)
        }

        // Verify high priority items are highlighted
        let highPriorityItems = actionItems.filter { $0.priority.lowercased() == "high" }
        XCTAssertGreaterThanOrEqual(highPriorityItems.count, 1)
    }

    func testActionItemsWithEmptyList() async throws {
        var sessionNotes = createTestSessionNotes()
        sessionNotes.actionItems = []

        let input = SessionNotesTool.SessionNotesInput(
            sessionNotes: sessionNotes,
            summaryType: "detailed",
            focusAreas: ["workflow"],
            wordCount: 200
        )

        let result = try await sessionTool.handle(input)

        XCTAssertNotNil(result.summary)
        XCTAssertTrue(result.summary?.actionItems?.isEmpty ?? true)
    }

    // MARK: - Technical Details Processing Tests

    func testTechnicalDetailsProcessing() async throws {
        let sessionNotes = createTestSessionNotes()
        let input = SessionNotesTool.SessionNotesInput(
            sessionNotes: sessionNotes,
            summaryType: "detailed",
            focusAreas: ["technical"],
            wordCount: 250
        )

        let result = try await sessionTool.handle(input)

        XCTAssertNotNil(result.summary)

        // Verify technical details are incorporated
        let content = result.summary?.overview ?? ""
        let technicalHighlights = result.summary?.technicalHighlights?.joined(separator: " ") ?? ""
        let fullTechnicalContent = (content + " " + technicalHighlights).lowercased()

        XCTAssertTrue(fullTechnicalContent.contains("48khz") || fullTechnicalContent.contains("24-bit"))
        XCTAssertTrue(fullTechnicalContent.contains("neumann") || fullTechnicalContent.contains("api"))
    }

    func testTechnicalDetailsWithEmptyData() async throws {
        var sessionNotes = createTestSessionNotes()
        sessionNotes.technicalDetails = SessionNotesTool.TechnicalDetails(
            sampleRate: "",
            bitDepth: "",
            buffer: "",
            recordingFormat: "",
            driveConfiguration: "",
            pluginsUsed: []
        )

        let input = SessionNotesTool.SessionNotesInput(
            sessionNotes: sessionNotes,
            summaryType: "detailed",
            focusAreas: ["technical"],
            wordCount: 200
        )

        let result = try await sessionTool.handle(input)

        XCTAssertNotNil(result.summary)
        // Should still generate a summary even with minimal technical data
        XCTAssertNotNil(result.summary?.technicalHighlights)
    }

    // MARK: - Word Count Tests

    func testWordCountAccuracy() async throws {
        let sessionNotes = createTestSessionNotes()
        let targetWordCount = 300

        let input = SessionNotesTool.SessionNotesInput(
            sessionNotes: sessionNotes,
            summaryType: "detailed",
            focusAreas: ["technical", "creative"],
            wordCount: targetWordCount
        )

        let result = try await sessionTool.handle(input)

        XCTAssertNotNil(result.summary)
        let actualWordCount = result.summary?.wordCount ?? 0

        // Should be reasonably close to target (within 20% margin)
        let lowerBound = Double(targetWordCount) * 0.8
        let upperBound = Double(targetWordCount) * 1.2
        XCTAssertGreaterThanOrEqual(Double(actualWordCount), lowerBound)
        XCTAssertLessThanOrEqual(Double(actualWordCount), upperBound)
    }

    func testBriefSummaryWordCount() async throws {
        let sessionNotes = createTestSessionNotes()
        let targetWordCount = 150

        let input = SessionNotesTool.SessionNotesInput(
            sessionNotes: sessionNotes,
            summaryType: "brief",
            focusAreas: ["essential"],
            wordCount: targetWordCount
        )

        let result = try await sessionTool.handle(input)

        XCTAssertNotNil(result.summary)
        let actualWordCount = result.summary?.wordCount ?? 0

        // Brief summary should be shorter
        XCTAssertLessThanOrEqual(actualWordCount, 200)
    }

    func testComprehensiveSummaryWordCount() async throws {
        let sessionNotes = createTestSessionNotes()
        let targetWordCount = 600

        let input = SessionNotesTool.SessionNotesInput(
            sessionNotes: sessionNotes,
            summaryType: "comprehensive",
            focusAreas: ["technical", "creative", "workflow", "analysis"],
            wordCount: targetWordCount
        )

        let result = try await sessionTool.handle(input)

        XCTAssertNotNil(result.summary)
        let actualWordCount = result.summary?.wordCount ?? 0

        // Comprehensive summary should be longer
        XCTAssertGreaterThan(actualWordCount, 400)
        XCTAssertLessThanOrEqual(actualWordCount, 800)
    }

    // MARK: - Edge Cases and Error Handling Tests

    func testSummarizeSessionWithNilValues() async throws {
        let sessionWithNilValues = SessionNotesTool.SessionNotes(
            date: nil,
            startTime: nil,
            endTime: nil,
            engineer: nil,
            assistant: nil,
            studio: nil,
            project: nil,
            musicians: nil,
            equipment: nil,
            technicalDetails: nil,
            notes: nil,
            actionItems: nil,
            nextSession: nil,
            weather: nil
        )

        let input = SessionNotesTool.SessionNotesInput(
            sessionNotes: sessionWithNilValues,
            summaryType: "detailed",
            focusAreas: ["technical"],
            wordCount: 200
        )

        let result = try await sessionTool.handle(input)

        XCTAssertNotNil(result.summary)
        XCTAssertNotNil(result.summary?.title)
        // Should handle nil values gracefully
    }

    func testSummarizeSessionWithExtremelyLongContent() async throws {
        var sessionNotes = createTestSessionNotes()

        // Create very long content
        let longNotes = String(repeating: "This is a very long session note with lots of repetitive content to test how the summarizer handles large amounts of text. ", count: 100)
        sessionNotes.notes = longNotes

        // Add many action items
        var manyActionItems: [SessionNotesTool.ActionItem] = []
        for i in 1...50 {
            manyActionItems.append(SessionNotesTool.ActionItem(
                task: "Task \(i): Handle various session-related activities and requirements",
                priority: i % 2 == 0 ? "high" : "medium",
                assignedTo: "Engineer \(i % 3)",
                dueDate: "2025-10-\(10 + i % 20)"
            ))
        }
        sessionNotes.actionItems = manyActionItems

        let input = SessionNotesTool.SessionNotesInput(
            sessionNotes: sessionNotes,
            summaryType: "detailed",
            focusAreas: ["technical", "workflow"],
            wordCount: 300
        )

        let result = try await sessionTool.handle(input)

        XCTAssertNotNil(result.summary)
        XCTAssertLessThanOrEqual(result.summary?.wordCount ?? 0, 400)
        // Should condense large amounts of information appropriately
    }

    func testSummarizeSessionWithSpecialCharacters() async throws {
        var sessionNotes = createTestSessionNotes()
        sessionNotes.notes = """
        Session notes with special characters: é, ü, ñ, ç, 中文, русский, العربية, 🎵, 🎧, 🎹, 🎸.

        Technical settings: 48kHz, 24-bit, 128 samples buffer.
        Equipment used: Neumann U87, API 512, Universal Audio Apollo.

        Performance notes: Excellent vocal delivery with emotional range & dynamic control.
        Guitar tone: Warm, vintage character with slight mid-range emphasis.
        """

        let input = SessionNotesTool.SessionNotesInput(
            sessionNotes: sessionNotes,
            summaryType: "detailed",
            focusAreas: ["technical", "creative"],
            wordCount: 200
        )

        let result = try await sessionTool.handle(input)

        XCTAssertNotNil(result.summary)
        // Should handle special characters and unicode properly
        XCTAssertNotNil(result.summary?.overview)
        XCTAssertFalse(result.summary?.overview?.isEmpty ?? true)
    }

    func testSummarizeSessionWithMinimalFocusAreas() async throws {
        let sessionNotes = createTestSessionNotes()
        let input = SessionNotesTool.SessionNotesInput(
            sessionNotes: sessionNotes,
            summaryType: "detailed",
            focusAreas: [], // Empty focus areas
            wordCount: 200
        )

        let result = try await sessionTool.handle(input)

        XCTAssertNotNil(result.summary)
        // Should still generate a summary even with no focus areas specified
        XCTAssertNotNil(result.summary?.overview)
    }

    // MARK: - Performance Tests

    func testSummarizePerformanceWithLargeDataset() async throws {
        let startTime = CFAbsoluteTimeGetCurrent()

        var sessionNotes = createTestSessionNotes()

        // Create large dataset
        let largeNotes = String(repeating: "Extended session content with technical details, creative insights, workflow information, and various musical aspects. ", count: 200)
        sessionNotes.notes = largeNotes

        let input = SessionNotesTool.SessionNotesInput(
            sessionNotes: sessionNotes,
            summaryType: "comprehensive",
            focusAreas: ["technical", "creative", "workflow", "analysis"],
            wordCount: 500
        )

        let result = try await sessionTool.handle(input)

        let processingTime = CFAbsoluteTimeGetCurrent() - startTime

        XCTAssertNotNil(result.summary)
        XCTAssertLessThan(processingTime, 3.0, "Summarization should complete within 3 seconds")
    }
}