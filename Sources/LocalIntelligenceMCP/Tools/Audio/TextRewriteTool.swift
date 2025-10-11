//
//  TextRewriteTool.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-08.
//

import Foundation

/// Text rewriting tool for tone and length adjustments
/// Implements apple.text.rewrite specification from audio tools specification
class TextRewriteTool: TextProcessingTool, @unchecked Sendable {

    // MARK: - Initialization

    init(logger: Logger, securityManager: SecurityManager) {
        let inputSchema: [String: Any] = [
            "type": "object",
            "properties": [
                "text": [
                    "type": "string",
                    "description": "Text to rewrite (notes, logs, transcripts, or other audio-related text)"
                ],
                "tone": [
                    "type": "string",
                    "description": "Target tone for the rewritten text",
                    "enum": ["technical", "friendly", "neutral", "executive"],
                    "default": "neutral"
                ],
                "length": [
                    "type": "string",
                    "description": "Target length for the rewritten text",
                    "enum": ["short", "medium", "long"],
                    "default": "medium"
                ]
            ],
            "required": ["text"]
        ]

        super.init(
            name: "apple_text_rewrite",
            description: "Rewrite text for tone/clarity/length without changing meaning",
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
            let tone = try validateToneParameter(from: parameters)
            let length = try validateLengthParameter(from: parameters)

            // Create processing parameters dictionary
            let processingParameters: [String: Any] = [
                "tone": tone,
                "length": length,
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
                "Text rewrite tool execution failed",
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
        let tone = parameters["tone"] as? String ?? "neutral"
        let length = parameters["length"] as? String ?? "medium"

        await logger.debug(
            "Processing text rewrite",
            metadata: [
                "tone": tone,
                "length": length,
                "textLength": text.count
            ]
        )

        // Validate policy and apply PII redaction if needed
        let policy = getPolicy(from: parameters)
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

        // Generate rewritten text based on tone and length
        let rewrittenText = try await generateRewrittenText(
            from: processedText,
            tone: tone,
            length: length
        )

        await logger.info(
            "Text rewrite completed",
            metadata: [
                "originalLength": text.count,
                "rewrittenLength": rewrittenText.count,
                "tone": tone,
                "length": length,
                "estimatedTokens": estimateTokens(rewrittenText)
            ]
        )

        return rewrittenText
    }

    // MARK: - Private Methods

    /// Generate rewritten text based on tone and length
    /// - Parameters:
    ///   - text: Text to rewrite
    ///   - tone: Target tone (technical, friendly, neutral, executive)
    ///   - length: Target length (short, medium, long)
    /// - Returns: Rewritten text
    private func generateRewrittenText(
        from text: String,
        tone: String,
        length: String
    ) async throws -> String {
        let sentences = splitIntoSentences(text)
        var processedSentences: [String] = []

        // Apply tone transformation
        for sentence in sentences {
            let transformedSentence = applyToneTransformation(to: sentence, tone: tone)
            processedSentences.append(transformedSentence)
        }

        // Apply length transformation
        let finalText = applyLengthTransformation(to: processedSentences, length: length)

        return finalText
    }

    /// Apply tone transformation to a sentence
    /// - Parameters:
    ///   - sentence: Sentence to transform
    ///   - tone: Target tone
    /// - Returns: Transformed sentence
    private func applyToneTransformation(to sentence: String, tone: String) -> String {
        let trimmedSentence = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSentence.isEmpty else { return trimmedSentence }

        switch tone {
        case "technical":
            return applyTechnicalTone(to: trimmedSentence)
        case "friendly":
            return applyFriendlyTone(to: trimmedSentence)
        case "neutral":
            return applyNeutralTone(to: trimmedSentence)
        case "executive":
            return applyExecutiveTone(to: trimmedSentence)
        default:
            return applyNeutralTone(to: trimmedSentence)
        }
    }

    /// Apply technical tone with audio engineering terminology
    /// - Parameter sentence: Sentence to transform
    /// - Returns: Technically-styled sentence
    private func applyTechnicalTone(to sentence: String) -> String {
        var result = sentence

        // Common informal to technical mappings
        let mappings: [String: String] = [
            "fix": "rectify",
            "fixes": "rectifies",
            "fixed": "rectified",
            "check": "verify",
            "checks": "verifies",
            "checked": "verified",
            "change": "modify",
            "changes": "modifies",
            "changed": "modified",
            "make better": "optimize",
            "made better": "optimized",
            "problem": "issue",
            "problems": "issues",
            "good": "optimal",
            "bad": "suboptimal",
            "work on": "process",
            "worked on": "processed",
            "set up": "configure",
            "turn on": "enable",
            "turned on": "enabled",
            "turn off": "disable",
            "turned off": "disabled"
        ]

        // Apply mappings
        for (informal, technical) in mappings {
            result = result.replacingOccurrences(of: informal, with: technical, options: .caseInsensitive)
        }

        // Add technical precision for audio-related content
        if isAudioRelated(sentence) {
            result = addAudioTechnicalPrecision(to: result)
        }

        return result
    }

    /// Apply friendly tone with conversational language
    /// - Parameter sentence: Sentence to transform
    /// - Returns: Friendly-styled sentence
    private func applyFriendlyTone(to sentence: String) -> String {
        var result = sentence

        // Technical to friendly mappings for audio context
        let technicalToFriendly: [String: String] = [
            "optimize": "make better",
            "rectify": "fix",
            "verify": "check",
            "configure": "set up",
            "enable": "turn on",
            "disable": "turn off",
            "issue": "problem",
            "optimal": "good",
            "suboptimal": "not ideal",
            "process": "work on"
        ]

        // Apply mappings
        for (technical, friendly) in technicalToFriendly {
            result = result.replacingOccurrences(of: technical, with: friendly, options: .caseInsensitive)
        }

        // Add friendly conversational elements
        if !result.contains("!") && !result.contains("?") {
            result = result + "."
        }

        return result
    }

    /// Apply neutral tone with objective language
    /// - Parameter sentence: Sentence to transform
    /// - Returns: Neutral-styled sentence
    private func applyNeutralTone(to sentence: String) -> String {
        var result = sentence

        // Remove emotional or biased language
        let biasedTerms: [String: String] = [
            "amazing": "notable",
            "terrible": "problematic",
            "perfect": "acceptable",
            "awful": "inadequate",
            "brilliant": "effective",
            "disaster": "failure",
            "wonderful": "positive",
            "horrible": "negative"
        ]

        for (biased, neutral) in biasedTerms {
            result = result.replacingOccurrences(of: biased, with: neutral, options: .caseInsensitive)
        }

        return result
    }

    /// Apply executive tone with concise, business-focused language
    /// - Parameter sentence: Sentence to transform
    /// - Returns: Executive-styled sentence
    private func applyExecutiveTone(to sentence: String) -> String {
        var result = sentence

        // Convert to executive/business language
        let casualToExecutive: [String: String] = [
            "fix": "resolve",
            "fixes": "resolves",
            "fixed": "resolved",
            "check": "review",
            "checks": "reviews",
            "checked": "reviewed",
            "change": "adjust",
            "changes": "adjusts",
            "changed": "adjusted",
            "make better": "enhance",
            "made better": "enhanced",
            "problem": "challenge",
            "problems": "challenges",
            "work on": "address",
            "worked on": "addressed",
            "set up": "implement",
            "start": "commence",
            "started": "commenced",
            "finish": "complete",
            "finished": "completed"
        ]

        // Apply mappings
        for (casual, executive) in casualToExecutive {
            result = result.replacingOccurrences(of: casual, with: executive, options: .caseInsensitive)
        }

        // Add business outcome focus for audio context
        if isAudioRelated(sentence) {
            result = addBusinessOutcomeFocus(to: result)
        }

        return result
    }

    /// Apply length transformation to processed sentences
    /// - Parameters:
    ///   - sentences: Array of processed sentences
    ///   - length: Target length (short, medium, long)
    /// - Returns: Length-adjusted text
    private func applyLengthTransformation(to sentences: [String], length: String) -> String {
        switch length {
        case "short":
            return createShortVersion(from: sentences)
        case "medium":
            return createMediumVersion(from: sentences)
        case "long":
            return createLongVersion(from: sentences)
        default:
            return createMediumVersion(from: sentences)
        }
    }

    /// Create short version by summarizing key points
    /// - Parameter sentences: Input sentences
    /// - Returns: Shortened text
    private func createShortVersion(from sentences: [String]) -> String {
        // Take first 1-2 sentences or compress if longer
        if sentences.count <= 2 {
            return sentences.joined(separator: " ")
        }

        // Create a condensed version focusing on audio-relevant content
        let audioSentences = sentences.filter { isAudioRelated($0) }
        let otherSentences = sentences.filter { !isAudioRelated($0) }

        var shortSentences: [String] = []

        // Prioritize audio-relevant sentences
        shortSentences.append(contentsOf: Array(audioSentences.prefix(1)))

        // Add one other key sentence if space allows
        if otherSentences.count > 0 {
            shortSentences.append(contentsOf: Array(otherSentences.prefix(1)))
        }

        return shortSentences.joined(separator: " ")
    }

    /// Create medium version with balanced detail
    /// - Parameter sentences: Input sentences
    /// - Returns: Medium-length text
    private func createMediumVersion(from sentences: [String]) -> String {
        // Include up to 4-5 sentences, prioritizing audio content
        let targetCount = min(5, sentences.count)

        let audioSentences = sentences.filter { isAudioRelated($0) }
        let otherSentences = sentences.filter { !isAudioRelated($0) }

        var mediumSentences: [String] = []

        // Include all audio sentences up to target
        mediumSentences.append(contentsOf: Array(audioSentences.prefix(targetCount)))

        // Fill remaining slots with other sentences
        let remainingSlots = targetCount - mediumSentences.count
        if remainingSlots > 0 {
            mediumSentences.append(contentsOf: Array(otherSentences.prefix(remainingSlots)))
        }

        return mediumSentences.joined(separator: " ")
    }

    /// Create long version with full detail and expansion
    /// - Parameter sentences: Input sentences
    /// - Returns: Expanded text
    private func createLongVersion(from sentences: [String]) -> String {
        var longSentences = sentences

        // Add detail to audio-related sentences
        for (index, sentence) in sentences.enumerated() {
            if isAudioRelated(sentence) {
                longSentences[index] = addAudioDetail(to: sentence)
            }
        }

        // Add transition phrases for better flow
        return addTransitions(to: longSentences)
    }

    /// Split text into sentences for processing
    /// - Parameter text: Text to split
    /// - Returns: Array of sentences
    private func splitIntoSentences(_ text: String) -> [String] {
        let sentences = text.components(separatedBy: ". ")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return sentences
    }

    /// Check if sentence contains audio-related content
    /// - Parameter sentence: Sentence to check
    /// - Returns: True if audio-related
    private func isAudioRelated(_ sentence: String) -> Bool {
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

    /// Add technical precision to audio-related sentences
    /// - Parameter sentence: Audio-related sentence
    /// - Returns: Enhanced sentence with technical precision
    private func addAudioTechnicalPrecision(to sentence: String) -> String {
        var result = sentence

        // Add technical specificity
        let enhancements: [String: String] = [
            "volume": "signal level",
            "sound": "audio signal",
            "music": "audio content",
            "recording": "audio capture",
            "mix": "audio mix",
            "master": "mastering process",
            "track": "audio track"
        ]

        for (general, specific) in enhancements {
            result = result.replacingOccurrences(of: general, with: specific, options: .caseInsensitive)
        }

        return result
    }

    /// Add business outcome focus to audio-related sentences
    /// - Parameter sentence: Audio-related sentence
    /// - Returns: Enhanced sentence with business focus
    private func addBusinessOutcomeFocus(to sentence: String) -> String {
        var result = sentence

        // Add outcome-oriented language
        let outcomeTerms = ["deliverable", "objective", "milestone", "success metric", "quality standard"]

        // For simplicity, add an outcome term if none present
        if !outcomeTerms.contains(where: { result.lowercased().contains($0) }) {
            if result.hasSuffix(".") {
                result = String(result.dropLast()) + " to ensure quality deliverables."
            } else {
                result += " to ensure quality deliverables."
            }
        }

        return result
    }

    /// Add technical detail to audio-related sentences
    /// - Parameter sentence: Audio-related sentence
    /// - Returns: Enhanced sentence with technical detail
    private func addAudioDetail(to sentence: String) -> String {
        var result = sentence

        // Add specific technical details based on content
        if sentence.lowercased().contains("eq") {
            result += " with precise frequency adjustments"
        } else if sentence.lowercased().contains("compressor") {
            result += " with optimal dynamic range control"
        } else if sentence.lowercased().contains("reverb") {
            result += " with appropriate spatial characteristics"
        }

        return result
    }

    /// Add transition phrases for better flow
    /// - Parameter sentences: Array of sentences
    /// - Returns: Text with transitions
    private func addTransitions(to sentences: [String]) -> String {
        let transitions = ["Additionally,", "Furthermore,", "Moreover,", "In addition,"]
        var result = ""

        for (index, sentence) in sentences.enumerated() {
            if index > 0 && index < transitions.count && !sentence.isEmpty {
                result += transitions[index] + " " + sentence + " "
            } else {
                result += sentence + " "
            }
        }

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Redact PII from text (inherited from TextProcessingTool)
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

    /// Get policy from parameters
    /// - Parameter parameters: Input parameters
    /// - Returns: Tool execution policy
    private func getPolicy(from parameters: [String: Any]) -> ToolExecutionPolicy {
        // Extract policy parameters or use defaults
        let piiRedact = parameters["pii_redact"] as? Bool ?? true
        let maxOutputTokens = parameters["max_output_tokens"] as? Int ?? TextProcessingTool.defaultMaxOutputTokens
        let temperature = parameters["temperature"] as? Double ?? 0.2

        return ToolExecutionPolicy(
            allowPCC: false,
            piiRedact: piiRedact,
            maxOutputTokens: maxOutputTokens,
            temperature: temperature
        )
    }

    // MARK: - Validation Methods

    /// Validate tone parameter
    /// - Parameter parameters: Input parameters
    /// - Returns: Validated tone string
    /// - Throws: ValidationError if tone is invalid
    private func validateToneParameter(from parameters: [String: AnyCodable]) throws -> String {
        guard let toneValue = parameters["tone"]?.value else {
            // Tone is optional, return default
            return "neutral"
        }

        guard let toneString = toneValue as? String else {
            throw ToolsRegistryError.invalidParameters(
                "tone parameter must be a string. Valid values: technical, friendly, neutral, executive"
            )
        }

        let validTones = ["technical", "friendly", "neutral", "executive"]
        guard validTones.contains(toneString.lowercased()) else {
            throw ToolsRegistryError.invalidParameters(
                "Invalid tone '\(toneString)'. Valid values: \(validTones.joined(separator: ", "))"
            )
        }

        return toneString.lowercased()
    }

    /// Validate length parameter
    /// - Parameter parameters: Input parameters
    /// - Returns: Validated length string
    /// - Throws: ValidationError if length is invalid
    private func validateLengthParameter(from parameters: [String: AnyCodable]) throws -> String {
        guard let lengthValue = parameters["length"]?.value else {
            // Length is optional, return default
            return "medium"
        }

        guard let lengthString = lengthValue as? String else {
            throw ToolsRegistryError.invalidParameters(
                "length parameter must be a string. Valid values: short, medium, long"
            )
        }

        let validLengths = ["short", "medium", "long"]
        guard validLengths.contains(lengthString.lowercased()) else {
            throw ToolsRegistryError.invalidParameters(
                "Invalid length '\(lengthString)'. Valid values: \(validLengths.joined(separator: ", "))"
            )
        }

        return lengthString.lowercased()
    }
}