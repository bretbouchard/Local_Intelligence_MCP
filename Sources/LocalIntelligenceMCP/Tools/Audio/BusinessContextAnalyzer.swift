//
//  BusinessContextAnalyzer.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-09.
//

import Foundation

/// Analyzes business context of audio content
public class BusinessContextAnalyzer {

    // MARK: - Business Context Analysis

    /// Analyzes business context of content
    /// - Parameters:
    ///   - content: Content to analyze
    ///   - context: Additional context information
    /// - Returns: Business context assessment
    public func analyzeBusinessContext(content: String, context: [String: Any] = [:]) -> BusinessContext {
        let lowercaseContent = content.lowercased()

        // Determine project type
        let projectType = determineProjectType(content: lowercaseContent)

        // Determine commercial nature
        let commercialNature = determineCommercialNature(content: lowercaseContent)

        // Determine client involvement
        let clientInvolvement = determineClientInvolvement(content: lowercaseContent)

        // Extract business entities
        let budgetMentions = extractBudgetMentions(content: content)
        let timelineMentions = extractTimelineMentions(content: content)
        let decisionPoints = extractDecisionPoints(content: lowercaseContent)
        let stakeholders = extractStakeholders(content: lowercaseContent)

        return BusinessContext(
            projectType: projectType,
            commercialNature: commercialNature,
            clientInvolvement: clientInvolvement,
            budgetMentions: budgetMentions,
            timelineMentions: timelineMentions,
            decisionPoints: decisionPoints,
            stakeholders: stakeholders
        )
    }

    /// Provides detailed business context analysis
    /// - Parameters:
    ///   - content: Content to analyze
    ///   - context: Additional context information
    /// - Returns: Detailed business context analysis
    public func getDetailedBusinessAnalysis(content: String, context: [String: Any] = [:]) -> DetailedBusinessAnalysis {
        let lowercaseContent = content.lowercased()

        // Basic business context
        let basicContext = analyzeBusinessContext(content: content, context: context)

        // Additional analysis
        let businessIndicators = extractBusinessIndicators(content: lowercaseContent)
        let riskFactors = identifyRiskFactors(content: lowercaseContent)
        let opportunityIndicators = identifyOpportunities(content: lowercaseContent)
        let complianceRequirements = extractComplianceRequirements(content: lowercaseContent)

        // Calculate business maturity score
        let maturityScore = calculateBusinessMaturityScore(
            businessContext: basicContext,
            indicators: businessIndicators,
            risks: riskFactors,
            opportunities: opportunityIndicators
        )

        // Generate business insights
        let insights = generateBusinessInsights(
            context: basicContext,
            indicators: businessIndicators,
            risks: riskFactors,
            opportunities: opportunityIndicators,
            maturityScore: maturityScore
        )

        return DetailedBusinessAnalysis(
            basicContext: basicContext,
            businessIndicators: businessIndicators,
            riskFactors: riskFactors,
            opportunityIndicators: opportunityIndicators,
            complianceRequirements: complianceRequirements,
            businessMaturityScore: maturityScore,
            insights: insights
        )
    }

    // MARK: - Project Type Analysis

    /// Determines project type based on content
    /// - Parameter content: Content to analyze
    /// - Returns: Project type
    private func determineProjectType(content: String) -> ProjectType {
        // Project type indicators with confidence scoring
        let projectTypeScores: [(ProjectType, [String])] = [
            (.musicProduction, ["music", "song", "track", "album", "recording", "vocals", "instruments"]),
            (.postProduction, ["film", "video", "movie", "picture", "sound design", "foley", "dub"]),
            (.gameAudio, ["game", "gaming", "interactive", "gameplay", "cutscene", "ambient"]),
            (.podcast, ["podcast", "episode", "show", "host", "guest", "audio blog"]),
            (.liveSound, ["live", "concert", "event", "venue", "pa", "sound reinforcement", "stage"]),
            (.broadcast, ["radio", "television", "tv", "broadcast", "air", "transmission"]),
            (.commercial, ["commercial", "advert", "advertisement", "promo", "jingle", "brand"]),
            (.educational, ["educational", "training", "course", "lesson", "tutorial", "learning"]),
            (.corporate, ["corporate", "business", "meeting", "presentation", "conference"])
        ]

        var bestType = ProjectType.personal
        var bestScore = 0

        for (type, indicators) in projectTypeScores {
            let score = indicators.filter { content.contains($0) }.count
            if score > bestScore {
                bestScore = score
                bestType = type
            }
        }

        return bestScore > 0 ? bestType : .personal
    }

    /// Determines commercial nature of content
    /// - Parameter content: Content to analyze
    /// - Returns: Commercial nature
    private func determineCommercialNature(content: String) -> CommercialNature {
        let commercialIndicators = [
            CommercialNature.commercial: ["client", "customer", "budget", "invoice", "payment", "profit"],
            CommercialNature.nonProfit: ["non-profit", "charity", "donation", "volunteer", "cause"],
            CommercialNature.research: ["research", "study", "experiment", "analysis", "investigation"],
            CommercialNature.educational: ["educational", "academic", "university", "school", "student"],
            CommercialNature.internal: ["internal", "company", "organization", "team", "department"]
        ]

        var bestNature = CommercialNature.personal
        var bestScore = 0

        for (nature, indicators) in commercialIndicators {
            let score = indicators.filter { content.contains($0) }.count
            if score > bestScore {
                bestScore = score
                bestNature = nature
            }
        }

        return bestScore > 0 ? bestNature : .personal
    }

    /// Determines client involvement level
    /// - Parameter content: Content to analyze
    /// - Returns: Client involvement level
    private func determineClientInvolvement(content: String) -> ClientInvolvement {
        let clientMentions = content.components(separatedBy: .whitespacesAndNewlines)
            .filter { $0.lowercased().contains("client") }.count

        // Also look for client-related terms
        let clientTerms = ["client", "customer", "approval", "feedback", "review", "sign-off"]
        let totalClientTerms = clientTerms.filter { content.contains($0) }.count

        let clientScore = clientMentions + totalClientTerms

        switch clientScore {
        case 0:
            return .none
        case 1...2:
            return .low
        case 3...5:
            return .medium
        case 6...10:
            return .high
        default:
            return .critical
        }
    }

    // MARK: - Entity Extraction Methods

    /// Extracts budget mentions from content
    /// - Parameter content: Content to analyze
    /// - Returns: Array of budget mentions
    private func extractBudgetMentions(content: String) -> [String] {
        let budgetPatterns = [
            #"(\$\d+(?:,\d{3})*(?:\.\d{2})?)"#,  // Currency amounts
            #"(\d+\s*dollars?) "#,
            #"(budget|cost|price|fee|rate)"#,
            #"(invoice|bill|charge|payment)"#,
            #"(quote|estimate|bid)"#
        ]

        var mentions: [String] = []

        for pattern in budgetPatterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { continue }

            let matches = regex.matches(in: content, range: NSRange(content.startIndex..<content.endIndex, in: content))
            for match in matches {
                if let range = Range(match.range, in: content) {
                    mentions.append(String(content[range]))
                }
            }
        }

        return Array(Set(mentions)) // Remove duplicates
    }

    /// Extracts timeline mentions from content
    /// - Parameter content: Content to analyze
    /// - Returns: Array of timeline mentions
    private func extractTimelineMentions(content: String) -> [String] {
        let timelinePatterns = [
            #"(deadline|due date|delivery date)"#,
            #"(by \d{1,2}/\d{1,2}/\d{4})"#,
            #"(within \d+ (day|week|month)s?)"#,
            #"(asap|as soon as possible)"#,
            #"(rush|expedited|priority)"#,
            #"(milestone|phase|stage)"#,
            #"(timeline|schedule|project plan)"#
        ]

        var mentions: [String] = []

        for pattern in timelinePatterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { continue }

            let matches = regex.matches(in: content, range: NSRange(content.startIndex..<content.endIndex, in: content))
            for match in matches {
                if let range = Range(match.range, in: content) {
                    mentions.append(String(content[range]))
                }
            }
        }

        return Array(Set(mentions)) // Remove duplicates
    }

    /// Extracts decision points from content
    /// - Parameter content: Content to analyze
    /// - Returns: Array of decision points
    private func extractDecisionPoints(content: String) -> [DecisionPoint] {
        var decisions: [DecisionPoint] = []

        // Decision indicators
        let decisionIndicators = ["decide", "decision", "approve", "approval", "choose", "select", "determine"]
        let sentences = content.components(separatedBy: CharacterSet(charactersIn: ".!?"))

        for sentence in sentences {
            let trimmedSentence = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedSentence.isEmpty else { continue }

            let lowercaseSentence = trimmedSentence.lowercased()

            if decisionIndicators.contains(where: lowercaseSentence.contains) {
                let status: DecisionStatus
                if lowercaseSentence.contains("approved") {
                    status = .approved
                } else if lowercaseSentence.contains("rejected") {
                    status = .rejected
                } else if lowercaseSentence.contains("deferred") {
                    status = .deferred
                } else if lowercaseSentence.contains("review") {
                    status = .underReview
                } else {
                    status = .pending
                }

                // Extract urgency
                let urgency: String?
                if lowercaseSentence.contains("urgent") || lowercaseSentence.contains("asap") {
                    urgency = "urgent"
                } else if lowercaseSentence.contains("this week") {
                    urgency = "this week"
                } else if lowercaseSentence.contains("next week") {
                    urgency = "next week"
                } else {
                    urgency = nil
                }

                // Extract stakeholders
                let stakeholderPatterns = ["client", "producer", "artist", "manager", "engineer"]
                let stakeholders = stakeholderPatterns.filter { lowercaseSentence.contains($0) }

                decisions.append(DecisionPoint(
                    description: trimmedSentence,
                    urgency: urgency,
                    stakeholders: stakeholders,
                    status: status
                ))
            }
        }

        return decisions
    }

    /// Extracts stakeholders from content
    /// - Parameter content: Content to analyze
    /// - Returns: Array of stakeholder names
    private func extractStakeholders(content: String) -> [String] {
        let stakeholderIndicators = [
            "client", "customer", "producer", "artist", "musician",
            "engineer", "manager", "director", "label", "publisher",
            "agency", "studio", "venue", "promoter", "investor"
        ]

        return stakeholderIndicators.filter { content.contains($0) }
    }

    // MARK: - Advanced Business Analysis

    /// Extracts business indicators from content
    /// - Parameter content: Content to analyze
    /// - Returns: Business indicators
    private func extractBusinessIndicators(content: String) -> BusinessIndicators {
        let contractIndicators = ["contract", "agreement", "terms", "deliverables", "scope"]
        let qualityIndicators = ["quality", "standard", "specification", "requirement", "compliance"]
        let riskIndicators = ["risk", "issue", "problem", "challenge", "concern"]
        let opportunityIndicators = ["opportunity", "potential", "growth", "expand", "new"]

        let contractCount = contractIndicators.filter { content.contains($0) }.count
        let qualityCount = qualityIndicators.filter { content.contains($0) }.count
        let riskCount = riskIndicators.filter { content.contains($0) }.count
        let opportunityCount = opportunityIndicators.filter { content.contains($0) }.count

        return BusinessIndicators(
            contractReferences: contractCount,
            qualityFocus: qualityCount,
            riskMentions: riskCount,
            opportunityReferences: opportunityCount
        )
    }

    /// Identifies risk factors in content
    /// - Parameter content: Content to analyze
    /// - Returns: Array of risk factors
    private func identifyRiskFactors(content: String) -> [RiskFactor] {
        let riskPatterns: [(String, RiskSeverity)] = [
            ("delay|overdue|behind schedule", .high),
            ("budget over|cost overrun|expensive", .high),
            ("technical issue|equipment failure|problem", .medium),
            ("client unhappy|dissatisfied|complaint", .high),
            ("deadline missed|late delivery", .high),
            ("unclear requirement|ambiguous spec", .medium),
            ("resource shortage|limited time", .medium)
        ]

        var riskFactors: [RiskFactor] = []

        for (pattern, severity) in riskPatterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { continue }

            let matches = regex.matches(in: content, range: NSRange(content.startIndex..<content.endIndex, in: content))
            for match in matches {
                if let range = Range(match.range, in: content) {
                    riskFactors.append(RiskFactor(
                        description: String(content[range]),
                        severity: severity,
                        category: .operational
                    ))
                }
            }
        }

        return riskFactors
    }

    /// Identifies opportunities in content
    /// - Parameter content: Content to analyze
    /// - Returns: Array of opportunity indicators
    private func identifyOpportunities(content: String) -> [OpportunityIndicator] {
        let opportunityPatterns: [(String, OpportunityType)] = [
            ("new project|additional work|expansion", .growth),
            ("upgrade|improve|enhance", .service),
            ("collaboration|partnership|joint", .partnership),
            ("innovation|new technology|advanced", .innovation),
            ("efficiency|optimization|streamline", .efficiency)
        ]

        var opportunities: [OpportunityIndicator] = []

        for (pattern, type) in opportunityPatterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { continue }

            let matches = regex.matches(in: content, range: NSRange(content.startIndex..<content.endIndex, in: content))
            for match in matches {
                if let range = Range(match.range, in: content) {
                    opportunities.append(OpportunityIndicator(
                        description: String(content[range]),
                        type: type,
                        potential: .medium
                    ))
                }
            }
        }

        return opportunities
    }

    /// Extracts compliance requirements from content
    /// - Parameter content: Content to analyze
    /// - Returns: Array of compliance requirements
    private func extractComplianceRequirements(content: String) -> [ComplianceRequirement] {
        let compliancePatterns: [(String, ComplianceCategory)] = [
            ("copyright|rights|licensing", .legal),
            ("safety|regulation|standard", .safety),
            ("format|specification|technical", .technical),
            ("contract|agreement|terms", .contractual)
        ]

        var requirements: [ComplianceRequirement] = []

        for (pattern, category) in compliancePatterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { continue }

            let matches = regex.matches(in: content, range: NSRange(content.startIndex..<content.endIndex, in: content))
            for match in matches {
                if let range = Range(match.range, in: content) {
                    requirements.append(ComplianceRequirement(
                        description: String(content[range]),
                        category: category,
                        priority: .medium
                    ))
                }
            }
        }

        return requirements
    }

    // MARK: - Business Maturity and Insights

    /// Calculates business maturity score
    /// - Parameters:
    ///   - businessContext: Basic business context
    ///   - indicators: Business indicators
    ///   - risks: Risk factors
    ///   - opportunities: Opportunity indicators
    /// - Returns: Business maturity score (0.0-1.0)
    private func calculateBusinessMaturityScore(
        businessContext: BusinessContext,
        indicators: BusinessIndicators,
        risks: [RiskFactor],
        opportunities: [OpportunityIndicator]
    ) -> Double {
        var score: Double = 0.0

        // Client involvement scoring
        switch businessContext.clientInvolvement {
        case .critical: score += 0.2
        case .high: score += 0.15
        case .medium: score += 0.1
        case .low: score += 0.05
        case .none: score += 0.0
        }

        // Commercial nature scoring
        switch businessContext.commercialNature {
        case .commercial: score += 0.2
        case .nonProfit: score += 0.15
        case .educational: score += 0.1
        case .research: score += 0.1
        case .internal: score += 0.05
        case .personal: score += 0.0
        }

        // Decision points scoring
        score += min(Double(businessContext.decisionPoints.count) * 0.05, 0.15)

        // Business indicators scoring
        score += min(Double(indicators.contractReferences) * 0.05, 0.1)
        score += min(Double(indicators.qualityFocus) * 0.05, 0.1)

        // Risk and opportunity awareness
        score += min(Double(risks.count) * 0.02, 0.1)
        score += min(Double(opportunities.count) * 0.02, 0.1)

        return min(score, 1.0)
    }

    /// Generates business insights
    /// - Parameters:
    ///   - context: Business context
    ///   - indicators: Business indicators
    ///   - risks: Risk factors
    ///   - opportunities: Opportunity indicators
    ///   - maturityScore: Business maturity score
    /// - Returns: Array of business insights
    private func generateBusinessInsights(
        context: BusinessContext,
        indicators: BusinessIndicators,
        risks: [RiskFactor],
        opportunities: [OpportunityIndicator],
        maturityScore: Double
    ) -> [String] {
        var insights: [String] = []

        // Project type insights
        insights.append("Project type: \(context.projectType.description)")

        // Client involvement insights
        insights.append("Client involvement: \(context.clientInvolvement.description)")

        // Commercial nature insights
        insights.append("Commercial nature: \(context.commercialNature.description)")

        // Decision making insights
        if !context.decisionPoints.isEmpty {
            insights.append("\(context.decisionPoints.count) decision points identified requiring attention")
        }

        // Risk insights
        let highRiskCount = risks.filter { $0.severity == .high }.count
        if highRiskCount > 0 {
            insights.append("\(highRiskCount) high-priority risk factors identified")
        }

        // Opportunity insights
        if !opportunities.isEmpty {
            insights.append("\(opportunities.count) potential opportunities identified")
        }

        // Maturity insights
        let maturityLevel: String
        switch maturityScore {
        case 0.8...1.0: maturityLevel = "Excellent business maturity"
        case 0.6..<0.8: maturityLevel = "Good business maturity"
        case 0.4..<0.6: maturityLevel = "Moderate business maturity"
        case 0.2..<0.4: maturityLevel = "Developing business maturity"
        default: maturityLevel = "Basic business maturity"
        }
        insights.append(maturityLevel)

        return insights
    }
}

// MARK: - Supporting Types

/// Detailed business analysis result
public struct DetailedBusinessAnalysis {
    public let basicContext: BusinessContext
    public let businessIndicators: BusinessIndicators
    public let riskFactors: [RiskFactor]
    public let opportunityIndicators: [OpportunityIndicator]
    public let complianceRequirements: [ComplianceRequirement]
    public let businessMaturityScore: Double
    public let insights: [String]

    public init(
        basicContext: BusinessContext,
        businessIndicators: BusinessIndicators,
        riskFactors: [RiskFactor],
        opportunityIndicators: [OpportunityIndicator],
        complianceRequirements: [ComplianceRequirement],
        businessMaturityScore: Double,
        insights: [String]
    ) {
        self.basicContext = basicContext
        self.businessIndicators = businessIndicators
        self.riskFactors = riskFactors
        self.opportunityIndicators = opportunityIndicators
        self.complianceRequirements = complianceRequirements
        self.businessMaturityScore = businessMaturityScore
        self.insights = insights
    }
}

/// Business indicators
public struct BusinessIndicators {
    public let contractReferences: Int
    public let qualityFocus: Int
    public let riskMentions: Int
    public let opportunityReferences: Int

    public init(contractReferences: Int, qualityFocus: Int, riskMentions: Int, opportunityReferences: Int) {
        self.contractReferences = contractReferences
        self.qualityFocus = qualityFocus
        self.riskMentions = riskMentions
        self.opportunityReferences = opportunityReferences
    }
}

/// Risk factor
public struct RiskFactor {
    public let description: String
    public let severity: RiskSeverity
    public let category: RiskCategory

    public init(description: String, severity: RiskSeverity, category: RiskCategory) {
        self.description = description
        self.severity = severity
        self.category = category
    }
}

/// Risk severity
public enum RiskSeverity: String, CaseIterable, Codable, Sendable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
}

/// Risk category
public enum RiskCategory: String, CaseIterable, Codable, Sendable {
    case operational = "operational"
    case financial = "financial"
    case technical = "technical"
    case legal = "legal"
    case reputational = "reputational"
}

/// Opportunity indicator
public struct OpportunityIndicator {
    public let description: String
    public let type: OpportunityType
    public let potential: OpportunityPotential

    public init(description: String, type: OpportunityType, potential: OpportunityPotential) {
        self.description = description
        self.type = type
        self.potential = potential
    }
}

/// Opportunity type
public enum OpportunityType: String, CaseIterable, Codable, Sendable {
    case growth = "growth"
    case service = "service"
    case partnership = "partnership"
    case innovation = "innovation"
    case efficiency = "efficiency"
}

/// Opportunity potential
public enum OpportunityPotential: String, CaseIterable, Codable, Sendable {
    case low = "low"
    case medium = "medium"
    case high = "high"
}

/// Compliance requirement
public struct ComplianceRequirement {
    public let description: String
    public let category: ComplianceCategory
    public let priority: CompliancePriority

    public init(description: String, category: ComplianceCategory, priority: CompliancePriority) {
        self.description = description
        self.category = category
        self.priority = priority
    }
}

/// Compliance category
public enum ComplianceCategory: String, CaseIterable, Codable, Sendable {
    case legal = "legal"
    case safety = "safety"
    case technical = "technical"
    case contractual = "contractual"
    case regulatory = "regulatory"
}

/// Compliance priority
public enum CompliancePriority: String, CaseIterable, Codable, Sendable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
}