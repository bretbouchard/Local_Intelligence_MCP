//
//  ContentPurposeDetector.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-09.
//

import Foundation
import AnyCodable

/// Content Purpose Detector for Audio Session Analysis
///
/// Advanced content analysis tool that detects the purpose, intent, and context behind
/// audio session content including notes, transcripts, logs, and documentation. Provides
/// comprehensive analysis of content type, target audience, actionability, and workflow stage.
///
/// Content Classification:
/// - Session types (recording, mixing, mastering, editing, planning)
/// - Document types (notes, transcripts, logs, technical docs, client communications)
/// - Purpose categories (informative, instructional, troubleshooting, reference, archival)
/// - Actionability levels (immediate action, scheduled action, reference only, archival)
/// - Target audiences (engineer, producer, client, musician, educational)
///
/// Audio Domain Intelligence:
/// - Workflow stage detection (pre-production, tracking, mixing, mastering, delivery)
/// - Technical complexity assessment (beginner, intermediate, advanced, professional)
/// - Equipment and software context extraction
/// - Session role identification (engineer notes, client feedback, technical specs)
/// - Priority and urgency assessment
///
/// Business Context Analysis:
/// - Commercial vs. personal project identification
/// - Client communication detection
/// - Budget and timeline mentions
/// - Decision points and approvals
/// - Project phase progression tracking
///
/// Performance Requirements:
/// - Execution: <200ms for comprehensive content analysis
/// - Memory: <3MB for classification models and context analysis
/// - Accuracy: >90% for content type and purpose detection
/// - Scalability: Support for documents up to 10,000 words
public final class ContentPurposeDetector: AudioDomainTool, @unchecked Sendable {

    // MARK: - Analysis Components

    private let contentClassificationAnalyzer: ContentClassificationAnalyzer
    private let technicalComplexityAnalyzer: TechnicalComplexityAnalyzer
    private let businessContextAnalyzer: BusinessContextAnalyzer
    private let qualityAssessor: QualityAssessor
    private let entityExtractor: ContentEntityExtractor
    private let sentimentAnalyzer: SentimentAnalyzer
    private let urgencyAnalyzer: UrgencyAnalyzer

    // MARK: - Initialization

    init(logger: Logger, securityManager: SecurityManager) {
        self.contentClassificationAnalyzer = ContentClassificationAnalyzer()
        self.technicalComplexityAnalyzer = TechnicalComplexityAnalyzer()
        self.businessContextAnalyzer = BusinessContextAnalyzer()
        self.qualityAssessor = QualityAssessor()
        self.entityExtractor = ContentEntityExtractor()
        self.sentimentAnalyzer = SentimentAnalyzer()
        self.urgencyAnalyzer = UrgencyAnalyzer()

        let inputSchema: [String: AnyCodable] = [
            "type": AnyCodable("object"),
            "properties": AnyCodable([
                "content": AnyCodable([
                    "type": AnyCodable("string"),
                    "description": AnyCodable("Audio session content to analyze (notes, transcripts, logs, documentation)"),
                    "minLength": AnyCodable(50),
                    "maxLength": AnyCodable(50000),
                    "examples": AnyCodable([
                        "Session Notes: Today we recorded lead vocals using Neumann U87 through API 312 preamp. Client was happy with take 3. Applied gentle EQ with 2kHz boost.",
                        "Technical Log: SSL G+ Console, Pro Tools HD, 96kHz/24-bit. Used Waves CLA-76 compressor with 4:1 ratio, -18dB threshold.",
                        "Client Email: Hi team, I've reviewed the latest mix and overall it sounds great. Could we add a bit more presence to the vocals?"
                    ])
                ]),
                "content_hint": AnyCodable([
                    "type": AnyCodable("string"),
                    "description": AnyCodable("Hint about the content type to improve classification accuracy"),
                    "enum": AnyCodable(["session_notes", "transcript", "technical_log", "client_communication", "other"])
                ]),
                "context": AnyCodable([
                    "type": AnyCodable("object"),
                    "description": AnyCodable("Additional context about the content"),
                    "properties": AnyCodable([
                        "author_role": AnyCodable([
                            "type": AnyCodable("string"),
                            "description": AnyCodable("Role of the content author (engineer, producer, client, etc.)")
                        ]),
                        "project_type": AnyCodable([
                            "type": AnyCodable("string"),
                            "description": AnyCodable("Type of audio project")
                        ]),
                        "workflow_stage": AnyCodable([
                            "type": AnyCodable("string"),
                            "enum": AnyCodable(WorkflowStage.allCases.map(\.rawValue)),
                            "description": AnyCodable("Current workflow stage of the project")
                        ])
                    ])
                ]),
                "analysis_depth": AnyCodable([
                    "type": AnyCodable("string"),
                    "description": AnyCodable("Depth of analysis to perform"),
                    "enum": AnyCodable(["basic", "standard", "comprehensive"]),
                    "default": AnyCodable("standard")
                ]),
                "include_quality_assessment": AnyCodable([
                    "type": AnyCodable("boolean"),
                    "description": AnyCodable("Include quality assessment of the content"),
                    "default": AnyCodable(true)
                ]),
                "include_business_context": AnyCodable([
                    "type": AnyCodable("boolean"),
                    "description": AnyCodable("Include business context analysis"),
                    "default": AnyCodable(true)
                ])
            ]),
            "required": AnyCodable(["content"])
        ]

        super.init(
            name: "apple_content_purpose",
            description: "Detects purpose, intent, and context behind audio session content with comprehensive classification and analysis.",
            inputSchema: inputSchema,
            logger: logger,
            securityManager: securityManager
        )
    }

    // MARK: - Audio Processing

    /// Analyze content purpose and characteristics
    public override func processAudioContent(_ content: String, with parameters: [String: Any]) async throws -> String {
        let textContent = content

        // Parse parameters
        let contentHint = parameters["content_hint"] as? String
        let context = parameters["context"] as? [String: Any] ?? [:]
        let analysisDepth = parameters["analysis_depth"] as? String ?? "standard"
        let includeQualityAssessment = parameters["include_quality_assessment"] as? Bool ?? true
        let includeBusinessContext = parameters["include_business_context"] as? Bool ?? true

        // Pre-security check
        try await performSecurityCheck(textContent)

        // Perform comprehensive analysis
        let result = try await analyzeContentPurpose(
            content: textContent,
            contentHint: contentHint,
            context: context,
            analysisDepth: analysisDepth,
            includeQualityAssessment: includeQualityAssessment,
            includeBusinessContext: includeBusinessContext
        )

        // Post-security validation
        try await validateOutput(result)

        return result
    }

    // MARK: - Private Implementation

    /// Perform comprehensive content purpose analysis
    private func analyzeContentPurpose(
        content: String,
        contentHint: String?,
        context: [String: Any],
        analysisDepth: String,
        includeQualityAssessment: Bool,
        includeBusinessContext: Bool
    ) async throws -> String {

        // Step 1: Content type classification and purpose analysis
        let contentType = contentClassificationAnalyzer.classifyContentType(
            content: content,
            hint: contentHint,
            context: context
        )

        // Step 2: Purpose analysis using the content classification analyzer
        let purpose = contentClassificationAnalyzer.purposeAnalyzer.analyzePurpose(content: content, contentType: contentType)
        let actionability = contentClassificationAnalyzer.purposeAnalyzer.determineActionability(content: content, purpose: purpose)
        let audience = contentClassificationAnalyzer.purposeAnalyzer.identifyAudience(content: content, context: context)
        let workflowStage = contentClassificationAnalyzer.purposeAnalyzer.identifyWorkflowStage(content: content, context: context)

        // Step 3: Technical complexity analysis
        let technicalComplexity = technicalComplexityAnalyzer.analyzeComplexity(content: content)

        // Step 4: Business context analysis
        let businessContext = includeBusinessContext ?
            businessContextAnalyzer.analyzeBusinessContext(content: content, context: context) :
            BusinessContext(
                projectType: .personal,
                commercialNature: .personal,
                clientInvolvement: .none
            )

        // Step 5: Quality assessment
        let qualityIndicators = includeQualityAssessment ?
            qualityAssessor.assessQuality(content: content, contentType: contentType) :
            QualityIndicators(
                completeness: 0.5,
                clarity: 0.5,
                organization: 0.5,
                technicalAccuracy: 0.5
            )

        // Step 6: Entity extraction
        let entities = entityExtractor.extractEntities(content: content)

        // Step 7: Key phrase extraction
        let keyPhrases = extractKeyPhrases(content: content)

        // Step 8: Sentiment analysis
        let sentiment = sentimentAnalyzer.analyzeSentiment(content: content)

        // Step 9: Urgency assessment
        let urgency = urgencyAnalyzer.assessUrgency(content: content, entities: entities)

        // Step 10: Compile result
        let result = ContentPurposeResult(
            contentType: contentType,
            purpose: purpose,
            actionability: actionability,
            audience: audience,
            workflowStage: workflowStage,
            technicalComplexity: technicalComplexity,
            businessContext: businessContext,
            qualityIndicators: qualityIndicators,
            entities: entities,
            keyPhrases: keyPhrases,
            sentiment: sentiment,
            urgency: urgency,
            metadata: [
                "analysis_depth": AnyCodable(analysisDepth),
                "content_length": AnyCodable(content.count),
                "word_count": AnyCodable(content.split(separator: " ").count),
                "content_hint": AnyCodable(contentHint ?? "none"),
                "analysis_timestamp": AnyCodable(Date().timeIntervalSince1970)
            ]
        )

        await logger.info(
            "Content purpose analysis completed",
            metadata: [
                "content_type": result.contentType.rawValue,
                "purpose": result.purpose.rawValue,
                "actionability": result.actionability.rawValue,
                "audience": result.audience.rawValue,
                "technical_complexity": result.technicalComplexity.level.rawValue,
                "urgency_level": result.urgency.urgencyLevel
            ]
        )

        // Convert to JSON string
        return try String(data: JSONEncoder().encode(result), encoding: .utf8) ??
               "{\"error\":\"Failed to encode analysis result\"}"
    }

    /// Extract key phrases from content
    private func extractKeyPhrases(content: String) -> [String] {
        let words = content.lowercased().components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty && $0.count > 3 }

        // Simple keyword frequency analysis
        var wordFrequency: [String: Int] = [:]
        for word in words {
            wordFrequency[word, default: 0] += 1
        }

        // Filter and sort by frequency
        let filteredWords = wordFrequency.filter { $0.value >= 2 }
        let sortedWords = filteredWords.sorted { $0.value > $1.value }

        // Return top key phrases
        return Array(sortedWords.prefix(10)).map { $0.key }
    }

    // MARK: - Security

    /// Validates input for security compliance
    private func performSecurityCheck(_ content: String) async throws {
        do {
            try TextValidationUtils.validateText(content)
            try TextValidationUtils.validateTextSecurity(content)
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
}

// MARK: - Analysis Components

/// Classifies content types based on patterns and structure
private class ContentTypeClassifier {

    private let typePatterns: [ContentPurposeDetector.ContentType: [String]]
    private let structureIndicators: [ContentPurposeDetector.ContentType: [String]]

    init() {
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

    func classifyContentType(content: String, hint: String?, context: [String: Any]) -> ContentPurposeDetector.ContentType {
        // Use hint if provided
        if let hint = hint, let contentType = ContentPurposeDetector.ContentType(rawValue: hint) {
            return contentType
        }

        let lowercaseContent = content.lowercased()
        var typeScores: [ContentPurposeDetector.ContentType: Double] = [:]

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
}

// MARK: - Content Purpose Detector Nested Types

extension ContentPurposeDetector {

    /// Content types that can be classified
    public enum ContentType: String, CaseIterable, Codable {
        case sessionNotes = "session_notes"
        case transcript = "transcript"
        case technicalLog = "technical_log"
        case clientCommunication = "client_communication"
        case projectDocumentation = "project_documentation"
        case troubleshooting = "troubleshooting"
        case reference = "reference"
        case tutorial = "tutorial"
        case checkList = "check_list"
        case meetingNotes = "meeting_notes"
        case email = "email"
        case chatLog = "chat_log"
        case specification = "specification"
        case review = "review"
        case feedback = "feedback"
    }

    /// Content purpose categories
    public enum ContentPurpose: String, CaseIterable, Codable {
        case informative = "informative"
        case instructional = "instructional"
        case troubleshooting = "troubleshooting"
        case reference = "reference"
        case documentation = "documentation"
        case communication = "communication"
        case decisionMaking = "decision_making"
        case archival = "archival"
    }

    /// Actionability levels for content
    public enum ActionabilityLevel: String, CaseIterable, Codable {
        case immediateAction = "immediate_action"
        case scheduledAction = "scheduled_action"
        case conditionalAction = "conditional_action"
        case informational = "informational"
        case referenceOnly = "reference_only"
    }

    /// Target audience for content
    public enum TargetAudience: String, CaseIterable, Codable {
        case engineer = "engineer"
        case producer = "producer"
        case client = "client"
        case musician = "musician"
        case student = "student"
        case general = "general"
        case technical = "technical"
        case creative = "creative"
    }

    /// Workflow stages in audio production
    public enum WorkflowStage: String, CaseIterable, Codable {
        case planning = "planning"
        case recording = "recording"
        case editing = "editing"
        case mixing = "mixing"
        case mastering = "mastering"
        case delivery = "delivery"
        case review = "review"
    }

    /// Technical complexity levels
    public enum ComplexityLevel: String, CaseIterable, Codable {
        case basic = "basic"
        case intermediate = "intermediate"
        case advanced = "advanced"
        case professional = "professional"
        case expert = "expert"
    }

    /// Project types
    public enum ProjectType: String, CaseIterable, Codable {
        case musicProduction = "music_production"
        case postProduction = "post_production"
        case gameAudio = "game_audio"
        case podcast = "podcast"
        case liveSound = "live_sound"
        case broadcast = "broadcast"
        case commercial = "commercial"
        case educational = "educational"
        case personal = "personal"
    }

    /// Commercial nature
    public enum CommercialNature: String, CaseIterable, Codable {
        case commercial = "commercial"
        case nonProfit = "non_profit"
        case research = "research"
        case internalProject = "internal"
        case personal = "personal"
    }

    /// Client involvement levels
    public enum ClientInvolvement: String, CaseIterable, Codable {
        case none = "none"
        case low = "low"
        case medium = "medium"
        case high = "high"
        case critical = "critical"
    }

    /// Decision status
    public enum DecisionStatus: String, CaseIterable, Codable {
        case pending = "pending"
        case approved = "approved"
        case rejected = "rejected"
        case deferred = "deferred"
    }

    /// Entity types
    public enum EntityType: String, CaseIterable, Codable {
        case person = "person"
        case organization = "organization"
        case location = "location"
        case money = "money"
        case date = "date"
        case time = "time"
        case equipment = "equipment"
        case software = "software"
    }

    /// Emotional tone
    public enum EmotionalTone: String, CaseIterable, Codable {
        case positive = "positive"
        case negative = "negative"
        case neutral = "neutral"
    }

    /// Professionalism level
    public enum ProfessionalismLevel: String, CaseIterable, Codable {
        case professional = "professional"
        case semiFormal = "semi_formal"
        case casual = "casual"
    }

    /// Priority levels
    public enum Priority: String, CaseIterable, Codable {
        case urgent = "urgent"
        case high = "high"
        case medium = "medium"
        case low = "low"
    }

    /// Time sensitivity
    public enum TimeSensitivity: String, CaseIterable, Codable {
        case immediate = "immediate"
        case sameDay = "same_day"
        case nextWeek = "next_week"
        case thisWeek = "this_week"
        case routine = "routine"
    }
}
