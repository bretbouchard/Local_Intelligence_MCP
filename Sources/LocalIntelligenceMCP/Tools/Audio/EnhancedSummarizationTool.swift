//
//  EnhancedSummarizationTool.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-09.
//

import Foundation

/// Enhanced Summarization tool demonstrating standardized error handling and logging
/// Shows best practices for implementing MCP tools with the new standardized framework
public class EnhancedSummarizationTool: EnhancedBaseMCPTool, @unchecked Sendable {

    // MARK: - Constants

    private static let supportedStyles = ["bullet", "abstract", "executive"]
    private static let defaultStyle = "bullet"
    private static let defaultMaxPoints = 7
    private static let minMaxPoints = 3
    private static let maxMaxPoints = 15
    private static let maxTextLength = 1000000

    // MARK: - Initialization

    public init(logger: Logger, securityManager: SecurityManager) {
        let inputSchema: [String: Any] = [
            "type": "object",
            "properties": [
                "text": [
                    "type": "string",
                    "description": "Text to summarize (notes, logs, transcripts, or other audio-related text)",
                    "minLength": 10,
                    "maxLength": EnhancedSummarizationTool.maxTextLength
                ],
                "style": [
                    "type": "string",
                    "description": "Summary style",
                    "enum": EnhancedSummarizationTool.supportedStyles,
                    "default": EnhancedSummarizationTool.defaultStyle
                ],
                "max_points": [
                    "type": "integer",
                    "description": "Maximum number of key points to extract",
                    "minimum": EnhancedSummarizationTool.minMaxPoints,
                    "maximum": EnhancedSummarizationTool.maxMaxPoints,
                    "default": EnhancedSummarizationTool.defaultMaxPoints
                ],
                "pii_redact": [
                    "type": "boolean",
                    "description": "Whether to redact personally identifiable information",
                    "default": true
                ],
                "max_output_tokens": [
                    "type": "integer",
                    "description": "Maximum number of output tokens",
                    "minimum": 50,
                    "maximum": 4096,
                    "default": 512
                ]
            ],
            "required": ["text"]
        ]

        super.init(
            name: "apple_summarize_enhanced",
            description: "Enhanced summarization tool with standardized error handling and logging",
            inputSchema: inputSchema,
            category: .textProcessing,
            requiresPermission: [.systemInfo],
            offlineCapable: true,
            logger: logger,
            securityManager: securityManager
        )
    }

    // MARK: - StandardizedTool Implementation

    /// Validate input parameters with standardized error handling
    private func validateParametersInternal(
        _ parameters: [String: AnyCodable],
        context: MCPExecutionContext
    ) async throws {
        // Call parent validation
        try await validateParametersStandard(parameters, context: context)

        // Validate required text parameter
        _ = try validateTextParameter(
            parameters["text"]?.value,
            name: "text",
            minLength: 10,
            maxLength: EnhancedSummarizationTool.maxTextLength,
            required: true,
            context: context
        )

        // Validate style parameter
        _ = try validateEnumParameter(
            parameters["style"]?.value,
            name: "style",
            allowedValues: EnhancedSummarizationTool.supportedStyles,
            required: false,
            defaultValue: EnhancedSummarizationTool.defaultStyle,
            context: context
        )

        // Validate max_points parameter
        _ = try validateNumericParameter(
            parameters["max_points"]?.value,
            name: "max_points",
            min: EnhancedSummarizationTool.minMaxPoints,
            max: EnhancedSummarizationTool.maxMaxPoints,
            required: false,
            defaultValue: EnhancedSummarizationTool.defaultMaxPoints,
            context: context
        ) as Int

        // Validate pii_redact parameter
        _ = try validateParameter(
            parameters["pii_redact"]?.value,
            as: Bool.self,
            name: "pii_redact",
            required: false,
            context: context
        )

        // Validate max_output_tokens parameter
        _ = try validateNumericParameter(
            parameters["max_output_tokens"]?.value,
            name: "max_output_tokens",
            min: 50,
            max: 4096,
            required: false,
            defaultValue: 512,
            context: context
        ) as Int

        // Parameters validated successfully
    }

    /// Core execution logic
    public override func performCoreExecution(
        parameters: [String: AnyCodable],
        context: MCPExecutionContext
    ) async throws -> Any {
        let startTime = Date()

        // Extract validated parameters
        let text = try validateParameter(
            parameters["text"]?.value,
            as: String.self,
            name: "text",
            required: true,
            context: context
        )

        let style = try validateEnumParameter(
            parameters["style"]?.value,
            name: "style",
            allowedValues: EnhancedSummarizationTool.supportedStyles,
            required: false,
            defaultValue: EnhancedSummarizationTool.defaultStyle,
            context: context
        )

        let maxPoints = try validateNumericParameter(
            parameters["max_points"]?.value,
            name: "max_points",
            min: EnhancedSummarizationTool.minMaxPoints,
            max: EnhancedSummarizationTool.maxMaxPoints,
            required: false,
            defaultValue: EnhancedSummarizationTool.defaultMaxPoints,
            context: context
        ) as Int

        let piiRedact = (try validateParameter(
            parameters["pii_redact"]?.value,
            as: Bool?.self,
            name: "pii_redact",
            required: false,
            context: context
        )) ?? true

        let maxOutputTokens = try validateNumericParameter(
            parameters["max_output_tokens"]?.value,
            name: "max_output_tokens",
            min: 50,
            max: 4096,
            required: false,
            defaultValue: 512,
            context: context
        ) as Int

        // Log processing start
        await LoggingUtils.logAudioProcessingStart(
            operation: "summarization",
            inputSize: text.count,
            parameters: [
                "style": style,
                "maxPoints": maxPoints,
                "piiRedact": piiRedact,
                "maxOutputTokens": maxOutputTokens
            ],
            context: context,
            logger: logger
        )

        // Apply PII redaction if required
        var processedText = text
        var piiDetections = 0
        var piiRedactions = 0

        if piiRedact {
            let piiResult = await applyPIIRedaction(to: text, context: context)
            processedText = piiResult.redactedText
            piiDetections = piiResult.detections
            piiRedactions = piiResult.redactions

            // Log PII processing
            await LoggingUtils.logPIIOperation(
                operation: "redaction",
                detections: piiResult.categories.map { $0 },
                context: context,
                logger: logger
            )
        }

        // Apply token limit if specified
        if maxOutputTokens > 0 {
            let estimatedTokens = estimateTokens(processedText)
            if estimatedTokens > maxOutputTokens {
                let targetCharacters = maxOutputTokens * 4
                processedText = String(processedText.prefix(targetCharacters))
                if !processedText.isEmpty {
                    processedText += "... [truncated]"
                }

                // Text truncated due to token limit
            }
        }

        // Generate summary
        let summaryStart = Date()
        let summary = try await generateSummary(
            from: processedText,
            style: style,
            maxPoints: maxPoints,
            context: context
        )
        let summaryDuration = Date().timeIntervalSince(summaryStart)

        // Log processing result
        await LoggingUtils.logAudioProcessingResult(
            operation: "summarization",
            duration: Date().timeIntervalSince(startTime),
            context: context,
            outputSize: summary.count,
            logger: logger
        )

        // Log additional quality metrics separately
        await logger.info("Summarization quality metrics", category: .multimedia, metadata: [
            "originalLength": text.count,
            "processedLength": processedText.count,
            "summaryLength": summary.count,
            "compressionRatio": Double(summary.count) / Double(text.count),
            "style": style,
            "maxPoints": maxPoints,
            "actualPoints": extractKeyPointCount(from: summary),
            "piiDetections": piiDetections,
            "piiRedactions": piiRedactions,
            "summaryGenerationTime": summaryDuration
        ])

        return [
            "summary": summary,
            "metadata": [
                "originalLength": text.count,
                "processedLength": processedText.count,
                "summaryLength": summary.count,
                "style": style,
                "maxPoints": maxPoints,
                "actualPoints": extractKeyPointCount(from: summary),
                "piiRedactionsApplied": piiRedactions,
                "compressionRatio": Double(summary.count) / Double(text.count)
            ]
        ]
    }

    // MARK: - Private Methods

    /// Apply PII redaction to text
    private func applyPIIRedaction(to text: String, context: MCPExecutionContext) async -> (redactedText: String, detections: Int, redactions: Int, categories: [String]) {
        let redactionStart = Date()
        var redactedText = text
        var detections = 0
        var redactions = 0
        var categories: Set<String> = []

        // Email redaction
        let emailPattern = #"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}"#
        let emailMatches = redactedText.matches(of: emailPattern)
        detections += emailMatches.count
        redactions += emailMatches.count
        categories.insert("email")
        redactedText = redactedText.replacingOccurrences(
            of: emailPattern,
            with: "[REDACTED_EMAIL]",
            options: .regularExpression
        )

        // Phone number redaction
        let phonePattern = #"\b\d{3}[-.]?\d{3}[-.]?\d{4}\b"#
        let phoneMatches = redactedText.matches(of: phonePattern)
        detections += phoneMatches.count
        redactions += phoneMatches.count
        categories.insert("phone")
        redactedText = redactedText.replacingOccurrences(
            of: phonePattern,
            with: "[REDACTED_PHONE]",
            options: .regularExpression
        )

        // API key redaction
        let apiKeyPattern = #"[a-zA-Z0-9]{20,}"#
        let apiKeyMatches = redactedText.matches(of: apiKeyPattern)
        detections += apiKeyMatches.count
        redactions += apiKeyMatches.count
        categories.insert("apiKey")
        redactedText = redactedText.replacingOccurrences(
            of: apiKeyPattern,
            with: "[REDACTED_KEY]",
            options: .regularExpression
        )

        // Log PII redaction performance
        await logPerformance(
            operation: "pii_redaction",
            duration: Date().timeIntervalSince(redactionStart),
            metadata: [
                "detections": detections,
                "redactions": redactions,
                "categories": Array(categories)
            ],
            context: context
        )

        return (redactedText, detections, redactions, Array(categories))
    }

    /// Generate summary based on specified style
    private func generateSummary(
        from text: String,
        style: String,
        maxPoints: Int,
        context: MCPExecutionContext
    ) async throws -> String {
        let sentences = splitIntoSentences(text)
        var keyPoints: [String] = []

        // Extract key points based on audio-related content
        for sentence in sentences {
            if isAudioRelevant(sentence) {
                keyPoints.append(sentence.trimmingCharacters(in: .whitespacesAndNewlines))
                if keyPoints.count >= maxPoints {
                    break
                }
            }
        }

        // If we don't have enough audio-specific points, add generic points
        if keyPoints.count < maxPoints {
            let genericPoints = extractGenericPoints(from: text, targetCount: maxPoints - keyPoints.count)
            keyPoints.append(contentsOf: genericPoints)
        }

        // Limit to max points
        keyPoints = Array(keyPoints.prefix(maxPoints))

        // Format based on style
        switch style {
        case "bullet":
            return formatBulletSummary(keyPoints: keyPoints, originalText: text)
        case "abstract":
            return formatAbstractSummary(keyPoints: keyPoints, originalText: text)
        case "executive":
            return formatExecutiveSummary(keyPoints: keyPoints, originalText: text)
        default:
            return formatBulletSummary(keyPoints: keyPoints, originalText: text)
        }
    }

    /// Split text into sentences for processing
    private func splitIntoSentences(_ text: String) -> [String] {
        return text.components(separatedBy: ". ")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    /// Check if a sentence contains audio-related content
    private func isAudioRelevant(_ sentence: String) -> Bool {
        let audioKeywords = [
            "mix", "master", "track", "audio", "sound", "music", "recording",
            "studio", "production", "engineer", "producer", "session",
            "DAW", "plugin", "EQ", "compressor", "reverb", "delay",
            "frequency", "amplitude", "waveform", "bitrate", "sample rate",
            "microphone", "preamp", "interface", "monitor", "speaker",
            "compression", "format", "bit depth", "channel", "sample",
            "gain", "volume", "pan", "automation", "MIDI", "tempo"
        ]

        let lowercaseSentence = sentence.lowercased()
        return audioKeywords.contains { lowercaseSentence.contains($0) }
    }

    /// Extract generic points from text when audio-specific ones are insufficient
    private func extractGenericPoints(from text: String, targetCount: Int) -> [String] {
        let sentences = splitIntoSentences(text)
        var points: [String] = []

        for sentence in sentences {
            if sentence.count > 20 && points.count < targetCount {
                if containsImportantIndicator(sentence) {
                    points.append(sentence.trimmingCharacters(in: .whitespacesAndNewlines))
                }
            }
        }

        return points
    }

    /// Check if sentence contains indicators of importance
    private func containsImportantIndicator(_ sentence: String) -> Bool {
        let indicators = [
            "critical", "important", "key", "main", "primary", "essential",
            "final", "conclusion", "result", "outcome", "success", "failure",
            "error", "warning", "note", "remember", "action"
        ]

        let lowercaseSentence = sentence.lowercased()
        return indicators.contains { lowercaseSentence.contains($0) } ||
               sentence.range(of: #"\\d+\%"#) != nil ||
               sentence.range(of: #"[$#]"#) != nil
    }

    /// Format summary as bullet points
    private func formatBulletSummary(keyPoints: [String], originalText: String) -> String {
        var summary = "## Summary\n\n"

        for (index, point) in keyPoints.enumerated() {
            summary += "\(index + 1). \(point)\n"
        }

        summary += "\n\n## Key Details\n\n"
        summary += "• Original text length: \(originalText.count) characters\n"
        summary += "• Key points extracted: \(keyPoints.count)\n"
        summary += "• Estimated tokens: \(estimateTokens(summary))\n"

        return summary
    }

    /// Format summary as abstract paragraph
    private func formatAbstractSummary(keyPoints: [String], originalText: String) -> String {
        let points = keyPoints.enumerated().map { "\($0.0 + 1). \($0.1)" }.joined(separator: " ")

        var summary = "## Abstract Summary\n\n"
        summary += points + ".\n\n"

        summary += "## Context\n\n"
        summary += "• Text length: \(originalText.count) characters\n"
        summary += "• Key points: \(keyPoints.count)\n"
        summary += "• Estimated tokens: \(estimateTokens(summary))\n"

        return summary
    }

    /// Format summary as executive brief
    private func formatExecutiveSummary(keyPoints: [String], originalText: String) -> String {
        let points = keyPoints.enumerated().map { "- \(String($0.0 + 1)). \($0.1)" }.joined(separator: "\n")

        var summary = "# Executive Summary\n\n"
        summary += points + ".\n\n"

        summary += "## Summary Statistics\n\n"
        summary += "• Total text length: \(originalText.count) characters\n"
        summary += "• Key insights: \(keyPoints.count)\n"

        return summary
    }

    /// Extract key point count from summary
    private func extractKeyPointCount(from summary: String) -> Int {
        let lines = summary.components(separatedBy: "\n")
        return lines.filter { $0.starts(with: "1.") || $0.starts(with: "2.") || $0.starts(with: "3.") }.count
    }

    /// Estimate token count for text
    private func estimateTokens(_ text: String) -> Int {
        // Simple estimation: ~4 characters per token
        return Int(ceil(Double(text.count) / 4.0))
    }
}

// MARK: - String Extensions

extension String {
    /// Find all matches of a regex pattern
    func matches(of pattern: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return []
        }

        let range = NSRange(self.startIndex..<self.endIndex, in: self)
        let matches = regex.matches(in: self, range: range)

        return matches.compactMap { match in
            if let range = Range(match.range, in: self) {
                return String(self[range])
            }
            return nil
        }
    }
}