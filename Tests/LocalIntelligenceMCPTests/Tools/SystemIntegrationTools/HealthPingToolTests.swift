//
//  HealthPingToolTests.swift
//  LocalIntelligenceMCPTests
//
//  Created on 2025-10-09.
//

import XCTest
@testable import LocalIntelligenceMCP

final class HealthPingToolTests: XCTestCase {

    var healthPingTool: HealthPingTool!

    override func setUp() async throws {
        try await super.setUp()
        healthPingTool = HealthPingTool()
    }

    override func tearDown() async throws {
        healthPingTool = nil
        try await super.tearDown()
    }

    // MARK: - Tool Initialization Tests

    func testToolInitialization() throws {
        XCTAssertEqual(healthPingTool.name, "health_ping")
        XCTAssertFalse(healthPingTool.description.isEmpty)

        // Verify input schema structure
        let schema = healthPingTool.inputSchema
        XCTAssertEqual(schema["type"] as? String, "object")

        let properties = schema["properties"] as? [String: Any]
        XCTAssertNotNil(properties)

        // Check required properties
        let requiredProperties = schema["required"] as? [String]
        XCTAssertTrue(requiredProperties?.isEmpty ?? false) // No required properties

        // Check optional properties with defaults
        XCTAssertNotNil(properties?["includeDiagnostics"])
        XCTAssertNotNil(properties?["checkTools"])
        XCTAssertNotNil(properties?["checkMemory"])
        XCTAssertNotNil(properties?["checkPerformance"])
        XCTAssertNotNil(properties?["timeout"])
    }

    func testInputSchemaDefaults() throws {
        let schema = healthPingTool.inputSchema
        let properties = schema["properties"] as? [String: Any]

        // Test default values
        XCTAssertEqual(properties?["includeDiagnostics"] as? [String: Any]?["default"] as? Bool, true)
        XCTAssertEqual(properties?["checkTools"] as? [String: Any]?["default"] as? Bool, true)
        XCTAssertEqual(properties?["checkMemory"] as? [String: Any]?["default"] as? Bool, true)
        XCTAssertEqual(properties?["checkPerformance"] as? [String: Any]?["default"] as? Bool, false)
        XCTAssertEqual(properties?["timeout"] as? [String: Any]?["default"] as? Int, 10)
    }

    // MARK: - Basic Execution Tests

    func testBasicHealthPingExecution() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )
        let parameters = [:] as [String: AnyCodable]

        do {
            let result = try await healthPingTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)
            XCTAssertNotNil(result.data)
            XCTAssertNil(result.error)
        } catch {
            XCTFail("Basic health ping execution should succeed: \(error.localizedDescription)")
        }
    }

    func testHealthPingWithDefaultParameters() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        // Test with default parameters (empty)
        let parameters = [:] as [String: AnyCodable]

        do {
            let result = try await healthPingTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)
            XCTAssertNotNil(result.data)

            // Verify response structure
            let data = result.data?.value as? [String: Any]
            XCTAssertNotNil(data)
            XCTAssertNotNil(data?["status"])
            XCTAssertNotNil(data?["timestamp"])
            XCTAssertNotNil(data?["uptime"])
            XCTAssertNotNil(data?["responseTime"])
            XCTAssertNotNil(data?["version"])
        } catch {
            XCTFail("Health ping with default parameters should succeed: \(error.localizedDescription)")
        }
    }

    // MARK: - Input Parameter Tests

    func testHealthPingInputParsing() throws {
        let parameters = [
            "includeDiagnostics": AnyCodable(false),
            "checkTools": AnyCodable(false),
            "checkMemory": AnyCodable(false),
            "checkPerformance": AnyCodable(true),
            "timeout": AnyCodable(30)
        ] as [String: AnyCodable]

        let input = try HealthPingTool.HealthPingInput(from: parameters)

        XCTAssertFalse(input.includeDiagnostics)
        XCTAssertFalse(input.checkTools)
        XCTAssertFalse(input.checkMemory)
        XCTAssertTrue(input.checkPerformance)
        XCTAssertEqual(input.timeout, 30)
    }

    func testHealthPingInputWithDefaults() throws {
        let parameters = [:] as [String: AnyCodable]

        let input = try HealthPingTool.HealthPingInput(from: parameters)

        XCTAssertTrue(input.includeDiagnostics) // Default: true
        XCTAssertTrue(input.checkTools) // Default: true
        XCTAssertTrue(input.checkMemory) // Default: true
        XCTAssertFalse(input.checkPerformance) // Default: false
        XCTAssertNil(input.timeout) // Default: nil
    }

    func testHealthPingWithDiagnosticsEnabled() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "includeDiagnostics": AnyCodable(true)
        ] as [String: AnyCodable]

        do {
            let result = try await healthPingTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            XCTAssertNotNil(data?["diagnostics"])

            let diagnostics = data?["diagnostics"] as? [String: Any]
            XCTAssertNotNil(diagnostics?["systemInfo"])
            XCTAssertNotNil(diagnostics?["environment"])
            XCTAssertNotNil(diagnostics?["dependencies"])
            XCTAssertNotNil(diagnostics?["lastHealthCheck"])
        } catch {
            XCTFail("Health ping with diagnostics should succeed: \(error.localizedDescription)")
        }
    }

    func testHealthPingWithDiagnosticsDisabled() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "includeDiagnostics": AnyCodable(false)
        ] as [String: AnyCodable]

        do {
            let result = try await healthPingTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            XCTAssertNil(data?["diagnostics"])
        } catch {
            XCTFail("Health ping without diagnostics should succeed: \(error.localizedDescription)")
        }
    }

    func testHealthPingWithToolChecking() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "checkTools": AnyCodable(true)
        ] as [String: AnyCodable]

        do {
            let result = try await healthPingTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            XCTAssertNotNil(data?["toolStatus"])

            let toolStatus = data?["toolStatus"] as? [[String: Any]]
            XCTAssertNotNil(toolStatus)
            XCTAssertGreaterThan(toolStatus?.count ?? 0, 0)

            // Verify tool status structure
            if let firstTool = toolStatus?.first {
                XCTAssertNotNil(firstTool["name"])
                XCTAssertNotNil(firstTool["status"])
                XCTAssertNotNil(firstTool["responseTime"])
                XCTAssertNotNil(firstTool["lastUsed"])
                XCTAssertNotNil(firstTool["errorCount"])
                XCTAssertNotNil(firstTool["issues"])
            }
        } catch {
            XCTFail("Health ping with tool checking should succeed: \(error.localizedDescription)")
        }
    }

    func testHealthPingWithMemoryChecking() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "checkMemory": AnyCodable(true)
        ] as [String: AnyCodable]

        do {
            let result = try await healthPingTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            XCTAssertNotNil(data?["memoryStatus"])

            let memoryStatus = data?["memoryStatus"] as? [String: Any]
            XCTAssertNotNil(memoryStatus?["totalMemory"])
            XCTAssertNotNil(memoryStatus?["usedMemory"])
            XCTAssertNotNil(memoryStatus?["availableMemory"])
            XCTAssertNotNil(memoryStatus?["memoryUsage"])
            XCTAssertNotNil(memoryStatus?["gcPressure"])
            XCTAssertNotNil(memoryStatus?["recommendations"])
        } catch {
            XCTFail("Health ping with memory checking should succeed: \(error.localizedDescription)")
        }
    }

    func testHealthPingWithPerformanceChecking() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "checkPerformance": AnyCodable(true)
        ] as [String: AnyCodable]

        do {
            let result = try await healthPingTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            XCTAssertNotNil(data?["performanceStatus"])

            let performanceStatus = data?["performanceStatus"] as? [String: Any]
            XCTAssertNotNil(performanceStatus?["averageResponseTime"])
            XCTAssertNotNil(performanceStatus?["requestsPerSecond"])
            XCTAssertNotNil(performanceStatus?["errorRate"])
            XCTAssertNotNil(performanceStatus?["concurrencyLevel"])
            XCTAssertNotNil(performanceStatus?["queueDepth"])
            XCTAssertNotNil(performanceStatus?["bottlenecks"])
        } catch {
            XCTFail("Health ping with performance checking should succeed: \(error.localizedDescription)")
        }
    }

    // MARK: - Health Status Tests

    func testHealthStatusValues() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [:] as [String: AnyCodable]

        do {
            let result = try await healthPingTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            let status = data?["status"] as? String

            // Verify status is one of expected values
            XCTAssertTrue(status == "healthy" || status == "degraded" || status == "unhealthy")
        } catch {
            XCTFail("Health status check should succeed: \(error.localizedDescription)")
        }
    }

    func testResponseTimeMeasurement() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [:] as [String: AnyCodable]

        do {
            let result = try await healthPingTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            let responseTime = data?["responseTime"] as? String

            XCTAssertNotNil(responseTime)
            XCTAssertTrue(responseTime?.contains("ms") ?? false)

            // Verify response time is reasonable (should be fast)
            let responseTimeValue = Double(responseTime?.replacingOccurrences(of: " ms", with: "") ?? "0") ?? 0
            XCTAssertLessThan(responseTimeValue, 5000) // Should be less than 5 seconds
        } catch {
            XCTFail("Response time measurement should succeed: \(error.localizedDescription)")
        }
    }

    // MARK: - System Information Tests

    func testSystemInformation() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "includeDiagnostics": AnyCodable(true)
        ] as [String: AnyCodable]

        do {
            let result = try await healthPingTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            let diagnostics = data?["diagnostics"] as? [String: Any]

            // Verify system info
            let systemInfo = diagnostics?["systemInfo"] as? [String: Any]
            XCTAssertNotNil(systemInfo?["platform"])
            XCTAssertNotNil(systemInfo?["architecture"])
            XCTAssertNotNil(systemInfo?["processorCount"])
            XCTAssertNotNil(systemInfo?["memoryTotal"])
            XCTAssertNotNil(systemInfo?["memoryAvailable"])
            XCTAssertNotNil(systemInfo?["diskSpace"])
            XCTAssertNotNil(systemInfo?["networkStatus"])

            // Verify environment info
            let environment = diagnostics?["environment"] as? [String: Any]
            XCTAssertNotNil(environment?["swiftVersion"])
            XCTAssertNotNil(environment?["mcpVersion"])
            XCTAssertNotNil(environment?["operatingSystem"])
            XCTAssertNotNil(environment?["processID"])
            XCTAssertNotNil(environment?["workingDirectory"])

            // Verify dependencies
            let dependencies = diagnostics?["dependencies"] as? [[String: Any]]
            XCTAssertNotNil(dependencies)
            XCTAssertGreaterThan(dependencies?.count ?? 0, 0)
        } catch {
            XCTFail("System information check should succeed: \(error.localizedDescription)")
        }
    }

    func testUptimeCalculation() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [:] as [String: AnyCodable]

        do {
            let result = try await healthPingTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            let uptime = data?["uptime"] as? String

            XCTAssertNotNil(uptime)
            XCTAssertFalse(uptime?.isEmpty ?? true)

            // Verify uptime format (should contain time units)
            XCTAssertTrue(uptime?.contains("d") ?? false || uptime?.contains("h") ?? false || uptime?.contains("m") ?? false)
        } catch {
            XCTFail("Uptime calculation should succeed: \(error.localizedDescription)")
        }
    }

    // MARK: - Recommendations Tests

    func testHealthRecommendations() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [:] as [String: AnyCodable]

        do {
            let result = try await healthPingTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            let recommendations = data?["recommendations"] as? [String]

            XCTAssertNotNil(recommendations)
            XCTAssertGreaterThan(recommendations?.count ?? 0, 0)

            // Verify recommendations are strings
            for recommendation in recommendations ?? [] {
                XCTAssertFalse(recommendation.isEmpty)
                XCTAssertTrue(recommendation.count > 5) // Should be meaningful
            }
        } catch {
            XCTFail("Health recommendations should succeed: \(error.localizedDescription)")
        }
    }

    // MARK: - Version Information Tests

    func testVersionInformation() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [:] as [String: AnyCodable]

        do {
            let result = try await healthPingTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            let version = data?["version"] as? String

            XCTAssertNotNil(version)
            XCTAssertFalse(version?.isEmpty ?? true)
            XCTAssertEqual(version, "1.0.0")
        } catch {
            XCTFail("Version information should succeed: \(error.localizedDescription)")
        }
    }

    // MARK: - Timestamp Tests

    func testTimestampFormatting() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [:] as [String: AnyCodable]

        do {
            let result = try await healthPingTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            let timestamp = data?["timestamp"] as? String

            XCTAssertNotNil(timestamp)
            XCTAssertFalse(timestamp?.isEmpty ?? true)

            // Verify ISO8601 format
            let formatter = ISO8601DateFormatter()
            let parsedDate = formatter.date(from: timestamp ?? "")
            XCTAssertNotNil(parsedDate)
        } catch {
            XCTFail("Timestamp formatting should succeed: \(error.localizedDescription)")
        }
    }

    // MARK: - Parameter Validation Tests

    func testTimeoutParameterValidation() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "timeout": AnyCodable(30)
        ] as [String: AnyCodable]

        do {
            let input = try HealthPingTool.HealthPingInput(from: parameters)
            XCTAssertEqual(input.timeout, 30)

            let result = try await healthPingTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)
        } catch {
            XCTFail("Timeout parameter validation should succeed: \(error.localizedDescription)")
        }
    }

    func testBooleanParameterValidation() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        // Test all boolean combinations
        let testCases: [[String: Any]] = [
            ["includeDiagnostics": true, "checkTools": true, "checkMemory": true, "checkPerformance": true],
            ["includeDiagnostics": false, "checkTools": false, "checkMemory": false, "checkPerformance": false],
            ["includeDiagnostics": true, "checkTools": false, "checkMemory": true, "checkPerformance": false]
        ]

        for testCase in testCases {
            let parameters = testCase.map { (key, value) in
                (key, AnyCodable(value))
            } as [String: AnyCodable]

            do {
                let input = try HealthPingTool.HealthPingInput(from: parameters)
                let result = try await healthPingTool.performExecution(parameters: parameters, context: context)
                XCTAssertTrue(result.success)
            } catch {
                XCTFail("Boolean parameter validation should succeed for case: \(testCase): \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Performance Tests

    func testHealthPingPerformance() {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [:] as [String: AnyCodable]

        measure {
            let expectation = XCTestExpectation(description: "Health ping performance")
            Task {
                do {
                    let result = try await healthPingTool.performExecution(parameters: parameters, context: context)
                    XCTAssertTrue(result.success)
                } catch {
                    XCTFail("Performance test should not fail: \(error.localizedDescription)")
                }
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 10.0)
        }
    }

    func testConcurrentHealthChecks() {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [:] as [String: AnyCodable]
        let concurrentRequests = 10

        measure {
            let expectation = XCTestExpectation(description: "Concurrent health checks")
            expectation.expectedFulfillmentCount = concurrentRequests

            for i in 0..<concurrentRequests {
                Task {
                    do {
                        let result = try await healthPingTool.performExecution(parameters: parameters, context: context)
                        XCTAssertTrue(result.success, "Request \(i) should succeed")
                    } catch {
                        XCTFail("Concurrent request \(i) should not fail: \(error.localizedDescription)")
                    }
                    expectation.fulfill()
                }
            }

            wait(for: [expectation], timeout: 15.0)
        }
    }

    // MARK: - Edge Cases Tests

    func testHealthPingWithContextMetadata() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [
                "requestSource": "unit_test",
                "testType": "edge_case",
                "timestamp": ISO8601DateFormatter().string(from: Date())
            ]
        )

        let parameters = [:] as [String: AnyCodable]

        do {
            let result = try await healthPingTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)
            XCTAssertNotNil(result.data)
        } catch {
            XCTFail("Health ping with context metadata should succeed: \(error.localizedDescription)")
        }
    }

    func testHealthPingWithMinimalParameters() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: "minimal-test",
            sessionId: "test-session",
            userId: "test-user",
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [:] as [String: AnyCodable]

        do {
            let result = try await healthPingTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)
            XCTAssertNotNil(result.data)
        } catch {
            XCTFail("Health ping with minimal parameters should succeed: \(error.localizedDescription)")
        }
    }

    func testHealthPingWithAllFeaturesEnabled() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "includeDiagnostics": AnyCodable(true),
            "checkTools": AnyCodable(true),
            "checkMemory": AnyCodable(true),
            "checkPerformance": AnyCodable(true),
            "timeout": AnyCodable(60)
        ] as [String: AnyCodable]

        do {
            let result = try await healthPingTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            XCTAssertNotNil(data?["diagnostics"])
            XCTAssertNotNil(data?["toolStatus"])
            XCTAssertNotNil(data?["memoryStatus"])
            XCTAssertNotNil(data?["performanceStatus"])
            XCTAssertNotNil(data?["recommendations"])
        } catch {
            XCTFail("Health ping with all features enabled should succeed: \(error.localizedDescription)")
        }
    }

    func testHealthPingWithAllFeaturesDisabled() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "includeDiagnostics": AnyCodable(false),
            "checkTools": AnyCodable(false),
            "checkMemory": AnyCodable(false),
            "checkPerformance": AnyCodable(false)
        ] as [String: AnyCodable]

        do {
            let result = try await healthPingTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            XCTAssertNil(data?["diagnostics"])
            XCTAssertNil(data?["toolStatus"])
            XCTAssertNil(data?["memoryStatus"])
            XCTAssertNil(data?["performanceStatus"])

            // Should still have basic health info
            XCTAssertNotNil(data?["status"])
            XCTAssertNotNil(data?["timestamp"])
            XCTAssertNotNil(data?["uptime"])
            XCTAssertNotNil(data?["responseTime"])
            XCTAssertNotNil(data?["version"])
            XCTAssertNotNil(data?["recommendations"])
        } catch {
            XCTFail("Health ping with all features disabled should succeed: \(error.localizedDescription)")
        }
    }

    func testHealthPingResultStructure() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [:] as [String: AnyCodable]

        do {
            let result = try await healthPingTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]

            // Verify all required fields exist
            let requiredFields = ["status", "timestamp", "uptime", "responseTime", "version", "recommendations"]
            for field in requiredFields {
                XCTAssertNotNil(data?[field], "Required field '\(field)' should not be nil")
            }

            // Verify field types
            XCTAssertTrue(data?["status"] is String)
            XCTAssertTrue(data?["timestamp"] is String)
            XCTAssertTrue(data?["uptime"] is String)
            XCTAssertTrue(data?["responseTime"] is String)
            XCTAssertTrue(data?["version"] is String)
            XCTAssertTrue(data?["recommendations"] is [String])

            // Verify status is valid
            let status = data?["status"] as? String
            XCTAssertTrue(status == "healthy" || status == "degraded" || status == "unhealthy")
        } catch {
            XCTFail("Health ping result structure validation should succeed: \(error.localizedDescription)")
        }
    }
}