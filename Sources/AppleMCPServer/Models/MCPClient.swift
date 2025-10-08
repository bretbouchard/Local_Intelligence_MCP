//
//  MCPClient.swift
//  AppleMCPServer
//
//  Created on 2025-10-07.
//

import Foundation

/// Data model for MCP Client connections
/// Aligns with the data-model.md specification
struct MCPClientDataModel: Codable, Identifiable {
    let id: UUID
    let name: String
    let version: String
    let connectedAt: Date
    let lastActivity: Date
    let status: ClientStatus
    let capabilities: ClientCapabilities
    let permissions: [PermissionType]
    let sessionInfo: SessionInfo
    let connectionInfo: ConnectionInfo
    let statistics: ClientStatistics
    let isActive: Bool
    let metadata: [String: AnyCodable]

    init(
        id: UUID = UUID(),
        name: String,
        version: String,
        connectedAt: Date = Date(),
        lastActivity: Date = Date(),
        status: ClientStatus = .connected,
        capabilities: ClientCapabilities = ClientCapabilities(),
        permissions: [PermissionType] = [],
        sessionInfo: SessionInfo = SessionInfo(),
        connectionInfo: ConnectionInfo = ConnectionInfo(),
        statistics: ClientStatistics = ClientStatistics(),
        isActive: Bool = true,
        metadata: [String: AnyCodable] = [:]
    ) {
        self.id = id
        self.name = name
        self.version = version
        self.connectedAt = connectedAt
        self.lastActivity = lastActivity
        self.status = status
        self.capabilities = capabilities
        self.permissions = permissions
        self.sessionInfo = sessionInfo
        self.connectionInfo = connectionInfo
        self.statistics = statistics
        self.isActive = isActive
        self.metadata = metadata
    }

    /// Update last activity timestamp
    func withLastActivity(_ timestamp: Date = Date()) -> MCPClientDataModel {
        return MCPClientDataModel(
            id: id,
            name: name,
            version: version,
            connectedAt: connectedAt,
            lastActivity: timestamp,
            status: status,
            capabilities: capabilities,
            permissions: permissions,
            sessionInfo: sessionInfo,
            connectionInfo: connectionInfo,
            statistics: statistics,
            isActive: isActive,
            metadata: metadata
        )
    }

    /// Update client status
    func with(status: ClientStatus) -> MCPClientDataModel {
        return MCPClientDataModel(
            id: id,
            name: name,
            version: version,
            connectedAt: connectedAt,
            lastActivity: lastActivity,
            status: status,
            capabilities: capabilities,
            permissions: permissions,
            sessionInfo: sessionInfo,
            connectionInfo: connectionInfo,
            statistics: statistics,
            isActive: status == .connected,
            metadata: metadata
        )
    }

    /// Update permissions
    func with(permissions: [PermissionType]) -> MCPClientDataModel {
        return MCPClientDataModel(
            id: id,
            name: name,
            version: version,
            connectedAt: connectedAt,
            lastActivity: lastActivity,
            status: status,
            capabilities: capabilities,
            permissions: permissions,
            sessionInfo: sessionInfo,
            connectionInfo: connectionInfo,
            statistics: statistics,
            isActive: isActive,
            metadata: metadata
        )
    }

    /// Update statistics with new request
    func withRequest(_ request: ClientRequest) -> MCPClientDataModel {
        return MCPClientDataModel(
            id: id,
            name: name,
            version: version,
            connectedAt: connectedAt,
            lastActivity: request.timestamp,
            status: status,
            capabilities: capabilities,
            permissions: permissions,
            sessionInfo: sessionInfo,
            connectionInfo: connectionInfo,
            statistics: statistics.withRequest(request),
            isActive: isActive,
            metadata: metadata
        )
    }

    /// Check if client has specific permission
    func hasPermission(_ permission: PermissionType) -> Bool {
        return permissions.contains(permission)
    }

    /// Check if client supports specific capability
    func supportsCapability(_ capability: String) -> Bool {
        return capabilities.supportedCapabilities.contains(capability)
    }

    /// Calculate session duration
    var sessionDuration: TimeInterval {
        lastActivity.timeIntervalSince(connectedAt)
    }

    /// Validate client model
    func validate() -> ValidationResult {
        var errors: [ValidationError] = []

        // Validate name
        if name.isEmpty {
            errors.append(ValidationError(
                code: "INVALID_CLIENT_NAME",
                message: "Client name cannot be empty",
                field: "name",
                value: name
            ))
        }

        if name.count > MCPConstants.Limits.maxClientNameLength {
            errors.append(ValidationError(
                code: "CLIENT_NAME_TOO_LONG",
                message: "Client name cannot exceed \(MCPConstants.Limits.maxClientNameLength) characters",
                field: "name",
                value: name
            ))
        }

        // Validate version
        let versionPattern = "^\\d+\\.\\d+\\.\\d+$"
        if version.range(of: versionPattern, options: .regularExpression) == nil {
            errors.append(ValidationError(
                code: "INVALID_VERSION_FORMAT",
                message: "Version must follow semantic versioning (x.y.z)",
                field: "version",
                value: version
            ))
        }

        // Validate timestamps
        if lastActivity < connectedAt {
            errors.append(ValidationError(
                code: "INVALID_TIMESTAMPS",
                message: "Last activity cannot be before connected timestamp",
                field: "lastActivity",
                value: lastActivity
            ))
        }

        // Validate capabilities
        let capabilitiesValidation = capabilities.validate()
        errors.append(contentsOf: capabilitiesValidation.errors)

        // Validate session info
        let sessionValidation = sessionInfo.validate()
        errors.append(contentsOf: sessionValidation.errors)

        // Validate connection info
        let connectionValidation = connectionInfo.validate()
        errors.append(contentsOf: connectionValidation.errors)

        // Validate statistics
        let statsValidation = statistics.validate()
        errors.append(contentsOf: statsValidation.errors)

        return ValidationResult(errors: errors)
    }

    /// Export client for MCP format
    func exportForMCP() -> [String: Any] {
        return [
            "id": id.uuidString,
            "name": name,
            "version": version,
            "connectedAt": connectedAt.iso8601String,
            "lastActivity": lastActivity.iso8601String,
            "status": status.rawValue,
            "capabilities": capabilities.export(),
            "permissions": permissions.map { $0.rawValue },
            "sessionInfo": sessionInfo.export(),
            "connectionInfo": connectionInfo.export(),
            "statistics": statistics.export(),
            "isActive": isActive,
            "sessionDuration": sessionDuration
        ]
    }
}

/// Client status enumeration
enum ClientStatus: String, Codable, CaseIterable {
    case connecting = "connecting"
    case connected = "connected"
    case disconnected = "disconnected"
    case error = "error"
    case suspended = "suspended"

    var displayName: String {
        switch self {
        case .connecting:
            return "Connecting"
        case .connected:
            return "Connected"
        case .disconnected:
            return "Disconnected"
        case .error:
            return "Error"
        case .suspended:
            return "Suspended"
        }
    }

    var isActive: Bool {
        switch self {
        case .connected:
            return true
        case .connecting, .disconnected, .error, .suspended:
            return false
        }
    }
}

/// Client capabilities
struct ClientCapabilities: Codable {
    let supportedCapabilities: [String]
    let supportedTools: [String]
    let protocolVersion: String
    let maxRequestSize: Int?
    let supportsStreaming: Bool
    let supportsBatchRequests: Bool

    init(
        supportedCapabilities: [String] = [],
        supportedTools: [String] = [],
        protocolVersion: String = "2024-11-05",
        maxRequestSize: Int? = nil,
        supportsStreaming: Bool = false,
        supportsBatchRequests: Bool = false
    ) {
        self.supportedCapabilities = supportedCapabilities
        self.supportedTools = supportedTools
        self.protocolVersion = protocolVersion
        self.maxRequestSize = maxRequestSize
        self.supportsStreaming = supportsStreaming
        self.supportsBatchRequests = supportsBatchRequests
    }

    /// Validate capabilities
    func validate() -> ValidationResult {
        var errors: [ValidationError] = []

        if protocolVersion.isEmpty {
            errors.append(ValidationError(
                code: "INVALID_PROTOCOL_VERSION",
                message: "Protocol version cannot be empty",
                field: "protocolVersion",
                value: protocolVersion
            ))
        }

        if let maxRequestSize = maxRequestSize, maxRequestSize <= 0 {
            errors.append(ValidationError(
                code: "INVALID_MAX_REQUEST_SIZE",
                message: "Max request size must be greater than 0",
                field: "maxRequestSize",
                value: maxRequestSize
            ))
        }

        return ValidationResult(errors: errors)
    }

    /// Export capabilities
    func export() -> [String: Any] {
        var result: [String: Any] = [
            "supportedCapabilities": supportedCapabilities,
            "supportedTools": supportedTools,
            "protocolVersion": protocolVersion,
            "supportsStreaming": supportsStreaming,
            "supportsBatchRequests": supportsBatchRequests
        ]

        if let maxRequestSize = maxRequestSize {
            result["maxRequestSize"] = maxRequestSize
        }

        return result
    }
}

/// Session information
struct SessionInfo: Codable {
    let sessionId: UUID
    let userId: String?
    let userRole: String?
    let authenticationMethod: AuthenticationMethod
    let ipAddress: String? // Redacted in exports
    let userAgent: String?
    let locale: String
    let timezone: String

    init(
        sessionId: UUID = UUID(),
        userId: String? = nil,
        userRole: String? = nil,
        authenticationMethod: AuthenticationMethod = .none,
        ipAddress: String? = nil,
        userAgent: String? = nil,
        locale: String = "en-US",
        timezone: String = "UTC"
    ) {
        self.sessionId = sessionId
        self.userId = userId
        self.userRole = userRole
        self.authenticationMethod = authenticationMethod
        self.ipAddress = ipAddress
        self.userAgent = userAgent
        self.locale = locale
        self.timezone = timezone
    }

    /// Validate session info
    func validate() -> ValidationResult {
        var errors: [ValidationError] = []

        // Validate locale format
        let localePattern = "^[a-z]{2}-[A-Z]{2}$"
        if locale.range(of: localePattern, options: .regularExpression) == nil {
            errors.append(ValidationError(
                code: "INVALID_LOCALE",
                message: "Locale must follow format 'xx-XX' (e.g., 'en-US')",
                field: "locale",
                value: locale
            ))
        }

        return ValidationResult(errors: errors)
    }

    /// Export session info (with IP redacted)
    func export() -> [String: Any] {
        var result: [String: Any] = [
            "sessionId": sessionId.uuidString,
            "authenticationMethod": authenticationMethod.rawValue,
            "locale": locale,
            "timezone": timezone
        ]

        if let userId = userId {
            result["userId"] = userId
        }

        if let userRole = userRole {
            result["userRole"] = userRole
        }

        if let userAgent = userAgent {
            result["userAgent"] = userAgent
        }

        return result
    }
}

/// Authentication method enumeration
enum AuthenticationMethod: String, Codable, CaseIterable {
    case none = "none"
    case token = "token"
    case certificate = "certificate"
    case basic = "basic"
    case oauth = "oauth"
    case apiKey = "apiKey"

    var displayName: String {
        switch self {
        case .none:
            return "None"
        case .token:
            return "Token"
        case .certificate:
            return "Certificate"
        case .basic:
            return "Basic"
        case .oauth:
            return "OAuth"
        case .apiKey:
            return "API Key"
        }
    }
}

/// Connection information
struct ConnectionInfo: Codable {
    let connectionId: UUID
    let transportType: TransportType
    let localAddress: String?
    let remoteAddress: String? // Redacted in exports
    let encryptionEnabled: Bool
    let compressionEnabled: Bool
    let keepAliveEnabled: Bool
    let keepAliveInterval: TimeInterval?

    init(
        connectionId: UUID = UUID(),
        transportType: TransportType = .unknown,
        localAddress: String? = nil,
        remoteAddress: String? = nil,
        encryptionEnabled: Bool = false,
        compressionEnabled: Bool = false,
        keepAliveEnabled: Bool = false,
        keepAliveInterval: TimeInterval? = nil
    ) {
        self.connectionId = connectionId
        self.transportType = transportType
        self.localAddress = localAddress
        self.remoteAddress = remoteAddress
        self.encryptionEnabled = encryptionEnabled
        self.compressionEnabled = compressionEnabled
        self.keepAliveEnabled = keepAliveEnabled
        self.keepAliveInterval = keepAliveInterval
    }

    /// Validate connection info
    func validate() -> ValidationResult {
        var errors: [ValidationError] = []

        if let keepAliveInterval = keepAliveInterval, keepAliveInterval <= 0 {
            errors.append(ValidationError(
                code: "INVALID_KEEP_ALIVE_INTERVAL",
                message: "Keep alive interval must be greater than 0",
                field: "keepAliveInterval",
                value: keepAliveInterval
            ))
        }

        return ValidationResult(errors: errors)
    }

    /// Export connection info (with remote address redacted)
    func export() -> [String: Any] {
        var result: [String: Any] = [
            "connectionId": connectionId.uuidString,
            "transportType": transportType.rawValue,
            "encryptionEnabled": encryptionEnabled,
            "compressionEnabled": compressionEnabled,
            "keepAliveEnabled": keepAliveEnabled
        ]

        if let localAddress = localAddress {
            result["localAddress"] = localAddress
        }

        if let keepAliveInterval = keepAliveInterval {
            result["keepAliveInterval"] = keepAliveInterval
        }

        return result
    }
}

/// Transport type enumeration
enum TransportType: String, Codable, CaseIterable {
    case unknown = "unknown"
    case stdio = "stdio"
    case websocket = "websocket"
    case http = "http"
    case tcp = "tcp"
    case unix = "unix"

    var displayName: String {
        switch self {
        case .unknown:
            return "Unknown"
        case .stdio:
            return "STDIO"
        case .websocket:
            return "WebSocket"
        case .http:
            return "HTTP"
        case .tcp:
            return "TCP"
        case .unix:
            return "Unix Socket"
        }
    }
}

/// Client statistics
struct ClientStatistics: Codable {
    let totalRequests: Int
    let successfulRequests: Int
    let failedRequests: Int
    let averageResponseTime: TimeInterval
    let lastRequestTime: Date?
    let requestsByTool: [String: Int]
    let dataTransferred: Int64
    let errors: [String: Int] // Error type -> count

    init(
        totalRequests: Int = 0,
        successfulRequests: Int = 0,
        failedRequests: Int = 0,
        averageResponseTime: TimeInterval = 0.0,
        lastRequestTime: Date? = nil,
        requestsByTool: [String: Int] = [:],
        dataTransferred: Int64 = 0,
        errors: [String: Int] = [:]
    ) {
        self.totalRequests = totalRequests
        self.successfulRequests = successfulRequests
        self.failedRequests = failedRequests
        self.averageResponseTime = averageResponseTime
        self.lastRequestTime = lastRequestTime
        self.requestsByTool = requestsByTool
        self.dataTransferred = dataTransferred
        self.errors = errors
    }

    /// Calculate success rate
    var successRate: Double {
        guard totalRequests > 0 else { return 0.0 }
        return Double(successfulRequests) / Double(totalRequests)
    }

    /// Calculate error rate
    var errorRate: Double {
        guard totalRequests > 0 else { return 0.0 }
        return Double(failedRequests) / Double(totalRequests)
    }

    /// Update statistics with new request
    func withRequest(_ request: ClientRequest) -> ClientStatistics {
        let newTotal = totalRequests + 1
        let newSuccessful = successfulRequests + (request.success ? 1 : 0)
        let newFailed = failedRequests + (request.success ? 0 : 1)

        // Calculate new average response time
        let newAverageResponseTime = (averageResponseTime * Double(totalRequests) + request.responseTime) / Double(newTotal)

        // Update requests by tool
        var newRequestsByTool = requestsByTool
        if let toolName = request.toolName {
            newRequestsByTool[toolName, default: 0] += 1
        }

        // Update data transferred
        let newDataTransferred = dataTransferred + Int64(request.requestSize) + Int64(request.responseSize)

        // Update errors
        var newErrors = errors
        if let errorType = request.errorType {
            newErrors[errorType, default: 0] += 1
        }

        return ClientStatistics(
            totalRequests: newTotal,
            successfulRequests: newSuccessful,
            failedRequests: newFailed,
            averageResponseTime: newAverageResponseTime,
            lastRequestTime: request.timestamp,
            requestsByTool: newRequestsByTool,
            dataTransferred: newDataTransferred,
            errors: newErrors
        )
    }

    /// Validate statistics
    func validate() -> ValidationResult {
        var errors: [ValidationError] = []

        if totalRequests < 0 {
            errors.append(ValidationError(
                code: "INVALID_TOTAL_REQUESTS",
                message: "Total requests cannot be negative",
                field: "totalRequests",
                value: totalRequests
            ))
        }

        if successfulRequests < 0 {
            errors.append(ValidationError(
                code: "INVALID_SUCCESSFUL_REQUESTS",
                message: "Successful requests cannot be negative",
                field: "successfulRequests",
                value: successfulRequests
            ))
        }

        if failedRequests < 0 {
            errors.append(ValidationError(
                code: "INVALID_FAILED_REQUESTS",
                message: "Failed requests cannot be negative",
                field: "failedRequests",
                value: failedRequests
            ))
        }

        if averageResponseTime < 0 {
            errors.append(ValidationError(
                code: "INVALID_AVERAGE_RESPONSE_TIME",
                message: "Average response time cannot be negative",
                field: "averageResponseTime",
                value: averageResponseTime
            ))
        }

        if dataTransferred < 0 {
            errors.append(ValidationError(
                code: "INVALID_DATA_TRANSFERRED",
                message: "Data transferred cannot be negative",
                field: "dataTransferred",
                value: dataTransferred
            ))
        }

        return ValidationResult(errors: errors)
    }

    /// Export statistics
    func export() -> [String: Any] {
        return [
            "totalRequests": totalRequests,
            "successfulRequests": successfulRequests,
            "failedRequests": failedRequests,
            "successRate": successRate,
            "errorRate": errorRate,
            "averageResponseTime": averageResponseTime,
            "lastRequestTime": lastRequestTime?.iso8601String as Any,
            "requestsByTool": requestsByTool,
            "dataTransferred": dataTransferred,
            "errors": errors
        ]
    }
}

/// Client request record
struct ClientRequest: Codable, Identifiable {
    let id: UUID
    let clientId: UUID
    let toolName: String?
    let method: String
    let timestamp: Date
    let responseTime: TimeInterval
    let success: Bool
    let requestSize: Int
    let responseSize: Int
    let errorType: String?
    let errorMessage: String?

    init(
        id: UUID = UUID(),
        clientId: UUID,
        toolName: String? = nil,
        method: String,
        timestamp: Date = Date(),
        responseTime: TimeInterval = 0.0,
        success: Bool = false,
        requestSize: Int = 0,
        responseSize: Int = 0,
        errorType: String? = nil,
        errorMessage: String? = nil
    ) {
        self.id = id
        self.clientId = clientId
        self.toolName = toolName
        self.method = method
        self.timestamp = timestamp
        self.responseTime = responseTime
        self.success = success
        self.requestSize = requestSize
        self.responseSize = responseSize
        self.errorType = errorType
        self.errorMessage = errorMessage
    }
}