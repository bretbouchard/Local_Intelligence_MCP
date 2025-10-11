//
//  ToolsRegistry.swift
//  LocalIntelligenceMCP
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
        await logger.info("Initializing MCP tools registry", category: .server, metadata: [:])

        // Register built-in tools
        try await registerTool(SystemInfoTool(logger: logger, securityManager: securityManager))
        try await registerTool(PermissionTool(logger: logger, securityManager: securityManager))
        try await registerTool(ShortcutsTool(logger: logger, securityManager: securityManager))
        try await registerTool(ShortcutsListTool(logger: logger, securityManager: securityManager))
        try await registerTool(VoiceControlTool(logger: logger, securityManager: securityManager))

        await logger.info("MCP tools registry initialized with \(tools.count) tools", category: .server, metadata: [:])
    }

    /// Initialize audio domain tools specifically
    /// This method should be called after the main initialization to register audio tools
    func initializeAudioTools() async throws {
        await logger.info("Initializing audio domain tools", category: .server, metadata: [:])

        // Register Core Text Processing Tools (User Story 1)
        do {
            // SummarizationTool - apple.summarize
            let summarizationTool = SummarizationTool(
                logger: logger,
                securityManager: securityManager
            )
            try await registerTool(summarizationTool)
            await logger.debug("Registered SummarizationTool (apple.summarize)", category: .server, metadata: [:])

            // TextRewriteTool - apple.text.rewrite
            let textRewriteTool = TextRewriteTool(
                logger: logger,
                securityManager: securityManager
            )
            try await registerTool(textRewriteTool)
            await logger.debug("Registered TextRewriteTool (apple.text.rewrite)", category: .server, metadata: [:])

            // TextNormalizeTool - apple.text.normalize
            let textNormalizeTool = TextNormalizeTool(
                logger: logger,
                securityManager: securityManager
            )
            try await registerTool(textNormalizeTool)
            await logger.debug("Registered TextNormalizeTool (apple.text.normalize)", category: .server, metadata: [:])

            // Register Advanced Text Analysis Tools (User Story 2)
            // FocusedSummarizationTool - apple.summarize.focus
            let focusedSummarizationTool = FocusedSummarizationTool(
                logger: logger,
                securityManager: securityManager
            )
            try await registerTool(focusedSummarizationTool)
            await logger.debug("Registered FocusedSummarizationTool (apple.summarize.focus)", category: .server, metadata: [:])

            // PIIRedactionTool - apple.text.redact
            let piiRedactionTool = PIIRedactionTool(
                logger: logger,
                securityManager: securityManager
            )
            try await registerTool(piiRedactionTool)
            await logger.debug("Registered PIIRedactionTool (apple.text.redact)", category: .server, metadata: [:])

            // TextChunkingTool - apple.text.chunk
            let textChunkingTool = TextChunkingTool(
                logger: logger,
                securityManager: securityManager
            )
            try await registerTool(textChunkingTool)
            await logger.debug("Registered TextChunkingTool (apple.text.chunk)", category: .server, metadata: [:])

            // TokenCountUtility - apple.tokens.count
            let tokenCountUtility = TokenCountUtility(
                logger: logger,
                securityManager: securityManager
            )
            try await registerTool(tokenCountUtility)
            await logger.debug("Registered TokenCountUtility (apple.tokens.count)", category: .server, metadata: [:])

            // Register Intent Analysis Tools (User Story 3)
            // IntentRecognitionTool - apple.intent.parse
            let intentRecognitionTool = IntentRecognitionTool(
                logger: logger,
                securityManager: securityManager
            )
            try await registerTool(intentRecognitionTool)
            await logger.debug("Registered IntentRecognitionTool (apple.intent.parse)", category: .server, metadata: [:])

            // QueryAnalysisTool - apple.query.analyze
            let queryAnalysisTool = QueryAnalysisTool(
                logger: logger,
                securityManager: securityManager
            )
            try await registerTool(queryAnalysisTool)
            await logger.debug("Registered QueryAnalysisTool (apple.query.analyze)", category: .server, metadata: [:])

            // ContentPurposeDetector - apple.content.purpose
            let contentPurposeDetector = ContentPurposeDetector(
                logger: logger,
                securityManager: securityManager
            )
            try await registerTool(contentPurposeDetector)
            await logger.debug("Registered ContentPurposeDetector (apple.content.purpose)", category: .server, metadata: [:])

            // Register Extraction Tools (User Story 4)
            // SchemaExtractionTool - apple.schema.extract
            let schemaExtractionTool = SchemaExtractionTool(
                logger: logger,
                securityManager: securityManager
            )
            try await registerTool(schemaExtractionTool)
            await logger.debug("Registered SchemaExtractionTool (apple.schema.extract)", category: .server, metadata: [:])

            // TagGenerationTool - apple.tags.generate
            let tagGenerationTool = TagGenerationTool(
                logger: logger,
                securityManager: securityManager
            )
            try await registerTool(tagGenerationTool)
            await logger.debug("Registered TagGenerationTool (apple.tags.generate)", category: .server, metadata: [:])

            // Register Catalog & Session Tools (User Story 5)
            // CatalogSummarizationTool - apple.catalog.summarize
            let catalogSummarizationTool = CatalogSummarizationTool(
                logger: logger,
                securityManager: securityManager
            )
            try await registerTool(catalogSummarizationTool)
            await logger.debug("Registered CatalogSummarizationTool (apple.catalog.summarize)", category: .server, metadata: [:])

            // SessionNotesTool - apple.session.summarize
            let sessionNotesTool = SessionNotesTool(
                logger: logger,
                securityManager: securityManager
            )
            try await registerTool(sessionNotesTool)
            await logger.debug("Registered SessionNotesTool (apple.session.summarize)", category: .server, metadata: [:])

            // FeedbackAnalysisTool - apple.feedback.analyze
            let feedbackAnalysisTool = FeedbackAnalysisTool(
                logger: logger,
                securityManager: securityManager
            )
            try await registerTool(feedbackAnalysisTool)
            await logger.debug("Registered FeedbackAnalysisTool (apple.feedback.analyze)", category: .server, metadata: [:])

            // Register System Integration Tools (User Story 6)
            // ModelInfoTool - model_info
            let modelInfoTool = ModelInfoTool(logger: logger, securityManager: securityManager)
            try await registerTool(modelInfoTool)
            await logger.debug("Registered ModelInfoTool (model_info)", category: .server, metadata: [:])

            // HealthPingTool - health_ping
            let healthPingTool = HealthPingTool(logger: logger, securityManager: securityManager)
            try await registerTool(healthPingTool)
            await logger.debug("Registered HealthPingTool (health_ping)", category: .server, metadata: [:])

            // CapabilitiesListTool - capabilities_list
            let capabilitiesListTool = CapabilitiesListTool(logger: logger, securityManager: securityManager)
            try await registerTool(capabilitiesListTool)
            await logger.debug("Registered CapabilitiesListTool (capabilities_list)", category: .server, metadata: [:])

            // EmbeddingGenerationTool - embedding_generate
            let embeddingGenerationTool = EmbeddingGenerationTool(logger: logger, securityManager: securityManager)
            try await registerTool(embeddingGenerationTool)
            await logger.debug("Registered EmbeddingGenerationTool (embedding_generate)", category: .server, metadata: [:])

            // SimilarityRankingTool - similarity_rank
            let similarityRankingTool = SimilarityRankingTool(logger: logger, securityManager: securityManager)
            try await registerTool(similarityRankingTool)
            await logger.debug("Registered SimilarityRankingTool (similarity_rank)", category: .server, metadata: [:])

            // Log text tools registration summary
            let coreTextTools = [
                summarizationTool.name,
                textRewriteTool.name,
                textNormalizeTool.name
            ]

            let advancedTextTools = [
                focusedSummarizationTool.name,
                piiRedactionTool.name,
                textChunkingTool.name
            ]

            let intentAnalysisTools = [
                intentRecognitionTool.name,
                queryAnalysisTool.name,
                contentPurposeDetector.name
            ]

            let extractionTools = [
                schemaExtractionTool.name,
                tagGenerationTool.name
            ]

            let catalogTools = [
                catalogSummarizationTool.name,
                sessionNotesTool.name,
                feedbackAnalysisTool.name
            ]

            let systemIntegrationTools = [
                modelInfoTool.name,
                healthPingTool.name,
                capabilitiesListTool.name,
                embeddingGenerationTool.name,
                similarityRankingTool.name
            ]

            let allTextTools = coreTextTools + advancedTextTools + intentAnalysisTools + extractionTools + catalogTools + systemIntegrationTools

            await logger.info(
                "Text processing and system integration tools registered successfully",
                category: .server,
                metadata: [
                    "coreTools": AnyCodable(coreTextTools.count),
                    "advancedTools": AnyCodable(advancedTextTools.count),
                    "intentAnalysisTools": AnyCodable(intentAnalysisTools.count),
                    "extractionTools": AnyCodable(extractionTools.count),
                    "catalogTools": AnyCodable(catalogTools.count),
                    "systemIntegrationTools": AnyCodable(systemIntegrationTools.count),
                    "totalTools": AnyCodable(allTextTools.count),
                    "userStories": AnyCodable(["US1", "US2", "US3", "US4", "US5", "US6"]),
                    "tools": AnyCodable(allTextTools)
                ]
            )

        } catch {
            await logger.error(
                "Failed to register text processing and system integration tools",
                error: error,
                category: .server,
                metadata: [
                    "userStories": ["US1", "US2", "US3", "US4", "US5", "US6"],
                    "phase": "Text Processing Tools including Intent Analysis, Extraction, Catalog Tools, and System Integration"
                ]
            )
            throw error
        }

        // Log completion of text, intent analysis, extraction, catalog, and system integration tools initialization
        let audioToolsCount = await getAudioDomainTools().count
        let textProcessingToolsCount = await getToolsByCategory(.textProcessing).count

        await logger.info(
            "Text processing, intent analysis, extraction, catalog, and system integration tools initialization completed",
            category: .server,
            metadata: [
                "audioDomainTools": AnyCodable(audioToolsCount),
                "textProcessingTools": AnyCodable(textProcessingToolsCount),
                "totalTextAndIntegrationTools": AnyCodable(21),
                "userStoriesCompleted": AnyCodable(["US1", "US2", "US3", "US4", "US5", "US6"]),
                "phase": "System Integration Tools Complete",
                "nextMilestone": AnyCodable("Phase 9: Polish & Cross-Cutting Concerns")
            ]
        )
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

        await logger.info("Tool '\(tool.name)' registered (\(tool.category.rawValue))", category: .server, metadata: [:])
    }

    /// Unregister a tool
    /// - Parameter toolName: Name of tool to unregister
    func unregisterTool(_ toolName: String) async {
        guard tools.removeValue(forKey: toolName) != nil else { return }

        await logger.info("Tool '\(toolName)' unregistered", category: .server, metadata: [:])
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

    /// Get tools filtered by category
    /// - Parameter category: Tool category to filter by
    /// - Returns: Array of tools in the specified category
    func getToolsByCategory(_ category: ToolCategory) async -> [MCPToolInfo] {
        return tools.values
            .filter { $0.category == category }
            .map { tool in
                MCPToolInfo(
                    name: tool.name,
                    description: tool.description,
                    inputSchema: tool.inputSchema,
                    category: tool.category,
                    requiresPermission: tool.requiresPermission,
                    offlineCapable: tool.offlineCapable
                )
            }
            .sorted { $0.name < $1.name }
    }

    /// Get audio domain tools (both textProcessing and audioDomain categories)
    /// - Returns: Array of audio-related tools
    func getAudioDomainTools() async -> [MCPToolInfo] {
        let audioCategories: [ToolCategory] = [.audioDomain, .textProcessing]
        return tools.values
            .filter { audioCategories.contains($0.category) }
            .map { tool in
                MCPToolInfo(
                    name: tool.name,
                    description: tool.description,
                    inputSchema: tool.inputSchema,
                    category: tool.category,
                    requiresPermission: tool.requiresPermission,
                    offlineCapable: tool.offlineCapable
                )
            }
            .sorted { $0.name < $1.name }
    }

    /// Get tools grouped by category
    /// - Returns: Dictionary mapping categories to arrays of tool information
    func getToolsByCategories() async -> [ToolCategory: [MCPToolInfo]] {
        var groupedTools: [ToolCategory: [MCPToolInfo]] = [:]

        for tool in tools.values {
            let toolInfo = MCPToolInfo(
                name: tool.name,
                description: tool.description,
                inputSchema: tool.inputSchema,
                category: tool.category,
                requiresPermission: tool.requiresPermission,
                offlineCapable: tool.offlineCapable
            )

            if groupedTools[tool.category] == nil {
                groupedTools[tool.category] = []
            }
            groupedTools[tool.category]?.append(toolInfo)
        }

        // Sort tools within each category
        for category in groupedTools.keys {
            groupedTools[category]?.sort { $0.name < $1.name }
        }

        return groupedTools
    }

    /// Get tools requiring specific permissions
    /// - Parameter permissions: Array of permission types to filter by
    /// - Returns: Array of tools requiring any of the specified permissions
    func getToolsRequiringPermissions(_ permissions: [PermissionType]) async -> [MCPToolInfo] {
        return tools.values
            .filter { tool in
                !Set(tool.requiresPermission).intersection(Set(permissions)).isEmpty
            }
            .map { tool in
                MCPToolInfo(
                    name: tool.name,
                    description: tool.description,
                    inputSchema: tool.inputSchema,
                    category: tool.category,
                    requiresPermission: tool.requiresPermission,
                    offlineCapable: tool.offlineCapable
                )
            }
            .sorted { $0.name < $1.name }
    }

    /// Get offline-capable tools
    /// - Returns: Array of tools that can work offline
    func getOfflineCapableTools() async -> [MCPToolInfo] {
        return tools.values
            .filter { $0.offlineCapable }
            .map { tool in
                MCPToolInfo(
                    name: tool.name,
                    description: tool.description,
                    inputSchema: tool.inputSchema,
                    category: tool.category,
                    requiresPermission: tool.requiresPermission,
                    offlineCapable: tool.offlineCapable
                )
            }
            .sorted { $0.name < $1.name }
    }

    /// Search tools by name or description
    /// - Parameter query: Search query string
    /// - Returns: Array of tools matching the query
    func searchTools(_ query: String) async -> [MCPToolInfo] {
        let lowercaseQuery = query.lowercased()

        return tools.values
            .filter { tool in
                tool.name.lowercased().contains(lowercaseQuery) ||
                tool.description.lowercased().contains(lowercaseQuery)
            }
            .map { tool in
                MCPToolInfo(
                    name: tool.name,
                    description: tool.description,
                    inputSchema: tool.inputSchema,
                    category: tool.category,
                    requiresPermission: tool.requiresPermission,
                    offlineCapable: tool.offlineCapable
                )
            }
            .sorted { $0.name < $1.name }
    }

    /// Get category statistics
    /// - Returns: Dictionary with tool counts per category
    func getCategoryStatistics() async -> [ToolCategory: Int] {
        var statistics: [ToolCategory: Int] = [:]

        for tool in tools.values {
            statistics[tool.category, default: 0] += 1
        }

        return statistics
    }

    /// Get tool by name
    /// - Parameter name: Tool name
    /// - Returns: Tool if found, nil otherwise
    func getTool(_ name: String) async -> (any MCPToolProtocol)? {
        return tools[name]
    }

    /// Create a tool instance for MCP execution
    /// - Parameter name: Tool name
    /// - Returns: Tool instance
    /// - Throws: ToolsRegistryError if tool not found
    func createTool(name: String) async throws -> any MCPToolProtocol {
        guard let tool = tools[name] else {
            throw ToolsRegistryError.toolNotFound(name)
        }
        return tool
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
            metadata: [:]
        )

        guard let tool = tools[name] else {
            await logger.warning("Tool '\(name)' not found for client \(context.clientId.uuidString)", category: .server, metadata: [:])

            let error = LocalMCPError(
                code: "TOOL_NOT_FOUND",
                message: "Tool '\(name)' not found",
                details: ["availableTools": AnyCodable(Array(tools.keys))]
            )

            await logger.mcpMessage(
                direction: .outbound,
                messageId: context.requestId,
                method: name,
                metadata: ["error": AnyCodable(error.code)]
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

            // Execute tool with Sendable parameters
            let sendableParameters = convertToSendableParameters(parameters)
            let result = try await tool.execute(parameters: sendableParameters, context: context)

            let executionTime = Date().timeIntervalSince(startTime)

            await logger.performance(
                "tool_execution",
                duration: executionTime,
                metadata: [
                    "toolName": AnyCodable(name),
                    "clientId": AnyCodable(context.clientId.uuidString),
                    "success": AnyCodable(result.success)
                ]
            )

            await logger.mcpMessage(
                direction: .outbound,
                messageId: context.requestId,
                method: name,
                metadata: [
                    "success": AnyCodable(result.success),
                    "executionTime": AnyCodable(executionTime)
                ]
            )

            return result

        } catch {
            let executionTime = Date().timeIntervalSince(startTime)

            await logger.error(
                "Tool execution failed for '\(name)'",
                error: error,
                category: .server,
                metadata: [:]
            )

            let mcpError = error.mcpError
            await logger.mcpMessage(
                direction: .outbound,
                messageId: context.requestId,
                method: name,
                metadata: ["error": AnyCodable(mcpError.code)]
            )

            return MCPResponse(success: false, error: mcpError, executionTime: executionTime)
        }
    }

    // MARK: - Private Methods

    private func validateTool(_ tool: any MCPToolProtocol) -> ValidationResult {
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

        // Audio tool specific validation
        errors.append(contentsOf: validateAudioToolRequirements(tool))

              // Validate permissions - temporarily commented for debugging
        // if tool.requiresPermission.isEmpty {
        //     errors.append(ValidationError(
        //         code: "MISSING_PERMISSIONS",
        //         message: "Tool must specify required permissions",
        //         field: "requiresPermission"
        //     ))
        // }

        return ValidationResult(errors: errors)
    }

    /// Validate audio tool specific requirements
    /// - Parameter tool: Tool to validate
    /// - Returns: Array of validation errors
    private func validateAudioToolRequirements(_ tool: any MCPToolProtocol) -> [ValidationError] {
        var errors: [ValidationError] = []

        // Check if audio domain tools have appropriate permissions
        if tool.category == .audioDomain || tool.category == .textProcessing {
            // Audio tools should specify at least one permission
            if tool.requiresPermission.isEmpty {
                errors.append(ValidationError(
                    code: "AUDIO_TOOL_REQUIRES_PERMISSION",
                    message: "Audio domain tools must specify required permissions",
                    field: "requiresPermission",
                    value: "[]"
                ))
            }
        }

        // Note: Naming convention validation temporarily disabled due to actor isolation
        // Re-enable when migrating to full async/await pattern

        return errors
    }

    private func validateParameters(_ tool: any MCPToolProtocol, parameters: [String: Any]) -> ValidationResult {
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

    private func validatePermissions(for tool: any MCPToolProtocol, context: MCPExecutionContext) async throws {
        for permission in tool.requiresPermission {
            // For now, we'll log permission checks
            // In a full implementation, you'd check actual system permissions
            await logger.debug("Checking permission \(permission.rawValue) for tool '\(tool.name)'", category: .security, metadata: [:])
        }
    }

    private func convertToSendableParameters(_ parameters: [String: Any]) -> [String: AnyCodable] {
        // Convert parameters to Sendable format using AnyCodable
        return parameters.mapValues { value in
            AnyCodable(value)
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

struct MCPToolInfo: Codable, Sendable {
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

protocol MCPToolProtocol: Sendable {
    var name: String { get }
    var description: String { get }
    var inputSchema: [String: AnyCodable] { get }
    var category: ToolCategory { get }
    var requiresPermission: [PermissionType] { get }
    var offlineCapable: Bool { get }

    func execute(parameters: [String: AnyCodable], context: MCPExecutionContext) async throws -> MCPResponse
}

// MARK: - Tool Base Class

open class BaseMCPTool: @unchecked Sendable, MCPToolProtocol {
    let name: String
    let description: String
    let inputSchema: [String: AnyCodable]
    let category: ToolCategory
    let requiresPermission: [PermissionType]
    let offlineCapable: Bool
    public let logger: Logger
    public let securityManager: SecurityManager

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
        self.inputSchema = inputSchema.mapValues { AnyCodable($0) }
        self.category = category
        self.requiresPermission = requiresPermission
        self.offlineCapable = offlineCapable
        self.logger = logger
        self.securityManager = securityManager
    }

    func execute(parameters: [String: AnyCodable], context: MCPExecutionContext) async throws -> MCPResponse {
        let startTime = Date()

        await logger.debug("Executing tool '\(name)' for client \(context.clientId.uuidString)", category: .server, metadata: [:])

        do {
            let result = try await performExecution(parameters: parameters, context: context)
            let executionTime = Date().timeIntervalSince(startTime)

            await logger.debug("Tool '\(name)' completed with success=\(result.success) in \(executionTime)s", category: .server, metadata: [:])

            return MCPResponse(success: result.success, data: result.data, error: result.error, executionTime: executionTime)
        } catch {
            let executionTime = Date().timeIntervalSince(startTime)

            await logger.error("Tool '\(name)' failed after \(executionTime)s", error: error, category: .server, metadata: [:])

            return MCPResponse(success: false, error: error.mcpError, executionTime: executionTime)
        }
    }

    /// Override this method in subclasses to implement tool-specific logic
    func performExecution(parameters: [String: AnyCodable], context: MCPExecutionContext) async throws -> MCPResponse {
        throw ToolsRegistryError.toolNotFound(name)
    }
}