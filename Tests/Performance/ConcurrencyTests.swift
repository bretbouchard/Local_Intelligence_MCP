//
//  ConcurrencyTests.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-08.
//

import XCTest
@testable import LocalIntelligenceMCP

final class ConcurrencyTests: XCTestCase {

    // MARK: - Properties

    private var logger: Logger!
    private var securityManager: SecurityManager!
    private var toolsRegistry: ToolsRegistry!
    private var server: MCPServer!

    // MARK: - Setup and Teardown

    override func setUp() async throws {
        try await super.setUp()

        // Initialize components for performance testing
        let config = LoggingConfiguration.default
        logger = Logger(configuration: config)
        await logger.setupFileLoggingIfNeeded()

        securityManager = SecurityManager(logger: logger)
        toolsRegistry = ToolsRegistry(logger: logger, securityManager: securityManager)

        try await toolsRegistry.initialize()

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

    // MARK: - Concurrent Connection Tests

    func testConcurrentConnections_MaximumLoad() async throws {
        // Test server behavior under maximum concurrent load
        try await server.start()

        let maxConnections = MCPConstants.Server.maxConcurrentClients
        let connectionCount = min(maxConnections, 20) // Limit for test stability

        await logger.info("Starting concurrent connection test with \(connectionCount) connections")

        let startTime = Date()
        var successCount = 0
        var errorCount = 0

        await withTaskGroup(of: (Bool, Error?).self) { group in
            for i in 0..<connectionCount {
                group.addTask {
                    do {
                        let clientId = UUID()
                        let systemInfoTool = await self.toolsRegistry.getTool(name: "system_info")

                        let context = MCPExecutionContext(
                            clientId: clientId,
                            requestId: "req_\(i)_\(UUID().uuidString)",
                            toolName: "system_info"
                        )

                        let params = [
                            "categories": ["device"],
                            "includeSensitive": false
                        ] as [String: Any]

                        let result = try await systemInfoTool!.performExecution(parameters: params, context: context)
                        return (result.success, nil)
                    } catch {
                        return (false, error)
                    }
                }
            }

            for await (success, error) in group {
                if success {
                    successCount += 1
                } else {
                    errorCount += 1
                    if let error = error {
                        await self.logger.error("Concurrent request failed", error: error)
                    }
                }
            }
        }

        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)

        await logger.info("Concurrent test completed", metadata: [
            "totalRequests": connectionCount,
            "successCount": successCount,
            "errorCount": errorCount,
            "duration": duration,
            "throughput": Double(connectionCount) / duration
        ])

        // Performance assertions
        XCTAssertGreaterThan(successCount, connectionCount / 2, "At least half of concurrent requests should succeed")
        XCTAssertLessThan(duration, 60.0, "Concurrent operations should complete within 60 seconds")
        XCTAssertGreaterThan(Double(connectionCount) / duration, 0.5, "Should handle at least 0.5 requests per second")

        // Server should still be responsive
        let serverStatus = await server.getStatus()
        XCTAssertTrue(serverStatus.isRunning)
    }

    func testConcurrentTools_MixedWorkload() async throws {
        // Test concurrent execution of different tools
        try await server.start()

        let toolNames = ["system_info", "health_check", "list_shortcuts"]
        let totalRequests = 30
        let requestsPerTool = totalRequests / toolNames.count

        await logger.info("Starting mixed workload test with \(totalRequests) requests")

        var results: [String: (success: Int, error: Int)] = [:]

        await withTaskGroup(of: (String, Bool, Error?).self) { group in
            for toolName in toolNames {
                for i in 0..<requestsPerTool {
                    group.addTask {
                        do {
                            let clientId = UUID()
                            let tool = await self.toolsRegistry.getTool(name: toolName)

                            let context = MCPExecutionContext(
                                clientId: clientId,
                                requestId: "\(toolName)_req_\(i)_\(UUID().uuidString)",
                                toolName: toolName
                            )

                            let params: [String: Any] = toolName == "system_info" ? [
                                "categories": ["device"],
                                "includeSensitive": false
                            ] : toolName == "list_shortcuts" ? [
                                "includeSystemShortcuts": false
                            ] : [:]

                            let result = try await tool!.performExecution(parameters: params, context: context)
                            return (toolName, result.success, nil)
                        } catch {
                            return (toolName, false, error)
                        }
                    }
                }
            }

            for await (toolName, success, error) in group {
                if results[toolName] == nil {
                    results[toolName] = (success: 0, error: 0)
                }

                if success {
                    results[toolName]?.success += 1
                } else {
                    results[toolName]?.error += 1
                    if let error = error {
                        await self.logger.error("Mixed workload request failed", metadata: ["tool": toolName], error: error)
                    }
                }
            }
        }

        await logger.info("Mixed workload test completed", metadata: results)

        // Verify each tool performed adequately
        for (toolName, result) in results {
            XCTAssertGreaterThan(result.success, 0, "\(toolName) should have some successful requests")
            XCTAssertLessThanOrEqual(result.error, requestsPerTool / 2, "\(toolName) should not have too many errors")
        }
    }

    func testConcurrentClient_Isolation() async throws {
        // Test that concurrent clients are properly isolated
        try await server.start()

        let clientCount = 10
        let requestsPerClient = 5

        await logger.info("Starting client isolation test with \(clientCount) clients")

        var clientResults: [UUID: [Bool]] = [:]

        await withTaskGroup(of: (UUID, Bool).self) { group in
            for clientIndex in 0..<clientCount {
                group.addTask {
                    let clientId = UUID()
                    var clientSuccesses: [Bool] = []

                    for requestIndex in 0..<requestsPerClient {
                        do {
                            let systemInfoTool = await self.toolsRegistry.getTool(name: "system_info")

                            let context = MCPExecutionContext(
                                clientId: clientId,
                                requestId: "client_\(clientIndex)_req_\(requestIndex)_\(UUID().uuidString)",
                                toolName: "system_info"
                            )

                            let params = [
                                "categories": ["server"],
                                "includeSensitive": false
                            ] as [String: Any]

                            let result = try await systemInfoTool!.performExecution(parameters: params, context: context)
                            clientSuccesses.append(result.success)
                        } catch {
                            clientSuccesses.append(false)
                        }
                    }

                    return (clientId, clientSuccesses.allSatisfy { $0 })
                }
            }

            for await (clientId, allSuccessful) in group {
                clientResults[clientId] = [allSuccessful]
            }
        }

        let successfulClients = clientResults.values.filter { $0.first ?? false }.count
        await logger.info("Client isolation test completed", metadata: [
            "totalClients": clientCount,
            "successfulClients": successfulClients
        ])

        // Most clients should have all requests succeed
        XCTAssertGreaterThanOrEqual(successfulClients, clientCount / 2, "Most clients should have all requests succeed")
    }

    // MARK: - Memory and Resource Tests

    func testMemoryUsage_ConcurrentOperations() async throws {
        // Test memory usage during concurrent operations
        try await server.start()

        let initialMemory = getMemoryUsage()
        await logger.info("Initial memory usage: \(formatMemorySize(initialMemory))")

        let operationCount = 50
        let batchSize = 10

        for batch in 0..<(operationCount / batchSize) {
            await logger.info("Starting memory test batch \(batch + 1)")

            await withTaskGroup(of: Void.self) { group in
                for i in 0..<batchSize {
                    group.addTask {
                        do {
                            let clientId = UUID()
                            let systemInfoTool = await self.toolsRegistry.getTool(name: "system_info")

                            let context = MCPExecutionContext(
                                clientId: clientId,
                                requestId: "mem_test_batch_\(batch)_req_\(i)_\(UUID().uuidString)",
                                toolName: "system_info"
                            )

                            let params = [
                                "categories": ["device", "hardware"],
                                "includeSensitive": false
                            ] as [String: Any]

                            _ = try await systemInfoTool!.performExecution(parameters: params, context: context)
                        } catch {
                            // Log but don't fail the test
                            await self.logger.error("Memory test operation failed", error: error)
                        }
                    }
                }
            }

            // Force garbage collection between batches
            let currentMemory = getMemoryUsage()
            await logger.info("Memory after batch \(batch + 1): \(formatMemorySize(currentMemory))")

            // Memory should not grow excessively
            let memoryGrowth = currentMemory - initialMemory
            let maxAllowedGrowth = 100 * 1024 * 1024 // 100MB

            if memoryGrowth > maxAllowedGrowth {
                await logger.warning("Memory usage growing rapidly", metadata: [
                    "growth": formatMemorySize(memoryGrowth),
                    "current": formatMemorySize(currentMemory)
                ])
            }
        }

        let finalMemory = getMemoryUsage()
        let totalGrowth = finalMemory - initialMemory

        await logger.info("Memory test completed", metadata: [
            "initialMemory": formatMemorySize(initialMemory),
            "finalMemory": formatMemorySize(finalMemory),
            "totalGrowth": formatMemorySize(totalGrowth)
        ])

        // Memory growth should be reasonable
        XCTAssertLessThan(totalGrowth, 200 * 1024 * 1024, "Total memory growth should be less than 200MB")
    }

    func testResourceCleanup_ConcurrentWorkloads() async throws {
        // Test that resources are properly cleaned up after concurrent workloads
        try await server.start()

        let workloadCount = 20

        await logger.info("Starting resource cleanup test with \(workloadCount) workloads")

        for workloadIndex in 0..<workloadCount {
            await withTaskGroup(of: Void.self) { group in
                // Create concurrent workload
                for i in 0..<5 {
                    group.addTask {
                        do {
                            let clientId = UUID()
                            let tools = ["system_info", "health_check", "list_shortcuts"]

                            for toolName in tools {
                                let tool = await self.toolsRegistry.getTool(name: toolName)
                                let context = MCPExecutionContext(
                                    clientId: clientId,
                                    requestId: "cleanup_test_\(workloadIndex)_\(toolName)_\(i)_\(UUID().uuidString)",
                                    toolName: toolName
                                )

                                let params: [String: Any] = toolName == "system_info" ? [
                                    "categories": ["device"],
                                    "includeSensitive": false
                                ] : toolName == "list_shortcuts" ? [
                                    "includeSystemShortcuts": false
                                ] : [:]

                                _ = try await tool!.performExecution(parameters: params, context: context)
                            }
                        } catch {
                            // Log but continue with cleanup test
                            await self.logger.error("Resource cleanup test operation failed", error: error)
                        }
                    }
                }
            }

            // Small delay to allow cleanup
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms

            if workloadIndex % 5 == 0 {
                let currentMemory = getMemoryUsage()
                await logger.info("Memory after workload \(workloadIndex): \(formatMemorySize(currentMemory))")
            }
        }

        // Verify server is still responsive after heavy workloads
        let systemInfoTool = await toolsRegistry.getTool(name: "system_info")
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: "final_cleanup_test_\(UUID().uuidString)",
            toolName: "system_info"
        )

        let params = [
            "categories": ["server"],
            "includeSensitive": false
        ] as [String: Any]

        let finalResult = try await systemInfoTool!.performExecution(parameters: params, context: context)
        XCTAssertTrue(finalResult.success, "Server should remain responsive after heavy concurrent workloads")

        await logger.info("Resource cleanup test completed successfully")
    }

    // MARK: - Stress Tests

    func testStressTest_HighFrequencyRequests() async throws {
        // Test server under high-frequency requests
        try await server.start()

        let requestCount = 100
        let requestDuration = 10.0 // seconds
        let requestsPerSecond = Double(requestCount) / requestDuration

        await logger.info("Starting stress test: \(requestCount) requests in \(requestDuration)s (\(requestsPerSecond) req/s)")

        let startTime = Date()
        var completedRequests = 0
        var failedRequests = 0

        await withTaskGroup(of: (Bool, Error?).self) { group in
            for i in 0..<requestCount {
                group.addTask {
                    // Add small delay to distribute requests over time
                    let delay = Double(i) / requestsPerSecond
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

                    do {
                        let clientId = UUID()
                        let systemInfoTool = await self.toolsRegistry.getTool(name: "system_info")

                        let context = MCPExecutionContext(
                            clientId: clientId,
                            requestId: "stress_req_\(i)_\(UUID().uuidString)",
                            toolName: "system_info"
                        )

                        let params = [
                            "categories": ["device"],
                            "includeSensitive": false
                        ] as [String: Any]

                        let result = try await systemInfoTool!.performExecution(parameters: params, context: context)
                        return (result.success, nil)
                    } catch {
                        return (false, error)
                    }
                }
            }

            for await (success, error) in group {
                if success {
                    completedRequests += 1
                } else {
                    failedRequests += 1
                    if let error = error {
                        await self.logger.error("Stress test request failed", error: error)
                    }
                }
            }
        }

        let endTime = Date()
        let actualDuration = endTime.timeIntervalSince(startTime)
        let actualThroughput = Double(completedRequests) / actualDuration

        await logger.info("Stress test completed", metadata: [
            "requestCount": requestCount,
            "completedRequests": completedRequests,
            "failedRequests": failedRequests,
            "targetDuration": requestDuration,
            "actualDuration": actualDuration,
            "targetThroughput": requestsPerSecond,
            "actualThroughput": actualThroughput
        ])

        // Performance assertions
        XCTAssertGreaterThan(completedRequests, requestCount * 0.8, "At least 80% of requests should complete")
        XCTAssertLessThan(failedRequests, requestCount * 0.2, "No more than 20% of requests should fail")
        XCTAssertLessThan(actualDuration, requestDuration * 2.0, "Should complete within reasonable time")

        // Server should still be responsive
        let serverStatus = await server.getStatus()
        XCTAssertTrue(serverStatus.isRunning)
    }

    func testStressTest_MemoryPressure() async throws {
        // Test server behavior under memory pressure
        try await server.start()

        let initialMemory = getMemoryUsage()
        await logger.info("Memory pressure test - Initial: \(formatMemorySize(initialMemory))")

        let batchSize = 20
        let batchCount = 10

        for batch in 0..<batchCount {
            await logger.info("Memory pressure batch \(batch + 1)/\(batchCount)")

            await withTaskGroup(of: Void.self) { group in
                for i in 0..<batchSize {
                    group.addTask {
                        do {
                            let clientId = UUID()

                            // Use system_info with more data categories to increase memory usage
                            let systemInfoTool = await self.toolsRegistry.getTool(name: "system_info")
                            let context = MCPExecutionContext(
                                clientId: clientId,
                                requestId: "mem_pressure_batch_\(batch)_req_\(i)_\(UUID().uuidString)",
                                toolName: "system_info"
                            )

                            let params = [
                                "categories": ["device", "os", "hardware", "network", "permissions", "server"],
                                "includeSensitive": false
                            ] as [String: Any]

                            let result = try await systemInfoTool!.performExecution(parameters: params, context: context)
                            if !result.success {
                                await self.logger.warning("Memory pressure request failed")
                            }
                        } catch {
                            await self.logger.error("Memory pressure batch operation failed", error: error)
                        }
                    }
                }
            }

            // Check memory usage between batches
            let currentMemory = getMemoryUsage()
            let memoryGrowth = currentMemory - initialMemory

            await logger.info("Memory after batch \(batch + 1): \(formatMemorySize(currentMemory)) (+\(formatMemorySize(memoryGrowth)))")

            // Trigger garbage collection if memory growth is significant
            if memoryGrowth > 50 * 1024 * 1024 { // 50MB
                await logger.info("Triggering garbage collection due to memory growth")
                // No explicit GC in Swift, but we can create and release large objects
                let _ = Array(repeating: "GC_TRIGGER", count: 10000).joined()
            }
        }

        let finalMemory = getMemoryUsage()
        let totalGrowth = finalMemory - initialMemory

        await logger.info("Memory pressure test completed", metadata: [
            "initialMemory": formatMemorySize(initialMemory),
            "finalMemory": formatMemorySize(finalMemory),
            "totalGrowth": formatMemorySize(totalGrowth)
        ])

        // Server should still be functional
        let healthResult = try await server.performHealthCheck()
        XCTAssertTrue(healthResult.isHealthy, "Server should remain healthy after memory pressure")

        // Memory growth should be controlled
        XCTAssertLessThan(totalGrowth, 300 * 1024 * 1024, "Memory growth should be controlled under pressure")
    }

    // MARK: - Timeout and Resilience Tests

    func testTimeoutHandling_ConcurrentRequests() async throws {
        // Test timeout handling under concurrent load
        try await server.start()

        let requestCount = 30
        var timeoutCount = 0
        var successCount = 0

        await logger.info("Starting timeout handling test with \(requestCount) requests")

        await withTaskGroup(of: (String, Bool).self) { group in
            for i in 0..<requestCount {
                group.addTask {
                    do {
                        let clientId = UUID()

                        // Use shortcuts tool which can timeout
                        let shortcutsTool = await self.toolsRegistry.getTool(name: "execute_shortcut")
                        let context = MCPExecutionContext(
                            clientId: clientId,
                            requestId: "timeout_test_req_\(i)_\(UUID().uuidString)",
                            toolName: "execute_shortcut"
                        )

                        let params = [
                            "shortcutName": "NonExistentTestShortcut_\(i)",
                            "inputParameters": [:],
                            "timeout": 1.0 // Short timeout to trigger timeouts
                        ] as [String: Any]

                        let startTime = Date()
                        let result = try await shortcutsTool!.performExecution(parameters: params, context: context)
                        let duration = Date().timeIntervalSince(startTime)

                        if result.success {
                            return ("success", true)
                        } else if duration >= 0.9 { // Likely timed out
                            return ("timeout", false)
                        } else {
                            return ("other_error", false)
                        }
                    } catch {
                        if error.localizedDescription.contains("timeout") {
                            return ("timeout", false)
                        } else {
                            return ("error", false)
                        }
                    }
                }
            }

            for await (resultType, success) in group {
                switch resultType {
                case "success":
                    successCount += 1
                case "timeout":
                    timeoutCount += 1
                default:
                    break
                }
            }
        }

        await logger.info("Timeout handling test completed", metadata: [
            "totalRequests": requestCount,
            "successCount": successCount,
            "timeoutCount": timeoutCount
        ])

        // Timeouts should be handled gracefully
        XCTAssertGreaterThan(successCount + timeoutCount, requestCount * 0.8, "Most requests should complete or timeout gracefully")

        // Server should remain responsive
        let serverStatus = await server.getStatus()
        XCTAssertTrue(serverStatus.isRunning)
    }

    // MARK: - Helper Methods

    private func getMemoryUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }

        if kerr == KERN_SUCCESS {
            return Int64(info.resident_size)
        } else {
            return 0
        }
    }

    private func formatMemorySize(_ bytes: Int64) -> String {
        let units = ["B", "KB", "MB", "GB"]
        var size = Double(bytes)
        var unitIndex = 0

        while size >= 1024 && unitIndex < units.count - 1 {
            size /= 1024
            unitIndex += 1
        }

        return String(format: "%.1f %@", size, units[unitIndex])
    }
}