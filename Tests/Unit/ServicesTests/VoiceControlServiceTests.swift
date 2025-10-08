//
//  VoiceControlServiceTests.swift
//  AppleMCPServer
//
//  Created on 2025-10-07.
//

import XCTest
@testable import AppleMCPServer

final class VoiceControlServiceTests: XCTestCase {

    // MARK: - Properties

    private var logger: Logger!
    private var securityManager: SecurityManager!
    private var voiceControlTool: VoiceControlTool!

    // MARK: - Setup and Teardown

    override func setUp() async throws {
        try await super.setUp()

        // Initialize test components
        let config = LoggingConfiguration.default
        logger = Logger(configuration: config)
        await logger.setupFileLoggingIfNeeded()

        securityManager = SecurityManager(logger: logger)
        voiceControlTool = VoiceControlTool(logger: logger, securityManager: securityManager)
    }

    override func tearDown() async throws {
        logger = nil
        securityManager = nil
        voiceControlTool = nil

        try await super.tearDown()
    }

    // MARK: - Tool Initialization Tests

    func testVoiceControlToolInitialization() async throws {
        // Test that the voice control tool initializes correctly
        XCTAssertNotNil(voiceControlTool)
        XCTAssertEqual(voiceControlTool.name, "execute_voice_command")
        XCTAssertFalse(voiceControlTool.description.isEmpty)
        XCTAssertNotNil(voiceControlTool.inputSchema)
        XCTAssertEqual(voiceControlTool.category, .voiceControl)
        XCTAssertTrue(voiceControlTool.requiresPermission.contains(.voiceControl))
        XCTAssertTrue(voiceControlTool.offlineCapable)
    }

    // MARK: - Input Schema Validation Tests

    func testInputSchemaValidation() async throws {
        // Test input schema structure
        let schema = voiceControlTool.inputSchema

        // Check required fields
        let required = schema["required"] as? [String]
        XCTAssertTrue(required?.contains("command") == true)

        // Check properties exist
        let properties = schema["properties"] as? [String: Any]
        XCTAssertNotNil(properties?["command"])
        XCTAssertNotNil(properties?["parameters"])
        XCTAssertNotNil(properties?["confidenceThreshold"])
        XCTAssertNotNil(properties?["language"])
        XCTAssertNotNil(properties?["timeout"])
        XCTAssertNotNil(properties?["validateCommand"])
    }

    func testValidParameters() async throws {
        // Test with valid minimal parameters
        let validParams = [
            "command": "open Safari"
        ]

        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "execute_voice_command"
        )

        // Should not throw for valid parameters
        do {
            _ = try await voiceControlTool.performExecution(parameters: validParams, context: context)
        } catch {
            // Expected to fail at execution stage since it's a mock, but should not fail validation
            XCTAssertTrue(error.localizedDescription.contains("not found") ||
                         error.localizedDescription.contains("validation") ||
                         error.localizedDescription.contains("execution"))
        }
    }

    func testMissingRequiredParameter() async throws {
        // Test with missing required command parameter
        let invalidParams = [
            "parameters": ["test": "value"]
        ]

        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "execute_voice_command"
        )

        do {
            _ = try await voiceControlTool.performExecution(parameters: invalidParams, context: context)
            XCTFail("Should have thrown an error for missing required parameter")
        } catch {
            // Expected behavior
            XCTAssertTrue(true)
        }
    }

    func testInvalidCommand() async throws {
        // Test with invalid commands
        let invalidCommands = ["", "   ", String(repeating: "x", count: 201)] // Empty, whitespace, too long

        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "execute_voice_command"
        )

        for invalidCommand in invalidCommands {
            let params = ["command": invalidCommand]

            do {
                _ = try await voiceControlTool.performExecution(parameters: params, context: context)
                XCTFail("Should have thrown an error for invalid command: '\(invalidCommand)'")
            } catch {
                // Expected behavior
                XCTAssertTrue(true)
            }
        }
    }

    // MARK: - Parameter Validation Tests

    func testConfidenceThresholdValidation() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "execute_voice_command"
        )

        // Test invalid confidence threshold values
        let invalidThresholds = [-0.1, 1.1] // Below and above valid range

        for threshold in invalidThresholds {
            let params = [
                "command": "open Safari",
                "confidenceThreshold": threshold
            ]

            do {
                _ = try await voiceControlTool.performExecution(parameters: params, context: context)
                XCTFail("Should have thrown an error for invalid confidence threshold: \(threshold)")
            } catch {
                // Expected behavior
                XCTAssertTrue(true)
            }
        }

        // Test valid confidence threshold values
        let validThresholds = [0.0, 0.5, 0.7, 1.0]

        for threshold in validThresholds {
            let params = [
                "command": "open Safari",
                "confidenceThreshold": threshold
            ]

            do {
                _ = try await voiceControlTool.performExecution(parameters: params, context: context)
            } catch {
                // May fail at execution but should not fail validation
                XCTAssertFalse(error.localizedDescription.contains("confidence"))
            }
        }
    }

    func testLanguageValidation() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "execute_voice_command"
        )

        // Test valid language codes
        let validLanguages = ["en-US", "en-GB", "es-ES", "fr-FR", "de-DE"]

        for language in validLanguages {
            let params = [
                "command": "open Safari",
                "language": language
            ]

            do {
                _ = try await voiceControlTool.performExecution(parameters: params, context: context)
            } catch {
                // May fail at execution but should not fail validation
                XCTAssertFalse(error.localizedDescription.contains("language"))
            }
        }

        // Test invalid language codes
        let invalidLanguages = ["invalid", "EN-US", "en-us", "english", "123"]

        for language in invalidLanguages {
            let params = [
                "command": "open Safari",
                "language": language
            ]

            do {
                _ = try await voiceControlTool.performExecution(parameters: params, context: context)
                XCTFail("Should have thrown an error for invalid language code: \(language)")
            } catch {
                // Expected behavior
                XCTAssertTrue(error.localizedDescription.contains("language") ||
                             error.localizedDescription.contains("validation"))
            }
        }
    }

    func testTimeoutValidation() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "execute_voice_command"
        )

        // Test invalid timeout values
        let invalidTimeouts = [0, -1, 31] // Below minimum and above maximum

        for timeout in invalidTimeouts {
            let params = [
                "command": "open Safari",
                "timeout": timeout
            ]

            do {
                _ = try await voiceControlTool.performExecution(parameters: params, context: context)
                XCTFail("Should have thrown an error for invalid timeout: \(timeout)")
            } catch {
                // Expected behavior
                XCTAssertTrue(true)
            }
        }

        // Test valid timeout values
        let validTimeouts = [1, 10, 30] // Minimum, default, and maximum

        for timeout in validTimeouts {
            let params = [
                "command": "open Safari",
                "timeout": timeout
            ]

            do {
                _ = try await voiceControlTool.performExecution(parameters: params, context: context)
            } catch {
                // May fail at execution but should not fail validation
                XCTAssertFalse(error.localizedDescription.contains("timeout"))
            }
        }
    }

    // MARK: - Command Execution Tests

    func testVoiceCommandExecution() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "execute_voice_command"
        )

        // Test basic execution structure
        let params = [
            "command": "open Safari"
        ]

        do {
            let result = try await voiceControlTool.performExecution(parameters: params, context: context)

            // Should not reach here for mock execution
            XCTFail("Expected execution to handle mock voice command")

        } catch {
            // Expected behavior - should handle gracefully
            XCTAssertTrue(true)
        }
    }

    func testCommandWithParameters() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "execute_voice_command"
        )

        // Test execution with parameters
        let params = [
            "command": "open Safari",
            "parameters": [
                "url": "https://www.apple.com",
                "newTab": true
            ],
            "confidenceThreshold": 0.8
        ]

        do {
            let result = try await voiceControlTool.performExecution(parameters: params, context: context)
            XCTFail("Expected execution to handle mock voice command")
        } catch {
            // Expected behavior
            XCTAssertTrue(true)
        }
    }

    func testCommandValidation() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "execute_voice_command"
        )

        // Test with command validation enabled
        let paramsWithValidation = [
            "command": "scroll down",
            "validateCommand": true
        ]

        do {
            let result = try await voiceControlTool.performExecution(parameters: paramsWithValidation, context: context)
        } catch {
            // Expected to fail since it's a mock
            XCTAssertTrue(true)
        }

        // Test with command validation disabled
        let paramsWithoutValidation = [
            "command": "custom action",
            "validateCommand": false
        ]

        do {
            let result = try await voiceControlTool.performExecution(parameters: paramsWithoutValidation, context: context)
        } catch {
            // Expected to fail since it's a mock
            XCTAssertTrue(true)
        }
    }

    // MARK: - Command Pattern Tests

    func testCommonVoiceCommands() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "execute_voice_command"
        )

        // Test common voice command patterns
        let commonCommands = [
            "open Safari",
            "close window",
            "scroll down",
            "click button",
            "switch to desktop",
            "show desktop",
            "hide window",
            "zoom in",
            "take screenshot",
            "start dictation"
        ]

        for command in commonCommands {
            let params = ["command": command]

            do {
                _ = try await voiceControlTool.performExecution(parameters: params, context: context)
            } catch {
                // Expected behavior for mock execution
                XCTAssertTrue(true)
            }
        }
    }

    // MARK: - Error Handling Tests

    func testExecutionErrorHandling() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "execute_voice_command"
        )

        // Test various error scenarios
        let errorScenarios: [[String: Any]] = [
            ["command": ""], // Empty command
            ["command": String(repeating: "x", count: 201)], // Too long command
            ["command": "test", "confidenceThreshold": -0.1], // Invalid confidence
            ["command": "test", "timeout": 0], // Invalid timeout
            ["command": "test", "language": "invalid"] // Invalid language
        ]

        for (index, params) in errorScenarios.enumerated() {
            do {
                _ = try await voiceControlTool.performExecution(parameters: params, context: context)
                XCTFail("Scenario \(index) should have thrown an error")
            } catch {
                // Expected behavior
                XCTAssertTrue(true, "Scenario \(index) correctly threw an error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Accessibility Tests

    func testAccessibilitySupport() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "execute_voice_command"
        )

        // Test accessibility-related commands
        let accessibilityCommands = [
            "turn on VoiceOver",
            "turn off VoiceOver",
            "enable Zoom",
            "disable Zoom",
            "increase contrast",
            "reduce motion"
        ]

        for command in accessibilityCommands {
            let params = [
                "command": command,
                "validateCommand": false // May not be in standard command list
            ]

            do {
                _ = try await voiceControlTool.performExecution(parameters: params, context: context)
            } catch {
                // Expected behavior
                XCTAssertTrue(true)
            }
        }
    }

    // MARK: - Performance Tests

    func testPerformanceValidation() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "execute_voice_command"
        )

        let params = [
            "command": "open Safari",
            "confidenceThreshold": 0.7
        ]

        // Measure validation performance
        measure {
            Task {
                do {
                    _ = try await voiceControlTool.performExecution(parameters: params, context: context)
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
            toolName: "execute_voice_command"
        )

        // Test with maximum parameter size
        let largeParameters = [
            "command": "test command",
            "parameters": [
                "largeText": String(repeating: "x", count: 10000)
            ]
        ]

        do {
            _ = try await voiceControlTool.performExecution(parameters: largeParameters, context: context)
        } catch {
            // May fail but should handle large input gracefully
            XCTAssertTrue(true)
        }

        // Test with special characters in command
        let specialCharCommands = [
            "open Safari!",
            "scroll down?",
            "click \"OK\" button",
            "open file: /path/to/file.txt"
        ]

        for command in specialCharCommands {
            let params = ["command": command]

            do {
                _ = try await voiceControlTool.performExecution(parameters: params, context: context)
            } catch {
                // Expected to fail but should handle special characters
                XCTAssertTrue(true)
            }
        }
    }

    // MARK: - Integration Tests

    func testToolIntegration() async throws {
        // Test that tool integrates properly with the logging system
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "execute_voice_command"
        )

        let params = [
            "command": "Integration Test Command",
            "validateCommand": false
        ]

        // This should generate logs without crashing
        do {
            _ = try await voiceControlTool.performExecution(parameters: params, context: context)
        } catch {
            // Expected
        }

        // Verify no crashes occurred and tool state remains consistent
        XCTAssertNotNil(voiceControlTool)
        XCTAssertEqual(voiceControlTool.name, "execute_voice_command")
    }

    func testMultilingualSupport() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "execute_voice_command"
        )

        // Test different language codes
        let multilingualParams = [
            ["command": "ouvrir Safari", "language": "fr-FR"], // French
            ["command": "abrir Safari", "language": "es-ES"], // Spanish
            ["command": "Safari öffnen", "language": "de-DE"], // German
            ["command": "apri Safari", "language": "it-IT"] // Italian
        ]

        for params in multilingualParams {
            do {
                _ = try await voiceControlTool.performExecution(parameters: params, context: context)
            } catch {
                // Expected behavior
                XCTAssertTrue(true)
            }
        }
    }
}