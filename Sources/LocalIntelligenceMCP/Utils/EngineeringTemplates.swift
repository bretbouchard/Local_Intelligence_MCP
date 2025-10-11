//
//  EngineeringTemplates.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-09.
//

import Foundation

/// Engineering-specific templates for audio production documentation
/// Provides standardized formats for session notes, feedback reports, and technical summaries
public struct EngineeringTemplates: @unchecked Sendable {

    // MARK: - Session Templates

    /// Generate tracking session template
    public static func trackingSessionTemplate() -> String {
        return """
        TRACKING SESSION NOTES
        ======================

        SESSION OVERVIEW
        ----------------
        Date: {date}
        Engineer: {engineer}
        Assistant: {assistant}
        Project: {project}
        Location: {studio}

        EQUIPMENT USED
        -------------
        Microphones: {microphones}
        Preamps: {preamps}
        Converters: {converters}
        DAW: {daw}
        Interface: {interface}

        INSTRUMENTS TRACKED
        ------------------
        {instruments_list}

        TECHNICAL SETTINGS
        -----------------
        Sample Rate: {sample_rate}
        Bit Depth: {bit_depth}
        Buffer Size: {buffer_size}

        KEY PERFORMANCES
        ----------------
        {performances_notes}

        ISSUES & SOLUTIONS
        ------------------
        {issues_solutions}

        NEXT STEPS
        ----------
        {next_steps}

        FILES CREATED
        -------------
        {files_list}
        """
    }

    /// Generate mixing session template
    public static func mixingSessionTemplate() -> String {
        return """
        MIXING SESSION NOTES
        ===================

        SESSION OVERVIEW
        ----------------
        Date: {date}
        Mix Engineer: {engineer}
        Project: {project}
        Song: {song}
        Client: {client}

        MIX GOAL
        --------
        {mix_goal}

        REFERENCE TRACKS
        ----------------
        {reference_tracks}

        SIGNAL CHAIN
        ------------
        Processing Chain:
        {processing_chain}

        MIX SETTINGS
        ------------
        Key Settings:
        • Kick: {kick_settings}
        • Snare: {snare_settings}
        • Bass: {bass_settings}
        • Vocals: {vocals_settings}
        • Guitars: {guitars_settings}
        • Keys: {keys_settings}
        • Drums: {drums_settings}

        AUTOMATION
        -----------
        {automation_notes}

        EFFECTS USED
        ------------
        Reverbs: {reverbs}
        Delays: {delays}
        Other FX: {other_fx}

        CLIENT NOTES
        ------------
        {client_notes}

        REVISION REQUESTS
        -----------------
        {revision_requests}

        NEXT SESSION
        ------------
        {next_session_notes}

        EXPORT SETTINGS
        ----------------
        {export_settings}
        """
    }

    /// Generate mastering session template
    public static func masteringSessionTemplate() -> String {
        return """
        MASTERING SESSION NOTES
        =======================

        SESSION OVERVIEW
        ----------------
        Date: {date}
        Mastering Engineer: {engineer}
        Project: {project}
        Artist: {artist}
        Album/EP: {album}

        SOURCE ANALYSIS
        ----------------
        Mix Analysis:
        • Dynamic Range: {dynamic_range}
        • Frequency Balance: {frequency_balance}
        • Stereo Image: {stereo_image}
        • Loudness: {current_loudness}

        CHAIN CONFIGURATION
        -------------------
        1. {eq_settings}
        2. {compression_settings}
        3. {saturation_settings}
        4. {limiter_settings}

        PROCESSING NOTES
        ----------------
        {processing_notes}

        COMPARISONS
        -----------
        Reference Tracks Used:
        {reference_comparisons}

        FINAL SETTINGS
        --------------
        Target Loudness: {target_loudness}
        True Peak: {true_peak}
        LUFS Integrated: {lufs_integrated}
        LUFS Short-term: {lufs_shortterm}

        CLIENT APPROVAL
        ---------------
        {client_approval_status}

        DELIVERY FORMATS
        ----------------
        {delivery_formats}

        NOTES
        -----
        {final_notes}
        """
    }

    // MARK: - Feedback Templates

    /// Generate client feedback template
    public static func clientFeedbackTemplate() -> String {
        return """
        CLIENT FEEDBACK REPORT
        ======================

        PROJECT INFORMATION
        ------------------
        Project: {project}
        Client: {client}
        Review Date: {review_date}
        Review Type: {review_type}

        OVERALL IMPRESSION
        ------------------
        Sentiment: {overall_sentiment}
        Key Response: {key_response}

        SPECIFIC FEEDBACK
        -----------------

        MIX BALANCE
        -----------
        {mix_balance_feedback}

        TONAL CHARACTER
        ----------------
        {tonal_feedback}

        DYNAMICS & ENERGY
        -----------------
        {dynamics_feedback}

        CREATIVE DIRECTION
        ------------------
        {creative_feedback}

        TECHNICAL CONCERNS
        ------------------
        {technical_feedback}

        PRIORITY ACTION ITEMS
        --------------------
        {priority_items}

        CLIENT PREFERENCES
        ------------------
        {client_preferences}

        NEXT STEPS
        ----------
        {next_steps}

        DEADLINES
        ----------
        {deadlines}
        """
    }

    /// Generate internal review template
    public static func internalReviewTemplate() -> String {
        return """
        INTERNAL MIX REVIEW
        ===================

        REVIEW DETAILS
        -------------
        Reviewer: {reviewer}
        Date: {review_date}
        Project: {project}
        Song: {song}

        TECHNICAL ASSESSMENT
        ---------------------

        CLARITY & DEFINITION
        --------------------
        • Vocals: {vocals_clarity}
        • Instruments: {instruments_clarity}
        • Separation: {separation_quality}

        BALANCE & PROPORTION
        --------------------
        • Level Balance: {level_balance}
        • Frequency Balance: {freq_balance}
        • Stereo Image: {stereo_image}

        DYNAMIC PROCESSING
        ------------------
        • Compression: {compression_assessment}
        • Limiting: {limiting_assessment}
        • Overall Dynamics: {dynamics_assessment}

        EFFECTS & ATMOSPHERE
        --------------------
        • Reverbs: {reverbs_assessment}
        • Delays: {delays_assessment}
        • Creative FX: {creative_fx_assessment}

        CREATIVE EVALUATION
        --------------------
        Emotional Impact: {emotional_impact}
        Energy Level: {energy_level}
        Commercial Viability: {commercial_viability}

        CRITICAL ISSUES
        ---------------
        {critical_issues}

        SUGGESTED IMPROVEMENTS
        ----------------------
        {improvements}

        OVERALL RATING
        --------------
        Technical Score: {technical_score}/10
        Creative Score: {creative_score}/10
        Overall Score: {overall_score}/10

        RECOMMENDATIONS
        ---------------
        {recommendations}
        """
    }

    // MARK: - Technical Report Templates

    /// Generate gear and setup template
    public static func gearSetupTemplate() -> String {
        return """
        STUDIO GEAR & SETUP REPORT
        =========================

        SETUP DATE: {setup_date}
        ENGINEER: {engineer}
        PROJECT: {project}

        SIGNAL FLOW DIAGRAM
        -------------------
        {signal_flow_diagram}

        MICROPHONES
        ------------
        {microphone_list}

        PREAMPLIFIERS
        -------------
        {preamp_list}

        OUTBOARD GEAR
        --------------
        {outboard_gear}

        MONITORING SETUP
        ----------------
        • Monitors: {monitors}
        • Room Treatment: {room_treatment}
        • Monitoring Level: {monitoring_level}

        SOFTWARE & PLUGINS
        ------------------
        DAW: {daw_version}
        Key Plugins: {key_plugins}

        CALIBRATION NOTES
        ------------------
        {calibration_notes}

        MEASUREMENTS
        -------------
        Room Response: {room_response}
        Frequency Response: {frequency_response}

        MAINTENANCE NEEDED
        ------------------
        {maintenance_items}

        UPGRADE RECOMMENDATIONS
        -----------------------
        {upgrade_recommendations}
        """
    }

    /// Generate troubleshooting template
    public static func troubleshootingTemplate() -> String {
        return """
        AUDIO TROUBLESHOOTING REPORT
        ============================

        ISSUE REPORTED
        --------------
        Date: {issue_date}
        Reported by: {reporter}
        Project: {project}
        Severity: {severity}

        PROBLEM DESCRIPTION
        -------------------
        {problem_description}

        ENVIRONMENT
        -----------
        System: {system_info}
        Software: {software_info}
        Hardware: {hardware_info}

        DIAGNOSTIC STEPS
        -----------------
        {diagnostic_steps}

        ROOT CAUSE ANALYSIS
        -------------------
        {root_cause}

        SOLUTION IMPLEMENTED
        --------------------
        {solution}

        VERIFICATION
        ------------
        {verification_steps}

        PREVENTION MEASURES
        --------------------
        {prevention_measures}

        IMPACT ASSESSMENT
        ------------------
        {impact_assessment}

        FOLLOW-UP REQUIRED
        ------------------
        {follow_up}
        """
    }

    // MARK: - Template Population Helpers

    /// Populate template with given values
    public static func populateTemplate(_ template: String, with values: [String: String]) -> String {
        var populatedTemplate = template

        for (key, value) in values {
            let placeholder = "{\(key)}"
            populatedTemplate = populatedTemplate.replacingOccurrences(of: placeholder, with: value)
        }

        return populatedTemplate
    }

    /// Get default template values for session type
    public static func getDefaultValues(for sessionType: String) -> [String: String] {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        let baseValues: [String: String] = [
            "date": formatter.string(from: Date()),
            "engineer": "Engineer Name",
            "project": "Project Name",
            "studio": "Studio Name"
        ]

        switch sessionType.lowercased() {
        case "tracking":
            return baseValues.merging([
                "assistant": "Assistant Name",
                "microphones": "List microphones used",
                "preamps": "List preamps used",
                "converters": "ADC/DAC information",
                "daw": "DAW software and version",
                "interface": "Audio interface",
                "sample_rate": "48 kHz",
                "bit_depth": "24-bit",
                "buffer_size": "128 samples",
                "instruments_list": "List instruments tracked",
                "performances_notes": "Notes on performances",
                "issues_solutions": "Any issues and how they were resolved",
                "next_steps": "What needs to be done next",
                "files_list": "List of files created"
            ]) { $1 }

        case "mixing":
            return baseValues.merging([
                "song": "Song Title",
                "client": "Client Name",
                "mix_goal": "Describe the intended outcome",
                "reference_tracks": "List reference tracks",
                "processing_chain": "Describe main signal chain",
                "kick_settings": "Kick drum processing",
                "snare_settings": "Snare drum processing",
                "bass_settings": "Bass processing",
                "vocals_settings": "Vocal processing",
                "guitars_settings": "Guitar processing",
                "keys_settings": "Keys/synth processing",
                "drums_settings": "Overall drum processing",
                "automation_notes": "Automation details",
                "reverbs": "Reverb plugins and settings",
                "delays": "Delay plugins and settings",
                "other_fx": "Other effects",
                "client_notes": "Client feedback and requests",
                "revision_requests": "Specific changes requested",
                "next_session_notes": "Plans for next session",
                "export_settings": "Export format and settings"
            ]) { $1 }

        case "mastering":
            return baseValues.merging([
                "artist": "Artist Name",
                "album": "Album/EP Title",
                "dynamic_range": "DR measurement",
                "frequency_balance": "Frequency analysis",
                "stereo_image": "Stereo field analysis",
                "current_loudness": "LUFS measurement",
                "eq_settings": "Equalizer settings",
                "compression_settings": "Compression settings",
                "saturation_settings": "Saturation/harmonic processing",
                "limiter_settings": "Limiter settings",
                "processing_notes": "Detailed processing notes",
                "reference_comparisons": "Comparison with reference tracks",
                "target_loudness": "Target LUFS",
                "true_peak": "True peak ceiling",
                "lufs_integrated": "Integrated LUFS",
                "lufs_shortterm": "Short-term LUFS",
                "client_approval_status": "Approved/rejected/pending",
                "delivery_formats": "Required delivery formats",
                "final_notes": "Additional notes"
            ]) { $1 }

        default:
            return baseValues
        }
    }

    // MARK: - Specialized Summary Templates

    /// Generate daily session summary
    public static func dailySessionSummary() -> String {
        return """
        DAILY SESSION SUMMARY
        ====================

        Date: {date}
        Engineer: {engineer}

        SESSIONS COMPLETED
        ------------------
        {sessions_completed}

        PROJECTS WORKED ON
        ------------------
        {projects_worked_on}

        TIME TRACKING
        -------------
        Total Hours: {total_hours}
        Billable Hours: {billable_hours}

        ACCOMPLISHMENTS
        ---------------
        {accomplishments}

        CHALLENGES FACED
        ----------------
        {challenges}

        EQUIPMENT ISSUES
        ----------------
        {equipment_issues}

        CLIENT COMMUNICATIONS
        ---------------------
        {client_communications}

        FILES BACKED UP
        ---------------
        {files_backed_up}

        TOMORROW'S PRIORITIES
        ---------------------
        {tomorrow_priorities}

        NOTES
        -----
        {notes}
        """
    }

    /// Generate project status template
    public static func projectStatusTemplate() -> String {
        return """
        PROJECT STATUS REPORT
        =====================

        Project: {project}
        Client: {client}
        Status Date: {status_date}

        PROJECT OVERVIEW
        ----------------
        Start Date: {start_date}
        Target Completion: {target_completion}
        Current Status: {current_status}

        WORK COMPLETED
        ---------------
        {work_completed}

        CURRENT PHASE
        -------------
        Phase: {current_phase}
        Progress: {progress_percentage}

        REMAINING WORK
        --------------
        {remaining_work}

        ISSUES & BLOCKERS
        -----------------
        {issues_blockers}

        BUDGET STATUS
        -------------
        Budget Allocated: {budget_allocated}
        Budget Spent: {budget_spent}
        Remaining: {budget_remaining}

        NEXT MILESTONE
        ---------------
        {next_milestone}
        Target Date: {milestone_date}

        TEAM NOTES
        ----------
        {team_notes}

        CLIENT UPDATES
        --------------
        {client_updates}

        ACTION ITEMS
        ------------
        {action_items}
        """
    }
}