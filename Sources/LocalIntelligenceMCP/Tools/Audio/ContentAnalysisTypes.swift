//
//  ContentAnalysisTypes.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-09.
//

import Foundation

// MARK: - Core Content Types

/// Types of audio session content
public enum ContentType: String, CaseIterable, Codable, Sendable {
    case sessionNotes = "session_notes"
    case transcript = "transcript"
    case technicalLog = "technical_log"
    case clientCommunication = "client_communication"
    case projectDocumentation = "project_documentation"
    case troubleshooting = "troubleshooting"
    case reference = "reference"
    case tutorial = "tutorial"
    case checkList = "checklist"
    case meetingNotes = "meeting_notes"
    case email = "email"
    case chatLog = "chat_log"
    case specification = "specification"
    case review = "review"
    case feedback = "feedback"

    var description: String {
        switch self {
        case .sessionNotes: return "Informal notes taken during recording or mixing sessions"
        case .transcript: return "Word-for-word transcription of audio content or conversations"
        case .technicalLog: return "Detailed technical specifications, settings, and parameters"
        case .clientCommunication: return "Communication with clients about project progress and decisions"
        case .projectDocumentation: return "Formal project documentation and specifications"
        case .troubleshooting: return "Problem-solving logs and issue resolution documentation"
        case .reference: return "Reference material for future use or consultation"
        case .tutorial: return "Educational content explaining processes or techniques"
        case .checkList: return "Task lists and procedural checklists"
        case .meetingNotes: return "Notes from meetings and discussions"
        case .email: return "Email correspondence related to audio projects"
        case .chatLog: return "Instant messaging or chat transcripts"
        case .specification: return "Technical specifications and requirements"
        case .review: return "Critical assessment and evaluation of audio work"
        case .feedback: return "Feedback and commentary on audio content or sessions"
        }
    }
}

/// Primary purpose of the content
public enum ContentPurpose: String, CaseIterable, Codable, Sendable {
    case informative = "informative"
    case instructional = "instructional"
    case troubleshooting = "troubleshooting"
    case reference = "reference"
    case archival = "archival"
    case decisionMaking = "decision_making"
    case communication = "communication"
    case planning = "planning"
    case evaluation = "evaluation"
    case documentation = "documentation"

    var description: String {
        switch self {
        case .informative: return "Provides information and updates about status or progress"
        case .instructional: return "Teaches or explains how to perform specific tasks"
        case .troubleshooting: return "Addresses problems and provides solutions"
        case .reference: return "Serves as reference material for future consultation"
        case .archival: return "Preserves information for historical record"
        case .decisionMaking: return "Supports decision-making processes"
        case .communication: return "Facilitates communication between stakeholders"
        case .planning: return "Supports planning and organization of work"
        case .evaluation: return "Provides assessment and critique of work"
        case .documentation: return "Documents processes, procedures, or specifications"
        }
    }
}

/// Actionability level of the content
public enum ActionabilityLevel: String, CaseIterable, Codable, Sendable {
    case immediateAction = "immediate_action"
    case scheduledAction = "scheduled_action"
    case conditionalAction = "conditional_action"
    case referenceOnly = "reference_only"
    case archival = "archival"
    case informational = "informational"

    var description: String {
        switch self {
        case .immediateAction: return "Requires immediate action or response"
        case .scheduledAction: return "Requires action at a specific future time"
        case .conditionalAction: return "Action required if certain conditions are met"
        case .referenceOnly: return "For reference only, no action required"
        case .archival: return "For archival purposes only"
        case .informational: return "Purely informational, no action needed"
        }
    }

    var priorityScore: Double {
        switch self {
        case .immediateAction: return 1.0
        case .scheduledAction: return 0.8
        case .conditionalAction: return 0.6
        case .referenceOnly: return 0.3
        case .informational: return 0.2
        case .archival: return 0.1
        }
    }
}

// MARK: - Target and Workflow Types

/// Target audience for the content
public enum TargetAudience: String, CaseIterable, Codable, Sendable {
    case engineer = "engineer"
    case producer = "producer"
    case client = "client"
    case musician = "musician"
    case student = "student"
    case technician = "technician"
    case manager = "manager"
    case general = "general"
    case legal = "legal"
    case archivist = "archivist"

    var description: String {
        switch self {
        case .engineer: return "Audio engineers and technical staff"
        case .producer: return "Producers and creative directors"
        case .client: return "Clients and stakeholders"
        case .musician: return "Musicians and performers"
        case .student: return "Students and learners"
        case .technician: return "Technical support and maintenance staff"
        case .manager: return "Project and business managers"
        case .general: return "General audience with mixed backgrounds"
        case .legal: return "Legal and compliance personnel"
        case .archivist: return "Archivists and documentation specialists"
        }
    }
}

/// Workflow stages in audio production
public enum WorkflowStage: String, CaseIterable, Codable, Sendable {
    case preProduction = "pre_production"
    case recording = "recording"
    case editing = "editing"
    case mixing = "mixing"
    case mastering = "mastering"
    case delivery = "delivery"
    case archival = "archival"
    case review = "review"
    case planning = "planning"
    case troubleshooting = "troubleshooting"

    var description: String {
        switch self {
        case .preProduction: return "Planning and preparation before recording"
        case .recording: return "Capturing audio performances"
        case .editing: return "Editing and arranging recorded audio"
        case .mixing: return "Balancing and processing audio tracks"
        case .mastering: return "Final processing and preparation for distribution"
        case .delivery: return "Final delivery to client or distribution channels"
        case .archival: return "Long-term storage and preservation"
        case .review: return "Quality control and review processes"
        case .planning: return "Project planning and organization"
        case .troubleshooting: return "Problem-solving and maintenance"
        }
    }
}

// MARK: - Complexity and Technical Types

/// Complexity levels
public enum ComplexityLevel: String, CaseIterable, Codable, Sendable {
    case basic = "basic"
    case intermediate = "intermediate"
    case advanced = "advanced"
    case professional = "professional"
    case expert = "expert"

    var description: String {
        switch self {
        case .basic: return "Simple concepts, minimal technical terminology"
        case .intermediate: return "Some technical terms and concepts"
        case .advanced: return "Complex technical concepts and terminology"
        case .professional: return "Industry-standard technical language"
        case .expert: return "Highly specialized technical content"
        }
    }
}

/// Technical complexity assessment
public struct TechnicalComplexity: Codable, Sendable {
    /// Overall complexity level
    public let level: ComplexityLevel

    /// Technical terms found
    public let technicalTerms: [String]

    /// Equipment mentioned
    public let equipment: [String]

    /// Software mentioned
    public let software: [String]

    /// Parameter specifications
    public let parameters: [String: String]

    /// Complexity score (0.0-1.0)
    public let complexityScore: Double

    public init(
        level: ComplexityLevel,
        technicalTerms: [String] = [],
        equipment: [String] = [],
        software: [String] = [],
        parameters: [String: String] = [:],
        complexityScore: Double
    ) {
        self.level = level
        self.technicalTerms = technicalTerms
        self.equipment = equipment
        self.software = software
        self.parameters = parameters
        self.complexityScore = complexityScore
    }
}

// MARK: - Business Context Types

/// Project types
public enum ProjectType: String, CaseIterable, Codable, Sendable {
    case musicProduction = "music_production"
    case postProduction = "post_production"
    case liveSound = "live_sound"
    case broadcast = "broadcast"
    case corporate = "corporate"
    case educational = "educational"
    case gameAudio = "game_audio"
    case filmAudio = "film_audio"
    case podcast = "podcast"
    case commercial = "commercial"
    case personal = "personal"
    case archival = "archival"

    var description: String {
        switch self {
        case .musicProduction: return "Music recording and production projects"
        case .postProduction: return "Film/video post-production and sound design"
        case .liveSound: return "Live event sound reinforcement"
        case .broadcast: return "Radio and television broadcasting"
        case .corporate: return "Corporate and business audio projects"
        case .educational: return "Educational and training content"
        case .gameAudio: return "Video game audio development"
        case .filmAudio: return "Feature film audio production"
        case .podcast: return "Podcast production and distribution"
        case .commercial: return "Commercial advertising and marketing"
        case .personal: return "Personal projects and experiments"
        case .archival: return "Audio restoration and archival projects"
        }
    }
}

/// Commercial nature
public enum CommercialNature: String, CaseIterable, Codable, Sendable {
    case commercial = "commercial"
    case nonProfit = "non_profit"
    case personal = "personal"
    case educational = "educational"
    case research = "research"
    case `internal` = "internal"

    var description: String {
        switch self {
        case .commercial: return "Commercial for-profit project"
        case .nonProfit: return "Non-profit or charitable project"
        case .personal: return "Personal project or experiment"
        case .educational: return "Educational or academic project"
        case .research: return "Research or experimental project"
        case .internal: return "Internal company project"
        }
    }
}

/// Client involvement level
public enum ClientInvolvement: String, CaseIterable, Codable, Sendable {
    case none = "none"
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"

    var description: String {
        switch self {
        case .none: return "No client involvement"
        case .low: return "Minimal client interaction"
        case .medium: return "Regular client communication"
        case .high: return "Frequent client collaboration"
        case .critical: return "Client-driven project with constant feedback"
        }
    }
}

/// Business context analysis
public struct BusinessContext: Codable, Sendable {
    /// Project type
    public let projectType: ProjectType

    /// Commercial vs. personal
    public let commercialNature: CommercialNature

    /// Client involvement
    public let clientInvolvement: ClientInvolvement

    /// Budget mentions
    public let budgetMentions: [String]

    /// Timeline mentions
    public let timelineMentions: [String]

    /// Decision points
    public let decisionPoints: [DecisionPoint]

    /// Stakeholders mentioned
    public let stakeholders: [String]

    public init(
        projectType: ProjectType,
        commercialNature: CommercialNature,
        clientInvolvement: ClientInvolvement,
        budgetMentions: [String] = [],
        timelineMentions: [String] = [],
        decisionPoints: [DecisionPoint] = [],
        stakeholders: [String] = []
    ) {
        self.projectType = projectType
        self.commercialNature = commercialNature
        self.clientInvolvement = clientInvolvement
        self.budgetMentions = budgetMentions
        self.timelineMentions = timelineMentions
        self.decisionPoints = decisionPoints
        self.stakeholders = stakeholders
    }
}

/// Decision point in project
public struct DecisionPoint: Codable, Sendable {
    public let description: String
    public let urgency: String?
    public let stakeholders: [String]
    public let status: DecisionStatus

    public init(description: String, urgency: String? = nil, stakeholders: [String] = [], status: DecisionStatus) {
        self.description = description
        self.urgency = urgency
        self.stakeholders = stakeholders
        self.status = status
    }
}

/// Decision status
public enum DecisionStatus: String, CaseIterable, Codable, Sendable {
    case pending = "pending"
    case approved = "approved"
    case rejected = "rejected"
    case deferred = "deferred"
    case underReview = "under_review"
}

// MARK: - Quality Assessment Types

/// Priority levels
public enum Priority: String, CaseIterable, Codable, Sendable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case urgent = "urgent"
    case critical = "critical"

    var score: Double {
        switch self {
        case .low: return 0.2
        case .medium: return 0.4
        case .high: return 0.6
        case .urgent: return 0.8
        case .critical: return 1.0
        }
    }
}

/// Content quality indicators
public struct QualityIndicators: Codable, Sendable {
    /// Completeness score (0.0-1.0)
    public let completeness: Double

    /// Clarity score (0.0-1.0)
    public let clarity: Double

    /// Organization score (0.0-1.0)
    public let organization: Double

    /// Technical accuracy score (0.0-1.0)
    public let technicalAccuracy: Double

    /// Action items identified
    public let actionItems: [ActionItem]

    /// Follow-up requirements
    public let followUpRequirements: [String]

    public init(
        completeness: Double,
        clarity: Double,
        organization: Double,
        technicalAccuracy: Double,
        actionItems: [ActionItem] = [],
        followUpRequirements: [String] = []
    ) {
        self.completeness = completeness
        self.clarity = clarity
        self.organization = organization
        self.technicalAccuracy = technicalAccuracy
        self.actionItems = actionItems
        self.followUpRequirements = followUpRequirements
    }
}

/// Action item identified in content
public struct ActionItem: Codable, Sendable {
    public let description: String
    public let assignee: String?
    public let deadline: String?
    public let priority: Priority
    public let category: String?

    public init(description: String, assignee: String? = nil, deadline: String? = nil, priority: Priority, category: String? = nil) {
        self.description = description
        self.assignee = assignee
        self.deadline = deadline
        self.priority = priority
        self.category = category
    }
}

// MARK: - Entity and Sentiment Types

/// Entity types
public enum EntityType: String, CaseIterable, Codable, Sendable {
    case person = "person"
    case equipment = "equipment"
    case software = "software"
    case project = "project"
    case location = "location"
    case organization = "organization"
    case date = "date"
    case time = "time"
    case money = "money"
    case technicalTerm = "technical_term"
    case actionItem = "action_item"
    case decision = "decision"
    case deadline = "deadline"
}

/// Content entity
public struct ContentEntity: Codable, Sendable {
    public let text: String
    public let type: EntityType
    public let confidence: Double
    public let context: String?

    public init(text: String, type: EntityType, confidence: Double, context: String? = nil) {
        self.text = text
        self.type = type
        self.confidence = confidence
        self.context = context
    }
}

/// Emotional tones
public enum EmotionalTone: String, CaseIterable, Codable, Sendable {
    case neutral = "neutral"
    case positive = "positive"
    case negative = "negative"
    case excited = "excited"
    case concerned = "concerned"
    case frustrated = "frustrated"
    case satisfied = "satisfied"
    case confused = "confused"
    case confident = "confident"
    case anxious = "anxious"
}

/// Professionalism levels
public enum ProfessionalismLevel: String, CaseIterable, Codable, Sendable {
    case highlyProfessional = "highly_professional"
    case professional = "professional"
    case semiFormal = "semi_formal"
    case casual = "casual"
    case informal = "informal"
}

/// Sentiment analysis
public struct SentimentAnalysis: Codable, Sendable {
    /// Overall sentiment (-1.0 to 1.0)
    public let sentiment: Double

    /// Confidence in sentiment analysis (0.0-1.0)
    public let confidence: Double

    /// Emotional tone
    public let emotionalTone: EmotionalTone

    /// Professionalism level
    public let professionalism: ProfessionalismLevel

    public init(sentiment: Double, confidence: Double, emotionalTone: EmotionalTone, professionalism: ProfessionalismLevel) {
        self.sentiment = sentiment
        self.confidence = confidence
        self.emotionalTone = emotionalTone
        self.professionalism = professionalism
    }
}

// MARK: - Urgency Types

/// Time sensitivity
public enum TimeSensitivity: String, CaseIterable, Codable, Sendable {
    case immediate = "immediate"
    case sameDay = "same_day"
    case thisWeek = "this_week"
    case nextWeek = "next_week"
    case thisMonth = "this_month"
    case routine = "routine"
    case noDeadline = "no_deadline"
}

/// Urgency assessment
public struct UrgencyAssessment: Codable, Sendable {
    /// Urgency level (0.0-1.0)
    public let urgencyLevel: Double

    /// Time sensitivity
    public let timeSensitivity: TimeSensitivity

    /// Response timeframe
    public let responseTimeframe: String?

    /// Critical issues identified
    public let criticalIssues: [String]

    public init(
        urgencyLevel: Double,
        timeSensitivity: TimeSensitivity,
        responseTimeframe: String? = nil,
        criticalIssues: [String] = []
    ) {
        self.urgencyLevel = urgencyLevel
        self.timeSensitivity = timeSensitivity
        self.responseTimeframe = responseTimeframe
        self.criticalIssues = criticalIssues
    }
}

// MARK: - Main Result Type

/// Comprehensive content purpose analysis result
public struct ContentPurposeResult: Codable, Sendable {
    /// Detected content type
    public let contentType: ContentType

    /// Primary purpose of content
    public let purpose: ContentPurpose

    /// Actionability level
    public let actionability: ActionabilityLevel

    /// Target audience
    public let audience: TargetAudience

    /// Workflow stage
    public let workflowStage: WorkflowStage?

    /// Technical complexity level
    public let technicalComplexity: TechnicalComplexity

    /// Business context
    public let businessContext: BusinessContext

    /// Content quality indicators
    public let qualityIndicators: QualityIndicators

    /// Extracted entities and context
    public let entities: [ContentEntity]

    /// Key phrases and topics
    public let keyPhrases: [String]

    /// Sentiment analysis
    public let sentiment: SentimentAnalysis

    /// Urgency assessment
    public let urgency: UrgencyAssessment

    /// Processing metadata
    public let metadata: [String: AnyCodable]

    public init(
        contentType: ContentType,
        purpose: ContentPurpose,
        actionability: ActionabilityLevel,
        audience: TargetAudience,
        workflowStage: WorkflowStage? = nil,
        technicalComplexity: TechnicalComplexity,
        businessContext: BusinessContext,
        qualityIndicators: QualityIndicators,
        entities: [ContentEntity] = [],
        keyPhrases: [String] = [],
        sentiment: SentimentAnalysis,
        urgency: UrgencyAssessment,
        metadata: [String: AnyCodable] = [:]
    ) {
        self.contentType = contentType
        self.purpose = purpose
        self.actionability = actionability
        self.audience = audience
        self.workflowStage = workflowStage
        self.technicalComplexity = technicalComplexity
        self.businessContext = businessContext
        self.qualityIndicators = qualityIndicators
        self.entities = entities
        self.keyPhrases = keyPhrases
        self.sentiment = sentiment
        self.urgency = urgency
        self.metadata = metadata
    }
}