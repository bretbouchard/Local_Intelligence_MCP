//
//  MCPServer.swift
//  AppleMCPServer
//
//  Created on 2025-10-07.
//

import Foundation
import NIOCore
import OSLog

/// Main MCP Server implementation
/// Implements MCP Protocol Compliance constitutional principle
actor MCPServer {

    // MARK: - Properties

    private let configuration: ServerConfiguration
    private let logger: Logger
    private let securityManager: SecurityManager
    private let toolsRegistry: ToolsRegistry

    private var clients: [UUID: MCPClient] = [:]
    private var isRunning = false
    private var startTime: Date?

    // MARK: - Initialization

    init(
        configuration: ServerConfiguration,
        logger: Logger,
        securityManager: SecurityManager,
        toolsRegistry: ToolsRegistry
    ) {
        self.configuration = configuration
        self.logger = logger
        self.securityManager = securityManager
        self.toolsRegistry = toolsRegistry
    }

    // MARK: - Server Lifecycle

    /// Start the MCP server
    /// - Throws: MCPServerError if startup fails
    func start() async throws {
        guard !isRunning else {
            throw MCPServerError.alreadyRunning
        }

        await logger.info("Starting Apple MCP Server", category: .server, metadata: [:])

        // Validate configuration
        let validation = await configuration.validate()
        guard validation.isValid else {
            let issues = validation.issues.map { $0.description }.joined(separator: "; ")
            throw MCPServerError.configurationError(issues)
        }

        // Initialize tools
        try await toolsRegistry.initialize()

        startTime = Date()
        isRunning = true

        await logger.info("Apple MCP Server started successfully", category: .server, metadata: [:])
    }

    /// Stop the MCP server
    func stop() async {
        guard isRunning else { return }

        await logger.info("Stopping Apple MCP Server", category: .server, metadata: [:])

        // Disconnect all clients
        for (clientId, client) in clients {
            await disconnectClient(clientId: clientId, reason: "Server shutting down")
        }

        isRunning = false
        startTime = nil

        await logger.info("Apple MCP Server stopped", category: .server, metadata: [:])
    }

    // MARK: - Client Management

    /// Handle new client connection
    /// - Parameter clientInfo: Information about the connecting client
    /// - Returns: Session token for the client
    /// - Throws: MCPServerError if connection fails
    func connectClient(_ clientInfo: ClientInfo) async throws -> SessionToken {
        guard isRunning else {
            throw MCPServerError.notRunning
        }

        guard clients.count < configuration.maxClients else {
            throw MCPServerError.maxClientsReached
        }

        let clientId = clientInfo.id
        let sessionToken = await securityManager.generateSessionToken(for: clientInfo)

        // Create client instance
        let client = MCPClient(
            id: clientId,
            info: clientInfo,
            sessionToken: sessionToken,
            connectedAt: Date(),
            lastActivity: Date()
        )

        clients[clientId] = client

        await logger.securityEvent(.clientConnected, clientId: clientId.uuidString, details: [:])

        await logger.info("Client connected", category: .server, metadata: [:])

        return sessionToken
    }

    /// Handle client disconnection
    /// - Parameters:
    ///   - clientId: Client identifier
    ///   - reason: Reason for disconnection
    func disconnectClient(clientId: UUID, reason: String) async {
        guard let client = clients[clientId] else { return }

        clients.removeValue(forKey: clientId)

        await logger.securityEvent(.clientDisconnected, clientId: clientId.uuidString, details: [:])

        await logger.info("Client disconnected", category: .server, metadata: [:])
    }

    /// Validate client session
    /// - Parameters:
    ///   - clientId: Client identifier
    ///   - sessionToken: Session token to validate
    /// - Returns: True if session is valid, false otherwise
    func validateClientSession(clientId: UUID, sessionToken: SessionToken) async -> Bool {
        guard let client = clients[clientId] else {
            return false
        }

        guard client.sessionToken.value == sessionToken.value else {
            return false
        }

        guard await securityManager.validateSessionToken(sessionToken) else {
            await disconnectClient(clientId: clientId, reason: "Session expired")
            return false
        }

        // Update last activity
        clients[clientId]?.lastActivity = Date()
        return true
    }

    // MARK: - Server Information

    /// Get server capabilities
    /// - Returns: Server capabilities object
    func getCapabilities() async -> ServerCapabilities {
        return ServerCapabilities(
            name: MCPConstants.Server.name,
            version: MCPConstants.Server.version,
            protocolVersion: MCPConstants.ProtocolInfo.version,
            tools: await toolsRegistry.getAvailableTools(),
            uptime: uptime,
            activeConnections: clients.count,
            maxConnections: configuration.maxClients
        )
    }

    /// Get server status
    /// - Returns: Server status information
    func getStatus() async -> MCPServerStatus {
        return MCPServerStatus(
            isRunning: isRunning,
            startTime: startTime,
            uptime: uptime,
            activeConnections: clients.count,
            maxConnections: configuration.maxClients,
            version: MCPConstants.Server.version
        )
    }

    // MARK: - Health Check

    /// Perform health check
    /// - Returns: Health check result
    func healthCheck() async -> HealthCheckResult {
        let checks = [
            "server_running": isRunning,
            "configuration_valid": await configuration.validate().isValid,
            "tools_available": await toolsRegistry.getAvailableTools().count > 0,
            "memory_usage": getMemoryUsage() < (100 * 1024 * 1024), // < 100MB
            "client_capacity": clients.count < configuration.maxClients
        ]

        let isHealthy = checks.values.allSatisfy { $0 }

        return HealthCheckResult(
            isHealthy: isHealthy,
            checks: checks,
            uptime: uptime,
            activeConnections: clients.count,
            timestamp: Date()
        )
    }

    // MARK: - Private Helpers

    private var uptime: TimeInterval {
        guard let startTime = startTime else { return 0 }
        return Date().timeIntervalSince(startTime)
    }

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
        }
        return 0
    }
}

// MARK: - Supporting Types

struct ServerCapabilities: Codable {
    let name: String
    let version: String
    let protocolVersion: String
    let tools: [MCPToolInfo]
    let uptime: TimeInterval
    let activeConnections: Int
    let maxConnections: Int
}

struct MCPServerStatus: Codable {
    let isRunning: Bool
    let startTime: Date?
    let uptime: TimeInterval
    let activeConnections: Int
    let maxConnections: Int
    let version: String
}

struct HealthCheckResult: Codable {
    let isHealthy: Bool
    let checks: [String: Bool]
    let uptime: TimeInterval
    let activeConnections: Int
    let timestamp: Date
}

struct MCPClient {
    let id: UUID
    let info: ClientInfo
    let sessionToken: SessionToken
    let connectedAt: Date
    var lastActivity: Date

    var isActive: Bool {
        return sessionToken.expiresAt > Date()
    }
}

enum MCPServerError: Error, LocalizedError {
    case alreadyRunning
    case notRunning
    case configurationError(String)
    case maxClientsReached
    case clientNotFound
    case invalidSession
    case toolNotFound(String)
    case toolExecutionFailed(String)

    var errorDescription: String? {
        switch self {
        case .alreadyRunning:
            return "Server is already running"
        case .notRunning:
            return "Server is not running"
        case .configurationError(let message):
            return "Configuration error: \(message)"
        case .maxClientsReached:
            return "Maximum number of clients reached"
        case .clientNotFound:
            return "Client not found"
        case .invalidSession:
            return "Invalid or expired session"
        case .toolNotFound(let toolName):
            return "Tool not found: \(toolName)"
        case .toolExecutionFailed(let message):
            return "Tool execution failed: \(message)"
        }
    }
}