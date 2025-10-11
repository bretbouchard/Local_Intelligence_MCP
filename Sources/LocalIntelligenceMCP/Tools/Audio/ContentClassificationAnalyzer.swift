//
//  ContentClassificationAnalyzer.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-09.
//

import Foundation

/// Analyzes content types and purposes based on patterns and structure
public class ContentClassificationAnalyzer {

    // MARK: - Properties

    private let typePatterns: [ContentType: [String]]
    private let structureIndicators: [ContentType: [String]]

    // MARK: - Sub-analyzers

    /// Public access to purpose analyzer for modular usage
    public let purposeAnalyzer: PurposeAnalyzer

    // MARK: - Initialization

    public init() {
        self.purposeAnalyzer = PurposeAnalyzer()

        self.typePatterns = [
            .sessionNotes: ["session", "recording", "mixing", "mastering", "notes", "log"],
            .transcript: ["transcript", "speaker", "said", "interview", "conversation"],
            .technicalLog: ["settings", "parameters", "specifications", "configuration", "technical"],
            .clientCommunication: ["client", "feedback", "review", "approval", "changes"],
            .projectDocumentation: ["documentation", "specification", "requirements", "guidelines"],
            .troubleshooting: ["problem", "issue", "error", "fix", "solution", "troubleshoot"],
            .reference: ["reference", "information", "data", "specifications"],
            .tutorial: ["tutorial", "guide", "how to", "step by step", "instructions"],
            .checkList: ["checklist", "todo", "task", "item", "verify"],
            .meetingNotes: ["meeting", "attendees", "agenda", "minutes", "discussion"],
            .email: ["subject", "to", "from", "cc", "bcc", "email", "message"],
            .chatLog: ["chat", "message", "said", "reply", "online"],
            .specification: ["specification", "shall", "must", "requirements", "technical"],
            .review: ["review", "assessment", "evaluation", "critique", "feedback"],
            .feedback: ["feedback", "comment", "suggestion", "opinion", "input"]
        ]

        self.structureIndicators = [
            .sessionNotes: ["take", "recording", "mic", "preamp", "eq", "compression"],
            .transcript: ["speaker", "timestamp", "dialogue", "question", "answer"],
            .technicalLog: ["khz", "db", "hz", "ratio", "threshold", "frequency"],
            .clientCommunication: ["please", "could you", "would like", "thank you", "appreciate"],
            .projectDocumentation: ["section", "subsection", "requirement", "specification"],
            .troubleshooting: ["error", "issue", "problem", "not working", "failed"],
            .tutorial: ["step", "first", "next", "then", "finally"],
            .checkList: ["[ ]", "[x]", "task", "complete", "verify"],
            .meetingNotes: ["attendees", "agenda", "action items", "decisions"],
            .email: ["dear", "regards", "sincerely", "best regards"]
        ]
    }

    // MARK: - Content Type Classification

    /// Classifies content type based on patterns and structure
    /// - Parameters:
    ///   - content: Content to classify
    ///   - hint: Optional hint about content type
    ///   - context: Additional context information
    /// - Returns: Detected content type
    public func classifyContentType(content: String, hint: String?, context: [String: Any]) -> ContentType {
        // Use hint if provided
        if let hint = hint, let contentType = ContentType(rawValue: hint) {
            return contentType
        }

        let lowercaseContent = content.lowercased()
        var typeScores: [ContentType: Double] = [:]

        // Score based on patterns
        for (contentType, patterns) in typePatterns {
            let matches = patterns.filter { lowercaseContent.contains($0) }.count
            typeScores[contentType] = Double(matches) / Double(patterns.count)
        }

        // Score based on structure indicators
        for (contentType, indicators) in structureIndicators {
            let matches = indicators.filter { lowercaseContent.contains($0) }.count
            typeScores[contentType] = (typeScores[contentType] ?? 0) + (Double(matches) * 0.1)
        }

        // Return type with highest score
        if let bestType = typeScores.max(by: { $0.value < $1.value }),
           bestType.value > 0.1 {
            return bestType.key
        }

        return .sessionNotes // Default type
    }

    /// Gets content type suggestions with confidence scores
    /// - Parameters:
    ///   - content: Content to analyze
    ///   - hint: Optional hint about content type
    ///   - context: Additional context information
    ///   - maxSuggestions: Maximum number of suggestions to return
    /// - Returns: Array of content type suggestions with confidence scores
    public func getContentTypeSuggestions(
        content: String,
        hint: String? = nil,
        context: [String: Any] = [:],
        maxSuggestions: Int = 3
    ) -> [(ContentType, Double)] {
        let lowercaseContent = content.lowercased()
        var typeScores: [ContentType: Double] = [:]

        // Score based on patterns
        for (contentType, patterns) in typePatterns {
            let matches = patterns.filter { lowercaseContent.contains($0) }.count
            typeScores[contentType] = Double(matches) / Double(patterns.count)
        }

        // Score based on structure indicators
        for (contentType, indicators) in structureIndicators {
            let matches = indicators.filter { lowercaseContent.contains($0) }.count
            typeScores[contentType] = (typeScores[contentType] ?? 0) + (Double(matches) * 0.1)
        }

        // Sort by score and return top suggestions
        let sortedScores = typeScores.sorted { $0.value > $1.value }
        return Array(sortedScores.prefix(maxSuggestions))
    }

    /// Validates content type classification
    /// - Parameters:
    ///   - content: Content to validate
    ///   - suggestedType: Suggested content type
    /// - Returns: Validation result with confidence and reasoning
    public func validateContentType(content: String, suggestedType: ContentType) -> ContentTypeValidation {
        let lowercaseContent = content.lowercased()

        // Get expected patterns for this type
        let expectedPatterns = typePatterns[suggestedType] ?? []
        let expectedStructures = structureIndicators[suggestedType] ?? []

        // Count matches
        let patternMatches = expectedPatterns.filter { lowercaseContent.contains($0) }
        let structureMatches = expectedStructures.filter { lowercaseContent.contains($0) }

        let patternScore = Double(patternMatches.count) / Double(max(expectedPatterns.count, 1))
        let structureScore = Double(structureMatches.count) * 0.1
        let overallScore = min(patternScore + structureScore, 1.0)

        // Generate reasoning
        var reasoning: [String] = []
        if !patternMatches.isEmpty {
            reasoning.append("Found \(patternMatches.count) matching content patterns")
        }
        if !structureMatches.isEmpty {
            reasoning.append("Found \(structureMatches.count) matching structural indicators")
        }

        return ContentTypeValidation(
            contentType: suggestedType,
            confidence: overallScore,
            matchedPatterns: patternMatches,
            matchedStructures: structureMatches,
            reasoning: reasoning.isEmpty ? ["No clear patterns found"] : reasoning
        )
    }
}

/// Analyzes content purpose and actionability
public class PurposeAnalyzer {

    // MARK: - Purpose Analysis

    /// Analyzes the primary purpose of content
    /// - Parameters:
    ///   - content: Content to analyze
    ///   - contentType: Detected content type
    /// - Returns: Primary content purpose
    public func analyzePurpose(content: String, contentType: ContentType) -> ContentPurpose {
        let lowercaseContent = content.lowercased()

        // Determine purpose based on content type and patterns
        switch contentType {
        case .sessionNotes, .technicalLog:
            return .informative
        case .tutorial, .checkList:
            return .instructional
        case .troubleshooting:
            return .troubleshooting
        case .reference, .specification:
            return .reference
        case .clientCommunication:
            if lowercaseContent.contains("decision") || lowercaseContent.contains("approve") {
                return .decisionMaking
            } else {
                return .communication
            }
        case .projectDocumentation:
            return .documentation
        default:
            return .informative
        }
    }

    /// Gets purpose suggestions with confidence scores
    /// - Parameters:
    ///   - content: Content to analyze
    ///   - contentType: Detected content type
    ///   - maxSuggestions: Maximum number of suggestions
    /// - Returns: Array of purpose suggestions with confidence scores
    public func getPurposeSuggestions(
        content: String,
        contentType: ContentType,
        maxSuggestions: Int = 3
    ) -> [(ContentPurpose, Double)] {
        let lowercaseContent = content.lowercased()
        var purposeScores: [ContentPurpose: Double] = [:]

        // Score based on keyword patterns
        for purpose in ContentPurpose.allCases {
            let score = calculatePurposeScore(content: lowercaseContent, purpose: purpose, contentType: contentType)
            purposeScores[purpose] = score
        }

        // Sort by score and return top suggestions
        let sortedScores = purposeScores.sorted { $0.value > $1.value }
        return Array(sortedScores.prefix(maxSuggestions))
    }

    /// Determines actionability level of content
    /// - Parameters:
    ///   - content: Content to analyze
    ///   - purpose: Detected purpose
    /// - Returns: Actionability level
    public func determineActionability(content: String, purpose: ContentPurpose) -> ActionabilityLevel {
        let lowercaseContent = content.lowercased()

        // Check for immediate action indicators
        let immediateActions = ["urgent", "asap", "immediately", "right away", "now", "emergency"]
        let scheduledActions = ["schedule", "tomorrow", "next week", "deadline", "due", "meeting"]
        let conditionalActions = ["if", "when", "in case", "should", "provided that"]

        if immediateActions.contains(where: lowercaseContent.contains) {
            return .immediateAction
        } else if scheduledActions.contains(where: lowercaseContent.contains) {
            return .scheduledAction
        } else if conditionalActions.contains(where: lowercaseContent.contains) {
            return .conditionalAction
        }

        // Determine based on purpose
        switch purpose {
        case .instructional:
            return .conditionalAction
        case .troubleshooting:
            return .immediateAction
        case .reference, .archival:
            return .referenceOnly
        case .communication:
            return .informational
        default:
            return .referenceOnly
        }
    }

    /// Identifies target audience for content
    /// - Parameters:
    ///   - content: Content to analyze
    ///   - context: Additional context information
    /// - Returns: Target audience
    public func identifyAudience(content: String, context: [String: Any]) -> TargetAudience {
        // Check context for explicit audience
        if let audienceString = context["author_role"] as? String,
           let audience = TargetAudience(rawValue: audienceString.lowercased()) {
            return audience
        }

        let lowercaseContent = content.lowercased()

        // Analyze content for audience indicators
        if lowercaseContent.contains("client") || lowercaseContent.contains("customer") {
            return .client
        } else if lowercaseContent.contains("student") || lowercaseContent.contains("learn") {
            return .student
        } else if lowercaseContent.contains("producer") || lowercaseContent.contains("creative") {
            return .producer
        } else if lowercaseContent.contains("musician") || lowercaseContent.contains("performer") {
            return .musician
        } else if lowercaseContent.contains("technical") || lowercaseContent.contains("engineering") {
            return .engineer
        }

        return .general // Default audience
    }

    /// Identifies workflow stage for content
    /// - Parameters:
    ///   - content: Content to analyze
    ///   - context: Additional context information
    /// - Returns: Workflow stage if determinable
    public func identifyWorkflowStage(content: String, context: [String: Any]) -> WorkflowStage? {
        // Check context for explicit workflow stage
        if let stageString = context["workflow_stage"] as? String,
           let stage = WorkflowStage(rawValue: stageString.lowercased()) {
            return stage
        }

        let lowercaseContent = content.lowercased()

        // Analyze content for workflow stage indicators
        if lowercaseContent.contains("record") || lowercaseContent.contains("tracking") {
            return .recording
        } else if lowercaseContent.contains("mix") || lowercaseContent.contains("balance") {
            return .mixing
        } else if lowercaseContent.contains("master") || lowercaseContent.contains("final") {
            return .mastering
        } else if lowercaseContent.contains("edit") || lowercaseContent.contains("comp") {
            return .editing
        } else if lowercaseContent.contains("plan") || lowercaseContent.contains("prepare") {
            return .planning
        } else if lowercaseContent.contains("deliver") || lowercaseContent.contains("export") {
            return .delivery
        }

        return nil // Unable to determine
    }

    // MARK: - Private Helper Methods

    /// Calculates purpose score based on content patterns
    /// - Parameters:
    ///   - content: Lowercase content
    ///   - purpose: Purpose to score
    ///   - contentType: Content type
    /// - Returns: Purpose score (0.0-1.0)
    private func calculatePurposeScore(content: String, purpose: ContentPurpose, contentType: ContentType) -> Double {
        var score: Double = 0.0

        // Content type base scoring
        switch contentType {
        case .sessionNotes, .technicalLog:
            score += purpose == .informative ? 0.7 : 0.1
        case .tutorial, .checkList:
            score += purpose == .instructional ? 0.7 : 0.1
        case .troubleshooting:
            score += purpose == .troubleshooting ? 0.7 : 0.1
        case .reference, .specification:
            score += purpose == .reference ? 0.7 : 0.1
        case .clientCommunication:
            score += (purpose == .communication || purpose == .decisionMaking) ? 0.6 : 0.1
        case .projectDocumentation:
            score += purpose == .documentation ? 0.7 : 0.1
        default:
            break
        }

        // Keyword-based scoring
        let keywords = getPurposeKeywords(purpose)
        let matches = keywords.filter { content.contains($0) }.count
        score += Double(matches) * 0.1

        return min(score, 1.0)
    }

    /// Gets keywords associated with a purpose
    /// - Parameter purpose: Purpose to get keywords for
    /// - Returns: Array of keywords
    private func getPurposeKeywords(_ purpose: ContentPurpose) -> [String] {
        switch purpose {
        case .informative:
            return ["information", "update", "status", "progress", "report"]
        case .instructional:
            return ["how to", "guide", "instructions", "steps", "learn"]
        case .troubleshooting:
            return ["problem", "issue", "error", "fix", "solution"]
        case .reference:
            return ["reference", "information", "data", "lookup"]
        case .archival:
            return ["archive", "history", "record", "preserve"]
        case .decisionMaking:
            return ["decision", "approve", "choose", "select", "determine"]
        case .communication:
            return ["message", "feedback", "discussion", "communicate"]
        case .planning:
            return ["plan", "schedule", "organize", "prepare"]
        case .evaluation:
            return ["evaluate", "assess", "review", "critique"]
        case .documentation:
            return ["document", "specify", "detail", "procedure"]
        }
    }
}

// MARK: - Supporting Types

/// Content type validation result
public struct ContentTypeValidation {
    public let contentType: ContentType
    public let confidence: Double
    public let matchedPatterns: [String]
    public let matchedStructures: [String]
    public let reasoning: [String]

    public init(
        contentType: ContentType,
        confidence: Double,
        matchedPatterns: [String],
        matchedStructures: [String],
        reasoning: [String]
    ) {
        self.contentType = contentType
        self.confidence = confidence
        self.matchedPatterns = matchedPatterns
        self.matchedStructures = matchedStructures
        self.reasoning = reasoning
    }
}