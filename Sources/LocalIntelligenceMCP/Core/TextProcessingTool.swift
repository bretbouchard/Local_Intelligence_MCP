//
//  TextProcessingTool.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-08.
//

import Foundation

/// Base class for text processing tools
/// Provides common functionality for text-centric operations
class TextProcessingTool: BaseMCPTool, @unchecked Sendable {

    // MARK: - Constants

    /// Maximum input length for text processing
    static let maxInputLength = 20_000

    /// Default maximum output tokens
    static let defaultMaxOutputTokens = 512

    // MARK: - Initialization

    init(
        name: String,
        description: String,
        inputSchema: [String: Any]? = nil,
        logger: Logger,
        securityManager: SecurityManager,
        requiresPermission: [PermissionType] = [.systemInfo],
        offlineCapable: Bool = true
    ) {
        // Default category for text processing tools
        let category = ToolCategory.textProcessing

        super.init(
            name: name,
            description: description,
            inputSchema: inputSchema ?? [:],
            category: category,
            requiresPermission: requiresPermission,
            offlineCapable: offlineCapable,
            logger: logger,
            securityManager: securityManager
        )
    }

    // MARK: - Text Processing Protocol

    /// Process text with the given parameters
    /// - Parameters:
    ///   - text: Input text to process
    ///   - parameters: Additional processing parameters
    /// - Returns: Processed text
    func processText(_ text: String, with parameters: [String: Any]) async throws -> String {
        // Override in subclasses
        throw ToolsRegistryError.toolNotFound(name)
    }

    /// Validate input text
    /// - Parameter text: Text to validate
    /// - Throws: ValidationError if text is invalid
    func validateInput(_ text: String) throws {
        guard !text.isEmpty else {
            throw ToolsRegistryError.invalidParameters("Input text cannot be empty")
        }

        guard text.count <= Self.maxInputLength else {
            throw ToolsRegistryError.invalidParameters(
                "Input text exceeds maximum length of \(Self.maxInputLength) characters"
            )
        }
    }

    /// Estimate token count for text
    /// - Parameter text: Text to analyze
    /// - Returns: Estimated token count
    func estimateTokens(_ text: String) -> Int {
        // Simple estimation: ~4 characters per token for English
        // This is a rough approximation - real implementation would use a tokenizer
        return Int(ceil(Double(text.count) / 4.0))
    }

    // MARK: - Helper Methods

    /// Extract text parameter from request parameters
    /// - Parameter parameters: Request parameters
    /// - Returns: Extracted text string
    /// - Throws: ValidationError if text parameter is missing or invalid
    func extractTextParameter(from parameters: [String: AnyCodable]) throws -> String {
        guard let textValue = parameters["text"]?.value as? String else {
            throw ToolsRegistryError.invalidParameters("text parameter is required")
        }

        try validateInput(textValue)
        return textValue
    }

    /// Extract optional text parameter from request parameters
    /// - Parameter parameters: Request parameters
    /// - Returns: Optional text string
    func extractOptionalTextParameter(from parameters: [String: AnyCodable]) -> String? {
        guard let textValue = parameters["text"]?.value as? String else {
            return nil
        }

        do {
            try validateInput(textValue)
            return textValue
        } catch {
            Task {
                await logger.warning("Invalid optional text parameter: \(error.localizedDescription)", metadata: [:])
            }
            return nil
        }
    }

    /// Apply policy to text output
    /// - Parameters:
    ///   - text: Original text output
    ///   - policy: Execution policy to apply
    /// - Returns: Policy-adjusted text
    func applyPolicy(to text: String, with policy: ToolExecutionPolicy?) -> String {
        guard let policy = policy else { return text }

        var processedText = text

        // Apply token limit
        if policy.maxOutputTokens > 0 {
            let estimatedTokens = estimateTokens(processedText)
            if estimatedTokens > policy.maxOutputTokens {
                // Truncate text to fit token limit
                let targetCharacters = policy.maxOutputTokens * 4
                processedText = String(processedText.prefix(targetCharacters))
                if !processedText.isEmpty {
                    processedText += "..."
                }
            }
        }

        // Apply PII redaction if required
        if policy.piiRedact {
            processedText = redactPII(from: processedText)
        }

        return processedText
    }

    /// Redact PII from text
    /// - Parameter text: Text to process
    /// - Returns: Text with PII redacted
    private func redactPII(from text: String) -> String {
        var redactedText = text

        // Email redaction
        let emailPattern = #"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}"#
        redactedText = redactedText.replacingOccurrences(
            of: emailPattern,
            with: "[REDACTED_EMAIL]",
            options: .regularExpression
        )

        // Phone number redaction (basic pattern)
        let phonePattern = #"\b\d{3}[-.]?\d{3}[-.]?\d{4}\b"#
        redactedText = redactedText.replacingOccurrences(
            of: phonePattern,
            with: "[REDACTED_PHONE]",
            options: .regularExpression
        )

        // API key pattern redaction
        let apiKeyPattern = #"[a-zA-Z0-9]{20,}"#
        redactedText = redactedText.replacingOccurrences(
            of: apiKeyPattern,
            with: "[REDACTED_KEY]",
            options: .regularExpression
        )

        return redactedText
    }

    // MARK: - Validation Helpers

    /// Validate text processing parameters
    /// - Parameters:
    ///   - parameters: Input parameters
    ///   - requiredFields: List of required field names
    /// - Throws: ValidationError if validation fails
    func validateTextProcessingParameters(
        _ parameters: [String: AnyCodable],
        requiredFields: [String] = ["text"]
    ) throws {
        for field in requiredFields {
            guard parameters[field]?.value != nil else {
                throw ToolsRegistryError.invalidParameters("\(field) parameter is required")
            }
        }

        // Validate text parameter if present
        if let text = extractOptionalTextParameter(from: parameters) {
            try validateInput(text)
        }
    }
}

// MARK: - Supporting Types

/// Text processing validation errors
enum TextProcessingError: Error, LocalizedError {
    case textTooLarge(Int)
    case textEmpty
    case invalidCharacter(String)
    case processingFailed(String)

    var errorDescription: String? {
        switch self {
        case .textTooLarge(let size):
            return "Text is too large (\(size) characters). Maximum allowed is \(TextProcessingTool.maxInputLength)."
        case .textEmpty:
            return "Text cannot be empty."
        case .invalidCharacter(let character):
            return "Invalid character detected: '\(character)'"
        case .processingFailed(let reason):
            return "Text processing failed: \(reason)"
        }
    }
}

/// Text chunking result
struct TextChunk: Codable, Sendable {
    let id: String
    let text: String
    let index: Int
    let metadata: [String: AnyCodable]

    init(id: String = UUID().uuidString, text: String, index: Int, metadata: [String: AnyCodable] = [:]) {
        self.id = id
        self.text = text
        self.index = index
        self.metadata = metadata
    }
}

/// Text processing result
struct TextProcessingResult: Codable, Sendable {
    let processedText: String
    let tokensUsed: Int
    let chunks: [TextChunk]?
    let metadata: [String: AnyCodable]

    init(processedText: String, tokensUsed: Int, chunks: [TextChunk]? = nil, metadata: [String: AnyCodable] = [:]) {
        self.processedText = processedText
        self.tokensUsed = tokensUsed
        self.chunks = chunks
        self.metadata = metadata
    }
}