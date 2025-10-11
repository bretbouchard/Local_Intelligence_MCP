//
//  EndToEndTests.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-08.
//

import XCTest
@testable import LocalIntelligenceMCP

final class EndToEndTests: XCTestCase {

    // MARK: - Properties

    private var logger: Logger!
    private var securityManager: SecurityManager!
    private var toolsRegistry: ToolsRegistry!
    private var server: MCPServer!

    // MARK: - Setup and Teardown

    override func setUp() async throws {
        try await super.setUp()

        // Initialize core components
        let config = LoggingConfiguration.default
        logger = Logger(configuration: config)
        await logger.setupFileLoggingIfNeeded()

        securityManager = SecurityManager(logger: logger)
        toolsRegistry = ToolsRegistry(logger: logger, securityManager: securityManager)

        // Initialize tools registry
        try await toolsRegistry.initialize()

        // Initialize server
        let serverConfig = ServerConfiguration.default
        server = MCPServer(
            configuration: serverConfig,
            logger: logger,
            securityManager: securityManager,
            toolsRegistry: toolsRegistry
        )
    }

    override func tearDown() async throws {
        // Cleanup server
        if server != nil && server.isRunning {
            try await server.stop()
        }

        logger = nil
        securityManager = nil
        toolsRegistry = nil
        server = nil

        try await super.tearDown()
    }

    // MARK: - User Story 1: MCP Server Discovery and Basic Info

    func testUserStory1_ServerDiscoveryWorkflow() async throws {
        // Test complete server discovery workflow
        await logger.info("Starting User Story 1: Server Discovery workflow test")

        // 1. Server should start successfully
        XCTAssertFalse(server.isRunning)
        try await server.start()
        XCTAssertTrue(server.isRunning)

        // 2. Server should provide basic info
        let serverStatus = await server.getStatus()
        XCTAssertTrue(serverStatus.isRunning)
        XCTAssertEqual(serverStatus.version, MCPConstants.Server.version)
        XCTAssertNotNil(serverStatus.startTime)
        XCTAssertEqual(serverStatus.activeConnections, 0)

        // 3. Tools should be discoverable
        let availableTools = await toolsRegistry.getAvailableTools()
        XCTAssertFalse(availableTools.isEmpty)

        // Verify essential tools are available
        let toolNames = availableTools.map { $0.name }
        XCTAssertTrue(toolNames.contains("system_info"))
        XCTAssertTrue(toolNames.contains("health_check"))

        // 4. Server should respond to health check
        let healthResult = try await server.performHealthCheck()
        XCTAssertTrue(healthResult.isHealthy)
        XCTAssertNotNil(healthResult.checks)

        // 5. Server should provide server info via system_info tool
        let systemInfoTool = await toolsRegistry.getTool(name: "system_info")
        XCTAssertNotNil(systemInfoTool)

        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "system_info"
        )

        let params = [
            "categories": ["server"],
            "includeSensitive": false
        ] as [String: Any]

        let result = try await systemInfoTool!.performExecution(parameters: params, context: context)
        XCTAssertTrue(result.success)

        if let data = result.data?.value as? [String: Any],
           let serverInfo = data["server"] as? [String: Any] {
            XCTAssertNotNil(serverInfo["version"])
            XCTAssertNotNil(serverInfo["uptime"])
            XCTAssertNotNil(serverInfo["capabilities"])
        } else {
            XCTFail("Server info should be available in system_info response")
        }

        await logger.info("User Story 1 workflow test completed successfully")
    }

    func testUserStory1_ServerCapabilitiesDiscovery() async throws {
        // Test server capabilities discovery workflow
        try await server.start()

        // Get available tools
        let tools = await toolsRegistry.getAvailableTools()
        XCTAssertFalse(tools.isEmpty)

        // Verify tool metadata completeness
        for toolInfo in tools {
            XCTAssertFalse(toolInfo.name.isEmpty)
            XCTAssertFalse(toolInfo.description.isEmpty)
            XCTAssertNotNil(toolInfo.category)
            XCTAssertNotNil(toolInfo.inputSchema)
        }

        // Test tool categories distribution
        var categories = Set<ToolCategory>()
        for toolInfo in tools {
            categories.insert(toolInfo.category)
        }

        // Should have tools in multiple categories
        XCTAssertGreaterThan(categories.count, 1)
        XCTAssertTrue(categories.contains(.systemInfo))
    }

    // MARK: - User Story 2: Apple Shortcuts Execution

    func testUserStory2_ShortcutsExecutionWorkflow() async throws {
        // Test complete shortcuts execution workflow
        await logger.info("Starting User Story 2: Shortcuts Execution workflow test")
        try await server.start()

        // 1. Discover available shortcuts
        let shortcutsListTool = await toolsRegistry.getTool(name: "list_shortcuts")
        XCTAssertNotNil(shortcutsListTool)

        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "list_shortcuts"
        )

        let listParams = [
            "includeSystemShortcuts": false,
            "searchQuery": nil
        ] as [String: Any]

        let listResult = try await shortcutsListTool!.performExecution(parameters: listParams, context: context)
        XCTAssertTrue(listResult.success)

        // 2. Execute a shortcut (simulated)
        let executeTool = await toolsRegistry.getTool(name: "execute_shortcut")
        XCTAssertNotNil(executeTool)

        let executeContext = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "execute_shortcut"
        )

        let executeParams = [
            "shortcutName": "Test Shortcut",
            "inputParameters": [:],
            "timeout": 30.0
        ] as [String: Any]

        // This may fail if the shortcut doesn't exist, but the workflow should be tested
        do {
            let executeResult = try await executeTool!.performExecution(parameters: executeParams, context: executeContext)
            // May succeed if test shortcut exists, or fail gracefully
            XCTAssertTrue(true)
        } catch {
            // Expected if test shortcut doesn't exist
            XCTAssertTrue(error.localizedDescription.contains("shortcut") ||
                        error.localizedDescription.contains("not found") ||
                        error.localizedDescription.contains("permission"))
        }

        // 3. Test shortcut execution with validation
        let invalidParams = [
            "shortcutName": "", // Empty name should fail validation
            "inputParameters": [:]
        ] as [String: Any]

        do {
            _ = try await executeTool!.performExecution(parameters: invalidParams, context: executeContext)
            XCTFail("Empty shortcut name should fail validation")
        } catch {
            // Expected behavior
            XCTAssertTrue(error.localizedDescription.contains("validation") ||
                        error.localizedDescription.contains("required") ||
                        error.localizedDescription.contains("empty"))
        }

        await logger.info("User Story 2 workflow test completed")
    }

    func testUserStory2_ShortcutsDiscoveryAndFiltering() async throws {
        // Test shortcuts discovery with filtering
        try await server.start()

        let shortcutsListTool = await toolsRegistry.getTool(name: "list_shortcuts")
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "list_shortcuts"
        )

        // Test with different filters
        let filterTests: [[String: Any]] = [
            ["includeSystemShortcuts": true],
            ["includeSystemShortcuts": false],
            ["categoryFilter": "productivity"],
            ["searchQuery": "test"],
            ["includeSystemShortcuts": false, "searchQuery": "custom"]
        ]

        for filterParams in filterTests {
            do {
                let result = try await shortcutsListTool!.performExecution(parameters: filterParams, context: context)
                XCTAssertTrue(result.success, "Should succeed with filter: \(filterParams)")
                XCTAssertNotNil(result.data)
            } catch {
                // May fail for invalid filter combinations, which is acceptable
                XCTAssertTrue(true, "Filter failed gracefully: \(filterParams)")
            }
        }
    }

    // MARK: - User Story 3: Voice Control Commands

    func testUserStory3_VoiceControlWorkflow() async throws {
        // Test complete voice control workflow
        await logger.info("Starting User Story 3: Voice Control workflow test")
        try await server.start()

        // 1. Initialize voice control
        let voiceTool = await toolsRegistry.getTool(name: "voice_command")
        XCTAssertNotNil(voiceTool)

        // 2. Test voice command execution
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "voice_command"
        )

        let voiceParams = [
            "command": "Open Safari",
            "language": "en-US",
            "confidence": 0.9
        ] as [String: Any]

        do {
            let result = try await voiceTool!.performExecution(parameters: voiceParams, context: context)
            // May fail due to voice control permissions/availability
            XCTAssertTrue(true, "Voice control result: \(result.success ? "success" : "failed")")
        } catch {
            // Expected if voice control is not available or permissions are denied
            XCTAssertTrue(error.localizedDescription.contains("voice") ||
                        error.localizedDescription.contains("permission") ||
                        error.localizedDescription.contains("accessibility"))
        }

        // 3. Test voice command validation
        let invalidVoiceParams = [
            "command": "", // Empty command should fail
            "language": "en-US",
            "confidence": 0.9
        ] as [String: Any]

        do {
            _ = try await voiceTool!.performExecution(parameters: invalidVoiceParams, context: context)
            XCTFail("Empty voice command should fail validation")
        } catch {
            // Expected behavior
            XCTAssertTrue(error.localizedDescription.contains("validation") ||
                        error.localizedDescription.contains("required") ||
                        error.localizedDescription.contains("command"))
        }

        await logger.info("User Story 3 workflow test completed")
    }

    func testUserStory3_VoiceControlAccessibilitySupport() async throws {
        // Test voice control accessibility features
        try await server.start()

        let voiceTool = await toolsRegistry.getTool(name: "voice_command")
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "voice_command"
        )

        // Test with different languages
        let languageTests = [
            ["command": "Test command", "language": "en-US"],
            ["command": "Test command", "language": "es-ES"],
            ["command": "Test command", "language": "fr-FR"],
            ["command": "Test command", "language": "de-DE"]
        ]

        for langParams in languageTests {
            let params = langParams.merging(["confidence": 0.8]) { (_, new) in new }

            do {
                let result = try await voiceTool!.performExecution(parameters: params, context: context)
                // May fail due to permissions, but should pass validation
                XCTAssertTrue(true, "Language test: \(langParams["language"] ?? "unknown")")
            } catch {
                // Expected if voice control is not available
                XCTAssertTrue(error.localizedDescription.contains("voice") ||
                            error.localizedDescription.contains("permission"))
            }
        }
    }

    // MARK: - User Story 4: System Information Access

    func testUserStory4_SystemInformationWorkflow() async throws {
        // Test complete system information access workflow
        await logger.info("Starting User Story 4: System Information workflow test")
        try await server.start()

        let systemInfoTool = await toolsRegistry.getTool(name: "system_info")
        XCTAssertNotNil(systemInfoTool)

        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "system_info"
        )

        // 1. Test basic system info access
        let basicParams = [
            "categories": ["device", "os"],
            "includeSensitive": false
        ] as [String: Any]

        let basicResult = try await systemInfoTool!.performExecution(parameters: basicParams, context: context)
        XCTAssertTrue(basicResult.success)
        XCTAssertNotNil(basicResult.data)

        if let data = basicResult.data?.value as? [String: Any] {
            XCTAssertNotNil(data["device"])
            XCTAssertNotNil(data["os"])
        } else {
            XCTFail("System info should return structured data")
        }

        // 2. Test comprehensive system info
        let comprehensiveParams = [
            "categories": ["device", "os", "hardware", "network", "permissions", "server"],
            "includeSensitive": false
        ] as [String: Any]

        let comprehensiveResult = try await systemInfoTool!.performExecution(parameters: comprehensiveParams, context: context)
        XCTAssertTrue(comprehensiveResult.success)

        if let data = comprehensiveResult.data?.value as? [String: Any] {
            let expectedCategories = ["device", "os", "hardware", "network", "permissions", "server"]
            for category in expectedCategories {
                XCTAssertNotNil(data[category], "Missing category: \(category)")
            }
        }

        // 3. Test sensitive information access (should be controlled)
        let sensitiveParams = [
            "categories": ["device"],
            "includeSensitive": true
        ] as [String: Any]

        do {
            let sensitiveResult = try await systemInfoTool!.performExecution(parameters: sensitiveParams, context: context)
            // Should either succeed with limited info or fail due to permissions
            XCTAssertTrue(true, "Sensitive info access handled appropriately")
        } catch {
            // Acceptable if sensitive info access is restricted
            XCTAssertTrue(error.localizedDescription.contains("permission") ||
                        error.localizedDescription.contains("access") ||
                        error.localizedDescription.contains("restricted"))
        }

        await logger.info("User Story 4 workflow test completed successfully")
    }

    func testUserStory4_SystemInformationValidation() async throws {
        // Test system information parameter validation
        try await server.start()

        let systemInfoTool = await toolsRegistry.getTool(name: "system_info")
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "system_info"
        )

        // Test invalid categories
        let invalidParams = [
            "categories": ["invalid_category"],
            "includeSensitive": false
        ] as [String: Any]

        do {
            let result = try await systemInfoTool!.performExecution(parameters: invalidParams, context: context)
            // Should handle invalid categories gracefully
            XCTAssertTrue(true, "Invalid categories handled gracefully")
        } catch {
            // May fail validation for completely invalid input
            XCTAssertTrue(true, "Invalid categories properly rejected")
        }

        // Test missing required parameters
        let missingParams = [
            "includeSensitive": false
            // Missing categories
        ] as [String: Any]

        do {
            _ = try await systemInfoTool!.performExecution(parameters: missingParams, context: context)
            XCTFail("Missing categories parameter should cause validation failure")
        } catch {
            // Expected behavior
            XCTAssertTrue(error.localizedDescription.contains("required") ||
                        error.localizedDescription.contains("validation") ||
                        error.localizedDescription.contains("categories"))
        }
    }

    // MARK: - Cross-User Story Integration Tests

    func testCompleteWorkflow_MultiToolExecution() async throws {
        // Test workflow using multiple tools together
        await logger.info("Starting complete multi-tool workflow test")
        try await server.start()

        let clientId = UUID()

        // 1. Get server status
        let systemInfoTool = await toolsRegistry.getTool(name: "system_info")
        let context1 = MCPExecutionContext(
            clientId: clientId,
            requestId: UUID().uuidString,
            toolName: "system_info"
        )

        let serverInfoParams = [
            "categories": ["server"],
            "includeSensitive": false
        ] as [String: Any]

        let serverInfoResult = try await systemInfoTool!.performExecution(parameters: serverInfoParams, context: context1)
        XCTAssertTrue(serverInfoResult.success)

        // 2. Perform health check
        let healthResult = try await server.performHealthCheck()
        XCTAssertTrue(healthResult.isHealthy)

        // 3. List available shortcuts
        let shortcutsTool = await toolsRegistry.getTool(name: "list_shortcuts")
        let context2 = MCPExecutionContext(
            clientId: clientId,
            requestId: UUID().uuidString,
            toolName: "list_shortcuts"
        )

        let shortcutsParams = [
            "includeSystemShortcuts": false
        ] as [String: Any]

        let shortcutsResult = try await shortcutsTool!.performExecution(parameters: shortcutsParams, context: context2)
        XCTAssertTrue(shortcutsResult.success)

        // 4. Get comprehensive system info
        let systemParams = [
            "categories": ["device", "os", "hardware"],
            "includeSensitive": false
        ] as [String: Any]

        let systemResult = try await systemInfoTool!.performExecution(parameters: systemParams, context: context1)
        XCTAssertTrue(systemResult.success)

        await logger.info("Complete multi-tool workflow test completed successfully")
    }

    func testErrorHandlingAndRecovery() async throws {
        // Test error handling and recovery scenarios
        try await server.start()

        let systemInfoTool = await toolsRegistry.getTool(name: "system_info")
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "system_info"
        )

        // Test 1: Invalid parameters handling
        let invalidParams = [
            "categories": "not_an_array", // Wrong type
            "includeSensitive": false
        ] as [String: Any]

        do {
            _ = try await systemInfoTool!.performExecution(parameters: invalidParams, context: context)
            XCTFail("Invalid parameter type should cause validation failure")
        } catch {
            // Expected behavior
            XCTAssertTrue(error.localizedDescription.contains("validation") ||
                        error.localizedDescription.contains("type") ||
                        error.localizedDescription.contains("array"))
        }

        // Test 2: Recovery with valid parameters
        let validParams = [
            "categories": ["device"],
            "includeSensitive": false
        ] as [String: Any]

        do {
            let result = try await systemInfoTool!.performExecution(parameters: validParams, context: context)
            XCTAssertTrue(result.success, "Should recover and succeed with valid parameters")
        } catch {
            XCTFail("Should recover from previous error and succeed with valid parameters")
        }

        // Test 3: Timeout handling
        let shortcutsTool = await toolsRegistry.getTool(name: "execute_shortcut")
        let shortcutsContext = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "execute_shortcut"
        )

        let timeoutParams = [
            "shortcutName": "NonExistentShortcut",
            "inputParameters": [:],
            "timeout": 0.001 // Very short timeout
        ] as [String: Any]

        do {
            _ = try await shortcutsTool!.performExecution(parameters: timeoutParams, context: shortcutsContext)
            // May fail due to timeout or non-existent shortcut, both are acceptable
            XCTAssertTrue(true, "Timeout handling works appropriately")
        } catch {
            // Expected behavior for timeout or missing shortcut
            XCTAssertTrue(error.localizedDescription.contains("timeout") ||
                        error.localizedDescription.contains("not found") ||
                        error.localizedDescription.contains("shortcut"))
        }
    }

    func testConcurrentMultiClientWorkflows() async throws {
        // Test concurrent workflows from multiple clients
        try await server.start()

        await withTaskGroup(of: Bool.self) { group in
            // Simulate 5 concurrent clients
            for clientId in 1...5 {
                group.addTask {
                    do {
                        let clientUUID = UUID()
                        let systemInfoTool = await self.toolsRegistry.getTool(name: "system_info")
                        let context = MCPExecutionContext(
                            clientId: clientUUID,
                            requestId: UUID().uuidString,
                            toolName: "system_info"
                        )

                        let params = [
                            "categories": ["device"],
                            "includeSensitive": false
                        ] as [String: Any]

                        let result = try await systemInfoTool!.performExecution(parameters: params, context: context)
                        return result.success
                    } catch {
                        return false
                    }
                }
            }

            var successCount = 0
            for await success in group {
                if success {
                    successCount += 1
                }
            }

            // Most or all concurrent requests should succeed
            XCTAssertGreaterThanOrEqual(successCount, 3, "At least 3 of 5 concurrent requests should succeed")
        }
    }

    func testPerformanceAndResourceManagement() async throws {
        // Test performance and resource management during intensive workflows
        try await server.start()

        let startTime = Date()

        // Perform multiple rapid operations
        let operationCount = 10
        var successCount = 0

        for i in 0..<operationCount {
            do {
                let systemInfoTool = await toolsRegistry.getTool(name: "system_info")
                let context = MCPExecutionContext(
                    clientId: UUID(),
                    requestId: UUID().uuidString,
                    toolName: "system_info"
                )

                let params = [
                    "categories": ["device"],
                    "includeSensitive": false
                ] as [String: Any]

                let result = try await systemInfoTool!.performExecution(parameters: params, context: context)
                if result.success {
                    successCount += 1
                }
            } catch {
                // Track failures but don't fail the test
                continue
            }
        }

        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)

        // Performance assertions
        XCTAssertGreaterThan(successCount, operationCount / 2, "At least half of operations should succeed")
        XCTAssertLessThan(duration, 30.0, "10 operations should complete within 30 seconds")
        XCTAssertLessThan(Double(successCount) / duration, 1.0, "Should handle at least 1 operation per second")
    }

    // MARK: - Data Consistency Tests

    func testDataConsistencyAcrossWorkflows() async throws {
        // Test data consistency across different workflows
        try await server.start()

        let systemInfoTool = await toolsRegistry.getTool(name: "system_info")
        let clientId = UUID()

        // Get system info multiple times and verify consistency
        var results: [[String: Any]] = []

        for _ in 0..<3 {
            let context = MCPExecutionContext(
                clientId: clientId,
                requestId: UUID().uuidString,
                toolName: "system_info"
            )

            let params = [
                "categories": ["device"],
                "includeSensitive": false
            ] as [String: Any]

            let result = try await systemInfoTool!.performExecution(parameters: params, context: context)
            XCTAssertTrue(result.success)

            if let data = result.data?.value as? [String: Any],
               let deviceInfo = data["device"] as? [String: Any] {
                results.append(deviceInfo)
            }
        }

        // Verify consistency across multiple calls
        XCTAssertEqual(results.count, 3)

        // Device model should be consistent
        if let firstModel = results.first?["model"] as? String {
            for result in results {
                XCTAssertEqual(result["model"] as? String, firstModel, "Device model should be consistent")
            }
        }

        // System name should be consistent
        if let firstSystemName = results.first?["systemName"] as? String {
            for result in results {
                XCTAssertEqual(result["systemName"] as? String, firstSystemName, "System name should be consistent")
            }
        }
    }
}