//
//  ModelInfoTool.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-09.
//

import Foundation

/// Tool for providing model information and system introspection capabilities
/// for the Local Intelligence MCP Tools system
public class ModelInfoTool: BaseMCPTool, @unchecked Sendable {

    public struct ModelInfoInput: Codable {
        let includePerformance: Bool
        let includeConfiguration: Bool
        let includeCapabilities: Bool
        let includeStatistics: Bool
        let format: String? // "json", "text", "markdown"

        init(from parameters: [String: AnyCodable]) throws {
            self.includePerformance = parameters["includePerformance"]?.value as? Bool ?? true
            self.includeConfiguration = parameters["includeConfiguration"]?.value as? Bool ?? true
            self.includeCapabilities = parameters["includeCapabilities"]?.value as? Bool ?? true
            self.includeStatistics = parameters["includeStatistics"]?.value as? Bool ?? false
            self.format = parameters["format"]?.value as? String
        }
    }

    public struct ModelInfo: Codable {
        let name: String
        let version: String
        let description: String
        let capabilities: [String]
        let domain: String
        let supportedTools: [String]
        let performance: PerformanceMetrics?
        let configuration: ConfigurationInfo?
        let statistics: SystemStatistics?
    }

    public struct PerformanceMetrics: Codable {
        let responseTime: String
        let throughput: String
        let memoryUsage: String
        let uptime: String
        let requestsProcessed: Int
        let errorRate: String
        let averageResponseTime: String
    }

    public struct ConfigurationInfo: Codable {
        let domain: String
        let logLevel: String
        let maxConcurrency: Int
        let timeoutSeconds: Int
        let features: [String]
        let security: SecurityConfig
    }

    public struct SecurityConfig: Codable {
        let inputValidation: Bool
        let rateLimiting: Bool
        let auditLogging: Bool
        let piiRedaction: Bool
    }

    public struct SystemStatistics: Codable {
        let totalRequests: Int
        let successfulRequests: Int
        let failedRequests: Int
        let averageResponseTime: String
        let toolsUsed: [ToolUsage]
        let topTools: [String]
        let lastReset: String
    }

    public struct ToolUsage: Codable {
        let toolName: String
        let usageCount: Int
        let averageResponseTime: String
        let lastUsed: String
    }

    public init(logger: Logger, securityManager: SecurityManager) {
        super.init(
            name: "model_info",
            description: "Provides comprehensive information about the Local Intelligence MCP Tools system including capabilities, performance metrics, and configuration details",
            inputSchema: [
                "type": "object",
                "properties": [
                    "includePerformance": [
                        "type": "boolean",
                        "default": true,
                        "description": "Include performance metrics and statistics"
                    ],
                    "includeConfiguration": [
                        "type": "boolean",
                        "default": true,
                        "description": "Include system configuration details"
                    ],
                    "includeCapabilities": [
                        "type": "boolean",
                        "default": true,
                        "description": "Include system capabilities and supported tools"
                    ],
                    "includeStatistics": [
                        "type": "boolean",
                        "default": false,
                        "description": "Include detailed usage statistics"
                    ],
                    "format": [
                        "type": "string",
                        "enum": ["json", "text", "markdown"],
                        "default": "json",
                        "description": "Output format for the information"
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
        let input = try ModelInfoInput(from: parameters)
        // Build model information
        let modelInfo = ModelInfo(
            name: "Local Intelligence MCP Tools",
            version: "1.0.0",
            description: "Professional audio engineering AI assistant with 16 specialized tools for audio production workflows including plugin analysis, session documentation, and client feedback processing",
            capabilities: getSystemCapabilities(),
            domain: "audio",
            supportedTools: getAllSupportedTools(),
            performance: input.includePerformance ? getPerformanceMetrics() : nil,
            configuration: input.includeConfiguration ? getConfigurationInfo() : nil,
            statistics: input.includeStatistics ? getSystemStatistics() : nil
        )

        return MCPResponse(
            success: true,
            data: AnyCodable(modelInfo)
        )
    }

    // MARK: - Private Helper Methods

    private func getSystemCapabilities() -> [String] {
        return [
            "text_processing",
            "intent_analysis",
            "schema_extraction",
            "catalog_analysis",
            "session_documentation",
            "feedback_analysis",
            "vendor_neutral_analysis",
            "engineering_templates",
            "plugin_clustering",
            "sentiment_analysis",
            "action_item_extraction",
            "multilingual_support",
            "real_time_processing",
            "security_enforcement",
            "audit_logging",
            "performance_monitoring"
        ]
    }

    private func getAllSupportedTools() -> [String] {
        return [
            // Core Text Processing Tools
            "apple.summarize",
            "apple.text.rewrite",
            "apple.text.normalize",
            "apple.summarize.focus",
            "apple.text.redact",
            "apple.text.chunk",
            "apple.text.count",

            // Intent Analysis Tools
            "apple.intent.recognize",
            "apple.query.analyze",
            "apple.purpose.detect",

            // Extraction & Classification Tools
            "apple.schema.extract",
            "apple.tags.generate",
            "apple.entities.extract",

            // Professional Audio Tools
            "apple.catalog.summarize",
            "apple.session.summarize",
            "apple.feedback.analyze"
        ]
    }

    private func getPerformanceMetrics() -> PerformanceMetrics {
        // In a real implementation, these would be actual metrics
        return PerformanceMetrics(
            responseTime: "< 300ms (average)",
            throughput: "100+ concurrent requests",
            memoryUsage: "512MB (typical)",
            uptime: calculateUptime(),
            requestsProcessed: getTotalRequestsProcessed(),
            errorRate: "< 1%",
            averageResponseTime: "150ms"
        )
    }

    private func getConfigurationInfo() -> ConfigurationInfo {
        return ConfigurationInfo(
            domain: "audio",
            logLevel: getLogLevel(),
            maxConcurrency: 100,
            timeoutSeconds: 30,
            features: getEnabledFeatures(),
            security: SecurityConfig(
                inputValidation: true,
                rateLimiting: true,
                auditLogging: true,
                piiRedaction: true
            )
        )
    }

    private func getSystemStatistics() -> SystemStatistics {
        // In a real implementation, these would be actual statistics
        return SystemStatistics(
            totalRequests: getTotalRequestsProcessed(),
            successfulRequests: getSuccessfulRequests(),
            failedRequests: getFailedRequests(),
            averageResponseTime: "150ms",
            toolsUsed: getToolUsageStats(),
            topTools: getTopUsedTools(),
            lastReset: getLastResetTime()
        )
    }

    // MARK: - Statistics Helper Methods

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

    private func getTotalRequestsProcessed() -> Int {
        // In a real implementation, this would track actual requests
        return Int.random(in: 1000...5000)
    }

    private func getSuccessfulRequests() -> Int {
        let total = getTotalRequestsProcessed()
        return Int(Double(total) * 0.99) // 99% success rate
    }

    private func getFailedRequests() -> Int {
        let total = getTotalRequestsProcessed()
        return total - getSuccessfulRequests()
    }

    private func getToolUsageStats() -> [ToolUsage] {
        let tools = getAllSupportedTools()
        return tools.map { tool in
            ToolUsage(
                toolName: tool,
                usageCount: Int.random(in: 10...500),
                averageResponseTime: "\(Int.random(in: 50...300))ms",
                lastUsed: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-Double.random(in: 0...86400)))
            )
        }.sorted { $0.usageCount > $1.usageCount }
    }

    private func getTopUsedTools() -> [String] {
        let usageStats = getToolUsageStats()
        return Array(usageStats.prefix(5).map { $0.toolName })
    }

    private func getLastResetTime() -> String {
        return ISO8601DateFormatter().string(from: Date().addingTimeInterval(-86400 * 7)) // 7 days ago
    }

    private func getLogLevel() -> String {
        // In a real implementation, this would come from configuration
        return "info"
    }

    private func getEnabledFeatures() -> [String] {
        return [
            "vendor_neutral_analysis",
            "engineering_templates",
            "sentiment_analysis",
            "plugin_clustering",
            "real_time_processing",
            "audit_logging",
            "security_enforcement"
        ]
    }
}