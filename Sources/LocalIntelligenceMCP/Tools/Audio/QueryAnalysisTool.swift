//
//  QueryAnalysisTool.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-09.
//

import Foundation
import AnyCodable

/// Query Analysis Tool for Audio Domain Classification
///
/// Comprehensive analysis tool for understanding and classifying user queries in audio domain contexts.
/// Analyzes query complexity, domain specificity, required expertise level, and provides recommendations
/// for response generation and tool selection.
///
/// Query Classification:
/// - Simple factual questions (equipment info, basic terminology)
/// - Technical questions (settings, parameters, troubleshooting)
/// - Complex procedural queries (workflow, multi-step processes)
/// - Creative/subjective queries (opinions, recommendations)
/// - Comparative queries (equipment comparison, technique comparison)
///
/// Audio Domain Analysis:
/// - Equipment and brand recognition with context
/// - Technical terminology complexity assessment
/// - Workflow stage identification (pre-production, recording, mixing, mastering)
/// - Expertise level requirements (beginner, intermediate, advanced, professional)
/// - Safety and risk assessment for equipment-related queries
///
/// Response Guidance:
/// - Recommended response length and complexity
/// - Required technical detail level
/// - Suggested tools and references
/// - Safety warnings and disclaimers
/// - Follow-up question suggestions
///
/// Performance Requirements:
/// - Execution: <150ms for comprehensive query analysis
/// - Memory: <2MB for classification models and dictionaries
/// - Accuracy: >85% for query classification accuracy
/// - Coverage: Support for 100+ audio domain subcategories
public final class QueryAnalysisTool: AudioDomainTool, @unchecked Sendable {

    // MARK: - Query Classification Types

    /// Main categories of user queries
    public enum QueryCategory: String, CaseIterable, Codable, Sendable {
        case factual = "factual"
        case technical = "technical"
        case procedural = "procedural"
        case comparative = "comparative"
        case creative = "creative"
        case troubleshooting = "troubleshooting"
        case recommendation = "recommendation"
        case safety = "safety"
        case cost = "cost"
        case workflow = "workflow"

        var description: String {
            switch self {
            case .factual: return "Simple factual questions about equipment, terms, or concepts"
            case .technical: return "Technical questions about settings, parameters, or specifications"
            case .procedural: return "Questions about processes, workflows, or step-by-step instructions"
            case .comparative: return "Questions comparing equipment, techniques, or approaches"
            case .creative: return "Subjective questions about creativity, opinion, or artistic choices"
            case .troubleshooting: return "Problem-solving questions about issues or malfunctions"
            case .recommendation: return "Questions seeking advice or recommendations"
            case .safety: return "Questions about safety, precautions, or potential risks"
            case .cost: return "Questions about pricing, budget, or financial considerations"
            case .workflow: return "Questions about session organization, planning, or project management"
            }
        }
    }

    /// Expertise level required for query
    public enum ExpertiseLevel: String, CaseIterable, Codable, Sendable {
        case beginner = "beginner"
        case intermediate = "intermediate"
        case advanced = "advanced"
        case professional = "professional"
        case expert = "expert"

        var description: String {
            switch self {
            case .beginner: return "Basic concepts, simple terminology, fundamental operations"
            case .intermediate: return "Some technical knowledge, common equipment familiarity"
            case .advanced: return "Deep technical knowledge, professional equipment experience"
            case .professional: return "Industry-level expertise, commercial studio experience"
            case .expert: return "Specialized knowledge, rare or advanced techniques"
            }
        }

        var complexityScore: Double {
            switch self {
            case .beginner: return 0.2
            case .intermediate: return 0.4
            case .advanced: return 0.6
            case .professional: return 0.8
            case .expert: return 1.0
            }
        }
    }

    /// Audio domain subcategories
    public enum AudioSubdomain: String, CaseIterable, Codable, Sendable {
        case recording = "recording"
        case mixing = "mixing"
        case mastering = "mastering"
        case editing = "editing"
        case liveSound = "live_sound"
        case postProduction = "post_production"
        case soundDesign = "sound_design"
        case broadcast = "broadcast"
        case gameAudio = "game_audio"
        case filmAudio = "film_audio"
        case musicProduction = "music_production"
        case podcasting = "podcasting"
        case streaming = "streaming"
        case forensics = "audio_forensics"
        case restoration = "audio_restoration"

        var description: String {
            switch self {
            case .recording: return "Microphone techniques, capture methods, studio recording"
            case .mixing: return "Balance, EQ, compression, effects, mix bus processing"
            case .mastering: return "Final processing, loudness, delivery formats, quality control"
            case .editing: return "Audio editing, comping, cleanup, arrangement"
            case .liveSound: return "Live reinforcement, venue acoustics, concert audio"
            case .postProduction: return "Film/video audio, ADR, foley, sound effects"
            case .soundDesign: return "Creative sound creation, synthesis, manipulation"
            case .broadcast: return "Radio, television broadcast standards and practices"
            case .gameAudio: return "Interactive audio, middleware, implementation"
            case .filmAudio: return "Cinematic audio, surround sound, theatrical mixing"
            case .musicProduction: return "Song creation, arrangement, production techniques"
            case .podcasting: return "Podcast recording, editing, distribution"
            case .streaming: return "Live streaming, broadcast audio for internet"
            case .forensics: return "Audio analysis for legal, investigative purposes"
            case .restoration: return "Audio repair, noise reduction, remastering"
            }
        }
    }

    // MARK: - Analysis Results

    /// Comprehensive query analysis result
    public struct QueryAnalysisResult: Codable, Sendable {
        /// Query classification
        public let category: QueryCategory

        /// Audio subdomain classification
        public let subdomain: AudioSubdomain?

        /// Required expertise level
        public let expertiseLevel: ExpertiseLevel

        /// Query complexity score (0.0-1.0)
        public let complexityScore: Double

        /// Audio domain relevance score (0.0-1.0)
        public let domainRelevance: Double

        /// Identified entities and concepts
        public let entities: [QueryEntity]

        /// Technical terminology found
        public let technicalTerms: [String]

        /// Equipment mentioned
        public let equipment: [String]

        /// Response recommendations
        public let responseGuidance: ResponseGuidance

        /// Safety and risk assessment
        public let safetyAssessment: SafetyAssessment?

        /// Processing metadata
        public let metadata: [String: AnyCodable]

        public init(
            category: QueryCategory,
            subdomain: AudioSubdomain? = nil,
            expertiseLevel: ExpertiseLevel,
            complexityScore: Double,
            domainRelevance: Double,
            entities: [QueryEntity] = [],
            technicalTerms: [String] = [],
            equipment: [String] = [],
            responseGuidance: ResponseGuidance,
            safetyAssessment: SafetyAssessment? = nil,
            metadata: [String: AnyCodable] = [:]
        ) {
            self.category = category
            self.subdomain = subdomain
            self.expertiseLevel = expertiseLevel
            self.complexityScore = complexityScore
            self.domainRelevance = domainRelevance
            self.entities = entities
            self.technicalTerms = technicalTerms
            self.equipment = equipment
            self.responseGuidance = responseGuidance
            self.safetyAssessment = safetyAssessment
            self.metadata = metadata
        }
    }

    /// Identified entity in query
    public struct QueryEntity: Codable, Sendable {
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

    /// Types of entities that can be identified
    public enum EntityType: String, CaseIterable, Codable, Sendable {
        case equipment = "equipment"
        case brand = "brand"
        case technique = "technique"
        case parameter = "parameter"
        case format = "format"
        case software = "software"
        case genre = "genre"
        case location = "location"
        case person = "person"
        case measurement = "measurement"
        case currency = "currency"
        case time = "time"
        case safety = "safety"
    }

    /// Response guidance for the query
    public struct ResponseGuidance: Codable, Sendable {
        /// Recommended response length
        public let recommendedLength: ResponseLength

        /// Required technical detail level
        public let technicalDetail: TechnicalDetailLevel

        /// Suggested tools to reference
        public let suggestedTools: [String]

        /// Recommended response style
        public let responseStyle: ResponseStyle

        /// Follow-up question suggestions
        public let followUpQuestions: [String]

        /// Warning or disclaimer recommendations
        public let warnings: [String]

        public init(
            recommendedLength: ResponseLength,
            technicalDetail: TechnicalDetailLevel,
            suggestedTools: [String] = [],
            responseStyle: ResponseStyle,
            followUpQuestions: [String] = [],
            warnings: [String] = []
        ) {
            self.recommendedLength = recommendedLength
            self.technicalDetail = technicalDetail
            self.suggestedTools = suggestedTools
            self.responseStyle = responseStyle
            self.followUpQuestions = followUpQuestions
            self.warnings = warnings
        }
    }

    /// Recommended response length
    public enum ResponseLength: String, CaseIterable, Codable, Sendable {
        case brief = "brief"        // 1-2 sentences
        case short = "short"        // 1 paragraph
        case medium = "medium"      // 2-3 paragraphs
        case detailed = "detailed"  // 4-5 paragraphs
        case comprehensive = "comprehensive" // Multiple sections

        var maxWords: Int {
            switch self {
            case .brief: return 50
            case .short: return 150
            case .medium: return 300
            case .detailed: return 500
            case .comprehensive: return 1000
            }
        }
    }

    /// Technical detail level
    public enum TechnicalDetailLevel: String, CaseIterable, Codable, Sendable {
        case basic = "basic"
        case moderate = "moderate"
        case technical = "technical"
        case expert = "expert"

        var description: String {
            switch self {
            case .basic: return "Simple explanations, avoid technical jargon"
            case .moderate: return "Some technical terms with explanations"
            case .technical: return "Technical language appropriate for audio professionals"
            case .expert: return "Highly technical, industry-specific terminology"
            }
        }
    }

    /// Recommended response style
    public enum ResponseStyle: String, CaseIterable, Codable, Sendable {
        case informative = "informative"
        case instructional = "instructional"
        case comparative = "comparative"
        case advisory = "advisory"
        case troubleshooting = "troubleshooting"
        case creative = "creative"
        case formal = "formal"
        case conversational = "conversational"
    }

    /// Safety and risk assessment
    public struct SafetyAssessment: Codable, Sendable {
        /// Risk level (0.0-1.0)
        public let riskLevel: Double

        /// Safety concerns identified
        public let concerns: [SafetyConcern]

        /// Required warnings
        public let requiredWarnings: [String]

        /// Recommended precautions
        public let precautions: [String]

        public init(
            riskLevel: Double,
            concerns: [SafetyConcern] = [],
            requiredWarnings: [String] = [],
            precautions: [String] = []
        ) {
            self.riskLevel = riskLevel
            self.concerns = concerns
            self.requiredWarnings = requiredWarnings
            self.precautions = precautions
        }
    }

    /// Types of safety concerns
    public enum SafetyConcern: String, CaseIterable, Codable, Sendable {
        case hearingProtection = "hearing_protection"
        case electricalSafety = "electrical_safety"
        case equipmentDamage = "equipment_damage"
        case structural = "structural"
        case ergonomic = "ergonomic"
        case dataLoss = "data_loss"
        case legal = "legal"
        case health = "health"

        var description: String {
            switch self {
            case .hearingProtection: return "Risk of hearing damage from high sound levels"
            case .electricalSafety: return "Electrical hazards, shock risk, power safety"
            case .equipmentDamage: return "Risk of damaging audio equipment"
            case .structural: return "Physical safety, mounting, weight distribution"
            case .ergonomic: return "Physical strain, repetitive stress, posture"
            case .dataLoss: return "Risk of losing audio data or project files"
            case .legal: return "Legal concerns, copyright, licensing"
            case .health: return "General health and safety considerations"
            }
        }
    }

    // MARK: - Analysis Components

    private let queryClassifier: QueryClassifier
    private let entityExtractor: EntityExtractor
    private let domainAnalyzer: DomainAnalyzer
    private let safetyAssessor: SafetyAssessor
    private let responseAdvisor: ResponseAdvisor

    // MARK: - Initialization

    init(logger: Logger, securityManager: SecurityManager) {
        self.queryClassifier = QueryClassifier()
        self.entityExtractor = EntityExtractor()
        self.domainAnalyzer = DomainAnalyzer()
        self.safetyAssessor = SafetyAssessor()
        self.responseAdvisor = ResponseAdvisor()

        let inputSchema: [String: AnyCodable] = [
            "type": AnyCodable("object"),
            "properties": AnyCodable([
                "query": AnyCodable([
                    "type": AnyCodable("string"),
                    "description": AnyCodable("User query or question to analyze"),
                    "minLength": AnyCodable(10),
                    "maxLength": AnyCodable(1000),
                    "examples": AnyCodable([
                        "What's the best microphone for recording vocals under $500?",
                        "How do I set up compression for a bass guitar?",
                        "Why is my mix sounding muddy and what can I do about it?",
                        "Compare Pro Tools vs Logic Pro for professional mixing",
                        "Is it safe to use 48V phantom power with ribbon microphones?"
                    ])
                ]),
                "context": AnyCodable([
                    "type": AnyCodable("object"),
                    "description": AnyCodable("Additional context about the user's situation or environment"),
                    "properties": AnyCodable([
                        "expertise": AnyCodable([
                            "type": AnyCodable("string"),
                            "enum": AnyCodable(ExpertiseLevel.allCases.map(\.rawValue)),
                            "description": AnyCodable("User's expertise level in audio production"
                            )]
                        ),
                        "environment": AnyCodable([
                            "type": AnyCodable("string"),
                            "description": AnyCodable("User's working environment (home studio, professional studio, etc.)")
                        ]),
                        "budget": AnyCodable([
                            "type": AnyCodable("string"),
                            "description": AnyCodable("Budget constraints or financial considerations")
                        ])
                    ])
                ]),
                "analysis_depth": AnyCodable([
                    "type": AnyCodable("string"),
                    "description": AnyCodable("Depth of analysis to perform"),
                    "enum": AnyCodable(["basic", "standard", "comprehensive"]),
                    "default": AnyCodable("standard")
                ]),
                "include_safety": AnyCodable([
                    "type": AnyCodable("boolean"),
                    "description": AnyCodable("Include safety assessment for equipment-related queries"),
                    "default": AnyCodable(true)
                ]),
                "response_guidance": AnyCodable([
                    "type": AnyCodable("boolean"),
                    "description": AnyCodable("Include response recommendations and guidance"),
                    "default": AnyCodable(true)
                ])
            ]),
            "required": AnyCodable(["query"])
        ]

        super.init(
            name: "apple_query_analyze",
            description: "Analyzes and classifies user queries in audio domain contexts with comprehensive categorization, expertise assessment, and response guidance.",
            inputSchema: inputSchema,
            logger: logger,
            securityManager: securityManager
        )
    }

    // MARK: - Audio Processing

    /// Analyze user query with comprehensive classification and guidance
    public override func processAudioContent(_ content: String, with parameters: [String: Any]) async throws -> String {
        let query = content

        // Parse parameters
        let context = parameters["context"] as? [String: Any] ?? [:]
        let analysisDepth = parameters["analysis_depth"] as? String ?? "standard"
        let includeSafety = parameters["include_safety"] as? Bool ?? true
        let includeResponseGuidance = parameters["response_guidance"] as? Bool ?? true

        // Pre-security check
        try await performSecurityCheck(query)

        // Perform comprehensive analysis
        let result = try await analyzeQuery(
            query: query,
            context: context,
            analysisDepth: analysisDepth,
            includeSafety: includeSafety,
            includeResponseGuidance: includeResponseGuidance
        )

        // Post-security validation
        try await validateOutput(result)

        return result
    }

    // MARK: - Private Implementation

    /// Perform comprehensive query analysis
    private func analyzeQuery(
        query: String,
        context: [String: Any],
        analysisDepth: String,
        includeSafety: Bool,
        includeResponseGuidance: Bool
    ) async throws -> String {

        // Step 1: Basic classification
        let category = queryClassifier.classifyCategory(query)
        let expertiseLevel = queryClassifier.determineExpertiseLevel(query, context: context)
        let complexityScore = queryClassifier.calculateComplexity(query)

        // Step 2: Domain analysis
        let domainRelevance = domainAnalyzer.calculateDomainRelevance(query)
        let subdomain = domainAnalyzer.identifySubdomain(query)

        // Step 3: Entity extraction
        let entities = entityExtractor.extractEntities(query)
        let technicalTerms = entityExtractor.extractTechnicalTerms(query)
        let equipment = entityExtractor.extractEquipment(query)

        // Step 4: Safety assessment (if requested)
        let safetyAssessment = includeSafety ? safetyAssessor.assessSafety(query, entities: entities) : nil

        // Step 5: Response guidance (if requested)
        let responseGuidance = includeResponseGuidance ?
            responseAdvisor.generateGuidance(
                query: query,
                category: category,
                expertiseLevel: expertiseLevel,
                complexityScore: complexityScore,
                entities: entities
            ) : ResponseGuidance(
                recommendedLength: .medium,
                technicalDetail: .moderate,
                responseStyle: .informative
            )

        // Step 6: Compile result
        let result = QueryAnalysisResult(
            category: category,
            subdomain: subdomain,
            expertiseLevel: expertiseLevel,
            complexityScore: complexityScore,
            domainRelevance: domainRelevance,
            entities: entities,
            technicalTerms: technicalTerms,
            equipment: equipment,
            responseGuidance: responseGuidance,
            safetyAssessment: safetyAssessment,
            metadata: [
                "analysis_depth": AnyCodable(analysisDepth),
                "query_length": AnyCodable(query.count),
                "word_count": AnyCodable(query.split(separator: " ").count),
                "analysis_timestamp": AnyCodable(Date().timeIntervalSince1970)
            ]
        )

        await logger.info(
            "Query analysis completed",
            metadata: [
                "category": result.category.rawValue,
                "expertise_level": result.expertiseLevel.rawValue,
                "complexity_score": result.complexityScore,
                "domain_relevance": result.domainRelevance,
                "entities_found": result.entities.count,
                "safety_assessed": result.safetyAssessment != nil
            ]
        )

        // Convert to JSON string
        return try String(data: JSONEncoder().encode(result), encoding: .utf8) ??
               "{\"error\":\"Failed to encode analysis result\"}"
    }

    // MARK: - Security

    /// Validates input for security compliance
    private func performSecurityCheck(_ query: String) async throws {
        do {
            try TextValidationUtils.validateText(query)
            try TextValidationUtils.validateTextSecurity(query)
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

/// Classifies queries into categories and determines expertise requirements
private class QueryClassifier {

    private let categoryKeywords: [QueryAnalysisTool.QueryCategory: [String]]
    private let expertiseIndicators: [QueryAnalysisTool.ExpertiseLevel: [String]]

    init() {
        self.categoryKeywords = [
            .factual: ["what is", "define", "explain", "tell me about", "what are"],
            .technical: ["how to", "how do i", "settings", "parameters", "configure", "setup"],
            .procedural: ["steps", "process", "workflow", "how to", "procedure", "method"],
            .comparative: ["compare", "versus", "vs", "difference", "better", "which is"],
            .creative: ["creative", "artistic", "opinion", "feel", "sound", "style"],
            .troubleshooting: ["problem", "issue", "not working", "fix", "troubleshoot", "error"],
            .recommendation: ["recommend", "suggest", "advice", "what should", "best"],
            .safety: ["safe", "dangerous", "risk", "warning", "precaution"],
            .cost: ["price", "cost", "budget", "cheap", "expensive", "affordable"],
            .workflow: ["workflow", "session", "project", "organize", "manage"]
        ]

        self.expertiseIndicators = [
            .beginner: ["basic", "beginner", "newbie", "start", "intro"],
            .intermediate: ["some experience", "intermediate", "comfortable with"],
            .advanced: ["advanced", "experienced", "professional", "skilled"],
            .professional: ["professional", "commercial", "studio", "industry"],
            .expert: ["expert", "specialized", "high-end", "vintage", "rare"]
        ]
    }

    func classifyCategory(_ query: String) -> QueryAnalysisTool.QueryCategory {
        let lowercaseQuery = query.lowercased()
        var categoryScores: [QueryAnalysisTool.QueryCategory: Double] = [:]

        // Score each category based on keyword matches
        for (category, keywords) in categoryKeywords {
            let matches = keywords.filter { lowercaseQuery.contains($0) }.count
            categoryScores[category] = Double(matches) / Double(keywords.count)
        }

        // Return category with highest score
        if let bestCategory = categoryScores.max(by: { $0.value < $1.value }) {
            return bestCategory.key
        }

        return .factual // Default category
    }

    func determineExpertiseLevel(_ query: String, context: [String: Any]) -> QueryAnalysisTool.ExpertiseLevel {
        let lowercaseQuery = query.lowercased()

        // Check context for explicit expertise level
        if let expertiseString = context["expertise"] as? String,
           let expertise = QueryAnalysisTool.ExpertiseLevel(rawValue: expertiseString.lowercased()) {
            return expertise
        }

        // Analyze query for expertise indicators
        var expertiseScores: [QueryAnalysisTool.ExpertiseLevel: Double] = [:]

        for (level, indicators) in expertiseIndicators {
            let matches = indicators.filter { lowercaseQuery.contains($0) }.count
            expertiseScores[level] = Double(matches)
        }

        // Consider technical terminology complexity
        let technicalComplexity = calculateTechnicalComplexity(query)
        if technicalComplexity > 0.8 {
            expertiseScores[QueryAnalysisTool.ExpertiseLevel.expert] = (expertiseScores[QueryAnalysisTool.ExpertiseLevel.expert] ?? 0) + 1.0
        } else if technicalComplexity > 0.6 {
            expertiseScores[QueryAnalysisTool.ExpertiseLevel.advanced] = (expertiseScores[QueryAnalysisTool.ExpertiseLevel.advanced] ?? 0) + 1.0
        } else if technicalComplexity > 0.4 {
            expertiseScores[QueryAnalysisTool.ExpertiseLevel.intermediate] = (expertiseScores[QueryAnalysisTool.ExpertiseLevel.intermediate] ?? 0) + 1.0
        } else {
            expertiseScores[QueryAnalysisTool.ExpertiseLevel.beginner] = (expertiseScores[QueryAnalysisTool.ExpertiseLevel.beginner] ?? 0) + 1.0
        }

        // Return expertise level with highest score
        if let bestLevel = expertiseScores.max(by: { $0.value < $1.value }) {
            return bestLevel.key
        }

        return .intermediate // Default level
    }

    func calculateComplexity(_ query: String) -> Double {
        var complexity = 0.3 // Base complexity

        let wordCount = query.split(separator: " ").count
        complexity += Double(min(wordCount, 50)) / 100.0

        // Add complexity for technical terms
        complexity += calculateTechnicalComplexity(query) * 0.3

        // Add complexity for multi-part questions
        let questionMarks = query.filter { $0 == "?" }.count
        complexity += Double(questionMarks) * 0.1

        // Add complexity for comparative language
        let comparativeWords = ["versus", "vs", "compare", "difference", "better"]
        let comparativeCount = comparativeWords.filter { query.lowercased().contains($0) }.count
        complexity += Double(comparativeCount) * 0.15

        return min(complexity, 1.0)
    }

    private func calculateTechnicalComplexity(_ query: String) -> Double {
        let technicalTerms = [
            "frequency", "spectrum", "compression", "eq", "equalization",
            "threshold", "ratio", "attack", "release", "automation",
            "khz", "hz", "db", "decibel", "bit depth", "sample rate",
            "latency", "buffer", "driver", "interface", "preamp"
        ]

        let lowercaseQuery = query.lowercased()
        let technicalCount = technicalTerms.filter { lowercaseQuery.contains($0) }.count
        return Double(technicalCount) / Double(technicalTerms.count)
    }
}

/// Extracts entities and technical terms from queries
private class EntityExtractor {

    private let equipmentBrands: Set<String>
    private let technicalTerms: Set<String>
    private let audioFormats: Set<String>
    private let softwareTools: Set<String>

    init() {
        self.equipmentBrands = [
            "neumann", "akg", "sennheiser", "shure", "audio-technica", "rode",
            "api", "neve", "ssl", "focusrite", "universal audio", "manley",
            "avid", "steinberg", "ableton", "native instruments", "waves",
            "fabfilter", "soundtoys", "valhalla", "plug-in alliance"
        ]

        self.technicalTerms = [
            "frequency", "spectrum", "compression", "eq", "equalization",
            "threshold", "ratio", "attack", "release", "makeup gain",
            "khz", "hz", "db", "decibel", "bit depth", "sample rate",
            "latency", "buffer", "driver", "interface", "preamp",
            "reverb", "delay", "chorus", "flanger", "phaser",
            "automation", "plugin", "vst", "au", "aax"
        ]

        self.audioFormats = [
            "wav", "mp3", "aiff", "flac", "m4a", "aac", "ogg", "dsd"
        ]

        self.softwareTools = [
            "pro tools", "logic pro", "ableton live", "cubase", "studio one",
            "reaper", "fl studio", "garageband", "audition", "waveLab"
        ]
    }

    func extractEntities(_ query: String) -> [QueryAnalysisTool.QueryEntity] {
        var entities: [QueryAnalysisTool.QueryEntity] = []
        let lowercaseQuery = query.lowercased()

        // Extract brands
        for brand in equipmentBrands {
            if lowercaseQuery.contains(brand) {
                entities.append(QueryAnalysisTool.QueryEntity(
                    text: brand,
                    type: .brand,
                    confidence: 0.9
                ))
            }
        }

        // Extract formats
        for format in audioFormats {
            if lowercaseQuery.contains(format) {
                entities.append(QueryAnalysisTool.QueryEntity(
                    text: format,
                    type: .format,
                    confidence: 0.8
                ))
            }
        }

        // Extract software
        for software in softwareTools {
            if lowercaseQuery.contains(software) {
                entities.append(QueryAnalysisTool.QueryEntity(
                    text: software,
                    type: .software,
                    confidence: 0.9
                ))
            }
        }

        // Extract measurements (frequencies, dB values, etc.)
        if let frequency = extractMeasurement(pattern: "(\\\\d+)\\\\s*hz", from: query) {
            entities.append(QueryAnalysisTool.QueryEntity(
                text: frequency,
                type: .measurement,
                confidence: 0.9,
                context: "frequency"
            ))
        }

        if let db = extractMeasurement(pattern: "(-?\\\\d+)\\\\s*db", from: query) {
            entities.append(QueryAnalysisTool.QueryEntity(
                text: db,
                type: .measurement,
                confidence: 0.9,
                context: "decibel"
            ))
        }

        // Extract currency values
        if let price = extractMeasurement(pattern: "\\$(\\\\d+)", from: query) {
            entities.append(QueryAnalysisTool.QueryEntity(
                text: price,
                type: .currency,
                confidence: 0.9,
                context: "price"
            ))
        }

        return entities
    }

    func extractTechnicalTerms(_ query: String) -> [String] {
        let lowercaseQuery = query.lowercased()
        return technicalTerms.filter { lowercaseQuery.contains($0) }
    }

    func extractEquipment(_ query: String) -> [String] {
        let lowercaseQuery = query.lowercased()
        let equipmentTerms = [
            "microphone", "mic", "preamp", "compressor", "eq", "console",
            "interface", "monitors", "headphones", "cable", "stand",
            "plugin", "software", "daw", "computer"
        ]
        return equipmentTerms.filter { lowercaseQuery.contains($0) }
    }

    private func extractMeasurement(pattern: String, from text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
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

/// Analyzes audio domain relevance and subdomains
private class DomainAnalyzer {

    private let subdomainKeywords: [QueryAnalysisTool.AudioSubdomain: [String]]

    init() {
        self.subdomainKeywords = [
            .recording: ["record", "capture", "microphone", "preamp", "tracking", "overdub"],
            .mixing: ["mix", "balance", "eq", "compression", "reverb", "effects", "automation"],
            .mastering: ["master", "final", "loudness", "limiting", "delivery", "quality control"],
            .editing: ["edit", "trim", "comp", "cleanup", "arrangement", "timing"],
            .liveSound: ["live", "venue", "concert", "reinforcement", "front of house"],
            .postProduction: ["film", "video", "adr", "foley", "dub", "post"],
            .soundDesign: ["design", "create", "synthesize", "manipulate", "effects"],
            .broadcast: ["radio", "television", "broadcast", "stream", "transmission"],
            .gameAudio: ["game", "interactive", "middleware", "implementation", "adaptive"],
            .musicProduction: ["music", "song", "arrangement", "production", "compose"],
            .podcasting: ["podcast", "episode", "host", "interview", "publishing"],
            .streaming: ["stream", "live stream", "internet", "broadcast online"]
        ]
    }

    func calculateDomainRelevance(_ query: String) -> Double {
        let audioKeywords = [
            "audio", "sound", "music", "recording", "mixing", "mastering",
            "microphone", "speaker", "headphone", "studio", "production",
            "eq", "compression", "reverb", "delay", "effects", "plugins"
        ]

        let lowercaseQuery = query.lowercased()
        let keywordCount = audioKeywords.filter { lowercaseQuery.contains($0) }.count
        let wordCount = query.split(separator: " ").count

        return Double(keywordCount) / Double(max(wordCount, 1))
    }

    func identifySubdomain(_ query: String) -> QueryAnalysisTool.AudioSubdomain? {
        let lowercaseQuery = query.lowercased()
        var subdomainScores: [QueryAnalysisTool.AudioSubdomain: Double] = [:]

        // Score each subdomain based on keyword matches
        for (subdomain, keywords) in subdomainKeywords {
            let matches = keywords.filter { lowercaseQuery.contains($0) }.count
            subdomainScores[subdomain] = Double(matches) / Double(keywords.count)
        }

        // Return subdomain with highest score (if significant)
        if let bestSubdomain = subdomainScores.max(by: { $0.value < $1.value }),
           bestSubdomain.value > 0.2 {
            return bestSubdomain.key
        }

        return nil
    }
}

/// Assesses safety concerns in queries
private class SafetyAssessor {

    private let safetyKeywords: [QueryAnalysisTool.SafetyConcern: [String]]
    private let riskPatterns: [String]

    init() {
        self.safetyKeywords = [
            .hearingProtection: ["loud", "deaf", "hearing", "ear", "damage", "protection"],
            .electricalSafety: ["power", "electric", "shock", "voltage", "cable", "outlet"],
            .equipmentDamage: ["damage", "break", "destroy", "harm", "ruin"],
            .structural: ["mount", "hang", "weight", "stand", "support", "secure"],
            .ergonomic: ["back", "posture", "strain", "ergonomic", "comfort"],
            .dataLoss: ["lose", "delete", "corrupt", "backup", "save", "recover"],
            .legal: ["copyright", "license", "legal", "permission", "rights"],
            .health: ["health", "medical", "condition", "symptoms", "doctor"]
        ]

        self.riskPatterns = [
            "48v phantom power ribbon",
            "high volume monitoring",
            "electrical grounding",
            "heavy equipment mounting"
        ]
    }

    func assessSafety(_ query: String, entities: [QueryAnalysisTool.QueryEntity]) -> QueryAnalysisTool.SafetyAssessment? {
        let lowercaseQuery = query.lowercased()
        var concerns: [QueryAnalysisTool.SafetyConcern] = []
        var riskLevel = 0.0

        // Check for safety-related keywords
        for (concern, keywords) in safetyKeywords {
            let matches = keywords.filter { lowercaseQuery.contains($0) }.count
            if matches > 0 {
                concerns.append(concern)
                riskLevel += Double(matches) * 0.2
            }
        }

        // Check for high-risk patterns
        for pattern in riskPatterns {
            if lowercaseQuery.contains(pattern) {
                riskLevel += 0.5
            }
        }

        // Generate required warnings based on concerns
        let requiredWarnings = generateWarnings(for: concerns)
        let precautions = generatePrecautions(for: concerns)

        // Normalize risk level
        riskLevel = min(riskLevel, 1.0)

        // Only return safety assessment if there are concerns
        if !concerns.isEmpty || riskLevel > 0.1 {
            return QueryAnalysisTool.SafetyAssessment(
                riskLevel: riskLevel,
                concerns: concerns,
                requiredWarnings: requiredWarnings,
                precautions: precautions
            )
        }

        return nil
    }

    private func generateWarnings(for concerns: [QueryAnalysisTool.SafetyConcern]) -> [String] {
        var warnings: [String] = []

        for concern in concerns {
            switch concern {
            case .hearingProtection:
                warnings.append("Always use hearing protection when working with high sound levels")
            case .electricalSafety:
                warnings.append("Ensure all electrical equipment is properly grounded and inspected")
            case .equipmentDamage:
                warnings.append("Incorrect settings or connections may damage equipment")
            case .structural:
                warnings.append("Ensure all equipment is properly mounted and secured")
            default:
                break
            }
        }

        return warnings
    }

    private func generatePrecautions(for concerns: [QueryAnalysisTool.SafetyConcern]) -> [String] {
        var precautions: [String] = []

        for concern in concerns {
            switch concern {
            case .hearingProtection:
                precautions.append("Start with low monitoring levels and gradually increase")
            case .electricalSafety:
                precautions.append("Turn off power before making connections")
            case .equipmentDamage:
                precautions.append("Consult equipment manuals before making changes")
            case .ergonomic:
                precautions.append("Take regular breaks and maintain proper posture")
            default:
                break
            }
        }

        return precautions
    }
}

/// Provides response guidance recommendations
private class ResponseAdvisor {

    func generateGuidance(
        query: String,
        category: QueryAnalysisTool.QueryCategory,
        expertiseLevel: QueryAnalysisTool.ExpertiseLevel,
        complexityScore: Double,
        entities: [QueryAnalysisTool.QueryEntity]
    ) -> QueryAnalysisTool.ResponseGuidance {

        // Determine recommended length
        let recommendedLength = determineRecommendedLength(
            category: category,
            complexity: complexityScore
        )

        // Determine technical detail level
        let technicalDetail = determineTechnicalDetail(
            expertise: expertiseLevel,
            complexity: complexityScore
        )

        // Determine response style
        let responseStyle = determineResponseStyle(category: category)

        // Generate suggested tools
        let suggestedTools = generateSuggestedTools(
            category: category,
            entities: entities
        )

        // Generate follow-up questions
        let followUpQuestions = generateFollowUpQuestions(
            category: category,
            expertise: expertiseLevel
        )

        // Generate warnings
        let warnings = generateWarnings(category: category, entities: entities)

        return QueryAnalysisTool.ResponseGuidance(
            recommendedLength: recommendedLength,
            technicalDetail: technicalDetail,
            suggestedTools: suggestedTools,
            responseStyle: responseStyle,
            followUpQuestions: followUpQuestions,
            warnings: warnings
        )
    }

    private func determineRecommendedLength(category: QueryAnalysisTool.QueryCategory, complexity: Double) -> QueryAnalysisTool.ResponseLength {
        switch category {
        case .factual:
            return complexity > 0.6 ? .medium : .short
        case .technical:
            return complexity > 0.7 ? .detailed : .medium
        case .procedural:
            return .detailed
        case .comparative:
            return .medium
        case .creative:
            return .medium
        case .troubleshooting:
            return .detailed
        case .recommendation:
            return .medium
        default:
            return .short
        }
    }

    private func determineTechnicalDetail(expertise: QueryAnalysisTool.ExpertiseLevel, complexity: Double) -> QueryAnalysisTool.TechnicalDetailLevel {
        switch expertise {
        case .beginner:
            return .basic
        case .intermediate:
            return complexity > 0.6 ? .technical : .moderate
        case .advanced:
            return complexity > 0.5 ? .technical : .moderate
        case .professional, .expert:
            return complexity > 0.4 ? .expert : .technical
        }
    }

    private func determineResponseStyle(category: QueryAnalysisTool.QueryCategory) -> QueryAnalysisTool.ResponseStyle {
        switch category {
        case .factual: return .informative
        case .technical: return .instructional
        case .procedural: return .instructional
        case .comparative: return .comparative
        case .creative: return .creative
        case .troubleshooting: return .troubleshooting
        case .recommendation: return .advisory
        case .safety: return .formal
        default: return .conversational
        }
    }

    private func generateSuggestedTools(category: QueryAnalysisTool.QueryCategory, entities: [QueryAnalysisTool.QueryEntity]) -> [String] {
        var tools: [String] = []

        switch category {
        case .factual:
            tools.append("apple.info.get")
        case .technical:
            tools.append("apple.settings.analyze")
        case .procedural:
            tools.append("apple.plan.simple")
        case .recommendation:
            tools.append("apple.settings.recommend")
        case .comparative:
            tools.append("apple.compare.equipment")
        default:
            break
        }

        return tools
    }

    private func generateFollowUpQuestions(category: QueryAnalysisTool.QueryCategory, expertise: QueryAnalysisTool.ExpertiseLevel) -> [String] {
        var questions: [String] = []

        switch category {
        case .factual:
            questions.append("Would you like more specific information about any aspect?")
        case .technical:
            questions.append("What equipment or software are you using?")
            questions.append("What is your experience level with this type of task?")
        case .troubleshooting:
            questions.append("When did this issue start?")
            questions.append("Have you made any recent changes to your setup?")
        case .recommendation:
            questions.append("What is your budget range?")
            questions.append("What is your primary use case?")
        default:
            break
        }

        return questions
    }

    private func generateWarnings(category: QueryAnalysisTool.QueryCategory, entities: [QueryAnalysisTool.QueryEntity]) -> [String] {
        var warnings: [String] = []

        if entities.contains(where: { $0.type == .safety }) {
            warnings.append("This query involves safety considerations - proceed with caution")
        }

        if category == .troubleshooting {
            warnings.append("Complex troubleshooting may require professional assistance")
        }

        return warnings
    }
}