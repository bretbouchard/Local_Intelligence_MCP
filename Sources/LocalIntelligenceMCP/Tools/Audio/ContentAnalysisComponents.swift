//
//  ContentAnalysisComponents.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-09.
//

import Foundation

/// Extracts entities from content
public class ContentEntityExtractor {

    // MARK: - Entity Extraction

    /// Extracts entities from content
    /// - Parameter content: Content to analyze
    /// - Returns: Array of content entities
    public func extractEntities(content: String) -> [ContentEntity] {
        var entities: [ContentEntity] = []

        // Entity extraction patterns
        let patterns: [(EntityType, String)] = [
            (.person, #"([A-Z][a-z]+\s+[A-Z][a-z]+)"#),
            (.money, #"(\$\d+(?:,\d{3})*(?:\.\d{2})?|\d+\s*dollars?)"#),
            (.date, #"(\d{1,2}/\d{1,2}/\d{4}|\d{4}-\d{2}-\d{2}|\w+\s+\d{1,2},?\s+\d{4})"#),
            (.time, #"(\d{1,2}:\d{2}\s*(?:am|pm|AM|PM)?|\d+\s*(?:am|pm|AM|PM))"#),
            (.project, #"([A-Z][a-zA-Z\s]*(?:Project|Album|Track|Song))"#),
            (.organization, #"([A-Z][a-z]+(?:\s+(?:Studios|Records|Media|Audio|Production)))"#)
        ]

        for (type, pattern) in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { continue }

            let matches = regex.matches(in: content, range: NSRange(content.startIndex..<content.endIndex, in: content))

            for match in matches {
                if let range = Range(match.range, in: content) {
                    let entityText = String(content[range])
                    entities.append(ContentEntity(
                        text: entityText,
                        type: type,
                        confidence: calculateEntityConfidence(entity: entityText, type: type)
                    ))
                }
            }
        }

        // Extract technical terms
        let technicalTerms = extractTechnicalTerms(content: content)
        entities.append(contentsOf: technicalTerms)

        // Extract action items as entities
        let actionItems = extractActionItemEntities(content: content)
        entities.append(contentsOf: actionItems)

        // Remove duplicates and sort by confidence
        entities = removeDuplicateEntities(entities)
        entities.sort { $0.confidence > $1.confidence }

        return entities
    }

    /// Provides detailed entity analysis
    /// - Parameter content: Content to analyze
    /// - Returns: Detailed entity analysis
    public func getDetailedEntityAnalysis(content: String) -> DetailedEntityAnalysis {
        let entities = extractEntities(content: content)

        // Group entities by type
        let entitiesByType = Dictionary(grouping: entities) { $0.type }

        // Calculate entity statistics
        let totalEntities = entities.count
        let uniqueEntityTypes = Set(entities.map { $0.type })
        let averageConfidence = entities.isEmpty ? 0.0 : entities.reduce(0.0) { $0 + $1.confidence } / Double(entities.count)

        // Identify entity relationships
        let entityRelationships = identifyEntityRelationships(entities: entities)

        // Generate entity insights
        let insights = generateEntityInsights(
            entities: entities,
            entitiesByType: entitiesByType,
            relationships: entityRelationships
        )

        return DetailedEntityAnalysis(
            entities: entities,
            entitiesByType: entitiesByType,
            totalEntities: totalEntities,
            uniqueTypes: uniqueEntityTypes.count,
            averageConfidence: averageConfidence,
            entityRelationships: entityRelationships,
            insights: insights
        )
    }

    // MARK: - Private Helper Methods

    /// Extracts technical terms as entities
    /// - Parameter content: Content to analyze
    /// - Returns: Array of technical term entities
    private func extractTechnicalTerms(content: String) -> [ContentEntity] {
        let technicalTerms = [
            "frequency", "spectrum", "compression", "eq", "equalization",
            "threshold", "ratio", "attack", "release", "makeup gain",
            "khz", "hz", "db", "decibel", "bit depth", "sample rate",
            "latency", "buffer", "driver", "interface", "preamp",
            "reverb", "delay", "chorus", "flanger", "phaser",
            "automation", "plugin", "vst", "au", "aax"
        ]

        let lowercaseContent = content.lowercased()
        var technicalEntities: [ContentEntity] = []

        for term in technicalTerms {
            if lowercaseContent.contains(term) {
                technicalEntities.append(ContentEntity(
                    text: term,
                    type: .technicalTerm,
                    confidence: 0.9
                ))
            }
        }

        return technicalEntities
    }

    /// Extracts action item entities
    /// - Parameter content: Content to analyze
    /// - Returns: Array of action item entities
    private func extractActionItemEntities(content: String) -> [ContentEntity] {
        let actionIndicators = ["need to", "should", "must", "will", "plan to"]
        let sentences = content.components(separatedBy: CharacterSet(charactersIn: ".!?"))

        var actionEntities: [ContentEntity] = []

        for sentence in sentences {
            let trimmedSentence = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedSentence.isEmpty else { continue }

            let lowercaseSentence = trimmedSentence.lowercased()
            if actionIndicators.contains(where: lowercaseSentence.contains) {
                actionEntities.append(ContentEntity(
                    text: trimmedSentence,
                    type: .actionItem,
                    confidence: 0.8
                ))
            }
        }

        return actionEntities
    }

    /// Calculates confidence score for an entity
    /// - Parameters:
    ///   - entity: Entity text
    ///   - type: Entity type
    /// - Returns: Confidence score (0.0-1.0)
    private func calculateEntityConfidence(entity: String, type: EntityType) -> Double {
        // Base confidence by entity type
        let baseConfidence: Double
        switch type {
        case .person: baseConfidence = 0.7
        case .money: baseConfidence = 0.9
        case .date: baseConfidence = 0.8
        case .time: baseConfidence = 0.8
        case .project: baseConfidence = 0.6
        case .organization: baseConfidence = 0.7
        case .technicalTerm: baseConfidence = 0.9
        case .actionItem: baseConfidence = 0.8
        default: baseConfidence = 0.5
        }

        // Adjust confidence based on entity characteristics
        let lengthScore = min(Double(entity.count) / 10.0, 1.0)
        let formatScore = hasValidFormat(entity: entity, type: type) ? 0.2 : 0.0

        return min(baseConfidence + lengthScore * 0.1 + formatScore, 1.0)
    }

    /// Checks if entity has valid format for its type
    /// - Parameters:
    ///   - entity: Entity text
    ///   - type: Entity type
    /// - Returns: True if format is valid
    private func hasValidFormat(entity: String, type: EntityType) -> Bool {
        switch type {
        case .money:
            return entity.hasPrefix("$") || entity.lowercased().contains("dollar")
        case .date:
            return entity.contains("/") || entity.contains("-") || entity.lowercased().contains("jan")
        case .time:
            return entity.contains(":") || entity.lowercased().contains("am") || entity.lowercased().contains("pm")
        case .person:
            return entity.components(separatedBy: " ").count >= 2
        default:
            return true
        }
    }

    /// Removes duplicate entities
    /// - Parameter entities: Array of entities
    /// - Returns: Array of unique entities
    private func removeDuplicateEntities(_ entities: [ContentEntity]) -> [ContentEntity] {
        var uniqueEntities: [ContentEntity] = []
        var seenTexts: Set<String> = []

        for entity in entities {
            let normalizedText = entity.text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            if !seenTexts.contains(normalizedText) {
                seenTexts.insert(normalizedText)
                uniqueEntities.append(entity)
            }
        }

        return uniqueEntities
    }

    /// Identifies relationships between entities
    /// - Parameter entities: Array of entities
    /// - Returns: Array of entity relationships
    private func identifyEntityRelationships(entities: [ContentEntity]) -> [EntityRelationship] {
        var relationships: [EntityRelationship] = []

        // Simple proximity-based relationship detection
        for i in 0..<entities.count {
            for j in (i+1)..<entities.count {
                let entity1 = entities[i]
                let entity2 = entities[j]

                // Check if entities are related based on type
                let relationshipType = determineRelationshipType(entity1: entity1, entity2: entity2)
                if relationshipType != nil {
                    relationships.append(EntityRelationship(
                        entity1: entity1,
                        entity2: entity2,
                        type: relationshipType!,
                        confidence: 0.6
                    ))
                }
            }
        }

        return relationships
    }

    /// Determines relationship type between two entities
    /// - Parameters:
    ///   - entity1: First entity
    ///   - entity2: Second entity
    /// - Returns: Relationship type if applicable
    private func determineRelationshipType(entity1: ContentEntity, entity2: ContentEntity) -> RelationshipType? {
        switch (entity1.type, entity2.type) {
        case (.person, .organization):
            return .employment
        case (.project, .person):
            return .participation
        case (.project, .organization):
            return .ownership
        case (.date, .project):
            return .temporal
        case (.money, .project):
            return .financial
        case (.technicalTerm, .project):
            return .technical
        default:
            return nil
        }
    }

    /// Generates entity insights
    /// - Parameters:
    ///   - entities: Array of entities
    ///   - entitiesByType: Entities grouped by type
    ///   - relationships: Entity relationships
    /// - Returns: Array of insights
    private func generateEntityInsights(
        entities: [ContentEntity],
        entitiesByType: [EntityType: [ContentEntity]],
        relationships: [EntityRelationship]
    ) -> [String] {
        var insights: [String] = []

        insights.append("Extracted \(entities.count) entities of \(entitiesByType.count) different types")

        if let technicalTerms = entitiesByType[.technicalTerm] {
            insights.append("Found \(technicalTerms.count) technical terms indicating specialized content")
        }

        if let people = entitiesByType[.person] {
            insights.append("Identified \(people.count) people mentioned in the content")
        }

        if let money = entitiesByType[.money] {
            insights.append("Found \(money.count) financial references")
        }

        if !relationships.isEmpty {
            insights.append("Identified \(relationships.count) potential relationships between entities")
        }

        let highConfidenceEntities = entities.filter { $0.confidence > 0.8 }
        insights.append("\(highConfidenceEntities.count) entities have high confidence (>0.8)")

        return insights
    }
}

/// Analyzes sentiment of content
public class SentimentAnalyzer {

    // MARK: - Sentiment Analysis

    /// Analyzes sentiment of content
    /// - Parameter content: Content to analyze
    /// - Returns: Sentiment analysis result
    public func analyzeSentiment(content: String) -> SentimentAnalysis {
        let lowercaseContent = content.lowercased()

        // Calculate sentiment score
        let sentiment = calculateSentimentScore(content: lowercaseContent)

        // Determine emotional tone
        let emotionalTone = determineEmotionalTone(sentiment: sentiment, content: lowercaseContent)

        // Determine professionalism level
        let professionalism = determineProfessionalismLevel(content: lowercaseContent)

        // Calculate confidence
        let confidence = calculateSentimentConfidence(content: content, sentiment: sentiment)

        return SentimentAnalysis(
            sentiment: sentiment,
            confidence: confidence,
            emotionalTone: emotionalTone,
            professionalism: professionalism
        )
    }

    /// Provides detailed sentiment analysis
    /// - Parameter content: Content to analyze
    /// - Returns: Detailed sentiment analysis
    public func getDetailedSentimentAnalysis(content: String) -> DetailedSentimentAnalysis {
        let basicAnalysis = analyzeSentiment(content: content)

        // Additional sentiment metrics
        let sentimentBreakdown = calculateSentimentBreakdown(content: content.lowercased())
        let emotionalIndicators = extractEmotionalIndicators(content: content.lowercased())
        let communicationStyle = analyzeCommunicationStyle(content: content.lowercased())

        // Generate sentiment insights
        let insights = generateSentimentInsights(
            basicAnalysis: basicAnalysis,
            breakdown: sentimentBreakdown,
            indicators: emotionalIndicators,
            style: communicationStyle
        )

        return DetailedSentimentAnalysis(
            basicAnalysis: basicAnalysis,
            sentimentBreakdown: sentimentBreakdown,
            emotionalIndicators: emotionalIndicators,
            communicationStyle: communicationStyle,
            insights: insights
        )
    }

    // MARK: - Private Helper Methods

    /// Calculates sentiment score
    /// - Parameter content: Content to analyze
    /// - Returns: Sentiment score (-1.0 to 1.0)
    private func calculateSentimentScore(content: String) -> Double {
        // Positive words
        let positiveWords = [
            "good", "great", "excellent", "amazing", "perfect", "love", "happy", "satisfied",
            "wonderful", "fantastic", "awesome", "brilliant", "outstanding", "superb",
            "please", "thank", "appreciate", "excited", "delighted", "thrilled"
        ]

        // Negative words
        let negativeWords = [
            "bad", "terrible", "awful", "hate", "angry", "frustrated", "disappointed",
            "problem", "issue", "error", "wrong", "fail", "poor", "worst", "horrible",
            "annoying", "difficult", "confusing", "complicated", "stressful"
        ]

        let positiveCount = positiveWords.filter { content.contains($0) }.count
        let negativeCount = negativeWords.filter { content.contains($0) }.count

        let totalWords = content.split(separator: " ").count
        let netSentiment = Double(positiveCount - negativeCount)
        let sentimentScore = netSentiment / Double(max(totalWords, 1))

        return max(-1.0, min(1.0, sentimentScore))
    }

    /// Determines emotional tone
    /// - Parameters:
    ///   - sentiment: Sentiment score
    ///   - content: Content to analyze
    /// - Returns: Emotional tone
    private func determineEmotionalTone(sentiment: Double, content: String) -> EmotionalTone {
        // Check for specific emotional indicators
        if content.contains("excited") || content.contains("thrilled") {
            return .excited
        } else if content.contains("concerned") || content.contains("worried") {
            return .concerned
        } else if content.contains("frustrated") || content.contains("annoyed") {
            return .frustrated
        } else if content.contains("satisfied") || content.contains("pleased") {
            return .satisfied
        } else if content.contains("confused") || content.contains("uncertain") {
            return .confused
        } else if content.contains("confident") || content.contains("sure") {
            return .confident
        } else if content.contains("anxious") || content.contains("nervous") {
            return .anxious
        } else if sentiment > 0.3 {
            return .positive
        } else if sentiment < -0.3 {
            return .negative
        } else {
            return .neutral
        }
    }

    /// Determines professionalism level
    /// - Parameter content: Content to analyze
    /// - Returns: Professionalism level
    private func determineProfessionalismLevel(content: String) -> ProfessionalismLevel {
        let professionalWords = [
            "please", "thank", "appreciate", "regards", "sincerely", "best regards",
            "accordingly", "therefore", "furthermore", "respectfully"
        ]

        let informalWords = [
            "hey", "yeah", "cool", "awesome", "dude", "gonna", "wanna",
            " kinda", "sorta", "sup", "what's up"
        ]

        let professionalCount = professionalWords.filter { content.contains($0) }.count
        let informalCount = informalWords.filter { content.contains($0) }.count

        // Check for proper grammar indicators
        let hasProperCapitalization = content.prefix(1).uppercased() == content.prefix(1)
        let hasProperPunctuation = content.contains(".") || content.contains("!") || content.contains("?")

        if professionalCount > informalCount + 1 && hasProperCapitalization && hasProperPunctuation {
            return .highlyProfessional
        } else if professionalCount > informalCount {
            return .professional
        } else if informalCount > professionalCount + 1 {
            return .casual
        } else if informalCount > 0 {
            return .informal
        } else {
            return .semiFormal
        }
    }

    /// Calculates sentiment confidence
    /// - Parameters:
    ///   - content: Content to analyze
    ///   - sentiment: Sentiment score
    /// - Returns: Confidence score (0.0-1.0)
    private func calculateSentimentConfidence(content: String, sentiment: Double) -> Double {
        let wordCount = content.split(separator: " ").count

        // Higher confidence for longer content and stronger sentiment
        let lengthConfidence = min(Double(wordCount) / 100.0, 1.0)
        let sentimentStrength = abs(sentiment)
        let strengthConfidence = min(sentimentStrength * 2, 1.0)

        return (lengthConfidence + strengthConfidence) / 2.0
    }

    /// Calculates sentiment breakdown
    /// - Parameter content: Content to analyze
    /// - Returns: Sentiment breakdown
    private func calculateSentimentBreakdown(content: String) -> SentimentBreakdown {
        let positiveWords = ["good", "great", "excellent", "amazing", "perfect"]
        let negativeWords = ["bad", "terrible", "awful", "hate", "angry"]
        let neutralWords = ["is", "are", "was", "were", "the", "a", "an"]

        let positiveCount = positiveWords.filter { content.contains($0) }.count
        let negativeCount = negativeWords.filter { content.contains($0) }.count
        let neutralCount = neutralWords.filter { content.contains($0) }.count

        let totalSentimentWords = positiveCount + negativeCount + neutralCount
        let positivePercentage = totalSentimentWords > 0 ? Double(positiveCount) / Double(totalSentimentWords) : 0.0
        let negativePercentage = totalSentimentWords > 0 ? Double(negativeCount) / Double(totalSentimentWords) : 0.0
        let neutralPercentage = totalSentimentWords > 0 ? Double(neutralCount) / Double(totalSentimentWords) : 0.0

        return SentimentBreakdown(
            positivePercentage: positivePercentage,
            negativePercentage: negativePercentage,
            neutralPercentage: neutralPercentage,
            totalSentimentWords: totalSentimentWords
        )
    }

    /// Extracts emotional indicators
    /// - Parameter content: Content to analyze
    /// - Returns: Array of emotional indicators
    private func extractEmotionalIndicators(content: String) -> [EmotionalIndicator] {
        let emotionPatterns: [(String, EmotionalTone)] = [
            ("excited", .excited),
            ("concerned", .concerned),
            ("frustrated", .frustrated),
            ("satisfied", .satisfied),
            ("confused", .confused),
            ("confident", .confident),
            ("anxious", .anxious)
        ]

        var indicators: [EmotionalIndicator] = []

        for (emotion, tone) in emotionPatterns {
            let occurrences = content.components(separatedBy: .whitespacesAndNewlines)
                .filter { $0.lowercased().contains(emotion) }.count

            if occurrences > 0 {
                indicators.append(EmotionalIndicator(
                    emotion: emotion,
                    tone: tone,
                    count: occurrences,
                    intensity: min(Double(occurrences) * 0.2, 1.0)
                ))
            }
        }

        return indicators
    }

    /// Analyzes communication style
    /// - Parameter content: Content to analyze
    /// - Returns: Communication style
    private func analyzeCommunicationStyle(content: String) -> CommunicationStyle {
        let questions = content.filter { $0 == "?" }.count
        let exclamations = content.filter { $0 == "!" }.count
        let words = content.split(separator: " ").count

        let questionRatio = Double(questions) / Double(words)
        let exclamationRatio = Double(exclamations) / Double(words)

        if questionRatio > 0.05 {
            return .inquisitive
        } else if exclamationRatio > 0.02 {
            return .expressive
        } else if content.contains("please") || content.contains("thank") {
            return .polite
        } else {
            return .neutral
        }
    }

    /// Generates sentiment insights
    /// - Parameters:
    ///   - basicAnalysis: Basic sentiment analysis
    ///   - breakdown: Sentiment breakdown
    ///   - indicators: Emotional indicators
    ///   - style: Communication style
    /// - Returns: Array of insights
    private func generateSentimentInsights(
        basicAnalysis: SentimentAnalysis,
        breakdown: SentimentBreakdown,
        indicators: [EmotionalIndicator],
        style: CommunicationStyle
    ) -> [String] {
        var insights: [String] = []

        insights.append("Overall sentiment: \(basicAnalysis.emotionalTone.rawValue)")
        insights.append("Professionalism level: \(basicAnalysis.professionalism.rawValue)")
        insights.append("Communication style: \(style.rawValue)")

        if !indicators.isEmpty {
            let dominantEmotion = indicators.max { $0.intensity < $1.intensity }
            if let emotion = dominantEmotion {
                insights.append("Dominant emotion: \(emotion.emotion) (\(String(format: "%.1f", emotion.intensity * 100))% intensity)")
            }
        }

        if breakdown.totalSentimentWords > 0 {
            insights.append("Sentiment breakdown: \(String(format: "%.1f", breakdown.positivePercentage * 100))% positive, \(String(format: "%.1f", breakdown.negativePercentage * 100))% negative")
        }

        if basicAnalysis.confidence > 0.8 {
            insights.append("High confidence sentiment analysis (>80%)")
        } else if basicAnalysis.confidence < 0.5 {
            insights.append("Low confidence sentiment analysis - consider more context")
        }

        return insights
    }
}

/// Assesses urgency of content
public class UrgencyAnalyzer {

    // MARK: - Urgency Assessment

    /// Assesses urgency of content
    /// - Parameters:
    ///   - content: Content to analyze
    ///   - entities: Extracted entities
    /// - Returns: Urgency assessment
    public func assessUrgency(content: String, entities: [ContentEntity] = []) -> UrgencyAssessment {
        let lowercaseContent = content.lowercased()

        // Calculate urgency level
        let urgencyLevel = calculateUrgencyLevel(content: lowercaseContent)

        // Determine time sensitivity
        let timeSensitivity = determineTimeSensitivity(content: lowercaseContent)

        // Determine response timeframe
        let responseTimeframe = determineResponseTimeframe(timeSensitivity: timeSensitivity, content: lowercaseContent)

        // Extract critical issues
        let criticalIssues = extractCriticalIssues(content: lowercaseContent)

        return UrgencyAssessment(
            urgencyLevel: urgencyLevel,
            timeSensitivity: timeSensitivity,
            responseTimeframe: responseTimeframe,
            criticalIssues: criticalIssues
        )
    }

    /// Provides detailed urgency analysis
    /// - Parameters:
    ///   - content: Content to analyze
    ///   - entities: Extracted entities
    /// - Returns: Detailed urgency analysis
    public func getDetailedUrgencyAnalysis(content: String, entities: [ContentEntity] = []) -> DetailedUrgencyAnalysis {
        let basicAssessment = assessUrgency(content: content, entities: entities)

        // Additional urgency metrics
        let urgencyFactors = calculateUrgencyFactors(content: content.lowercased())
        let deadlineAnalysis = analyzeDeadlines(content: content.lowercased())
        let priorityIndicators = extractPriorityIndicators(content: content.lowercased())

        // Generate urgency insights
        let insights = generateUrgencyInsights(
            assessment: basicAssessment,
            factors: urgencyFactors,
            deadlines: deadlineAnalysis,
            priorities: priorityIndicators
        )

        return DetailedUrgencyAnalysis(
            basicAssessment: basicAssessment,
            urgencyFactors: urgencyFactors,
            deadlineAnalysis: deadlineAnalysis,
            priorityIndicators: priorityIndicators,
            insights: insights
        )
    }

    // MARK: - Private Helper Methods

    /// Calculates urgency level
    /// - Parameter content: Content to analyze
    /// - Returns: Urgency level (0.0-1.0)
    private func calculateUrgencyLevel(content: String) -> Double {
        // Urgency indicators with weights
        let urgentWords: [(String, Double)] = [
            ("urgent", 1.0),
            ("asap", 0.9),
            ("immediately", 0.9),
            ("emergency", 1.0),
            ("critical", 0.8),
            ("now", 0.7),
            ("rush", 0.8),
            ("priority", 0.6)
        ]

        let timeWords: [(String, Double)] = [
            ("today", 0.6),
            ("tomorrow", 0.4),
            ("deadline", 0.7),
            ("due", 0.6),
            ("end of day", 0.5)
        ]

        var urgencyScore = 0.0

        // Score urgent words
        for (word, weight) in urgentWords {
            if content.contains(word) {
                urgencyScore += weight
            }
        }

        // Score time words
        for (word, weight) in timeWords {
            if content.contains(word) {
                urgencyScore += weight
            }
        }

        return min(urgencyScore / 3.0, 1.0) // Normalize to 0-1 range
    }

    /// Determines time sensitivity
    /// - Parameter content: Content to analyze
    /// - Returns: Time sensitivity
    private func determineTimeSensitivity(content: String) -> TimeSensitivity {
        if content.contains("urgent") || content.contains("immediately") || content.contains("emergency") {
            return .immediate
        } else if content.contains("today") || content.contains("end of day") {
            return .sameDay
        } else if content.contains("tomorrow") {
            return .nextWeek
        } else if content.contains("this week") || content.contains("deadline") {
            return .thisWeek
        } else if content.contains("this month") {
            return .thisMonth
        } else if content.contains("schedule") || content.contains("plan") {
            return .routine
        } else {
            return .noDeadline
        }
    }

    /// Determines response timeframe
    /// - Parameters:
    ///   - timeSensitivity: Time sensitivity
    ///   - content: Content to analyze
    /// - Returns: Response timeframe
    private func determineResponseTimeframe(timeSensitivity: TimeSensitivity, content: String) -> String? {
        switch timeSensitivity {
        case .immediate:
            return "Within 1 hour"
        case .sameDay:
            return "Same day"
        case .nextWeek:
            return "Within 1 week"
        case .thisWeek:
            return "This week"
        case .thisMonth:
            return "Within 1 month"
        case .routine:
            return "Within 2 weeks"
        case .noDeadline:
            return nil
        }
    }

    /// Extracts critical issues
    /// - Parameter content: Content to analyze
    /// - Returns: Array of critical issues
    private func extractCriticalIssues(content: String) -> [String] {
        let criticalPatterns = [
            "urgent", "asap", "immediately", "emergency", "critical",
            "problem", "issue", "error", "fail", "broken", "not working"
        ]

        return criticalPatterns.filter { content.contains($0) }
    }

    /// Calculates urgency factors
    /// - Parameter content: Content to analyze
    /// - Returns: Urgency factors
    private func calculateUrgencyFactors(content: String) -> UrgencyFactors {
        let deadlineWords = ["deadline", "due date", "delivery", "completion"]
        let priorityWords = ["priority", "important", "critical", "urgent"]
        let riskWords = ["risk", "danger", "warning", "attention"]

        let deadlineCount = deadlineWords.filter { content.contains($0) }.count
        let priorityCount = priorityWords.filter { content.contains($0) }.count
        let riskCount = riskWords.filter { content.contains($0) }.count

        return UrgencyFactors(
            deadlinePressure: Double(deadlineCount),
            priorityLevel: Double(priorityCount),
            riskLevel: Double(riskCount),
            externalPressure: content.contains("client") || content.contains("customer") ? 1.0 : 0.0
        )
    }

    /// Analyzes deadlines
    /// - Parameter content: Content to analyze
    /// - Returns: Deadline analysis
    private func analyzeDeadlines(content: String) -> DeadlineAnalysis {
        let datePatterns = [
            #"(\d{1,2}/\d{1,2}/\d{4})"#,
            #"(\d{4}-\d{2}-\d{2})"#,
            #"(\w+\s+\d{1,2},?\s+\d{4})"#
        ]

        var deadlines: [String] = []

        for pattern in datePatterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { continue }

            let matches = regex.matches(in: content, range: NSRange(content.startIndex..<content.endIndex, in: content))
            for match in matches {
                if let range = Range(match.range, in: content) {
                    deadlines.append(String(content[range]))
                }
            }
        }

        let hasExplicitDeadline = !deadlines.isEmpty
        let hasTimeConstraints = content.contains("by") || content.contains("before") || content.contains("within")

        return DeadlineAnalysis(
            hasExplicitDeadline: hasExplicitDeadline,
            deadlineDates: deadlines,
            hasTimeConstraints: hasTimeConstraints,
            deadlineCount: deadlines.count
        )
    }

    /// Extracts priority indicators
    /// - Parameter content: Content to analyze
    /// - Returns: Array of priority indicators
    private func extractPriorityIndicators(content: String) -> [PriorityIndicator] {
        let priorityPatterns: [(String, Priority)] = [
            ("high priority", .high),
            ("urgent", .urgent),
            ("critical", .critical),
            ("low priority", .low),
            ("medium priority", .medium)
        ]

        var indicators: [PriorityIndicator] = []

        for (pattern, priority) in priorityPatterns {
            if content.contains(pattern) {
                indicators.append(PriorityIndicator(
                    priority: priority,
                    context: pattern,
                    weight: priority.score
                ))
            }
        }

        return indicators
    }

    /// Generates urgency insights
    /// - Parameters:
    ///   - assessment: Basic urgency assessment
    ///   - factors: Urgency factors
    ///   - deadlines: Deadline analysis
    ///   - priorities: Priority indicators
    /// - Returns: Array of insights
    private func generateUrgencyInsights(
        assessment: UrgencyAssessment,
        factors: UrgencyFactors,
        deadlines: DeadlineAnalysis,
        priorities: [PriorityIndicator]
    ) -> [String] {
        var insights: [String] = []

        insights.append("Time sensitivity: \(assessment.timeSensitivity.rawValue)")

        if let timeframe = assessment.responseTimeframe {
            insights.append("Suggested response timeframe: \(timeframe)")
        }

        if !assessment.criticalIssues.isEmpty {
            insights.append("\(assessment.criticalIssues.count) critical issues identified")
        }

        if deadlines.hasExplicitDeadline {
            insights.append("\(deadlines.deadlineCount) explicit deadlines detected")
        }

        if !priorities.isEmpty {
            let highestPriority = priorities.max { $0.weight < $1.weight }
            if let priority = highestPriority {
                insights.append("Highest priority: \(priority.priority.rawValue)")
            }
        }

        let totalPressure = factors.deadlinePressure + factors.priorityLevel + factors.riskLevel + factors.externalPressure
        if totalPressure > 3.0 {
            insights.append("High overall urgency pressure detected")
        } else if totalPressure < 1.0 {
            insights.append("Low urgency pressure - flexible timeline")
        }

        return insights
    }
}

// MARK: - Supporting Types

/// Detailed entity analysis result
public struct DetailedEntityAnalysis {
    public let entities: [ContentEntity]
    public let entitiesByType: [EntityType: [ContentEntity]]
    public let totalEntities: Int
    public let uniqueTypes: Int
    public let averageConfidence: Double
    public let entityRelationships: [EntityRelationship]
    public let insights: [String]

    public init(
        entities: [ContentEntity],
        entitiesByType: [EntityType: [ContentEntity]],
        totalEntities: Int,
        uniqueTypes: Int,
        averageConfidence: Double,
        entityRelationships: [EntityRelationship],
        insights: [String]
    ) {
        self.entities = entities
        self.entitiesByType = entitiesByType
        self.totalEntities = totalEntities
        self.uniqueTypes = uniqueTypes
        self.averageConfidence = averageConfidence
        self.entityRelationships = entityRelationships
        self.insights = insights
    }
}

/// Entity relationship
public struct EntityRelationship {
    public let entity1: ContentEntity
    public let entity2: ContentEntity
    public let type: RelationshipType
    public let confidence: Double

    public init(entity1: ContentEntity, entity2: ContentEntity, type: RelationshipType, confidence: Double) {
        self.entity1 = entity1
        self.entity2 = entity2
        self.type = type
        self.confidence = confidence
    }
}

/// Relationship type
public enum RelationshipType: String, CaseIterable, Codable, Sendable {
    case employment = "employment"
    case participation = "participation"
    case ownership = "ownership"
    case temporal = "temporal"
    case financial = "financial"
    case technical = "technical"
}

/// Detailed sentiment analysis result
public struct DetailedSentimentAnalysis {
    public let basicAnalysis: SentimentAnalysis
    public let sentimentBreakdown: SentimentBreakdown
    public let emotionalIndicators: [EmotionalIndicator]
    public let communicationStyle: CommunicationStyle
    public let insights: [String]

    public init(
        basicAnalysis: SentimentAnalysis,
        sentimentBreakdown: SentimentBreakdown,
        emotionalIndicators: [EmotionalIndicator],
        communicationStyle: CommunicationStyle,
        insights: [String]
    ) {
        self.basicAnalysis = basicAnalysis
        self.sentimentBreakdown = sentimentBreakdown
        self.emotionalIndicators = emotionalIndicators
        self.communicationStyle = communicationStyle
        self.insights = insights
    }
}

/// Sentiment breakdown
public struct SentimentBreakdown {
    public let positivePercentage: Double
    public let negativePercentage: Double
    public let neutralPercentage: Double
    public let totalSentimentWords: Int

    public init(positivePercentage: Double, negativePercentage: Double, neutralPercentage: Double, totalSentimentWords: Int) {
        self.positivePercentage = positivePercentage
        self.negativePercentage = negativePercentage
        self.neutralPercentage = neutralPercentage
        self.totalSentimentWords = totalSentimentWords
    }
}

/// Emotional indicator
public struct EmotionalIndicator {
    public let emotion: String
    public let tone: EmotionalTone
    public let count: Int
    public let intensity: Double

    public init(emotion: String, tone: EmotionalTone, count: Int, intensity: Double) {
        self.emotion = emotion
        self.tone = tone
        self.count = count
        self.intensity = intensity
    }
}

/// Communication style
public enum CommunicationStyle: String, CaseIterable, Codable, Sendable {
    case neutral = "neutral"
    case polite = "polite"
    case expressive = "expressive"
    case inquisitive = "inquisitive"
}

/// Detailed urgency analysis result
public struct DetailedUrgencyAnalysis {
    public let basicAssessment: UrgencyAssessment
    public let urgencyFactors: UrgencyFactors
    public let deadlineAnalysis: DeadlineAnalysis
    public let priorityIndicators: [PriorityIndicator]
    public let insights: [String]

    public init(
        basicAssessment: UrgencyAssessment,
        urgencyFactors: UrgencyFactors,
        deadlineAnalysis: DeadlineAnalysis,
        priorityIndicators: [PriorityIndicator],
        insights: [String]
    ) {
        self.basicAssessment = basicAssessment
        self.urgencyFactors = urgencyFactors
        self.deadlineAnalysis = deadlineAnalysis
        self.priorityIndicators = priorityIndicators
        self.insights = insights
    }
}

/// Urgency factors
public struct UrgencyFactors {
    public let deadlinePressure: Double
    public let priorityLevel: Double
    public let riskLevel: Double
    public let externalPressure: Double

    public init(deadlinePressure: Double, priorityLevel: Double, riskLevel: Double, externalPressure: Double) {
        self.deadlinePressure = deadlinePressure
        self.priorityLevel = priorityLevel
        self.riskLevel = riskLevel
        self.externalPressure = externalPressure
    }

    /// Total urgency pressure
    public var totalPressure: Double {
        return deadlinePressure + priorityLevel + riskLevel + externalPressure
    }
}

/// Deadline analysis
public struct DeadlineAnalysis {
    public let hasExplicitDeadline: Bool
    public let deadlineDates: [String]
    public let hasTimeConstraints: Bool
    public let deadlineCount: Int

    public init(hasExplicitDeadline: Bool, deadlineDates: [String], hasTimeConstraints: Bool, deadlineCount: Int) {
        self.hasExplicitDeadline = hasExplicitDeadline
        self.deadlineDates = deadlineDates
        self.hasTimeConstraints = hasTimeConstraints
        self.deadlineCount = deadlineCount
    }
}

/// Priority indicator
public struct PriorityIndicator {
    public let priority: Priority
    public let context: String
    public let weight: Double

    public init(priority: Priority, context: String, weight: Double) {
        self.priority = priority
        self.context = context
        self.weight = weight
    }
}