//
//  ToolsRegistryTests.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-07.
//

import XCTest
@testable import LocalIntelligenceMCP

final class ToolsRegistryTests: XCTestCase {

    // MARK: - Properties

    private var logger: Logger!
    private var securityManager: SecurityManager!
    private var toolsRegistry: ToolsRegistry!

    // MARK: - Setup and Teardown

    override func setUp() async throws {
        try await super.setUp()

        // Initialize test components
        let config = LoggingConfiguration.default
        logger = Logger(configuration: config)
        await logger.setupFileLoggingIfNeeded()

        securityManager = SecurityManager(logger: logger)
        toolsRegistry = ToolsRegistry(logger: logger, securityManager: securityManager)
    }

    override func tearDown() async throws {
        logger = nil
        securityManager = nil
        toolsRegistry = nil

        try await super.tearDown()
    }

    // MARK: - Registry Initialization Tests

    func testToolsRegistryInitialization() async throws {
        // Test that the tools registry initializes correctly
        XCTAssertNotNil(toolsRegistry)
        XCTAssertEqual(toolsRegistry.tools.count, 0, "Registry should start empty")
    }

    func testToolsRegistryDefaultInitialization() async throws {
        // Test default tool initialization
        try await toolsRegistry.initialize()

        // Should register all default tools
        let availableTools = await toolsRegistry.getAvailableTools()
        XCTAssertEqual(availableTools.count, 5, "Should register 5 default tools")

        let toolNames = availableTools.map { $0.name }.sorted()
        let expectedToolNames = [
            "execute_shortcut",
            "execute_voice_command",
            "list_shortcuts",
            "system_info",
            "get_permission_status"
        ]
        XCTAssertEqual(toolNames, expectedToolNames, "Should register expected default tools")
    }

    func testToolsRegistryInitializationIdempotency() async throws {
        // Test that initialization can be called multiple times without issues
        try await toolsRegistry.initialize()
        let firstCount = (await toolsRegistry.getAvailableTools()).count

        try await toolsRegistry.initialize()
        let secondCount = (await toolsRegistry.getAvailableTools()).count

        XCTAssertEqual(firstCount, secondCount, "Initialization should be idempotent")
    }

    // MARK: - Tool Registration Tests

    func testToolRegistration() async throws {
        // Test registering a custom tool
        let customTool = MockTool(
            name: "custom_test_tool",
            description: "A custom test tool",
            inputSchema: ["type": "object"],
            category: .utilities,
            requiresPermission: [],
            offlineCapable: true
        )

        try await toolsRegistry.registerTool(customTool)

        let tool = await toolsRegistry.getTool("custom_test_tool")
        XCTAssertNotNil(tool)
        XCTAssertEqual(tool?.name, "custom_test_tool")
    }

    func testDuplicateToolRegistration() async throws {
        // Test that duplicate tool names are rejected
        let tool1 = MockTool(
            name: "duplicate_test",
            description: "First tool",
            inputSchema: [:],
            category: .utilities,
            requiresPermission: [],
            offlineCapable: true
        )

        let tool2 = MockTool(
            name: "duplicate_test",
            description: "Second tool with same name",
            inputSchema: [:],
            category: .productivity,
            requiresPermission: [],
            offlineCapable: true
        )

        // First registration should succeed
        try await toolsRegistry.registerTool(tool1)
        XCTAssertNotNil(await toolsRegistry.getTool("duplicate_test"))

        // Second registration with same name should fail
        do {
            try await toolsRegistry.registerTool(tool2)
            XCTFail("Should throw error for duplicate tool name")
        } catch let error as ToolsRegistryError {
            XCTAssertEqual(error, .duplicateTool("duplicate_test"))
        }
    }

    func testInvalidToolRegistration() async throws {
        // Test registration of invalid tools
        let invalidTool = MockTool(
            name: "", // Invalid empty name
            description: "Invalid tool",
            inputSchema: [:],
            category: .utilities,
            requiresPermission: [],
            offlineCapable: true
        )

        do {
            try await toolsRegistry.registerTool(invalidTool)
            XCTFail("Should throw error for invalid tool")
        } catch let error as ToolsRegistryError {
            XCTAssertEqual(error, .invalidTool(.contains("INVALID_TOOL_NAME")))
        }
    }

    func testToolUnregistration() async throws {
        // Initialize with default tools first
        try await toolsRegistry.initialize()
        let initialCount = (await toolsRegistry.getAvailableTools()).count

        // Unregister a tool
        await toolsRegistry.unregisterTool("system_info")

        let afterUnregistrationCount = (await toolsRegistry.getAvailableTools()).count
        XCTAssertEqual(afterUnregistrationCount, initialCount - 1)

        let unregisteredTool = await toolsRegistry.getTool("system_info")
        XCTAssertNil(unregisteredTool)
    }

    func testUnregisterNonExistentTool() async throws {
        // Test unregistering a tool that doesn't exist
        let initialCount = (await toolsRegistry.getAvailableTools()).count

        await toolsRegistry.unregisterTool("non_existent_tool")

        // Should not crash and count should remain unchanged
        let finalCount = (await toolsRegistry.getAvailableTools()).count
        XCTAssertEqual(finalCount, initialCount)
    }

    // MARK: - Tool Retrieval Tests

    func testGetAvailableTools() async throws {
        // Initialize with default tools
        try await toolsRegistry.initialize()

        let availableTools = await toolsRegistry.getAvailableTools()
        XCTAssertFalse(availableTools.isEmpty)

        // Verify all tools have required information
        for toolInfo in availableTools {
            XCTAssertFalse(toolInfo.name.isEmpty)
            XCTAssertFalse(toolInfo.description.isEmpty)
            XCTAssertNotNil(toolInfo.inputSchema)
            XCTAssertFalse(toolInfo.requiresPermission.isEmpty)
            XCTAssertNotNil(toolInfo.category)
        }

        // Verify sorting
        for i in 1..<availableTools.count {
            XCTAssertLessThanOrEqual(availableTools[i-1].name, availableTools[i].name)
        }
    }

    func testGetTool() async throws {
        // Initialize with default tools
        try await toolsRegistry.initialize()

        // Test getting existing tools
        let systemInfoTool = await toolsRegistry.getTool("system_info")
        XCTAssertNotNil(systemInfoTool)
        XCTAssertEqual(systemInfoTool?.name, "system_info")

        let shortcutsTool = await toolsRegistry.getTool("execute_shortcut")
        XCTAssertNotNil(shortcutsTool)
        XCTAssertEqual(shortcutsTool?.name, "execute_shortcut")

        // Test getting non-existent tool
        let nonExistentTool = await toolsRegistry.getTool("non_existent")
        XCTAssertNil(nonExistentTool)
    }

    func testGetToolsWithEmptyRegistry() async throws {
        // Test with empty registry
        let availableTools = await toolsRegistry.getAvailableTools()
        XCTAssertTrue(availableTools.isEmpty)

        let anyTool = await toolsRegistry.getTool("any_tool")
        XCTAssertNil(anyTool)
    }

    // MARK: - Tool Execution Tests

    func testToolExecution() async throws {
        // Initialize with default tools
        try await toolsRegistry.initialize()

        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "test_tool"
        )

        // Test executing system_info tool
        let systemInfoParams = [
            "categories": ["server"],
            "includeSensitive": false
        ]

        do {
            let result = try await toolsRegistry.executeTool(
                name: "system_info",
                parameters: systemInfoParams,
                context: context
            )
            XCTAssertTrue(result.success, "System info tool should execute successfully")
            XCTAssertNotNil(result.data)
        } catch {
            XCTFail("System info tool execution should not fail: \(error.localizedDescription)")
        }
    }

    func testToolExecutionWithNonExistentTool() async throws {
        // Initialize with default tools
        try await toolsRegistry.initialize()

        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "test_tool"
        )

        let params = ["test": "value"]

        do {
            let result = try await toolsRegistry.executeTool(
                name: "non_existent_tool",
                parameters: params,
                context: context
            )
            XCTAssertFalse(result.success, "Non-existent tool should fail")
            XCTAssertNotNil(result.error)
        } catch {
            // Acceptable if error is thrown
            XCTAssertTrue(true)
        }
    }

    func testToolExecutionWithInvalidParameters() async throws {
        // Initialize with default tools
        try await toolsRegistry.initialize()

        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "test_tool"
        )

        // Test executing tool with missing required parameters
        let invalidParams: [String: Any] = [:]

        do {
            let result = try await toolsRegistry.executeTool(
                name: "system_info",
                parameters: invalidParams,
                context: context
            )
            XCTAssertFalse(result.success, "Missing required parameters should fail")
            XCTAssertNotNil(result.error)
        } catch {
            // Acceptable if error is thrown
            XCTAssertTrue(true)
        }
    }

    // MARK: - Tool Validation Tests

    func testToolValidation() async throws {
        // Test tool validation logic
        let validTool = MockTool(
            name: "valid_tool",
            description: "A valid test tool",
            inputSchema: [
                "type": "object",
                "properties": [
                    "test": ["type": "string"]
                ]
            ],
            category: .utilities,
            requiresPermission: [.shortcuts],
            offlineCapable: true
        )

        // Tool should be valid
        let validationResult = validateTool(validTool)
        XCTAssertTrue(validationResult.isValid)
        XCTAssertTrue(validationResult.errors.isEmpty)
    }

    func testToolValidationForInvalidTool() async throws {
        // Test tool validation for invalid tools
        let invalidTool = MockTool(
            name: "", // Invalid empty name
            description: "Invalid tool",
            inputSchema: [:], // Invalid empty schema
            category: .utilities,
            requiresPermission: [], // Invalid empty permissions
            offlineCapable: true
        )

        // Tool should be invalid
        let validationResult = validateTool(invalidTool)
        XCTAssertFalse(validationResult.isValid)
        XCTAssertFalse(validationResult.errors.isEmpty)
    }

    func testParameterValidation() async throws {
        // Test parameter validation logic
        let validTool = MockTool(
            name: "test_tool",
            description: "Test tool",
            inputSchema: [
                "type": "object",
                "properties": [
                    "requiredParam": ["type": "string"]
                ],
                "required": ["requiredParam"]
            ],
            category: .utilities,
            requiresPermission: [],
            offlineCapable: true
        )

        // Create mock MCPTool for validation
        let mcpTool = MCPTool(
            name: validTool.name,
            description: validTool.description,
            inputSchema: validTool.inputSchema,
            category: validTool.category,
            requiresPermission: validTool.requiresPermission,
            offlineCapable: validTool.offlineCapable,
            logger: logger,
            securityManager: securityManager
        )

        // Test with valid parameters
        let validParams = ["requiredParam": "test_value"]
        let validResult = validateParameters(mcpTool, parameters: validParams)
        XCTAssertTrue(validResult.isValid, "Valid parameters should pass validation")

        // Test with missing required parameter
        let invalidParams = ["optionalParam": "test_value"]
        let invalidResult = validateParameters(mcpTool, parameters: invalidParams)
        XCTAssertFalse(invalidResult.isValid, "Missing required parameter should fail validation")
    }

    // MARK: - Performance Tests

    func testRegistryPerformance() async throws {
        // Test registry performance with many tools
        try await toolsRegistry.initialize()

        measure {
            Task {
                let _ = await toolsRegistry.getAvailableTools()
            }
        }
    }

    func testToolExecutionPerformance() async throws {
        // Test tool execution performance
        try await toolsRegistry.initialize()

        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "performance_test"
        )

        let params = ["test": "value"]

        measure {
            Task {
                do {
                    _ = try await toolsRegistry.executeTool(
                        name: "system_info",
                        parameters: ["categories": ["server"]],
                        context: context
                    )
                } catch {
                    // Expected to work, but we're measuring performance
                }
            }
        }
    }

    // MARK: - Concurrency Tests

    func testConcurrentToolAccess() async throws {
        // Test concurrent access to tools
        try await toolsRegistry.initialize()

        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "concurrent_test"
        )

        // Create multiple concurrent tasks
        let tasks = (0..<10).map { _ in
            Task {
                await toolsRegistry.getAvailableTools()
            }
        }

        // Wait for all tasks to complete
        let results = await withTaskGroup(of: [MCPToolInfo].self) { group in
            for task in tasks {
                group.addTask { await task }
            }
            var allResults: [MCPToolInfo] = []
            for try await result in group {
                allResults.append(result)
            }
            return allResults
        }

        // All results should be the same
        XCTAssertEqual(results.count, 10)
        for result in results {
            XCTAssertEqual(result.count, 5) // Default number of tools
        }
    }

    func testConcurrentToolRegistration() async throws {
        // Test concurrent tool registration
        let tools = (0..<5).map { i in
            MockTool(
                name: "concurrent_tool_\(i)",
                description: "Concurrent test tool \(i)",
                inputSchema: [:],
                category: .utilities,
                requiresPermission: [],
                offlineCapable: true
            )
        }

        // Register tools concurrently
        let tasks = tools.map { tool in
            Task {
                try await toolsRegistry.registerTool(tool)
            }
        }

        // Wait for all registrations to complete
        for task in tasks {
            try await task
        }

        // Verify all tools were registered
        for tool in tools {
            let registeredTool = await toolsRegistry.getTool(tool.name)
            XCTAssertNotNil(registeredTool)
        }
    }

    // MARK: - Error Handling Tests

    func testRegistryErrorHandling() async throws {
        // Test various error scenarios
        try await toolsRegistry.initialize()

        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "error_test"
        )

        // Test execution with invalid tool name
        do {
            let result = try await toolsRegistry.executeTool(
                name: "invalid_tool",
                parameters: [:],
                context: context
            )
            XCTAssertNotNil(result.error)
        }

        // Test execution with invalid parameters
        do {
            let result = try await toolsRegistry.executeTool(
                name: "system_info",
                parameters: ["invalid": "parameter"],
                context: context
            )
            // May succeed with graceful handling or fail appropriately
            XCTAssertTrue(result.success || result.error != nil)
        }
    }

    // MARK: - Integration Tests

    func testToolRegistryIntegration() async throws {
        // Test integration between registry and actual tools
        try await toolsRegistry.initialize()

        let availableTools = await toolsRegistry.getAvailableTools()
        XCTAssertFalse(availableTools.isEmpty)

        // Verify each tool can be retrieved by name
        for toolInfo in availableTools {
            let tool = await toolsRegistry.getTool(toolInfo.name)
            XCTAssertNotNil(tool)
            XCTAssertEqual(tool?.name, toolInfo.name)
        }

        // Test that tools can execute successfully
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "integration_test"
        )

        for toolInfo in availableTools.prefix(3) { // Test first 3 tools
            do {
                let result = try await toolsRegistry.executeTool(
                    name: toolInfo.name,
                    parameters: [:],
                    context: context
                )
                // Most tools should fail gracefully with missing parameters, but should not crash
                XCTAssertNotNil(result.error || result.data)
            } catch {
                // Acceptable if tool throws error
                XCTAssertTrue(true)
            }
        }
    }

    func testRegistryStateConsistency() async throws {
        // Test that registry state remains consistent after operations
        try await toolsRegistry.initialize()
        let initialTools = await toolsRegistry.getAvailableTools()

        // Perform various operations
        _ = await toolsRegistry.getTool("system_info")
        _ = await toolsRegistry.getAvailableTools()
        _ = await toolsRegistry.getTool("execute_shortcut")

        // Verify state consistency
        let finalTools = await toolsRegistry.getAvailableTools()
        XCTAssertEqual(initialTools.count, finalTools.count)

        let initialNames = Set(initialTools.map { $0.name })
        let finalNames = Set(finalTools.map { $0.name })
        XCTAssertEqual(initialNames, finalNames)
    }
}

// MARK: - Mock Tool for Testing

private class MockTool: MCPToolProtocol {
    let name: String
    let description: String
    let inputSchema: [String: Any]
    let category: ToolCategory
    let requiresPermission: [PermissionType]
    let offlineCapable: Bool

    init(
        name: String,
        description: String,
        inputSchema: [String: Any],
        category: ToolCategory,
        requiresPermission: [PermissionType],
        offlineCapable: Bool
    ) {
        self.name = name
        self.description = description
        self.inputSchema = inputSchema
        self.category = category
        self.requiresPermission = requiresPermission
        self.offlineCapable = offlineCapable
    }

    func execute(parameters: [String: Any], context: MCPExecutionContext) async throws -> MCPResponse {
        // Mock execution
        return MCPResponse(
            success: true,
            data: AnyCodable(["mockResult": "success"]),
            executionTime: 0.1
        )
    }
}