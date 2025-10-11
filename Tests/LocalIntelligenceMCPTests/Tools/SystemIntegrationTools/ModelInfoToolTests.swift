//
//  ModelInfoToolTests.swift
//  LocalIntelligenceMCPTests
//
//  Created on 2025-10-09.
//

import XCTest
@testable import LocalIntelligenceMCP

final class ModelInfoToolTests: XCTestCase {

    // MARK: - Properties

    private var logger: Logger!
    private var securityManager: SecurityManager!
    private var modelInfoTool: ModelInfoTool!

    // MARK: - Setup and Teardown

    override func setUp() async throws {
        try await super.setUp()

        // Initialize test components
        let config = LoggingConfiguration.default
        logger = Logger(configuration: config)
        await logger.setupFileLoggingIfNeeded()

        securityManager = SecurityManager(logger: logger)
        modelInfoTool = ModelInfoTool()
    }

    override func tearDown() async throws {
        logger = nil
        securityManager = nil
        modelInfoTool = nil

        try await super.tearDown()
    }

    // MARK: - Tool Initialization Tests

    func testModelInfoToolInitialization() async throws {
        XCTAssertNotNil(modelInfoTool)
        XCTAssertEqual(modelInfoTool.name, "model_info")
        XCTAssertFalse(modelInfoTool.description.isEmpty)
        XCTAssertNotNil(modelInfoTool.inputSchema)
        XCTAssertEqual(modelInfoTool.category, .audioDomain)
        XCTAssertTrue(modelInfoTool.requiresPermission.contains(.systemInfo))
        XCTAssertTrue(modelInfoTool.offlineCapable)
    }

    func testInputSchemaStructure() async throws {
        let schema = modelInfoTool.inputSchema

        // Check basic schema structure
        XCTAssertEqual(schema["type"] as? String, "object")

        // Check properties exist
        let properties = schema["properties"]?.value as? [String: Any]
        XCTAssertNotNil(properties)
        XCTAssertNotNil(properties?["includePerformance"])
        XCTAssertNotNil(properties?["includeConfiguration"])
        XCTAssertNotNil(properties?["includeCapabilities"])
        XCTAssertNotNil(properties?["includeStatistics"])
        XCTAssertNotNil(properties?["format"])

        // Check no required fields
        let required = schema["required"]?.value as? [String]
        XCTAssertTrue(required?.isEmpty == true)
    }

    // MARK: - Basic Execution Tests

    func testBasicModelInfoExecution() async throws {
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
            let result = try await modelInfoTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)
            XCTAssertNotNil(result.data)
            XCTAssertNil(result.error)

            if let data = result.data?.value as? ModelInfoTool.ModelInfo {
                XCTAssertEqual(data.name, "Local Intelligence MCP Tools")
                XCTAssertEqual(data.version, "1.0.0")
                XCTAssertEqual(data.domain, "audio")
                XCTAssertFalse(data.capabilities.isEmpty)
                XCTAssertFalse(data.supportedTools.isEmpty)
            }
        } catch {
            XCTFail("Basic model info execution should succeed: \(error.localizedDescription)")
        }
    }

    func testModelInfoWithPerformanceMetrics() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "includePerformance": true,
            "includeConfiguration": false,
            "includeCapabilities": false,
            "includeStatistics": false
        ] as [String: AnyCodable]

        do {
            let result = try await modelInfoTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            if let data = result.data?.value as? ModelInfoTool.ModelInfo {
                XCTAssertNotNil(data.performance)
                XCTAssertNil(data.configuration)
                XCTAssertNil(data.statistics)
                XCTAssertFalse(data.capabilities.isEmpty)
                XCTAssertFalse(data.supportedTools.isEmpty)
            }
        } catch {
            XCTFail("Model info with performance metrics should succeed: \(error.localizedDescription)")
        }
    }

    func testModelInfoWithConfiguration() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "includePerformance": false,
            "includeConfiguration": true,
            "includeCapabilities": false,
            "includeStatistics": false
        ] as [String: AnyCodable]

        do {
            let result = try await modelInfoTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            if let data = result.data?.value as? ModelInfoTool.ModelInfo {
                XCTAssertNil(data.performance)
                XCTAssertNotNil(data.configuration)
                XCTAssertNil(data.statistics)
                XCTAssertFalse(data.capabilities.isEmpty)
                XCTAssertFalse(data.supportedTools.isEmpty)
            }
        } catch {
            XCTFail("Model info with configuration should succeed: \(error.localizedDescription)")
        }
    }

    func testModelInfoWithCapabilities() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "includePerformance": false,
            "includeConfiguration": false,
            "includeCapabilities": true,
            "includeStatistics": false
        ] as [String: AnyCodable]

        do {
            let result = try await modelInfoTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            if let data = result.data?.value as? ModelInfo.ModelInfo {
                XCTAssertNil(data.performance)
                XCTAssertNil(data.configuration)
                XCTAssertNil(data.statistics)
                XCTAssertFalse(data.capabilities.isEmpty)
                XCTAssertFalse(data.supportedTools.isEmpty)
            }
        } catch {
            XCTFail("Model info with capabilities should succeed: \(error.localizedDescription)")
        }
    }

    func testModelInfoWithStatistics() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "includePerformance": false,
            "includeConfiguration": false,
            "includeCapabilities": false,
            "includeStatistics": true
        ] as [String: AnyCodable]

        do {
            let result = try await modelInfo.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            if let data = result.data?.value as? ModelInfo.ModelInfo {
                XCTAssertNil(data.performance)
                XCTAssertNil(data.configuration)
                XCTAssertNil(data.capabilities)
                XCTAssertNotNil(data.statistics)
                XCTAssertFalse(data.supportedTools.isEmpty)
            }
        } catch {
            XCTFail("Model info with statistics should succeed: \(error.localizedDescription)")
        }
    }

    func testModelInfoWithAllOptions() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "includePerformance": true,
            "includeConfiguration": true,
            "includeCapabilities": true,
            "includeStatistics": true,
            "format": "json"
        ] as [String: AnyCodable]

        do {
            let result = try await modelInfoTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            if let data = result.data?.value as? ModelInfo.ModelInfo {
                XCTAssertNotNil(data.performance)
                XCTAssertNotNil(data.configuration)
                XCTAssertNotNil(data.capabilities)
                XCTAssertNotNil(data.statistics)
                XCTAssertFalse(data.supportedTools.isEmpty)
            }
        } catch {
            XCTFail("Model info with all options should succeed: \(error.localizedDescription)")
        }
    }

    // MARK: - Capabilities Tests

    func testSystemCapabilitiesContent() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "includeCapabilities": true
        ] as [String: AnyCodable]

        do {
            let result = try await modelInfoTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            if let data = result.data?.value as? ModelInfoTool.ModelInfo {
                let capabilities = data.capabilities

                // Check for expected capabilities
                XCTAssertTrue(capabilities.contains("text_processing"))
                XCTAssertTrue(capabilities.contains("intent_analysis"))
                XCTAssertTrue(capabilities.contains("schema_extraction"))
                XCTAssertTrue(capabilities.contains("catalog_analysis"))
                XCTAssertTrue(capabilities.contains("session_documentation"))
                XCTAssertTrue(capabilities.contains("feedback_analysis"))
                XCTAssertTrue(capabilities.contains("vendor_neutral_analysis"))
                XCTAssertTrue(capabilities.contains("engineering_templates"))
                XCTAssertTrue(capabilities.contains("plugin_clustering"))
                XCTAssertTrue(capabilities.contains("sentiment_analysis"))
                XCTAssertTrue(capabilities.contains("action_item_extraction"))
                XCTAssertTrue(capabilities.contains("multilingual_support"))
                XCTAssertTrue(capabilities.contains("real_time_processing"))
                XCTAssertTrue(capabilities.contains("security_enforcement"))
                XCTAssertTrue(capabilities.contains("audit_logging"))
                XCTAssertTrue(capabilities.contains("performance_monitoring"))
            }
        } catch {
            XCTFail("System capabilities should be included: \(error.localizedDescription)")
        }
    }

    func testSupportedToolsList() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "includeCapabilities": true
        ] as [String: AnyCodable]

        do {
            let result = try await modelInfo.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            if let data = result.data?.value as? ModelInfo.ModelInfo {
                let tools = data.supportedTools

                // Check for core text processing tools
                XCTAssertTrue(tools.contains("apple.summarize"))
                XCTAssertTrue(tools.contains("apple.text.rewrite"))
                XCTAssertTrue(tools.contains("apple.text.normalize"))
                XCTAssertTrue(tools.contains("apple.summarize.focus"))
                XCTAssertTrue(tools.contains("apple.text.redact"))
                XCTAssertTrue(tools.contains("apple.text.chunk"))
                XCTAssertTrue(tools.contains("apple.text.count"))

                // Check for intent analysis tools
                XCTAssertTrue(tools.contains("apple.intent.recognize"))
                XCTAssertTrue(tools.contains("apple.query.analyze"))
                XCTAssertTrue(tools.contains("apple.purpose.detect"))

                // Check for extraction tools
                XCTAssertTrue(tools.contains("apple.schema.extract"))
                XCTAssertTrue(tools.contains("apple.tags.generate"))
                XCTAssertTrue(tools.contains("apple.entities.extract"))

                // Check for professional audio tools
                XCTAssertTrue(tools.contains("apple.catalog.summarize"))
                XCTAssertTrue(tools.contains("apple.session.summarize"))
                XCTAssertTrue(tools.contains("apple.feedback.analyze"))
            }
        } catch {
            XCTFail("Supported tools should be listed: \(error.localizedDescription)")
        }
    }

    // MARK: - Performance Metrics Tests

    func testPerformanceMetricsContent() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidUUIDString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "includePerformance": true
        ] as [String: AnyCodable]

        do {
            let result = try await modelInfo.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            if let data = result.data?.value as? ModelInfoTool.ModelInfo,
               let performance = data.performance {

                XCTAssertFalse(performance.responseTime.isEmpty)
                XCTAssertFalse(performance.throughput.isEmpty)
                XCTAssertFalse(performance.memoryUsage.isEmpty)
                XCTAssertFalse(performance.uptime.isEmpty)
                XCTAssertFalse(performance.averageResponseTime.isEmpty)
                XCTAssertTrue(performance.requestsProcessed >= 0)
                XCTAssertFalse(performance.errorRate.isEmpty)
            }
        } catch {
            XCTFail("Performance metrics should be included: \(error.localizedDescription)")
        }
    }

    func testPerformanceMetricsValidity() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "includePerformance": true
        ] as [String: AnyCodable]

        do {
            let result = try await modelInfoTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            if let data = result.data?.value as? ModelInfo.ModelInfo,
               let performance = data.performance {

                // Check response time format
                XCTAssertTrue(performance.responseTime.contains("ms"))

                // Check throughput format
                XCTAssertFalse(performance.throughput.isEmpty)

                // Check memory usage format
                XCTAssertTrue(performance.memoryUsage.contains("MB") || performance.memoryUsage.contains("GB"))

                // Check error rate format
                XCTAssertTrue(performance.errorRate.contains("%") || Double(performance.errorRate.replacingOccurrences(of: "%", with: "")) != nil)

                // Check requests processed is reasonable
                XCTAssertTrue(performance.requestsProcessed >= 0)
            }
        } catch {
            XCTFail("Performance metrics should be valid: \(error.localizedDescription)")
        }
    }

    // MARK: - Configuration Tests

    func testConfigurationContent() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "includeConfiguration": true
        ] as [String: AnyCodable]

        do {
            let result = try await modelInfo.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            if let data = result.data?.value as? ModelInfoTool.ModelInfo,
               let configuration = data.configuration {

                XCTAssertEqual(configuration.domain, "audio")
                XCTAssertFalse(configuration.logLevel.isEmpty)
                XCTAssertTrue(configuration.maxConcurrency > 0)
                XCTAssertTrue(configuration.timeoutSeconds > 0)
                XCTAssertFalse(configuration.features.isEmpty)

                // Check security configuration
                let security = configuration.security
                XCTAssertTrue(security.inputValidation)
                XCTAssertTrue(security.rateLimiting)
                XCTAssertTrue(security.auditLogging)
                XCTAssertTrue(security.piiRedaction)
            }
        } catch {
            XCTFail("Configuration should be included: \(error.localizedDescription)")
        }
    }

    // MARK: - Statistics Tests

    func testStatisticsContent() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "includeStatistics": true
        ] as [String: AnyCodable]

        do {
            let result = try await modelInfo.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            if let data = result.data?.value as? ModelInfo.ModelInfo,
               let statistics = data.statistics {

                XCTAssertTrue(statistics.totalRequests >= 0)
                XCTAssertTrue(statistics.successfulRequests >= 0)
                XCTAssertTrue(statistics.failedRequests >= 0)
                XCTAssertFalse(statistics.averageResponseTime.isEmpty)
                XCTAssertFalse(statistics.toolsUsed.isEmpty)
                XCTAssertFalse(statistics.topTools.isEmpty)
                XCTAssertFalse(statistics.lastReset.isEmpty)

                // Check data consistency
                XCTAssertEqual(statistics.totalRequests, statistics.successfulRequests + statistics.failedRequests)
            }
        } catch {
            XCTFail("Statistics should be included: \(error.localizedDescription)")
        }
    }

    func testToolUsageStats() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "includeStatistics": true
        ] as [String: AnyCodable]

        do {
            let result = try await modelInfo.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            if let data = result.data?.value as? ModelInfo.ModelInfo,
               let statistics = data.statistics,
               let toolsUsed = statistics.toolsUsed {

                XCTAssertFalse(toolsUsed.isEmpty)

                // Check that each tool usage entry has required fields
                for toolUsage in toolsUsed {
                    XCTAssertFalse(toolUsage.toolName.isEmpty)
                    XCTAssertTrue(toolUsage.usageCount >= 0)
                    XCTAssertFalse(toolUsage.averageResponseTime.isEmpty)
                    XCTAssertFalse(toolUsage.lastUsed.isEmpty)
                }
            }
        } catch {
            XCFail("Tool usage stats should be included: \(error.localizedDescription)")
        }
    }

    // MARK: - Format Tests

    func testJSONFormatOutput() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "format": "json"
        ] as [String: AnyCodable]

        do {
            let result = try await modelInfoTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)
            XCTAssertNotNil(result.data)
        } catch {
            XCTFail("JSON format should succeed: \(error.localizedDescription)")
        }
    }

    func testTextFormatOutput() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "format": "text"
        ] as [String: AnyCodable]

        do {
            let result = try await modelInfo.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)
            XCTAssertNotNil(result.data)
        } catch {
            XCTFail("Text format should succeed: \(error.localizedDescription)")
        }
    }

    func testMarkdownFormatOutput() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "format": "markdown"
        ] as [String: AnyCodable]

        do {
            let result = try await modelInfo.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)
            XCTAssertNotNil(result.data)
        } catch {
            XCTFail("Markdown format should succeed: \(error.localizedDescription)")
        }
    }

    // MARK: - Parameter Validation Tests

    func testInvalidFormatParameter() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "format": "invalid_format"
        ] as [String: AnyCodable]

        do {
            let result = try await modelInfoTool.performExecution(parameters: parameters, context: context)
            // Should still succeed with default format
            XCTAssertTrue(result.success)
        } catch {
            XCTFail("Invalid format parameter should not cause failure: \(error.localizedDescription)")
        }
    }

    func testBooleanParameterHandling() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "includePerformance": false,
            "includeConfiguration": false,
            "includeCapabilities": false,
            "includeStatistics": false
        ] as [String: AnyCodable]

        do {
            let result = try await modelInfoTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            // Should still include some basic information even with all flags false
            if let data = result.data?.value as? ModelInfoTool.ModelInfo {
                XCTAssertFalse(data.capabilities.isEmpty)
                XCTAssertFalse(data.supportedTools.isEmpty)
            }
        } catch {
            XCTFail("Boolean parameter handling should work: \(error.localizedDescription)")
        }
    }

    // MARK: - Performance Tests

    func testModelInfoPerformance() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [:] as [String: AnyCodable]

        // Measure execution time
        measure {
            Task {
                do {
                    let result = try await modelInfoTool.performExecution(parameters: parameters, context: context)
                    XCTAssertTrue(result.success)
                } catch {
                    XCTFail("Performance test should not fail: \(error.localizedDescription)")
                }
            }
        }
    }

    func testConcurrentModelInfo() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [:] as [String: AnyCodable]

        // Test concurrent executions
        await withTaskGroup(of: Bool.self) { group in
            for i in 0..<3 {
                group.addTask {
                    do {
                        let result = try await self.modelInfoTool.performExecution(parameters: parameters, context: context)
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

            XCTAssertEqual(successCount, 3, "All concurrent model info calls should succeed")
        }
    }

    // MARK: - Edge Cases Tests

    func testEmptyParameters() async throws {
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
            let result = try await modelInfoTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            if let data = result.data?.value as? ModelInfo.ModelInfo {
                // Should still provide basic information
                XCTAssertEqual(data.name, "Local Intelligence MCP Tools")
                XCTAssertFalse(data.capabilities.isEmpty)
                XCTAssertFalse(data.supportedTools.isEmpty)
            }
        } catch {
            XCTFail("Empty parameters should work: \(error.localizedDescription)")
        }
    }

    func testNullParameterValues() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "includePerformance": nil,
            "includeConfiguration": nil,
            "includeCapabilities": nil,
            "includeStatistics": nil,
            "format": nil
        ] as [String: AnyCodable]

        do {
            let result = try await modelInfoTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            // Should use default values
            if let data = result.data?.value as? ModelInfo.ModelInfo {
                XCTAssertNotNil(data.capabilities)
                XCTAssertNotNil(data.supportedTools)
            }
        } catch {
            XCTFail("Null parameter values should work: \(error.localizedDescription)")
        }
    }
}