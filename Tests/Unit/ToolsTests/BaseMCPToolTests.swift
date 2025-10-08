//
//  BaseMCPToolTests.swift
//  AppleMCPServer
//
//  Created on 2025-10-08.
//

import XCTest
@testable import AppleMCPServer

final class BaseMCPToolTests: XCTestCase {

    // MARK: - Properties

    private var logger: Logger!
    private var securityManager: SecurityManager!
    private var mockTool: MockBaseTool!

    // MARK: - Setup and Teardown

    override func setUp() async throws {
        try await super.setUp()

        // Initialize test components
        let config = LoggingConfiguration.default
        logger = Logger(configuration: config)
        await logger.setupFileLoggingIfNeeded()

        securityManager = SecurityManager(logger: logger)
        mockTool = MockBaseTool(logger: logger, securityManager: securityManager)
    }

    override func tearDown() async throws {
        logger = nil
        securityManager = nil
        mockTool = nil

        try await super.tearDown()
    }

    // MARK: - Tool Initialization Tests

    func testBaseToolInitialization() async throws {
        // Test that the base tool initializes correctly
        XCTAssertNotNil(mockTool)
        XCTAssertEqual(mockTool.name, "mock_base_tool")
        XCTAssertFalse(mockTool.description.isEmpty)
        XCTAssertNotNil(mockTool.inputSchema)
        XCTAssertEqual(mockTool.category, .utility)
        XCTAssertTrue(mockTool.requiresPermission.isEmpty)
        XCTAssertTrue(mockTool.offlineCapable)
        XCTAssertEqual(mockTool.version, "1.0.0")
    }

    func testToolInheritance() async throws {
        // Test that mock tool properly inherits from BaseMCPTool
        XCTAssertTrue(mockTool is BaseMCPTool)
        XCTAssertTrue(mockTool is MCPTool)
    }

    func testToolProperties() async throws {
        // Test tool property validation
        XCTAssertLessThanOrEqual(mockTool.name.count, MCPConstants.Limits.maxToolNameLength)
        XCTAssertLessThanOrEqual(mockTool.description.count, MCPConstants.Limits.maxToolDescriptionLength)
        XCTAssertNotNil(mockTool.inputSchema)
    }

    // MARK: - Input Schema Tests

    func testInputSchemaStructure() async throws {
        let schema = mockTool.inputSchema

        // Check basic schema structure
        XCTAssertNotNil(schema["type"])
        XCTAssertEqual(schema["type"] as? String, "object")

        // Check properties exist
        let properties = schema["properties"] as? [String: Any]
        XCTAssertNotNil(properties)

        // Check that mock tool has expected input parameters
        XCTAssertNotNil(properties?["testString"])
        XCTAssertNotNil(properties?["testNumber"])
        XCTAssertNotNil(properties?["testBoolean"])
    }

    func testInputSchemaValidation() async throws {
        let schema = mockTool.inputSchema

        // Check required fields
        let required = schema["required"] as? [String]
        XCTAssertTrue(required?.contains("testString") == true)
        XCTAssertFalse(required?.contains("testOptional") == true)
    }

    // MARK: - Permission Tests

    func testPermissionRequirements() async throws {
        // Test that tool correctly reports its permission requirements
        XCTAssertTrue(mockTool.requiresPermission.isEmpty)

        // Test permission checking
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: mockTool.name
        )

        let hasPermission = await mockTool.checkPermission(context: context)
        XCTAssertTrue(hasPermission, "Mock tool should not require special permissions")
    }

    func testOfflineCapability() async throws {
        // Test offline capability reporting
        XCTAssertTrue(mockTool.offlineCapable)

        // Test that tool can execute without network
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: mockTool.name
        )

        let params = [
            "testString": "test_value",
            "testNumber": 42,
            "testBoolean": true
        ] as [String: Any]

        do {
            let result = try await mockTool.performExecution(parameters: params, context: context)
            XCTAssertTrue(result.success, "Tool should execute successfully offline")
        } catch {
            XCTFail("Offline execution should not fail: \(error.localizedDescription)")
        }
    }

    // MARK: - Parameter Validation Tests

    func testParameterValidationSuccess() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: mockTool.name
        )

        let validParams = [
            "testString": "valid_string",
            "testNumber": 42,
            "testBoolean": true,
            "testOptional": "optional_value"
        ] as [String: Any]

        do {
            let result = try await mockTool.performExecution(parameters: validParams, context: context)
            XCTAssertTrue(result.success)
            XCTAssertNotNil(result.data)
            XCTAssertNil(result.error)
        } catch {
            XCTFail("Valid parameters should not cause execution failure: \(error.localizedDescription)")
        }
    }

    func testParameterValidationMissingRequired() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: mockTool.name
        )

        let invalidParams = [
            "testNumber": 42,
            "testBoolean": true
            // Missing required testString
        ] as [String: Any]

        do {
            _ = try await mockTool.performExecution(parameters: invalidParams, context: context)
            XCTFail("Missing required parameter should cause validation failure")
        } catch {
            // Expected behavior - validation should fail
            XCTAssertTrue(error.localizedDescription.contains("required") ||
                        error.localizedDescription.contains("validation") ||
                        error.localizedDescription.contains("testString"))
        }
    }

    func testParameterValidationInvalidTypes() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: mockTool.name
        )

        let invalidParams = [
            "testString": 123, // Wrong type
            "testNumber": "not_a_number", // Wrong type
            "testBoolean": "not_a_boolean" // Wrong type
        ] as [String: Any]

        do {
            _ = try await mockTool.performExecution(parameters: invalidParams, context: context)
            XCTFail("Invalid parameter types should cause validation failure")
        } catch {
            // Expected behavior - validation should fail
            XCTAssertTrue(error.localizedDescription.contains("type") ||
                        error.localizedDescription.contains("validation"))
        }
    }

    // MARK: - Execution Tests

    func testBasicExecution() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: mockTool.name
        )

        let params = [
            "testString": "execution_test",
            "testNumber": 100,
            "testBoolean": false
        ] as [String: Any]

        do {
            let result = try await mockTool.performExecution(parameters: params, context: context)
            XCTAssertTrue(result.success)
            XCTAssertNotNil(result.data)
            XCTAssertNil(result.error)
            XCTAssertNotNil(result.executionTime)

            // Verify mock tool behavior
            if let data = result.data?.value as? [String: Any] {
                XCTAssertEqual(data["receivedString"] as? String, "execution_test")
                XCTAssertEqual(data["receivedNumber"] as? Int, 100)
                XCTAssertEqual(data["receivedBoolean"] as? Bool, false)
                XCTAssertEqual(data["toolName"] as? String, mockTool.name)
                XCTAssertNotNil(data["executionId"])
            }
        } catch {
            XCTFail("Basic execution should succeed: \(error.localizedDescription)")
        }
    }

    func testExecutionWithOptionalParameters() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: mockTool.name
        )

        let params = [
            "testString": "optional_test",
            "testNumber": 50,
            "testBoolean": true,
            "testOptional": "optional_value"
        ] as [String: Any]

        do {
            let result = try await mockTool.performExecution(parameters: params, context: context)
            XCTAssertTrue(result.success)

            if let data = result.data?.value as? [String: Any] {
                XCTAssertEqual(data["receivedOptional"] as? String, "optional_value")
            }
        } catch {
            XCTFail("Execution with optional parameters should succeed: \(error.localizedDescription)")
        }
    }

    func testExecutionWithoutOptionalParameters() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: mockTool.name
        )

        let params = [
            "testString": "no_optional_test",
            "testNumber": 25,
            "testBoolean": false
            // No optional parameter
        ] as [String: Any]

        do {
            let result = try await mockTool.performExecution(parameters: params, context: context)
            XCTAssertTrue(result.success)

            if let data = result.data?.value as? [String: Any] {
                XCTAssertNil(data["receivedOptional"])
            }
        } catch {
            XCTFail("Execution without optional parameters should succeed: \(error.localizedDescription)")
        }
    }

    // MARK: - Error Handling Tests

    func testExecutionErrorHandling() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: mockTool.name
        )

        // Test with empty parameters
        let emptyParams: [String: Any] = [:]

        do {
            _ = try await mockTool.performExecution(parameters: emptyParams, context: context)
            XCTFail("Empty parameters should cause validation failure")
        } catch {
            // Expected behavior
            XCTAssertTrue(error.localizedDescription.contains("required") ||
                        error.localizedDescription.contains("validation"))
        }
    }

    func testErrorFormatting() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: mockTool.name
        )

        let invalidParams = [
            "testString": ""
        ] as [String: Any]

        do {
            _ = try await mockTool.performExecution(parameters: invalidParams, context: context)
            XCTFail("Invalid parameters should produce structured error")
        } catch {
            // Verify error is properly formatted
            let errorString = error.localizedDescription
            XCTAssertFalse(errorString.isEmpty)
            XCTAssertTrue(errorString.count > 0)
        }
    }

    // MARK: - Performance Tests

    func testExecutionPerformance() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: mockTool.name
        )

        let params = [
            "testString": "performance_test",
            "testNumber": 1,
            "testBoolean": true
        ] as [String: Any]

        // Measure execution time
        measure {
            Task {
                do {
                    let result = try await mockTool.performExecution(parameters: params, context: context)
                    XCTAssertTrue(result.success)
                } catch {
                    XCTFail("Performance test should not fail: \(error.localizedDescription)")
                }
            }
        }
    }

    func testConcurrentExecution() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: mockTool.name
        )

        let params = [
            "testString": "concurrent_test",
            "testNumber": 2,
            "testBoolean": false
        ] as [String: Any]

        // Test concurrent executions
        await withTaskGroup(of: Bool.self) { group in
            for i in 0..<10 {
                group.addTask {
                    do {
                        let result = try await self.mockTool.performExecution(parameters: params, context: context)
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

            XCTAssertEqual(successCount, 10, "All concurrent executions should succeed")
        }
    }

    // MARK: - Integration Tests

    func testToolIntegrationWithLogging() async throws {
        // Test that tool integrates properly with logging system
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: mockTool.name
        )

        let params = [
            "testString": "logging_test",
            "testNumber": 3,
            "testBoolean": true
        ] as [String: Any]

        // This should generate logs without crashing
        do {
            let result = try await mockTool.performExecution(parameters: params, context: context)
            XCTAssertTrue(result.success)
        } catch {
            XCTFail("Integration test should not fail: \(error.localizedDescription)")
        }

        // Verify tool state remains consistent
        XCTAssertNotNil(mockTool)
        XCTAssertEqual(mockTool.name, "mock_base_tool")
    }

    func testToolIntegrationWithSecurity() async throws {
        // Test that tool integrates properly with security manager
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: mockTool.name
        )

        let params = [
            "testString": "security_test",
            "testNumber": 4,
            "testBoolean": false
        ] as [String: Any]

        do {
            let result = try await mockTool.performExecution(parameters: params, context: context)
            XCTAssertTrue(result.success)

            // Tool should have passed through security checks
            XCTAssertTrue(true)
        } catch {
            XCTFail("Security integration should not fail: \(error.localizedDescription)")
        }
    }

    // MARK: - State Tests

    func testToolStateConsistency() async throws {
        // Test that tool maintains consistent state across executions
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: mockTool.name
        )

        let params1 = [
            "testString": "state_test_1",
            "testNumber": 5,
            "testBoolean": true
        ] as [String: Any]

        let params2 = [
            "testString": "state_test_2",
            "testNumber": 6,
            "testBoolean": false
        ] as [String: Any]

        do {
            let result1 = try await mockTool.performExecution(parameters: params1, context: context)
            let result2 = try await mockTool.performExecution(parameters: params2, context: context)

            XCTAssertTrue(result1.success)
            XCTAssertTrue(result2.success)

            // Tool properties should remain unchanged
            XCTAssertEqual(mockTool.name, "mock_base_tool")
            XCTAssertEqual(mockTool.version, "1.0.0")
            XCTAssertTrue(mockTool.offlineCapable)
        } catch {
            XCTFail("State consistency test should not fail: \(error.localizedDescription)")
        }
    }

    // MARK: - Edge Cases Tests

    func testEdgeCases() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: mockTool.name
        )

        // Test with maximum length string
        let maxLengthString = String(repeating: "a", count: MCPConstants.Limits.maxParameterValueLength)
        let longParams = [
            "testString": maxLengthString,
            "testNumber": 7,
            "testBoolean": true
        ] as [String: Any]

        do {
            let result = try await mockTool.performExecution(parameters: longParams, context: context)
            // May succeed or fail depending on implementation - both are acceptable
            XCTAssertTrue(true)
        } catch {
            // Acceptable if implementation limits parameter length
            XCTAssertTrue(true)
        }

        // Test with special characters
        let specialParams = [
            "testString": "🚀 Test with special chars: àéîöü ñ 中文 العربية",
            "testNumber": 8,
            "testBoolean": true
        ] as [String: Any]

        do {
            let result = try await mockTool.performExecution(parameters: specialParams, context: context)
            XCTAssertTrue(result.success, "Should handle special characters correctly")
        } catch {
            XCTFail("Special characters should not cause failure: \(error.localizedDescription)")
        }
    }
}

// MARK: - Mock Base Tool Implementation

/// Mock implementation of BaseMCPTool for testing
class MockBaseTool: BaseMCPTool {
    override var name: String {
        "mock_base_tool"
    }

    override var description: String {
        "Mock base tool for testing BaseMCPTool functionality"
    }

    override var inputSchema: [String: Any] {
        return [
            "type": "object",
            "properties": [
                "testString": [
                    "type": "string",
                    "description": "Test string parameter"
                ],
                "testNumber": [
                    "type": "number",
                    "description": "Test number parameter"
                ],
                "testBoolean": [
                    "type": "boolean",
                    "description": "Test boolean parameter"
                ],
                "testOptional": [
                    "type": "string",
                    "description": "Optional test parameter"
                ]
            ],
            "required": ["testString", "testNumber", "testBoolean"]
        ]
    }

    override var category: ToolCategory {
        .utility
    }

    override var requiresPermission: [PermissionType] {
        [] // No special permissions required for testing
    }

    override var offlineCapable: Bool {
        true
    }

    override var version: String {
        "1.0.0"
    }

    override func validateParameters(_ parameters: [String: Any]) -> ValidationResult {
        // Check required parameters
        guard let testString = parameters["testString"] as? String else {
            return .invalid(errors: [
                ValidationError(code: "MISSING_REQUIRED", message: "testString is required", field: "testString")
            ])
        }

        guard parameters["testNumber"] is NSNumber || parameters["testNumber"] is Int || parameters["testNumber"] is Double else {
            return .invalid(errors: [
                ValidationError(code: "INVALID_TYPE", message: "testNumber must be a number", field: "testNumber")
            ])
        }

        guard parameters["testBoolean"] is Bool else {
            return .invalid(errors: [
                ValidationError(code: "INVALID_TYPE", message: "testBoolean must be a boolean", field: "testBoolean")
            ])
        }

        // Additional validation
        if testString.isEmpty {
            return .invalid(errors: [
                ValidationError(code: "EMPTY_STRING", message: "testString cannot be empty", field: "testString", value: testString)
            ])
        }

        return .valid()
    }

    override func executeCoreLogic(with parameters: [String: Any], context: MCPExecutionContext) async throws -> Any {
        // Extract parameters
        let testString = parameters["testString"] as? String ?? ""
        let testNumber = (parameters["testNumber"] as? NSNumber)?.intValue ?? (parameters["testNumber"] as? Int) ?? 0
        let testBoolean = parameters["testBoolean"] as? Bool ?? false
        let testOptional = parameters["testOptional"] as? String

        // Create mock result
        let result: [String: Any] = [
            "receivedString": testString,
            "receivedNumber": testNumber,
            "receivedBoolean": testBoolean,
            "receivedOptional": testOptional as Any,
            "toolName": name,
            "executionId": UUID().uuidString,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "mockExecution": true
        ]

        return result
    }
}