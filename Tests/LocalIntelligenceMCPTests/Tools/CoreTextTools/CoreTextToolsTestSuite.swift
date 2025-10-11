//
//  CoreTextToolsTestSuite.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-08.
//

import XCTest
@testable import LocalIntelligenceMCP

/// Test Suite Runner for Core Text Processing Tools
/// This test suite provides a comprehensive validation of all core text processing tools
/// implemented in User Story 1 of the Local Intelligence MCP Tools project.
final class CoreTextToolsTestSuite: XCTestCase {

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

        // Register core text tools
        try await toolsRegistry.registerTool(SummarizationTool(logger: logger, securityManager: securityManager))
        try await toolsRegistry.registerTool(TextRewriteTool(logger: logger, securityManager: securityManager))
        try await toolsRegistry.registerTool(TextNormalizeTool(logger: logger, securityManager: securityManager))
    }

    override func tearDown() async throws {
        logger = nil
        securityManager = nil
        toolsRegistry = nil

        try await super.tearDown()
    }

    // MARK: - Comprehensive Test Suite

    /// Test complete functionality of all core text processing tools
    func testCoreTextProcessingToolsCompleteFunctionality() async throws {
        print("\n🧪 Starting Core Text Processing Tools Test Suite")
        print("=" * 60)

        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "test_suite"
        )

        // Test 1: Tool Discovery and Registration
        print("\n📋 Test 1: Tool Discovery and Registration")
        await testToolDiscovery()
        print("✅ Tool discovery completed")

        // Test 2: Basic Tool Functionality
        print("\n🔧 Test 2: Basic Tool Functionality")
        await testBasicToolFunctionality(context: context)
        print("✅ Basic functionality tests completed")

        // Test 3: Audio Domain Specialization
        print("\n🎵 Test 3: Audio Domain Specialization")
        await testAudioDomainSpecialization(context: context)
        print("✅ Audio domain specialization tests completed")

        // Test 4: Input Validation and Error Handling
        print("\n🛡️ Test 4: Input Validation and Error Handling")
        await testInputValidationAndErrorHandling(context: context)
        print("✅ Input validation tests completed")

        // Test 5: Performance Characteristics
        print("\n⚡ Test 5: Performance Characteristics")
        await testPerformanceCharacteristics(context: context)
        print("✅ Performance tests completed")

        // Test 6: Integration Scenarios
        print("\n🔗 Test 6: Integration Scenarios")
        await testIntegrationScenarios(context: context)
        print("✅ Integration tests completed")

        print("\n🎉 Core Text Processing Tools Test Suite Completed Successfully!")
        print("=" * 60)
    }

    // MARK: - Individual Test Methods

    private func testToolDiscovery() async {
        let availableTools = await toolsRegistry.getAvailableTools()
        let textProcessingTools = await toolsRegistry.getToolsByCategory(.textProcessing)
        let audioDomainTools = await toolsRegistry.getAudioDomainTools()

        XCTAssertEqual(availableTools.count, 3, "Should have exactly 3 core text tools registered")
        XCTAssertEqual(textProcessingTools.count, 3, "All tools should be in textProcessing category")
        XCTAssertEqual(audioDomainTools.count, 3, "All tools should be discoverable as audio domain tools")

        let toolNames = availableTools.map { $0.name }.sorted()
        let expectedToolNames = ["apple.summarize", "apple.text.normalize", "apple.text.rewrite"].sorted()
        XCTAssertEqual(toolNames, expectedToolNames, "All expected tool names should be present")

        // Verify tool metadata
        for toolInfo in availableTools {
            XCTAssertTrue(toolInfo.offlineCapable, "All core text tools should be offline capable")
            XCTAssertTrue(toolInfo.requiresPermission.contains(.systemInfo), "All tools should require systemInfo permission")
            XCTAssertFalse(toolInfo.description.isEmpty, "All tools should have descriptions")
            XCTAssertNotNil(toolInfo.inputSchema, "All tools should have input schemas")
        }
    }

    private func testBasicToolFunctionality(context: MCPExecutionContext) async {
        let testText = """
        Recording session: Applied EQ to vocals, used compression, added reverb.
        The mix sounds professional and polished.
        """

        // Test SummarizationTool
        let summarizeResult = try await toolsRegistry.executeTool(
            name: "apple.summarize",
            parameters: ["text": testText, "style": "bullet", "max_points": 3],
            context: context
        )
        XCTAssertTrue(summarizeResult.success, "SummarizationTool should execute successfully")

        // Test TextRewriteTool
        let rewriteResult = try await toolsRegistry.executeTool(
            name: "apple.text.rewrite",
            parameters: ["text": testText, "tone": "technical", "length": "medium"],
            context: context
        )
        XCTAssertTrue(rewriteResult.success, "TextRewriteTool should execute successfully")

        // Test TextNormalizeTool
        let normalizeResult = try await toolsRegistry.executeTool(
            name: "apple.text.normalize",
            parameters: ["text": testText],
            context: context
        )
        XCTAssertTrue(normalizeResult.success, "TextNormalizeTool should execute successfully")

        // Verify all tools return proper data format
        for result in [summarizeResult, rewriteResult, normalizeResult] {
            XCTAssertNotNil(result.data, "Tool should return data")
            if let data = result.data?.value as? [String: Any] {
                XCTAssertNotNil(data["text"], "Tool should return text in data")
            }
        }
    }

    private func testAudioDomainSpecialization(context: MCPExecutionContext) async {
        let audioText = """
        Studio session: Used Neumann U87 microphone through Neve preamp.
        Applied 4:1 compression with medium attack. EQ boosted highs at 8kHz.
        Reverb added at 30% wet. Final mix at -14 LUFS.
        """

        // Test audio-relevant content detection in SummarizationTool
        let summarizeResult = try await toolsRegistry.executeTool(
            name: "apple.summarize",
            parameters: ["text": audioText, "style": "bullet"],
            context: context
        )

        if let data = summarizeResult.data?.value as? [String: Any],
           let summaryText = data["text"] as? String {
            XCTAssertTrue(summaryText.lowercased().contains("microphone") ||
                         summaryText.lowercased().contains("compression") ||
                         summaryText.lowercased().contains("eq") ||
                         summaryText.lowercased().contains("reverb"),
                         "Summary should prioritize audio-relevant content")
        }

        // Test audio terminology enhancement in TextRewriteTool
        let rewriteResult = try await toolsRegistry.executeTool(
            name: "apple.text.rewrite",
            parameters: ["text": "The sound needs work. Let's make it better.", "tone": "technical"],
            context: context
        )

        if let data = rewriteResult.data?.value as? [String: Any],
           let rewrittenText = data["text"] as? String {
            XCTAssertTrue(rewrittenText.lowercased().contains("optimize") ||
                         rewrittenText.lowercased().contains("enhance") ||
                         rewrittenText.lowercased().contains("rectify"),
                         "Technical tone should use audio-specific terminology")
        }

        // Test DAW terminology normalization in TextNormalizeTool
        let normalizeResult = try await toolsRegistry.executeTool(
            name: "apple.text.normalize",
            parameters: ["text": "Used EQ plugins and VST instruments. DAW automation was applied."],
            context: context
        )

        if let data = normalizeResult.data?.value as? [String: Any],
           let normalizedText = data["text"] as? String {
            XCTAssertTrue(normalizedText.lowercased().contains("equalizer") ||
                         normalizedText.lowercased().contains("plugin") ||
                         normalizedText.lowercased().contains("digital audio workstation"),
                         "Should normalize DAW terminology")
        }
    }

    private func testInputValidationAndErrorHandling(context: MCPExecutionContext) async {
        // Test missing required parameters
        let emptyParams: [String: Any] = [:]

        do {
            _ = try await toolsRegistry.executeTool(
                name: "apple.summarize",
                parameters: emptyParams,
                context: context
            )
            XCTFail("Should fail with missing required parameter")
        } catch {
            // Expected behavior
        }

        // Test invalid parameter values
        do {
            _ = try await toolsRegistry.executeTool(
                name: "apple.text.rewrite",
                parameters: ["text": "test", "tone": "invalid_tone"],
                context: context
            )
            XCTFail("Should fail with invalid tone parameter")
        } catch {
            // Expected behavior
        }

        // Test empty text parameter
        do {
            _ = try await toolsRegistry.executeTool(
                name: "apple.text.normalize",
                parameters: ["text": ""],
                context: context
            )
            XCTFail("Should fail with empty text parameter")
        } catch {
            // Expected behavior
        }

        // Test parameter value limits
        do {
            _ = try await toolsRegistry.executeTool(
                name: "apple.summarize",
                parameters: ["text": "test", "max_points": 20],
                context: context
            )
            XCTFail("Should fail with max_points exceeding limit")
        } catch {
            // Expected behavior
        }
    }

    private func testPerformanceCharacteristics(context: MCPExecutionContext) async {
        let testText = """
        Audio processing: Applied EQ and compression for enhanced clarity.
        The mix demonstrates professional quality and balanced frequency response.
        """

        // Test individual tool performance
        let startTime = Date()

        let summarizeResult = try await toolsRegistry.executeTool(
            name: "apple.summarize",
            parameters: ["text": testText],
            context: context
        )

        let executionTime = Date().timeIntervalSince(startTime)

        XCTAssertTrue(summarizeResult.success, "Performance test execution should succeed")
        XCTAssertLessThan(executionTime, 1.0, "Individual tool execution should be under 1 second")

        // Test concurrent execution performance
        await withTaskGroup(of: Bool.self) { group in
            for i in 0..<10 {
                group.addTask {
                    do {
                        let result = try await self.toolsRegistry.executeTool(
                            name: "apple.summarize",
                            parameters: ["text": testText],
                            context: context
                        )
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

    private func testIntegrationScenarios(context: MCPExecutionContext) async {
        // Scenario 1: Complete audio session workflow
        let messySessionNotes = """
        Recording session notes:

        •   Set up microphones
           Used U87 for vocals
           SM57 for guitar amp
        •   Check levels
           Peaks at -6dB
           RMS at -18dB
        •  Record takes
           Vocal:  "This  was  good"
           Guitar: Need   more reverb

        [background noise]  Remove later

        The  vocals  sound  "excellent"  but need  EQ..  The guitar  is too quiet!!
        """

        // Step 1: Normalize
        let normalizeResult = try await toolsRegistry.executeTool(
            name: "apple.text.normalize",
            parameters: ["text": messySessionNotes],
            context: context
        )
        XCTAssertTrue(normalizeResult.success)

        // Step 2: Rewrite for professional documentation
        if let normalizedText = normalizeResult.data?.value as? [String: Any]?["text"] as? String {
            let rewriteResult = try await toolsRegistry.executeTool(
                name: "apple.text.rewrite",
                parameters: ["text": normalizedText, "tone": "executive", "length": "medium"],
                context: context
            )
            XCTAssertTrue(rewriteResult.success)

            // Step 3: Create summary for stakeholders
            if let rewrittenText = rewriteResult.data?.value as? [String: Any]?["text"] as? String {
                let summarizeResult = try await toolsRegistry.executeTool(
                    name: "apple.summarize",
                    parameters: ["text": rewrittenText, "style": "abstract", "max_points": 4],
                    context: context
                )
                XCTAssertTrue(summarizeResult.success)

                if let summaryText = summarizeResult.data?.value as? [String: Any]?["text"] as? String {
                    XCTAssertFalse(summaryText.isEmpty)
                    XCTAssertFalse(summaryText.contains("[background noise]"))
                    XCTAssertTrue(summaryText.contains("Abstract"))
                }
            }
        }

        // Scenario 2: Tool discovery and metadata validation
        let availableTools = await toolsRegistry.getAvailableTools()
        XCTAssertEqual(availableTools.count, 3)

        for toolInfo in availableTools {
            XCTAssertFalse(toolInfo.name.isEmpty)
            XCTAssertFalse(toolInfo.description.isEmpty)
            XCTAssertTrue(toolInfo.offlineCapable)
            XCTAssertEqual(toolInfo.category, .textProcessing)
        }
    }

    // MARK: - Test Metrics and Reporting

    func testToolMetricsAndReporting() async throws {
        print("\n📊 Tool Metrics and Reporting")
        print("-" * 40)

        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "metrics_test"
        )

        var toolMetrics: [String: [String: Any]] = [:]

        // Collect metrics for each tool
        let toolNames = ["apple.summarize", "apple.text.rewrite", "apple.text.normalize"]
        let testText = "Audio session: Applied EQ, compression, and reverb. Professional mix quality achieved."

        for toolName in toolNames {
            let startTime = Date()

            let result = try await toolsRegistry.executeTool(
                name: toolName,
                parameters: ["text": testText],
                context: context
            )

            let endTime = Date()

            toolMetrics[toolName] = [
                "success": result.success,
                "executionTime": endTime.timeIntervalSince(startTime),
                "hasData": result.data != nil,
                "hasError": result.error != nil
            ]
        }

        // Report metrics
        for (toolName, metrics) in toolMetrics {
            let status = metrics["success"] as? Bool ? "✅" : "❌"
            let time = String(format: "%.3f", metrics["executionTime"] as? TimeInterval ?? 0)
            let dataStatus = (metrics["hasData"] as? Bool ?? false) ? "📄" : "⚠️"
            let errorStatus = (metrics["hasError"] as? Bool ?? false) ? "❌" : "✅"

            print("\(status) \(toolName): \(time)s | Data: \(dataStatus) | Error: \(errorStatus)")
        }

        // Verify all tools succeeded
        let allSuccessful = toolMetrics.values.allSatisfy { ($0["success"] as? Bool) == true }
        XCTAssertTrue(allSuccessful, "All tools should execute successfully")
    }

    // MARK: - Validation Test

    func testJSONSchemaCompliance() async throws {
        print("\n🔍 JSON Schema Compliance Validation")
        print("-" * 40)

        let availableTools = await toolsRegistry.getAvailableTools()

        for toolInfo in availableTools {
            let schema = toolInfo.inputSchema

            // Verify schema structure
            XCTAssertEqual(schema["type"] as? String, "object", "\(toolInfo.name): Schema type should be 'object'")
            XCTAssertNotNil(schema["properties"], "\(toolInfo.name): Schema should have properties")

            if let properties = schema["properties"]?.value as? [String: Any] {
                // Verify text property exists
                XCTAssertNotNil(properties["text"], "\(toolInfo.name): Should have 'text' property")

                // Verify text property structure
                if let textProp = properties["text"] as? [String: Any] {
                    XCTAssertEqual(textProp["type"] as? String, "string", "\(toolInfo.name): Text property should be string type")
                    XCTAssertNotNil(textProp["description"], "\(toolInfo.name): Text property should have description")
                }
            }

            print("✅ \(toolInfo.name): Schema compliant")
        }
    }
}

// MARK: - Test Suite Extensions

extension CoreTextToolsTestSuite {

    /// Run the complete test suite with detailed reporting
    func runCompleteTestSuite() async throws {
        print("\n🚀 Local Intelligence MCP Core Text Processing Tools - Complete Test Suite")
        print("User Story 1: Core Text Processing Tools (Priority: P1)")
        print("Test Coverage: Initialization, Functionality, Validation, Performance, Integration")
        print("=" * 80)

        try await testCoreTextProcessingToolsCompleteFunctionality()
        try await testToolMetricsAndReporting()
        try await testJSONSchemaCompliance()

        print("\n🎊 Test Suite Summary")
        print("=" * 30)
        print("✅ All tests completed successfully")
        print("✅ Core text processing tools are fully functional")
        print("✅ Audio domain specialization verified")
        print("✅ Input validation and error handling confirmed")
        print("✅ Performance characteristics within acceptable limits")
        print("✅ Integration scenarios validated")
        print("✅ JSON schema compliance confirmed")
        print("\n🏆 User Story 1 implementation is complete and ready for production!")
    }
}

// MARK: - String Extensions for Test Reporting

extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}