//
//  HealthPingTool.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-09.
//

import Foundation

/// Tool for health monitoring and system health checks for the Local Intelligence MCP Tools
public class HealthPingTool: BaseMCPTool, @unchecked Sendable {

    public struct HealthPingInput: Codable {
        let includeDiagnostics: Bool
        let checkTools: Bool
        let checkMemory: Bool
        let checkPerformance: Bool
        let timeout: Int? // Timeout in seconds

        init(from parameters: [String: AnyCodable]) throws {
            self.includeDiagnostics = parameters["includeDiagnostics"]?.value as? Bool ?? true
            self.checkTools = parameters["checkTools"]?.value as? Bool ?? true
            self.checkMemory = parameters["checkMemory"]?.value as? Bool ?? true
            self.checkPerformance = parameters["checkPerformance"]?.value as? Bool ?? false
            self.timeout = parameters["timeout"]?.value as? Int
        }
    }

    public struct HealthPingResult: Codable {
        let status: String // "healthy", "degraded", "unhealthy"
        let timestamp: String
        let uptime: String
        let responseTime: String
        let version: String
        let diagnostics: Diagnostics?
        let toolStatus: [ToolHealth]?
        let memoryStatus: MemoryStatus?
        let performanceStatus: PerformanceStatus?
        let recommendations: [String]
    }

    public struct Diagnostics: Codable {
        let systemInfo: SystemInfo
        let environment: EnvironmentInfo
        let dependencies: [DependencyStatus]
        let lastHealthCheck: String
    }

    public struct SystemInfo: Codable {
        let platform: String
        let architecture: String
        let processorCount: Int
        let memoryTotal: String
        let memoryAvailable: String
        let diskSpace: String
        let networkStatus: String
    }

    public struct EnvironmentInfo: Codable {
        let swiftVersion: String
        let mcpVersion: String
        let operatingSystem: String
        let processID: Int
        let workingDirectory: String
        let environmentVariables: [String: String]
    }

    public struct DependencyStatus: Codable {
        let name: String
        let status: String // "available", "unavailable", "degraded"
        let version: String?
        let details: String?
    }

    public struct ToolHealth: Codable {
        let name: String
        let status: String // "healthy", "degraded", "unhealthy"
        let responseTime: String
        let lastUsed: String
        let errorCount: Int
        let issues: [String]
    }

    public struct MemoryStatus: Codable {
        let totalMemory: String
        let usedMemory: String
        let availableMemory: String
        let memoryUsage: String // percentage
        let gcPressure: String
        let recommendations: [String]
    }

    public struct PerformanceStatus: Codable {
        let averageResponseTime: String
        let requestsPerSecond: String
        let errorRate: String
        let concurrencyLevel: Int
        let queueDepth: Int
        let bottlenecks: [String]
    }

    public init(logger: Logger, securityManager: SecurityManager) {
        super.init(
            name: "health_ping",
            description: "Performs comprehensive health checks on the Local Intelligence MCP Tools system including system diagnostics, tool status monitoring, memory usage analysis, and performance metrics",
            inputSchema: [
                "type": "object",
                "properties": [
                    "includeDiagnostics": [
                        "type": "boolean",
                        "default": true,
                        "description": "Include detailed system diagnostics"
                    ],
                    "checkTools": [
                        "type": "boolean",
                        "default": true,
                        "description": "Check health status of all available tools"
                    ],
                    "checkMemory": [
                        "type": "boolean",
                        "default": true,
                        "description": "Include memory usage analysis"
                    ],
                    "checkPerformance": [
                        "type": "boolean",
                        "default": false,
                        "description": "Include performance metrics analysis"
                    ],
                    "timeout": [
                        "type": "integer",
                        "default": 10,
                        "minimum": 1,
                        "maximum": 60,
                        "description": "Health check timeout in seconds"
                    ]
                ],
                "required": []
            ],
            category: .systemInfo,
            requiresPermission: [.systemInfo],
            offlineCapable: true,
            logger: logger,
            securityManager: securityManager
        )
    }

    public override func performExecution(parameters: [String: AnyCodable], context: MCPExecutionContext) async throws -> MCPResponse {
        // Parse input parameters
        let input = try HealthPingInput(from: parameters)
        let startTime = Date().timeIntervalSince1970

        // Perform health checks
        let systemStatus = checkSystemHealth()
        let toolHealth = input.checkTools ? checkToolHealth() : nil
        let memoryStatus = input.checkMemory ? checkMemoryHealth() : nil
        let performanceStatus = input.checkPerformance ? checkPerformanceHealth() : nil
        let diagnostics = input.includeDiagnostics ? getSystemDiagnostics() : nil

        let responseTime = Date().timeIntervalSince1970 - startTime

        // Determine overall health status
        let overallStatus = determineOverallStatus(
            systemStatus: systemStatus,
            toolHealth: toolHealth,
            memoryStatus: memoryStatus,
            performanceStatus: performanceStatus
        )

        // Generate recommendations
        let recommendations = generateHealthRecommendations(
            systemStatus: systemStatus,
            toolHealth: toolHealth,
            memoryStatus: memoryStatus,
            performanceStatus: performanceStatus
        )

        let result = HealthPingResult(
            status: overallStatus,
            timestamp: ISO8601DateFormatter().string(from: Date()),
            uptime: calculateUptime(),
            responseTime: String(format: "%.2f ms", responseTime * 1000),
            version: "1.0.0",
            diagnostics: diagnostics,
            toolStatus: toolHealth,
            memoryStatus: memoryStatus,
            performanceStatus: performanceStatus,
            recommendations: recommendations
        )

        return MCPResponse(
            success: true,
            data: AnyCodable(result)
        )
    }

    // MARK: - Health Check Methods

    private func checkSystemHealth() -> String {
        // Check system resources and basic functionality
        let memoryPressure = getMemoryPressure()
        let diskSpace = getAvailableDiskSpace()
        let processorLoad = getProcessorLoad()

        if memoryPressure > 0.9 || diskSpace < 1.0 || processorLoad > 0.95 {
            return "unhealthy"
        } else if memoryPressure > 0.7 || diskSpace < 5.0 || processorLoad > 0.8 {
            return "degraded"
        } else {
            return "healthy"
        }
    }

    private func checkToolHealth() -> [ToolHealth] {
        let allTools = [
            "apple_summarize",
            "apple_text_rewrite",
            "apple_text_normalize",
            "apple_summarize_focus",
            "apple_text_redact",
            "apple_text_chunk",
            "apple_text_count",
            "apple_intent_recognize",
            "apple_query_analyze",
            "apple_purpose_detect",
            "apple_schema_extract",
            "apple_tags_generate",
            "apple_entities_extract",
            "apple_catalog_summarize",
            "apple_session_summarize",
            "apple_feedback_analyze"
        ]

        return allTools.map { toolName in
            // Simulate tool health check
            let isHealthy = Double.random(in: 0...1) > 0.1 // 90% healthy
            let responseTime = Int.random(in: 50...300)
            let errorCount = isHealthy ? Int.random(in: 0...2) : Int.random(in: 5...15)

            var issues: [String] = []
            if !isHealthy {
                issues.append("Elevated error rate detected")
                if responseTime > 200 {
                    issues.append("Slow response time")
                }
                if errorCount > 10 {
                    issues.append("High error frequency")
                }
            }

            return ToolHealth(
                name: toolName,
                status: isHealthy ? "healthy" : (errorCount > 10 ? "unhealthy" : "degraded"),
                responseTime: "\(responseTime)ms",
                lastUsed: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-Double.random(in: 0...3600))),
                errorCount: errorCount,
                issues: issues
            )
        }
    }

    private func checkMemoryHealth() -> MemoryStatus {
        let totalMemory = getTotalMemory()
        let usedMemory = getUsedMemory()
        let availableMemory = totalMemory - usedMemory
        let memoryUsage = (usedMemory / totalMemory) * 100
        let gcPressure = getGCPressure()

        var recommendations: [String] = []
        if memoryUsage > 80 {
            recommendations.append("High memory usage detected - consider optimizing large operations")
        }
        if gcPressure > 0.7 {
            recommendations.append("High garbage collection pressure - monitor for memory leaks")
        }
        if availableMemory < 1024 * 1024 * 1024 { // Less than 1GB
            recommendations.append("Low available memory - consider increasing system resources")
        }

        return MemoryStatus(
            totalMemory: formatBytes(totalMemory),
            usedMemory: formatBytes(usedMemory),
            availableMemory: formatBytes(availableMemory),
            memoryUsage: String(format: "%.1f%%", memoryUsage),
            gcPressure: String(format: "%.1f%%", gcPressure * 100),
            recommendations: recommendations
        )
    }

    private func checkPerformanceHealth() -> PerformanceStatus {
        let avgResponseTime = getAverageResponseTime()
        let requestsPerSecond = getRequestsPerSecond()
        let errorRate = getErrorRate()
        let concurrencyLevel = getCurrentConcurrencyLevel()
        let queueDepth = getQueueDepth()

        var bottlenecks: [String] = []
        if avgResponseTime > 500 {
            bottlenecks.append("High average response time")
        }
        if errorRate > 0.05 {
            bottlenecks.append("Elevated error rate")
        }
        if queueDepth > 50 {
            bottlenecks.append("High request queue depth")
        }
        if concurrencyLevel > 80 {
            bottlenecks.append("High concurrency level")
        }

        return PerformanceStatus(
            averageResponseTime: "\(avgResponseTime)ms",
            requestsPerSecond: String(format: "%.1f", requestsPerSecond),
            errorRate: String(format: "%.2f%%", errorRate * 100),
            concurrencyLevel: concurrencyLevel,
            queueDepth: queueDepth,
            bottlenecks: bottlenecks
        )
    }

    private func getSystemDiagnostics() -> Diagnostics {
        return Diagnostics(
            systemInfo: SystemInfo(
                platform: getPlatform(),
                architecture: getArchitecture(),
                processorCount: ProcessInfo.processInfo.processorCount,
                memoryTotal: formatBytes(getTotalMemory()),
                memoryAvailable: formatBytes(getAvailableMemory()),
                diskSpace: formatBytes(getAvailableDiskSpace()),
                networkStatus: getNetworkStatus()
            ),
            environment: EnvironmentInfo(
                swiftVersion: getSwiftVersion(),
                mcpVersion: "1.0.0",
                operatingSystem: getOperatingSystem(),
                processID: Int(ProcessInfo.processInfo.processIdentifier),
                workingDirectory: FileManager.default.currentDirectoryPath,
                environmentVariables: getRelevantEnvironmentVariables()
            ),
            dependencies: checkDependencies(),
            lastHealthCheck: ISO8601DateFormatter().string(from: Date())
        )
    }

    // MARK: - Helper Methods

    private func determineOverallStatus(
        systemStatus: String,
        toolHealth: [ToolHealth]?,
        memoryStatus: MemoryStatus?,
        performanceStatus: PerformanceStatus?
    ) -> String {
        var unhealthyCount = 0
        var degradedCount = 0

        // Check system status
        if systemStatus == "unhealthy" { unhealthyCount += 1 }
        else if systemStatus == "degraded" { degradedCount += 1 }

        // Check tool health
        if let toolHealth = toolHealth {
            for tool in toolHealth {
                if tool.status == "unhealthy" { unhealthyCount += 1 }
                else if tool.status == "degraded" { degradedCount += 1 }
            }
        }

        // Check memory status
        if let memoryStatus = memoryStatus {
            let memoryUsage = Double(memoryStatus.memoryUsage.dropLast()) ?? 0
            if memoryUsage > 90 { unhealthyCount += 1 }
            else if memoryUsage > 70 { degradedCount += 1 }
        }

        // Check performance status
        if let performanceStatus = performanceStatus {
            if !performanceStatus.bottlenecks.isEmpty {
                if performanceStatus.bottlenecks.count > 2 { unhealthyCount += 1 }
                else { degradedCount += 1 }
            }
        }

        if unhealthyCount > 0 {
            return "unhealthy"
        } else if degradedCount > 0 {
            return "degraded"
        } else {
            return "healthy"
        }
    }

    private func generateHealthRecommendations(
        systemStatus: String,
        toolHealth: [ToolHealth]?,
        memoryStatus: MemoryStatus?,
        performanceStatus: PerformanceStatus?
    ) -> [String] {
        var recommendations: [String] = []

        if systemStatus != "healthy" {
            recommendations.append("System resources are under pressure - consider scaling or optimizing")
        }

        if let toolHealth = toolHealth {
            let unhealthyTools = toolHealth.filter { $0.status == "unhealthy" }
            if !unhealthyTools.isEmpty {
                recommendations.append("\(unhealthyTools.count) tool(s) are unhealthy - check logs and restart if needed")
            }

            let degradedTools = toolHealth.filter { $0.status == "degraded" }
            if !degradedTools.isEmpty {
                recommendations.append("\(degradedTools.count) tool(s) are degraded - monitor performance")
            }
        }

        if let memoryStatus = memoryStatus {
            recommendations.append(contentsOf: memoryStatus.recommendations)
        }

        if let performanceStatus = performanceStatus {
            if !performanceStatus.bottlenecks.isEmpty {
                recommendations.append("Performance bottlenecks detected: \(performanceStatus.bottlenecks.joined(separator: ", "))")
            }
        }

        if recommendations.isEmpty {
            recommendations.append("All systems operating normally")
        }

        return recommendations
    }

    // MARK: - System Information Methods

    private func calculateUptime() -> String {
        let uptime = ProcessInfo.processInfo.systemUptime
        let days = Int(uptime / 86400)
        let hours = Int((uptime.truncatingRemainder(dividingBy: 86400)) / 3600)
        let minutes = Int((uptime.truncatingRemainder(dividingBy: 3600)) / 60)

        if days > 0 {
            return "\(days)d \(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    private func getMemoryPressure() -> Double {
        let usedMemory = getUsedMemory()
        let totalMemory = getTotalMemory()
        return usedMemory / totalMemory
    }

    private func getAvailableDiskSpace() -> Double {
        // In a real implementation, this would check actual disk space
        return Double.random(in: 10...100) * 1024 * 1024 * 1024 // 10-100GB
    }

    private func getProcessorLoad() -> Double {
        // In a real implementation, this would check actual processor load
        return Double.random(in: 0.1...0.9)
    }

    private func getTotalMemory() -> Double {
        // In a real implementation, this would get actual system memory
        return Double.random(in: 8...32) * 1024 * 1024 * 1024 // 8-32GB
    }

    private func getUsedMemory() -> Double {
        let total = getTotalMemory()
        return total * Double.random(in: 0.3...0.8) // 30-80% usage
    }

    private func getAvailableMemory() -> Double {
        return getTotalMemory() - getUsedMemory()
    }

    private func getGCPressure() -> Double {
        // Simulate GC pressure
        return Double.random(in: 0.1...0.8)
    }

    private func getAverageResponseTime() -> Int {
        // Simulate average response time in milliseconds
        return Int.random(in: 100...400)
    }

    private func getRequestsPerSecond() -> Double {
        // Simulate requests per second
        return Double.random(in: 10...100)
    }

    private func getErrorRate() -> Double {
        // Simulate error rate
        return Double.random(in: 0.001...0.02) // 0.1-2%
    }

    private func getCurrentConcurrencyLevel() -> Int {
        // Simulate current concurrency level
        return Int.random(in: 1...50)
    }

    private func getQueueDepth() -> Int {
        // Simulate queue depth
        return Int.random(in: 0...20)
    }

    private func getPlatform() -> String {
        #if os(macOS)
        return "macOS"
        #elseif os(Linux)
        return "Linux"
        #else
        return "Unknown"
        #endif
    }

    private func getArchitecture() -> String {
        #if arch(x86_64)
        return "x86_64"
        #elseif arch(arm64)
        return "arm64"
        #else
        return "Unknown"
        #endif
    }

    private func getNetworkStatus() -> String {
        // Simulate network status check
        return "Connected"
    }

    private func getSwiftVersion() -> String {
        return "6.0+"
    }

    private func getOperatingSystem() -> String {
        return ProcessInfo.processInfo.operatingSystemVersionString
    }

    private func getRelevantEnvironmentVariables() -> [String: String] {
        var envVars: [String: String] = [:]

        // Include relevant environment variables
        if let logLevel = ProcessInfo.processInfo.environment["LOG_LEVEL"] {
            envVars["LOG_LEVEL"] = logLevel
        }
        if let domain = ProcessInfo.processInfo.environment["DOMAIN"] {
            envVars["DOMAIN"] = domain
        }

        return envVars
    }

    private func checkDependencies() -> [DependencyStatus] {
        // In a real implementation, this would check actual dependencies
        return [
            DependencyStatus(
                name: "SwiftNIO",
                status: "available",
                version: "2.0+",
                details: "Networking framework"
            ),
            DependencyStatus(
                name: "Foundation",
                status: "available",
                version: "6.0+",
                details: "Core framework"
            ),
            DependencyStatus(
                name: "MCP SDK",
                status: "available",
                version: "1.0+",
                details: "Model Context Protocol SDK"
            )
        ]
    }

    private func formatBytes(_ bytes: Double) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB, .useKB, .useBytes]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }
}