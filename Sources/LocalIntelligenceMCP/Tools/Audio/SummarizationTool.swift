//
//  SummarizationTool.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-08.
//

import Foundation

/// Summarization tool for audio session notes and transcripts
/// Implements apple_summarize specification from audio tools specification
class SummarizationTool: TextProcessingTool, @unchecked Sendable {

    // MARK: - Initialization

    init(logger: Logger, securityManager: SecurityManager) {
        let inputSchema: [String: Any] = [
            "type": "object",
            "properties": [
                "text": [
                    "type": "string",
                    "description": "Text to summarize (notes, logs, transcripts, or other audio-related text)"
                ],
                "style": [
                    "type": "string",
                    "description": "Summary style",
                    "enum": ["bullet", "abstract", "executive"],
                    "default": "bullet"
                ],
                "max_points": [
                    "type": "integer",
                    "description": "Maximum number of key points to extract",
                    "minimum": 3,
                    "maximum": 15,
                    "default": 7
                ]
            ],
            "required": ["text"]
        ]

        super.init(
            name: "apple_summarize",
            description: "Produce concise summary of provided text (notes, logs, transcripts)",
            inputSchema: inputSchema,
            logger: logger,
            securityManager: securityManager,
            requiresPermission: [.systemInfo],
            offlineCapable: true
        )
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
            try validateTextProcessingParameters(parameters, requiredFields: ["text"])
            let text = try extractTextParameter(from: parameters)

            // Validate and extract optional parameters
            let style = try validateStyleParameter(from: parameters)
            let maxPoints = try validateMaxPointsParameter(from: parameters)

            // Create processing parameters dictionary
            let processingParameters: [String: Any] = [
                "style": style,
                "max_points": maxPoints,
                "pii_redact": parameters["pii_redact"]?.value as? Bool ?? true,
                "max_output_tokens": parameters["max_output_tokens"]?.value as? Int ?? TextProcessingTool.defaultMaxOutputTokens,
                "temperature": parameters["temperature"]?.value as? Double ?? 0.2
            ]

            // Process the text using the overridden method
            let processedText = try await processText(text, with: processingParameters)

            return MCPResponse(
                success: true,
                data: AnyCodable(["text": processedText])
            )

        } catch {
            await logger.error(
                "Summarization tool execution failed",
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

    // MARK: - TextProcessingTool Protocol

    /// Process text with the given parameters
    /// - Parameters:
    ///   - text: Input text to process
    ///   - parameters: Additional processing parameters
    /// - Returns: Processed text
    override func processText(_ text: String, with parameters: [String: Any]) async throws -> String {
        let style = parameters["style"] as? String ?? "bullet"
        let maxPoints = parameters["max_points"] as? Int ?? 7

        await logger.debug(
            "Processing text summarization",
            metadata: [
                "style": style,
                "maxPoints": maxPoints,
                "textLength": text.count
            ]
        )

        // Validate policy and apply PII redaction if needed
        let policy = ToolExecutionPolicy(
            allowPCC: false,
            piiRedact: parameters["pii_redact"] as? Bool ?? true,
            maxOutputTokens: parameters["max_output_tokens"] as? Int ?? TextProcessingTool.defaultMaxOutputTokens,
            temperature: parameters["temperature"] as? Double ?? 0.2
        )
        var processedText = text

        // Apply PII redaction if required by policy
        if policy.piiRedact {
            processedText = redactPII(from: processedText)
        }

        // Apply token limit if specified
        if policy.maxOutputTokens > 0 {
            let estimatedTokens = estimateTokens(processedText)
            if estimatedTokens > policy.maxOutputTokens {
                // Truncate to fit token limit
                let targetCharacters = policy.maxOutputTokens * 4
                processedText = String(processedText.prefix(targetCharacters))
                if !processedText.isEmpty {
                    processedText += "... [truncated]"
                }
            }
        }

        // Generate summary based on style
        let summary = try await generateSummary(
            from: processedText,
            style: style,
            maxPoints: maxPoints
        )

        await logger.info(
            "Text summarization completed",
            metadata: [
                "originalLength": text.count,
                "summaryLength": summary.count,
                "style": style,
                "maxPoints": maxPoints,
                "estimatedTokens": estimateTokens(summary)
            ]
        )

        return summary
    }

    // MARK: - Private Methods

    /// Generate summary based on specified style
    /// - Parameters:
    ///   - text: Text to summarize
    ///   - style: Summary style (bullet, abstract, executive)
    ///   - maxPoints: Maximum number of key points
    /// - Returns: Generated summary
    private func generateSummary(
        from text: String,
        style: String,
        maxPoints: Int
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
            // Default to bullet style
            return formatBulletSummary(keyPoints: keyPoints, originalText: text)
        }
    }

    /// Format summary as bullet points
    private func formatBulletSummary(keyPoints: [String], originalText: String) -> String {
        var summary = "## Summary\n\n"

        for (index, point) in keyPoints.enumerated() {
            summary += "\(index + 1). \(point)\n"
        }

        summary += "\n\n## Key Details\n\n"

        // Add original text length info
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
        summary += "• Estimated processing time: \(Date().timeIntervalSince1970)ms\n"

        return summary
    }

    /// Split text into sentences for processing
    private func splitIntoSentences(_ text: String) -> [String] {
        // Simple sentence splitting - could be enhanced with NLP
        let sentences = text.components(separatedBy: ". ")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return sentences
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
    /// - Parameters:
    ///   - text: Source text
    ///   - targetCount: Number of points to extract
    /// - Returns: Array of generic points
    private func extractGenericPoints(from text: String, targetCount: Int) -> [String] {
        // Simple heuristics for extracting important information
        let sentences = splitIntoSentences(text)
        var points: [String] = []

        // Look for sentences with numbers, percentages, or indicators of importance
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

    /// Redact PII from text
    private func redactPII(from text: String) -> String {
        var redactedText = text

        // Email redaction
        let emailPattern = #"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}"#
        redactedText = redactedText.replacingOccurrences(
            of: emailPattern,
            with: "[REDACTED_EMAIL]",
            options: .regularExpression
        )

        // Phone number redaction
        let phonePattern = #"\b\d{3}[-.]?\d{3}[-.]?\d{4}\b"#
        redactedText = redactedText.replacingOccurrences(
            of: phonePattern,
            with: "[REDACTED_PHONE]",
            options: .regularExpression
        )

        // API key redaction
        let apiKeyPattern = #"[a-zA-Z0-9]{20,}"#
        redactedText = redactedText.replacingOccurrences(
            of: apiKeyPattern,
            with: "[REDACTED_KEY]",
            options: .regularExpression
        )

        return redactedText
    }

    // MARK: - Validation Methods

    /// Validate style parameter
    /// - Parameter parameters: Input parameters
    /// - Returns: Validated style string
    /// - Throws: ValidationError if style is invalid
    private func validateStyleParameter(from parameters: [String: AnyCodable]) throws -> String {
        guard let styleValue = parameters["style"]?.value else {
            // Style is optional, return default
            return "bullet"
        }

        guard let styleString = styleValue as? String else {
            throw ToolsRegistryError.invalidParameters(
                "style parameter must be a string. Valid values: bullet, abstract, executive"
            )
        }

        let validStyles = ["bullet", "abstract", "executive"]
        guard validStyles.contains(styleString.lowercased()) else {
            throw ToolsRegistryError.invalidParameters(
                "Invalid style '\(styleString)'. Valid values: \(validStyles.joined(separator: ", "))"
            )
        }

        return styleString.lowercased()
    }

    /// Validate max_points parameter
    /// - Parameter parameters: Input parameters
    /// - Returns: Validated max_points integer
    /// - Throws: ValidationError if max_points is invalid
    private func validateMaxPointsParameter(from parameters: [String: AnyCodable]) throws -> Int {
        guard let maxPointsValue = parameters["max_points"]?.value else {
            // max_points is optional, return default
            return 7
        }

        guard let maxPointsInt = maxPointsValue as? Int else {
            throw ToolsRegistryError.invalidParameters(
                "max_points parameter must be an integer between 3 and 15"
            )
        }

        guard maxPointsInt >= 3 else {
            throw ToolsRegistryError.invalidParameters(
                "max_points must be at least 3, got \(maxPointsInt)"
            )
        }

        guard maxPointsInt <= 15 else {
            throw ToolsRegistryError.invalidParameters(
                "max_points must be at most 15, got \(maxPointsInt)"
            )
        }

        return maxPointsInt
    }
}