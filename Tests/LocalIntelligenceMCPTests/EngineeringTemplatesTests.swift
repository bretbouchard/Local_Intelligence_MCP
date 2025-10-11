//
//  EngineeringTemplatesTests.swift
//  LocalIntelligenceMCPTests
//
//  Created on 2025-10-09.
//

import XCTest
@testable import LocalIntelligenceMCP

final class EngineeringTemplatesTests: XCTestCase {

    // MARK: - Session Template Tests

    func testTrackingSessionTemplate() {
        let template = EngineeringTemplates.trackingSessionTemplate()

        XCTAssertFalse(template.isEmpty)

        // Verify template contains expected placeholders
        let expectedPlaceholders = [
            "TRACKING SESSION NOTES",
            "SESSION OVERVIEW",
            "Date: {date}",
            "Engineer: {engineer}",
            "Assistant: {assistant}",
            "Project: {project}",
            "Location: {studio}",
            "EQUIPMENT USED",
            "Microphones: {microphones}",
            "Preamps: {preamps}",
            "Converters: {converters}",
            "DAW: {daw}",
            "Interface: {interface}",
            "INSTRUMENTS TRACKED",
            "{instruments_list}",
            "TECHNICAL SETTINGS",
            "Sample Rate: {sample_rate}",
            "Bit Depth: {bit_depth}",
            "Buffer Size: {buffer_size}",
            "KEY PERFORMANCES",
            "{performances_notes}",
            "ISSUES & SOLUTIONS",
            "{issues_solutions}",
            "NEXT STEPS",
            "{next_steps}",
            "FILES CREATED",
            "{files_list}"
        ]

        for placeholder in expectedPlaceholders {
            XCTAssertTrue(template.contains(placeholder), "Template should contain '\(placeholder)'")
        }
    }

    func testMixingSessionTemplate() {
        let template = EngineeringTemplates.mixingSessionTemplate()

        XCTAssertFalse(template.isEmpty)

        // Verify template contains expected placeholders
        let expectedPlaceholders = [
            "MIXING SESSION NOTES",
            "SESSION OVERVIEW",
            "Date: {date}",
            "Mix Engineer: {engineer}",
            "Project: {project}",
            "Song: {song}",
            "Client: {client}",
            "MIX GOAL",
            "{mix_goal}",
            "REFERENCE TRACKS",
            "{reference_tracks}",
            "SIGNAL CHAIN",
            "Processing Chain:",
            "{processing_chain}",
            "MIX SETTINGS",
            "Key Settings:",
            "• Kick: {kick_settings}",
            "• Snare: {snare_settings}",
            "• Bass: {bass_settings}",
            "• Vocals: {vocals_settings}",
            "• Guitars: {guitars_settings}",
            "• Keys: {keys_settings}",
            "• Drums: {drums_settings}",
            "AUTOMATION",
            "{automation_notes}",
            "EFFECTS USED",
            "Reverbs: {reverbs}",
            "Delays: {delays}",
            "Other FX: {other_fx}",
            "CLIENT NOTES",
            "{client_notes}",
            "REVISION REQUESTS",
            "{revision_requests}",
            "NEXT SESSION",
            "{next_session_notes}",
            "EXPORT SETTINGS",
            "{export_settings}"
        ]

        for placeholder in expectedPlaceholders {
            XCTAssertTrue(template.contains(placeholder), "Mixing template should contain '\(placeholder)'")
        }
    }

    func testMasteringSessionTemplate() {
        let template = EngineeringTemplates.masteringSessionTemplate()

        XCTAssertFalse(template.isEmpty)

        // Verify template contains expected placeholders
        let expectedPlaceholders = [
            "MASTERING SESSION NOTES",
            "SESSION OVERVIEW",
            "Date: {date}",
            "Mastering Engineer: {engineer}",
            "Project: {project}",
            "Artist: {artist}",
            "Album/EP: {album}",
            "SOURCE ANALYSIS",
            "Mix Analysis:",
            "• Dynamic Range: {dynamic_range}",
            "• Frequency Balance: {frequency_balance}",
            "• Stereo Image: {stereo_image}",
            "• Loudness: {current_loudness}",
            "CHAIN CONFIGURATION",
            "1. {eq_settings}",
            "2. {compression_settings}",
            "3. {saturation_settings}",
            "4. {limiter_settings}",
            "PROCESSING NOTES",
            "{processing_notes}",
            "COMPARISONS",
            "Reference Tracks Used:",
            "{reference_comparisons}",
            "FINAL SETTINGS",
            "Target Loudness: {target_loudness}",
            "True Peak: {true_peak}",
            "LUFS Integrated: {lufs_integrated}",
            "LUFS Short-term: {lufs_shortterm}",
            "CLIENT APPROVAL",
            "{client_approval_status}",
            "DELIVERY FORMATS",
            "{delivery_formats}",
            "NOTES",
            "{final_notes}"
        ]

        for placeholder in expectedPlaceholders {
            XCTAssertTrue(template.contains(placeholder), "Mastering template should contain '\(placeholder)'")
        }
    }

    // MARK: - Feedback Template Tests

    func testClientFeedbackTemplate() {
        let template = EngineeringTemplates.clientFeedbackTemplate()

        XCTAssertFalse(template.isEmpty)

        // Verify template contains expected placeholders
        let expectedPlaceholders = [
            "CLIENT FEEDBACK REPORT",
            "PROJECT INFORMATION",
            "Project: {project}",
            "Client: {client}",
            "Review Date: {review_date}",
            "Review Type: {review_type}",
            "OVERALL IMPRESSION",
            "Sentiment: {overall_sentiment}",
            "Key Response: {key_response}",
            "SPECIFIC FEEDBACK",
            "MIX BALANCE",
            "{mix_balance_feedback}",
            "TONAL CHARACTER",
            "{tonal_feedback}",
            "DYNAMICS & ENERGY",
            "{dynamics_feedback}",
            "CREATIVE DIRECTION",
            "{creative_feedback}",
            "TECHNICAL CONCERNS",
            "{technical_feedback}",
            "PRIORITY ACTION ITEMS",
            "{priority_items}",
            "CLIENT PREFERENCES",
            "{client_preferences}",
            "NEXT STEPS",
            "{next_steps}",
            "DEADLINES",
            "{deadlines}"
        ]

        for placeholder in expectedPlaceholders {
            XCTAssertTrue(template.contains(placeholder), "Client feedback template should contain '\(placeholder)'")
        }
    }

    func testInternalReviewTemplate() {
        let template = EngineeringTemplates.internalReviewTemplate()

        XCTAssertFalse(template.isEmpty)

        // Verify template contains expected placeholders
        let expectedPlaceholders = [
            "INTERNAL MIX REVIEW",
            "REVIEW DETAILS",
            "Reviewer: {reviewer}",
            "Date: {review_date}",
            "Project: {project}",
            "Song: {song}",
            "TECHNICAL ASSESSMENT",
            "CLARITY & DEFINITION",
            "• Vocals: {vocals_clarity}",
            "• Instruments: {instruments_clarity}",
            "• Separation: {separation_quality}",
            "BALANCE & PROPORTION",
            "• Level Balance: {level_balance}",
            "• Frequency Balance: {freq_balance}",
            "• Stereo Image: {stereo_image}",
            "DYNAMIC PROCESSING",
            "• Compression: {compression_assessment}",
            "• Limiting: {limiting_assessment}",
            "• Overall Dynamics: {dynamics_assessment}",
            "EFFECTS & ATMOSPHERE",
            "• Reverbs: {reverbs_assessment}",
            "• Delays: {delays_assessment}",
            "• Creative FX: {creative_fx_assessment}",
            "CREATIVE EVALUATION",
            "Emotional Impact: {emotional_impact}",
            "Energy Level: {energy_level}",
            "Commercial Viability: {commercial_viability}",
            "CRITICAL ISSUES",
            "{critical_issues}",
            "SUGGESTED IMPROVEMENTS",
            "{improvements}",
            "OVERALL RATING",
            "Technical Score: {technical_score}/10",
            "Creative Score: {creative_score}/10",
            "Overall Score: {overall_score}/10",
            "RECOMMENDATIONS",
            "{recommendations}"
        ]

        for placeholder in expectedPlaceholders {
            XCTAssertTrue(template.contains(placeholder), "Internal review template should contain '\(placeholder)'")
        }
    }

    // MARK: - Technical Report Template Tests

    func testGearSetupTemplate() {
        let template = EngineeringTemplates.gearSetupTemplate()

        XCTAssertFalse(template.isEmpty)

        // Verify template contains expected placeholders
        let expectedPlaceholders = [
            "STUDIO GEAR & SETUP REPORT",
            "SETUP DATE: {setup_date}",
            "ENGINEER: {engineer}",
            "PROJECT: {project}",
            "SIGNAL FLOW DIAGRAM",
            "{signal_flow_diagram}",
            "MICROPHONES",
            "{microphone_list}",
            "PREAMPLIFIERS",
            "{preamp_list}",
            "OUTBOARD GEAR",
            "{outboard_gear}",
            "MONITORING SETUP",
            "• Monitors: {monitors}",
            "• Room Treatment: {room_treatment}",
            "• Monitoring Level: {monitoring_level}",
            "SOFTWARE & PLUGINS",
            "DAW: {daw_version}",
            "Key Plugins: {key_plugins}",
            "CALIBRATION NOTES",
            "{calibration_notes}",
            "MEASUREMENTS",
            "Room Response: {room_response}",
            "Frequency Response: {frequency_response}",
            "MAINTENANCE NEEDED",
            "{maintenance_items}",
            "UPGRADE RECOMMENDATIONS",
            "{upgrade_recommendations}"
        ]

        for placeholder in expectedPlaceholders {
            XCTAssertTrue(template.contains(placeholder), "Gear setup template should contain '\(placeholder)'")
        }
    }

    func testTroubleshootingTemplate() {
        let template = EngineeringTemplates.troubleshootingTemplate()

        XCTAssertFalse(template.isEmpty)

        // Verify template contains expected placeholders
        let expectedPlaceholders = [
            "AUDIO TROUBLESHOOTING REPORT",
            "ISSUE REPORTED",
            "Date: {issue_date}",
            "Reported by: {reporter}",
            "Project: {project}",
            "Severity: {severity}",
            "PROBLEM DESCRIPTION",
            "{problem_description}",
            "ENVIRONMENT",
            "System: {system_info}",
            "Software: {software_info}",
            "Hardware: {hardware_info}",
            "DIAGNOSTIC STEPS",
            "{diagnostic_steps}",
            "ROOT CAUSE ANALYSIS",
            "{root_cause}",
            "SOLUTION IMPLEMENTED",
            "{solution}",
            "VERIFICATION",
            "{verification_steps}",
            "PREVENTION MEASURES",
            "{prevention_measures}",
            "IMPACT ASSESSMENT",
            "{impact_assessment}",
            "FOLLOW-UP REQUIRED",
            "{follow_up}"
        ]

        for placeholder in expectedPlaceholders {
            XCTAssertTrue(template.contains(placeholder), "Troubleshooting template should contain '\(placeholder)'")
        }
    }

    // MARK: - Specialized Summary Template Tests

    func testDailySessionSummary() {
        let template = EngineeringTemplates.dailySessionSummary()

        XCTAssertFalse(template.isEmpty)

        // Verify template contains expected placeholders
        let expectedPlaceholders = [
            "DAILY SESSION SUMMARY",
            "Date: {date}",
            "Engineer: {engineer}",
            "SESSIONS COMPLETED",
            "{sessions_completed}",
            "PROJECTS WORKED ON",
            "{projects_worked_on}",
            "TIME TRACKING",
            "Total Hours: {total_hours}",
            "Billable Hours: {billable_hours}",
            "ACCOMPLISHMENTS",
            "{accomplishments}",
            "CHALLENGES FACED",
            "{challenges}",
            "EQUIPMENT ISSUES",
            "{equipment_issues}",
            "CLIENT COMMUNICATIONS",
            "{client_communications}",
            "FILES BACKED UP",
            "{files_backed_up}",
            "TOMORROW'S PRIORITIES",
            "{tomorrow_priorities}",
            "NOTES",
            "{notes}"
        ]

        for placeholder in expectedPlaceholders {
            XCTAssertTrue(template.contains(placeholder), "Daily summary template should contain '\(placeholder)'")
        }
    }

    func testProjectStatusTemplate() {
        let template = EngineeringTemplates.projectStatusTemplate()

        XCTAssertFalse(template.isEmpty)

        // Verify template contains expected placeholders
        let expectedPlaceholders = [
            "PROJECT STATUS REPORT",
            "Project: {project}",
            "Client: {client}",
            "Status Date: {status_date}",
            "PROJECT OVERVIEW",
            "Start Date: {start_date}",
            "Target Completion: {target_completion}",
            "Current Status: {current_status}",
            "WORK COMPLETED",
            "{work_completed}",
            "CURRENT PHASE",
            "Phase: {current_phase}",
            "Progress: {progress_percentage}",
            "REMAINING WORK",
            "{remaining_work}",
            "ISSUES & BLOCKERS",
            "{issues_blockers}",
            "BUDGET STATUS",
            "Budget Allocated: {budget_allocated}",
            "Budget Spent: {budget_spent}",
            "Remaining: {budget_remaining}",
            "NEXT MILESTONE",
            "{next_milestone}",
            "Target Date: {milestone_date}",
            "TEAM NOTES",
            "{team_notes}",
            "CLIENT UPDATES",
            "{client_updates}",
            "ACTION ITEMS",
            "{action_items}"
        ]

        for placeholder in expectedPlaceholders {
            XCTAssertTrue(template.contains(placeholder), "Project status template should contain '\(placeholder)'")
        }
    }

    // MARK: - Template Population Tests

    func testPopulateTemplateBasic() {
        let template = "Hello {name}, your project {project} is ready for review on {date}."
        let values = [
            "name": "John",
            "project": "Rock Album",
            "date": "2025-10-09"
        ]

        let populated = EngineeringTemplates.populateTemplate(template, with: values)

        XCTAssertEqual(populated, "Hello John, your project Rock Album is ready for review on 2025-10-09.")
    }

    func testPopulateTemplateEmptyValues() {
        let template = "Project: {project}, Engineer: {engineer}, Date: {date}"
        let values: [String: String] = [:]

        let populated = EngineeringTemplates.populateTemplate(template, with: values)

        // Should leave placeholders unchanged when no values provided
        XCTAssertEqual(populated, "Project: {project}, Engineer: {engineer}, Date: {date}")
    }

    func testPopulateTemplatePartialValues() {
        let template = "Project: {project}, Engineer: {engineer}, Studio: {studio}"
        let values = [
            "project": "Pop Single",
            "studio": "Studio A"
            // Missing engineer value
        ]

        let populated = EngineeringTemplates.populateTemplate(template, with: values)

        XCTAssertEqual(populated, "Project: Pop Single, Engineer: {engineer}, Studio: Studio A")
    }

    func testPopulateTemplateSpecialCharacters() {
        let template = "Client: {client}, Notes: {notes}, Amount: ${amount}"
        let values = [
            "client": "José García",
            "notes": "Great work! Needs minor adjustments in the chorus section.",
            "amount": "500.00"
        ]

        let populated = EngineeringTemplates.populateTemplate(template, with: values)

        XCTAssertEqual(populated, "Client: José García, Notes: Great work! Needs minor adjustments in the chorus section., Amount: $500.00")
    }

    func testPopulateTemplateRepeatedPlaceholders() {
        let template = "{project} - {project} by {artist}. Reviewer: {name}, Client: {name}."
        let values = [
            "project": "Summer Hit",
            "artist": "The Band",
            "name": "John Smith"
        ]

        let populated = EngineeringTemplates.populateTemplate(template, with: values)

        XCTAssertEqual(populated, "Summer Hit - Summer Hit by The Band. Reviewer: John Smith, Client: John Smith.")
    }

    func testPopulateTemplateNoPlaceholders() {
        let template = "This is a static text with no placeholders."
        let values = [
            "project": "Test Project",
            "engineer": "Test Engineer"
        ]

        let populated = EngineeringTemplates.populateTemplate(template, with: values)

        XCTAssertEqual(populated, "This is a static text with no placeholders.")
    }

    func testPopulateTemplateWithBracesInContent() {
        let template = "Use EQ at {frequency}Hz with {gain}dB boost. Filter slope: 24dB/octave."
        let values = [
            "frequency": "100",
            "gain": "+3"
        ]

        let populated = EngineeringTemplates.populateTemplate(template, with: values)

        XCTAssertEqual(populated, "Use EQ at 100Hz with +3dB boost. Filter slope: 24dB/octave.")
    }

    // MARK: - Default Values Tests

    func testGetDefaultValuesForTracking() {
        let defaultValues = EngineeringTemplates.getDefaultValues(for: "tracking")

        XCTAssertNotNil(defaultValues["date"])
        XCTAssertNotNil(defaultValues["engineer"])
        XCTAssertNotNil(defaultValues["project"])
        XCTAssertNotNil(defaultValues["studio"])
        XCTAssertEqual(defaultValues["assistant"], "Assistant Name")
        XCTAssertEqual(defaultValues["microphones"], "List microphones used")
        XCTAssertEqual(defaultValues["preamps"], "List preamps used")
        XCTAssertEqual(defaultValues["converters"], "ADC/DAC information")
        XCTAssertEqual(defaultValues["daw"], "DAW software and version")
        XCTAssertEqual(defaultValues["interface"], "Audio interface")
        XCTAssertEqual(defaultValues["sample_rate"], "48 kHz")
        XCTAssertEqual(defaultValues["bit_depth"], "24-bit")
        XCTAssertEqual(defaultValues["buffer_size"], "128 samples")
        XCTAssertEqual(defaultValues["instruments_list"], "List instruments tracked")
        XCTAssertEqual(defaultValues["performances_notes"], "Notes on performances")
        XCTAssertEqual(defaultValues["issues_solutions"], "Any issues and how they were resolved")
        XCTAssertEqual(defaultValues["next_steps"], "What needs to be done next")
        XCTAssertEqual(defaultValues["files_list"], "List of files created")
    }

    func testGetDefaultValuesForMixing() {
        let defaultValues = EngineeringTemplates.getDefaultValues(for: "mixing")

        XCTAssertNotNil(defaultValues["date"])
        XCTAssertNotNil(defaultValues["engineer"])
        XCTAssertNotNil(defaultValues["project"])
        XCTAssertEqual(defaultValues["song"], "Song Title")
        XCTAssertEqual(defaultValues["client"], "Client Name")
        XCTAssertEqual(defaultValues["mix_goal"], "Describe the intended outcome")
        XCTAssertEqual(defaultValues["reference_tracks"], "List reference tracks")
        XCTAssertEqual(defaultValues["processing_chain"], "Describe main signal chain")
        XCTAssertEqual(defaultValues["kick_settings"], "Kick drum processing")
        XCTAssertEqual(defaultValues["snare_settings"], "Snare drum processing")
        XCTAssertEqual(defaultValues["bass_settings"], "Bass processing")
        XCTAssertEqual(defaultValues["vocals_settings"], "Vocal processing")
        XCTAssertEqual(defaultValues["guitars_settings"], "Guitar processing")
        XCTAssertEqual(defaultValues["keys_settings"], "Keys/synth processing")
        XCTAssertEqual(defaultValues["drums_settings"], "Overall drum processing")
        XCTAssertEqual(defaultValues["automation_notes"], "Automation details")
        XCTAssertEqual(defaultValues["reverbs"], "Reverb plugins and settings")
        XCTAssertEqual(defaultValues["delays"], "Delay plugins and settings")
        XCTAssertEqual(defaultValues["other_fx"], "Other effects")
        XCTAssertEqual(defaultValues["client_notes"], "Client feedback and requests")
        XCTAssertEqual(defaultValues["revision_requests"], "Specific changes requested")
        XCTAssertEqual(defaultValues["next_session_notes"], "Plans for next session")
        XCTAssertEqual(defaultValues["export_settings"], "Export format and settings")
    }

    func testGetDefaultValuesForMastering() {
        let defaultValues = EngineeringTemplates.getDefaultValues(for: "mastering")

        XCTAssertNotNil(defaultValues["date"])
        XCTAssertNotNil(defaultValues["engineer"])
        XCTAssertNotNil(defaultValues["project"])
        XCTAssertEqual(defaultValues["artist"], "Artist Name")
        XCTAssertEqual(defaultValues["album"], "Album/EP Title")
        XCTAssertEqual(defaultValues["dynamic_range"], "DR measurement")
        XCTAssertEqual(defaultValues["frequency_balance"], "Frequency analysis")
        XCTAssertEqual(defaultValues["stereo_image"], "Stereo field analysis")
        XCTAssertEqual(defaultValues["current_loudness"], "LUFS measurement")
        XCTAssertEqual(defaultValues["eq_settings"], "Equalizer settings")
        XCTAssertEqual(defaultValues["compression_settings"], "Compression settings")
        XCTAssertEqual(defaultValues["saturation_settings"], "Saturation/harmonic processing")
        XCTAssertEqual(defaultValues["limiter_settings"], "Limiter settings")
        XCTAssertEqual(defaultValues["processing_notes"], "Detailed processing notes")
        XCTAssertEqual(defaultValues["reference_comparisons"], "Comparison with reference tracks")
        XCTAssertEqual(defaultValues["target_loudness"], "Target LUFS")
        XCTAssertEqual(defaultValues["true_peak"], "True peak ceiling")
        XCTAssertEqual(defaultValues["lufs_integrated"], "Integrated LUFS")
        XCTAssertEqual(defaultValues["lufs_shortterm"], "Short-term LUFS")
        XCTAssertEqual(defaultValues["client_approval_status"], "Approved/rejected/pending")
        XCTAssertEqual(defaultValues["delivery_formats"], "Required delivery formats")
        XCTAssertEqual(defaultValues["final_notes"], "Additional notes")
    }

    func testGetDefaultValuesForUnknownSessionType() {
        let defaultValues = EngineeringTemplates.getDefaultValues(for: "unknown_type")

        // Should return base values for unknown types
        XCTAssertNotNil(defaultValues["date"])
        XCTAssertNotNil(defaultValues["engineer"])
        XCTAssertNotNil(defaultValues["project"])
        XCTAssertNotNil(defaultValues["studio"])

        // Should not include type-specific values
        XCTAssertNil(defaultValues["song"])
        XCTAssertNil(defaultValues["client"])
        XCTAssertNil(defaultValues["artist"])
        XCTAssertNil(defaultValues["album"])
    }

    func testGetDefaultValuesCaseInsensitive() {
        let lowercaseValues = EngineeringTemplates.getDefaultValues(for: "tracking")
        let uppercaseValues = EngineeringTemplates.getDefaultValues(for: "TRACKING")
        let mixedCaseValues = EngineeringTemplates.getDefaultValues(for: "Tracking")

        // Should be case insensitive
        XCTAssertEqual(lowercaseValues["sample_rate"], uppercaseValues["sample_rate"])
        XCTAssertEqual(lowercaseValues["sample_rate"], mixedCaseValues["sample_rate"])
    }

    // MARK: - Integration Tests

    func testCompleteTrackingSessionWorkflow() {
        // Get template
        let template = EngineeringTemplates.trackingSessionTemplate()

        // Get default values
        var values = EngineeringTemplates.getDefaultValues(for: "tracking")

        // Override with custom values
        values.merge([
            "engineer": "John Smith",
            "assistant": "Jane Doe",
            "project": "Rock Album - Track 1",
            "studio": "Studio A",
            "microphones": "Neumann U87 (vocal), SM57 (guitar amp)",
            "preamps": "API 512 (vocal), Neve 1073 (guitar)",
            "instruments_list": "Lead vocal, Electric guitar, Bass guitar",
            "performances_notes": "Excellent vocal performance, guitar needs retake on bridge",
            "issues_solutions": "Ground hum resolved by checking cable connections",
            "next_steps": "Record bass tomorrow, schedule drums for next week",
            "files_list": "Vocal_Lead_01.wav, Guitar_Rhythm_01.wav"
        ]) { $1 }

        // Populate template
        let populated = EngineeringTemplates.populateTemplate(template, with: values)

        // Verify key content is present
        XCTAssertTrue(populated.contains("John Smith"))
        XCTAssertTrue(populated.contains("Jane Doe"))
        XCTAssertTrue(populated.contains("Rock Album - Track 1"))
        XCTAssertTrue(populated.contains("Studio A"))
        XCTAssertTrue(populated.contains("Neumann U87"))
        XCTAssertTrue(populated.contains("API 512"))
        XCTAssertTrue(populated.contains("Ground hum resolved"))

        // Verify placeholders are replaced
        XCTAssertFalse(populated.contains("{engineer}"))
        XCTAssertFalse(populated.contains("{project}"))
        XCTAssertFalse(populated.contains("{microphones}"))
    }

    func testCompleteMixingSessionWorkflow() {
        // Get template
        let template = EngineeringTemplates.mixingSessionTemplate()

        // Get default values and customize
        var values = EngineeringTemplates.getDefaultValues(for: "mixing")
        values.merge([
            "engineer": "Alex Turner",
            "project": "Pop Single",
            "song": "Summer Vibes",
            "client": "Emily Chen",
            "mix_goal": "Modern pop sound with warm vintage character",
            "reference_tracks": "Blinding Lights, Levitating",
            "kick_settings": "API 2500, 4:1 ratio, 3dB GR",
            "vocals_settings": "CLA-76, LA-2A, de-ess, EQ",
            "client_notes": "Loves the vocal sound, wants more low end in chorus",
            "revision_requests": "Add +2dB at 80Hz in chorus sections",
            "export_settings": "WAV 24-bit, -1dBTP, -14 LUFS integrated"
        ]) { $1 }

        // Populate template
        let populated = EngineeringTemplates.populateTemplate(template, with: values)

        // Verify content
        XCTAssertTrue(populated.contains("Alex Turner"))
        XCTAssertTrue(populated.contains("Summer Vibes"))
        XCTAssertTrue(populated.contains("Emily Chen"))
        XCTAssertTrue(populated.contains("Modern pop sound"))
        XCTAssertTrue(populated.contains("CLA-76"))
        XCTAssertTrue(populated.contains("Blinding Lights"))
    }

    func testCompleteFeedbackWorkflow() {
        // Get template
        let template = EngineeringTemplates.clientFeedbackTemplate()

        // Create feedback values
        let values = [
            "project": "Rock Album",
            "client": "Robert Johnson",
            "review_date": "2025-10-09",
            "review_type": "Mix Review v2",
            "overall_sentiment": "Positive with minor suggestions",
            "key_response": "Great work overall, just need some small adjustments",
            "mix_balance_feedback": "Vocals could be 1-2dB louder in chorus",
            "tonal_feedback": "Guitars sound great, maybe slight brightness boost",
            "dynamics_feedback": "Drum impact is excellent, perfect energy",
            "priority_items": "1. Raise vocal level in chorus, 2. Add 1dB at 8kHz to guitars",
            "next_steps": "Implement revisions and send v3 for approval",
            "deadlines": "Client needs final version by Friday EOD"
        ]

        // Populate template
        let populated = EngineeringTemplates.populateTemplate(template, with: values)

        // Verify content
        XCTAssertTrue(populated.contains("Rock Album"))
        XCTAssertTrue(populated.contains("Robert Johnson"))
        XCTAssertTrue(populated.contains("Positive with minor suggestions"))
        XCTAssertTrue(populated.contains("Vocals could be 1-2dB louder"))
        XCTAssertTrue(populated.contains("Drum impact is excellent"))
        XCTAssertTrue(populated.contains("Friday EOD"))
    }

    // MARK: - Edge Cases Tests

    func testPopulateTemplateWithNilValues() {
        let template = "Project: {project}, Engineer: {engineer}"
        let values = [
            "project": "Test Project",
            "engineer": "" // Empty string
        ]

        let populated = EngineeringTemplates.populateTemplate(template, with: values)

        XCTAssertEqual(populated, "Project: Test Project, Engineer: ")
    }

    func testPopulateTemplateWithUnicodeContent() {
        let template = "Artist: {artist}, Song: {song}, Notes: {notes}"
        let values = [
            "artist": "José García",
            "song": "Canción de Amor ❤️",
            "notes": "Excellent performance with emotional depth 💫"
        ]

        let populated = EngineeringTemplates.populateTemplate(template, with: values)

        XCTAssertEqual(populated, "Artist: José García, Song: Canción de Amor ❤️, Notes: Excellent performance with emotional depth 💫")
    }

    func testTemplatePlaceholderEdgeCases() {
        // Test with malformed placeholders
        let template = "Content: {incomplete}, Content: {toolongcontentname}, Content: {}"
        let values = [
            "incomplete": "value1"
        ]

        let populated = EngineeringTemplates.populateTemplate(template, with: values)

        XCTAssertEqual(populated, "Content: value1, Content: {toolongcontentname}, Content: {}")
    }

    func testTemplateWithVeryLongValues() {
        let template = "Description: {description}"
        let longDescription = String(repeating: "This is a very long description that goes on and on. ", count: 20)
        let values = ["description": longDescription]

        let populated = EngineeringTemplates.populateTemplate(template, with: values)

        XCTAssertTrue(populated.hasPrefix("Description: This is a very long description"))
        XCTAssertEqual(populated.count, "Description: ".count + longDescription.count)
    }

    // MARK: - Performance Tests

    func testTemplatePopulationPerformance() {
        let template = EngineeringTemplates.trackingSessionTemplate()
        var values = EngineeringTemplates.getDefaultValues(for: "tracking")

        // Add many custom values
        for i in 1...100 {
            values["custom_\(i)"] = "Custom value \(i)"
        }

        let startTime = CFAbsoluteTimeGetCurrent()
        let populated = EngineeringTemplates.populateTemplate(template, with: values)
        let processingTime = CFAbsoluteTimeGetCurrent() - startTime

        XCTAssertFalse(populated.isEmpty)
        XCTAssertLessThan(processingTime, 0.1, "Template population should be very fast")
    }

    func testMultipleTemplatePopulationPerformance() {
        let templates = [
            EngineeringTemplates.trackingSessionTemplate(),
            EngineeringTemplates.mixingSessionTemplate(),
            EngineeringTemplates.masteringSessionTemplate(),
            EngineeringTemplates.clientFeedbackTemplate(),
            EngineeringTemplates.internalReviewTemplate()
        ]

        let values = [
            "project": "Test Project",
            "engineer": "Test Engineer",
            "date": "2025-10-09",
            "client": "Test Client"
        ]

        let startTime = CFAbsoluteTimeGetCurrent()

        for template in templates {
            let populated = EngineeringTemplates.populateTemplate(template, with: values)
            XCTAssertFalse(populated.isEmpty)
        }

        let processingTime = CFAbsoluteTimeGetCurrent() - startTime

        XCTAssertLessThan(processingTime, 0.2, "Multiple template populations should be fast")
    }
}