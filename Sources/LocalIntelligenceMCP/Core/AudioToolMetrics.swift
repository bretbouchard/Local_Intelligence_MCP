//
//  AudioToolMetrics.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-08.
//

import Foundation

/// Performance monitoring framework for audio tools
/// Provides comprehensive metrics collection, analysis, and reporting
actor AudioToolMetrics: Sendable {

    // MARK: - Properties

    private let logger: Logger
    private let configuration: AudioToolsConfiguration.Performance
    private var toolMetrics: [String: ToolMetrics] = [:]
    private var globalMetrics: GlobalMetrics
    private var sessionMetrics: [UUID: SessionMetrics] = [:]
    private var performanceHistory: [PerformanceRecord] = []
    private var activeOperations: [String: ActiveOperation] = [:]

    // MARK: - Metrics Storage

    private var metricsCache: [String: CachedMetrics] = [:]
    private var lastCacheCleanup: Date = Date()

    // MARK: - Initialization

    init(logger: Logger, configuration: AudioToolsConfiguration.Performance) {
        self.logger = logger
        self.configuration = configuration
        self.globalMetrics = GlobalMetrics()
    }

    // MARK: - Operation Tracking

    /// Start tracking a tool operation
    /// - Parameters:
    ///   - toolName: Name of the tool
    ///   - clientId: Client ID
    ///   - operationId: Unique operation identifier
    ///   - parameters: Operation parameters
    /// - Returns: Operation tracking context
    func startOperation(
        toolName: String,
        clientId: UUID,
        operationId: String = UUID().uuidString,
        parameters: [String: Any] = [:]
    ) -> OperationContext {
        let convertedParameters = parameters.mapValues { AnyCodable($0) }
        let context = OperationContext(
            operationId: operationId,
            toolName: toolName,
            clientId: clientId,
            startTime: Date(),
            parameters: convertedParameters
        )

        let activeOperation = ActiveOperation(context: context)
        activeOperations[operationId] = activeOperation

        Task {
            await logger.debug(
                "Started tracking operation",
                metadata: [
                    "operationId": operationId,
                    "toolName": toolName,
                    "clientId": clientId.uuidString
                ]
            )
        }

        return context
    }

    /// Complete tracking a tool operation
    /// - Parameters:
    ///   - operationId: Operation identifier
    ///   - success: Whether the operation succeeded
    ///   - result: Operation result data
    ///   - error: Error if operation failed
    /// - Returns: Performance metrics for the operation
    func completeOperation(
        operationId: String,
        success: Bool,
        result: Any? = nil,
        error: Error? = nil
    ) -> OperationMetrics? {
        guard let activeOperation = activeOperations.removeValue(forKey: operationId) else {
            Task {
                await logger.warning("Attempted to complete unknown operation", metadata: ["operationId": operationId])
            }
            return nil
        }

        let endTime = Date()
        let executionTime = endTime.timeIntervalSince(activeOperation.context.startTime)

        let resultSize = if let result = result {
            String(describing: result).count
        } else {
            0
        }

        let metrics = OperationMetrics(
            context: activeOperation.context,
            endTime: endTime,
            executionTime: executionTime,
            success: success,
            resultSize: resultSize,
            error: error
        )

        // Update various metrics collections
        updateToolMetrics(metrics)
        updateGlobalMetrics(metrics)
        updateSessionMetrics(metrics)
        recordPerformanceHistory(metrics)

        // Log operation completion
        Task {
            await logger.performance(
                "tool_operation",
                duration: executionTime,
                metadata: [
                    "toolName": activeOperation.context.toolName,
                    "operationId": operationId,
                    "success": success,
                    "resultSize": metrics.resultSize
                ]
            )
        }

        return metrics
    }

    // MARK: - Metrics Retrieval

    /// Get metrics for a specific tool
    /// - Parameter toolName: Tool name
    /// - Returns: Tool metrics or nil if not found
    func getToolMetrics(_ toolName: String) -> ToolMetrics? {
        return toolMetrics[toolName]
    }

    /// Get global metrics across all tools
    /// - Returns: Global performance metrics
    func getGlobalMetrics() -> GlobalMetrics {
        return globalMetrics
    }

    /// Get metrics for a specific client session
    /// - Parameter clientId: Client ID
    /// - Returns: Session metrics or nil if not found
    func getSessionMetrics(_ clientId: UUID) -> SessionMetrics? {
        return sessionMetrics[clientId]
    }

    /// Get performance metrics for a time range
    /// - Parameters:
    ///   - startDate: Start of time range
    ///   - endDate: End of time range
    /// - Returns: Array of performance records
    func getPerformanceHistory(from startDate: Date, to endDate: Date) -> [PerformanceRecord] {
        return performanceHistory.filter { record in
            record.timestamp >= startDate && record.timestamp <= endDate
        }
    }

    /// Get top performing tools by success rate
    /// - Parameter limit: Maximum number of tools to return
    /// - Returns: Array of tool performance summaries
    func getTopPerformingTools(limit: Int = 10) async -> [ToolPerformanceSummary] {
        var summaries: [ToolPerformanceSummary] = []

        for (toolName, metrics) in toolMetrics {
            summaries.append(ToolPerformanceSummary(toolName: toolName, metrics: metrics))
        }

        // Get all success rates first, then sort
        var summariesWithRates: [(ToolPerformanceSummary, Double)] = []
        for summary in summaries {
            let rate = await summary.metrics.successRate
            summariesWithRates.append((summary, rate))
        }

        // Sort by success rate
        summariesWithRates.sort { $0.1 > $1.1 }

        return Array(summariesWithRates.prefix(limit).map { $0.0 })
    }

    /// Get tools with performance issues
    /// - Returns: Array of tools with performance problems
    func getToolsWithPerformanceIssues() async -> [PerformanceIssue] {
        var issues: [PerformanceIssue] = []

        for (toolName, metricsActor) in toolMetrics {
            let successRate = await metricsActor.successRate
            let totalExecutions = await metricsActor.totalExecutionsValue
            let averageExecutionTime = await metricsActor.averageExecutionTime

            // Check for low success rate
            if successRate < 0.9 && totalExecutions >= 10 {
                issues.append(PerformanceIssue(
                    toolName: toolName,
                    issueType: .lowSuccessRate,
                    severity: .warning,
                    description: "Success rate is \(String(format: "%.1f", successRate * 100))%",
                    recommendation: "Review tool implementation and error handling"
                ))
            }

            // Check for slow average execution time
            if averageExecutionTime > 5.0 && totalExecutions >= 5 {
                issues.append(PerformanceIssue(
                    toolName: toolName,
                    issueType: .slowExecution,
                    severity: averageExecutionTime > 10.0 ? .error : .warning,
                    description: "Average execution time is \(String(format: "%.2f", averageExecutionTime))s",
                    recommendation: "Optimize tool implementation or increase timeout limits"
                ))
            }

            // Check for high error rate in recent operations
            let recentRecords = performanceHistory.suffix(50).filter { $0.toolName == toolName }
            if recentRecords.count >= 10 {
                let recentSuccessRate = Double(recentRecords.filter { $0.success }.count) / Double(recentRecords.count)
                if recentSuccessRate < 0.8 {
                    issues.append(PerformanceIssue(
                        toolName: toolName,
                        issueType: .recentErrors,
                        severity: .warning,
                        description: "Recent success rate is \(String(format: "%.1f", recentSuccessRate * 100))%",
                        recommendation: "Check for recent changes or external dependencies"
                    ))
                }
            }
        }

        return issues.sorted { $0.severity.rawValue > $1.severity.rawValue }
    }

    // MARK: - Analytics and Reporting

    /// Generate performance report
    /// - Parameters:
    ///   - timeRange: Time range for the report
    ///   - includeDetails: Whether to include detailed breakdowns
    /// - Returns: Performance report
    func generatePerformanceReport(
        timeRange: TimeRange = .last24Hours,
        includeDetails: Bool = false
    ) async -> PerformanceReport {
        let (startDate, endDate) = getDateRange(for: timeRange)
        let records = getPerformanceHistory(from: startDate, to: endDate)
        let issues = await getToolsWithPerformanceIssues()
        let topTools = await getTopPerformingTools(limit: 5)

        return PerformanceReport(
            timeRange: timeRange,
            startDate: startDate,
            endDate: endDate,
            globalMetrics: globalMetrics,
            performanceIssues: issues,
            topPerformingTools: topTools,
            records: includeDetails ? records : [],
            generatedAt: Date()
        )
    }

    // MARK: - Cache Management

    /// Clean up expired cached metrics
    func cleanupExpiredMetrics() {
        let now = Date()
        let cutoffDate = now.addingTimeInterval(-configuration.metricsRetentionPeriod)

        // Remove expired performance history
        performanceHistory.removeAll { $0.timestamp < cutoffDate }

        // Clean up inactive sessions
        Task {
            var activeSessions: [UUID: SessionMetrics] = [:]
            for (clientId, metrics) in sessionMetrics {
                let lastActivity = await metrics.lastActivityTime
                if now.timeIntervalSince(lastActivity) < configuration.metricsRetentionPeriod {
                    activeSessions[clientId] = metrics
                }
            }
            sessionMetrics = activeSessions
        }

        // Clean up metrics cache
        if now.timeIntervalSince(lastCacheCleanup) > 3600 { // Every hour
            var activeCache: [String: CachedMetrics] = [:]
            for (key, cached) in metricsCache {
                if now.timeIntervalSince(cached.timestamp) <= configuration.cacheExpirationTime {
                    activeCache[key] = cached
                }
            }
            metricsCache = activeCache
            lastCacheCleanup = now
        }

        Task {
            await logger.debug("Cleaned up expired metrics", metadata: [
                "historyCount": performanceHistory.count,
                "sessionCount": sessionMetrics.count,
                "cacheCount": metricsCache.count
            ])
        }
    }

    // MARK: - Private Update Methods

    private func updateToolMetrics(_ metrics: OperationMetrics) {
        let toolName = metrics.context.toolName

        if toolMetrics[toolName] == nil {
            toolMetrics[toolName] = ToolMetrics(toolName: toolName)
        }

        Task {
            await toolMetrics[toolName]?.addOperation(metrics)
        }
    }

    private func updateGlobalMetrics(_ metrics: OperationMetrics) {
        globalMetrics.addOperation(metrics)
    }

    private func updateSessionMetrics(_ metrics: OperationMetrics) {
        let clientId = metrics.context.clientId

        if sessionMetrics[clientId] == nil {
            sessionMetrics[clientId] = SessionMetrics(clientId: clientId)
        }

        Task {
            await sessionMetrics[clientId]?.addOperation(metrics)
        }
    }

    private func recordPerformanceHistory(_ metrics: OperationMetrics) {
        let record = PerformanceRecord(
            toolName: metrics.context.toolName,
            clientId: metrics.context.clientId,
            timestamp: metrics.endTime,
            executionTime: metrics.executionTime,
            success: metrics.success,
            resultSize: metrics.resultSize,
            error: metrics.error?.localizedDescription
        )

        performanceHistory.append(record)

        // Keep only recent history to prevent memory issues
        if performanceHistory.count > 10000 {
            performanceHistory.removeFirst(performanceHistory.count - 10000)
        }
    }

    private func getDateRange(for timeRange: TimeRange) -> (startDate: Date, endDate: Date) {
        let now = Date()
        let startDate: Date

        switch timeRange {
        case .lastHour:
            startDate = now.addingTimeInterval(-3600)
        case .last24Hours:
            startDate = now.addingTimeInterval(-86400)
        case .last7Days:
            startDate = now.addingTimeInterval(-604800)
        case .last30Days:
            startDate = now.addingTimeInterval(-2592000)
        }

        return (startDate: startDate, endDate: now)
    }
}

// MARK: - Supporting Types

/// Context for tracking an operation
struct OperationContext: Sendable {
    let operationId: String
    let toolName: String
    let clientId: UUID
    let startTime: Date
    let parameters: [String: AnyCodable]
}

/// Active operation being tracked
struct ActiveOperation: Sendable {
    let context: OperationContext
}

/// Metrics for a single operation
struct OperationMetrics: Sendable {
    let context: OperationContext
    let endTime: Date
    let executionTime: TimeInterval
    let success: Bool
    let resultSize: Int
    let error: Error?
}

/// Metrics for a specific tool
actor ToolMetrics {
    let toolName: String
    private var totalExecutions: Int = 0
    private var successfulExecutions: Int = 0
    private var totalExecutionTime: TimeInterval = 0.0
    private var minExecutionTime: TimeInterval = Double.greatestFiniteMagnitude
    private var maxExecutionTime: TimeInterval = 0.0
    private var totalResultSize: Int = 0
    private var lastExecution: Date?

    init(toolName: String) {
        self.toolName = toolName
    }

    var successRate: Double {
        guard totalExecutions > 0 else { return 0.0 }
        return Double(successfulExecutions) / Double(totalExecutions)
    }

    var averageExecutionTime: TimeInterval {
        guard totalExecutions > 0 else { return 0.0 }
        return totalExecutionTime / Double(totalExecutions)
    }

    var averageResultSize: Int {
        guard totalExecutions > 0 else { return 0 }
        return totalResultSize / totalExecutions
    }

    var totalExecutionsValue: Int {
        return totalExecutions
    }

    func addOperation(_ metrics: OperationMetrics) {
        totalExecutions += 1
        if metrics.success {
            successfulExecutions += 1
        }
        totalExecutionTime += metrics.executionTime
        totalResultSize += metrics.resultSize
        minExecutionTime = min(minExecutionTime, metrics.executionTime)
        maxExecutionTime = max(maxExecutionTime, metrics.executionTime)
        lastExecution = metrics.endTime
    }
}

/// Global metrics across all tools
class GlobalMetrics: @unchecked Sendable {
    private var totalOperations: Int = 0
    private var successfulOperations: Int = 0
    private var totalExecutionTime: TimeInterval = 0.0
    private var activeOperations: Int = 0
    private var uniqueTools: Set<String> = []
    private var uniqueClients: Set<UUID> = []

    var overallSuccessRate: Double {
        guard totalOperations > 0 else { return 0.0 }
        return Double(successfulOperations) / Double(totalOperations)
    }

    var averageExecutionTime: TimeInterval {
        guard totalOperations > 0 else { return 0.0 }
        return totalExecutionTime / Double(totalOperations)
    }

    func addOperation(_ metrics: OperationMetrics) {
        totalOperations += 1
        if metrics.success {
            successfulOperations += 1
        }
        totalExecutionTime += metrics.executionTime
        uniqueTools.insert(metrics.context.toolName)
        uniqueClients.insert(metrics.context.clientId)
    }

    func incrementActiveOperations() {
        activeOperations += 1
    }

    func decrementActiveOperations() {
        activeOperations = max(0, activeOperations - 1)
    }
}

/// Metrics for a client session
actor SessionMetrics {
    let clientId: UUID
    private var operations: [OperationMetrics] = []
    private var lastActivity: Date = Date()

    init(clientId: UUID) {
        self.clientId = clientId
    }

    var totalOperations: Int {
        return operations.count
    }

    var successRate: Double {
        guard !operations.isEmpty else { return 0.0 }
        return Double(operations.filter { $0.success }.count) / Double(operations.count)
    }

    var lastActivityTime: Date {
        return lastActivity
    }

    func addOperation(_ metrics: OperationMetrics) {
        operations.append(metrics)
        lastActivity = metrics.endTime

        // Keep only recent operations
        if operations.count > 1000 {
            operations.removeFirst(operations.count - 1000)
        }
    }
}

/// Performance record for historical tracking
struct PerformanceRecord: Codable, Sendable {
    let toolName: String
    let clientId: UUID
    let timestamp: Date
    let executionTime: TimeInterval
    let success: Bool
    let resultSize: Int
    let error: String?
}

/// Tool performance summary
struct ToolPerformanceSummary: Sendable {
    let toolName: String
    let metrics: ToolMetrics
}

/// Performance issue detection
struct PerformanceIssue: Sendable {
    let toolName: String
    let issueType: IssueType
    let severity: Severity
    let description: String
    let recommendation: String

    enum IssueType: String, Codable, Sendable {
        case lowSuccessRate = "lowSuccessRate"
        case slowExecution = "slowExecution"
        case recentErrors = "recentErrors"
        case memoryUsage = "memoryUsage"
    }

    enum Severity: String, Codable, CaseIterable, Sendable {
        case info = "info"
        case warning = "warning"
        case error = "error"
        case critical = "critical"

        var rawValue: Int {
            switch self {
            case .info: return 1
            case .warning: return 2
            case .error: return 3
            case .critical: return 4
            }
        }
    }
}

/// Time range for metrics analysis
enum TimeRange: String, Codable, CaseIterable, Sendable {
    case lastHour = "lastHour"
    case last24Hours = "last24Hours"
    case last7Days = "last7Days"
    case last30Days = "last30Days"
}

/// Performance report
struct PerformanceReport: Sendable {
    let timeRange: TimeRange
    let startDate: Date
    let endDate: Date
    let globalMetrics: GlobalMetrics
    let performanceIssues: [PerformanceIssue]
    let topPerformingTools: [ToolPerformanceSummary]
    let records: [PerformanceRecord]
    let generatedAt: Date
}

/// Export format for metrics data
enum ExportFormat: String, CaseIterable {
    case json = "json"
    case csv = "csv"
}

/// Cached metrics
struct CachedMetrics: Sendable {
    let metrics: AnyCodable
    let timestamp: Date
}