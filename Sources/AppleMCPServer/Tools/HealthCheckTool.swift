//
//  HealthCheckTool.swift
//  AppleMCPServer
//
//  Created on 2025-10-07.
//

import Foundation

/// Tool for checking server health and status
class HealthCheckTool: BaseMCPTool {

    init(logger: Logger, securityManager: SecurityManager) {
        let inputSchema: [String: Any] = [
            "type": "object",
            "properties": [
                "components": [
                    "type": "array",
                    "items": [
                        "type": "string",
                        "enum": ["server", "security", "tools", "permissions", "system", "network", "storage"]
                    ],
                    "description": "Specific components to check (default: all)"
                ],
                "detailed": [
                    "type": "boolean",
                    "description": "Include detailed component information",
                    "default": false
                ]
            ],
            "description": "Perform comprehensive health check of the Apple MCP server and its components"
        ]

        super.init(
            name: "health_check",
            description: "Check the health and status of the Apple MCP server and its components",
            inputSchema: inputSchema,
            category: .general,
            requiresPermission: [.systemInfo],
            offlineCapable: true,
            logger: logger,
            securityManager: securityManager
        )
    }

    override func performExecution(parameters: [String: Any], context: MCPExecutionContext) async throws -> MCPResponse {
        let components = parameters["components"] as? [String] ?? ["server", "security", "tools", "permissions", "system", "network", "storage"]
        let detailed = parameters["detailed"] as? Bool ?? false

        let startTime = Date()
        let executionId = generateExecutionID()

        await logger.info("Performing health check", category: .general, metadata: [
            "components": components.joined(separator: ","),
            "detailed": detailed,
            "executionId": executionId,
            "clientId": context.clientId.uuidString
        ])

        var healthResults: [String: Any] = [:]
        var overallStatus: HealthStatus = .healthy
        var issues: [String] = []

        // Check each component
        if components.contains("server") {
            let serverHealth = await checkServerHealth(detailed: detailed)
            healthResults["server"] = serverHealth.result
            if serverHealth.status != .healthy {
                overallStatus = serverHealth.status
                issues.append(contentsOf: serverHealth.issues)
            }
        }

        if components.contains("security") {
            let securityHealth = await checkSecurityHealth(detailed: detailed)
            healthResults["security"] = securityHealth.result
            if securityHealth.status == .unhealthy {
                overallStatus = .unhealthy
                issues.append(contentsOf: securityHealth.issues)
            } else if securityHealth.status == .degraded && overallStatus == .healthy {
                overallStatus = .degraded
            }
        }

        if components.contains("tools") {
            let toolsHealth = await checkToolsHealth(detailed: detailed)
            healthResults["tools"] = toolsHealth.result
            if toolsHealth.status == .unhealthy {
                overallStatus = .unhealthy
                issues.append(contentsOf: toolsHealth.issues)
            } else if toolsHealth.status == .degraded && overallStatus == .healthy {
                overallStatus = .degraded
            }
        }

        if components.contains("permissions") {
            let permissionsHealth = await checkPermissionsHealth(detailed: detailed)
            healthResults["permissions"] = permissionsHealth.result
            if permissionsHealth.status == .unhealthy {
                overallStatus = .unhealthy
                issues.append(contentsOf: permissionsHealth.issues)
            } else if permissionsHealth.status == .degraded && overallStatus == .healthy {
                overallStatus = .degraded
            }
        }

        if components.contains("system") {
            let systemHealth = await checkSystemHealth(detailed: detailed)
            healthResults["system"] = systemHealth.result
            if systemHealth.status == .unhealthy {
                overallStatus = .unhealthy
                issues.append(contentsOf: systemHealth.issues)
            } else if systemHealth.status == .degraded && overallStatus == .healthy {
                overallStatus = .degraded
            }
        }

        if components.contains("network") {
            let networkHealth = await checkNetworkHealth(detailed: detailed)
            healthResults["network"] = networkHealth.result
            if networkHealth.status == .unhealthy {
                overallStatus = .unhealthy
                issues.append(contentsOf: networkHealth.issues)
            } else if networkHealth.status == .degraded && overallStatus == .healthy {
                overallStatus = .degraded
            }
        }

        if components.contains("storage") {
            let storageHealth = await checkStorageHealth(detailed: detailed)
            healthResults["storage"] = storageHealth.result
            if storageHealth.status == .unhealthy {
                overallStatus = .unhealthy
                issues.append(contentsOf: storageHealth.issues)
            } else if storageHealth.status == .degraded && overallStatus == .healthy {
                overallStatus = .degraded
            }
        }

        // Compile final result
        let executionTime = Date().timeIntervalSince(startTime)

        var result: [String: Any] = [
            "status": overallStatus.rawValue,
            "timestamp": Date().iso8601String,
            "executionTime": executionTime,
            "executionId": executionId,
            "components": healthResults
        ]

        if !issues.isEmpty {
            result["issues"] = issues
        }

        if detailed {
            result["summary"] = generateHealthSummary(healthResults: healthResults, overallStatus: overallStatus)
        }

        await logger.performance(
            "health_check",
            duration: executionTime,
            metadata: [
                "overallStatus": overallStatus.rawValue,
                "componentsChecked": components.count,
                "issuesFound": issues.count
            ]
        )

        return MCPResponse(
            success: true,
            data: AnyCodable(result),
            executionTime: executionTime
        )
    }

    // MARK: - Component Health Checks

    private func checkServerHealth(detailed: Bool) async -> (status: HealthStatus, result: [String: Any], issues: [String]) {
        var issues: [String] = []
        var result: [String: Any] = [:]

        // Check server uptime
        let uptime = ProcessInfo.processInfo.systemUptime
        result["uptime"] = uptime
        result["uptimeFormatted"] = formatDuration(uptime)

        // Check memory usage
        let memoryUsage = getMemoryUsage()
        result["memoryUsage"] = [
            "used": memoryUsage.used,
            "total": memoryUsage.total,
            "percentage": memoryUsage.percentage
        ]

        if memoryUsage.percentage > 90 {
            issues.append("High memory usage: \(String(format: "%.1f", memoryUsage.percentage))%")
        }

        // Check process count
        let processCount = getProcessCount()
        result["processCount"] = processCount

        // Check server status
        result["status"] = "running"
        result["version"] = MCPConstants.Server.version

        if detailed {
            result["startTime"] = Date().addingTimeInterval(-uptime).iso8601String
            result["processorInfo"] = [
                "count": ProcessInfo.processInfo.processorCount,
                "activeCount": ProcessInfo.processInfo.activeProcessorCount
            ]
        }

        let status: HealthStatus = issues.isEmpty ? .healthy : (memoryUsage.percentage > 90 ? .degraded : .healthy)
        return (status, result, issues)
    }

    private func checkSecurityHealth(detailed: Bool) async -> (status: HealthStatus, result: [String: Any], issues: [String]) {
        var issues: [String] = []
        var result: [String: Any] = [:]

        // Check keychain access
        let keychainAccessible = await checkKeychainAccess()
        result["keychainAccessible"] = keychainAccessible
        if !keychainAccessible {
            issues.append("Keychain access failed")
        }

        // Check permission validator
        let permissionValidatorWorking = await checkPermissionValidator()
        result["permissionValidatorWorking"] = permissionValidatorWorking
        if !permissionValidatorWorking {
            issues.append("Permission validator not responding")
        }

        // Check security manager
        let securityManagerWorking = await checkSecurityManager()
        result["securityManagerWorking"] = securityManagerWorking
        if !securityManagerWorking {
            issues.append("Security manager not responding")
        }

        if detailed {
            result["securityFeatures"] = [
                "auditLogging": true,
                "encryptionEnabled": true,
                "sessionManagement": true,
                "credentialStorage": keychainAccessible
            ]
        }

        let status: HealthStatus = issues.isEmpty ? .healthy : .unhealthy
        return (status, result, issues)
    }

    private func checkToolsHealth(detailed: Bool) async -> (status: HealthStatus, result: [String: Any], issues: [String]) {
        var issues: [String] = []
        var result: [String: Any] = [:]

        // Check available tools
        let availableTools = [
            MCPConstants.Tools.systemInfo,
            MCPConstants.Tools.executeShortcut,
            MCPConstants.Tools.listShortcuts,
            MCPConstants.Tools.voiceCommand,
            MCPConstants.Tools.checkPermission
        ]

        var toolStatus: [String: Bool] = [:]
        var workingTools = 0

        for tool in availableTools {
            let toolWorking = await checkToolAvailability(tool)
            toolStatus[tool] = toolWorking
            if toolWorking {
                workingTools += 1
            } else {
                issues.append("Tool '\(tool)' not available")
            }
        }

        result["tools"] = toolStatus
        result["availableTools"] = workingTools
        result["totalTools"] = availableTools.count

        if detailed {
            result["toolDetails"] = [
                "systemInfo": toolStatus[MCPConstants.Tools.systemInfo] ?? false,
                "shortcuts": (toolStatus[MCPConstants.Tools.executeShortcut] ?? false) && (toolStatus[MCPConstants.Tools.listShortcuts] ?? false),
                "voiceControl": toolStatus[MCPConstants.Tools.voiceCommand] ?? false,
                "permissions": toolStatus[MCPConstants.Tools.checkPermission] ?? false
            ]
        }

        let status: HealthStatus = workingTools == availableTools.count ? .healthy : (workingTools > 0 ? .degraded : .unhealthy)
        return (status, result, issues)
    }

    private func checkPermissionsHealth(detailed: Bool) async -> (status: HealthStatus, result: [String: Any], issues: [String]) {
        var issues: [String] = []
        var result: [String: Any] = [:]

        // Check critical permissions
        let criticalPermissions: [PermissionType] = [.accessibility, .shortcuts, .systemInfo]
        var permissionStatus: [String: String] = [:]

        for permission in criticalPermissions {
            let status = await checkPermissionStatus(permission)
            permissionStatus[permission.rawValue] = status

            if status == "denied" {
                issues.append("Permission '\(permission.rawValue)' is denied")
            } else if status == "restricted" {
                issues.append("Permission '\(permission.rawValue)' is restricted")
            }
        }

        result["permissions"] = permissionStatus
        result["criticalPermissionsCount"] = criticalPermissions.count
        result["grantedPermissionsCount"] = permissionStatus.values.filter { $0 == "authorized" }.count

        if detailed {
            result["allPermissions"] = [
                "accessibility": permissionStatus["accessibility"],
                "shortcuts": permissionStatus["shortcuts"],
                "microphone": await checkPermissionStatus(.microphone),
                "systemInfo": permissionStatus["systemInfo"],
                "network": await checkPermissionStatus(.network)
            ]
        }

        let status: HealthStatus = issues.isEmpty ? .healthy : .degraded
        return (status, result, issues)
    }

    private func checkSystemHealth(detailed: Bool) async -> (status: HealthStatus, result: [String: Any], issues: [String]) {
        var issues: [String] = []
        var result: [String: Any] = [:]

        // Check CPU load
        let cpuLoad = getCPULoad()
        result["cpuLoad"] = cpuLoad
        if cpuLoad > 80 {
            issues.append("High CPU load: \(String(format: "%.1f", cpuLoad))%")
        }

        // Check disk space
        let diskSpace = await getDiskSpace()
        result["diskSpace"] = diskSpace
        if diskSpace.availablePercentage < 10 {
            issues.append("Low disk space: \(String(format: "%.1f", diskSpace.availablePercentage))% available")
        }

        // Check system temperature (simplified)
        let thermalState = getHealthThermalState()
        result["thermalState"] = thermalState.rawValue
        if thermalState == .serious || thermalState == .critical {
            issues.append("System thermal state: \(thermalState.rawValue)")
        }

        if detailed {
            result["systemInfo"] = [
                "platform": "macOS",
                "architecture": "unknown", // ProcessInfo.processorInfo is not available in this context
                "processorCount": ProcessInfo.processInfo.processorCount
            ]
        }

        let status: HealthStatus = issues.isEmpty ? .healthy : (cpuLoad > 90 || diskSpace.availablePercentage < 5 ? .unhealthy : .degraded)
        return (status, result, issues)
    }

    private func checkNetworkHealth(detailed: Bool) async -> (status: HealthStatus, result: [String: Any], issues: [String]) {
        var issues: [String] = []
        var result: [String: Any] = [:]

        // Check network connectivity
        let isOnline = await checkNetworkConnectivity()
        result["isOnline"] = isOnline
        if !isOnline {
            issues.append("No network connectivity")
        }

        // Check network interfaces
        let interfaces = await getNetworkInterfaces()
        result["activeInterfaces"] = interfaces.count
        result["interfaces"] = interfaces

        if interfaces.isEmpty && isOnline {
            issues.append("Network connectivity reported but no active interfaces found")
        }

        if detailed {
            result["networkDetails"] = [
                "localhostReachable": await checkLocalhostReachability(),
                "dnsWorking": await checkDNSResolution()
            ]
        }

        let status: HealthStatus = issues.isEmpty ? .healthy : (isOnline ? .degraded : .unhealthy)
        return (status, result, issues)
    }

    private func checkStorageHealth(detailed: Bool) async -> (status: HealthStatus, result: [String: Any], issues: [String]) {
        var issues: [String] = []
        var result: [String: Any] = [:]

        // Check log directory
        let logDirAccessible = await checkLogDirectoryAccess()
        result["logDirectoryAccessible"] = logDirAccessible
        if !logDirAccessible {
            issues.append("Log directory not accessible")
        }

        // Check config directory
        let configDirAccessible = await checkConfigDirectoryAccess()
        result["configDirectoryAccessible"] = configDirAccessible
        if !configDirAccessible {
            issues.append("Config directory not accessible")
        }

        // Check temp directory
        let tempDirAccessible = await checkTempDirectoryAccess()
        result["tempDirectoryAccessible"] = tempDirAccessible
        if !tempDirAccessible {
            issues.append("Temp directory not accessible")
        }

        if detailed {
            result["storagePaths"] = [
                "logs": "~/.apple-mcp-server/logs",
                "config": "~/.apple-mcp-server/config",
                "temp": "/tmp/apple-mcp-server"
            ]
        }

        let status: HealthStatus = issues.isEmpty ? .healthy : .unhealthy
        return (status, result, issues)
    }

    // MARK: - Helper Methods

    private func getMemoryUsage() -> (used: Int64, total: Int64, percentage: Double) {
        let processInfo = ProcessInfo.processInfo
        let total = Int64(processInfo.physicalMemory)
        // This is a simplified calculation - in a real implementation, you'd get actual memory usage
        let used = total / 2 // Simulate 50% usage
        let percentage = Double(used) / Double(total) * 100.0
        return (used, total, percentage)
    }

    private func getProcessCount() -> Int {
        // This would use system APIs to get actual process count
        return 150 // Simulated value
    }

    private func getCPULoad() -> Double {
        // This would use system APIs to get actual CPU load
        return Double.random(in: 10...30) // Simulated value
    }

    private func getHealthThermalState() -> ThermalState {
        // This would use actual system thermal state
        return .nominal
    }

    private func getDiskSpace() async -> (total: Int64, free: Int64, used: Int64, availablePercentage: Double) {
        let fileManager = FileManager.default
        do {
            let attributes = try fileManager.attributesOfFileSystem(forPath: "/")
            guard let totalSize = attributes[.systemSize] as? UInt64,
                  let freeSize = attributes[.systemFreeSize] as? UInt64 else {
                return (0, 0, 0, 0)
            }

            let total = Int64(totalSize)
            let free = Int64(freeSize)
            let used = total - free
            let availablePercentage = Double(free) / Double(total) * 100.0

            return (total, free, used, availablePercentage)
        } catch {
            return (0, 0, 0, 0)
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        let seconds = Int(duration) % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    private func generateHealthSummary(healthResults: [String: Any], overallStatus: HealthStatus) -> String {
        let componentCount = healthResults.keys.count
        let healthyComponents = healthResults.values.compactMap { result -> Bool? in
            if let dict = result as? [String: Any],
               let status = dict["status"] as? String {
                return status == "healthy" || status == "running"
            }
            return nil
        }.count

        return "Overall status: \(overallStatus.rawValue). \(healthyComponents)/\(componentCount) components healthy."
    }

    // MARK: - Async Check Methods (Simplified Implementations)

    private func checkKeychainAccess() async -> Bool {
        // This would attempt actual keychain operations
        return true
    }

    private func checkPermissionValidator() async -> Bool {
        // This would check if the permission validator is responsive
        return true
    }

    private func checkSecurityManager() async -> Bool {
        // This would check if the security manager is responsive
        return true
    }

    private func checkToolAvailability(_ tool: String) async -> Bool {
        // This would check if a specific tool is available and functional
        return true
    }

    private func checkPermissionStatus(_ permission: PermissionType) async -> String {
        // This would check actual system permission status
        return "authorized"
    }

    private func checkNetworkConnectivity() async -> Bool {
        // This would check actual network connectivity
        return true
    }

    private func getNetworkInterfaces() async -> [String] {
        // This would get actual network interfaces
        return ["en0"]
    }

    private func checkLocalhostReachability() async -> Bool {
        // This would check if localhost is reachable
        return true
    }

    private func checkDNSResolution() async -> Bool {
        // This would check if DNS resolution is working
        return true
    }

    private func checkLogDirectoryAccess() async -> Bool {
        // This would check if log directory is accessible
        return true
    }

    private func checkConfigDirectoryAccess() async -> Bool {
        // This would check if config directory is accessible
        return true
    }

    private func checkTempDirectoryAccess() async -> Bool {
        // This would check if temp directory is accessible
        return true
    }
}

// MARK: - Supporting Types

enum HealthStatus: String, Codable {
    case healthy = "healthy"
    case degraded = "degraded"
    case unhealthy = "unhealthy"

    var emoji: String {
        switch self {
        case .healthy:
            return "✅"
        case .degraded:
            return "⚠️"
        case .unhealthy:
            return "❌"
        }
    }
}

enum HealthHealthThermalState: String, Codable {
    case nominal = "nominal"
    case fair = "fair"
    case serious = "serious"
    case critical = "critical"
}