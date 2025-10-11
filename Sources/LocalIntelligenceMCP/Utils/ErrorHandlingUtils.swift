//
//  ErrorHandlingUtils.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-09.
//

import Foundation

/// Utility class for standardized error handling across all MCP tools
/// Provides consistent error creation, sanitization, and logging patterns
class ErrorHandlingUtils {

    // MARK: - Error Creation Utilities

    /// Create a standardized validation error with sanitized message
    /// - Parameters:
    ///   - message: Error message (will be sanitized)
    ///   - field: Field name that caused the error
    ///   - value: Value that caused the error (will be sanitized)
    ///   - toolName: Name of the tool where error occurred
    /// - Returns: Formatted ValidationError
    static func createValidationError(
        message: String,
        field: String? = nil,
        value: Any? = nil,
        toolName: String
    ) -> Error {
        let sanitizedMessage = sanitizeErrorMessage(message)
        let context = buildErrorContext(toolName: toolName, field: field, value: value)

        return ToolsRegistryError.invalidParameters("\(sanitizedMessage) \(context)")
    }

    /// Create a standardized security error
    /// - Parameters:
    ///   - message: Security error message
    ///   - operation: Operation that failed
    ///   - toolName: Name of the tool where error occurred
    /// - Returns: SecurityError
    static func createSecurityError(
        message: String,
        operation: String,
        toolName: String
    ) -> SecurityError {
        let sanitizedMessage = sanitizeErrorMessage(message)
        let context = buildSecurityContext(operation: operation, toolName: toolName)

        return SecurityError.unauthorizedAccess
    }

    /// Create a standardized processing error
    /// - Parameters:
    ///   - message: Processing error message
    ///   - operation: Operation that failed
    ///   - toolName: Name of the tool where error occurred
    ///   - cause: Underlying error that caused this error
    /// - Returns: AudioProcessingError
    static func createProcessingError(
        message: String,
        operation: String,
        toolName: String,
        cause: Error? = nil
    ) -> AudioProcessingError {
        let sanitizedMessage = sanitizeErrorMessage(message)
        let context = buildErrorContext(toolName: toolName, field: operation, value: cause?.localizedDescription)

        return AudioProcessingError.processingFailed("\(sanitizedMessage) \(context)")
    }

    /// Create a standardized timeout error
    /// - Parameters:
    ///   - operation: Operation that timed out
    ///   - timeout: Timeout duration in seconds
    ///   - toolName: Name of the tool where error occurred
    /// - Returns: Timeout error
    static func createTimeoutError(
        operation: String,
        timeout: TimeInterval,
        toolName: String
    ) -> Error {
        let message = "Operation '\(operation)' timed out after \(String(format: "%.2f", timeout)) seconds"
        let context = buildErrorContext(toolName: toolName, field: "timeout", value: timeout)

        return ToolsRegistryError.invalidTool("\(message) \(context)")
    }

    // MARK: - Error Sanitization

    /// Sanitize error message to prevent information disclosure
    /// - Parameter message: Raw error message
    /// - Returns: Sanitized error message
    static func sanitizeErrorMessage(_ message: String) -> String {
        var sanitized = message

        // Remove potential sensitive data patterns
        let sensitivePatterns = [
            #"(?i)(password|secret|key|token|credential|api[_-]?key)\s*[:=]\s*\S+"#,
            #"(?i)(authorization|auth)\s*[:=]\s*\S+"#,
            #"\b[a-zA-Z0-9+/]{40,}={0,2}\b"#, // Base64 encoded data
            #"\b[a-f0-9]{32,}\b"#, // Hexadecimal data
            #"\bsk_[a-zA-Z0-9]{20,}\b"#, // API key pattern
            #"\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b"# // UUID pattern
        ]

        for pattern in sensitivePatterns {
            sanitized = sanitized.replacingOccurrences(
                of: pattern,
                with: "[REDACTED]",
                options: .regularExpression
            )
        }

        // Remove file paths that might contain sensitive information
        let pathPatterns = [
            #"/Users/[^/\s]+/"#,
            #"/home/[^/\s]+/"#,
            #"C:\\Users\\[^\\]+\\"#
        ]

        for pattern in pathPatterns {
            sanitized = sanitized.replacingOccurrences(
                of: pattern,
                with: "/[USER]/",
                options: .regularExpression
            )
        }

        return sanitized
    }

    /// Sanitize parameter value for error context
    /// - Parameter value: Raw parameter value
    /// - Returns: Sanitized value string
    static func sanitizeParameterValue(_ value: Any?) -> String {
        guard let value = value else { return "nil" }

        if let stringValue = value as? String {
            if stringValue.count > 100 {
                return String(stringValue.prefix(100)) + "..."
            }

            // Check for sensitive data patterns
            if looksLikeSensitiveData(stringValue) {
                return "[REDACTED]"
            }

            return stringValue
        } else if let arrayValue = value as? [Any] {
            if arrayValue.count > 10 {
                return "Array(\(arrayValue.count) items)"
            }
            return "Array(\(arrayValue.count) items: \(arrayValue.prefix(3).map { "\($0)" }.joined(separator: ", "))"
        } else if let dictValue = value as? [String: Any] {
            return "Dictionary(\(dictValue.count) keys)"
        } else {
            return String(describing: value)
        }
    }

    // MARK: - Error Context Building

    /// Build standardized error context information
    /// - Parameters:
    ///   - toolName: Name of the tool
    ///   - field: Field name (optional)
    ///   - value: Field value (optional)
    /// - Returns: Formatted context string
    private static func buildErrorContext(toolName: String, field: String?, value: Any?) -> String {
        var context = "[Tool: \(toolName)]"

        if let field = field {
            context += " [Field: \(field)]"
        }

        if let value = value {
            let sanitizedValue = sanitizeParameterValue(value)
            context += " [Value: \(sanitizedValue)]"
        }

        return context
    }

    /// Build security error context
    /// - Parameters:
    ///   - operation: Operation that failed
    ///   - toolName: Name of the tool
    /// - Returns: Formatted security context
    private static func buildSecurityContext(operation: String, toolName: String) -> String {
        return "[Tool: \(toolName)] [Operation: \(operation)] [Security: Access Denied]"
    }

    // MARK: - Error Classification

    /// Classify error type for appropriate handling
    /// - Parameter error: Error to classify
    /// - Returns: Error classification
    static func classifyError(_ error: Error) -> ErrorClassification {
        if error is ToolsRegistryError {
            return .validation
        } else if error is SecurityError {
            return .security
        } else if error is AudioProcessingError {
            return .processing
        } else if error is DecodingError {
            return .serialization
        } else if error is EncodingError {
            return .serialization
        } else {
            return .unknown
        }
    }

    /// Check if error is recoverable
    /// - Parameter error: Error to check
    /// - Returns: True if error is recoverable
    static func isRecoverable(_ error: Error) -> Bool {
        let classification = classifyError(error)

        switch classification {
        case .validation:
            return false // Validation errors are not recoverable
        case .security:
            return false // Security errors are not recoverable
        case .processing:
            return true // Processing errors might be recoverable with retry
        case .serialization:
            return false // Serialization errors are not recoverable
        case .unknown:
            return true // Unknown errors might be recoverable
        }
    }

    /// Get recommended retry strategy for error
    /// - Parameter error: Error to analyze
    /// - Returns: Recommended retry strategy
    static func getRetryStrategy(_ error: Error) -> RetryStrategy {
        let classification = classifyError(error)

        switch classification {
        case .validation:
            return .none
        case .security:
            return .none
        case .processing:
            return .exponential(base: 2.0, maxDelay: 30.0)
        case .serialization:
            return .none
        case .unknown:
            return .linear(delay: 1.0, maxRetries: 3)
        }
    }

    // MARK: - Error Logging Support

    /// Create error metadata for logging
    /// - Parameters:
    ///   - error: Error to log
    ///   - context: Execution context
    ///   - additionalInfo: Additional information to include
    /// - Returns: Metadata dictionary for logging
    static func createErrorMetadata(
        error: Error,
        context: MCPExecutionContext,
        additionalInfo: [String: Any] = [:]
    ) -> [String: Any] {
        var metadata: [String: Any] = [
            "errorType": String(describing: type(of: error)),
            "errorClassification": classifyError(error).rawValue,
            "isRecoverable": isRecoverable(error),
            "toolName": context.toolName,
            "requestId": context.requestId,
            "clientId": context.clientId.uuidString
        ]

        // Add retry strategy if applicable
        let retryStrategy = getRetryStrategy(error)
        switch retryStrategy {
        case .none:
            break
        default:
            metadata["retryStrategy"] = retryStrategy.description
        }

        // Add additional context information
        metadata.merge(additionalInfo) { (_, new) in new }

        return metadata
    }

    /// Format error for user-facing response
    /// - Parameters:
    ///   - error: Error to format
    ///   - includeDetails: Whether to include technical details
    /// - Returns: User-friendly error message
    static func formatErrorForUser(_ error: Error, includeDetails: Bool = false) -> String {
        let classification = classifyError(error)

        switch classification {
        case .validation:
            return "Invalid input parameters. Please check your input and try again."
        case .security:
            return "Access denied. You don't have permission to perform this operation."
        case .processing:
            return "Processing failed. Please try again later."
        case .serialization:
            return "Data format error. Please check your input format."
        case .unknown:
            if includeDetails {
                return "An error occurred: \(sanitizeErrorMessage(error.localizedDescription))"
            } else {
                return "An unexpected error occurred. Please try again later."
            }
        }
    }

    // MARK: - Private Helper Methods

    /// Check if string looks like sensitive data
    /// - Parameter string: String to check
    /// - Returns: True if string appears to contain sensitive data
    private static func looksLikeSensitiveData(_ string: String) -> Bool {
        let patterns = [
            "^[A-Za-z0-9+/]{40,}=$",  // Base64 encoded data
            "^[a-f0-9]{32,}$",         // Hexadecimal
            "sk_[a-zA-Z0-9]{20,}",      // API key pattern
            "[0-9]{4}-[0-9]{4}-[0-9]{4}-[0-9]{4}"  // UUID pattern
        ]

        return patterns.contains { pattern in
            string.range(of: pattern, options: .regularExpression) != nil
        }
    }
}

// MARK: - Supporting Types

/// Error classification for handling purposes
enum ErrorClassification: String {
    case validation = "validation"
    case security = "security"
    case processing = "processing"
    case serialization = "serialization"
    case unknown = "unknown"
}

/// Retry strategy for recoverable errors
enum RetryStrategy {
    case none
    case linear(delay: TimeInterval, maxRetries: Int)
    case exponential(base: Double, maxDelay: TimeInterval)

    var description: String {
        switch self {
        case .none:
            return "no_retry"
        case .linear(let delay, let maxRetries):
            return "linear_retry(delay=\(delay),max=\(maxRetries))"
        case .exponential(let base, let maxDelay):
            return "exponential_retry(base=\(base),max_delay=\(maxDelay))"
        }
    }
}

/// Enhanced error handling for MCP tools
public protocol MCPErrorHandling {
    /// Handle errors in a standardized way
    /// - Parameters:
    ///   - error: Error to handle
    ///   - context: Execution context
    /// - Returns: MCP response with appropriate error information
    func handleError(_ error: Error, context: MCPExecutionContext) async -> MCPResponse

    /// Log error with appropriate context
    /// - Parameters:
    ///   - error: Error to log
    ///   - context: Execution context
    ///   - logger: Logger instance
    func logError(_ error: Error, context: MCPExecutionContext, logger: Logger) async
}

/// Default implementation of MCPErrorHandling
public extension MCPErrorHandling {

    func handleError(_ error: Error, context: MCPExecutionContext) async -> MCPResponse {
        let sanitizedMessage = ErrorHandlingUtils.sanitizeErrorMessage(error.localizedDescription)
        let userMessage = ErrorHandlingUtils.formatErrorForUser(error, includeDetails: false)

        return MCPResponse(
            success: false,
            error: LocalMCPError(
                code: ErrorHandlingUtils.classifyError(error).rawValue,
                message: userMessage,
                details: [
                    "technicalMessage": AnyCodable(sanitizedMessage),
                    "toolName": AnyCodable(context.toolName),
                    "requestId": AnyCodable(context.requestId)
                ]
            )
        )
    }

    func logError(_ error: Error, context: MCPExecutionContext, logger: Logger) async {
        let metadata = ErrorHandlingUtils.createErrorMetadata(error: error, context: context)

        await logger.error(
            "Tool execution failed",
            error: error,
            category: .general,
            metadata: metadata
        )
    }
}