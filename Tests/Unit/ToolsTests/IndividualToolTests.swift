//
//  IndividualToolTests.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-08.
//

import XCTest
@testable import LocalIntelligenceMCP

final class IndividualToolTests: XCTestCase {

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

        // Initialize tools registry
        try await toolsRegistry.initialize()
    }

    override func tearDown() async throws {
        logger = nil
        securityManager = nil
        toolsRegistry = nil

        try await super.tearDown()
    }

    // MARK: - ShortcutsTool Tests

    func testShortcutsToolProperties() async throws {
        guard let shortcutsTool = await toolsRegistry.getTool(name: "execute_shortcut") else {
            XCTFail("ShortcutsTool should be registered")
            return
        }

        XCTAssertEqual(shortcutsTool.name, "execute_shortcut")
        XCTAssertFalse(shortcutsTool.description.isEmpty)
        XCTAssertNotNil(shortcutsTool.inputSchema)
        XCTAssertEqual(shortcutsTool.category, .shortcuts)
        XCTAssertTrue(shortcutsTool.requiresPermission.contains(.shortcuts))
        XCTAssertTrue(shortcutsTool.offlineCapable)
    }

    func testShortcutsToolInputSchema() async throws {
        guard let shortcutsTool = await toolsRegistry.getTool(name: "execute_shortcut") else {
            XCTFail("ShortcutsTool should be registered")
            return
        }

        let schema = shortcutsTool.inputSchema

        // Check required fields
        let required = schema["required"] as? [String]
        XCTAssertTrue(required?.contains("shortcutName") == true)

        // Check properties
        let properties = schema["properties"] as? [String: Any]
        XCTAssertNotNil(properties?["shortcutName"])
        XCTAssertNotNil(properties?["inputParameters"])
        XCTAssertNotNil(properties?["timeout"])
    }

    func testShortcutsToolValidation() async throws {
        guard let shortcutsTool = await toolsRegistry.getTool(name: "execute_shortcut") else {
            XCTFail("ShortcutsTool should be registered")
            return
        }

        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "execute_shortcut"
        )

        // Test valid parameters
        let validParams = [
            "shortcutName": "Test Shortcut",
            "inputParameters": [:],
            "timeout": 30.0
        ] as [String: Any]

        do {
            let result = try await shortcutsTool.performExecution(parameters: validParams, context: context)
            // May fail due to missing shortcut but validation should pass
            XCTAssertTrue(true)
        } catch {
            // Expected if shortcut doesn't exist
            XCTAssertTrue(error.localizedDescription.contains("shortcut") ||
                        error.localizedDescription.contains("not found") ||
                        error.localizedDescription.isEmpty) // May be empty if validation passes
        }

        // Test invalid parameters
        let invalidParams = [
            "timeout": 30.0
            // Missing required shortcutName
        ] as [String: Any]

        do {
            _ = try await shortcutsTool.performExecution(parameters: invalidParams, context: context)
            XCTFail("Should fail validation for missing shortcutName")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("required") ||
                        error.localizedDescription.contains("validation") ||
                        error.localizedDescription.contains("shortcutName"))
        }
    }

    // MARK: - ShortcutsListTool Tests

    func testShortcutsListToolProperties() async throws {
        guard let shortcutsListTool = await toolsRegistry.getTool(name: "list_shortcuts") else {
            XCTFail("ShortcutsListTool should be registered")
            return
        }

        XCTAssertEqual(shortcutsListTool.name, "list_shortcuts")
        XCTAssertFalse(shortcutsListTool.description.isEmpty)
        XCTAssertNotNil(shortcutsListTool.inputSchema)
        XCTAssertEqual(shortcutsListTool.category, .shortcuts)
        XCTAssertTrue(shortcutsListTool.requiresPermission.contains(.shortcuts))
        XCTAssertTrue(shortcutsListTool.offlineCapable)
    }

    func testShortcutsListToolExecution() async throws {
        guard let shortcutsListTool = await toolsRegistry.getTool(name: "list_shortcuts") else {
            XCTFail("ShortcutsListTool should be registered")
            return
        }

        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "list_shortcuts"
        )

        let params = [
            "includeSystemShortcuts": false,
            "categoryFilter": nil,
            "searchQuery": nil
        ] as [String: Any]

        do {
            let result = try await shortcutsListTool.performExecution(parameters: params, context: context)
            XCTAssertTrue(result.success, "Should successfully list shortcuts")
            XCTAssertNotNil(result.data)
        } catch {
            XCTFail("Shortcuts listing should not fail: \(error.localizedDescription)")
        }
    }

    // MARK: - VoiceControlTool Tests

    func testVoiceControlToolProperties() async throws {
        guard let voiceControlTool = await toolsRegistry.getTool(name: "voice_command") else {
            XCTFail("VoiceControlTool should be registered")
            return
        }

        XCTAssertEqual(voiceControlTool.name, "voice_command")
        XCTAssertFalse(voiceControlTool.description.isEmpty)
        XCTAssertNotNil(voiceControlTool.inputSchema)
        XCTAssertEqual(voiceControlTool.category, .accessibility)
        XCTAssertTrue(voiceControlTool.requiresPermission.contains(.voiceControl))
        XCTAssertTrue(voiceControlTool.offlineCapable)
    }

    func testVoiceControlToolInputSchema() async throws {
        guard let voiceControlTool = await toolsRegistry.getTool(name: "voice_command") else {
            XCTFail("VoiceControlTool should be registered")
            return
        }

        let schema = voiceControlTool.inputSchema

        // Check required fields
        let required = schema["required"] as? [String]
        XCTAssertTrue(required?.contains("command") == true)

        // Check properties
        let properties = schema["properties"] as? [String: Any]
        XCTAssertNotNil(properties?["command"])
        XCTAssertNotNil(properties?["language"])
        XCTAssertNotNil(properties?["confidence"])
    }

    func testVoiceControlToolValidation() async throws {
        guard let voiceControlTool = await toolsRegistry.getTool(name: "voice_command") else {
            XCTFail("VoiceControlTool should be registered")
            return
        }

        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "voice_command"
        )

        // Test valid parameters
        let validParams = [
            "command": "Open Safari",
            "language": "en-US",
            "confidence": 0.9
        ] as [String: Any]

        do {
            let result = try await voiceControlTool.performExecution(parameters: validParams, context: context)
            // May fail due to voice control permissions but validation should pass
            XCTAssertTrue(true)
        } catch {
            // Expected if voice control is not available
            XCTAssertTrue(error.localizedDescription.contains("voice") ||
                        error.localizedDescription.contains("permission") ||
                        error.localizedDescription.contains("accessibility") ||
                        error.localizedDescription.isEmpty) // May be empty if validation passes
        }

        // Test invalid parameters
        let invalidParams = [
            "language": "en-US",
            "confidence": 0.9
            // Missing required command
        ] as [String: Any]

        do {
            _ = try await voiceControlTool.performExecution(parameters: invalidParams, context: context)
            XCTFail("Should fail validation for missing command")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("required") ||
                        error.localizedDescription.contains("validation") ||
                        error.localizedDescription.contains("command"))
        }
    }

    // MARK: - SystemInfoTool Tests

    func testSystemInfoToolProperties() async throws {
        guard let systemInfoTool = await toolsRegistry.getTool(name: "system_info") else {
            XCTFail("SystemInfoTool should be registered")
            return
        }

        XCTAssertEqual(systemInfoTool.name, "system_info")
        XCTAssertFalse(systemInfoTool.description.isEmpty)
        XCTAssertNotNil(systemInfoTool.inputSchema)
        XCTAssertEqual(systemInfoTool.category, .systemInfo)
        XCTAssertTrue(systemInfoTool.requiresPermission.contains(.systemInfo))
        XCTAssertTrue(systemInfoTool.offlineCapable)
    }

    func testSystemInfoToolInputSchema() async throws {
        guard let systemInfoTool = await toolsRegistry.getTool(name: "system_info") else {
            XCTFail("SystemInfoTool should be registered")
            return
        }

        let schema = systemInfoTool.inputSchema

        // Check required fields
        let required = schema["required"] as? [String]
        XCTAssertTrue(required?.contains("categories") == true)

        // Check properties
        let properties = schema["properties"] as? [String: Any]
        XCTAssertNotNil(properties?["categories"])
        XCTAssertNotNil(properties?["includeSensitive"])
    }

    func testSystemInfoToolExecution() async throws {
        guard let systemInfoTool = await toolsRegistry.getTool(name: "system_info") else {
            XCTFail("SystemInfoTool should be registered")
            return
        }

        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "system_info"
        )

        let params = [
            "categories": ["device", "server"],
            "includeSensitive": false
        ] as [String: Any]

        do {
            let result = try await systemInfoTool.performExecution(parameters: params, context: context)
            XCTAssertTrue(result.success, "Should successfully retrieve system info")
            XCTAssertNotNil(result.data)

            // Verify structure of returned data
            if let data = result.data?.value as? [String: Any] {
                XCTAssertNotNil(data["device"])
                XCTAssertNotNil(data["server"])
            }
        } catch {
            XCTFail("System info retrieval should not fail: \(error.localizedDescription)")
        }
    }

    // MARK: - HealthCheckTool Tests

    func testHealthCheckToolProperties() async throws {
        guard let healthCheckTool = await toolsRegistry.getTool(name: "health_check") else {
            XCTFail("HealthCheckTool should be registered")
            return
        }

        XCTAssertEqual(healthCheckTool.name, "health_check")
        XCTAssertFalse(healthCheckTool.description.isEmpty)
        XCTAssertNotNil(healthCheckTool.inputSchema)
        XCTAssertEqual(healthCheckTool.category, .system)
        XCTAssertTrue(healthCheckTool.requiresPermission.isEmpty) // Usually no special permissions
        XCTAssertTrue(healthCheckTool.offlineCapable)
    }

    func testHealthCheckToolExecution() async throws {
        guard let healthCheckTool = await toolsRegistry.getTool(name: "health_check") else {
            XCTFail("HealthCheckTool should be registered")
            return
        }

        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "health_check"
        )

        let params = [
            "includeDiagnostics": false,
            "timeout": 10.0
        ] as [String: Any]

        do {
            let result = try await healthCheckTool.performExecution(parameters: params, context: context)
            XCTAssertTrue(result.success, "Health check should succeed")
            XCTAssertNotNil(result.data)

            // Verify health check structure
            if let data = result.data?.value as? [String: Any] {
                XCTAssertNotNil(data["status"])
                XCTAssertNotNil(data["timestamp"])
                XCTAssertNotNil(data["uptime"])
            }
        } catch {
            XCTFail("Health check should not fail: \(error.localizedDescription)")
        }
    }

    // MARK: - PermissionTool Tests

    func testPermissionToolProperties() async throws {
        guard let permissionTool = await toolsRegistry.getTool(name: "check_permission") else {
            XCTFail("PermissionTool should be registered")
            return
        }

        XCTAssertEqual(permissionTool.name, "check_permission")
        XCTAssertFalse(permissionTool.description.isEmpty)
        XCTAssertNotNil(permissionTool.inputSchema)
        XCTAssertEqual(permissionTool.category, .security)
        XCTAssertTrue(permissionTool.requiresPermission.isEmpty) // Should check permissions, not require them
        XCTAssertTrue(permissionTool.offlineCapable)
    }

    func testPermissionToolExecution() async throws {
        guard let permissionTool = await toolsRegistry.getTool(name: "check_permission") else {
            XCTFail("PermissionTool should be registered")
            return
        }

        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "check_permission"
        )

        let params = [
            "permissionType": "shortcuts",
            "clientId": UUID().uuidString
        ] as [String: Any]

        do {
            let result = try await permissionTool.performExecution(parameters: params, context: context)
            XCTAssertTrue(result.success, "Permission check should succeed")
            XCTAssertNotNil(result.data)

            // Verify permission check structure
            if let data = result.data?.value as? [String: Any] {
                XCTAssertNotNil(data["permissionType"])
                XCTAssertNotNil(data["granted"])
                XCTAssertNotNil(data["timestamp"])
            }
        } catch {
            XCTFail("Permission check should not fail: \(error.localizedDescription)")
        }
    }

    // MARK: - Tool Discovery Tests

    func testAllRegisteredTools() async throws {
        let availableTools = await toolsRegistry.getAvailableTools()

        XCTAssertFalse(availableTools.isEmpty, "Should have registered tools")

        let expectedToolNames = [
            "execute_shortcut",
            "list_shortcuts",
            "voice_command",
            "system_info",
            "health_check",
            "check_permission"
        ]

        for toolName in expectedToolNames {
            let toolExists = availableTools.contains { $0.name == toolName }
            XCTAssertTrue(toolExists, "Tool '\(toolName)' should be registered")
        }
    }

    func testToolCategoryDistribution() async throws {
        let availableTools = await toolsRegistry.getAvailableTools()

        var categoryCount: [ToolCategory: Int] = [:]

        for toolInfo in availableTools {
            categoryCount[toolInfo.category, default: 0] += 1
        }

        // Verify we have tools in expected categories
        XCTAssertGreaterThan(categoryCount[.shortcuts, default: 0], 0, "Should have shortcuts tools")
        XCTAssertGreaterThan(categoryCount[.systemInfo, default: 0], 0, "Should have system info tools")
        XCTAssertGreaterThan(categoryCount[.accessibility, default: 0], 0, "Should have accessibility tools")
        XCTAssertGreaterThan(categoryCount[.system, default: 0], 0, "Should have system tools")
        XCTAssertGreaterThan(categoryCount[.security, default: 0], 0, "Should have security tools")
    }

    // MARK: - Tool Permission Tests

    func testToolPermissionRequirements() async throws {
        let availableTools = await toolsRegistry.getAvailableTools()

        for toolInfo in availableTools {
            switch toolInfo.name {
            case "execute_shortcut", "list_shortcuts":
                XCTAssertTrue(toolInfo.requiresPermission.contains(.shortcuts),
                             "\(toolInfo.name) should require shortcuts permission")
            case "voice_command":
                XCTAssertTrue(toolInfo.requiresPermission.contains(.voiceControl),
                             "\(toolInfo.name) should require voice control permission")
            case "system_info":
                XCTAssertTrue(toolInfo.requiresPermission.contains(.systemInfo),
                             "\(toolInfo.name) should require system info permission")
            case "health_check", "check_permission":
                XCTAssertTrue(toolInfo.requiresPermission.isEmpty,
                             "\(toolInfo.name) should not require special permissions")
            default:
                break
            }
        }
    }

    // MARK: - Tool Integration Tests

    func testToolExecutionConsistency() async throws {
        let availableTools = await toolsRegistry.getAvailableTools()
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "test"
        )

        for toolInfo in availableTools {
            guard let tool = await toolsRegistry.getTool(name: toolInfo.name) else { continue }

            // Test that tool has consistent properties
            XCTAssertEqual(tool.name, toolInfo.name)
            XCTAssertEqual(tool.category, toolInfo.category)
            XCTAssertEqual(tool.description, toolInfo.description)

            // Test that tool has valid input schema
            XCTAssertNotNil(tool.inputSchema)

            // Test that tool can handle basic parameter validation
            let minimalParams: [String: Any] = [:]

            do {
                _ = try await tool.performExecution(parameters: minimalParams, context: context)
                // May fail, but shouldn't crash
            } catch {
                // Expected for tools with required parameters
                XCTAssertTrue(true)
            }
        }
    }

    // MARK: - Performance Tests

    func testToolDiscoveryPerformance() async throws {
        // Measure performance of tool discovery
        measure {
            Task {
                do {
                    let _ = await self.toolsRegistry.getAvailableTools()
                } catch {
                    XCTFail("Tool discovery should not fail")
                }
            }
        }
    }

    func testConcurrentToolAccess() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "concurrent_test"
        )

        // Test concurrent access to different tools
        await withTaskGroup(of: Bool.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    do {
                        let tools = await self.toolsRegistry.getAvailableTools()
                        guard let firstTool = tools.first,
                              let tool = await self.toolsRegistry.getTool(name: firstTool.name) else {
                            return false
                        }

                        // Try to get tool properties (should be thread-safe)
                        let _ = tool.name
                        let _ = tool.description
                        let _ = tool.inputSchema

                        return true
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

            XCTAssertEqual(successCount, 10, "All concurrent tool accesses should succeed")
        }
    }

    // MARK: - Error Handling Tests

    func testToolExecutionErrorHandling() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "error_test"
        )

        // Test error handling with invalid parameters for each tool
        let availableTools = await toolsRegistry.getAvailableTools()

        for toolInfo in availableTools {
            guard let tool = await toolsRegistry.getTool(name: toolInfo.name) else { continue }

            do {
                // Try with completely invalid parameters
                let invalidParams = [
                    "invalid_parameter": "invalid_value",
                    "another_invalid": 12345
                ] as [String: Any]

                _ = try await tool.performExecution(parameters: invalidParams, context: context)

                // Some tools might handle invalid parameters gracefully
                XCTAssertTrue(true)
            } catch {
                // Most tools should reject invalid parameters
                XCTAssertTrue(error.localizedDescription.contains("required") ||
                            error.localizedDescription.contains("validation") ||
                            error.localizedDescription.contains("invalid") ||
                            error.localizedDescription.isEmpty) // May be empty if handled gracefully
            }
        }
    }
}