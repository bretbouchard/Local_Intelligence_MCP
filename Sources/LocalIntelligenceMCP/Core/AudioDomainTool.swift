//
//  AudioDomainTool.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-08.
//

import Foundation

/// Base class for audio domain-specific tools
/// Provides common functionality for audio engineering and production operations
public class AudioDomainTool: BaseMCPTool, @unchecked Sendable {

    // MARK: - Constants

    /// Maximum input length for audio processing requests
    static let maxInputLength = 50_000

    /// Default maximum output tokens for audio analysis
    static let defaultMaxOutputTokens = 1024

    /// Supported audio file formats
    static let supportedAudioFormats = ["wav", "mp3", "aiff", "flac", "m4a", "aac"]

    /// Supported session document formats
    static let supportedSessionFormats = ["txt", "json", "xml"]

    // MARK: - Initialization

    public init(
        name: String,
        description: String,
        inputSchema: [String: Any]? = nil,
        logger: Logger,
        securityManager: SecurityManager,
        requiresPermission: [PermissionType] = [.systemInfo],
        offlineCapable: Bool = true
    ) {
        // Default category for audio domain tools
        let category = ToolCategory.audioDomain

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

    // MARK: - Audio Domain Processing Protocol

    /// Process audio-related content with the given parameters
    /// - Parameters:
    ///   - content: Audio-related content (transcripts, session notes, metadata)
    ///   - parameters: Additional processing parameters
    /// - Returns: Processed audio domain content
    func processAudioContent(_ content: String, with parameters: [String: Any]) async throws -> String {
        // Override in subclasses
        throw ToolsRegistryError.toolNotFound(name)
    }

    /// Validate audio-related input content
    /// - Parameter content: Content to validate
    /// - Throws: ValidationError if content is invalid
    func validateAudioContent(_ content: String) throws {
        guard !content.isEmpty else {
            throw ToolsRegistryError.invalidParameters("Audio content cannot be empty")
        }

        guard content.count <= Self.maxInputLength else {
            throw ToolsRegistryError.invalidParameters(
                "Audio content exceeds maximum length of \(Self.maxInputLength) characters"
            )
        }
    }

    /// Validate audio file format
    /// - Parameter format: File format to validate
    /// - Throws: ValidationError if format is unsupported
    func validateAudioFormat(_ format: String) throws {
        guard Self.supportedAudioFormats.contains(format.lowercased()) else {
            throw ToolsRegistryError.invalidParameters(
                "Unsupported audio format: \(format). Supported formats: \(Self.supportedAudioFormats.joined(separator: ", "))"
            )
        }
    }

    /// Validate session document format
    /// - Parameter format: Document format to validate
    /// - Throws: ValidationError if format is unsupported
    func validateSessionFormat(_ format: String) throws {
        guard Self.supportedSessionFormats.contains(format.lowercased()) else {
            throw ToolsRegistryError.invalidParameters(
                "Unsupported session format: \(format). Supported formats: \(Self.supportedSessionFormats.joined(separator: ", "))"
            )
        }
    }

    // MARK: - Helper Methods

    /// Extract audio content parameter from request parameters
    /// - Parameter parameters: Request parameters
    /// - Returns: Extracted audio content string
    /// - Throws: ValidationError if content parameter is missing or invalid
    func extractAudioContentParameter(from parameters: [String: AnyCodable]) throws -> String {
        guard let contentValue = parameters["content"]?.value as? String else {
            throw ToolsRegistryError.invalidParameters("content parameter is required")
        }

        try validateAudioContent(contentValue)
        return contentValue
    }

    /// Extract optional audio content parameter from request parameters
    /// - Parameter parameters: Request parameters
    /// - Returns: Optional audio content string
    func extractOptionalAudioContentParameter(from parameters: [String: AnyCodable]) async -> String? {
        guard let contentValue = parameters["content"]?.value as? String else {
            return nil
        }

        do {
            try validateAudioContent(contentValue)
            return contentValue
        } catch {
            await logger.warning("Invalid optional audio content parameter: \(error.localizedDescription)", category: .general, metadata: [:])
            return nil
        }
    }

    /// Extract audio file format parameter
    /// - Parameter parameters: Request parameters
    /// - Returns: Audio format string
    /// - Throws: ValidationError if format parameter is invalid
    func extractAudioFormatParameter(from parameters: [String: AnyCodable]) throws -> String {
        let format = parameters["format"]?.value as? String ?? "wav"
        try validateAudioFormat(format)
        return format.lowercased()
    }

    /// Extract session format parameter
    /// - Parameter parameters: Request parameters
    /// - Returns: Session format string
    /// - Throws: ValidationError if format parameter is invalid
    func extractSessionFormatParameter(from parameters: [String: AnyCodable]) throws -> String {
        let format = parameters["sessionFormat"]?.value as? String ?? "json"
        try validateSessionFormat(format)
        return format.lowercased()
    }

    /// Apply policy to audio domain output
    /// - Parameters:
    ///   - content: Original content output
    ///   - policy: Execution policy to apply
    /// - Returns: Policy-adjusted content
    func applyPolicy(to content: String, with policy: ToolExecutionPolicy?) -> String {
        guard let policy = policy else { return content }

        var processedContent = content

        // Apply token limit
        if policy.maxOutputTokens > 0 {
            let estimatedTokens = estimateTokens(processedContent)
            if estimatedTokens > policy.maxOutputTokens {
                // Truncate content to fit token limit
                let targetCharacters = policy.maxOutputTokens * 4
                processedContent = String(processedContent.prefix(targetCharacters))
                if !processedContent.isEmpty {
                    processedContent += "..."
                }
            }
        }

        // Apply PII redaction if required (especially important for audio session data)
        if policy.piiRedact {
            processedContent = redactPII(from: processedContent)
        }

        return processedContent
    }

    /// Redact PII from audio-related content
    /// Enhanced version for audio domain (artist names, client info, etc.)
    /// - Parameter content: Content to process
    /// - Returns: Content with PII redacted
    private func redactPII(from content: String) -> String {
        var redactedContent = content

        // Email redaction
        let emailPattern = #"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}"#
        redactedContent = redactedContent.replacingOccurrences(
            of: emailPattern,
            with: "[REDACTED_EMAIL]",
            options: .regularExpression
        )

        // Phone number redaction
        let phonePattern = #"\b\d{3}[-.]?\d{3}[-.]?\d{4}\b"#
        redactedContent = redactedContent.replacingOccurrences(
            of: phonePattern,
            with: "[REDACTED_PHONE]",
            options: .regularExpression
        )

        // Client name redaction (common in audio session notes)
        let clientPattern = #"(?i)client:\s*([A-Z][a-z]+\s[A-Z][a-z]+)"#
        redactedContent = redactedContent.replacingOccurrences(
            of: clientPattern,
            with: "client: [REDACTED_CLIENT]",
            options: .regularExpression
        )

        // Artist name redaction
        let artistPattern = #"(?i)artist:\s*([A-Z][a-z]+\s([A-Z][a-z]+\s)?)?[A-Z][a-z]+)"#
        redactedContent = redactedContent.replacingOccurrences(
            of: artistPattern,
            with: "artist: [REDACTED_ARTIST]",
            options: .regularExpression
        )

        // API key pattern redaction
        let apiKeyPattern = #"[a-zA-Z0-9]{20,}"#
        redactedContent = redactedContent.replacingOccurrences(
            of: apiKeyPattern,
            with: "[REDACTED_KEY]",
            options: .regularExpression
        )

        return redactedContent
    }

    /// Estimate token count for audio-related content
    /// - Parameter content: Content to analyze
    /// - Returns: Estimated token count
    func estimateTokens(_ content: String) -> Int {
        // Audio content often has technical terms that use more tokens
        // This is a rough approximation - real implementation would use a tokenizer
        return Int(ceil(Double(content.count) / 3.5))
    }

    // MARK: - Validation Helpers

    /// Validate audio domain processing parameters
    /// - Parameters:
    ///   - parameters: Input parameters
    ///   - requiredFields: List of required field names
    /// - Throws: ValidationError if validation fails
    func validateAudioProcessingParameters(
        _ parameters: [String: AnyCodable],
        requiredFields: [String] = ["content"]
    ) async throws {
        for field in requiredFields {
            guard parameters[field]?.value != nil else {
                throw ToolsRegistryError.invalidParameters("\(field) parameter is required")
            }
        }

        // Validate content parameter if present
        if let content = await extractOptionalAudioContentParameter(from: parameters) {
            try validateAudioContent(content)
        }
    }

    /// Check if content contains audio-related keywords
    /// - Parameter content: Content to analyze
    /// - Returns: True if content appears to be audio-related
    func isAudioRelatedContent(_ content: String) -> Bool {
        let audioKeywords = [
            "mix", "master", "track", "audio", "sound", "music", "recording",
            "studio", "production", "engineer", "producer", "session",
            "DAW", "plugin", "EQ", "compressor", "reverb", "delay",
            "frequency", "amplitude", "waveform", "bitrate", "sample rate",
            "microphone", "preamp", "interface", "monitor", "speaker"
        ]

        let lowercaseContent = content.lowercased()
        return audioKeywords.contains { lowercaseContent.contains($0) }
    }
}

// MARK: - Supporting Types

/// Audio processing validation errors
enum AudioProcessingError: Error, LocalizedError {
    case unsupportedFormat(String)
    case contentTooLarge(Int)
    case contentEmpty
    case invalidAudioData(String)
    case processingFailed(String)
    case unsupportedOperation(String)
    case invalidInput(String)
    case validationError(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedFormat(let format):
            return "Unsupported audio format: \(format)"
        case .contentTooLarge(let size):
            return "Audio content is too large (\(size) characters). Maximum allowed is \(AudioDomainTool.maxInputLength)."
        case .contentEmpty:
            return "Audio content cannot be empty."
        case .invalidAudioData(let reason):
            return "Invalid audio data: \(reason)"
        case .processingFailed(let reason):
            return "Audio processing failed: \(reason)"
        case .unsupportedOperation(let operation):
            return "Unsupported audio operation: \(operation)"
        case .invalidInput(let reason):
            return "Invalid input: \(reason)"
        case .validationError(let reason):
            return "Validation error: \(reason)"
        }
    }
}

/// Audio file metadata structure
struct AudioFileMetadata: Codable, Sendable {
    let filename: String
    let format: String
    let duration: TimeInterval?
    let sampleRate: Int?
    let bitDepth: Int?
    let channels: Int?
    let bitrate: Int?
    let fileSize: Int64?
    let createdDate: Date?
    let modifiedDate: Date?

    init(
        filename: String,
        format: String,
        duration: TimeInterval? = nil,
        sampleRate: Int? = nil,
        bitDepth: Int? = nil,
        channels: Int? = nil,
        bitrate: Int? = nil,
        fileSize: Int64? = nil,
        createdDate: Date? = nil,
        modifiedDate: Date? = nil
    ) {
        self.filename = filename
        self.format = format
        self.duration = duration
        self.sampleRate = sampleRate
        self.bitDepth = bitDepth
        self.channels = channels
        self.bitrate = bitrate
        self.fileSize = fileSize
        self.createdDate = createdDate
        self.modifiedDate = modifiedDate
    }
}

/// Audio session information structure
struct AudioSessionInfo: Codable, Sendable {
    let sessionId: String
    let projectName: String?
    let sessionDate: Date?
    let engineer: String?
    let producer: String?
    let studio: String?
    let DAW: String?
    let trackCount: Int?
    let duration: TimeInterval?
    let notes: String?
    let metadata: [String: AnyCodable]

    init(
        sessionId: String = UUID().uuidString,
        projectName: String? = nil,
        sessionDate: Date? = nil,
        engineer: String? = nil,
        producer: String? = nil,
        studio: String? = nil,
        DAW: String? = nil,
        trackCount: Int? = nil,
        duration: TimeInterval? = nil,
        notes: String? = nil,
        metadata: [String: AnyCodable] = [:]
    ) {
        self.sessionId = sessionId
        self.projectName = projectName
        self.sessionDate = sessionDate
        self.engineer = engineer
        self.producer = producer
        self.studio = studio
        self.DAW = DAW
        self.trackCount = trackCount
        self.duration = duration
        self.notes = notes
        self.metadata = metadata
    }
}

/// Audio processing result
struct AudioProcessingResult: Codable, Sendable {
    let processedContent: String
    let tokensUsed: Int
    let audioMetadata: AudioFileMetadata?
    let sessionInfo: AudioSessionInfo?
    let metadata: [String: AnyCodable]

    init(
        processedContent: String,
        tokensUsed: Int,
        audioMetadata: AudioFileMetadata? = nil,
        sessionInfo: AudioSessionInfo? = nil,
        metadata: [String: AnyCodable] = [:]
    ) {
        self.processedContent = processedContent
        self.tokensUsed = tokensUsed
        self.audioMetadata = audioMetadata
        self.sessionInfo = sessionInfo
        self.metadata = metadata
    }
}