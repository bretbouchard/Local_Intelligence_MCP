//
//  MCPServer.swift
//  AppleMCPServer
//
//  Created on 2025-10-07.
//

import Foundation

/// Data model for the MCP Server component
/// Aligns with the data-model.md specification
struct MCPServerDataModel: Codable {
    let id: UUID
    let version: String
    let capabilities: ServerCapabilitiesDataModel
    let status: ServerStatusDataModel
    let startTime: Date?
    let activeConnections: Int

    init(
        id: UUID = UUID(),
        version: String = MCPConstants.Server.version,
        capabilities: ServerCapabilitiesDataModel = ServerCapabilitiesDataModel(),
        status: ServerStatusDataModel = .starting,
        startTime: Date? = nil,
        activeConnections: Int = 0
    ) {
        self.id = id
        self.version = version
        self.capabilities = capabilities
        self.status = status
        self.startTime = startTime
        self.activeConnections = activeConnections
    }

    /// Update server status
    func with(status: ServerStatusDataModel) -> MCPServerDataModel {
        return MCPServerDataModel(
            id: id,
            version: version,
            capabilities: capabilities,
            status: status,
            startTime: startTime,
            activeConnections: activeConnections
        )
    }

    /// Update active connections count
    func with(activeConnections: Int) -> MCPServerDataModel {
        return MCPServerDataModel(
            id: id,
            version: version,
            capabilities: capabilities,
            status: status,
            startTime: startTime,
            activeConnections: activeConnections
        )
    }

    /// Validate server model
    func validate() -> ValidationResult {
        var errors: [ValidationError] = []

        // Validate version format
        let versionPattern = "^\\d+\\.\\d+\\.\\d+$"
        if version.range(of: versionPattern, options: .regularExpression) == nil {
            errors.append(ValidationError(
                code: "INVALID_VERSION_FORMAT",
                message: "Version must follow semantic versioning (x.y.z)",
                field: "version",
                value: version
            ))
        }

        // Validate active connections
        if activeConnections < 0 || activeConnections > MCPConstants.Server.maxConcurrentClients {
            errors.append(ValidationError(
                code: "INVALID_ACTIVE_CONNECTIONS",
                message: "Active connections must be between 0 and \(MCPConstants.Server.maxConcurrentClients)",
                field: "activeConnections",
                value: activeConnections
            ))
        }

        // Validate status
        switch status {
        case .starting, .running, .stopping, .stopped:
            break // Valid statuses
        case .error:
            errors.append(ValidationError(
                code: "INVALID_SERVER_STATUS",
                message: "Server should not be in error state during normal operation",
                field: "status"
            ))
        }

        return ValidationResult(errors: errors)
    }
}

/// Server status enumeration (data model)
enum ServerStatusDataModel: String, Codable, CaseIterable {
    case starting = "starting"
    case running = "running"
    case stopping = "stopping"
    case stopped = "stopped"
    case error = "error"

    init(from decoder: Decoder) throws {
        let rawValue = try decoder.singleValueContainer().decode(String.self)
        self = ServerStatusDataModel(rawValue: rawValue) ?? .error
    }

    var isHealthy: Bool {
        switch self {
        case .running:
            return true
        case .starting, .stopping, .stopped:
            return false
        case .error:
            return false
        }
    }
}

/// Server capabilities information (data model)
struct ServerCapabilitiesDataModel: Codable {
    let name: String
    let version: String
    let protocolVersion: String
    let tools: [String]
    let features: [String]

    init(
        name: String = MCPConstants.Server.name,
        version: String = MCPConstants.Server.version,
        protocolVersion: String = MCPConstants.ProtocolInfo.version,
        tools: [String] = [],
        features: [String] = []
    ) {
        self.name = name
        self.version = version
        self.protocolVersion = protocolVersion
        self.tools = tools
        self.features = features
    }
}

/// Server statistics and metrics
struct ServerStatistics {
    let uptime: TimeInterval
    let totalRequests: Int
    let activeConnections: Int
    let maxConnections: Int
    let memoryUsage: Int64
    let cpuUsage: Double

    init(
        uptime: TimeInterval = 0,
        totalRequests: Int = 0,
        activeConnections: Int = 0,
        maxConnections: Int = MCPConstants.Server.maxConcurrentClients,
        memoryUsage: Int64 = 0,
        cpuUsage: Double = 0.0
    ) {
        self.uptime = uptime
        self.totalRequests = totalRequests
        self.activeConnections = activeConnections
        self.maxConnections = maxConnections
        self.memoryUsage = memoryUsage
        self.cpuUsage = cpuUsage
    }
}