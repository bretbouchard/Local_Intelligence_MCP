//
//  SessionNotesTool.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-09.
//

import Foundation

/// Session notes summarization tool for engineering session documentation
/// Implements apple.session.summarize specification for processing audio engineering session notes
public final class SessionNotesTool: AudioDomainTool, @unchecked Sendable {

    // MARK: - Initialization

    public convenience init(
        logger: Logger,
        securityManager: SecurityManager
    ) {
        self.init(
            name: "apple_session_summarize",
            description: "Specialized summarization for audio engineering session documentation and notes",
            inputSchema: nil,
            logger: logger,
            securityManager: securityManager
        )
    }

    public override init(
        name: String,
        description: String,
        inputSchema: [String: Any]? = nil,
        logger: Logger,
        securityManager: SecurityManager,
        requiresPermission: [PermissionType] = [.systemInfo],
        offlineCapable: Bool = true
    ) {
        let defaultInputSchema: [String: AnyCodable] = [
            "type": AnyCodable("object"),
            "properties": AnyCodable([
                "content": [
                    "type": "string",
                    "description": "Session notes content to summarize"
                ],
                "session_type": [
                    "type": "string",
                    "enum": ["tracking", "mixing", "mastering", "production", "sound_design", "edit", "review", "general"],
                    "default": "general",
                    "description": "Type of session being documented"
                ],
                "focus_areas": [
                    "type": "array",
                    "items": ["type": "string"],
                    "description": "Specific areas to focus on in the summary (e.g., 'settings', 'techniques', 'issues', 'decisions')"
                ],
                "detail_level": [
                    "type": "string",
                    "enum": ["brief", "standard", "detailed", "comprehensive"],
                    "default": "standard",
                    "description": "Level of detail in the generated summary"
                ],
                "include_technical": [
                    "type": "boolean",
                    "default": true,
                    "description": "Include technical settings and parameters in summary"
                ],
                "include_action_items": [
                    "type": "boolean",
                    "default": true,
                    "description": "Extract and highlight action items and next steps"
                ],
                "duration_estimate": [
                    "type": "string",
                    "description": "Estimated session duration (e.g., '2 hours', '90 minutes')"
                ],
                "use_template": [
                    "type": "boolean",
                    "default": false,
                    "description": "Use engineering-specific template for session notes"
                ],
                "template_type": [
                    "type": "string",
                    "enum": ["tracking", "mixing", "mastering", "daily_summary", "project_status", "feedback", "internal_review", "gear_setup", "troubleshooting"],
                    "default": "tracking",
                    "description": "Type of engineering template to use"
                ]
            ]),
            "required": AnyCodable(["content"])
        ]

        super.init(
            name: name,
            description: description,
            inputSchema: inputSchema ?? defaultInputSchema,
            logger: logger,
            securityManager: securityManager,
            requiresPermission: requiresPermission,
            offlineCapable: offlineCapable
        )
    }

    // MARK: - Session Summary Types

    public struct SessionSummary: Codable, Sendable {
        let overview: String
        let keyPoints: [String]
        let technicalDetails: TechnicalDetails?
        let actionItems: [ActionItem]
        let sessionMetadata: SessionMetadata
        let confidence: Double

        public init(
            overview: String,
            keyPoints: [String],
            technicalDetails: TechnicalDetails? = nil,
            actionItems: [ActionItem] = [],
            sessionMetadata: SessionMetadata,
            confidence: Double = 0.8
        ) {
            self.overview = overview
            self.keyPoints = keyPoints
            self.technicalDetails = technicalDetails
            self.actionItems = actionItems
            self.sessionMetadata = sessionMetadata
            self.confidence = confidence
        }
    }

    public struct TechnicalDetails: Codable, Sendable {
        let equipment: [String]
        let settings: [String]
        let techniques: [String]
        let software: [String]
        let plugins: [String]

        public init(
            equipment: [String] = [],
            settings: [String] = [],
            techniques: [String] = [],
            software: [String] = [],
            plugins: [String] = []
        ) {
            self.equipment = equipment
            self.settings = settings
            self.techniques = techniques
            self.software = software
            self.plugins = plugins
        }
    }

    public struct ActionItem: Codable, Sendable {
        let description: String
        let priority: String
        let assignee: String?
        let dueDate: String?
        let context: String?

        public init(
            description: String,
            priority: String = "medium",
            assignee: String? = nil,
            dueDate: String? = nil,
            context: String? = nil
        ) {
            self.description = description
            self.priority = priority
            self.assignee = assignee
            self.dueDate = dueDate
            self.context = context
        }
    }

    public struct SessionMetadata: Codable, Sendable {
        let sessionType: String
        let duration: String?
        let participants: [String]
        let date: String
        let focusAreas: [String]
        let detailLevel: String

        public init(
            sessionType: String,
            duration: String? = nil,
            participants: [String] = [],
            date: String,
            focusAreas: [String] = [],
            detailLevel: String = "standard"
        ) {
            self.sessionType = sessionType
            self.duration = duration
            self.participants = participants
            self.date = date
            self.focusAreas = focusAreas
            self.detailLevel = detailLevel
        }
    }

    // MARK: - AudioDomainTool Implementation

    internal override func performExecution(parameters: [String: AnyCodable], context: MCPExecutionContext) async throws -> MCPResponse {
        // Extract content parameter
        guard let content = parameters["content"]?.value as? String else {
            throw ToolsRegistryError.invalidParameters("content parameter is required")
        }

        guard !content.isEmpty else {
            throw ToolsRegistryError.invalidParameters("content cannot be empty")
        }

        // Extract other parameters
        var processingParams: [String: Any] = [:]
        for (key, value) in parameters {
            processingParams[key] = value.value
        }

        // Process using the audio content method
        let result = try await processAudioContent(content, with: processingParams)

        return MCPResponse(
            success: true,
            data: AnyCodable(result),
            error: nil
        )
    }

    public override func processAudioContent(_ content: String, with parameters: [String: Any]) async throws -> String {
        let startTime = Date()

        await logger.debug("Starting session notes summarization", category: .general, metadata: [
            "tool": AnyCodable(name),
            "contentLength": AnyCodable(content.count)
        ])

        // Extract parameters
        let sessionType = parameters["session_type"] as? String ?? "general"
        let focusAreas = parameters["focus_areas"] as? [String] ?? []
        let detailLevel = parameters["detail_level"] as? String ?? "standard"
        let includeTechnical = parameters["include_technical"] as? Bool ?? true
        let includeActionItems = parameters["include_action_items"] as? Bool ?? true
        let durationEstimate = parameters["duration_estimate"] as? String
        let useTemplate = parameters["use_template"] as? Bool ?? false
        let templateType = parameters["template_type"] as? String ?? "tracking"

        do {
            // Generate session summary
            let summary = try await generateSessionSummary(
                from: content,
                sessionType: sessionType,
                focusAreas: focusAreas,
                detailLevel: detailLevel,
                includeTechnical: includeTechnical,
                includeActionItems: includeActionItems,
                durationEstimate: durationEstimate,
                useTemplate: useTemplate,
                templateType: templateType
            )

            let response = try encodeJSON(summary)

            await logger.info("Session notes summarization completed successfully", category: .general, metadata: [
                "sessionType": AnyCodable(sessionType),
                "detailLevel": AnyCodable(detailLevel),
                "processingTime": AnyCodable(Date().timeIntervalSince(startTime)),
                "keyPointsCount": AnyCodable(summary.keyPoints.count),
                "actionItemsCount": AnyCodable(summary.actionItems.count)
            ])

            return response

        } catch {
            await logger.error("Session notes summarization failed", error: error, category: .general, metadata: [:])
            throw error
        }
    }

    // MARK: - Private Methods

    /// Generate comprehensive session summary
    private func generateSessionSummary(
        from content: String,
        sessionType: String,
        focusAreas: [String],
        detailLevel: String,
        includeTechnical: Bool,
        includeActionItems: Bool,
        durationEstimate: String?,
        useTemplate: Bool,
        templateType: String
    ) async throws -> SessionSummary {

        // Handle template-based generation if requested
        if useTemplate {
            return try await generateTemplateBasedSummary(
                from: content,
                templateType: templateType,
                sessionType: sessionType,
                includeTechnical: includeTechnical,
                includeActionItems: includeActionItems
            )
        }

        // Generate overview
        let overview = try await generateOverview(
            from: content,
            sessionType: sessionType,
            detailLevel: detailLevel
        )

        // Extract key points
        let keyPoints = try await extractKeyPoints(
            from: content,
            focusAreas: focusAreas,
            detailLevel: detailLevel
        )

        // Extract technical details if requested
        var technicalDetails: TechnicalDetails?
        if includeTechnical {
            technicalDetails = try await extractTechnicalDetails(from: content)
        }

        // Extract action items if requested
        var actionItems: [ActionItem] = []
        if includeActionItems {
            actionItems = try await extractActionItems(from: content)
        }

        // Create session metadata
        let metadata = SessionMetadata(
            sessionType: sessionType,
            duration: durationEstimate,
            participants: extractParticipants(from: content),
            date: extractSessionDate(from: content) ?? formatDate(Date()),
            focusAreas: focusAreas,
            detailLevel: detailLevel
        )

        // Calculate confidence based on content quality
        let confidence = calculateConfidence(
            content: content,
            overview: overview,
            keyPoints: keyPoints,
            hasTechnical: technicalDetails != nil,
            hasActionItems: !actionItems.isEmpty
        )

        return SessionSummary(
            overview: overview,
            keyPoints: keyPoints,
            technicalDetails: technicalDetails,
            actionItems: actionItems,
            sessionMetadata: metadata,
            confidence: confidence
        )
    }

    /// Generate session overview based on type and detail level
    private func generateOverview(
        from content: String,
        sessionType: String,
        detailLevel: String
    ) async throws -> String {

        let sentences = content.components(separatedBy: ".").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        switch detailLevel {
        case "brief":
            // Extract 1-2 sentences that best represent the session
            return extractBestOverviewSentences(from: sentences, count: 2)

        case "standard":
            // Generate a 3-4 sentence overview
            return generateStandardOverview(from: content, sessionType: sessionType)

        case "detailed":
            // Generate comprehensive overview with session type context
            return generateDetailedOverview(from: content, sessionType: sessionType)

        case "comprehensive":
            // Full detailed overview with all aspects
            return generateComprehensiveOverview(from: content, sessionType: sessionType)

        default:
            return generateStandardOverview(from: content, sessionType: sessionType)
        }
    }

    /// Extract key points from content
    private func extractKeyPoints(
        from content: String,
        focusAreas: [String],
        detailLevel: String
    ) async throws -> [String] {

        var keyPoints: [String] = []

        // Extract based on session type
        switch focusAreas.isEmpty ? nil : focusAreas.first {
        case "settings":
            keyPoints.append(contentsOf: extractSettingsPoints(from: content))
        case "techniques":
            keyPoints.append(contentsOf: extractTechniquePoints(from: content))
        case "issues":
            keyPoints.append(contentsOf: extractIssuePoints(from: content))
        case "decisions":
            keyPoints.append(contentsOf: extractDecisionPoints(from: content))
        default:
            // Extract all types of key points
            keyPoints.append(contentsOf: extractAllKeyPoints(from: content))
        }

        // Filter and prioritize based on detail level
        let maxPoints = getMaxPointsForDetailLevel(detailLevel)
        return prioritizeKeyPoints(keyPoints, maxCount: maxPoints)
    }

    /// Extract technical details from content
    private func extractTechnicalDetails(from content: String) async throws -> TechnicalDetails {
        let equipment = extractEquipment(from: content)
        let settings = extractSettings(from: content)
        let techniques = extractTechniques(from: content)
        let software = extractSoftware(from: content)
        let plugins = extractPlugins(from: content)

        return TechnicalDetails(
            equipment: equipment,
            settings: settings,
            techniques: techniques,
            software: software,
            plugins: plugins
        )
    }

    /// Extract action items from content
    private func extractActionItems(from content: String) async throws -> [ActionItem] {
        let actionPatterns = [
            "TODO:",
            "Need to",
            "Should",
            "Follow up",
            "Next step",
            "Action item",
            "Remember to"
        ]

        var actionItems: [ActionItem] = []
        let sentences = content.components(separatedBy: ".").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        for sentence in sentences {
            for pattern in actionPatterns {
                if sentence.lowercased().contains(pattern.lowercased()) {
                    let actionItem = ActionItem(
                        description: sentence,
                        priority: determinePriority(from: sentence),
                        assignee: extractAssignee(from: sentence),
                        dueDate: extractDueDate(from: sentence),
                        context: extractContext(from: sentence)
                    )
                    actionItems.append(actionItem)
                    break
                }
            }
        }

        return actionItems
    }

    // MARK: - Helper Methods

    private func extractBestOverviewSentences(from sentences: [String], count: Int) -> String {
        // Filter for meaningful sentences (minimum length)
        let meaningfulSentences = sentences.filter { $0.count > 10 }

        // Take first N sentences or all if fewer
        let selectedSentences = Array(meaningfulSentences.prefix(count))
        return selectedSentences.joined(separator: ". ")
    }

    private func generateStandardOverview(from content: String, sessionType: String) -> String {
        // Extract key information based on session type
        let sessionTypeKeywords = getSessionTypeKeywords(sessionType)
        let sentences = content.components(separatedBy: ".").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        var overviewSentences: [String] = []

        // Look for sentences with session-specific keywords
        for sentence in sentences.prefix(5) {
            let lowercaseSentence = sentence.lowercased()
            for keyword in sessionTypeKeywords {
                if lowercaseSentence.contains(keyword.lowercased()) {
                    overviewSentences.append(sentence.trimmingCharacters(in: .whitespacesAndNewlines))
                    break
                }
            }
        }

        // If no specific sentences found, use first few sentences
        if overviewSentences.isEmpty {
            overviewSentences = Array(sentences.prefix(3))
        }

        return overviewSentences.joined(separator: ". ")
    }

    private func generateDetailedOverview(from content: String, sessionType: String) -> String {
        let standardOverview = generateStandardOverview(from: content, sessionType: sessionType)
        let keyActivities = extractKeyActivities(from: content, sessionType: sessionType)

        var overview = standardOverview
        if !keyActivities.isEmpty {
            overview += ". Key activities included: " + keyActivities.joined(separator: ", ")
        }

        return overview
    }

    private func generateComprehensiveOverview(from content: String, sessionType: String) -> String {
        let detailedOverview = generateDetailedOverview(from: content, sessionType: sessionType)
        let outcome = extractSessionOutcome(from: content)
        let challenges = extractChallenges(from: content)

        var overview = detailedOverview

        if !outcome.isEmpty {
            overview += ". Session outcome: " + outcome
        }

        if !challenges.isEmpty {
            overview += ". Challenges addressed: " + challenges.joined(separator: ", ")
        }

        return overview
    }

    private func getSessionTypeKeywords(_ sessionType: String) -> [String] {
        switch sessionType.lowercased() {
        case "tracking":
            return ["recorded", "tracking", "microphone", "take", "performance", "instrument"]
        case "mixing":
            return ["mix", "balance", "levels", "pan", "eq", "compression", "reverb"]
        case "mastering":
            return ["master", "final", "loudness", "limiting", "eq", "stereo"]
        case "production":
            return ["arrangement", "production", "structure", "composition", "songwriting"]
        case "sound_design":
            return ["sound design", "foley", "effects", "ambient", "texture"]
        case "edit":
            return ["edit", "cut", "splice", "timing", "cleanup", "comp"]
        case "review":
            return ["review", "feedback", "notes", "changes", "revision"]
        default:
            return ["session", "work", "project", "audio"]
        }
    }

    private func extractKeyActivities(from content: String, sessionType: String) -> [String] {
        let keywords = getSessionTypeKeywords(sessionType)
        let sentences = content.components(separatedBy: ".").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        var activities: [String] = []

        for sentence in sentences.prefix(10) {
            let lowercaseSentence = sentence.lowercased()
            for keyword in keywords {
                if lowercaseSentence.contains(keyword.lowercased()) {
                    activities.append(sentence.trimmingCharacters(in: .whitespacesAndNewlines))
                    break
                }
            }
        }

        return Array(activities.prefix(3))
    }

    private func extractSessionOutcome(from content: String) -> String {
        let outcomeKeywords = ["result", "outcome", "achieved", "completed", "finished", "final", "accomplished"]
        let sentences = content.components(separatedBy: ".").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        for sentence in sentences.suffix(5) {
            let lowercaseSentence = sentence.lowercased()
            for keyword in outcomeKeywords {
                if lowercaseSentence.contains(keyword) {
                    return sentence.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }

        return ""
    }

    private func extractChallenges(from content: String) -> [String] {
        let challengeKeywords = ["problem", "issue", "challenge", "difficulty", "struggle", "fix", "resolve", "solution"]
        let sentences = content.components(separatedBy: ".").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        var challenges: [String] = []

        for sentence in sentences {
            let lowercaseSentence = sentence.lowercased()
            for keyword in challengeKeywords {
                if lowercaseSentence.contains(keyword) {
                    challenges.append(sentence.trimmingCharacters(in: .whitespacesAndNewlines))
                    break
                }
            }
        }

        return Array(challenges.prefix(2))
    }

    private func extractAllKeyPoints(from content: String) -> [String] {
        var keyPoints: [String] = []

        // Add settings points
        keyPoints.append(contentsOf: extractSettingsPoints(from: content))

        // Add technique points
        keyPoints.append(contentsOf: extractTechniquePoints(from: content))

        // Add issue points
        keyPoints.append(contentsOf: extractIssuePoints(from: content))

        // Add decision points
        keyPoints.append(contentsOf: extractDecisionPoints(from: content))

        return keyPoints
    }

    private func extractSettingsPoints(from content: String) -> [String] {
        let settingsKeywords = ["setting", "parameter", "value", "level", "amount", "threshold", "frequency", "db"]
        let sentences = content.components(separatedBy: ".").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        var settingsPoints: [String] = []

        for sentence in sentences {
            let lowercaseSentence = sentence.lowercased()
            for keyword in settingsKeywords {
                if lowercaseSentence.contains(keyword) {
                    settingsPoints.append(sentence.trimmingCharacters(in: .whitespacesAndNewlines))
                    break
                }
            }
        }

        return settingsPoints
    }

    private func extractTechniquePoints(from content: String) -> [String] {
        let techniqueKeywords = ["technique", "method", "approach", "process", "procedure", "way", "how"]
        let sentences = content.components(separatedBy: ".").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        var techniquePoints: [String] = []

        for sentence in sentences {
            let lowercaseSentence = sentence.lowercased()
            for keyword in techniqueKeywords {
                if lowercaseSentence.contains(keyword) {
                    techniquePoints.append(sentence.trimmingCharacters(in: .whitespacesAndNewlines))
                    break
                }
            }
        }

        return techniquePoints
    }

    private func extractIssuePoints(from content: String) -> [String] {
        let issueKeywords = ["issue", "problem", "challenge", "difficulty", "bug", "error", "mistake"]
        let sentences = content.components(separatedBy: ".").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        var issuePoints: [String] = []

        for sentence in sentences {
            let lowercaseSentence = sentence.lowercased()
            for keyword in issueKeywords {
                if lowercaseSentence.contains(keyword) {
                    issuePoints.append(sentence.trimmingCharacters(in: .whitespacesAndNewlines))
                    break
                }
            }
        }

        return issuePoints
    }

    private func extractDecisionPoints(from content: String) -> [String] {
        let decisionKeywords = ["decided", "chose", "selected", "went with", "settled on", "agreed", "concluded"]
        let sentences = content.components(separatedBy: ".").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        var decisionPoints: [String] = []

        for sentence in sentences {
            let lowercaseSentence = sentence.lowercased()
            for keyword in decisionKeywords {
                if lowercaseSentence.contains(keyword) {
                    decisionPoints.append(sentence.trimmingCharacters(in: .whitespacesAndNewlines))
                    break
                }
            }
        }

        return decisionPoints
    }

    private func getMaxPointsForDetailLevel(_ detailLevel: String) -> Int {
        switch detailLevel.lowercased() {
        case "brief":
            return 3
        case "standard":
            return 5
        case "detailed":
            return 8
        case "comprehensive":
            return 12
        default:
            return 5
        }
    }

    private func prioritizeKeyPoints(_ points: [String], maxCount: Int) -> [String] {
        // Simple prioritization: longer sentences and those with specific keywords get priority
        let priorityKeywords = ["important", "key", "critical", "essential", "major", "significant"]

        let prioritizedPoints = points.sorted { point1, point2 in
            let score1 = calculatePriorityScore(point1, keywords: priorityKeywords)
            let score2 = calculatePriorityScore(point2, keywords: priorityKeywords)

            if score1 != score2 {
                return score1 > score2
            }

            return point1.count > point2.count
        }

        return Array(prioritizedPoints.prefix(maxCount))
    }

    private func calculatePriorityScore(_ point: String, keywords: [String]) -> Int {
        var score = 0
        let lowercasePoint = point.lowercased()

        for keyword in keywords {
            if lowercasePoint.contains(keyword) {
                score += 2
            }
        }

        // Bonus points for specific audio terms
        let audioTerms = ["eq", "compressor", "reverb", "delay", "mic", "preamp", "converter"]
        for term in audioTerms {
            if lowercasePoint.contains(term) {
                score += 1
            }
        }

        return score
    }

    private func extractEquipment(from content: String) -> [String] {
        let equipmentPatterns = [
            "\\b(mic|microphone|preamp|compressor|eq|reverb|delay|console|interface|converter|monitor)\\b",
            "\\b(Pro Tools|Logic Pro|Ableton|Cubase|Nuendo|Reaper)\\b"
        ]

        var equipment: [String] = []

        for pattern in equipmentPatterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { continue }

            let matches = regex.matches(in: content, range: NSRange(content.startIndex..., in: content))

            for match in matches {
                if let range = Range(match.range, in: content) {
                    let foundEquipment = String(content[range])
                    if !equipment.contains(foundEquipment) {
                        equipment.append(foundEquipment)
                    }
                }
            }
        }

        return equipment
    }

    private func extractSettings(from content: String) -> [String] {
        let settingsPattern = "\\b(\\d+\\s*(Hz|kHz|dB|ms|bpm))\\b"

        var settings: [String] = []

        guard let regex = try? NSRegularExpression(pattern: settingsPattern, options: .caseInsensitive) else {
            return settings
        }

        let matches = regex.matches(in: content, range: NSRange(content.startIndex..., in: content))

        for match in matches {
            if let range = Range(match.range, in: content) {
                let setting = String(content[range])
                settings.append(setting)
            }
        }

        return settings
    }

    private func extractTechniques(from content: String) -> [String] {
        let techniqueKeywords = ["recording", "mixing", "mastering", "eq", "compression", "reverb", "delay", "automation", "bussing"]
        let sentences = content.components(separatedBy: ".").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        var techniques: [String] = []

        for sentence in sentences {
            let lowercaseSentence = sentence.lowercased()
            for keyword in techniqueKeywords {
                if lowercaseSentence.contains(keyword) {
                    let technique = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !techniques.contains(technique) {
                        techniques.append(technique)
                    }
                    break
                }
            }
        }

        return Array(techniques.prefix(5))
    }

    private func extractSoftware(from content: String) -> [String] {
        let softwarePatterns = [
            "\\b(Pro Tools|Logic Pro|Ableton Live|Cubase|Nuendo|Reaper|FL Studio|Studio One)\\b",
            "\\b(Waves|Native Instruments|Universal Audio|iZotope|Soundtoys|FabFilter)\\b"
        ]

        var software: [String] = []

        for pattern in softwarePatterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { continue }

            let matches = regex.matches(in: content, range: NSRange(content.startIndex..., in: content))

            for match in matches {
                if let range = Range(match.range, in: content) {
                    let foundSoftware = String(content[range])
                    if !software.contains(foundSoftware) {
                        software.append(foundSoftware)
                    }
                }
            }
        }

        return software
    }

    private func extractPlugins(from content: String) -> [String] {
        let pluginPattern = "\\b([A-Z][a-zA-Z\\s]*?(EQ|Compressor|Reverb|Delay|Limiter|Gate|Expander|Phaser|Chorus|Flanger|Distortion|Saturation))\\b"

        var plugins: [String] = []

        guard let regex = try? NSRegularExpression(pattern: pluginPattern) else {
            return plugins
        }

        let matches = regex.matches(in: content, range: NSRange(content.startIndex..., in: content))

        for match in matches {
            if let range = Range(match.range, in: content) {
                let plugin = String(content[range])
                if !plugins.contains(plugin) {
                    plugins.append(plugin)
                }
            }
        }

        return plugins
    }

    private func extractParticipants(from content: String) -> [String] {
        // Simple extraction of names - in a real implementation, this would be more sophisticated
        let namePattern = "\\b([A-Z][a-z]+ [A-Z][a-z]+)\\b"

        var participants: [String] = []

        guard let regex = try? NSRegularExpression(pattern: namePattern) else {
            return participants
        }

        let matches = regex.matches(in: content, range: NSRange(content.startIndex..., in: content))

        for match in matches {
            if let range = Range(match.range, in: content) {
                let name = String(content[range])
                if !participants.contains(name) && !isCommonWord(name) {
                    participants.append(name)
                }
            }
        }

        return Array(participants.prefix(5))
    }

    private func isCommonWord(_ word: String) -> Bool {
        let commonWords = ["Session", "Note", "Audio", "Sound", "Music", "Recording", "Mixing"]
        return commonWords.contains(word)
    }

    private func extractSessionDate(from content: String) -> String? {
        let datePattern = "\\b(\\d{1,2}[/-]\\d{1,2}[/-]\\d{2,4}|\\d{4}[/-]\\d{1,2}[/-]\\d{1,2})\\b"

        guard let regex = try? NSRegularExpression(pattern: datePattern) else {
            return nil
        }

        if let match = regex.firstMatch(in: content, range: NSRange(content.startIndex..., in: content)),
           let range = Range(match.range, in: content) {
            return String(content[range])
        }

        return nil
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func determinePriority(from sentence: String) -> String {
        let lowercaseSentence = sentence.lowercased()

        if lowercaseSentence.contains("urgent") || lowercaseSentence.contains("asap") || lowercaseSentence.contains("immediately") {
            return "high"
        } else if lowercaseSentence.contains("when possible") || lowercaseSentence.contains("sometime") {
            return "low"
        } else {
            return "medium"
        }
    }

    private func extractAssignee(from sentence: String) -> String? {
        // Simple pattern to find names after "assign to" or similar phrases
        let assigneePattern = "\\b(assign to|assigned to|by)\\s+([A-Z][a-z]+ [A-Z][a-z]+)\\b"

        guard let regex = try? NSRegularExpression(pattern: assigneePattern, options: .caseInsensitive) else {
            return nil
        }

        if let match = regex.firstMatch(in: sentence, range: NSRange(sentence.startIndex..., in: sentence)),
           let assigneeRange = Range(match.range(at: 2), in: sentence) {
            return String(sentence[assigneeRange])
        }

        return nil
    }

    private func extractDueDate(from sentence: String) -> String? {
        let datePattern = "\\b(due|by|before|on)\\s+(\\d{1,2}[/-]\\d{1,2}[/-]\\d{2,4}|tomorrow|today|next week|monday|tuesday|wednesday|thursday|friday|saturday|sunday)\\b"

        guard let regex = try? NSRegularExpression(pattern: datePattern, options: .caseInsensitive) else {
            return nil
        }

        if let match = regex.firstMatch(in: sentence, range: NSRange(sentence.startIndex..., in: sentence)),
           let dateRange = Range(match.range(at: 2), in: sentence) {
            return String(sentence[dateRange])
        }

        return nil
    }

    private func extractContext(from sentence: String) -> String? {
        // Extract context from surrounding content
        let words = sentence.components(separatedBy: " ")
        if words.count > 5 {
            return Array(words.prefix(8)).joined(separator: " ")
        }
        return nil
    }

    private func calculateConfidence(
        content: String,
        overview: String,
        keyPoints: [String],
        hasTechnical: Bool,
        hasActionItems: Bool
    ) -> Double {
        var confidence: Double = 0.5 // Base confidence

        // Content quality factors
        if content.count > 100 {
            confidence += 0.1
        }

        if content.count > 500 {
            confidence += 0.1
        }

        // Overview quality
        if !overview.isEmpty && overview.count > 50 {
            confidence += 0.1
        }

        // Key points
        if !keyPoints.isEmpty {
            confidence += 0.1
            if keyPoints.count >= 3 {
                confidence += 0.1
            }
        }

        // Technical details
        if hasTechnical {
            confidence += 0.1
        }

        // Action items
        if hasActionItems {
            confidence += 0.1
        }

        return min(confidence, 1.0)
    }

    /// Generate template-based summary using engineering templates
    private func generateTemplateBasedSummary(
        from content: String,
        templateType: String,
        sessionType: String,
        includeTechnical: Bool,
        includeActionItems: Bool
    ) async throws -> SessionSummary {

        // Get the appropriate template
        let template: String
        switch templateType.lowercased() {
        case "tracking":
            template = EngineeringTemplates.trackingSessionTemplate()
        case "mixing":
            template = EngineeringTemplates.mixingSessionTemplate()
        case "mastering":
            template = EngineeringTemplates.masteringSessionTemplate()
        case "daily_summary":
            template = EngineeringTemplates.dailySessionSummary()
        case "project_status":
            template = EngineeringTemplates.projectStatusTemplate()
        case "feedback":
            template = EngineeringTemplates.clientFeedbackTemplate()
        case "internal_review":
            template = EngineeringTemplates.internalReviewTemplate()
        case "gear_setup":
            template = EngineeringTemplates.gearSetupTemplate()
        case "troubleshooting":
            template = EngineeringTemplates.troubleshootingTemplate()
        default:
            template = EngineeringTemplates.trackingSessionTemplate()
        }

        // Extract template values from content
        let templateValues = extractTemplateValues(from: content, templateType: templateType, sessionType: sessionType)

        // Populate template with extracted values
        let populatedTemplate = EngineeringTemplates.populateTemplate(template, with: templateValues)

        // Create overview from populated template
        let overview = generateOverviewFromTemplate(populatedTemplate, templateType: templateType)

        // Extract key points based on template content
        let keyPoints = extractKeyPointsFromTemplate(populatedTemplate, templateType: templateType)

        // Extract technical details if requested
        var technicalDetails: TechnicalDetails?
        if includeTechnical {
            technicalDetails = extractTechnicalDetailsFromTemplate(populatedTemplate, templateType: templateType)
        }

        // Extract action items if requested
        var actionItems: [ActionItem] = []
        if includeActionItems {
            actionItems = extractActionItemsFromTemplate(populatedTemplate, templateType: templateType)
        }

        // Create session metadata
        let metadata = SessionMetadata(
            sessionType: sessionType,
            duration: extractDurationFromTemplate(populatedTemplate),
            participants: extractParticipantsFromTemplate(populatedTemplate),
            date: extractDateFromTemplate(populatedTemplate) ?? formatDate(Date()),
            focusAreas: extractFocusAreasFromTemplate(populatedTemplate),
            detailLevel: "template"
        )

        // Calculate confidence based on template population quality
        let confidence = calculateTemplateConfidence(
            template: populatedTemplate,
            originalContent: content,
            hasTechnical: technicalDetails != nil,
            hasActionItems: !actionItems.isEmpty
        )

        return SessionSummary(
            overview: overview,
            keyPoints: keyPoints,
            technicalDetails: technicalDetails,
            actionItems: actionItems,
            sessionMetadata: metadata,
            confidence: confidence
        )
    }

    /// Extract template values from content
    private func extractTemplateValues(from content: String, templateType: String, sessionType: String) -> [String: String] {
        var values: [String: String] = EngineeringTemplates.getDefaultValues(for: sessionType)

        // Extract date information
        if let extractedDate = extractSessionDate(from: content) {
            values["date"] = extractedDate
        }

        // Extract participants
        let participants = extractParticipants(from: content)
        if !participants.isEmpty {
            values["engineer"] = participants.first ?? "Engineer Name"
            if participants.count > 1 {
                values["assistant"] = participants[1]
            }
        }

        // Extract project information
        let projectName = extractProjectName(from: content)
        if !projectName.isEmpty {
            values["project"] = projectName
        }

        // Extract session-specific information
        switch templateType.lowercased() {
        case "tracking":
            values["instruments_list"] = extractInstrumentsList(from: content)
            values["issues_solutions"] = extractIssuesAndSolutions(from: content)
            values["next_steps"] = extractNextSteps(from: content)

        case "mixing":
            values["mix_goal"] = extractMixGoal(from: content)
            values["client_notes"] = extractClientNotes(from: content)
            values["revision_requests"] = extractRevisionRequests(from: content)

        case "mastering":
            values["dynamic_range"] = extractDynamicRange(from: content)
            values["processing_notes"] = extractProcessingNotes(from: content)
            values["delivery_formats"] = extractDeliveryFormats(from: content)

        default:
            break
        }

        // Extract equipment information
        let equipment = extractEquipment(from: content)
        if !equipment.isEmpty {
            values["microphones"] = equipment.filter { $0.lowercased().contains("mic") }.joined(separator: ", ")
            values["preamps"] = equipment.filter { $0.lowercased().contains("preamp") }.joined(separator: ", ")
        }

        // Extract software information
        let software = extractSoftware(from: content)
        if !software.isEmpty {
            values["daw"] = software.first ?? "DAW Name"
        }

        // Extract technical settings
        let settings = extractSettings(from: content)
        if !settings.isEmpty {
            values["sample_rate"] = settings.filter { $0.contains("Hz") }.first ?? "48 kHz"
            values["bit_depth"] = settings.filter { $0.contains("bit") }.first ?? "24-bit"
        }

        return values
    }

    /// Generate overview from populated template
    private func generateOverviewFromTemplate(_ template: String, templateType: String) -> String {
        let lines = template.components(separatedBy: "\n")
        var overviewLines: [String] = []

        // Extract meaningful lines for overview (skip headers and empty lines)
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedLine.isEmpty && !trimmedLine.contains("=") && !trimmedLine.contains("---") {
                // Skip lines with template placeholders
                if !trimmedLine.contains("{") && trimmedLine.count > 10 {
                    overviewLines.append(trimmedLine)
                }
            }
        }

        // Take first few meaningful lines as overview
        let overviewText = Array(overviewLines.prefix(3)).joined(separator: ". ")
        return overviewText.isEmpty ? "Template-based session summary generated for \(templateType)" : overviewText
    }

    /// Extract key points from template content
    private func extractKeyPointsFromTemplate(_ template: String, templateType: String) -> [String] {
        var keyPoints: [String] = []
        let lines = template.components(separatedBy: "\n")

        // Look for filled-in sections
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)

            // Skip headers and empty lines
            if trimmedLine.isEmpty || trimmedLine.contains("=") || trimmedLine.contains("---") {
                continue
            }

            // Skip template placeholders
            if trimmedLine.contains("{") && trimmedLine.contains("}") {
                continue
            }

            // Include meaningful content lines
            if trimmedLine.count > 15 && !keyPoints.contains(trimmedLine) {
                keyPoints.append(trimmedLine)
            }
        }

        return Array(keyPoints.prefix(8))
    }

    /// Extract technical details from template
    private func extractTechnicalDetailsFromTemplate(_ template: String, templateType: String) -> TechnicalDetails? {
        let equipment = extractEquipmentFromTemplate(template)
        let settings = extractSettingsFromTemplate(template)
        let techniques = extractTechniquesFromTemplate(template)
        let software = extractSoftwareFromTemplate(template)
        let plugins = extractPluginsFromTemplate(template)

        if equipment.isEmpty && settings.isEmpty && techniques.isEmpty && software.isEmpty && plugins.isEmpty {
            return nil
        }

        return TechnicalDetails(
            equipment: equipment,
            settings: settings,
            techniques: techniques,
            software: software,
            plugins: plugins
        )
    }

    /// Extract action items from template
    private func extractActionItemsFromTemplate(_ template: String, templateType: String) -> [ActionItem] {
        let content = template
        var actionItems: [ActionItem] = []

        let actionPatterns = [
            "TODO:", "Need to", "Should", "Follow up", "Next step", "Action item", "Remember to"
        ]

        let sentences = content.components(separatedBy: ".").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        for sentence in sentences {
            for pattern in actionPatterns {
                if sentence.lowercased().contains(pattern.lowercased()) {
                    let actionItem = ActionItem(
                        description: sentence,
                        priority: determinePriority(from: sentence),
                        assignee: extractAssignee(from: sentence),
                        dueDate: extractDueDate(from: sentence),
                        context: extractContext(from: sentence)
                    )
                    actionItems.append(actionItem)
                    break
                }
            }
        }

        return actionItems
    }

    // Template-specific extraction methods
    private func extractProjectName(from content: String) -> String {
        let patterns = ["project:", "song:", "track:", "title:"]
        for pattern in patterns {
            if let range = content.lowercased().range(of: pattern) {
                let afterPattern = content[range.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
                let firstLine = afterPattern.components(separatedBy: "\n").first ?? ""
                if !firstLine.isEmpty && firstLine.count < 50 {
                    return firstLine.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }
        return ""
    }

    private func extractInstrumentsList(from content: String) -> String {
        let instrumentKeywords = ["guitar", "bass", "drums", "vocals", "piano", "keys", "synth"]
        let sentences = content.components(separatedBy: ".").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        var instruments: [String] = []
        for sentence in sentences {
            let lowercaseSentence = sentence.lowercased()
            for keyword in instrumentKeywords {
                if lowercaseSentence.contains(keyword) {
                    instruments.append(sentence)
                    break
                }
            }
        }

        return instruments.joined(separator: "\n")
    }

    private func extractNextSteps(from content: String) -> String {
        let nextStepKeywords = ["next", "follow", "continue", "proceed", "upcoming", "future", "plan", "schedule"]
        let sentences = content.components(separatedBy: ".").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        var nextSteps: [String] = []
        for sentence in sentences {
            let lowercaseSentence = sentence.lowercased()
            for keyword in nextStepKeywords {
                if lowercaseSentence.contains(keyword) {
                    nextSteps.append(sentence)
                    break
                }
            }
        }

        return nextSteps.joined(separator: "\n")
    }

    private func extractIssuesAndSolutions(from content: String) -> String {
        let issueKeywords = ["problem", "issue", "challenge", "solution", "fix", "resolve"]
        let sentences = content.components(separatedBy: ".").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        var issues: [String] = []
        for sentence in sentences {
            let lowercaseSentence = sentence.lowercased()
            for keyword in issueKeywords {
                if lowercaseSentence.contains(keyword) {
                    issues.append(sentence)
                    break
                }
            }
        }

        return issues.joined(separator: "\n")
    }

    private func extractMixGoal(from content: String) -> String {
        let goalKeywords = ["goal", "objective", "aim", "target", "vision", "direction"]
        let sentences = content.components(separatedBy: ".").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        for sentence in sentences {
            let lowercaseSentence = sentence.lowercased()
            for keyword in goalKeywords {
                if lowercaseSentence.contains(keyword) {
                    return sentence
                }
            }
        }

        return "Standard mixing goals: clarity, balance, and commercial viability"
    }

    private func extractClientNotes(from content: String) -> String {
        let clientKeywords = ["client", "feedback", "notes", "comments", "review"]
        let sentences = content.components(separatedBy: ".").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        var notes: [String] = []
        for sentence in sentences {
            let lowercaseSentence = sentence.lowercased()
            for keyword in clientKeywords {
                if lowercaseSentence.contains(keyword) {
                    notes.append(sentence)
                    break
                }
            }
        }

        return notes.joined(separator: "\n")
    }

    private func extractRevisionRequests(from content: String) -> String {
        let revisionKeywords = ["change", "adjust", "modify", "update", "revision", "edit"]
        let sentences = content.components(separatedBy: ".").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        var revisions: [String] = []
        for sentence in sentences {
            let lowercaseSentence = sentence.lowercased()
            for keyword in revisionKeywords {
                if lowercaseSentence.contains(keyword) {
                    revisions.append(sentence)
                    break
                }
            }
        }

        return revisions.joined(separator: "\n")
    }

    private func extractDynamicRange(from content: String) -> String {
        let drPattern = "\\b(DR\\s*\\d+|dynamic\\s*range\\s*\\d+)\\b"

        guard let regex = try? NSRegularExpression(pattern: drPattern, options: .caseInsensitive) else {
            return "DR not specified"
        }

        if let match = regex.firstMatch(in: content, range: NSRange(content.startIndex..., in: content)),
           let range = Range(match.range, in: content) {
            return String(content[range])
        }

        return "DR not specified"
    }

    private func extractProcessingNotes(from content: String) -> String {
        let processingKeywords = ["eq", "compression", "reverb", "delay", "limiting", "mastering"]
        let sentences = content.components(separatedBy: ".").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        var notes: [String] = []
        for sentence in sentences {
            let lowercaseSentence = sentence.lowercased()
            for keyword in processingKeywords {
                if lowercaseSentence.contains(keyword) {
                    notes.append(sentence)
                    break
                }
            }
        }

        return notes.joined(separator: "\n")
    }

    private func extractDeliveryFormats(from content: String) -> String {
        let formatKeywords = ["wav", "mp3", "flac", "aiff", "m4a", "ddp", "cd"]
        let words = content.components(separatedBy: .whitespacesAndNewlines)

        var formats: [String] = []
        for word in words {
            let lowercaseWord = word.lowercased()
            for keyword in formatKeywords {
                if lowercaseWord.contains(keyword) {
                    formats.append(word)
                    break
                }
            }
        }

        return formats.isEmpty ? "Standard formats: WAV 16-bit/44.1kHz" : formats.joined(separator: ", ")
    }

    private func extractEquipmentFromTemplate(_ template: String) -> [String] {
        return extractEquipment(from: template)
    }

    private func extractSettingsFromTemplate(_ template: String) -> [String] {
        return extractSettings(from: template)
    }

    private func extractTechniquesFromTemplate(_ template: String) -> [String] {
        return extractTechniques(from: template)
    }

    private func extractSoftwareFromTemplate(_ template: String) -> [String] {
        return extractSoftware(from: template)
    }

    private func extractPluginsFromTemplate(_ template: String) -> [String] {
        return extractPlugins(from: template)
    }

    private func extractDurationFromTemplate(_ template: String) -> String? {
        let durationPattern = "\\b(\\d+\\s*(hours?|hrs?|minutes?|mins?))\\b"

        guard let regex = try? NSRegularExpression(pattern: durationPattern, options: .caseInsensitive) else {
            return nil
        }

        if let match = regex.firstMatch(in: template, range: NSRange(template.startIndex..., in: template)),
           let range = Range(match.range, in: template) {
            return String(template[range])
        }

        return nil
    }

    private func extractParticipantsFromTemplate(_ template: String) -> [String] {
        return extractParticipants(from: template)
    }

    private func extractDateFromTemplate(_ template: String) -> String? {
        return extractSessionDate(from: template)
    }

    private func extractFocusAreasFromTemplate(_ template: String) -> [String] {
        let focusAreas = ["tracking", "mixing", "mastering", "editing", "production"]
        let lowercaseTemplate = template.lowercased()

        return focusAreas.filter { lowercaseTemplate.contains($0) }
    }

    private func calculateTemplateConfidence(
        template: String,
        originalContent: String,
        hasTechnical: Bool,
        hasActionItems: Bool
    ) -> Double {
        var confidence: Double = 0.6 // Base confidence for template generation

        // Check how well template was populated
        let unfilledPlaceholders = template.components(separatedBy: "{").count - 1
        let totalPlaceholders = template.components(separatedBy: "}").count - 1

        if totalPlaceholders > 0 {
            let fillRatio = Double(totalPlaceholders - unfilledPlaceholders) / Double(totalPlaceholders)
            confidence += fillRatio * 0.3
        }

        // Content quality factors
        if originalContent.count > 100 {
            confidence += 0.05
        }

        if originalContent.count > 500 {
            confidence += 0.05
        }

        // Technical details bonus
        if hasTechnical {
            confidence += 0.1
        }

        // Action items bonus
        if hasActionItems {
            confidence += 0.1
        }

        return min(confidence, 1.0)
    }

    /// Encode result as JSON string
    private func encodeJSON(_ result: SessionSummary) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data = try encoder.encode(result)
        return String(data: data, encoding: .utf8) ?? "{}"
    }
}