//
//  StandardizedTool.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-09.
//

import Foundation

/// Protocol for tools with standardized error handling and logging
/// Ensures consistent behavior across all MCP tools
public protocol StandardizedTool: MCPErrorHandling {

    /// Tool logger instance
    var logger: Logger { get }

    /// Security manager instance
    var securityManager: SecurityManager { get }

    /// Tool name
    var toolName: String { get }

    /// Execute tool with standardized error handling and logging
    /// - Parameters:
    ///   - parameters: Input parameters
    ///   - context: Execution context
    /// - Returns: MCP response
    func executeWithStandardHandling(
        parameters: [String: AnyCodable],
        context: MCPExecutionContext
    ) async throws -> MCPResponse

    /// Validate input parameters with standardized error reporting
    /// - Parameters:
    ///   - parameters: Input parameters to validate
    ///   - context: Execution context
    /// - Throws: ValidationError if validation fails
    func validateParametersStandard(
        _ parameters: [String: AnyCodable],
        context: MCPExecutionContext
    ) async throws

    /// Perform core tool logic (to be implemented by concrete tools)
    /// - Parameters:
    ///   - parameters: Validated parameters
    ///   - context: Execution context
    /// - Returns: Tool result data
    func performCoreExecution(
        parameters: [String: AnyCodable],
        context: MCPExecutionContext
    ) async throws -> Any
}

/// Default implementation of StandardizedTool protocol
public extension StandardizedTool {

    /// Default implementation with standardized error handling and logging
    func executeWithStandardHandling(
        parameters: [String: AnyCodable],
        context: MCPExecutionContext
    ) async throws -> MCPResponse {
        let startTime = Date()
        let toolLogger = await logger.toolLogger(toolName)

        // Log tool execution start
        await toolLogger.logStart(parameters: parameters, context: context)

        do {
            // Validate parameters
            try await validateParametersStandard(parameters, context: context)

            // Perform core execution
            let result = try await performCoreExecution(parameters: parameters, context: context)

            // Calculate execution time
            let executionTime = Date().timeIntervalSince(startTime)

            // Log success
            let resultSize = calculateResultSize(result)
            await toolLogger.logSuccessWithContext(executionTime: executionTime, resultSize: resultSize, context: context)

            return MCPResponse(
                success: true,
                data: AnyCodable(result),
                executionTime: executionTime
            )

        } catch {
            // Calculate execution time
            let executionTime = Date().timeIntervalSince(startTime)

            // Log failure
            await toolLogger.logFailureWithContext(error: error, executionTime: executionTime, context: context)

            // Return standardized error response
            return await handleError(error, context: context)
        }
    }

    /// Default parameter validation (can be overridden by tools)
    func validateParametersStandard(
        _ parameters: [String: AnyCodable],
        context: MCPExecutionContext
    ) async throws {
        // Basic validation - ensure parameters exist
        guard !parameters.isEmpty else {
            throw ErrorHandlingUtils.createValidationError(
                message: "No parameters provided",
                toolName: toolName
            )
        }

        // Validate parameter count
        if parameters.count > 100 {
            throw ErrorHandlingUtils.createValidationError(
                message: "Too many parameters provided",
                toolName: toolName
            )
        }

        // Log parameter validation
        await logger.debug(
            "Parameters validated successfully",
            category: .general,
            metadata: [
                "toolName": toolName,
                "requestId": context.requestId,
                "parameterCount": parameters.count
            ]
        )
    }

    /// Calculate result size for logging
    /// - Parameter result: Result data
    /// - Returns: Size in bytes (estimated)
    private func calculateResultSize(_ result: Any) -> Int {
        do {
            let data = try JSONEncoder().encode(AnyCodable(result))
            return data.count
        } catch {
            // If encoding fails, estimate size based on string representation
            return String(describing: result).count
        }
    }
}

/// Enhanced base class for tools with standardized behavior
open class EnhancedBaseMCPTool: BaseMCPTool, StandardizedTool, @unchecked Sendable {

    // MARK: - StandardizedTool Protocol

    public var toolName: String {
        return name
    }

    /// Main execution method with standardized handling
    public final override func performExecution(
        parameters: [String: AnyCodable],
        context: MCPExecutionContext
    ) async throws -> MCPResponse {
        return try await executeWithStandardHandling(parameters: parameters, context: context)
    }

    // Default validation implementation is provided by protocol extension

    /// Core execution to be implemented by concrete tools
    open func performCoreExecution(
        parameters: [String: AnyCodable],
        context: MCPExecutionContext
    ) async throws -> Any {
        // Default implementation - should be overridden
        throw ToolsRegistryError.toolNotFound("Core execution not implemented")
    }

    // MARK: - Convenience Methods

    /// Get tool-specific logger
    public func getToolLogger() async -> ToolLogger {
        return await logger.toolLogger(toolName)
    }

    /// Log performance metric with tool context
    public func logPerformance(
        operation: String,
        duration: TimeInterval,
        metadata: [String: Any] = [:],
        context: MCPExecutionContext
    ) async {
        await LoggingUtils.logPerformance(
            operation: operation,
            duration: duration,
            metadata: metadata,
            context: context,
            logger: logger
        )
    }

    /// Log security event with tool context
    public func logSecurityEvent(
        eventType: SecurityEventType,
        details: [String: Any],
        context: MCPExecutionContext
    ) async {
        await LoggingUtils.logSecurityEvent(
            eventType,
            toolName: toolName,
            details: details,
            context: context,
            logger: logger
        )
    }

    /// Validate parameter with standardized error handling
    public func validateParameter<T>(
        _ value: Any?,
        as type: T.Type,
        name: String,
        required: Bool = true,
        context: MCPExecutionContext
    ) throws -> T {
        guard let value = value else {
            if required {
                throw ErrorHandlingUtils.createValidationError(
                    message: "Required parameter '\(name)' is missing",
                    field: name,
                    toolName: toolName
                )
            }
            throw ErrorHandlingUtils.createValidationError(
                message: "Optional parameter '\(name)' is nil",
                field: name,
                toolName: toolName
            )
        }

        guard let typedValue = value as? T else {
            throw ErrorHandlingUtils.createValidationError(
                message: "Parameter '\(name)' has invalid type",
                field: name,
                value: value,
                toolName: toolName
            )
        }

        return typedValue
    }

    /// Validate enum parameter with allowed values
    public func validateEnumParameter(
        _ value: Any?,
        name: String,
        allowedValues: [String],
        required: Bool = true,
        defaultValue: String? = nil,
        context: MCPExecutionContext
    ) throws -> String {
        if let value = value as? String {
            guard allowedValues.contains(value.lowercased()) else {
                throw ErrorHandlingUtils.createValidationError(
                    message: "Invalid value for parameter '\(name)'",
                    field: name,
                    value: value,
                    toolName: toolName
                )
            }
            return value.lowercased()
        } else if required {
            throw ErrorHandlingUtils.createValidationError(
                message: "Required parameter '\(name)' is missing",
                field: name,
                toolName: toolName
            )
        } else if let defaultValue = defaultValue {
            return defaultValue
        } else {
            throw ErrorHandlingUtils.createValidationError(
                message: "Parameter '\(name)' is required but no default value provided",
                field: name,
                toolName: toolName
            )
        }
    }

    /// Validate numeric parameter with range constraints
    public func validateNumericParameter<T: Comparable>(
        _ value: Any?,
        name: String,
        min: T? = nil,
        max: T? = nil,
        required: Bool = true,
        defaultValue: T? = nil,
        context: MCPExecutionContext
    ) throws -> T {
        let numericValue: T

        if let value = value as? T {
            numericValue = value
        } else if required {
            throw ErrorHandlingUtils.createValidationError(
                message: "Required parameter '\(name)' is missing or invalid",
                field: name,
                toolName: toolName
            )
        } else if let defaultValue = defaultValue {
            numericValue = defaultValue
        } else {
            throw ErrorHandlingUtils.createValidationError(
                message: "Parameter '\(name)' is required but no default value provided",
                field: name,
                toolName: toolName
            )
        }

        if let min = min, numericValue < min {
            throw ErrorHandlingUtils.createValidationError(
                message: "Parameter '\(name)' is below minimum value",
                field: name,
                value: numericValue,
                toolName: toolName
            )
        }

        if let max = max, numericValue > max {
            throw ErrorHandlingUtils.createValidationError(
                message: "Parameter '\(name)' exceeds maximum value",
                field: name,
                value: numericValue,
                toolName: toolName
            )
        }

        return numericValue
    }

    /// Sanitize and validate text parameter
    public func validateTextParameter(
        _ value: Any?,
        name: String,
        minLength: Int = 0,
        maxLength: Int? = nil,
        required: Bool = true,
        context: MCPExecutionContext
    ) throws -> String {
        guard let textValue = value as? String else {
            if required {
                throw ErrorHandlingUtils.createValidationError(
                    message: "Required text parameter '\(name)' is missing or invalid",
                    field: name,
                    toolName: toolName
                )
            }
            return ""
        }

        if required && textValue.isEmpty {
            throw ErrorHandlingUtils.createValidationError(
                message: "Required text parameter '\(name)' cannot be empty",
                field: name,
                toolName: toolName
            )
        }

        if textValue.count < minLength {
            throw ErrorHandlingUtils.createValidationError(
                message: "Text parameter '\(name)' is too short",
                field: name,
                value: textValue.count,
                toolName: toolName
            )
        }

        if let maxLength = maxLength, textValue.count > maxLength {
            throw ErrorHandlingUtils.createValidationError(
                message: "Text parameter '\(name)' is too long",
                field: name,
                value: textValue.count,
                toolName: toolName
            )
        }

        return textValue
    }
}

