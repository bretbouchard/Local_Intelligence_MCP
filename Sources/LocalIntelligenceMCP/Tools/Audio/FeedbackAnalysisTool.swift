//
//  FeedbackAnalysisTool.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-09.
//

import Foundation

/// Client feedback analysis tool for sentiment and action item extraction
/// Implements apple.feedback.analyze specification for processing client feedback on audio work
public final class FeedbackAnalysisTool: AudioDomainTool, @unchecked Sendable {

    // MARK: - Initialization

    public convenience init(
        logger: Logger,
        securityManager: SecurityManager
    ) {
        self.init(
            name: "apple_feedback_analyze",
            description: "Analyze client feedback with sentiment analysis and action item extraction for audio projects",
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
                "feedback": [
                    "type": "string",
                    "description": "Client feedback text to analyze"
                ],
                "project_context": [
                    "type": "string",
                    "description": "Context about the project (e.g., 'mix review', 'mastering feedback', 'production notes')"
                ],
                "feedback_type": [
                    "type": "string",
                    "enum": ["mix", "master", "production", "general", "technical", "creative"],
                    "default": "general",
                    "description": "Type of feedback being provided"
                ],
                "sentiment_analysis": [
                    "type": "boolean",
                    "default": true,
                    "description": "Perform sentiment analysis on the feedback"
                ],
                "extract_action_items": [
                    "type": "boolean",
                    "default": true,
                    "description": "Extract actionable items from feedback"
                ],
                "identify_priorities": [
                    "type": "boolean",
                    "default": true,
                    "description": "Identify priority levels for different feedback points"
                ],
                "summarize_feedback": [
                    "type": "boolean",
                    "default": true,
                    "description": "Generate a summary of the feedback"
                ],
                "use_template": [
                    "type": "boolean",
                    "default": false,
                    "description": "Use engineering-specific template for feedback analysis"
                ],
                "template_type": [
                    "type": "string",
                    "enum": ["client_feedback", "internal_review"],
                    "default": "client_feedback",
                    "description": "Type of feedback template to use"
                ]
            ]),
            "required": AnyCodable(["feedback"])
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

    // MARK: - Feedback Analysis Types

    public struct FeedbackAnalysis: Codable, Sendable {
        let summary: String
        let sentiment: SentimentAnalysis
        let keyPoints: [KeyPoint]
        let actionItems: [ActionItem]
        let categories: [FeedbackCategory]
        let priorities: [PriorityItem]
        let metadata: FeedbackMetadata
        let confidence: Double

        public init(
            summary: String,
            sentiment: SentimentAnalysis,
            keyPoints: [KeyPoint] = [],
            actionItems: [ActionItem] = [],
            categories: [FeedbackCategory] = [],
            priorities: [PriorityItem] = [],
            metadata: FeedbackMetadata,
            confidence: Double = 0.8
        ) {
            self.summary = summary
            self.sentiment = sentiment
            self.keyPoints = keyPoints
            self.actionItems = actionItems
            self.categories = categories
            self.priorities = priorities
            self.metadata = metadata
            self.confidence = confidence
        }
    }

    public struct SentimentAnalysis: Codable, Sendable {
        let overall: SentimentScore
        let aspects: [AspectSentiment]
        let emotionalTone: String
        let confidence: Double

        public init(
            overall: SentimentScore,
            aspects: [AspectSentiment] = [],
            emotionalTone: String,
            confidence: Double = 0.8
        ) {
            self.overall = overall
            self.aspects = aspects
            self.emotionalTone = emotionalTone
            self.confidence = confidence
        }
    }

    public struct SentimentScore: Codable, Sendable {
        let label: String
        let score: Double
        let magnitude: Double

        public init(label: String, score: Double, magnitude: Double) {
            self.label = label
            self.score = score
            self.magnitude = magnitude
        }
    }

    public struct AspectSentiment: Codable, Sendable {
        let aspect: String
        let sentiment: SentimentScore
        let mention: String

        public init(aspect: String, sentiment: SentimentScore, mention: String) {
            self.aspect = aspect
            self.sentiment = sentiment
            self.mention = mention
        }
    }

    public struct KeyPoint: Codable, Sendable {
        let point: String
        let category: String
        let sentiment: String
        let importance: Int

        public init(point: String, category: String, sentiment: String, importance: Int = 1) {
            self.point = point
            self.category = category
            self.sentiment = sentiment
            self.importance = importance
        }
    }

    public struct ActionItem: Codable, Sendable {
        let description: String
        let priority: String
        let category: String
        let context: String
        let effort: String?

        public init(
            description: String,
            priority: String,
            category: String,
            context: String,
            effort: String? = nil
        ) {
            self.description = description
            self.priority = priority
            self.category = category
            self.context = context
            self.effort = effort
        }
    }

    public struct FeedbackCategory: Codable, Sendable {
        let name: String
        let count: Int
        let examples: [String]

        public init(name: String, count: Int, examples: [String]) {
            self.name = name
            self.count = count
            self.examples = examples
        }
    }

    public struct PriorityItem: Codable, Sendable {
        let item: String
        let priority: String
        let rationale: String

        public init(item: String, priority: String, rationale: String) {
            self.item = item
            self.priority = priority
            self.rationale = rationale
        }
    }

    public struct FeedbackMetadata: Codable, Sendable {
        let feedbackType: String
        let projectContext: String?
        let wordCount: Int
        let analyzedAt: String
        let processingTime: Double

        public init(
            feedbackType: String,
            projectContext: String? = nil,
            wordCount: Int,
            analyzedAt: String,
            processingTime: Double
        ) {
            self.feedbackType = feedbackType
            self.projectContext = projectContext
            self.wordCount = wordCount
            self.analyzedAt = analyzedAt
            self.processingTime = processingTime
        }
    }

    // MARK: - AudioDomainTool Implementation

    internal override func performExecution(parameters: [String: AnyCodable], context: MCPExecutionContext) async throws -> MCPResponse {
        // Extract feedback parameter
        guard let feedback = parameters["feedback"]?.value as? String else {
            throw ToolsRegistryError.invalidParameters("feedback parameter is required")
        }

        guard !feedback.isEmpty else {
            throw ToolsRegistryError.invalidParameters("feedback cannot be empty")
        }

        // Extract other parameters
        var processingParams: [String: Any] = [:]
        for (key, value) in parameters {
            processingParams[key] = value.value
        }

        // Process using the audio content method
        let result = try await processAudioContent(feedback, with: processingParams)

        return MCPResponse(
            success: true,
            data: AnyCodable(result),
            error: nil
        )
    }

    public override func processAudioContent(_ content: String, with parameters: [String: Any]) async throws -> String {
        let startTime = Date()

        await logger.debug("Starting feedback analysis", category: .general, metadata: [
            "tool": AnyCodable(name),
            "feedbackLength": AnyCodable(content.count)
        ])

        // Extract parameters
        let projectContext = parameters["project_context"] as? String
        let feedbackType = parameters["feedback_type"] as? String ?? "general"
        let performSentimentAnalysis = parameters["sentiment_analysis"] as? Bool ?? true
        let extractActionItems = parameters["extract_action_items"] as? Bool ?? true
        let identifyPriorities = parameters["identify_priorities"] as? Bool ?? true
        let summarizeFeedback = parameters["summarize_feedback"] as? Bool ?? true
        let useTemplate = parameters["use_template"] as? Bool ?? false
        let templateType = parameters["template_type"] as? String ?? "client_feedback"

        do {
            // Generate feedback analysis
            let analysis = try await generateFeedbackAnalysis(
                from: content,
                projectContext: projectContext,
                feedbackType: feedbackType,
                performSentimentAnalysis: performSentimentAnalysis,
                extractActionItems: extractActionItems,
                identifyPriorities: identifyPriorities,
                summarizeFeedback: summarizeFeedback,
                useTemplate: useTemplate,
                templateType: templateType,
                startTime: startTime
            )

            let response = try encodeJSON(analysis)

            await logger.info("Feedback analysis completed successfully", category: .general, metadata: [
                "feedbackType": AnyCodable(feedbackType),
                "sentiment": AnyCodable(analysis.sentiment.overall.label),
                "actionItemsCount": AnyCodable(analysis.actionItems.count),
                "keyPointsCount": AnyCodable(analysis.keyPoints.count),
                "processingTime": AnyCodable(analysis.metadata.processingTime)
            ])

            return response

        } catch {
            await logger.error("Feedback analysis failed", error: error, category: .general, metadata: [:])
            throw error
        }
    }

    // MARK: - Private Methods

    /// Generate comprehensive feedback analysis
    private func generateFeedbackAnalysis(
        from content: String,
        projectContext: String?,
        feedbackType: String,
        performSentimentAnalysis: Bool,
        extractActionItems: Bool,
        identifyPriorities: Bool,
        summarizeFeedback: Bool,
        useTemplate: Bool,
        templateType: String,
        startTime: Date
    ) async throws -> FeedbackAnalysis {

        let processingTime = Date().timeIntervalSince(startTime)

        // Handle template-based generation if requested
        if useTemplate {
            return try await generateTemplateBasedFeedbackAnalysis(
                from: content,
                projectContext: projectContext,
                feedbackType: feedbackType,
                templateType: templateType,
                performSentimentAnalysis: performSentimentAnalysis,
                extractActionItems: extractActionItems,
                identifyPriorities: identifyPriorities,
                processingTime: processingTime
            )
        }

        // Generate summary if requested
        var summary = ""
        if summarizeFeedback {
            summary = try await generateFeedbackSummary(from: content, feedbackType: feedbackType)
        }

        // Perform sentiment analysis if requested
        var sentiment: SentimentAnalysis
        if performSentimentAnalysis {
            sentiment = try await analyzeSentiment(from: content, feedbackType: feedbackType)
        } else {
            sentiment = SentimentAnalysis(
                overall: SentimentScore(label: "neutral", score: 0.0, magnitude: 0.0),
                emotionalTone: "neutral"
            )
        }

        // Extract key points
        let keyPoints = try await extractKeyPoints(from: content, sentiment: sentiment)

        // Extract action items if requested
        var actionItems: [ActionItem] = []
        if extractActionItems {
            actionItems = try await extractFeedbackActionItems(from: content, feedbackType: feedbackType)
        }

        // Categorize feedback
        let categories = try await categorizeFeedback(from: content, keyPoints: keyPoints)

        // Identify priorities if requested
        var priorities: [PriorityItem] = []
        if identifyPriorities {
            priorities = try await identifyFeedbackPriorities(from: content, actionItems: actionItems)
        }

        // Create metadata
        let metadata = FeedbackMetadata(
            feedbackType: feedbackType,
            projectContext: projectContext,
            wordCount: content.components(separatedBy: " ").count,
            analyzedAt: formatDate(Date()),
            processingTime: processingTime
        )

        // Calculate confidence
        let confidence = calculateAnalysisConfidence(
            content: content,
            sentiment: sentiment,
            hasActionItems: !actionItems.isEmpty,
            hasKeyPoints: !keyPoints.isEmpty
        )

        return FeedbackAnalysis(
            summary: summary,
            sentiment: sentiment,
            keyPoints: keyPoints,
            actionItems: actionItems,
            categories: categories,
            priorities: priorities,
            metadata: metadata,
            confidence: confidence
        )
    }

    /// Generate feedback summary
    private func generateFeedbackSummary(from content: String, feedbackType: String) async throws -> String {
        let sentences = content.components(separatedBy: ".").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        // Extract key sentences based on feedback type
        let keywords = getFeedbackTypeKeywords(feedbackType)
        var summarySentences: [String] = []

        for sentence in sentences.prefix(8) {
            let lowercaseSentence = sentence.lowercased()
            for keyword in keywords {
                if lowercaseSentence.contains(keyword.lowercased()) {
                    summarySentences.append(sentence.trimmingCharacters(in: .whitespacesAndNewlines))
                    break
                }
            }
        }

        // If no specific sentences found, use first few sentences
        if summarySentences.isEmpty {
            summarySentences = Array(sentences.prefix(3))
        }

        return summarySentences.joined(separator: ". ")
    }

    /// Analyze sentiment of feedback
    private func analyzeSentiment(from content: String, feedbackType: String) async throws -> SentimentAnalysis {
        // Overall sentiment analysis
        let overallSentiment = calculateOverallSentiment(from: content)

        // Aspect-based sentiment analysis
        let aspects = try await analyzeAspectSentiment(from: content)

        // Emotional tone analysis
        let emotionalTone = analyzeEmotionalTone(from: content)

        let confidence = calculateSentimentConfidence(content: content, overall: overallSentiment)

        return SentimentAnalysis(
            overall: overallSentiment,
            aspects: aspects,
            emotionalTone: emotionalTone,
            confidence: confidence
        )
    }

    /// Extract key points from feedback
    private func extractKeyPoints(from content: String, sentiment: SentimentAnalysis) async throws -> [KeyPoint] {
        let sentences = content.components(separatedBy: ".").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        var keyPoints: [KeyPoint] = []

        for (index, sentence) in sentences.enumerated() {
            let trimmedSentence = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedSentence.count > 15 { // Only consider meaningful sentences
                let category = categorizeSentence(trimmedSentence)
                let sentimentLabel = getSentenceSentiment(trimmedSentence, overall: sentiment.overall.label)
                let importance = calculateSentenceImportance(trimmedSentence, position: index, total: sentences.count)

                keyPoints.append(KeyPoint(
                    point: trimmedSentence,
                    category: category,
                    sentiment: sentimentLabel,
                    importance: importance
                ))
            }
        }

        // Sort by importance and return top points
        return keyPoints.sorted { $0.importance > $1.importance }.prefix(8).map { $0 }
    }

    /// Extract action items from feedback
    private func extractFeedbackActionItems(from content: String, feedbackType: String) async throws -> [ActionItem] {
        let actionPatterns = [
            "should",
            "need to",
            "consider",
            "try",
            "change",
            "adjust",
            "fix",
            "improve",
            "add",
            "remove",
            "increase",
            "decrease",
            "make",
            "update"
        ]

        var actionItems: [ActionItem] = []
        let sentences = content.components(separatedBy: ".").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        for sentence in sentences {
            let lowercaseSentence = sentence.lowercased()

            for pattern in actionPatterns {
                if lowercaseSentence.contains(pattern) {
                    let actionItem = ActionItem(
                        description: sentence,
                        priority: determineActionPriority(sentence),
                        category: categorizeAction(sentence, feedbackType: feedbackType),
                        context: extractActionContext(sentence),
                        effort: estimateEffort(sentence)
                    )
                    actionItems.append(actionItem)
                    break
                }
            }
        }

        return actionItems
    }

    /// Categorize feedback
    private func categorizeFeedback(from content: String, keyPoints: [KeyPoint]) async throws -> [FeedbackCategory] {
        var categoryGroups: [String: [String]] = [:]

        // Group key points by category
        for keyPoint in keyPoints {
            if categoryGroups[keyPoint.category] == nil {
                categoryGroups[keyPoint.category] = []
            }
            categoryGroups[keyPoint.category]?.append(keyPoint.point)
        }

        // Convert to FeedbackCategory objects
        var categories: [FeedbackCategory] = []
        for (categoryName, examples) in categoryGroups {
            let feedbackCategory = FeedbackCategory(
                name: categoryName,
                count: examples.count,
                examples: Array(examples.prefix(3))
            )
            categories.append(feedbackCategory)
        }

        return categories.sorted { $0.count > $1.count }
    }

    /// Identify feedback priorities
    private func identifyFeedbackPriorities(from content: String, actionItems: [ActionItem]) async throws -> [PriorityItem] {
        var priorities: [PriorityItem] = []

        // Prioritize action items
        for actionItem in actionItems {
            let rationale = determinePriorityRationale(actionItem)
            let priorityItem = PriorityItem(
                item: actionItem.description,
                priority: actionItem.priority,
                rationale: rationale
            )
            priorities.append(priorityItem)
        }

        // Add high-impact feedback points that might not be action items
        let highImpactKeywords = ["critical", "major", "significant", "important", "urgent"]
        let sentences = content.components(separatedBy: ".").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        for sentence in sentences {
            let lowercaseSentence = sentence.lowercased()
            for keyword in highImpactKeywords {
                if lowercaseSentence.contains(keyword) && !priorities.contains(where: { $0.item == sentence }) {
                    let priorityItem = PriorityItem(
                        item: sentence,
                        priority: "high",
                        rationale: "Contains priority keyword: \(keyword)"
                    )
                    priorities.append(priorityItem)
                    break
                }
            }
        }

        return priorities.sorted { priority1, priority2 in
            let priorityOrder = ["high", "medium", "low"]
            let index1 = priorityOrder.firstIndex(of: priority1.priority) ?? priorityOrder.count
            let index2 = priorityOrder.firstIndex(of: priority2.priority) ?? priorityOrder.count
            return index1 < index2
        }
    }

    // MARK: - Helper Methods

    private func getFeedbackTypeKeywords(_ feedbackType: String) -> [String] {
        switch feedbackType.lowercased() {
        case "mix":
            return ["mix", "balance", "levels", "eq", "compression", "reverb", "pan", "stereo"]
        case "master":
            return ["master", "loudness", "limiting", "final", "eq", "overall", "commercial"]
        case "production":
            return ["arrangement", "structure", "songwriting", "composition", "instrumentation", "feel"]
        case "technical":
            return ["technical", "quality", "issue", "problem", "fix", "equipment", "gear"]
        case "creative":
            return ["creative", "artistic", "direction", "vision", "feel", "emotion", "vibe"]
        default:
            return ["feedback", "notes", "comments", "suggestions", "review"]
        }
    }

    private func calculateOverallSentiment(from content: String) -> SentimentScore {
        let positiveWords = [
            "great", "excellent", "amazing", "love", "perfect", "good", "nice", "well",
            "fantastic", "wonderful", "brilliant", "outstanding", "impressive", "solid"
        ]

        let negativeWords = [
            "bad", "terrible", "awful", "hate", "worst", "poor", "weak", "problem",
            "issue", "wrong", "fix", "change", "disappoint", "struggle", "difficult"
        ]

        let words = content.lowercased().components(separatedBy: .whitespacesAndNewlines)
        var positiveCount = 0
        var negativeCount = 0

        for word in words {
            if positiveWords.contains(word) {
                positiveCount += 1
            } else if negativeWords.contains(word) {
                negativeCount += 1
            }
        }

        let totalSentimentWords = positiveCount + negativeCount
        let score = totalSentimentWords > 0 ? Double(positiveCount - negativeCount) / Double(totalSentimentWords) : 0.0
        let magnitude = Double(totalSentimentWords) / Double(words.count)

        let label: String
        if score > 0.1 {
            label = "positive"
        } else if score < -0.1 {
            label = "negative"
        } else {
            label = "neutral"
        }

        return SentimentScore(label: label, score: score, magnitude: magnitude)
    }

    private func analyzeAspectSentiment(from content: String) async throws -> [AspectSentiment] {
        let aspects = ["mix", "vocals", "instruments", "bass", "drums", "production", "arrangement", "sound quality"]
        var aspectSentiments: [AspectSentiment] = []

        for aspect in aspects {
            let aspectKeywords = [aspect, "\(aspect)s", aspect.replacingOccurrences(of: " ", with: "")]
            let sentences = content.components(separatedBy: ".").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

            for sentence in sentences {
                let lowercaseSentence = sentence.lowercased()
                for keyword in aspectKeywords {
                    if lowercaseSentence.contains(keyword) {
                        let sentiment = calculateSentenceSentiment(sentence)
                        let aspectSentiment = AspectSentiment(
                            aspect: aspect,
                            sentiment: sentiment,
                            mention: sentence.trimmingCharacters(in: .whitespacesAndNewlines)
                        )
                        aspectSentiments.append(aspectSentiment)
                        break
                    }
                }
            }
        }

        return aspectSentiments
    }

    private func calculateSentenceSentiment(_ sentence: String) -> SentimentScore {
        return calculateOverallSentiment(from: sentence)
    }

    private func analyzeEmotionalTone(from content: String) -> String {
        let emotionalKeywords = [
            ("excited", ["excited", "thrilled", "energetic", "enthusiastic"]),
            ("concerned", ["concerned", "worried", "anxious", "troubled"]),
            ("frustrated", ["frustrated", "annoyed", "disappointed", "upset"]),
            ("pleased", ["pleased", "satisfied", "happy", "content"]),
            ("confused", ["confused", "unclear", "unsure", "puzzled"]),
            ("urgent", ["urgent", "immediate", "critical", "asap"])
        ]

        let lowercaseContent = content.lowercased()
        var toneScores: [String: Int] = [:]

        for (tone, keywords) in emotionalKeywords {
            var count = 0
            for keyword in keywords {
                count += lowercaseContent.components(separatedBy: keyword).count - 1
            }
            if count > 0 {
                toneScores[tone] = count
            }
        }

        if let highestScoringTone = toneScores.max(by: { $0.value < $1.value })?.key {
            return highestScoringTone
        }

        return "neutral"
    }

    private func calculateSentimentConfidence(content: String, overall: SentimentScore) -> Double {
        var confidence = 0.5

        let wordCount = content.components(separatedBy: " ").count
        if wordCount > 50 {
            confidence += 0.2
        }
        if wordCount > 100 {
            confidence += 0.1
        }

        confidence += min(overall.magnitude * 2, 0.2)

        return min(confidence, 1.0)
    }

    private func categorizeSentence(_ sentence: String) -> String {
        let categories = [
            ("technical", ["eq", "compression", "reverb", "delay", "mix", "master", "levels", "technical"]),
            ("creative", ["feel", "vibe", "emotion", "creative", "artistic", "direction", "vision"]),
            ("performance", ["performance", "playing", "singing", "instrument", "timing", "rhythm"]),
            ("production", ["arrangement", "structure", "songwriting", "composition", "production"]),
            ("general", ["feedback", "notes", "comments", "suggestions", "overall"])
        ]

        let lowercaseSentence = sentence.lowercased()

        for (category, keywords) in categories {
            for keyword in keywords {
                if lowercaseSentence.contains(keyword) {
                    return category
                }
            }
        }

        return "general"
    }

    private func getSentenceSentiment(_ sentence: String, overall: String) -> String {
        let sentenceSentiment = calculateOverallSentiment(from: sentence)
        return sentenceSentiment.label.isEmpty ? overall : sentenceSentiment.label
    }

    private func calculateSentenceImportance(_ sentence: String, position: Int, total: Int) -> Int {
        var importance = 1

        // Earlier sentences are often more important
        if position < total / 3 {
            importance += 2
        } else if position < 2 * total / 3 {
            importance += 1
        }

        // Longer sentences might be more important
        if sentence.count > 50 {
            importance += 1
        }

        // Sentences with specific audio terms are important
        let audioTerms = ["eq", "compressor", "reverb", "delay", "mix", "master", "vocals", "bass", "drums"]
        let lowercaseSentence = sentence.lowercased()
        for term in audioTerms {
            if lowercaseSentence.contains(term) {
                importance += 1
                break
            }
        }

        return importance
    }

    private func determineActionPriority(_ sentence: String) -> String {
        let lowercaseSentence = sentence.lowercased()

        if lowercaseSentence.contains("urgent") || lowercaseSentence.contains("critical") || lowercaseSentence.contains("immediately") {
            return "high"
        } else if lowercaseSentence.contains("might") || lowercaseSentence.contains("consider") || lowercaseSentence.contains("could") {
            return "low"
        } else {
            return "medium"
        }
    }

    private func categorizeAction(_ sentence: String, feedbackType: String) -> String {
        let categories = [
            ("mix", ["levels", "balance", "eq", "compression", "reverb", "pan"]),
            ("master", ["loudness", "limiting", "final", "overall", "commercial"]),
            ("production", ["arrangement", "structure", "instrumentation", "songwriting"]),
            ("technical", ["fix", "issue", "problem", "technical", "quality"]),
            ("creative", ["feel", "vibe", "emotion", "direction", "artistic"])
        ]

        let lowercaseSentence = sentence.lowercased()

        for (category, keywords) in categories {
            for keyword in keywords {
                if lowercaseSentence.contains(keyword) {
                    return category
                }
            }
        }

        return "general"
    }

    private func extractActionContext(_ sentence: String) -> String {
        let words = sentence.components(separatedBy: " ")
        if words.count > 3 {
            return Array(words.prefix(6)).joined(separator: " ")
        }
        return sentence
    }

    private func estimateEffort(_ sentence: String) -> String? {
        let lowercaseSentence = sentence.lowercased()

        if lowercaseSentence.contains("small") || lowercaseSentence.contains("minor") || lowercaseSentence.contains("quick") {
            return "low"
        } else if lowercaseSentence.contains("major") || lowercaseSentence.contains("significant") || lowercaseSentence.contains("complete") {
            return "high"
        } else if lowercaseSentence.contains("rework") || lowercaseSentence.contains("rewrite") || lowercaseSentence.contains("start over") {
            return "very high"
        }

        return "medium"
    }

    private func determinePriorityRationale(_ actionItem: ActionItem) -> String {
        switch actionItem.priority {
        case "high":
            return actionItem.effort == "low" ? "Quick win with high impact" : "Critical client requirement"
        case "medium":
            return "Important improvement that enhances quality"
        case "low":
            return "Nice to have but not essential"
        default:
            return "Standard priority action item"
        }
    }

    private func calculateAnalysisConfidence(
        content: String,
        sentiment: SentimentAnalysis,
        hasActionItems: Bool,
        hasKeyPoints: Bool
    ) -> Double {
        var confidence = 0.5

        if content.count > 100 {
            confidence += 0.1
        }

        if sentiment.confidence > 0.7 {
            confidence += 0.1
        }

        if hasActionItems {
            confidence += 0.1
        }

        if hasKeyPoints {
            confidence += 0.1
        }

        confidence += min(sentiment.overall.magnitude, 0.1)

        return min(confidence, 1.0)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    /// Generate template-based feedback analysis using engineering templates
    private func generateTemplateBasedFeedbackAnalysis(
        from content: String,
        projectContext: String?,
        feedbackType: String,
        templateType: String,
        performSentimentAnalysis: Bool,
        extractActionItems: Bool,
        identifyPriorities: Bool,
        processingTime: Double
    ) async throws -> FeedbackAnalysis {

        // Get the appropriate template
        let template: String
        switch templateType.lowercased() {
        case "client_feedback":
            template = EngineeringTemplates.clientFeedbackTemplate()
        case "internal_review":
            template = EngineeringTemplates.internalReviewTemplate()
        default:
            template = EngineeringTemplates.clientFeedbackTemplate()
        }

        // Extract template values from content
        let templateValues = extractFeedbackTemplateValues(from: content, templateType: templateType, feedbackType: feedbackType)

        // Populate template with extracted values
        let populatedTemplate = EngineeringTemplates.populateTemplate(template, with: templateValues)

        // Generate summary from populated template
        let summary = generateFeedbackSummaryFromTemplate(populatedTemplate, templateType: templateType)

        // Perform sentiment analysis if requested
        var sentiment: SentimentAnalysis
        if performSentimentAnalysis {
            sentiment = try await analyzeSentiment(from: content, feedbackType: feedbackType)
        } else {
            sentiment = SentimentAnalysis(
                overall: SentimentScore(label: "neutral", score: 0.0, magnitude: 0.0),
                emotionalTone: "neutral"
            )
        }

        // Extract key points from template
        let keyPoints = extractKeyPointsFromFeedbackTemplate(populatedTemplate, sentiment: sentiment)

        // Extract action items if requested
        var actionItems: [ActionItem] = []
        if extractActionItems {
            actionItems = extractActionItemsFromFeedbackTemplate(populatedTemplate, feedbackType: feedbackType)
        }

        // Categorize feedback from template
        let categories = categorizeFeedbackFromTemplate(populatedTemplate, keyPoints: keyPoints)

        // Identify priorities if requested
        var priorities: [PriorityItem] = []
        if identifyPriorities {
            priorities = identifyFeedbackPrioritiesFromTemplate(populatedTemplate, actionItems: actionItems)
        }

        // Create metadata
        let metadata = FeedbackMetadata(
            feedbackType: feedbackType,
            projectContext: projectContext,
            wordCount: content.components(separatedBy: " ").count,
            analyzedAt: formatDate(Date()),
            processingTime: processingTime
        )

        // Calculate confidence
        let confidence = calculateTemplateFeedbackConfidence(
            template: populatedTemplate,
            originalContent: content,
            sentiment: sentiment,
            hasActionItems: !actionItems.isEmpty,
            hasKeyPoints: !keyPoints.isEmpty
        )

        return FeedbackAnalysis(
            summary: summary,
            sentiment: sentiment,
            keyPoints: keyPoints,
            actionItems: actionItems,
            categories: categories,
            priorities: priorities,
            metadata: metadata,
            confidence: confidence
        )
    }

    /// Extract template values for feedback analysis
    private func extractFeedbackTemplateValues(from content: String, templateType: String, feedbackType: String) -> [String: String] {
        var values: [String: String] = [:]

        // Add date
        values["review_date"] = formatDate(Date())

        // Extract project information
        let projectName = extractProjectNameFromFeedback(content)
        if !projectName.isEmpty {
            values["project"] = projectName
        }

        values["review_type"] = feedbackType

        // Extract sentiment information
        let overallSentiment = calculateOverallSentiment(from: content)
        values["overall_sentiment"] = overallSentiment.label
        values["key_response"] = generateKeyResponseFromSentiment(overallSentiment)

        // Extract feedback-specific information based on type
        switch templateType.lowercased() {
        case "client_feedback":
            values["mix_balance_feedback"] = extractFeedbackSection(from: content, keywords: ["mix", "balance", "levels"])
            values["tonal_feedback"] = extractFeedbackSection(from: content, keywords: ["tone", "tonal", "eq", "frequency"])
            values["dynamics_feedback"] = extractFeedbackSection(from: content, keywords: ["dynamics", "compression", "volume"])
            values["creative_feedback"] = extractFeedbackSection(from: content, keywords: ["creative", "feel", "vibe", "emotion"])
            values["technical_feedback"] = extractFeedbackSection(from: content, keywords: ["technical", "quality", "issue", "problem"])
            values["client_preferences"] = extractPreferencesFromFeedback(content)
            values["deadlines"] = extractDeadlinesFromFeedback(content)

        case "internal_review":
            values["vocals_clarity"] = extractClarityFeedback(from: content, aspect: "vocals")
            values["instruments_clarity"] = extractClarityFeedback(from: content, aspect: "instruments")
            values["separation_quality"] = extractClarityFeedback(from: content, aspect: "separation")
            values["level_balance"] = extractBalanceFeedback(from: content)
            values["freq_balance"] = extractFrequencyBalanceFeedback(from: content)
            values["stereo_image"] = extractStereoFeedback(from: content)
            values["compression_assessment"] = extractProcessingFeedback(from: content, processing: "compression")
            values["limiting_assessment"] = extractProcessingFeedback(from: content, processing: "limiting")
            values["emotional_impact"] = extractImpactFeedback(from: content, impact: "emotional")
            values["energy_level"] = extractImpactFeedback(from: content, impact: "energy")
            values["commercial_viability"] = extractImpactFeedback(from: content, impact: "commercial")

        default:
            break
        }

        // Extract common feedback elements
        values["priority_items"] = extractPriorityItemsFromFeedback(content)
        values["next_steps"] = extractNextStepsFromFeedback(content)

        return values
    }

    /// Generate feedback summary from populated template
    private func generateFeedbackSummaryFromTemplate(_ template: String, templateType: String) -> String {
        let lines = template.components(separatedBy: "\n")
        var summaryLines: [String] = []

        // Extract meaningful lines for summary
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
            if trimmedLine.count > 10 && !summaryLines.contains(trimmedLine) {
                summaryLines.append(trimmedLine)
            }
        }

        // Take first few meaningful lines as summary
        let summaryText = Array(summaryLines.prefix(4)).joined(separator: ". ")
        return summaryText.isEmpty ? "Template-based feedback analysis generated for \(templateType)" : summaryText
    }

    /// Extract key points from feedback template
    private func extractKeyPointsFromFeedbackTemplate(_ template: String, sentiment: SentimentAnalysis) -> [KeyPoint] {
        var keyPoints: [KeyPoint] = []
        let lines = template.components(separatedBy: "\n")

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
            if trimmedLine.count > 15 {
                let category = categorizeFeedbackSentence(trimmedLine)
                let sentimentLabel = getSentenceSentiment(trimmedLine, overall: sentiment.overall.label)
                let importance = calculateFeedbackSentenceImportance(trimmedLine)

                keyPoints.append(KeyPoint(
                    point: trimmedLine,
                    category: category,
                    sentiment: sentimentLabel,
                    importance: importance
                ))
            }
        }

        // Sort by importance and return top points
        return keyPoints.sorted { $0.importance > $1.importance }.prefix(8).map { $0 }
    }

    /// Extract action items from feedback template
    private func extractActionItemsFromFeedbackTemplate(_ template: String, feedbackType: String) -> [ActionItem] {
        let actionPatterns = [
            "should", "need to", "consider", "try", "change", "adjust", "fix", "improve",
            "add", "remove", "increase", "decrease", "make", "update", "enhance"
        ]

        var actionItems: [ActionItem] = []
        let sentences = template.components(separatedBy: ".").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        for sentence in sentences {
            let lowercaseSentence = sentence.lowercased()

            for pattern in actionPatterns {
                if lowercaseSentence.contains(pattern) {
                    let actionItem = ActionItem(
                        description: sentence,
                        priority: determineFeedbackActionPriority(sentence),
                        category: categorizeFeedbackAction(sentence, feedbackType: feedbackType),
                        context: extractFeedbackActionContext(sentence),
                        effort: estimateFeedbackActionEffort(sentence)
                    )
                    actionItems.append(actionItem)
                    break
                }
            }
        }

        return actionItems
    }

    // Helper methods for template-based feedback analysis
    private func extractProjectNameFromFeedback(_ content: String) -> String {
        let patterns = ["project:", "song:", "track:", "mix:", "master:"]
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

    private func generateKeyResponseFromSentiment(_ sentiment: SentimentScore) -> String {
        switch sentiment.label {
        case "positive":
            return "Client is satisfied with the work"
        case "negative":
            return "Client has significant concerns that need addressing"
        case "neutral":
            return "Client has mixed feelings or needs minor adjustments"
        default:
            return "Client feedback requires further clarification"
        }
    }

    private func extractFeedbackSection(from content: String, keywords: [String]) -> String {
        let sentences = content.components(separatedBy: ".").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        var feedbackItems: [String] = []
        for sentence in sentences {
            let lowercaseSentence = sentence.lowercased()
            for keyword in keywords {
                if lowercaseSentence.contains(keyword) {
                    feedbackItems.append(sentence)
                    break
                }
            }
        }

        return feedbackItems.joined(separator: "\n")
    }

    private func extractPreferencesFromFeedback(_ content: String) -> String {
        let preferenceKeywords = ["prefer", "like", "want", "prefer", "would like", "preference"]
        let sentences = content.components(separatedBy: ".").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        var preferences: [String] = []
        for sentence in sentences {
            let lowercaseSentence = sentence.lowercased()
            for keyword in preferenceKeywords {
                if lowercaseSentence.contains(keyword) {
                    preferences.append(sentence)
                    break
                }
            }
        }

        return preferences.joined(separator: "\n")
    }

    private func extractDeadlinesFromFeedback(_ content: String) -> String {
        let deadlineKeywords = ["deadline", "due", "by", "before", "when", "asap", "urgent"]
        let sentences = content.components(separatedBy: ".").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        var deadlines: [String] = []
        for sentence in sentences {
            let lowercaseSentence = sentence.lowercased()
            for keyword in deadlineKeywords {
                if lowercaseSentence.contains(keyword) {
                    deadlines.append(sentence)
                    break
                }
            }
        }

        return deadlines.joined(separator: "\n")
    }

    private func extractClarityFeedback(from content: String, aspect: String) -> String {
        let clarityKeywords = ["clear", "unclear", "muddy", "defined", "sharp", "focused"]
        let sentences = content.components(separatedBy: ".").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        var clarityFeedback: [String] = []
        for sentence in sentences {
            let lowercaseSentence = sentence.lowercased()
            if lowercaseSentence.contains(aspect.lowercased()) {
                for keyword in clarityKeywords {
                    if lowercaseSentence.contains(keyword) {
                        clarityFeedback.append(sentence)
                        break
                    }
                }
            }
        }

        return clarityFeedback.joined(separator: "\n")
    }

    private func extractBalanceFeedback(from content: String) -> String {
        return extractFeedbackSection(from: content, keywords: ["balance", "levels", "loud", "quiet"])
    }

    private func extractFrequencyBalanceFeedback(from content: String) -> String {
        return extractFeedbackSection(from: content, keywords: ["frequency", "bass", "treble", "mids", "eq"])
    }

    private func extractStereoFeedback(from content: String) -> String {
        return extractFeedbackSection(from: content, keywords: ["stereo", "mono", "wide", "narrow", "pan"])
    }

    private func extractProcessingFeedback(from content: String, processing: String) -> String {
        return extractFeedbackSection(from: content, keywords: [processing, "over", "under", "too much", "not enough"])
    }

    private func extractImpactFeedback(from content: String, impact: String) -> String {
        let impactKeywords = ["impact", "effect", "result", "outcome"]
        let sentences = content.components(separatedBy: ".").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        var impactFeedback: [String] = []
        for sentence in sentences {
            let lowercaseSentence = sentence.lowercased()
            if lowercaseSentence.contains(impact.lowercased()) {
                for keyword in impactKeywords {
                    if lowercaseSentence.contains(keyword) {
                        impactFeedback.append(sentence)
                        break
                    }
                }
            }
        }

        return impactFeedback.joined(separator: "\n")
    }

    private func extractPriorityItemsFromFeedback(_ content: String) -> String {
        let priorityKeywords = ["important", "critical", "urgent", "priority", "focus", "key"]
        return extractFeedbackSection(from: content, keywords: priorityKeywords)
    }

    private func extractNextStepsFromFeedback(_ content: String) -> String {
        let nextStepKeywords = ["next", "follow", "continue", "proceed", "upcoming"]
        return extractFeedbackSection(from: content, keywords: nextStepKeywords)
    }

    private func categorizeFeedbackFromTemplate(_ template: String, keyPoints: [KeyPoint]) -> [FeedbackCategory] {
        var categoryGroups: [String: [String]] = [:]

        // Group key points by category
        for keyPoint in keyPoints {
            if categoryGroups[keyPoint.category] == nil {
                categoryGroups[keyPoint.category] = []
            }
            categoryGroups[keyPoint.category]?.append(keyPoint.point)
        }

        // Convert to FeedbackCategory objects
        var categories: [FeedbackCategory] = []
        for (categoryName, examples) in categoryGroups {
            let feedbackCategory = FeedbackCategory(
                name: categoryName,
                count: examples.count,
                examples: Array(examples.prefix(3))
            )
            categories.append(feedbackCategory)
        }

        return categories.sorted { $0.count > $1.count }
    }

    private func identifyFeedbackPrioritiesFromTemplate(_ template: String, actionItems: [ActionItem]) -> [PriorityItem] {
        var priorities: [PriorityItem] = []

        // Prioritize action items
        for actionItem in actionItems {
            let rationale = determineFeedbackPriorityRationale(actionItem)
            let priorityItem = PriorityItem(
                item: actionItem.description,
                priority: actionItem.priority,
                rationale: rationale
            )
            priorities.append(priorityItem)
        }

        // Add high-impact feedback points that might not be action items
        let highImpactKeywords = ["critical", "major", "significant", "important", "urgent"]
        let sentences = template.components(separatedBy: ".").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        for sentence in sentences {
            let lowercaseSentence = sentence.lowercased()
            for keyword in highImpactKeywords {
                if lowercaseSentence.contains(keyword) && !priorities.contains(where: { $0.item == sentence }) {
                    let priorityItem = PriorityItem(
                        item: sentence,
                        priority: "high",
                        rationale: "Contains priority keyword: \(keyword)"
                    )
                    priorities.append(priorityItem)
                    break
                }
            }
        }

        return priorities.sorted { priority1, priority2 in
            let priorityOrder = ["high", "medium", "low"]
            let index1 = priorityOrder.firstIndex(of: priority1.priority) ?? priorityOrder.count
            let index2 = priorityOrder.firstIndex(of: priority2.priority) ?? priorityOrder.count
            return index1 < index2
        }
    }

    private func categorizeFeedbackSentence(_ sentence: String) -> String {
        let categories = [
            ("technical", ["eq", "compression", "reverb", "delay", "mix", "master", "levels", "technical"]),
            ("creative", ["feel", "vibe", "emotion", "creative", "artistic", "direction", "vision"]),
            ("performance", ["performance", "playing", "singing", "instrument", "timing", "rhythm"]),
            ("production", ["arrangement", "structure", "songwriting", "composition", "production"]),
            ("general", ["feedback", "notes", "comments", "suggestions", "overall"])
        ]

        let lowercaseSentence = sentence.lowercased()

        for (category, keywords) in categories {
            for keyword in keywords {
                if lowercaseSentence.contains(keyword) {
                    return category
                }
            }
        }

        return "general"
    }

    private func calculateFeedbackSentenceImportance(_ sentence: String) -> Int {
        var importance = 1

        // Sentences with specific audio terms are important
        let audioTerms = ["eq", "compressor", "reverb", "delay", "mix", "master", "vocals", "bass", "drums"]
        let lowercaseSentence = sentence.lowercased()
        for term in audioTerms {
            if lowercaseSentence.contains(term) {
                importance += 1
                break
            }
        }

        // Sentences with priority keywords are more important
        let priorityKeywords = ["important", "critical", "major", "significant", "urgent"]
        for keyword in priorityKeywords {
            if lowercaseSentence.contains(keyword) {
                importance += 2
                break
            }
        }

        return importance
    }

    private func determineFeedbackActionPriority(_ sentence: String) -> String {
        let lowercaseSentence = sentence.lowercased()

        if lowercaseSentence.contains("urgent") || lowercaseSentence.contains("critical") || lowercaseSentence.contains("immediately") {
            return "high"
        } else if lowercaseSentence.contains("might") || lowercaseSentence.contains("consider") || lowercaseSentence.contains("could") {
            return "low"
        } else {
            return "medium"
        }
    }

    private func categorizeFeedbackAction(_ sentence: String, feedbackType: String) -> String {
        let categories = [
            ("mix", ["levels", "balance", "eq", "compression", "reverb", "pan"]),
            ("master", ["loudness", "limiting", "final", "overall", "commercial"]),
            ("production", ["arrangement", "structure", "instrumentation", "songwriting"]),
            ("technical", ["fix", "issue", "problem", "technical", "quality"]),
            ("creative", ["feel", "vibe", "emotion", "direction", "artistic"])
        ]

        let lowercaseSentence = sentence.lowercased()

        for (category, keywords) in categories {
            for keyword in keywords {
                if lowercaseSentence.contains(keyword) {
                    return category
                }
            }
        }

        return "general"
    }

    private func extractFeedbackActionContext(_ sentence: String) -> String {
        let words = sentence.components(separatedBy: " ")
        if words.count > 3 {
            return Array(words.prefix(6)).joined(separator: " ")
        }
        return sentence
    }

    private func estimateFeedbackActionEffort(_ sentence: String) -> String? {
        let lowercaseSentence = sentence.lowercased()

        if lowercaseSentence.contains("small") || lowercaseSentence.contains("minor") || lowercaseSentence.contains("quick") {
            return "low"
        } else if lowercaseSentence.contains("major") || lowercaseSentence.contains("significant") || lowercaseSentence.contains("complete") {
            return "high"
        } else if lowercaseSentence.contains("rework") || lowercaseSentence.contains("rewrite") || lowercaseSentence.contains("start over") {
            return "very high"
        }

        return "medium"
    }

    private func determineFeedbackPriorityRationale(_ actionItem: ActionItem) -> String {
        switch actionItem.priority {
        case "high":
            return actionItem.effort == "low" ? "Quick win with high impact" : "Critical client requirement"
        case "medium":
            return "Important improvement that enhances quality"
        case "low":
            return "Nice to have but not essential"
        default:
            return "Standard priority action item"
        }
    }

    private func calculateTemplateFeedbackConfidence(
        template: String,
        originalContent: String,
        sentiment: SentimentAnalysis,
        hasActionItems: Bool,
        hasKeyPoints: Bool
    ) -> Double {
        var confidence = 0.6 // Base confidence for template generation

        // Check how well template was populated
        let unfilledPlaceholders = template.components(separatedBy: "{").count - 1
        let totalPlaceholders = template.components(separatedBy: "}").count - 1

        if totalPlaceholders > 0 {
            let fillRatio = Double(totalPlaceholders - unfilledPlaceholders) / Double(totalPlaceholders)
            confidence += fillRatio * 0.2
        }

        // Content quality factors
        if originalContent.count > 50 {
            confidence += 0.05
        }

        if originalContent.count > 200 {
            confidence += 0.05
        }

        // Sentiment analysis bonus
        if sentiment.confidence > 0.7 {
            confidence += 0.1
        }

        // Action items bonus
        if hasActionItems {
            confidence += 0.1
        }

        // Key points bonus
        if hasKeyPoints {
            confidence += 0.1
        }

        return min(confidence, 1.0)
    }

    /// Encode result as JSON string
    private func encodeJSON(_ result: FeedbackAnalysis) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data = try encoder.encode(result)
        return String(data: data, encoding: .utf8) ?? "{}"
    }
}