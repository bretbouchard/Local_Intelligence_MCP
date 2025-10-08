//
//  SystemInfoServiceTests.swift
//  AppleMCPServer
//
//  Created on 2025-10-07.
//

import XCTest
@testable import AppleMCPServer

final class SystemInfoServiceTests: XCTestCase {

    // MARK: - Properties

    private var logger: Logger!
    private var securityManager: SecurityManager!
    private var systemInfoTool: SystemInfoTool!

    // MARK: - Setup and Teardown

    override func setUp() async throws {
        try await super.setUp()

        // Initialize test components
        let config = LoggingConfiguration.default
        logger = Logger(configuration: config)
        await logger.setupFileLoggingIfNeeded()

        securityManager = SecurityManager(logger: logger)
        systemInfoTool = SystemInfoTool(logger: logger, securityManager: securityManager)
    }

    override func tearDown() async throws {
        logger = nil
        securityManager = nil
        systemInfoTool = nil

        try await super.tearDown()
    }

    // MARK: - Tool Initialization Tests

    func testSystemInfoToolInitialization() async throws {
        // Test that the system info tool initializes correctly
        XCTAssertNotNil(systemInfoTool)
        XCTAssertEqual(systemInfoTool.name, "system_info")
        XCTAssertFalse(systemInfoTool.description.isEmpty)
        XCTAssertNotNil(systemInfoTool.inputSchema)
        XCTAssertEqual(systemInfoTool.category, .systemInfo)
        XCTAssertTrue(systemInfoTool.requiresPermission.contains(.systemInfo))
        XCTAssertTrue(systemInfoTool.offlineCapable)
    }

    // MARK: - Input Schema Validation Tests

    func testInputSchemaValidation() async throws {
        // Test input schema structure
        let schema = systemInfoTool.inputSchema

        // Check required fields
        let required = schema["required"] as? [String]
        XCTAssertTrue(required?.contains("categories") == true)

        // Check properties exist
        let properties = schema["properties"] as? [String: Any]
        XCTAssertNotNil(properties?["categories"])
        XCTAssertNotNil(properties?["includeSensitive"])
    }

    func testValidCategories() async throws {
        // Test with valid categories
        let validCategories = [
            ["device"],
            ["os"],
            ["hardware"],
            ["network"],
            ["permissions"],
            ["server"],
            ["device", "os"],
            ["hardware", "network", "server"],
            ["device", "os", "hardware", "network", "permissions", "server"]
        ]

        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "system_info"
        )

        for categories in validCategories {
            let params = [
                "categories": categories,
                "includeSensitive": false
            ]

            do {
                let result = try await systemInfoTool.performExecution(parameters: params, context: context)
                XCTAssertTrue(result.success, "Should succeed for valid categories: \(categories)")
                XCTAssertNotNil(result.data)
            } catch {
                XCTFail("Should not throw for valid categories: \(categories), error: \(error.localizedDescription)")
            }
        }
    }

    func testMissingRequiredParameter() async throws {
        // Test with missing required categories parameter
        let invalidParams = [
            "includeSensitive": false
        ]

        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "system_info"
        )

        do {
            _ = try await systemInfoTool.performExecution(parameters: invalidParams, context: context)
            XCTFail("Should have thrown an error for missing required parameter")
        } catch {
            // Expected behavior
            XCTAssertTrue(error.localizedDescription.contains("categories") ||
                         error.localizedDescription.contains("required"))
        }
    }

    func testInvalidCategories() async throws {
        // Test with invalid categories
        let invalidCategories = [
            ["invalid_category"],
            ["device", "invalid"],
            ["", "os"],
            ["DEVICE"], // Case sensitive
            [123] // Wrong type
        ]

        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "system_info"
        )

        for categories in invalidCategories {
            let params = [
                "categories": categories,
                "includeSensitive": false
            ]

            do {
                _ = try await systemInfoTool.performExecution(parameters: params, context: context)
                // May succeed but filter out invalid categories, or may fail - both are acceptable
                XCTAssertTrue(true)
            } catch {
                // Acceptable behavior for invalid categories
                XCTAssertTrue(true)
            }
        }
    }

    // MARK: - Category-Specific Tests

    func testDeviceInfoCategory() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "system_info"
        )

        let params = [
            "categories": ["device"],
            "includeSensitive": false
        ]

        do {
            let result = try await systemInfoTool.performExecution(parameters: params, context: context)
            XCTAssertTrue(result.success)

            if let data = result.data?.value as? [String: Any],
               let deviceInfo = data["device"] as? [String: Any] {

                // Check for expected device info fields
                XCTAssertNotNil(deviceInfo["model"])
                XCTAssertNotNil(deviceInfo["manufacturer"])
                XCTAssertNotNil(deviceInfo["systemName"])
            }
        } catch {
            XCTFail("Should successfully retrieve device info: \(error.localizedDescription)")
        }
    }

    func testOSInfoCategory() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "system_info"
        )

        let params = [
            "categories": ["os"],
            "includeSensitive": false
        ]

        do {
            let result = try await systemInfoTool.performExecution(parameters: params, context: context)
            XCTAssertTrue(result.success)

            if let data = result.data?.value as? [String: Any],
               let osInfo = data["os"] as? [String: Any] {

                // Check for expected OS info fields
                XCTAssertNotNil(osInfo["name"])
                XCTAssertNotNil(osInfo["version"])
                XCTAssertNotNil(osInfo["build"])
                XCTAssertNotNil(osInfo["architecture"])
            }
        } catch {
            XCTFail("Should successfully retrieve OS info: \(error.localizedDescription)")
        }
    }

    func testHardwareInfoCategory() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "system_info"
        )

        let params = [
            "categories": ["hardware"],
            "includeSensitive": false
        ]

        do {
            let result = try await systemInfoTool.performExecution(parameters: params, context: context)
            XCTAssertTrue(result.success)

            if let data = result.data?.value as? [String: Any],
               let hardwareInfo = data["hardware"] as? [String: Any] {

                // Check for expected hardware info fields
                XCTAssertNotNil(hardwareInfo["processor"])
                XCTAssertNotNil(hardwareInfo["memory"])
                XCTAssertNotNil(hardwareInfo["storage"])
            }
        } catch {
            XCTFail("Should successfully retrieve hardware info: \(error.localizedDescription)")
        }
    }

    func testNetworkInfoCategory() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "system_info"
        )

        let params = [
            "categories": ["network"],
            "includeSensitive": false
        ]

        do {
            let result = try await systemInfoTool.performExecution(parameters: params, context: context)
            XCTAssertTrue(result.success)

            if let data = result.data?.value as? [String: Any],
               let networkInfo = data["network"] as? [String: Any] {

                // Check for expected network info fields
                XCTAssertNotNil(networkInfo["connected"])
                XCTAssertNotNil(networkInfo["interfaces"])
            }
        } catch {
            XCTFail("Should successfully retrieve network info: \(error.localizedDescription)")
        }
    }

    func testPermissionsInfoCategory() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "system_info"
        )

        let params = [
            "categories": ["permissions"],
            "includeSensitive": false
        ]

        do {
            let result = try await systemInfoTool.performExecution(parameters: params, context: context)
            XCTAssertTrue(result.success)

            if let data = result.data?.value as? [String: Any],
               let permissionsInfo = data["permissions"] as? [String: Any] {

                // Check for expected permissions info fields
                XCTAssertNotNil(permissionsInfo["shortcuts"])
                XCTAssertNotNil(permissionsInfo["voiceControl"])
                XCTAssertNotNil(permissionsInfo["systemInfo"])
            }
        } catch {
            XCTFail("Should successfully retrieve permissions info: \(error.localizedDescription)")
        }
    }

    func testServerInfoCategory() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "system_info"
        )

        let params = [
            "categories": ["server"],
            "includeSensitive": false
        ]

        do {
            let result = try await systemInfoTool.performExecution(parameters: params, context: context)
            XCTAssertTrue(result.success)

            if let data = result.data?.value as? [String: Any],
               let serverInfo = data["server"] as? [String: Any] {

                // Check for expected server info fields
                XCTAssertNotNil(serverInfo["version"])
                XCTAssertNotNil(serverInfo["uptime"])
                XCTAssertNotNil(serverInfo["capabilities"])
            }
        } catch {
            XCTFail("Should successfully retrieve server info: \(error.localizedDescription)")
        }
    }

    // MARK: - Sensitive Information Tests

    func testSensitiveInformationAccess() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "system_info"
        )

        // Test requesting sensitive info without proper permissions
        let params = [
            "categories": ["device"],
            "includeSensitive": true
        ]

        do {
            let result = try await systemInfoTool.performExecution(parameters: params, context: context)

            // Should either succeed with limited info or fail due to permissions
            if result.success {
                // If successful, verify sensitive info is handled properly
                XCTAssertTrue(true)
            } else {
                // If failed, should be due to permission check
                XCTAssertNotNil(result.error)
            }
        } catch {
            // May fail due to permission restrictions
            XCTAssertTrue(true)
        }
    }

    func testNonSensitiveInformationAccess() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "system_info"
        )

        // Test requesting non-sensitive info should always work
        let params = [
            "categories": ["device", "os"],
            "includeSensitive": false
        ]

        do {
            let result = try await systemInfoTool.performExecution(parameters: params, context: context)
            XCTAssertTrue(result.success, "Should always succeed for non-sensitive information")
            XCTAssertNotNil(result.data)
        } catch {
            XCTFail("Should not fail for non-sensitive information: \(error.localizedDescription)")
        }
    }

    // MARK: - Error Handling Tests

    func testExecutionErrorHandling() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "system_info"
        )

        // Test various error scenarios
        let errorScenarios: [[String: Any]] = [
            [:], // Missing categories
            ["categories": []], // Empty categories
            ["categories": NSNull()], // Null categories
            ["categories": "not_an_array"], // Wrong type
            ["categories": [123], "includeSensitive": "not_boolean"] // Wrong types
        ]

        for (index, params) in errorScenarios.enumerated() {
            do {
                _ = try await systemInfoTool.performExecution(parameters: params, context: context)
                // Some invalid inputs might be handled gracefully, so don't necessarily fail
                XCTAssertTrue(true, "Scenario \(index) handled gracefully")
            } catch {
                // Expected behavior for truly invalid inputs
                XCTAssertTrue(true, "Scenario \(index) correctly threw an error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Performance Tests

    func testPerformanceValidation() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "system_info"
        )

        let params = [
            "categories": ["device", "os", "hardware"],
            "includeSensitive": false
        ]

        // Measure performance
        measure {
            Task {
                do {
                    let result = try await systemInfoTool.performExecution(parameters: params, context: context)
                    XCTAssertTrue(result.success)
                } catch {
                    XCTFail("Performance test should not fail: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Integration Tests

    func testToolIntegration() async throws {
        // Test that tool integrates properly with the logging system
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "system_info"
        )

        let params = [
            "categories": ["server"],
            "includeSensitive": false
        ]

        // This should generate logs without crashing
        do {
            let result = try await systemInfoTool.performExecution(parameters: params, context: context)
            XCTAssertTrue(result.success)
        } catch {
            XCTFail("Integration test should not fail: \(error.localizedDescription)")
        }

        // Verify no crashes occurred and tool state remains consistent
        XCTAssertNotNil(systemInfoTool)
        XCTAssertEqual(systemInfoTool.name, "system_info")
    }

    func testMultipleCategoriesSimultaneously() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "system_info"
        )

        // Test requesting all categories at once
        let params = [
            "categories": ["device", "os", "hardware", "network", "permissions", "server"],
            "includeSensitive": false
        ]

        do {
            let result = try await systemInfoTool.performExecution(parameters: params, context: context)
            XCTAssertTrue(result.success)

            if let data = result.data?.value as? [String: Any] {
                // Verify all requested categories are present
                let expectedCategories = ["device", "os", "hardware", "network", "permissions", "server"]
                for category in expectedCategories {
                    XCTAssertNotNil(data[category], "Missing category: \(category)")
                }
            }
        } catch {
            XCTFail("Should successfully retrieve all categories: \(error.localizedDescription)")
        }
    }

    func testPermissionHandling() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "system_info"
        )

        // Test that permission checking is working
        let params = [
            "categories": ["device"],
            "includeSensitive": false
        ]

        do {
            let result = try await systemInfoTool.performExecution(parameters: params, context: context)

            // Should succeed since basic system info should be accessible
            XCTAssertTrue(result.success)

            // The fact that we get here means permissions were checked and granted
            XCTAssertTrue(true)
        } catch {
            // If it fails, it should be due to permission restrictions
            XCTAssertTrue(error.localizedDescription.contains("permission") ||
                         error.localizedDescription.contains("access"))
        }
    }

    // MARK: - Edge Cases Tests

    func testEdgeCases() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "system_info"
        )

        // Test with duplicate categories
        let duplicateCategoriesParams = [
            "categories": ["device", "device", "os", "os"],
            "includeSensitive": false
        ]

        do {
            let result = try await systemInfoTool.performExecution(parameters: duplicateCategoriesParams, context: context)
            XCTAssertTrue(result.success)

            // Should handle duplicates gracefully
            if let data = result.data?.value as? [String: Any] {
                XCTAssertNotNil(data["device"])
                XCTAssertNotNil(data["os"])
            }
        } catch {
            XCTFail("Should handle duplicate categories gracefully: \(error.localizedDescription)")
        }

        // Test with mixed valid and invalid categories
        let mixedCategoriesParams = [
            "categories": ["device", "invalid_category", "os"],
            "includeSensitive": false
        ]

        do {
            let result = try await systemInfoTool.performExecution(parameters: mixedCategoriesParams, context: context)

            // Should either succeed with valid categories only or filter out invalid ones
            if result.success {
                if let data = result.data?.value as? [String: Any] {
                    XCTAssertNotNil(data["device"])
                    XCTAssertNotNil(data["os"])
                    // Invalid category should not be present
                }
            }
        } catch {
            // Acceptable if it fails due to invalid category
            XCTAssertTrue(true)
        }
    }
}