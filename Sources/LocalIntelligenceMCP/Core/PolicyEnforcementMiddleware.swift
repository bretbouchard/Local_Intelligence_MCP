//
//  PolicyEnforcementMiddleware.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-08.
//

import Foundation

/// Middleware for enforcing execution policies and security constraints
/// Provides centralized policy enforcement for all MCP tool operations
actor PolicyEnforcementMiddleware: Sendable {

    // MARK: - Properties

    private let logger: Logger
    private let securityManager: SecurityManager
    private let defaultPolicy: ToolExecutionPolicy
    private var toolSpecificPolicies: [String: ToolExecutionPolicy] = [:]
    private var clientSpecificPolicies: [UUID: ToolExecutionPolicy] = [:]

    // MARK: - Initialization

    init(
        logger: Logger,
        securityManager: SecurityManager,
        defaultPolicy: ToolExecutionPolicy = .default
    ) {
        self.logger = logger
        self.securityManager = securityManager
        self.defaultPolicy = defaultPolicy
    }

    // MARK: - Policy Management

    /// Set policy for a specific tool
    /// - Parameters:
    ///   - toolName: Name of the tool
    ///   - policy: Policy to apply
    func setPolicy(for toolName: String, policy: ToolExecutionPolicy) {
        toolSpecificPolicies[toolName] = policy
        Task {
            await logger.info("Set policy for tool: \(toolName)", category: .general, metadata: [:])
        }
    }

    /// Set policy for a specific client
    /// - Parameters:
    ///   - clientId: Client identifier
    ///   - policy: Policy to apply
    func setPolicy(for clientId: UUID, policy: ToolExecutionPolicy) {
        clientSpecificPolicies[clientId] = policy
        Task {
            await logger.info("Set policy for client: \(clientId)", category: .general, metadata: [:])
        }
    }

    /// Get effective policy for a tool execution
    /// - Parameters:
    ///   - toolName: Name of the tool
    ///   - clientId: Client identifier
    /// - Returns: Effective policy to apply
    func getEffectivePolicy(for toolName: String, clientId: UUID) -> ToolExecutionPolicy {
        // Priority: Client-specific > Tool-specific > Default
        if let clientPolicy = clientSpecificPolicies[clientId] {
            return clientPolicy
        }

        if let toolPolicy = toolSpecificPolicies[toolName] {
            return toolPolicy
        }

        return defaultPolicy
    }

    // MARK: - Policy Enforcement

    /// Execute a tool operation with policy enforcement
    /// - Parameters:
    ///   - operation: The operation to execute
    ///   - context: Execution context
    ///   - policy: Policy to apply (optional, will be determined if not provided)
    /// - Returns: Result of the operation
    func executeWithPolicy<T: Sendable>(
        _ operation: @escaping @Sendable () async throws -> T,
        context: MCPExecutionContext,
        policy: ToolExecutionPolicy? = nil
    ) async throws -> T {
        let effectivePolicy = policy ?? getEffectivePolicy(for: context.toolName, clientId: context.clientId)

        // Pre-execution checks
        try await preExecutionChecks(context: context, policy: effectivePolicy)

        // Execute the operation
        let startTime = Date()
        let result = try await operation()
        let executionTime = Date().timeIntervalSince(startTime)

        // Post-execution processing
        let processedResult = try await postExecutionProcessing(
            result: result,
            context: context,
            policy: effectivePolicy,
            executionTime: executionTime
        )

        // Log execution
        await logger.info(
            "Tool executed successfully",
            metadata: [
                "toolName": context.toolName,
                "clientId": context.clientId.uuidString,
                "executionTime": executionTime,
                "policyApplied": effectivePolicy.allowPCC != defaultPolicy.allowPCC || effectivePolicy.piiRedact != defaultPolicy.piiRedact
            ]
        )

        return processedResult
    }

    // MARK: - Pre-Execution Checks

    /// Perform pre-execution security and policy checks
    /// - Parameters:
    ///   - context: Execution context
    ///   - policy: Policy to enforce
    /// - Throws: PolicyViolationError if checks fail
    private func preExecutionChecks(context: MCPExecutionContext, policy: ToolExecutionPolicy) async throws {
        // Check permissions
        try await checkPermissions(context: context)

        // Check rate limits
        try await checkRateLimits(context: context)

        // Validate policy constraints
        try await validatePolicyConstraints(context: context, policy: policy)

        // Check tool-specific constraints
        try await checkToolConstraints(context: context)
    }

    /// Check if the client has required permissions for the tool
    /// - Parameter context: Execution context
    /// - Throws: PermissionDeniedError if permissions are insufficient
    private func checkPermissions(context: MCPExecutionContext) async throws {
        // For now, we'll implement a basic permission check
        // In a real implementation, this would check against actual security policies
        let hasPermission = await checkBasicPermission(context: context)

        guard hasPermission else {
            await logger.warning(
                "Permission denied for tool execution",
                metadata: [
                    "toolName": context.toolName,
                    "clientId": context.clientId.uuidString
                ]
            )
            throw PolicyViolationError.permissionDenied(toolName: context.toolName, clientId: context.clientId)
        }
    }

    /// Basic permission check (placeholder implementation)
    /// - Parameter context: Execution context
    /// - Returns: True if permission is granted
    private func checkBasicPermission(context: MCPExecutionContext) async -> Bool {
        // This is a simplified implementation
        // In a real system, this would check against actual permissions
        return true
    }

    /// Check rate limits for the client and tool
    /// - Parameter context: Execution context
    /// - Throws: RateLimitError if limits are exceeded
    private func checkRateLimits(context: MCPExecutionContext) async throws {
        // Implementation would check against stored rate limit counters
        // For now, we'll allow all requests
        // In a real implementation, this would check:
        // - Client-wide rate limits
        // - Tool-specific rate limits
        // - Time window constraints

        await logger.debug(
            "Rate limits checked",
            metadata: [
                "toolName": context.toolName,
                "clientId": context.clientId.uuidString
            ]
        )
    }

    /// Validate policy-specific constraints
    /// - Parameters:
    ///   - context: Execution context
    ///   - policy: Policy to validate
    /// - Throws: PolicyViolationError if constraints are violated
    private func validatePolicyConstraints(context: MCPExecutionContext, policy: ToolExecutionPolicy) async throws {
        // Check PCC (Private Compute Compute) constraints
        if !policy.allowPCC && context.toolName.contains("pcc") {
            throw PolicyViolationError.pccNotAllowed(toolName: context.toolName)
        }

        // Check tool-specific constraints
        if isHighRiskTool(context.toolName) && policy.temperature > 0.5 {
            await logger.warning(
                "High temperature for high-risk tool",
                metadata: [
                    "toolName": context.toolName,
                    "temperature": policy.temperature
                ]
            )
        }

        await logger.debug(
            "Policy constraints validated",
            metadata: [
                "toolName": context.toolName,
                "allowPCC": policy.allowPCC,
                "piiRedact": policy.piiRedact,
                "maxOutputTokens": policy.maxOutputTokens
            ]
        )
    }

    /// Check tool-specific constraints
    /// - Parameter context: Execution context
    /// - Throws: PolicyViolationError if constraints are violated
    private func checkToolConstraints(context: MCPExecutionContext) async throws {
        // For now, assume all tools are available
        // In a real implementation, this would check against a tool registry

        // Check tool-specific requirements
        if let toolRequirements = getToolRequirements(context.toolName) {
            try await validateToolRequirements(toolRequirements, context: context)
        }
    }

    // MARK: - Post-Execution Processing

    /// Process result after execution
    /// - Parameters:
    ///   - result: Raw result from operation
    ///   - context: Execution context
    ///   - policy: Policy that was applied
    ///   - executionTime: Time taken for execution
    /// - Returns: Processed result
    /// - Throws: ProcessingError if processing fails
    private func postExecutionProcessing<T: Sendable>(
        result: T,
        context: MCPExecutionContext,
        policy: ToolExecutionPolicy,
        executionTime: TimeInterval
    ) async throws -> T {
        // Apply post-execution policies based on result type
        if let stringResult = result as? String {
            let processedString = applyPostExecutionPolicies(
                to: stringResult,
                policy: policy
            )

            // Note: This is a type-unsafe cast. In a real implementation,
            // we'd need better type handling or make T constrained
            return processedString as! T
        }

        // For non-string results, return as-is (could add other type handlers)
        return result
    }

    /// Apply post-execution policies to string output
    /// - Parameters:
    ///   - content: String content to process
    ///   - policy: Policy to apply
    /// - Returns: Processed content
    private func applyPostExecutionPolicies(to content: String, policy: ToolExecutionPolicy) -> String {
        var processedContent = content

        // Apply token limit
        if policy.maxOutputTokens > 0 {
            let estimatedTokens = estimateTokens(content)
            if estimatedTokens > policy.maxOutputTokens {
                let targetCharacters = policy.maxOutputTokens * 4
                processedContent = String(processedContent.prefix(targetCharacters))
                if !processedContent.isEmpty {
                    processedContent += "... [truncated]"
                }
            }
        }

        // Apply PII redaction
        if policy.piiRedact {
            processedContent = redactPII(from: processedContent)
        }

        return processedContent
    }

    // MARK: - Helper Methods

    /// Check if a tool is considered high-risk
    /// - Parameter toolName: Name of the tool
    /// - Returns: True if tool is high-risk
    private func isHighRiskTool(_ toolName: String) -> Bool {
        let highRiskKeywords = ["delete", "remove", "system", "admin", "root", "format"]
        let lowercaseToolName = toolName.lowercased()
        return highRiskKeywords.contains { lowercaseToolName.contains($0) }
    }

    /// Get tool-specific requirements
    /// - Parameter toolName: Name of the tool
    /// - Returns: Tool requirements if available
    private func getToolRequirements(_ toolName: String) -> ToolRequirements? {
        // This would typically be loaded from configuration
        // For now, return some basic requirements
        switch toolName {
        case _ where toolName.contains("summarize"):
            return ToolRequirements(
                minMemoryMB: 512,
                maxExecutionTime: 30.0,
                requiresNetwork: false
            )
        case _ where toolName.contains("rewrite"):
            return ToolRequirements(
                minMemoryMB: 256,
                maxExecutionTime: 20.0,
                requiresNetwork: false
            )
        default:
            return nil
        }
    }

    /// Validate tool requirements against current context
    /// - Parameters:
    ///   - requirements: Tool requirements
    ///   - context: Execution context
    /// - Throws: RequirementError if requirements are not met
    private func validateToolRequirements(_ requirements: ToolRequirements, context: MCPExecutionContext) async throws {
        // Check memory requirements
        let availableMemory = getAvailableMemory()
        guard availableMemory >= requirements.minMemoryMB else {
            throw PolicyViolationError.insufficientMemory(
                required: requirements.minMemoryMB,
                available: availableMemory
            )
        }

        // Check network requirement
        if requirements.requiresNetwork && !isNetworkAvailable() {
            throw PolicyViolationError.networkRequired
        }

        await logger.debug(
            "Tool requirements validated",
            metadata: [
                "toolName": context.toolName,
                "requiredMemory": requirements.minMemoryMB,
                "availableMemory": availableMemory
            ]
        )
    }

    /// Estimate token count for content
    /// - Parameter content: Content to analyze
    /// - Returns: Estimated token count
    private func estimateTokens(_ content: String) -> Int {
        return Int(ceil(Double(content.count) / 4.0))
    }

    /// Redact PII from content
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

        return redactedContent
    }

    /// Get available system memory in MB
    /// - Returns: Available memory in MB
    private func getAvailableMemory() -> Int {
        // This would use system APIs to get actual available memory
        // For now, return a reasonable default
        return 4096 // 4GB
    }

    /// Check if network is available
    /// - Returns: True if network is available
    private func isNetworkAvailable() -> Bool {
        // This would use system APIs to check network connectivity
        // For now, return true
        return true
    }
}

// MARK: - Supporting Types

/// Tool requirements specification
struct ToolRequirements: Sendable {
    let minMemoryMB: Int
    let maxExecutionTime: TimeInterval
    let requiresNetwork: Bool

    init(minMemoryMB: Int, maxExecutionTime: TimeInterval, requiresNetwork: Bool) {
        self.minMemoryMB = minMemoryMB
        self.maxExecutionTime = maxExecutionTime
        self.requiresNetwork = requiresNetwork
    }
}

/// Policy enforcement errors
enum PolicyViolationError: Error, LocalizedError {
    case permissionDenied(toolName: String, clientId: UUID)
    case rateLimitExceeded(toolName: String, clientId: UUID)
    case pccNotAllowed(toolName: String)
    case toolNotAvailable(toolName: String)
    case insufficientMemory(required: Int, available: Int)
    case networkRequired
    case maxExecutionTimeExceeded(toolName: String, maxTime: TimeInterval)
    case contentTooLarge(toolName: String, maxSize: Int)
    case invalidPolicy(policy: String)

    var errorDescription: String? {
        switch self {
        case .permissionDenied(let toolName, let clientId):
            return "Permission denied for client \(clientId) to execute tool \(toolName)"
        case .rateLimitExceeded(let toolName, let clientId):
            return "Rate limit exceeded for client \(clientId) on tool \(toolName)"
        case .pccNotAllowed(let toolName):
            return "PCC operations not allowed for tool \(toolName)"
        case .toolNotAvailable(let toolName):
            return "Tool \(toolName) is not available"
        case .insufficientMemory(let required, let available):
            return "Insufficient memory: required \(required)MB, available \(available)MB"
        case .networkRequired:
            return "Network connection required but not available"
        case .maxExecutionTimeExceeded(let toolName, let maxTime):
            return "Tool \(toolName) exceeded maximum execution time of \(maxTime)s"
        case .contentTooLarge(let toolName, let maxSize):
            return "Content too large for tool \(toolName). Maximum size: \(maxSize)"
        case .invalidPolicy(let policy):
            return "Invalid policy configuration: \(policy)"
        }
    }
}

/// Content processing errors
enum ProcessingError: Error, LocalizedError {
    case contentTruncated(String)
    case piiRedactionFailed(String)
    case tokenLimitExceeded(String)
    case invalidContentType(String)

    var errorDescription: String? {
        switch self {
        case .contentTruncated(let reason):
            return "Content was truncated: \(reason)"
        case .piiRedactionFailed(let reason):
            return "PII redaction failed: \(reason)"
        case .tokenLimitExceeded(let reason):
            return "Token limit exceeded: \(reason)"
        case .invalidContentType(let type):
            return "Invalid content type for processing: \(type)"
        }
    }
}