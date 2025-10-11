//
//  ParameterValidationUtils.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-09.
//

import Foundation

/// Utility class for standardized parameter validation across all MCP tools
/// Eliminates code duplication and provides consistent validation patterns
public class ParameterValidationUtils {

    // MARK: - Enum Parameter Validation

    /// Validate enum parameter with type safety
    /// - Parameters:
    ///   - parameters: Input parameters dictionary
    ///   - key: Parameter key to validate
    ///   - type: Enum type to validate against
    ///   - defaultValue: Default value if parameter is missing
    ///   - required: Whether parameter is required
    ///   - context: Execution context for error reporting
    /// - Returns: Validated enum value
    /// - Throws: ValidationError if validation fails
    public static func validateEnumParameter<T: CaseIterable>(
        _ parameters: [String: AnyCodable],
        key: String,
        type: T.Type,
        defaultValue: T? = nil,
        required: Bool = false,
        context: MCPExecutionContext
    ) throws -> T where T: RawRepresentable, T.RawValue == String {

        guard let value = parameters[key]?.value else {
            if required {
                throw ErrorHandlingUtils.createValidationError(
                    message: "Required parameter '\(key)' is missing",
                    field: key,
                    toolName: context.toolName
                )
            } else if let defaultValue = defaultValue {
                return defaultValue
            } else {
                throw ErrorHandlingUtils.createValidationError(
                    message: "Optional parameter '\(key)' is missing and no default provided",
                    field: key,
                    toolName: context.toolName
                )
            }
        }

        guard let stringValue = value as? String else {
            throw ErrorHandlingUtils.createValidationError(
                message: "Parameter '\(key)' must be a string",
                field: key,
                value: value,
                toolName: context.toolName
            )
        }

        let validValues = T.allCases.map { $0.rawValue.lowercased() }
        guard validValues.contains(stringValue.lowercased()) else {
            throw ErrorHandlingUtils.createValidationError(
                message: "Invalid value for parameter '\(key)'",
                field: key,
                value: stringValue,
                toolName: context.toolName
            )
        }

        // Find matching enum case (case insensitive)
        for caseValue in T.allCases {
            if caseValue.rawValue.lowercased() == stringValue.lowercased() {
                return caseValue
            }
        }

        // This should not be reached due to the validation above
        throw ErrorHandlingUtils.createValidationError(
            message: "Failed to match enum value for parameter '\(key)'",
            field: key,
            value: stringValue,
            toolName: context.toolName
        )
    }

    // MARK: - Numeric Parameter Validation

    /// Validate numeric parameter with range constraints
    /// - Parameters:
    ///   - parameters: Input parameters dictionary
    ///   - key: Parameter key to validate
    ///   - min: Minimum allowed value
    ///   - max: Maximum allowed value
    ///   - defaultValue: Default value if parameter is missing
    ///   - required: Whether parameter is required
    ///   - context: Execution context for error reporting
    /// - Returns: Validated numeric value
    /// - Throws: ValidationError if validation fails
    public static func validateNumericParameter<T: Comparable>(
        _ parameters: [String: AnyCodable],
        key: String,
        min: T? = nil,
        max: T? = nil,
        defaultValue: T? = nil,
        required: Bool = false,
        context: MCPExecutionContext
    ) throws -> T {

        guard let value = parameters[key]?.value else {
            if required {
                throw ErrorHandlingUtils.createValidationError(
                    message: "Required parameter '\(key)' is missing",
                    field: key,
                    toolName: context.toolName
                )
            } else if let defaultValue = defaultValue {
                return defaultValue
            } else {
                throw ErrorHandlingUtils.createValidationError(
                    message: "Optional parameter '\(key)' is missing and no default provided",
                    field: key,
                    toolName: context.toolName
                )
            }
        }

        guard let numericValue = value as? T else {
            throw ErrorHandlingUtils.createValidationError(
                message: "Parameter '\(key)' has invalid type",
                field: key,
                value: value,
                toolName: context.toolName
            )
        }

        if let min = min, numericValue < min {
            throw ErrorHandlingUtils.createValidationError(
                message: "Parameter '\(key)' is below minimum allowed value",
                field: key,
                value: numericValue,
                toolName: context.toolName
            )
        }

        if let max = max, numericValue > max {
            throw ErrorHandlingUtils.createValidationError(
                message: "Parameter '\(key)' exceeds maximum allowed value",
                field: key,
                value: numericValue,
                toolName: context.toolName
            )
        }

        return numericValue
    }

    // MARK: - String Parameter Validation

    /// Validate string parameter with length constraints
    /// - Parameters:
    ///   - parameters: Input parameters dictionary
    ///   - key: Parameter key to validate
    ///   - minLength: Minimum allowed length
    ///   - maxLength: Maximum allowed length
    ///   - defaultValue: Default value if parameter is missing
    ///   - required: Whether parameter is required
    ///   - context: Execution context for error reporting
    /// - Returns: Validated string value
    /// - Throws: ValidationError if validation fails
    public static func validateStringParameter(
        _ parameters: [String: AnyCodable],
        key: String,
        minLength: Int = 0,
        maxLength: Int? = nil,
        defaultValue: String? = nil,
        required: Bool = false,
        context: MCPExecutionContext
    ) throws -> String {

        guard let value = parameters[key]?.value else {
            if required {
                throw ErrorHandlingUtils.createValidationError(
                    message: "Required parameter '\(key)' is missing",
                    field: key,
                    toolName: context.toolName
                )
            } else if let defaultValue = defaultValue {
                return defaultValue
            } else {
                return ""
            }
        }

        guard let stringValue = value as? String else {
            throw ErrorHandlingUtils.createValidationError(
                message: "Parameter '\(key)' must be a string",
                field: key,
                value: value,
                toolName: context.toolName
            )
        }

        if required && stringValue.isEmpty {
            throw ErrorHandlingUtils.createValidationError(
                message: "Required parameter '\(key)' cannot be empty",
                field: key,
                toolName: context.toolName
            )
        }

        if stringValue.count < minLength {
            throw ErrorHandlingUtils.createValidationError(
                message: "Parameter '\(key)' is too short (minimum \(minLength) characters)",
                field: key,
                value: stringValue.count,
                toolName: context.toolName
            )
        }

        if let maxLength = maxLength, stringValue.count > maxLength {
            throw ErrorHandlingUtils.createValidationError(
                message: "Parameter '\(key)' is too long (maximum \(maxLength) characters)",
                field: key,
                value: stringValue.count,
                toolName: context.toolName
            )
        }

        return stringValue
    }

    /// Validate boolean parameter
    /// - Parameters:
    ///   - parameters: Input parameters dictionary
    ///   - key: Parameter key to validate
    ///   - defaultValue: Default value if parameter is missing
    ///   - required: Whether parameter is required
    ///   - context: Execution context for error reporting
    /// - Returns: Validated boolean value
    /// - Throws: ValidationError if validation fails
    public static func validateBooleanParameter(
        _ parameters: [String: AnyCodable],
        key: String,
        defaultValue: Bool,
        required: Bool = false,
        context: MCPExecutionContext
    ) throws -> Bool {

        guard let value = parameters[key]?.value else {
            if required {
                throw ErrorHandlingUtils.createValidationError(
                    message: "Required parameter '\(key)' is missing",
                    field: key,
                    toolName: context.toolName
                )
            } else {
                return defaultValue
            }
        }

        guard let boolValue = value as? Bool else {
            throw ErrorHandlingUtils.createValidationError(
                message: "Parameter '\(key)' must be a boolean",
                field: key,
                value: value,
                toolName: context.toolName
            )
        }

        return boolValue
    }

    // MARK: - Array Parameter Validation

    /// Validate array parameter
    /// - Parameters:
    ///   - parameters: Input parameters dictionary
    ///   - key: Parameter key to validate
    ///   - elementType: Type of array elements
    ///   - minCount: Minimum number of elements
    ///   - maxCount: Maximum number of elements
    ///   - required: Whether parameter is required
    ///   - context: Execution context for error reporting
    /// - Returns: Validated array value
    /// - Throws: ValidationError if validation fails
    public static func validateArrayParameter<T>(
        _ parameters: [String: AnyCodable],
        key: String,
        elementType: T.Type,
        minCount: Int = 0,
        maxCount: Int? = nil,
        required: Bool = false,
        context: MCPExecutionContext
    ) throws -> [T] {

        guard let value = parameters[key]?.value else {
            if required {
                throw ErrorHandlingUtils.createValidationError(
                    message: "Required parameter '\(key)' is missing",
                    field: key,
                    toolName: context.toolName
                )
            } else {
                return []
            }
        }

        guard let arrayValue = value as? [Any] else {
            throw ErrorHandlingUtils.createValidationError(
                message: "Parameter '\(key)' must be an array",
                field: key,
                value: value,
                toolName: context.toolName
            )
        }

        if arrayValue.count < minCount {
            throw ErrorHandlingUtils.createValidationError(
                message: "Parameter '\(key)' must contain at least \(minCount) elements",
                field: key,
                value: arrayValue.count,
                toolName: context.toolName
            )
        }

        if let maxCount = maxCount, arrayValue.count > maxCount {
            throw ErrorHandlingUtils.createValidationError(
                message: "Parameter '\(key)' cannot contain more than \(maxCount) elements",
                field: key,
                value: arrayValue.count,
                toolName: context.toolName
            )
        }

        // Type conversion with validation
        let typedArray: [T] = try arrayValue.compactMap { element in
            guard let typedElement = element as? T else {
                throw ErrorHandlingUtils.createValidationError(
                    message: "Array element in parameter '\(key)' has invalid type",
                    field: key,
                    value: element,
                    toolName: context.toolName
                )
            }
            return typedElement
        }

        return typedArray
    }

    // MARK: - Audio Domain Specific Validation

    /// Validate audio format parameter
    /// - Parameters:
    ///   - parameters: Input parameters dictionary
    ///   - key: Parameter key to validate
    ///   - defaultValue: Default value if parameter is missing
    ///   - required: Whether parameter is required
    ///   - context: Execution context for error reporting
    /// - Returns: Validated audio format string
    /// - Throws: ValidationError if validation fails
    public static func validateAudioFormat(
        _ parameters: [String: AnyCodable],
        key: String,
        defaultValue: String = "wav",
        required: Bool = false,
        context: MCPExecutionContext
    ) throws -> String {

        let validFormats = ["wav", "mp3", "aiff", "flac", "m4a", "aac", "ogg", "wma"]

        return try validateStringParameter(
            parameters,
            key: key,
            defaultValue: defaultValue,
            required: required,
            context: context
        )
    }

    /// Validate session type parameter
    /// - Parameters:
    ///   - parameters: Input parameters dictionary
    ///   - key: Parameter key to validate
    ///   - defaultValue: Default value if parameter is missing
    ///   - required: Whether parameter is required
    ///   - context: Execution context for error reporting
    /// - Returns: Validated session type string
    /// - Throws: ValidationError if validation fails
    public static func validateSessionType(
        _ parameters: [String: AnyCodable],
        key: String,
        defaultValue: String = "general",
        required: Bool = false,
        context: MCPExecutionContext
    ) throws -> String {

        let validSessionTypes = [
            "tracking", "mixing", "mastering", "production",
            "sound_design", "edit", "review", "general"
        ]

        return try validateStringParameter(
            parameters,
            key: key,
            defaultValue: defaultValue,
            required: required,
            context: context
        )
    }

    /// Validate detail level parameter
    /// - Parameters:
    ///   - parameters: Input parameters dictionary
    ///   - key: Parameter key to validate
    ///   - defaultValue: Default value if parameter is missing
    ///   - required: Whether parameter is required
    ///   - context: Execution context for error reporting
    /// - Returns: Validated detail level string
    /// - Throws: ValidationError if validation fails
    public static func validateDetailLevel(
        _ parameters: [String: AnyCodable],
        key: String,
        defaultValue: String = "standard",
        required: Bool = false,
        context: MCPExecutionContext
    ) throws -> String {

        let validLevels = ["brief", "standard", "detailed", "comprehensive"]

        return try validateStringParameter(
            parameters,
            key: key,
            defaultValue: defaultValue,
            required: required,
            context: context
        )
    }

    // MARK: - Multi-Parameter Validation

    /// Validate multiple parameters at once
    /// - Parameters:
    ///   - parameters: Input parameters dictionary
    ///   - validators: Array of validation closures
    ///   - context: Execution context for error reporting
    /// - Throws: ValidationError if any validation fails
    public static func validateParameters(
        _ parameters: [String: AnyCodable],
        validators: [(String, (Any, MCPExecutionContext) throws -> Void)],
        context: MCPExecutionContext
    ) throws {

        for (key, validator) in validators {
            if let value = parameters[key]?.value {
                try validator(value, context)
            }
        }
    }

    // MARK: - Validation Result

    /// Validation result with detailed information
    public struct ValidationResult {
        public let isValid: Bool
        public let errors: [ValidationError]
        public let warnings: [ValidationWarning]
        public let sanitizedParameters: [String: AnyCodable]

        public init(isValid: Bool = true, errors: [ValidationError] = [], warnings: [ValidationWarning] = [], sanitizedParameters: [String: AnyCodable] = [:]) {
            self.isValid = isValid && errors.isEmpty
            self.errors = errors
            self.warnings = warnings
            self.sanitizedParameters = sanitizedParameters
        }

        public static func valid(_ sanitizedParameters: [String: AnyCodable] = [:]) -> ValidationResult {
            return ValidationResult(sanitizedParameters: sanitizedParameters)
        }

        public static func invalid(_ errors: [ValidationError], sanitizedParameters: [String: AnyCodable] = [:]) -> ValidationResult {
            return ValidationResult(isValid: false, errors: errors, sanitizedParameters: sanitizedParameters)
        }

        public static func warning(_ warnings: [ValidationWarning], sanitizedParameters: [String: AnyCodable] = [:]) -> ValidationResult {
            return ValidationResult(warnings: warnings, sanitizedParameters: sanitizedParameters)
        }
    }

    /// Validation warning for non-critical issues
    public struct ValidationWarning {
        public let field: String
        public let message: String
        public let recommendation: String?

        public init(field: String, message: String, recommendation: String? = nil) {
            self.field = field
            self.message = message
            self.recommendation = recommendation
        }
    }

    /// Validation error with detailed context
    public struct ValidationError {
        public let field: String
        public let message: String
        public let value: Any?

        public init(field: String, message: String, value: Any? = nil) {
            self.field = field
            self.message = message
            self.value = value
        }
    }
}

// MARK: - Common Audio-Specific Enums

/// Common audio formats supported by the tools
public enum AudioFormat: String, CaseIterable {
    case wav = "wav"
    case mp3 = "mp3"
    case aiff = "aiff"
    case flac = "flac"
    case m4a = "m4a"
    case aac = "aac"
    case ogg = "ogg"
    case wma = "wma"
}

/// Common session types for audio engineering
public enum SessionType: String, CaseIterable {
    case tracking = "tracking"
    case mixing = "mixing"
    case mastering = "mastering"
    case production = "production"
    case soundDesign = "sound_design"
    case edit = "edit"
    case review = "review"
    case general = "general"
}

/// Detail levels for summarization and analysis
public enum DetailLevel: String, CaseIterable {
    case brief = "brief"
    case standard = "standard"
    case detailed = "detailed"
    case comprehensive = "comprehensive"
}