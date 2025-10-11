//
// LoggingUtils.swift
// LocalIntelligenceMCP
//

import Foundation

/// Utility class for standardized logging patterns
public class LoggingUtils {
    /// Log security events
    static func logSecurityEvent(
        _ eventType: SecurityEventType,
        toolName: String,
        details: [String: Any],
        context: MCPExecutionContext,
        logger: Logger
    ) async {
        // Create simple metadata to avoid concurrency issues
        await logger.securityEvent(eventType, clientId: context.clientId.uuidString, details: [
            "toolName": toolName,
            "requestId": context.requestId
        ])
    }
    
    /// Log performance metrics
    static func logPerformance(
        operation: String,
        duration: TimeInterval,
        metadata: [String: Any],
        context: MCPExecutionContext,
        logger: Logger
    ) async {
        // Create simple metadata to avoid concurrency issues
        await logger.performance(operation, duration: duration, metadata: [
            "requestId": context.requestId,
            "clientId": context.clientId.uuidString
        ])
    }
    
    /// Log audio processing
    static func logAudioProcessing(
        operation: String,
        duration: TimeInterval,
        context: MCPExecutionContext,
        outputSize: Int,
        quality: [String: Any]? = nil,
        logger: Logger
    ) async {
        // Create simple metadata to avoid concurrency issues
        await logger.info("Audio processing completed", category: .multimedia, metadata: [
            "operation": operation,
            "requestId": context.requestId,
            "clientId": context.clientId.uuidString,
            "duration": duration,
            "outputSize": outputSize
        ])
    }
    
    /// Log health check
    static func logHealthCheck(
        component: String,
        status: String,
        metrics: [String: Any],
        context: MCPExecutionContext,
        logger: Logger
    ) async {
        // Create simple metadata to avoid concurrency issues
        await logger.info("Health check completed", category: .general, metadata: [
            "component": component,
            "requestId": context.requestId,
            "clientId": context.clientId.uuidString,
            "status": status
        ])
    }

    /// Log audio processing start
    static func logAudioProcessingStart(
        operation: String,
        inputSize: Int,
        parameters: [String: Any],
        context: MCPExecutionContext,
        logger: Logger
    ) async {
        // Create simple metadata to avoid concurrency issues
        await logger.info("Audio processing started", category: .multimedia, metadata: [
            "operation": operation,
            "requestId": context.requestId,
            "clientId": context.clientId.uuidString,
            "inputSize": inputSize
        ])
    }

    /// Log PII operation
    static func logPIIOperation(
        operation: String,
        detections: [String],
        context: MCPExecutionContext,
        logger: Logger
    ) async {
        // Create simple metadata to avoid concurrency issues
        await logger.info("PII operation completed", category: .security, metadata: [
            "operation": operation,
            "requestId": context.requestId,
            "clientId": context.clientId.uuidString,
            "detectionCount": detections.count
        ])
    }

    /// Log audio processing result
    static func logAudioProcessingResult(
        operation: String,
        duration: TimeInterval,
        context: MCPExecutionContext,
        outputSize: Int,
        logger: Logger
    ) async {
        // Create simple metadata to avoid concurrency issues
        await logger.info("Audio processing result", category: .multimedia, metadata: [
            "operation": operation,
            "requestId": context.requestId,
            "clientId": context.clientId.uuidString,
            "duration": duration,
            "outputSize": outputSize
        ])
    }
}

// MARK: - Logger Extensions

public extension Logger {
    /// Create a tool-specific logger
    func toolLogger(_ toolName: String) -> ToolLogger {
        return ToolLogger(baseLogger: self, toolName: toolName)
    }
}

/// Tool-specific logger wrapper
public struct ToolLogger: Sendable {
    private let baseLogger: Logger
    private let toolName: String

    init(baseLogger: Logger, toolName: String) {
        self.baseLogger = baseLogger
        self.toolName = toolName
    }

    /// Log tool start
    func logStart(
        parameters: [String: Any],
        context: MCPExecutionContext
    ) async {
        await baseLogger.info("Tool started: \(toolName)", category: .general, metadata: [
            "toolName": toolName,
            "requestId": context.requestId,
            "clientId": context.clientId.uuidString
        ])
    }

    /// Log tool completion
    func logCompletion(
        duration: TimeInterval,
        resultSize: Int,
        success: Bool,
        context: MCPExecutionContext
    ) async {
        await baseLogger.info("Tool completed: \(toolName)", category: .general, metadata: [
            "toolName": toolName,
            "requestId": context.requestId,
            "clientId": context.clientId.uuidString,
            "duration": duration,
            "resultSize": resultSize,
            "success": success
        ])
    }

    /// Log tool error
    func logError(
        _ error: Error,
        duration: TimeInterval,
        context: MCPExecutionContext
    ) async {
        await baseLogger.error("Tool failed: \(toolName)", error: error, category: .general, metadata: [
            "toolName": toolName,
            "requestId": context.requestId,
            "clientId": context.clientId.uuidString,
            "duration": duration
        ])
    }

    /// Log tool success
    func logSuccess(_ message: String = "", metadata: [String: Any] = [:]) async {
        await baseLogger.info("Tool succeeded: \(toolName) \(message)", category: .general, metadata: [:])
    }

    /// Log tool failure
    func logFailure(_ message: String = "", error: Error? = nil, metadata: [String: Any] = [:]) async {
        await baseLogger.error("Tool failed: \(toolName) \(message)", category: .general, metadata: [:])
    }
    
    /// Log tool success with full context
    func logSuccessWithContext(
        executionTime: TimeInterval,
        resultSize: Int,
        context: MCPExecutionContext
    ) async {
        await baseLogger.info("Tool succeeded: \(toolName)", category: .general, metadata: [
            "toolName": toolName,
            "requestId": context.requestId,
            "clientId": context.clientId.uuidString,
            "executionTime": executionTime,
            "resultSize": resultSize
        ])
    }

    /// Log tool failure with full context
    func logFailureWithContext(
        error: Error,
        executionTime: TimeInterval,
        context: MCPExecutionContext
    ) async {
        await baseLogger.error("Tool failed: \(toolName)", error: error, category: .general, metadata: [
            "toolName": toolName,
            "requestId": context.requestId,
            "clientId": context.clientId.uuidString,
            "executionTime": executionTime
        ])
    }
}
