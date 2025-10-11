//
//  IntentRecognitionTool.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-09.
//

import Foundation
import AnyCodable

/// Intent Recognition Tool for Audio Domain Commands
///
/// Implements apple.intent.parse specification for converting natural-language commands
/// into normalized intents for Audio Agent operations. Recognizes audio-specific intents
/// with confidence scoring and argument extraction.
///
/// Supported Intents:
/// - Recording: start_recording, stop_recording, setup_microphone, track_instrument
/// - Mixing: apply_eq, add_compression, set_levels, automate_parameters
/// - Editing: trim_audio, crossfade, time_stretch, pitch_correct
/// - Processing: apply_effects, master_track, export_audio, analyze_frequency
/// - Session: create_session, save_session, load_session, manage_tracks
/// - Query: get_info, analyze_settings, recommend_settings, troubleshoot
/// - Planning: create_plan, generate_checklist, estimate_time, suggest_workflow
///
/// Audio Domain Features:
/// - Equipment and brand recognition (Neumann, API, SSL, Pro Tools)
/// - Technical terminology parsing (frequency, dB, compression ratios)
/// - Workflow context awareness (tracking, mixing, mastering)
/// - Studio session structure understanding
///
/// Performance Requirements:
/// - Execution: <100ms for intent recognition
/// - Memory: <1MB for pattern matching overhead
/// - Accuracy: >90% for common audio commands
/// - Concurrency: Thread-safe for multiple simultaneous operations
public final class IntentRecognitionTool: AudioDomainTool, @unchecked Sendable {

    // MARK: - Intent Types

    /// Supported intent categories for audio domain operations
    public enum AudioIntent: String, CaseIterable, Codable, Sendable {
        // Recording Intents
        case startRecording = "start_recording"
        case stopRecording = "stop_recording"
        case setupMicrophone = "setup_microphone"
        case trackInstrument = "track_instrument"
        case recordTake = "record_take"
        case armTrack = "arm_track"

        // Mixing Intents
        case applyEQ = "apply_eq"
        case addCompression = "add_compression"
        case setLevels = "set_levels"
        case automateParameters = "automate_parameters"
        case addReverb = "add_reverb"
        case insertPlugin = "insert_plugin"
        case createSend = "create_send"
        case panTrack = "pan_track"

        // Editing Intents
        case trimAudio = "trim_audio"
        case crossfade = "crossfade"
        case timeStretch = "time_stretch"
        case pitchCorrect = "pitch_correct"
        case consolidate = "consolidate"
        case nudgeAudio = "nudge_audio"

        // Processing Intents
        case applyEffects = "apply_effects"
        case masterTrack = "master_track"
        case exportAudio = "export_audio"
        case analyzeFrequency = "analyze_frequency"
        case removeNoise = "remove_noise"
        case normalizeAudio = "normalize_audio"

        // Session Management Intents
        case createSession = "create_session"
        case saveSession = "save_session"
        case loadSession = "load_session"
        case manageTracks = "manage_tracks"
        case duplicateTrack = "duplicate_track"
        case importAudio = "import_audio"

        // Query Intents
        case getInfo = "get_info"
        case analyzeSettings = "analyze_settings"
        case recommendSettings = "recommend_settings"
        case troubleshoot = "troubleshoot"
        case compareSettings = "compare_settings"
        case listPlugins = "list_plugins"

        // Planning Intents
        case createPlan = "create_plan"
        case generateChecklist = "generate_checklist"
        case estimateTime = "estimate_time"
        case suggestWorkflow = "suggest_workflow"
        case scheduleSession = "schedule_session"

        // Utility Intents
        case calculate = "calculate"
        case convert = "convert"
        case measure = "measure"
        case validate = "validate"
        case help = "help"

        var description: String {
            switch self {
            case .startRecording: return "Start recording audio on specified track"
            case .stopRecording: return "Stop current recording operation"
            case .setupMicrophone: return "Configure microphone settings and placement"
            case .trackInstrument: return "Record a specific instrument"
            case .recordTake: return "Record a new take of existing track"
            case .armTrack: return "Arm track for recording"
            case .applyEQ: return "Apply equalization to audio track"
            case .addCompression: return "Add compression to audio track"
            case .setLevels: return "Adjust volume levels and gain staging"
            case .automateParameters: return "Create automation for parameters"
            case .addReverb: return "Add reverb effects to track"
            case .insertPlugin: return "Insert plugin on track"
            case .createSend: return "Create send effect"
            case .panTrack: return "Adjust stereo panning"
            case .trimAudio: return "Trim audio clip boundaries"
            case .crossfade: return "Create crossfade between clips"
            case .timeStretch: return "Change audio timing without pitch"
            case .pitchCorrect: return "Correct pitch in audio recording"
            case .consolidate: return "Consolidate audio clips"
            case .nudgeAudio: return "Nudge audio timing"
            case .applyEffects: return "Apply audio effects processing"
            case .masterTrack: return "Apply mastering processing"
            case .exportAudio: return "Export audio to file"
            case .analyzeFrequency: return "Analyze frequency spectrum"
            case .removeNoise: return "Remove noise from audio"
            case .normalizeAudio: return "Normalize audio levels"
            case .createSession: return "Create new recording session"
            case .saveSession: return "Save current session"
            case .loadSession: return "Load existing session"
            case .manageTracks: return "Manage track configuration"
            case .duplicateTrack: return "Duplicate existing track"
            case .importAudio: return "Import audio files"
            case .getInfo: return "Get information about audio/track"
            case .analyzeSettings: return "Analyze current audio settings"
            case .recommendSettings: return "Recommend audio settings"
            case .troubleshoot: return "Troubleshoot audio issues"
            case .compareSettings: return "Compare different settings"
            case .listPlugins: return "List available plugins"
            case .createPlan: return "Create plan for audio work"
            case .generateChecklist: return "Generate task checklist"
            case .estimateTime: return "Estimate time for audio task"
            case .suggestWorkflow: return "Suggest audio workflow"
            case .scheduleSession: return "Schedule recording session"
            case .calculate: return "Perform audio calculations"
            case .convert: return "Convert audio formats/measurements"
            case .measure: return "Measure audio properties"
            case .validate: return "Validate audio settings"
            case .help: return "Get help with audio tasks"
            }
        }

        var category: IntentCategory {
            switch self {
            case .startRecording, .stopRecording, .setupMicrophone, .trackInstrument,
                 .recordTake, .armTrack:
                return .recording
            case .applyEQ, .addCompression, .setLevels, .automateParameters,
                 .addReverb, .insertPlugin, .createSend, .panTrack:
                return .mixing
            case .trimAudio, .crossfade, .timeStretch, .pitchCorrect,
                 .consolidate, .nudgeAudio:
                return .editing
            case .applyEffects, .masterTrack, .exportAudio, .analyzeFrequency,
                 .removeNoise, .normalizeAudio:
                return .processing
            case .createSession, .saveSession, .loadSession, .manageTracks,
                 .duplicateTrack, .importAudio:
                return .sessionManagement
            case .getInfo, .analyzeSettings, .recommendSettings, .troubleshoot,
                 .compareSettings, .listPlugins:
                return .query
            case .createPlan, .generateChecklist, .estimateTime, .suggestWorkflow,
                 .scheduleSession:
                return .planning
            case .calculate, .convert, .measure, .validate, .help:
                return .utility
            }
        }
    }

    /// Intent categories for grouping similar intents
    public enum IntentCategory: String, CaseIterable, Codable, Sendable {
        case recording = "recording"
        case mixing = "mixing"
        case editing = "editing"
        case processing = "processing"
        case sessionManagement = "session_management"
        case query = "query"
        case planning = "planning"
        case utility = "utility"

        var description: String {
            switch self {
            case .recording: return "Audio recording and capture operations"
            case .mixing: return "Mixing and signal processing operations"
            case .editing: return "Audio editing and manipulation operations"
            case .processing: return "Audio processing and effects operations"
            case .sessionManagement: return "Session and track management operations"
            case .query: return "Information and analysis queries"
            case .planning: return "Planning and workflow operations"
            case .utility: return "Utility and helper operations"
            }
        }
    }

    // MARK: - Intent Recognition Result

    /// Result of intent recognition operation
    public struct IntentRecognitionResult: Codable, Sendable {
        /// Recognized intent
        public let intent: AudioIntent

        /// Confidence score (0.0-1.0)
        public let confidence: Double

        /// Extracted arguments and parameters
        public let arguments: [String: AnyCodable]

        /// Intent category
        public let category: IntentCategory

        /// Original text input
        public let originalText: String

        /// Alternative intents with confidence scores
        public let alternatives: [AlternativeIntent]

        /// Audio domain context extracted from text
        public let audioContext: AudioContext?

        /// Processing metadata
        public let metadata: [String: AnyCodable]

        public init(
            intent: AudioIntent,
            confidence: Double,
            arguments: [String: AnyCodable],
            category: IntentCategory,
            originalText: String,
            alternatives: [AlternativeIntent] = [],
            audioContext: AudioContext? = nil,
            metadata: [String: AnyCodable] = [:]
        ) {
            self.intent = intent
            self.confidence = confidence
            self.arguments = arguments
            self.category = category
            self.originalText = originalText
            self.alternatives = alternatives
            self.audioContext = audioContext
            self.metadata = metadata
        }
    }

    /// Alternative intent with confidence
    public struct AlternativeIntent: Codable, Sendable {
        public let intent: AudioIntent
        public let confidence: Double
        public let reason: String?

        public init(intent: AudioIntent, confidence: Double, reason: String? = nil) {
            self.intent = intent
            self.confidence = confidence
            self.reason = reason
        }
    }

    /// Audio context extracted from user input
    public struct AudioContext: Codable, Sendable {
        /// Equipment mentioned in input
        public let equipment: [String]

        /// Technical parameters mentioned
        public let parameters: [String: String]

        /// Track/Session context
        public let trackContext: String?

        /// Audio domain keywords found
        public let keywords: [String]

        /// Session phase (recording, mixing, etc.)
        public let sessionPhase: String?

        public init(
            equipment: [String] = [],
            parameters: [String: String] = [:],
            trackContext: String? = nil,
            keywords: [String] = [],
            sessionPhase: String? = nil
        ) {
            self.equipment = equipment
            self.parameters = parameters
            self.trackContext = trackContext
            self.keywords = keywords
            self.sessionPhase = sessionPhase
        }
    }

    // MARK: - Pattern Matching

    /// Intent pattern for matching user input
    private struct IntentPattern {
        let intent: AudioIntent
        let patterns: [String]
        let keywords: [String]
        let argumentExtractors: [String: String]
        let confidence: Double
        let requiredWords: [String]

        init(intent: AudioIntent, patterns: [String], keywords: [String] = [],
             argumentExtractors: [String: String] = [:], confidence: Double = 0.8,
             requiredWords: [String] = []) {
            self.intent = intent
            self.patterns = patterns
            self.keywords = keywords
            self.argumentExtractors = argumentExtractors
            self.confidence = confidence
            self.requiredWords = requiredWords
        }

        func matches(_ text: String) -> (match: Bool, confidence: Double, arguments: [String: AnyCodable]) {
            let lowercasedText = text.lowercased()

            // Check required words
            let hasRequiredWords = requiredWords.isEmpty || requiredWords.allSatisfy {
                lowercasedText.contains($0.lowercased())
            }
            guard hasRequiredWords else { return (false, 0.0, [:]) }

            // Calculate match score
            var matchScore = 0.0
            var extractedArgs: [String: AnyCodable] = [:]

            // Pattern matching
            for pattern in patterns {
                if lowercasedText.contains(pattern.lowercased()) {
                    matchScore += confidence
                }
            }

            // Keyword matching
            let keywordMatches = keywords.filter { lowercasedText.contains($0.lowercased()) }.count
            if !keywords.isEmpty {
                matchScore += Double(keywordMatches) / Double(keywords.count) * 0.3
            }

            // Extract arguments
            for (key, pattern) in argumentExtractors {
                if let extracted = extractArgument(from: text, pattern: pattern) {
                    extractedArgs[key] = AnyCodable(extracted)
                }
            }

            let finalConfidence = min(matchScore, 1.0)
            return (matchScore > 0.3, finalConfidence, extractedArgs)
        }

        private func extractArgument(from text: String, pattern: String) -> String? {
            // Simple regex-based argument extraction
            guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
            let range = NSRange(location: 0, length: text.utf16.count)
            if let match = regex.firstMatch(in: text, range: range) {
                if match.numberOfRanges > 1 {
                    let argumentRange = match.range(at: 1)
                    if argumentRange.location != NSNotFound {
                        let startIndex = text.index(text.startIndex, offsetBy: argumentRange.location)
                        let endIndex = text.index(startIndex, offsetBy: argumentRange.length)
                        return String(text[startIndex..<endIndex])
                    }
                }
            }
            return nil
        }
    }

    // MARK: - Properties

    private let intentPatterns: [IntentPattern]
    private let audioKeywordExtractor: AudioKeywordExtractor

    // MARK: - Initialization

    init(logger: Logger, securityManager: SecurityManager) {
        self.audioKeywordExtractor = AudioKeywordExtractor()
        self.intentPatterns = IntentRecognitionTool.createIntentPatterns()

        let inputSchema: [String: AnyCodable] = [
            "type": AnyCodable("object"),
            "properties": AnyCodable([
                "text": AnyCodable([
                    "type": AnyCodable("string"),
                    "description": AnyCodable("Natural language command or request for audio operations"),
                    "minLength": AnyCodable(5),
                    "maxLength": AnyCodable(500),
                    "examples": AnyCodable([
                        "Start recording the lead vocal track",
                        "Apply EQ to the bass with a boost at 80Hz",
                        "Export the mix as a high-quality WAV file",
                        "What's the best microphone for recording acoustic guitar?",
                        "Create a checklist for the mixing session"
                    ])
                ]),
                "allowed": AnyCodable([
                    "type": AnyCodable("array"),
                    "description": AnyCodable("List of allowed intents to restrict recognition scope"),
                    "items": AnyCodable([
                        "type": AnyCodable("string"),
                        "enum": AnyCodable(AudioIntent.allCases.map(\.rawValue))
                    ]),
                    "default": AnyCodable([])
                ]),
                "confidence_threshold": AnyCodable([
                    "type": AnyCodable("number"),
                    "description": AnyCodable("Minimum confidence threshold for intent recognition"),
                    "minimum": AnyCodable(0.1),
                    "maximum": AnyCodable(1.0),
                    "default": AnyCodable(0.6)
                ]),
                "include_alternatives": AnyCodable([
                    "type": AnyCodable("boolean"),
                    "description": AnyCodable("Include alternative intents with confidence scores"),
                    "default": AnyCodable(true)
                ]),
                "extract_context": AnyCodable([
                    "type": AnyCodable("boolean"),
                    "description": AnyCodable("Extract audio domain context from input"),
                    "default": AnyCodable(true)
                ])
            ]),
            "required": AnyCodable(["text"])
        ]

        super.init(
            name: "apple_intent_parse",
            description: "Converts natural-language commands into normalized intents for Audio Agent operations with confidence scoring and argument extraction.",
            inputSchema: inputSchema,
            logger: logger,
            securityManager: securityManager
        )
    }

    // MARK: - Audio Processing

    /// Parse natural language text to recognize audio domain intent
    public override func processAudioContent(_ content: String, with parameters: [String: Any]) async throws -> String {
        let text = content

        // Parse parameters
        let allowedIntents = parameters["allowed"] as? [String] ?? []
        let confidenceThreshold = parameters["confidence_threshold"] as? Double ?? 0.6
        let includeAlternatives = parameters["include_alternatives"] as? Bool ?? true
        let extractContext = parameters["extract_context"] as? Bool ?? true

        // Pre-security check
        try await performSecurityCheck(text)

        // Perform intent recognition
        let result = try await recognizeIntent(
            in: text,
            allowedIntents: allowedIntents,
            confidenceThreshold: confidenceThreshold,
            includeAlternatives: includeAlternatives,
            extractContext: extractContext
        )

        // Post-security validation
        try await validateOutput(result)

        return result
    }

    // MARK: - Private Implementation

    /// Recognize intent from natural language text
    private func recognizeIntent(
        in text: String,
        allowedIntents: [String],
        confidenceThreshold: Double,
        includeAlternatives: Bool,
        extractContext: Bool
    ) async throws -> String {

        var matches: [(intent: AudioIntent, confidence: Double, arguments: [String: AnyCodable])] = []

        // Match against all patterns
        for pattern in intentPatterns {
            // Skip if intent not in allowed list
            if !allowedIntents.isEmpty && !allowedIntents.contains(pattern.intent.rawValue) {
                continue
            }

            let (hasMatch, confidence, arguments) = pattern.matches(text)
            if hasMatch {
                matches.append((intent: pattern.intent, confidence: confidence, arguments: arguments))
            }
        }

        // Sort by confidence
        matches.sort { $0.confidence > $1.confidence }

        // Get best match
        guard let bestMatch = matches.first, bestMatch.confidence >= confidenceThreshold else {
            throw AudioProcessingError.invalidInput("No intent recognized with sufficient confidence")
        }

        // Extract audio context if requested
        let audioContext = extractContext ? audioKeywordExtractor.extractContext(from: text) : nil

        // Generate alternatives if requested
        let alternatives = includeAlternatives ?
            matches.dropFirst().prefix(3).map {
                AlternativeIntent(intent: $0.intent, confidence: $0.confidence)
            } : []

        // Create result
        let result = IntentRecognitionResult(
            intent: bestMatch.intent,
            confidence: bestMatch.confidence,
            arguments: bestMatch.arguments,
            category: bestMatch.intent.category,
            originalText: text,
            alternatives: Array(alternatives),
            audioContext: audioContext,
            metadata: [
                "patterns_evaluated": AnyCodable(intentPatterns.count),
                "matches_found": AnyCodable(matches.count),
                "confidence_threshold": AnyCodable(confidenceThreshold),
                "audio_domain_confidence": AnyCodable(calculateAudioDomainConfidence(text))
            ]
        )

        await logger.info(
            "Intent recognized",
            metadata: [
                "intent": result.intent.rawValue,
                "confidence": result.confidence,
                "category": result.category.rawValue,
                "alternatives": result.alternatives.count,
                "audio_context": result.audioContext != nil
            ]
        )

        // Convert to JSON string
        return try String(data: JSONEncoder().encode(result), encoding: .utf8) ??
               "{\"error\":\"Failed to encode result\"}"
    }

    /// Calculate confidence that text is audio domain related
    private func calculateAudioDomainConfidence(_ text: String) -> Double {
        let audioKeywords = [
            "microphone", "recording", "mixing", "mastering", "eq", "compression",
            "reverb", "delay", "track", "session", "plugin", "daw", "audio",
            "frequency", "khz", "db", "gain", "volume", "pan", "automation",
            "export", "import", "normalize", "compress", "equalize"
        ]

        let lowercaseText = text.lowercased()
        let keywordCount = audioKeywords.filter { lowercaseText.contains($0) }.count
        let wordCount = text.split(separator: " ").count

        return Double(keywordCount) / Double(max(wordCount, 1))
    }

    // MARK: - Security

    /// Validates input for security compliance
    private func performSecurityCheck(_ text: String) async throws {
        do {
            try TextValidationUtils.validateText(text)
            try TextValidationUtils.validateTextSecurity(text)
        } catch {
            throw AudioProcessingError.invalidInput(error.localizedDescription)
        }
    }

    /// Validates output for security compliance
    private func validateOutput(_ output: String) async throws {
        do {
            try TextValidationUtils.validateText(output)
            try TextValidationUtils.validateTextSecurity(output)
        } catch {
            throw AudioProcessingError.validationError(error.localizedDescription)
        }
    }

    // MARK: - Pattern Factory

    /// Create intent patterns for audio domain commands
    private static func createIntentPatterns() -> [IntentPattern] {
        return [
            // Recording Patterns
            IntentPattern(
                intent: .startRecording,
                patterns: ["start recording", "record", "begin recording", "capture audio"],
                keywords: ["record", "capture", "start", "begin"],
                argumentExtractors: ["track": "record\\\\s+(?:the\\\\s+)?(.+?)\\\\s*(?:track|channel)?"]
            ),

            IntentPattern(
                intent: .stopRecording,
                patterns: ["stop recording", "stop", "end recording", "finish recording"],
                keywords: ["stop", "end", "finish"]
            ),

            IntentPattern(
                intent: .setupMicrophone,
                patterns: ["setup microphone", "mic setup", "place microphone", "position mic"],
                keywords: ["microphone", "mic", "setup", "place", "position"],
                argumentExtractors: ["microphone": "(?:use|with)\\\\s+(.+?)\\\\s+microphone"]
            ),

            // Mixing Patterns
            IntentPattern(
                intent: .applyEQ,
                patterns: ["apply eq", "equalize", "eq the", "add eq"],
                keywords: ["eq", "equalize", "frequency", "boost", "cut"],
                argumentExtractors: [
                    "frequency": "(\\\\d+)\\\\s*hz",
                    "gain": "([+-]?\\\\d+)\\\\s*db",
                    "track": "eq\\\\s+(?:the\\\\s+)?(.+?)\\\\s+(?:track|channel)?"
                ]
            ),

            IntentPattern(
                intent: .addCompression,
                patterns: ["add compression", "compress", "apply compression"],
                keywords: ["compression", "compress", "dynamics", "ratio"],
                argumentExtractors: [
                    "ratio": "ratio\\\\s+(\\\\d+:\\\\d+)",
                    "threshold": "threshold\\\\s+(-?\\\\d+)"
                ]
            ),

            IntentPattern(
                intent: .setLevels,
                patterns: ["set levels", "adjust levels", "set volume", "adjust gain"],
                keywords: ["levels", "volume", "gain", "adjust", "set"],
                argumentExtractors: ["level": "(-?\\\\d+)\\\\s*db"]
            ),

            // Processing Patterns
            IntentPattern(
                intent: .exportAudio,
                patterns: ["export", "bounce", "render", "save as"],
                keywords: ["export", "bounce", "render", "save"],
                argumentExtractors: [
                    "format": "(?:as|to)\\\\s+(wav|mp3|aiff|flac)",
                    "quality": "(\\\\d+)\\\\s*(?:kbps|bit)"
                ]
            ),

            IntentPattern(
                intent: .analyzeFrequency,
                patterns: ["analyze frequency", "spectrum analysis", "freq analysis"],
                keywords: ["frequency", "spectrum", "analyze", "fft"]
            ),

            // Query Patterns
            IntentPattern(
                intent: .getInfo,
                patterns: ["what is", "tell me about", "get info", "information"],
                keywords: ["what", "tell", "info", "information", "about"]
            ),

            IntentPattern(
                intent: .recommendSettings,
                patterns: ["recommend", "suggest", "what should", "best settings"],
                keywords: ["recommend", "suggest", "best", "optimal"]
            ),

            IntentPattern(
                intent: .troubleshoot,
                patterns: ["troubleshoot", "fix", "problem", "issue"],
                keywords: ["troubleshoot", "fix", "problem", "issue", "trouble"]
            ),

            // Planning Patterns
            IntentPattern(
                intent: .createPlan,
                patterns: ["create plan", "make plan", "plan for", "workflow"],
                keywords: ["plan", "workflow", "steps", "process"]
            ),

            IntentPattern(
                intent: .generateChecklist,
                patterns: ["checklist", "to do list", "task list", "steps"],
                keywords: ["checklist", "list", "tasks", "steps"]
            ),

            IntentPattern(
                intent: .estimateTime,
                patterns: ["how long", "time estimate", "duration", "will it take"],
                keywords: ["time", "how long", "duration", "estimate"]
            )
        ]
    }
}

// MARK: - Audio Keyword Extractor

/// Extracts audio domain context from natural language text
private class AudioKeywordExtractor {

    private let equipmentBrands = [
        "neumann", "akg", "sennheiser", "shure", "audio-technica", "rode",
        "api", "neve", "ssl", "focusrite", "universal audio", "manley",
        "pro tools", "logic pro", "ableton", "cubase", "studio one",
        "waves", "fabfilter", "soundtoys", "valhalla", "native instruments"
    ]

    private let technicalTerms = [
        "frequency", "khz", "hz", "db", "decibel", "gain", "volume", "pan",
        "compression", "eq", "equalization", "reverb", "delay", "chorus",
        "automation", "mixing", "mastering", "tracking", "overdub",
        "bit depth", "sample rate", "wav", "mp3", "aiff", "flac"
    ]

    private let sessionPhases = [
        "recording", "tracking", "mixing", "mastering", "editing", "production"
    ]

    func extractContext(from text: String) -> IntentRecognitionTool.AudioContext {
        let lowercaseText = text.lowercased()

        // Extract equipment
        let equipment = equipmentBrands.filter { lowercaseText.contains($0) }

        // Extract technical parameters
        var parameters: [String: String] = [:]

        // Extract frequency values
        if let frequency = extractValue(pattern: "(\\\\d+)\\\\s*hz", from: text) {
            parameters["frequency"] = frequency
        }

        // Extract dB values
        if let db = extractValue(pattern: "(-?\\\\d+)\\\\s*db", from: text) {
            parameters["gain"] = db
        }

        // Extract sample rate
        if let sampleRate = extractValue(pattern: "(\\\\d+)\\\\s*(?:khz|hz)", from: text) {
            parameters["sample_rate"] = sampleRate
        }

        // Extract track context
        let trackKeywords = ["track", "channel", "bus", "aux", "master"]
        let trackContext = trackKeywords.first { lowercaseText.contains($0) }

        // Extract keywords
        let keywords = technicalTerms.filter { lowercaseText.contains($0) }

        // Determine session phase
        let sessionPhase = sessionPhases.first { lowercaseText.contains($0) }

        return IntentRecognitionTool.AudioContext(
            equipment: equipment,
            parameters: parameters,
            trackContext: trackContext,
            keywords: keywords,
            sessionPhase: sessionPhase
        )
    }

    private func extractValue(pattern: String, from text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(location: 0, length: text.utf16.count)
        if let match = regex.firstMatch(in: text, range: range) {
            let matchRange = match.range
            if matchRange.location != NSNotFound {
                let startIndex = text.index(text.startIndex, offsetBy: matchRange.location)
                let endIndex = text.index(startIndex, offsetBy: matchRange.length)
                return String(text[startIndex..<endIndex])
            }
        }
        return nil
    }
}