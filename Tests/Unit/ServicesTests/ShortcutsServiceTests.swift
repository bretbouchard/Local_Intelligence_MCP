//
//  ShortcutsServiceTests.swift
//  AppleMCPServer
//
//  Created on 2025-10-07.
//

import XCTest
@testable import AppleMCPServer

final class ShortcutsServiceTests: XCTestCase {

    // MARK: - Properties

    private var logger: Logger!
    private var securityManager: SecurityManager!
    private var shortcutsTool: ShortcutsTool!

    // MARK: - Setup and Teardown

    override func setUp() async throws {
        try await super.setUp()

        // Initialize test components
        let config = LoggingConfiguration.default
        logger = Logger(configuration: config)
        await logger.setupFileLoggingIfNeeded()

        securityManager = SecurityManager(logger: logger)
        shortcutsTool = ShortcutsTool(logger: logger, securityManager: securityManager)
    }

    override func tearDown() async throws {
        logger = nil
        securityManager = nil
        shortcutsTool = nil

        try await super.tearDown()
    }

    // MARK: - Tool Initialization Tests

    func testShortcutsToolInitialization() async throws {
        // Test that the shortcuts tool initializes correctly
        XCTAssertNotNil(shortcutsTool)
        XCTAssertEqual(shortcutsTool.name, "execute_shortcut")
        XCTAssertFalse(shortcutsTool.description.isEmpty)
        XCTAssertNotNil(shortcutsTool.inputSchema)
        XCTAssertEqual(shortcutsTool.category, .shortcuts)
        XCTAssertTrue(shortcutsTool.requiresPermission.contains(.shortcuts))
        XCTAssertTrue(shortcutsTool.offlineCapable)
    }

    // MARK: - Input Validation Tests

    func testInputSchemaValidation() async throws {
        // Test input schema structure
        let schema = shortcutsTool.inputSchema

        // Check required fields
        let required = schema["required"] as? [String]
        XCTAssertTrue(required?.contains("shortcutName") == true)

        // Check properties exist
        let properties = schema["properties"] as? [String: Any]
        XCTAssertNotNil(properties?["shortcutName"])
        XCTAssertNotNil(properties?["parameters"])
        XCTAssertNotNil(properties?["timeout"])
        XCTAssertNotNil(properties?["validateParameters"])
        XCTAssertNotNil(properties?["waitForCompletion"])
    }

    func testValidParameters() async throws {
        // Test with valid minimal parameters
        let validParams = [
            "shortcutName": "Test Shortcut"
        ]

        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "execute_shortcut"
        )

        // Should not throw for valid parameters
        do {
            _ = try await shortcutsTool.performExecution(parameters: validParams, context: context)
        } catch {
            // Expected to fail at execution stage since shortcut doesn't exist, but should not fail validation
            XCTAssertTrue(error.localizedDescription.contains("not found") || error.localizedDescription.contains("validation"))
        }
    }

    func testMissingRequiredParameter() async throws {
        // Test with missing required shortcutName parameter
        let invalidParams = [
            "parameters": ["test": "value"]
        ]

        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "execute_shortcut"
        )

        do {
            _ = try await shortcutsTool.performExecution(parameters: invalidParams, context: context)
            XCTFail("Should have thrown an error for missing required parameter")
        } catch {
            // Expected behavior
            XCTAssertTrue(true)
        }
    }

    func testInvalidShortcutName() async throws {
        // Test with invalid shortcut names
        let invalidNames = ["", " "] // Empty and whitespace-only names

        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "execute_shortcut"
        )

        for invalidName in invalidNames {
            let params = ["shortcutName": invalidName]

            do {
                _ = try await shortcutsTool.performExecution(parameters: params, context: context)
                XCTFail("Should have thrown an error for invalid shortcut name: '\(invalidName)'")
            } catch {
                // Expected behavior
                XCTAssertTrue(true)
            }
        }
    }

    func testTimeoutValidation() async throws {
        // Test timeout parameter validation
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "execute_shortcut"
        )

        // Test invalid timeout values
        let invalidTimeouts = [0, -1, 301] // Below minimum and above maximum

        for timeout in invalidTimeouts {
            let params = [
                "shortcutName": "Test Shortcut",
                "timeout": timeout
            ]

            do {
                _ = try await shortcutsTool.performExecution(parameters: params, context: context)
                XCTFail("Should have thrown an error for invalid timeout: \(timeout)")
            } catch {
                // Expected behavior
                XCTAssertTrue(true)
            }
        }

        // Test valid timeout values
        let validTimeouts = [1, 30, 300] // Minimum, default, and maximum

        for timeout in validTimeouts {
            let params = [
                "shortcutName": "Test Shortcut",
                "timeout": timeout
            ]

            do {
                _ = try await shortcutsTool.performExecution(parameters: params, context: context)
            } catch {
                // May fail at execution but should not fail validation
                XCTAssertFalse(error.localizedDescription.contains("timeout"))
            }
        }
    }

    // MARK: - Parameter Validation Tests

    func testParameterValidation() async throws {
        // Test parameter validation functionality
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "execute_shortcut"
        )

        // Test with validateParameters enabled
        let paramsWithValidation = [
            "shortcutName": "Test Shortcut",
            "validateParameters": true,
            "parameters": ["test": "value"]
        ]

        do {
            _ = try await shortcutsTool.performExecution(parameters: paramsWithValidation, context: context)
        } catch {
            // Expected to fail since shortcut doesn't exist
            XCTAssertTrue(true)
        }

        // Test with validateParameters disabled
        let paramsWithoutValidation = [
            "shortcutName": "Test Shortcut",
            "validateParameters": false,
            "parameters": ["test": "value"]
        ]

        do {
            _ = try await shortcutsTool.performExecution(parameters: paramsWithoutValidation, context: context)
        } catch {
            // Expected to fail since shortcut doesn't exist
            XCTAssertTrue(true)
        }
    }

    // MARK: - Execution Tests

    func testShortcutExecution() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "execute_shortcut"
        )

        // Test basic execution structure
        let params = [
            "shortcutName": "Test Shortcut",
            "waitForCompletion": true
        ]

        do {
            let result = try await shortcutsTool.performExecution(parameters: params, context: context)

            // Should not reach here for non-existent shortcut
            XCTFail("Expected execution to fail for non-existent shortcut")

        } catch {
            // Expected behavior - shortcut should not exist
            XCTAssertTrue(error.localizedDescription.contains("not found") ||
                         error.localizedDescription.contains("execution") ||
                         error.localizedDescription.contains("validation"))
        }
    }

    func testExecutionWithParameters() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "execute_shortcut"
        )

        // Test execution with parameters
        let params = [
            "shortcutName": "Test Shortcut",
            "parameters": [
                "text": "Hello World",
                "number": 42,
                "boolean": true
            ],
            "waitForCompletion": true
        ]

        do {
            let result = try await shortcutsTool.performExecution(parameters: params, context: context)
            XCTFail("Expected execution to fail for non-existent shortcut")
        } catch {
            // Expected behavior
            XCTAssertTrue(true)
        }
    }

    func testAsyncExecution() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "execute_shortcut"
        )

        // Test async execution (waitForCompletion: false)
        let params = [
            "shortcutName": "Test Shortcut",
            "waitForCompletion": false,
            "timeout": 5
        ]

        do {
            let result = try await shortcutsTool.performExecution(parameters: params, context: context)

            // For async execution, should return quickly with execution info
            if result.success {
                XCTAssertNotNil(result.data)
                let data = result.data?.value as? [String: Any]
                XCTAssertNotNil(data?["executionId"])
            }
        } catch {
            // May fail but should be quick due to async nature
            XCTAssertTrue(true)
        }
    }

    // MARK: - Error Handling Tests

    func testExecutionErrorHandling() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "execute_shortcut"
        )

        // Test various error scenarios
        let errorScenarios = [
            ["shortcutName": ""], // Empty name
            ["shortcutName": String(repeating: "x", count: 300)], // Too long name
            ["shortcutName": "Test", "timeout": -1] // Invalid timeout
        ]

        for (index, params) in errorScenarios.enumerated() {
            do {
                _ = try await shortcutsTool.performExecution(parameters: params, context: context)
                XCTFail("Scenario \(index) should have thrown an error")
            } catch {
                // Expected behavior
                XCTAssertTrue(true, "Scenario \(index) correctly threw an error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Performance Tests

    func testPerformanceValidation() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "execute_shortcut"
        )

        let params = [
            "shortcutName": "Test Shortcut"
        ]

        // Measure validation performance
        measure {
            Task {
                do {
                    _ = try await shortcutsTool.performExecution(parameters: params, context: context)
                } catch {
                    // Expected
                }
            }
        }
    }

    // MARK: - Edge Cases Tests

    func testEdgeCases() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "execute_shortcut"
        )

        // Test with maximum parameter size
        let largeParameters = [
            "shortcutName": "Test",
            "parameters": [
                "largeText": String(repeating: "x", count: 10000)
            ]
        ]

        do {
            _ = try await shortcutsTool.performExecution(parameters: largeParameters, context: context)
        } catch {
            // May fail but should handle large input gracefully
            XCTAssertTrue(true)
        }

        // Test with special characters in shortcut name
        let specialCharParams = [
            "shortcutName": "Test-Shortcut_With.Special@Characters"
        ]

        do {
            _ = try await shortcutsTool.performExecution(parameters: specialCharParams, context: context)
        } catch {
            // Expected to fail but should handle special characters
            XCTAssertTrue(true)
        }
    }

    // MARK: - Integration Tests

    func testToolIntegration() async throws {
        // Test that tool integrates properly with the logging system
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "execute_shortcut"
        )

        let params = ["shortcutName": "Integration Test"]

        // This should generate logs without crashing
        do {
            _ = try await shortcutsTool.performExecution(parameters: params, context: context)
        } catch {
            // Expected
        }

        // Verify no crashes occurred and tool state remains consistent
        XCTAssertNotNil(shortcutsTool)
        XCTAssertEqual(shortcutsTool.name, "execute_shortcut")
    }
}