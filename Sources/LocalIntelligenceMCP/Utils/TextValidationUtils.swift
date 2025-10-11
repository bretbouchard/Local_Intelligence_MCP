//
//  TextValidationUtils.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-08.
//

import Foundation

/// Utility class for text validation operations
/// Provides common validation methods used across text processing tools
class TextValidationUtils {

    // MARK: - Text Content Validation

    /// Validate text input for processing
    /// - Parameters:
    ///   - text: Text to validate
    ///   - maxLength: Maximum allowed length (optional)
    ///   - minLength: Minimum required length (optional)
    ///   - allowEmpty: Whether empty text is allowed
    /// - Throws: ValidationError if validation fails
    static func validateText(
        _ text: String,
        maxLength: Int? = TextProcessingTool.maxInputLength,
        minLength: Int = 1,
        allowEmpty: Bool = false
    ) throws {
        // Check for empty text
        if !allowEmpty && text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw ToolsRegistryError.invalidParameters("Input text cannot be empty")
        }

        // Check minimum length
        if text.count < minLength {
            throw ToolsRegistryError.invalidParameters(
                "Input text must be at least \(minLength) characters long, got \(text.count)"
            )
        }

        // Check maximum length
        if let maxLength = maxLength, text.count > maxLength {
            throw ToolsRegistryError.invalidParameters(
                "Input text exceeds maximum length of \(maxLength) characters, got \(text.count)"
            )
        }
    }

    /// Validate that text contains reasonable content
    /// - Parameter text: Text to validate
    /// - Throws: ValidationError if text appears to be invalid
    static func validateTextContent(_ text: String) throws {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check for obviously invalid content (only special characters, etc.)
        let invalidPatterns = [
            #"^[^\w\s]*$"#, // Only special characters
            #"^\s*$"#, // Only whitespace
            #"^[.,!?;:\-]*$"# // Only punctuation
        ]

        for pattern in invalidPatterns {
            if trimmedText.range(of: pattern, options: .regularExpression) != nil {
                throw ToolsRegistryError.invalidParameters(
                    "Input text appears to contain invalid content"
                )
            }
        }

        // Check for reasonable word count (at least 1 word)
        let words = trimmedText.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        if words.isEmpty {
            throw ToolsRegistryError.invalidParameters(
                "Input text must contain at least one word"
            )
        }
    }

    // MARK: - Parameter Validation

    /// Validate enum parameter
    /// - Parameters:
    ///   - value: Parameter value
    ///   - validValues: Array of valid string values
    ///   - parameterName: Name of the parameter for error messages
    ///   - defaultValue: Default value if parameter is missing
    /// - Returns: Validated string value
    /// - Throws: ValidationError if validation fails
    static func validateEnumParameter<T: Collection>(
        _ value: Any?,
        validValues: T,
        parameterName: String,
        defaultValue: String? = nil
    ) throws -> String where T.Element == String {
        // Check if parameter is missing
        if value == nil {
            if let defaultValue = defaultValue {
                return defaultValue
            } else {
                throw ToolsRegistryError.invalidParameters(
                    "\(parameterName) parameter is required"
                )
            }
        }

        // Check if parameter is a string
        guard let stringValue = value as? String else {
            throw ToolsRegistryError.invalidParameters(
                "\(parameterName) parameter must be a string"
            )
        }

        // Check if value is in valid enum
        let validValuesArray = Array(validValues)
        if !validValuesArray.contains(stringValue.lowercased()) {
            throw ToolsRegistryError.invalidParameters(
                "Invalid \(parameterName) '\(stringValue)'. Valid values: \(validValuesArray.joined(separator: ", "))"
            )
        }

        return stringValue.lowercased()
    }

    /// Validate integer parameter with range constraints
    /// - Parameters:
    ///   - value: Parameter value
    ///   - parameterName: Name of the parameter for error messages
    ///   - minValue: Minimum allowed value (optional)
    ///   - maxValue: Maximum allowed value (optional)
    ///   - defaultValue: Default value if parameter is missing
    /// - Returns: Validated integer value
    /// - Throws: ValidationError if validation fails
    static func validateIntParameter(
        _ value: Any?,
        parameterName: String,
        minValue: Int? = nil,
        maxValue: Int? = nil,
        defaultValue: Int? = nil
    ) throws -> Int {
        // Check if parameter is missing
        if value == nil {
            if let defaultValue = defaultValue {
                return defaultValue
            } else {
                throw ToolsRegistryError.invalidParameters(
                    "\(parameterName) parameter is required"
                )
            }
        }

        // Check if parameter is an integer
        guard let intValue = value as? Int else {
            throw ToolsRegistryError.invalidParameters(
                "\(parameterName) parameter must be an integer"
            )
        }

        // Check minimum value
        if let minValue = minValue, intValue < minValue {
            throw ToolsRegistryError.invalidParameters(
                "\(parameterName) must be at least \(minValue), got \(intValue)"
            )
        }

        // Check maximum value
        if let maxValue = maxValue, intValue > maxValue {
            throw ToolsRegistryError.invalidParameters(
                "\(parameterName) must be at most \(maxValue), got \(intValue)"
            )
        }

        return intValue
    }

    /// Validate boolean parameter
    /// - Parameters:
    ///   - value: Parameter value
    ///   - parameterName: Name of the parameter for error messages
    ///   - defaultValue: Default value if parameter is missing
    /// - Returns: Validated boolean value
    /// - Throws: ValidationError if validation fails
    static func validateBoolParameter(
        _ value: Any?,
        parameterName: String,
        defaultValue: Bool
    ) -> Bool {
        guard let boolValue = value as? Bool else {
            return defaultValue
        }
        return boolValue
    }

    /// Validate double parameter with range constraints
    /// - Parameters:
    ///   - value: Parameter value
    ///   - parameterName: Name of the parameter for error messages
    ///   - minValue: Minimum allowed value (optional)
    ///   - maxValue: Maximum allowed value (optional)
    ///   - defaultValue: Default value if parameter is missing
    /// - Returns: Validated double value
    /// - Throws: ValidationError if validation fails
    static func validateDoubleParameter(
        _ value: Any?,
        parameterName: String,
        minValue: Double? = nil,
        maxValue: Double? = nil,
        defaultValue: Double? = nil
    ) throws -> Double {
        // Check if parameter is missing
        if value == nil {
            if let defaultValue = defaultValue {
                return defaultValue
            } else {
                throw ToolsRegistryError.invalidParameters(
                    "\(parameterName) parameter is required"
                )
            }
        }

        // Check if parameter is a number
        guard let doubleValue = value as? Double else {
            throw ToolsRegistryError.invalidParameters(
                "\(parameterName) parameter must be a number"
            )
        }

        // Check minimum value
        if let minValue = minValue, doubleValue < minValue {
            throw ToolsRegistryError.invalidParameters(
                "\(parameterName) must be at least \(minValue), got \(doubleValue)"
            )
        }

        // Check maximum value
        if let maxValue = maxValue, doubleValue > maxValue {
            throw ToolsRegistryError.invalidParameters(
                "\(parameterName) must be at most \(maxValue), got \(doubleValue)"
            )
        }

        return doubleValue
    }

    // MARK: - Audio Domain Validation

    /// Validate that text appears to be audio-related content
    /// - Parameter text: Text to validate
    /// - Returns: Confidence score (0.0 to 1.0) indicating how likely the text is audio-related
    static func validateAudioDomainContent(_ text: String) -> Double {
        let audioKeywords = [
            "mix", "master", "track", "audio", "sound", "music", "recording",
            "studio", "production", "engineer", "producer", "session",
            "DAW", "plugin", "EQ", "compressor", "reverb", "delay",
            "frequency", "amplitude", "waveform", "bitrate", "sample rate",
            "microphone", "preamp", "interface", "monitor", "speaker",
            "compression", "format", "bit depth", "channel", "sample",
            "gain", "volume", "pan", "automation", "MIDI", "tempo",
            "khz", "hz", "db", "dbfs", "rms", "vst", "au", "aax"
        ]

        let words = text.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }

        guard !words.isEmpty else { return 0.0 }

        let audioWordCount = words.filter { word in
            audioKeywords.contains { word.contains($0) }
        }.count

        return Double(audioWordCount) / Double(words.count)
    }

    /// Validate audio format parameter
    /// - Parameter value: Format value to validate
    /// - Returns: Validated format string
    /// - Throws: ValidationError if format is invalid
    static func validateAudioFormat(_ value: Any?) throws -> String {
        let validFormats = ["wav", "mp3", "aiff", "flac", "m4a", "aac", "ogg", "wma"]

        return try validateEnumParameter(
            value,
            validValues: validFormats,
            parameterName: "format",
            defaultValue: "wav"
        )
    }

    /// Validate session format parameter
    /// - Parameter value: Session format value to validate
    /// - Returns: Validated session format string
    /// - Throws: ValidationError if format is invalid
    static func validateSessionFormat(_ value: Any?) throws -> String {
        let validFormats = ["json", "xml", "txt", "csv"]

        return try validateEnumParameter(
            value,
            validValues: validFormats,
            parameterName: "sessionFormat",
            defaultValue: "json"
        )
    }

    // MARK: - Security Validation

    /// Validate text for potentially harmful content
    /// - Parameter text: Text to validate
    /// - Throws: ValidationError if potentially harmful content is detected
    static func validateTextSecurity(_ text: String) throws {
        // Check for script injection patterns
        let scriptPatterns = [
            #"<script[^>]*>.*?</script>"#,
            #"javascript:"#,
            #"on\w+\s*="#,
            #"eval\s*\("#,
            #"document\."#,
            #"window\."#
        ]

        for pattern in scriptPatterns {
            if text.lowercased().range(of: pattern, options: .regularExpression) != nil {
                throw ToolsRegistryError.invalidParameters(
                    "Input text contains potentially harmful content"
                )
            }
        }

        // Check for path traversal patterns
        let pathTraversalPatterns = [
            #"\.\.[/\\]"#,
            #"%2e%2e[/\\]"#,
            #"/etc/passwd"#,
            #"\\windows\\system32"#
        ]

        for pattern in pathTraversalPatterns {
            if text.lowercased().range(of: pattern, options: .regularExpression) != nil {
                throw ToolsRegistryError.invalidParameters(
                    "Input text contains potentially dangerous path references"
                )
            }
        }
    }

    // MARK: - Policy Validation

    /// Validate policy parameters against security constraints
    /// - Parameters:
    ///   - piiRedact: PII redaction setting
    ///   - maxOutputTokens: Maximum output tokens
    ///   - temperature: Temperature setting
    /// - Throws: ValidationError if policy violates security constraints
    static func validatePolicyParameters(
        piiRedact: Bool?,
        maxOutputTokens: Int?,
        temperature: Double?
    ) throws {
        // Validate max output tokens
        if let maxTokens = maxOutputTokens {
            if maxTokens < 1 {
                throw ToolsRegistryError.invalidParameters(
                    "max_output_tokens must be at least 1, got \(maxTokens)"
                )
            }
            if maxTokens > 4096 {
                throw ToolsRegistryError.invalidParameters(
                    "max_output_tokens cannot exceed 4096, got \(maxTokens)"
                )
            }
        }

        // Validate temperature
        if let temp = temperature {
            if temp < 0.0 || temp > 2.0 {
                throw ToolsRegistryError.invalidParameters(
                    "temperature must be between 0.0 and 2.0, got \(temp)"
                )
            }
        }
    }

    // MARK: - Error Formatting

    /// Format validation error with context
    /// - Parameters:
    ///   - error: Original error
    ///   - toolName: Name of the tool
    ///   - parameterName: Name of the parameter that caused the error (optional)
    ///   - value: Value that caused the error (optional)
    /// - Returns: Formatted ValidationError
    static func formatValidationError(
        _ error: Error,
        toolName: String,
        parameterName: String? = nil,
        value: Any? = nil
    ) -> Error {
        let message: String

        if let paramName = parameterName {
            message = "Tool '\(toolName)': Invalid parameter '\(paramName)'"
        } else {
            message = "Tool '\(toolName)': Validation failed"
        }

        if let value = value {
            return ToolsRegistryError.invalidParameters("\(message) - Value: \(value) - Error: \(error.localizedDescription)")
        } else {
            return ToolsRegistryError.invalidParameters("\(message) - Error: \(error.localizedDescription)")
        }
    }
}