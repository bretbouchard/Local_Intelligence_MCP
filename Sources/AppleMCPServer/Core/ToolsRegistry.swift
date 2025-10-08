//
//  ToolsRegistry.swift
//  AppleMCPServer
//
//  Created on 2025-10-07.
//

import Foundation

/// Registry for managing MCP tools
/// Implements Tool-Based Architecture constitutional principle
actor ToolsRegistry {

    // MARK: - Properties

    private var tools: [String: MCPToolProtocol] = [:]
    private let logger: Logger
    private let securityManager: SecurityManager

    // MARK: - Initialization

    init(logger: Logger, securityManager: SecurityManager) {
        self.logger = logger
        self.securityManager = securityManager
    }

    // MARK: - Registry Management

    /// Initialize the tools registry with default tools
    func initialize() async throws {
        await logger.info("Initializing MCP tools registry", category: .server)

        // Register built-in tools
        try await registerTool(SystemInfoTool(logger: logger, securityManager: securityManager))
        try await registerTool(PermissionTool(logger: logger, securityManager: securityManager))
        try await registerTool(ShortcutsTool(logger: logger, securityManager: securityManager))
        try await registerTool(ShortcutsListTool(logger: logger, securityManager: securityManager))
        try await registerTool(VoiceControlTool(logger: logger, securityManager: securityManager))

        await logger.info("MCP tools registry initialized", category: .server, metadata: [
            "totalTools": tools.count,
            "toolNames": Array(tools.keys)
        ])
    }

    /// Register a new tool
    /// - Parameter tool: Tool to register
    /// - Throws: ToolsRegistryError if registration fails
    func registerTool(_ tool: MCPToolProtocol) async throws {
        // Validate tool
        let validation = validateTool(tool)
        guard validation.isValid else {
            throw ToolsRegistryError.invalidTool(validation.errors.map { $0.message }.joined(separator: "; "))
        }

        // Check for duplicate tool name
        if tools.keys.contains(tool.name) {
            throw ToolsRegistryError.duplicateTool(tool.name)
        }

        tools[tool.name] = tool

        await logger.info("Tool registered", category: .server, metadata: [
            "toolName": tool.name,
            "toolCategory": tool.category.rawValue,
            "offlineCapable": tool.offlineCapable
        ])
    }

    /// Unregister a tool
    /// - Parameter toolName: Name of tool to unregister
    func unregisterTool(_ toolName: String) async {
        guard tools.removeValue(forKey: toolName) != nil else { return }

        await logger.info("Tool unregistered", category: .server, metadata: [
            "toolName": toolName
        ])
    }

    /// Get available tools
    /// - Returns: Array of available tool information
    func getAvailableTools() async -> [MCPToolInfo] {
        return tools.values.map { tool in
            MCPToolInfo(
                name: tool.name,
                description: tool.description,
                inputSchema: tool.inputSchema,
                category: tool.category,
                requiresPermission: tool.requiresPermission,
                offlineCapable: tool.offlineCapable
            )
        }.sorted { $0.name < $1.name }
    }

    /// Get tool by name
    /// - Parameter name: Tool name
    /// - Returns: Tool if found, nil otherwise
    func getTool(_ name: String) async -> MCPTool? {
        return tools[name]
    }

    /// Execute a tool
    /// - Parameters:
    ///   - name: Tool name
    ///   - parameters: Tool parameters
    ///   - context: Execution context
    /// - Returns: Tool execution result
    /// - Throws: ToolsRegistryError if execution fails
    func executeTool(
        name: String,
        parameters: [String: Any],
        context: MCPExecutionContext
    ) async throws -> MCPResponse {
        let startTime = Date()

        await logger.mcpMessage(
            direction: .inbound,
            messageId: context.requestId,
            method: name,
            metadata: [
                "clientId": context.clientId.uuidString,
                "parameters": parameters.sanitizedForLogging()
            ]
        )

        guard let tool = tools[name] else {
            await logger.warning("Tool not found", category: .server, metadata: [
                "toolName": name,
                "clientId": context.clientId.uuidString
            ])

            let error = MCPError(
                code: "TOOL_NOT_FOUND",
                message: "Tool '\(name)' not found",
                details: ["availableTools": AnyCodable(Array(tools.keys))]
            )

            await logger.mcpMessage(
                direction: .outbound,
                messageId: context.requestId,
                method: name,
                metadata: ["error": error.code]
            )

            return MCPResponse(success: false, error: error)
        }

        do {
            // Validate permissions
            try await validatePermissions(for: tool, context: context)

            // Validate parameters
            let validationResult = validateParameters(tool, parameters: parameters)
            guard validationResult.isValid else {
                throw ToolsRegistryError.invalidParameters(
                    validationResult.errors.map { $0.message }.joined(separator: "; ")
                )
            }

            // Execute tool
            let result = try await tool.execute(parameters: parameters, context: context)

            let executionTime = Date().timeIntervalSince(startTime)

            await logger.performance(
                "tool_execution",
                duration: executionTime,
                metadata: [
                    "toolName": name,
                    "clientId": context.clientId.uuidString,
                    "success": result.success
                ]
            )

            await logger.mcpMessage(
                direction: .outbound,
                messageId: context.requestId,
                method: name,
                metadata: [
                    "success": result.success,
                    "executionTime": executionTime
                ]
            )

            return result

        } catch {
            let executionTime = Date().timeIntervalSince(startTime)

            await logger.error(
                "Tool execution failed",
                error: error,
                category: .server,
                metadata: [
                    "toolName": name,
                    "clientId": context.clientId.uuidString,
                    "executionTime": executionTime
                ]
            )

            let mcpError = error.mcpError
            await logger.mcpMessage(
                direction: .outbound,
                messageId: context.requestId,
                method: name,
                metadata: ["error": mcpError.code]
            )

            return MCPResponse(success: false, error: mcpError, executionTime: executionTime)
        }
    }

    // MARK: - Private Methods

    private func validateTool(_ tool: MCPTool) -> ValidationResult {
        var errors: [ValidationError] = []

        // Validate tool name
        if !tool.name.isValidMCPToolName {
            errors.append(ValidationError(
                code: "INVALID_TOOL_NAME",
                message: "Tool name is invalid",
                field: "name",
                value: tool.name
            ))
        }

        // Validate description
        if tool.description.isEmpty {
            errors.append(ValidationError(
                code: "MISSING_DESCRIPTION",
                message: "Tool description is required",
                field: "description"
            ))
        }

        // Validate input schema
        if tool.inputSchema.isEmpty {
            errors.append(ValidationError(
                code: "MISSING_INPUT_SCHEMA",
                message: "Input schema is required",
                field: "inputSchema"
            ))
        }

        // Validate permissions
        if tool.requiresPermission.isEmpty {
            errors.append(ValidationError(
                code: "MISSING_PERMISSIONS",
                message: "Tool must specify required permissions",
                field: "requiresPermission"
            ))
        }

        return ValidationResult(errors: errors)
    }

    private func validateParameters(_ tool: MCPTool, parameters: [String: Any]) -> ValidationResult {
        var errors: [ValidationError] = []

        // Basic parameter validation
        for (key, value) in parameters {
            if key.isEmpty {
                errors.append(ValidationError(
                    code: "EMPTY_PARAMETER_KEY",
                    message: "Parameter key cannot be empty"
                ))
                continue
            }

            if let stringValue = value as? String {
                if stringValue.count > MCPConstants.Limits.maxParameterValueLength {
                    errors.append(ValidationError(
                        code: "PARAMETER_TOO_LONG",
                        message: "Parameter value exceeds maximum length",
                        field: key,
                        value: "\(stringValue.count) characters"
                    ))
                }
            }
        }

        // Check for required parameters based on schema
        // This is a simplified validation - in a full implementation,
        // you'd parse the JSON schema and validate against it

        return ValidationResult(errors: errors)
    }

    private func validatePermissions(for tool: MCPTool, context: MCPExecutionContext) async throws {
        for permission in tool.requiresPermission {
            // For now, we'll log permission checks
            // In a full implementation, you'd check actual system permissions
            await logger.debug("Checking permission", category: .security, metadata: [
                "permission": permission.rawValue,
                "toolName": tool.name,
                "clientId": context.clientId.uuidString
            ])
        }
    }
}

// MARK: - Supporting Types

struct MCPTool {
    let name: String
    let description: String
    let inputSchema: [String: Any]
    let category: ToolCategory
    let requiresPermission: [PermissionType]
    let offlineCapable: Bool

    // Protocol for tool execution
    var execute: (_ parameters: [String: Any], _ context: MCPExecutionContext) async throws -> MCPResponse {
        fatalError("execute method must be overridden")
    }
}

struct MCPToolInfo: Codable {
    let name: String
    let description: String
    let inputSchema: [String: AnyCodable]
    let category: ToolCategory
    let requiresPermission: [PermissionType]
    let offlineCapable: Bool

    enum CodingKeys: String, CodingKey {
        case name, description, inputSchema, category, requiresPermission, offlineCapable
    }

    init(name: String, description: String, inputSchema: [String: Any], category: ToolCategory, requiresPermission: [PermissionType], offlineCapable: Bool) {
        self.name = name
        self.description = description
        self.category = category
        self.requiresPermission = requiresPermission
        self.offlineCapable = offlineCapable

        // Convert Any to AnyCodable for JSON compatibility
        self.inputSchema = inputSchema.mapValues { AnyCodable($0) }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        category = try container.decode(ToolCategory.self, forKey: .category)
        requiresPermission = try container.decode([PermissionType].self, forKey: .requiresPermission)
        offlineCapable = try container.decode(Bool.self, forKey: .offlineCapable)

        // Handle dynamic input schema decoding
        if container.contains(.inputSchema) {
            inputSchema = try container.decode([String: AnyCodable].self, forKey: .inputSchema)
        } else {
            inputSchema = [:]
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(category, forKey: .category)
        try container.encode(requiresPermission, forKey: .requiresPermission)
        try container.encode(offlineCapable, forKey: .offlineCapable)

        // Convert AnyCodable back to [String: AnyCodable] for encoding
        let encodableSchema = inputSchema.mapValues { AnyCodable($0) }
        try container.encode(encodableSchema, forKey: .inputSchema)
    }
}

enum ToolsRegistryError: Error, LocalizedError {
    case invalidTool(String)
    case duplicateTool(String)
    case toolNotFound(String)
    case invalidParameters(String)
    case permissionDenied(String)

    var errorDescription: String? {
        switch self {
        case .invalidTool(let message):
            return "Invalid tool: \(message)"
        case .duplicateTool(let name):
            return "Tool already exists: \(name)"
        case .toolNotFound(let name):
            return "Tool not found: \(name)"
        case .invalidParameters(let message):
            return "Invalid parameters: \(message)"
        case .permissionDenied(let message):
            return "Permission denied: \(message)"
        }
    }
}

// MARK: - Base Tool Protocol

protocol MCPToolProtocol {
    var name: String { get }
    var description: String { get }
    var inputSchema: [String: Any] { get }
    var category: ToolCategory { get }
    var requiresPermission: [PermissionType] { get }
    var offlineCapable: Bool { get }

    func execute(parameters: [String: Any], context: MCPExecutionContext) async throws -> MCPResponse
}

// MARK: - Tool Base Class

class BaseMCPTool: MCPToolProtocol {
    let name: String
    let description: String
    let inputSchema: [String: Any]
    let category: ToolCategory
    let requiresPermission: [PermissionType]
    let offlineCapable: Bool
    let logger: Logger
    let securityManager: SecurityManager

    init(
        name: String,
        description: String,
        inputSchema: [String: Any],
        category: ToolCategory,
        requiresPermission: [PermissionType],
        offlineCapable: Bool,
        logger: Logger,
        securityManager: SecurityManager
    ) {
        self.name = name
        self.description = description
        self.inputSchema = inputSchema
        self.category = category
        self.requiresPermission = requiresPermission
        self.offlineCapable = offlineCapable
        self.logger = logger
        self.securityManager = securityManager
    }

    func execute(parameters: [String: Any], context: MCPExecutionContext) async throws -> MCPResponse {
        let startTime = Date()

        await logger.debug("Executing tool", category: .server, metadata: [
            "toolName": name,
            "clientId": context.clientId.uuidString,
            "parameters": parameters.sanitizedForLogging()
        ])

        do {
            let result = try await performExecution(parameters: parameters, context: context)
            let executionTime = Date().timeIntervalSince(startTime)

            await logger.debug("Tool execution completed", category: .server, metadata: [
                "toolName": name,
                "success": result.success,
                "executionTime": executionTime
            ])

            return MCPResponse(success: result.success, data: result.data, error: result.error, executionTime: executionTime)
        } catch {
            let executionTime = Date().timeIntervalSince(startTime)

            await logger.error("Tool execution failed", error: error, category: .server, metadata: [
                "toolName": name,
                "executionTime": executionTime
            ])

            return MCPResponse(success: false, error: error.mcpError, executionTime: executionTime)
        }
    }

    /// Override this method in subclasses to implement tool-specific logic
    func performExecution(parameters: [String: Any], context: MCPExecutionContext) async throws -> MCPResponse {
        throw ToolsRegistryError.toolNotFound(name)
    }
}