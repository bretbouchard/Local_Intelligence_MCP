//
//  TextNormalizeTool.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-08.
//

import Foundation

/// Text normalization tool for cleaning and formatting text
/// Implements apple.text.normalize specification from audio tools specification
class TextNormalizeTool: TextProcessingTool, @unchecked Sendable {

    // MARK: - Initialization

    init(logger: Logger, securityManager: SecurityManager) {
        let inputSchema: [String: Any] = [
            "type": "object",
            "properties": [
                "text": [
                    "type": "string",
                    "description": "Text to normalize and clean formatting (notes, logs, transcripts, or other audio-related text)"
                ]
            ],
            "required": ["text"]
        ]

        super.init(
            name: "apple_text_normalize",
            description: "Clean formatting: fix spacing, quotes, lists, headings",
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

            // Create processing parameters dictionary
            let processingParameters: [String: Any] = [
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
                "Text normalize tool execution failed",
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
        await logger.debug(
            "Processing text normalization",
            metadata: [
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

        // Generate normalized text
        let normalizedText = generateNormalizedText(from: processedText)

        await logger.info(
            "Text normalization completed",
            metadata: [
                "originalLength": text.count,
                "normalizedLength": normalizedText.count,
                "estimatedTokens": estimateTokens(normalizedText)
            ]
        )

        return normalizedText
    }

    // MARK: - Private Methods

    /// Generate normalized text with cleaned formatting
    /// - Parameter text: Text to normalize
    /// - Returns: Normalized text
    private func generateNormalizedText(from text: String) -> String {
        var result = text

        // Apply normalization steps in order
        result = normalizeSpacing(result)
        result = normalizeQuotes(result)
        result = normalizeLists(result)
        result = normalizeHeadings(result)
        result = normalizePunctuation(result)
        result = normalizeLineBreaks(result)
        result = normalizeSpecialCharacters(result)

        return result
    }

    /// Normalize spacing issues
    /// - Parameter text: Text to process
    /// - Returns: Text with normalized spacing
    private func normalizeSpacing(_ text: String) -> String {
        var result = text

        // Remove extra spaces at beginning and end
        result = result.trimmingCharacters(in: .whitespacesAndNewlines)

        // Replace multiple spaces with single space
        result = result.replacingOccurrences(of: " +", with: " ", options: .regularExpression)

        // Fix spacing around punctuation
        result = result.replacingOccurrences(of: " +([,.!?;:])", with: "$1", options: .regularExpression)
        result = result.replacingOccurrences(of: "([\\[\\({]) +", with: "$1", options: .regularExpression)
        result = result.replacingOccurrences(of: " +([\\])}])", with: "$1", options: .regularExpression)

        // Ensure single space after punctuation if not at end
        result = result.replacingOccurrences(of: "([,.!?;:])(?!\\s|$)", with: "$1 ", options: .regularExpression)

        // Fix spacing around quotes
        result = result.replacingOccurrences(of: " ?\" ?([^\"]+) ?\" ?", with: " \"$1\" ", options: .regularExpression)
        result = result.replacingOccurrences(of: " ?' ?([^']+) ?' ?", with: " '$1' ", options: .regularExpression)

        // Clean up any double spaces that might have been created
        result = result.replacingOccurrences(of: " +", with: " ", options: .regularExpression)

        return result
    }

    /// Normalize quotation marks
    /// - Parameter text: Text to process
    /// - Returns: Text with normalized quotes
    private func normalizeQuotes(_ text: String) -> String {
        var result = text

        // Convert smart quotes to straight quotes for consistency
        result = result.replacingOccurrences(of: "\u{201C}", with: "\"")  // Left double quote
        result = result.replacingOccurrences(of: "\u{201D}", with: "\"")  // Right double quote
        result = result.replacingOccurrences(of: "\u{2018}", with: "'")   // Left single quote
        result = result.replacingOccurrences(of: "\u{2019}", with: "'")   // Right single quote

        // Ensure paired quotes
        result = fixUnpairedQuotes(result)

        return result
    }

    /// Fix unpaired quotation marks
    /// - Parameter text: Text to process
    /// - Returns: Text with fixed quote pairs
    private func fixUnpairedQuotes(_ text: String) -> String {
        var result = text
        let quoteChar = "\""

        // Count quotes
        let quoteCount = result.filter { $0 == Character(quoteChar) }.count

        // If odd number of quotes, add missing closing quote
        if quoteCount % 2 == 1 {
            // Find the last quote and add a closing quote if appropriate
            if let lastQuoteRange = result.range(of: quoteChar, options: .backwards) {
                let afterQuote = String(result[result.index(after: lastQuoteRange.upperBound)...])
                if afterQuote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    // End quote - add opening quote
                    result.insert(Character(quoteChar), at: result.startIndex)
                } else {
                    // Mid-text quote - add closing quote at end
                    result += quoteChar
                }
            }
        }

        return result
    }

    /// Normalize list formatting
    /// - Parameter text: Text to process
    /// - Returns: Text with normalized lists
    private func normalizeLists(_ text: String) -> String {
        var result = text

        // Normalize bullet points
        result = result.replacingOccurrences(of: #"^[ •·▪▫◦‣⁃]\s*"#, with: "• ", options: .regularExpression)
        result = result.replacingOccurrences(of: #"^\s*[-*]\s+"#, with: "• ", options: .regularExpression)

        // Normalize numbered lists
        result = result.replacingOccurrences(of: "^\\s*(\\d+)\\.\\s*", with: "$1. ", options: .regularExpression)
        result = result.replacingOccurrences(of: "^\\s*(\\d+)\\)\\s*", with: "$1. ", options: .regularExpression)
        result = result.replacingOccurrences(of: "^\\s*\\((\\d+)\\)\\s*", with: "$1. ", options: .regularExpression)

        // Normalize lettered lists
        result = result.replacingOccurrences(of: "^\\s*([a-zA-Z])\\.\\s*", with: "$1. ", options: .regularExpression)
        result = result.replacingOccurrences(of: "^\\s*([a-zA-Z])\\)\\s*", with: "$1. ", options: .regularExpression)

        // Fix inconsistent list indentation
        result = normalizeListIndentation(result)

        return result
    }

    /// Normalize list indentation
    /// - Parameter text: Text to process
    /// - Returns: Text with consistent list indentation
    private func normalizeListIndentation(_ text: String) -> String {
        let lines = text.components(separatedBy: .newlines)
        var normalizedLines: [String] = []
        var currentIndentLevel = 0

        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)

            if isListItem(trimmedLine) {
                // Calculate proper indentation based on list level
                let indentLevel = calculateListIndentLevel(for: trimmedLine)
                let indent = String(repeating: "  ", count: indentLevel)
                normalizedLines.append(indent + trimmedLine)
            } else {
                // Non-list line, preserve relative indentation but clean up
                if !trimmedLine.isEmpty {
                    let indent = String(repeating: "  ", count: currentIndentLevel)
                    normalizedLines.append(indent + trimmedLine)
                } else {
                    normalizedLines.append("")
                }
            }
        }

        return normalizedLines.joined(separator: "\n")
    }

    /// Check if a line is a list item
    /// - Parameter line: Line to check
    /// - Returns: True if line is a list item
    private func isListItem(_ line: String) -> Bool {
        let patterns = [
            #"^•\s+"#,
            #"^\d+\.\s+"#,
            #"^[a-zA-Z]\.\s+"#
        ]

        return patterns.contains { line.range(of: $0, options: .regularExpression) != nil }
    }

    /// Calculate list indent level for a line
    /// - Parameter line: List item line
    /// - Returns: Indent level
    private func calculateListIndentLevel(for line: String) -> Int {
        // Simple heuristic: count leading spaces divided by 2
        let leadingSpaces = line.prefix { $0 == " " }.count
        return leadingSpaces / 2
    }

    /// Normalize headings
    /// - Parameter text: Text to process
    /// - Returns: Text with normalized headings
    private func normalizeHeadings(_ text: String) -> String {
        var result = text

        // Normalize markdown headings (# ## ### etc.)
        result = result.replacingOccurrences(of: "^\\s*#{1,6}\\s*", with: "# ", options: .regularExpression)

        // Normalize ALL CAPS headings (common in session notes)
        result = result.replacingOccurrences(of: "^\\s*([A-Z][A-Z\\s]{5,})\\s*$", with: "# $1", options: .regularExpression)

        // Normalize underlined headings (common in plain text)
        result = normalizeUnderlinedHeadings(result)

        return result
    }

    /// Normalize underlined headings
    /// - Parameter text: Text to process
    /// - Returns: Text with normalized underlined headings
    private func normalizeUnderlinedHeadings(_ text: String) -> String {
        let lines = text.components(separatedBy: .newlines)
        var normalizedLines: [String] = []
        var i = 0

        while i < lines.count {
            let currentLine = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)

            // Check if next line is an underline
            if i + 1 < lines.count {
                let nextLine = lines[i + 1].trimmingCharacters(in: .whitespacesAndNewlines)

                if isUnderline(nextLine) {
                    // Convert to markdown heading
                    let level = determineHeadingLevel(from: nextLine)
                    let heading = String(repeating: "#", count: level) + " " + currentLine
                    normalizedLines.append(heading)
                    i += 2 // Skip the underline
                    continue
                }
            }

            normalizedLines.append(currentLine)
            i += 1
        }

        return normalizedLines.joined(separator: "\n")
    }

    /// Check if a line is an underline
    /// - Parameter line: Line to check
    /// - Returns: True if line is an underline
    private func isUnderline(_ line: String) -> Bool {
        let underlinePatterns = [
            #"^=+$"#,  // Level 1
            #"^-+$"#,  // Level 2
            #"^~+$"#   // Alternative
        ]

        return underlinePatterns.contains { line.range(of: $0, options: .regularExpression) != nil }
    }

    /// Determine heading level from underline
    /// - Parameter line: Underline line
    /// - Returns: Heading level (1-6)
    private func determineHeadingLevel(from line: String) -> Int {
        if line.range(of: #"^=+$"#, options: .regularExpression) != nil {
            return 1
        } else if line.range(of: #"^-+$"#, options: .regularExpression) != nil {
            return 2
        } else {
            return 2 // Default to level 2
        }
    }

    /// Normalize punctuation
    /// - Parameter text: Text to process
    /// - Returns: Text with normalized punctuation
    private func normalizePunctuation(_ text: String) -> String {
        var result = text

        // Fix spacing around common punctuation
        result = result.replacingOccurrences(of: ",\\s*,", with: ", ", options: .regularExpression)
        result = result.replacingOccurrences(of: "\\.\\s*\\.", with: ". ", options: .regularExpression)
        result = result.replacingOccurrences(of: "!\\s*!", with: "! ", options: .regularExpression)
        result = result.replacingOccurrences(of: "\\?\\s*\\?", with: "? ", options: .regularExpression)

        // Fix ellipses
        result = result.replacingOccurrences(of: "\\.\\.+", with: "...", options: .regularExpression)

        // Fix multiple punctuation at end of sentences
        result = result.replacingOccurrences(of: "([.!?])\\1+", with: "$1", options: .regularExpression)

        return result
    }

    /// Normalize line breaks
    /// - Parameter text: Text to process
    /// - Returns: Text with normalized line breaks
    private func normalizeLineBreaks(_ text: String) -> String {
        var result = text

        // Convert Windows line endings to Unix
        result = result.replacingOccurrences(of: "\r\n", with: "\n")

        // Remove excessive consecutive blank lines
        result = result.replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)

        // Ensure single newline at end of file
        result = result.trimmingCharacters(in: .whitespacesAndNewlines)
        if !result.isEmpty {
            result += "\n"
        }

        return result
    }

    /// Normalize special characters common in audio/transcription text
    /// - Parameter text: Text to process
    /// - Returns: Text with normalized special characters
    private func normalizeSpecialCharacters(_ text: String) -> String {
        var result = text

        // Common transcription artifacts
        result = result.replacingOccurrences(of: "\\[.*?\\]", with: "", options: .regularExpression) // Remove [inaudible], [laughter], etc.
        result = result.replacingOccurrences(of: "\\(.*?\\)", with: "", options: .regularExpression) // Remove parenthetical notes
        result = result.replacingOccurrences(of: "\\*.*?\\*", with: "", options: .regularExpression) // Remove italicized notes

        // Clean up audio-specific notation
        result = normalizeAudioNotation(result)

        return result
    }

    /// Normalize audio-specific notation
    /// - Parameter text: Text to process
    /// - Returns: Text with normalized audio notation
    private func normalizeAudioNotation(_ text: String) -> String {
        var result = text

        // Normalize time stamps (00:00:00 format)
        result = result.replacingOccurrences(of: "\\b\\d{1,2}:\\d{2}:\\d{2}\\b", with: "[$0]", options: .regularExpression)

        // Normalize track names
        result = result.replacingOccurrences(of: "\"([^\"]+)\"\\s*[:|-]", with: "Track: $1 -", options: .regularExpression)

        // Normalize DAW-specific terminology
        result = normalizeDAWTerminology(result)

        return result
    }

    /// Normalize DAW-specific terminology
    /// - Parameter text: Text to process
    /// - Returns: Text with normalized DAW terminology
    private func normalizeDAWTerminology(_ text: String) -> String {
        var result = text

        // Common DAW terminology normalization
        let dawTerms: [String: String] = [
            "EQ": "equalizer",
            "FX": "effects",
            "VST": "plugin",
            "AU": "plugin",
            "RTAS": "plugin",
            "AAX": "plugin",
            "DAW": "digital audio workstation",
            "MIDI": "MIDI", // Keep as is
            "CPU": "processor",
            "RAM": "memory",
            "Hz": "Hertz",
            "kHz": "kilohertz",
            "dB": "decibels",
            "dBFS": "decibels relative to full scale",
            "RMS": "root mean square"
        ]

        for (abbr, full) in dawTerms {
            result = result.replacingOccurrences(of: "\\b\(abbr)\\b", with: full, options: .regularExpression)
        }

        return result
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
}