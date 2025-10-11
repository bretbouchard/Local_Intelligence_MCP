//
//  FocusedSummarizationTool.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-08.
//

import Foundation

/// Focused Summarization Tool for Audio Domain Content
///
/// Implements apple.summarize.focus specification:
/// - Targeted summarization focusing on specific aspects of audio content
/// - Focus array parameter for specifying summary concentration areas
/// - Coverage tracking to measure how well focus areas are covered
/// - Audio domain-specific focus categories (recording, mixing, mastering, technical, creative)
/// - Configurable summary styles and length options
///
/// Use Cases:
/// - Executive summaries focusing on specific aspects (e.g., "just the technical details")
/// - Client deliverables highlighting creative decisions or technical achievements
/// - Quality assurance summaries focusing on specific problem areas
/// - Documentation extracts for specific audiences (producers, engineers, musicians)
///
/// Performance Requirements:
/// - Execution: <200ms for 1000 words with 2-3 focus areas
/// - Memory: <2MB for 5000 words + processing overhead
/// - Concurrency: Thread-safe for multiple simultaneous operations
/// - Audio domain: Enhanced for recording/mixing/mastering terminology
public final class FocusedSummarizationTool: AudioDomainTool, @unchecked Sendable {

    // MARK: - Initialization

    public init(logger: Logger, securityManager: SecurityManager) {
        super.init(
            name: "apple_summarize_focus",
            description: "Generates targeted summaries of audio content focusing on specific aspects like recording techniques, mixing decisions, or creative choices, with coverage tracking.",
            inputSchema: [
                "type": AnyCodable("object"),
                "properties": AnyCodable([
                    "text": AnyCodable([
                        "type": AnyCodable("string"),
                        "description": AnyCodable("Audio session notes, transcripts, or technical documentation to summarize"),
                        "minLength": AnyCodable(50)
                    ]),
                    "focus": AnyCodable([
                        "type": AnyCodable("array"),
                        "description": AnyCodable("Specific aspects to focus on in the summary (2-5 recommended)"),
                        "items": AnyCodable([
                            "type": AnyCodable("string"),
                            "enum": AnyCodable(FocusCategory.allCases.map(\.rawValue))
                        ]),
                        "minItems": AnyCodable(1),
                        "maxItems": AnyCodable(8)
                    ]),
                    "style": AnyCodable([
                        "type": AnyCodable("string"),
                        "description": AnyCodable("Format and style of the focused summary"),
                        "enum": AnyCodable(SummaryStyle.allCases.map(\.rawValue)),
                        "default": AnyCodable(SummaryStyle.bullet.rawValue)
                    ]),
                    "max_points": AnyCodable([
                        "type": AnyCodable("integer"),
                        "description": AnyCodable("Maximum number of key points to include per focus area"),
                        "minimum": AnyCodable(1),
                        "maximum": AnyCodable(10),
                        "default": AnyCodable(5)
                    ]),
                    "coverage_threshold": AnyCodable([
                        "type": AnyCodable("number"),
                        "description": AnyCodable("Minimum coverage percentage (0.0-1.0) for adequate focus representation"),
                        "minimum": AnyCodable(0.0),
                        "maximum": AnyCodable(1.0),
                        "default": AnyCodable(0.7)
                    ])
                ]),
                "required": AnyCodable(["text", "focus"])
            ],
            logger: logger,
            securityManager: securityManager
        )
    }

    // MARK: - Focus Categories

    /// Supported focus areas for audio content summarization
    public enum FocusCategory: String, CaseIterable {
        case recording = "recording"
        case mixing = "mixing"
        case mastering = "mastering"
        case technical = "technical"
        case creative = "creative"
        case performance = "performance"
        case equipment = "equipment"
        case production = "production"
        case critique = "critique"
        case workflow = "workflow"

        var description: String {
            switch self {
            case .recording: return "Microphone techniques, signal chain, recording environment"
            case .mixing: return "Balance decisions, effects processing, stereo placement"
            case .mastering: return "Final processing, loudness, delivery preparation"
            case .technical: return "Equipment settings, technical parameters, specifications"
            case .creative: return "Artistic decisions, creative choices, musical elements"
            case .performance: return "Performance quality, musician contributions, takes"
            case .equipment: return "Gear used, instruments, plugins, hardware"
            case .production: return "Production decisions, arrangement, overall sound"
            case .critique: return "Problems identified, improvements needed, critiques"
            case .workflow: return "Process steps, time management, efficiency"
            }
        }
    }

    /// Summary formatting styles
    public enum SummaryStyle: String, CaseIterable {
        case bullet = "bullet"
        case paragraph = "paragraph"
        case executive = "executive"
        case technical = "technical"

        var description: String {
            switch self {
            case .bullet: return "Concise bullet points highlighting focus areas"
            case .paragraph: return "Narrative format with smooth transitions"
            case .executive: return "High-level summary for stakeholders"
            case .technical: return "Detailed technical summary for engineers"
            }
        }
    }

    // MARK: - BaseMCPTool Override

    /// Override performExecution to handle proper validation and parameter extraction
    /// - Parameters:
    ///   - parameters: Input parameters from MCP request
    ///   - context: Execution context
    /// - Returns: MCP response with processed text
    override func performExecution(parameters: [String: AnyCodable], context: MCPExecutionContext) async throws -> MCPResponse {
        do {
            // Validate required parameters and extract text
            try await validateAudioProcessingParameters(parameters, requiredFields: ["text", "focus"])
            let text = try extractAudioContentParameter(from: parameters)

            // Convert AnyCodable parameters to [String: Any] for processing
            var processingParameters: [String: Any] = [:]
            for (key, value) in parameters {
                processingParameters[key] = value.value
            }

            // Process the text using the overridden method
            let processedText = try await processAudioContent(text, with: processingParameters)

            return MCPResponse(
                success: true,
                data: AnyCodable(["text": processedText])
            )

        } catch {
            await logger.error(
                "Focused summarization tool execution failed",
                error: error,
                metadata: [
                    "tool": name,
                    "clientId": context.clientId.uuidString,
                    "requestId": context.requestId
                ]
            )
            throw error
        }
    }

    // MARK: - Audio Processing

    /// Generates focused summary with coverage tracking
    public override func processAudioContent(_ content: String, with parameters: [String: Any]) async throws -> String {
        // Use the content parameter directly instead of extracting from parameters
        let text = content

        guard let focusStrings = parameters["focus"] as? [String] else {
            throw AudioProcessingError.invalidInput("focus parameter is required")
        }

        // Parse focus categories
        let focusCategories = try focusStrings.compactMap { focusString -> FocusCategory? in
            guard let category = FocusCategory(rawValue: focusString.lowercased()) else {
                throw AudioProcessingError.invalidInput("Invalid focus category: \(focusString). Valid categories: \(FocusCategory.allCases.map(\.rawValue).joined(separator: ", "))")
            }
            return category
        }

        guard !focusCategories.isEmpty else {
            throw AudioProcessingError.invalidInput("At least one valid focus category is required")
        }

        // Parse style
        let styleString = parameters["style"] as? String ?? SummaryStyle.bullet.rawValue
        guard let style = SummaryStyle(rawValue: styleString.lowercased()) else {
            throw AudioProcessingError.invalidInput("Invalid style: \(styleString)")
        }

        // Parse max points
        let maxPoints = min(max(1, parameters["max_points"] as? Int ?? 5), 10)

        // Parse coverage threshold
        let coverageThreshold = min(max(0.0, parameters["coverage_threshold"] as? Double ?? 0.7), 1.0)

        // Pre-security check
        try await performSecurityCheck(text)

        // Generate focused summary
        let summaryResult = try await generateFocusedSummary(
            from: text,
            focusingOn: focusCategories,
            style: style,
            maxPoints: maxPoints,
            coverageThreshold: coverageThreshold
        )

        // Post-security validation
        try await validateOutput(summaryResult.summary)

        return summaryResult.summary
    }

    // MARK: - Private Implementation

    /// Result structure for focused summarization
    private struct FocusedSummaryResult {
        let summary: String
        let metadata: [String: Any]
    }

    /// Generates focused summary with coverage tracking
    private func generateFocusedSummary(
        from text: String,
        focusingOn categories: [FocusCategory],
        style: SummaryStyle,
        maxPoints: Int,
        coverageThreshold: Double
    ) async throws -> FocusedSummaryResult {

        // Analyze content for each focus category
        var categoryResults: [FocusCategory: [String]] = [:]
        var coverageData: [String: Any] = [:]

        for category in categories {
            let keyPoints = try await extractKeyPoints(for: category, from: text, maxPoints: maxPoints)
            categoryResults[category] = keyPoints
            coverageData[category.rawValue] = [
                "points_found": keyPoints.count,
                "coverage_percentage": calculateCoverage(for: category, points: keyPoints, text: text)
            ]
        }

        // Check if coverage threshold is met
        let overallCoverage = calculateOverallCoverage(coverageData)
        coverageData["overall_coverage"] = overallCoverage

        // Generate summary based on style
        let summary = try await formatFocusedSummary(
            categoryResults: categoryResults,
            style: style
        )

        // Build metadata
        var metadata: [String: Any] = [
            "focus_categories": categories.map(\.rawValue),
            "style": style.rawValue,
            "coverage": coverageData,
            "word_count": text.split(separator: " ").count,
            "summary_word_count": summary.split(separator: " ").count,
            "processing_timestamp": ISO8601DateFormatter().string(from: Date())
        ]

        // Add coverage warning if below threshold
        if overallCoverage < coverageThreshold {
            metadata["coverage_warning"] = "Overall coverage \(String(format: "%.1f", overallCoverage * 100))% is below threshold \(String(format: "%.1f", coverageThreshold * 100))%"
        }

        return FocusedSummaryResult(summary: summary, metadata: metadata)
    }

    /// Extracts key points for a specific focus category
    private func extractKeyPoints(for category: FocusCategory, from text: String, maxPoints: Int) async throws -> [String] {
        let keywords = getKeywords(for: category)
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var scoredSentences: [(sentence: String, score: Double)] = []

        for sentence in sentences {
            let score = calculateRelevanceScore(sentence: sentence, keywords: keywords, category: category)
            if score > 0.1 {
                scoredSentences.append((sentence: sentence, score: score))
            }
        }

        // Sort by score and take top points
        scoredSentences.sort { $0.score > $1.score }
        let topSentences = Array(scoredSentences.prefix(maxPoints))

        return topSentences.map { $0.sentence }
    }

    /// Gets relevant keywords for each focus category
    private func getKeywords(for category: FocusCategory) -> [String] {
        switch category {
        case .recording:
            return ["microphone", "mic", "preamp", "interface", "ad/da", "converter", "level", "gain", "signal chain", "room", "acoustics", "isolation", "bleed", "technique", "placement"]
        case .mixing:
            return ["mix", "balance", "eq", "equalization", "compression", "reverb", "delay", "pan", "stereo", "mono", "automation", "fader", "level", "bus", "send", "return"]
        case .mastering:
            return ["mastering", "master", "loudness", "limiting", "eq", "compression", "stereo", "mono", "conversion", "dithering", "delivery", "format", "target", "lufs"]
        case .technical:
            return ["settings", "parameters", "specification", "frequency", "hz", "khz", "db", "ms", "bit", "sample", "rate", "plugin", "software", "hardware", "version"]
        case .creative:
            return ["creative", "artistic", "vision", "direction", "choice", "decision", "feel", "emotion", "mood", "tone", "character", "sound", "texture"]
        case .performance:
            return ["performance", "musician", "player", "take", "recording", "mistake", "perfect", "timing", "rhythm", "feel", "groove", "energy", "dynamics"]
        case .equipment:
            return ["gear", "equipment", "microphone", "preamp", "compressor", "eq", "reverb", "delay", "interface", "converter", "monitor", "speaker", "headphone"]
        case .production:
            return ["production", "producer", "arrangement", "song", "structure", "intro", "verse", "chorus", "bridge", "outro", "direction", "overall"]
        case .critique:
            return ["problem", "issue", "mistake", "fix", "improve", "better", "wrong", "bad", "good", "excellent", "needs", "should", "could"]
        case .workflow:
            return ["process", "workflow", "time", "session", "hours", "minutes", "step", "phase", "stage", "setup", "teardown", "organization", "planning"]
        }
    }

    /// Calculates relevance score for a sentence against keywords
    private func calculateRelevanceScore(sentence: String, keywords: [String], category: FocusCategory) -> Double {
        let lowercaseSentence = sentence.lowercased()
        var score = 0.0

        // Count keyword matches
        let keywordMatches = keywords.filter { lowercaseSentence.contains($0.lowercased()) }.count
        score += Double(keywordMatches) * 0.3

        // Audio domain terms
        let audioTerms = ["audio", "sound", "music", "track", "session", "recording", "mix", "master"]
        let audioMatches = audioTerms.filter { lowercaseSentence.contains($0) }.count
        score += Double(audioMatches) * 0.2

        // Technical indicators
        if category == .technical || category == .recording || category == .mixing || category == .mastering {
            let technicalIndicators = ["db", "hz", "khz", "ms", "bit", "sample", "plugin", "settings"]
            let technicalMatches = technicalIndicators.filter { lowercaseSentence.contains($0) }.count
            score += Double(technicalMatches) * 0.4
        }

        // Sentence length penalty (prefer concise sentences)
        let wordCount = sentence.split(separator: " ").count
        if wordCount > 25 {
            score *= 0.8
        } else if wordCount > 40 {
            score *= 0.6
        }

        return min(score, 1.0)
    }

    /// Calculates coverage percentage for a category
    private func calculateCoverage(for category: FocusCategory, points: [String], text: String) -> Double {
        let keywords = getKeywords(for: category)
        let lowercaseText = text.lowercased()
        let totalKeywords = keywords.filter { lowercaseText.contains($0.lowercased()) }.count

        guard totalKeywords > 0 else { return 0.0 }

        let coveredKeywords = points.reduce(0) { total, point in
            let pointLower = point.lowercased()
            let matches = keywords.filter { pointLower.contains($0.lowercased()) }.count
            return total + matches
        }

        return min(Double(coveredKeywords) / Double(totalKeywords), 1.0)
    }

    /// Calculates overall coverage across all categories
    private func calculateOverallCoverage(_ coverageData: [String: Any]) -> Double {
        let categoryCoverages = coverageData.compactMap { (key, value) -> Double? in
            guard key != "overall_coverage", let data = value as? [String: Any],
                  let coverage = data["coverage_percentage"] as? Double else { return nil }
            return coverage
        }

        guard !categoryCoverages.isEmpty else { return 0.0 }
        return categoryCoverages.reduce(0, +) / Double(categoryCoverages.count)
    }

    /// Formats focused summary according to style
    private func formatFocusedSummary(categoryResults: [FocusCategory: [String]], style: SummaryStyle) async throws -> String {
        switch style {
        case .bullet:
            return formatBulletSummary(categoryResults: categoryResults)
        case .paragraph:
            return formatParagraphSummary(categoryResults: categoryResults)
        case .executive:
            return formatExecutiveSummary(categoryResults: categoryResults)
        case .technical:
            return formatTechnicalSummary(categoryResults: categoryResults)
        }
    }

    /// Formats bullet-style focused summary
    private func formatBulletSummary(categoryResults: [FocusCategory: [String]]) -> String {
        var summary = "Focused Summary\n\n"

        for (category, points) in categoryResults.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            if points.isEmpty { continue }

            summary += "**\(category.rawValue.capitalized):**\n"
            for point in points {
                summary += "• \(point)\n"
            }
            summary += "\n"
        }

        return summary.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Formats paragraph-style focused summary
    private func formatParagraphSummary(categoryResults: [FocusCategory: [String]]) -> String {
        var summary = "This summary focuses on "

        let categories = Array(categoryResults.keys).sorted { (category1: FocusCategory, category2: FocusCategory) -> Bool in
            category1.rawValue < category2.rawValue
        }
        let categoryNames = categories.map { (category: FocusCategory) -> String in
            category.rawValue
        }.joined(separator: ", ")
        summary += categoryNames

        summary += ".\n\n"

        for (index, category) in categories.enumerated() {
            let points = categoryResults[category] ?? []
            if points.isEmpty { continue }

            summary += "Regarding \(category.rawValue), "
            summary += points.joined(separator: " ")

            if index < categories.count - 1 {
                summary += " "
            }
        }

        return summary
    }

    /// Formats executive-style focused summary
    private func formatExecutiveSummary(categoryResults: [FocusCategory: [String]]) -> String {
        var summary = "Executive Summary - Key Focus Areas\n\n"

        // Overview
        let totalPoints = categoryResults.values.reduce(0) { $0 + $1.count }
        summary += "• **\(totalPoints)** key findings identified across \(categoryResults.count) focus areas\n\n"

        // Key highlights by category
        for (category, points) in categoryResults.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            if points.isEmpty { continue }

            summary += "**\(category.rawValue.capitalized) Highlights:**\n"
            if let topPoint = points.first {
                summary += "• \(topPoint)\n"
            }
            summary += "\n"
        }

        return summary.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Formats technical-style focused summary
    private func formatTechnicalSummary(categoryResults: [FocusCategory: [String]]) -> String {
        var summary = "Technical Analysis - Focused Summary\n\n"

        for (category, points) in categoryResults.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            if points.isEmpty { continue }

            summary += "[\(category.rawValue.uppercased())]\n"
            for (index, point) in points.enumerated() {
                summary += "\(index + 1). \(point)\n"
            }
            summary += "\n"
        }

        return summary.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Security

    /// Validates input for security compliance
    private func performSecurityCheck(_ text: String) async throws {
        try TextValidationUtils.validateText(text)
        try TextValidationUtils.validateTextSecurity(text)
    }

    /// Validates output for security compliance
    private func validateOutput(_ output: String) async throws {
        try TextValidationUtils.validateText(output)
        try TextValidationUtils.validateTextSecurity(output)
    }
}