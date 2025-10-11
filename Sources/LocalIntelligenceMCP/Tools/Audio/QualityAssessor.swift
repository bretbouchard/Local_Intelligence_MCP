//
//  QualityAssessor.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-09.
//

import Foundation

/// Assesses content quality and extracts actionable insights
public class QualityAssessor {

    // MARK: - Quality Assessment

    /// Assesses content quality
    /// - Parameters:
    ///   - content: Content to assess
    ///   - contentType: Type of content
    /// - Returns: Quality indicators
    public func assessQuality(content: String, contentType: ContentType) -> QualityIndicators {
        // Calculate quality metrics
        let completeness = calculateCompleteness(content: content, contentType: contentType)
        let clarity = calculateClarity(content: content)
        let organization = calculateOrganization(content: content)
        let technicalAccuracy = calculateTechnicalAccuracy(content: content, contentType: contentType)

        // Extract action items
        let actionItems = extractActionItems(content: content)

        // Extract follow-up requirements
        let followUpRequirements = extractFollowUpRequirements(content: content)

        return QualityIndicators(
            completeness: completeness,
            clarity: clarity,
            organization: organization,
            technicalAccuracy: technicalAccuracy,
            actionItems: actionItems,
            followUpRequirements: followUpRequirements
        )
    }

    /// Provides detailed quality analysis
    /// - Parameters:
    ///   - content: Content to assess
    ///   - contentType: Type of content
    /// - Returns: Detailed quality analysis
    public func getDetailedQualityAnalysis(content: String, contentType: ContentType) -> DetailedQualityAnalysis {
        // Basic quality assessment
        let basicQuality = assessQuality(content: content, contentType: contentType)

        // Additional quality metrics
        let readabilityScore = calculateReadabilityScore(content: content)
        let structureScore = calculateStructureScore(content: content)
        let consistencyScore = calculateConsistencyScore(content: content)
        let completenessScore = calculateCompletenessScore(content: content, contentType: contentType)

        // Quality issues identification
        let qualityIssues = identifyQualityIssues(content: content, contentType: contentType)
        let improvementSuggestions = generateImprovementSuggestions(
            content: content,
            contentType: contentType,
            qualityIndicators: basicQuality,
            qualityIssues: qualityIssues
        )

        // Overall quality score
        let overallQualityScore = (basicQuality.completeness + basicQuality.clarity +
                                  basicQuality.organization + basicQuality.technicalAccuracy) / 4.0

        return DetailedQualityAnalysis(
            basicQuality: basicQuality,
            readabilityScore: readabilityScore,
            structureScore: structureScore,
            consistencyScore: consistencyScore,
            completenessScore: completenessScore,
            overallQualityScore: overallQualityScore,
            qualityIssues: qualityIssues,
            improvementSuggestions: improvementSuggestions
        )
    }

    // MARK: - Quality Metric Calculations

    /// Calculates completeness score
    /// - Parameters:
    ///   - content: Content to analyze
    ///   - contentType: Type of content
    /// - Returns: Completeness score (0.0-1.0)
    private func calculateCompleteness(content: String, contentType: ContentType) -> Double {
        let wordCount = content.split(separator: " ").count

        // Different content types have different optimal lengths
        let targetLength: Int
        switch contentType {
        case .sessionNotes:
            targetLength = 100
        case .technicalLog:
            targetLength = 150
        case .clientCommunication:
            targetLength = 200
        case .projectDocumentation:
            targetLength = 300
        case .troubleshooting:
            targetLength = 250
        case .tutorial:
            targetLength = 400
        default:
            targetLength = 100
        }

        // Score based on proximity to target length
        let lengthScore = 1.0 - abs(Double(wordCount - targetLength)) / Double(targetLength)
        return max(0.0, min(1.0, lengthScore))
    }

    /// Calculates clarity score
    /// - Parameter content: Content to analyze
    /// - Returns: Clarity score (0.0-1.0)
    private func calculateClarity(content: String) -> Double {
        let sentences = content.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        guard !sentences.isEmpty else { return 0.0 }

        // Calculate average sentence length
        let totalWords = sentences.flatMap { $0.split(separator: " ") }.count
        let avgSentenceLength = Double(totalWords) / Double(sentences.count)

        // Optimal sentence length is 15-20 words
        let optimalLength = 17.5
        let lengthScore = 1.0 - abs(avgSentenceLength - optimalLength) / optimalLength

        // Check for clarity indicators
        let lowercaseContent = content.lowercased()
        let clarityWords = ["clear", "obvious", "specific", "precise", "detailed", "explicit"]
        let confusionWords = ["unclear", "confusing", "vague", "uncertain", "ambiguous"]

        let clarityBonus = Double(clarityWords.filter { lowercaseContent.contains($0) }.count) * 0.1
        let confusionPenalty = Double(confusionWords.filter { lowercaseContent.contains($0) }.count) * 0.15

        return max(0.0, min(1.0, lengthScore + clarityBonus - confusionPenalty))
    }

    /// Calculates organization score
    /// - Parameter content: Content to analyze
    /// - Returns: Organization score (0.0-1.0)
    private func calculateOrganization(content: String) -> Double {
        let lowercaseContent = content.lowercased()

        // Look for organizational indicators
        let organizationWords = ["first", "second", "third", "next", "then", "finally", "conclusion", "summary", "introduction"]
        let listIndicators = ["•", "-", "1.", "2.", "a)", "b)", "*"]
        let sectionMarkers = ["section", "chapter", "part", "step", "phase", "stage"]

        let organizationScore = Double(organizationWords.filter { lowercaseContent.contains($0) }.count) * 0.05
        let listScore = Double(listIndicators.filter { content.contains($0) }.count) * 0.1
        let sectionScore = Double(sectionMarkers.filter { lowercaseContent.contains($0) }.count) * 0.08

        return max(0.0, min(1.0, organizationScore + listScore + sectionScore))
    }

    /// Calculates technical accuracy score
    /// - Parameters:
    ///   - content: Content to analyze
    ///   - contentType: Type of content
    /// - Returns: Technical accuracy score (0.0-1.0)
    private func calculateTechnicalAccuracy(content: String, contentType: ContentType) -> Double {
        // Only relevant for technical content types
        let technicalTypes: [ContentType] = [.technicalLog, .troubleshooting, .specification, .projectDocumentation]
        guard technicalTypes.contains(contentType) else { return 0.8 } // Default for non-technical content

        let technicalTerms = ["khz", "hz", "db", "ratio", "threshold", "frequency", "bit", "sample"]
        let lowercaseContent = content.lowercased()

        let technicalTermsFound = technicalTerms.filter { lowercaseContent.contains($0) }

        // Basic consistency check
        if technicalTermsFound.isEmpty {
            return 0.8 // Not technical content
        }

        // Check for proper formatting and consistency
        let hasProperFormatting = technicalTermsFound.allSatisfy { term in
            let pattern = "\\b\(term)\\b"
            return content.range(of: pattern, options: .regularExpression) != nil
        }

        let formattingScore = hasProperFormatting ? 0.9 : 0.6

        // Check for numerical consistency (e.g., consistent units)
        let hasConsistentUnits = checkTechnicalConsistency(content: content, technicalTerms: technicalTermsFound)
        let consistencyBonus = hasConsistentUnits ? 0.1 : 0.0

        return min(1.0, formattingScore + consistencyBonus)
    }

    // MARK: - Advanced Quality Metrics

    /// Calculates readability score
    /// - Parameter content: Content to analyze
    /// - Returns: Readability score (0.0-1.0)
    private func calculateReadabilityScore(content: String) -> Double {
        let words = content.split(separator: " ")
        let sentences = content.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        guard !sentences.isEmpty else { return 0.0 }

        let avgWordsPerSentence = Double(words.count) / Double(sentences.count)
        let avgCharsPerWord = words.reduce(0.0) { $0 + Double($1.count) } / Double(words.count)

        // Simple readability scoring (lower average sentence length and word length = more readable)
        let sentenceScore = max(0.0, 1.0 - (avgWordsPerSentence - 15) / 25)
        let wordScore = max(0.0, 1.0 - (avgCharsPerWord - 5) / 5)

        return (sentenceScore + wordScore) / 2.0
    }

    /// Calculates structure score
    /// - Parameter content: Content to analyze
    /// - Returns: Structure score (0.0-1.0)
    private func calculateStructureScore(content: String) -> Double {
        let lines = content.components(separatedBy: .newlines)
        let nonEmptyLines = lines.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        guard !nonEmptyLines.isEmpty else { return 0.0 }

        // Check for structural elements
        let hasHeadings = nonEmptyLines.contains { $0.trimmingCharacters(in: .whitespacesAndNewlines).count < 50 && $0.hasPrefix("#") }
        let hasLists = nonEmptyLines.contains { $0.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("-") || $0.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("*") }
        let hasParagraphs = nonEmptyLines.count > 3

        let structureScore = Double([hasHeadings, hasLists, hasParagraphs].filter { $0 }.count) / 3.0
        return structureScore
    }

    /// Calculates consistency score
    /// - Parameter content: Content to analyze
    /// - Returns: Consistency score (0.0-1.0)
    private func calculateConsistencyScore(content: String) -> Double {
        let lowercaseContent = content.lowercased()

        // Check for consistent terminology
        let terms = ["eq", "compression", "reverb", "delay", "frequency"]
        let consistentTerms = terms.filter { term in
            let occurrences = lowercaseContent.components(separatedBy: .whitespacesAndNewlines)
                .filter { $0.contains(term) }.count
            return occurrences <= 1 // Allow one mention to avoid penalizing
        }

        let terminologyScore = Double(consistentTerms.count) / Double(terms.count)

        // Check for consistent formatting
        let hasConsistentCasing = checkCasingConsistency(content: content)
        let formattingScore = hasConsistentCasing ? 1.0 : 0.7

        return (terminologyScore + formattingScore) / 2.0
    }

    /// Calculates completeness score for specific content type
    /// - Parameters:
    ///   - content: Content to analyze
    ///   - contentType: Type of content
    /// - Returns: Completeness score (0.0-1.0)
    private func calculateCompletenessScore(content: String, contentType: ContentType) -> Double {
        let lowercaseContent = content.lowercased()

        switch contentType {
        case .sessionNotes:
            let requiredElements = ["recording", "mic", "take", "performance"]
            let foundElements = requiredElements.filter { lowercaseContent.contains($0) }
            return Double(foundElements.count) / Double(requiredElements.count)

        case .technicalLog:
            let requiredElements = ["settings", "parameters", "equipment", "signal"]
            let foundElements = requiredElements.filter { lowercaseContent.contains($0) }
            return Double(foundElements.count) / Double(requiredElements.count)

        case .clientCommunication:
            let requiredElements = ["client", "feedback", "approval", "decision"]
            let foundElements = requiredElements.filter { lowercaseContent.contains($0) }
            return Double(foundElements.count) / Double(requiredElements.count)

        case .troubleshooting:
            let requiredElements = ["problem", "issue", "solution", "fix"]
            let foundElements = requiredElements.filter { lowercaseContent.contains($0) }
            return Double(foundElements.count) / Double(requiredElements.count)

        default:
            return 0.8 // Default for other content types
        }
    }

    // MARK: - Quality Issues and Suggestions

    /// Identifies quality issues in content
    /// - Parameters:
    ///   - content: Content to analyze
    ///   - contentType: Type of content
    /// - Returns: Array of quality issues
    private func identifyQualityIssues(content: String, contentType: ContentType) -> [QualityIssue] {
        var issues: [QualityIssue] = []

        // Length issues
        let wordCount = content.split(separator: " ").count
        if wordCount < 20 {
            issues.append(QualityIssue(
                type: .insufficientLength,
                description: "Content is too short to be comprehensive",
                severity: .medium,
                suggestion: "Add more details and context"
            ))
        } else if wordCount > 1000 {
            issues.append(QualityIssue(
                type: .excessiveLength,
                description: "Content may be too long for easy reading",
                severity: .low,
                suggestion: "Consider breaking into smaller sections"
            ))
        }

        // Clarity issues
        if content.contains("unclear") || content.contains("confusing") {
            issues.append(QualityIssue(
                type: .clarity,
                description: "Content contains self-identified clarity issues",
                severity: .high,
                suggestion: "Review and clarify ambiguous sections"
            ))
        }

        // Technical consistency issues
        if contentType == .technicalLog || contentType == .specification {
            let hasUnits = content.contains("hz") || content.contains("khz") || content.contains("db")
            if !hasUnits {
                issues.append(QualityIssue(
                    type: .technicalAccuracy,
                    description: "Technical content lacks specific measurements",
                    severity: .medium,
                    suggestion: "Add specific technical parameters and measurements"
                ))
            }
        }

        return issues
    }

    /// Generates improvement suggestions
    /// - Parameters:
    ///   - content: Content to analyze
    ///   - contentType: Type of content
    ///   - qualityIndicators: Quality indicators
    ///   - qualityIssues: Identified quality issues
    /// - Returns: Array of improvement suggestions
    private func generateImprovementSuggestions(
        content: String,
        contentType: ContentType,
        qualityIndicators: QualityIndicators,
        qualityIssues: [QualityIssue]
    ) -> [String] {
        var suggestions: [String] = []

        // Add suggestions based on quality scores
        if qualityIndicators.completeness < 0.6 {
            suggestions.append("Add more comprehensive details to improve completeness")
        }

        if qualityIndicators.clarity < 0.6 {
            suggestions.append("Reorganize content for better clarity and readability")
        }

        if qualityIndicators.organization < 0.6 {
            suggestions.append("Improve organization with headings, lists, or sections")
        }

        if qualityIndicators.technicalAccuracy < 0.6 {
            suggestions.append("Review and correct technical details for accuracy")
        }

        // Add suggestions based on content type
        switch contentType {
        case .sessionNotes:
            suggestions.append("Include specific microphone placements and recording techniques")
            suggestions.append("Document equipment settings and signal chain details")

        case .technicalLog:
            suggestions.append("Add comprehensive parameter specifications")
            suggestions.append("Include before/after comparisons when applicable")

        case .clientCommunication:
            suggestions.append("Clearly outline next steps and action items")
            suggestions.append("Document client decisions and approvals")

        case .troubleshooting:
            suggestions.append("Provide step-by-step problem resolution")
            suggestions.append("Include both problem description and solution details")

        default:
            break
        }

        // Add suggestions based on quality issues
        for issue in qualityIssues {
            suggestions.append(issue.suggestion)
        }

        return Array(Set(suggestions)) // Remove duplicates
    }

    // MARK: - Helper Methods

    /// Checks technical consistency in content
    /// - Parameters:
    ///   - content: Content to analyze
    ///   - technicalTerms: Technical terms found
    /// - Returns: True if content is technically consistent
    private func checkTechnicalConsistency(content: String, technicalTerms: [String]) -> Bool {
        // Simple consistency check - ensure numerical values have units
        let numberPattern = #"(\d+(?:\.\d+)?)\s*([a-zA-Z]{1,3})"#
        guard let regex = try? NSRegularExpression(pattern: numberPattern, options: .caseInsensitive) else {
            return false
        }

        let matches = regex.matches(in: content, range: NSRange(content.startIndex..<content.endIndex, in: content))

        // Check if most numbers have units
        let numbersWithUnits = matches.filter { match in
            if match.numberOfRanges > 2,
               let unitRange = Range(match.range(at: 2), in: content) {
                let unit = String(content[unitRange]).lowercased()
                return ["hz", "khz", "db", "ms", "sec", "bit"].contains(unit)
            }
            return false
        }

        return Double(numbersWithUnits.count) / Double(matches.count) > 0.7
    }

    /// Checks casing consistency in content
    /// - Parameter content: Content to analyze
    /// - Returns: True if content has consistent casing
    private func checkCasingConsistency(content: String) -> Bool {
        let lines = content.components(separatedBy: .newlines)
        let nonEmptyLines = lines.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        guard nonEmptyLines.count > 1 else { return true }

        // Check if most lines start consistently (with capital letter or lowercase)
        let startsWithCapital = nonEmptyLines.filter {
            let firstChar = $0.trimmingCharacters(in: .whitespacesAndNewlines).first
            return firstChar?.isUppercase ?? false
        }.count

        let startsWithLowercase = nonEmptyLines.filter {
            let firstChar = $0.trimmingCharacters(in: .whitespacesAndNewlines).first
            return firstChar?.isLowercase ?? false
        }.count

        // Consider consistent if >70% follow same pattern
        return Double(max(startsWithCapital, startsWithLowercase)) > Double(nonEmptyLines.count) * 0.7
    }

    // MARK: - Extraction Methods

    /// Extracts action items from content
    /// - Parameter content: Content to analyze
    /// - Returns: Array of action items
    private func extractActionItems(content: String) -> [ActionItem] {
        let actionIndicators = ["need to", "should", "must", "will", "plan to", "going to", "action item"]
        let sentences = content.components(separatedBy: CharacterSet(charactersIn: ".!?"))

        var actionItems: [ActionItem] = []

        for sentence in sentences {
            let trimmedSentence = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedSentence.isEmpty else { continue }

            let lowercaseSentence = trimmedSentence.lowercased()
            if actionIndicators.contains(where: lowercaseSentence.contains) {
                let priority: Priority
                if lowercaseSentence.contains("urgent") || lowercaseSentence.contains("asap") {
                    priority = .urgent
                } else if lowercaseSentence.contains("important") || lowercaseSentence.contains("priority") {
                    priority = .high
                } else if lowercaseSentence.contains("should") {
                    priority = .medium
                } else {
                    priority = .low
                }

                actionItems.append(ActionItem(
                    description: trimmedSentence,
                    priority: priority
                ))
            }
        }

        return actionItems
    }

    /// Extracts follow-up requirements from content
    /// - Parameter content: Content to analyze
    /// - Returns: Array of follow-up requirements
    private func extractFollowUpRequirements(content: String) -> [String] {
        let followUpIndicators = ["follow up", "check back", "review", "confirm", "verify", "follow-up"]
        let lowercaseContent = content.lowercased()

        return followUpIndicators.filter { lowercaseContent.contains($0) }
    }
}

// MARK: - Supporting Types

/// Detailed quality analysis result
public struct DetailedQualityAnalysis {
    public let basicQuality: QualityIndicators
    public let readabilityScore: Double
    public let structureScore: Double
    public let consistencyScore: Double
    public let completenessScore: Double
    public let overallQualityScore: Double
    public let qualityIssues: [QualityIssue]
    public let improvementSuggestions: [String]

    public init(
        basicQuality: QualityIndicators,
        readabilityScore: Double,
        structureScore: Double,
        consistencyScore: Double,
        completenessScore: Double,
        overallQualityScore: Double,
        qualityIssues: [QualityIssue],
        improvementSuggestions: [String]
    ) {
        self.basicQuality = basicQuality
        self.readabilityScore = readabilityScore
        self.structureScore = structureScore
        self.consistencyScore = consistencyScore
        self.completenessScore = completenessScore
        self.overallQualityScore = overallQualityScore
        self.qualityIssues = qualityIssues
        self.improvementSuggestions = improvementSuggestions
    }
}

/// Quality issue
public struct QualityIssue {
    public let type: QualityIssueType
    public let description: String
    public let severity: QualityIssueSeverity
    public let suggestion: String

    public init(type: QualityIssueType, description: String, severity: QualityIssueSeverity, suggestion: String) {
        self.type = type
        self.description = description
        self.severity = severity
        self.suggestion = suggestion
    }
}

/// Quality issue type
public enum QualityIssueType: String, CaseIterable, Codable, Sendable {
    case insufficientLength = "insufficient_length"
    case excessiveLength = "excessive_length"
    case clarity = "clarity"
    case organization = "organization"
    case technicalAccuracy = "technical_accuracy"
    case completeness = "completeness"
    case consistency = "consistency"
}

/// Quality issue severity
public enum QualityIssueSeverity: String, CaseIterable, Codable, Sendable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
}