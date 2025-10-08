//
//  Types.swift
//  AppleMCPServer
//
//  Created on 2025-10-07.
//

import Foundation

// MARK: - MCP Protocol Types

/// Standard MCP response format
struct MCPResponse: Codable {
    let success: Bool
    let data: AnyCodable?
    let error: MCPError?
    let executionTime: TimeInterval?

    init(success: Bool, data: AnyCodable? = nil, error: MCPError? = nil, executionTime: TimeInterval? = nil) {
        self.success = success
        self.data = data
        self.error = error
        self.executionTime = executionTime
    }

    enum CodingKeys: String, CodingKey {
        case success, data, error, executionTime
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        success = try container.decode(Bool.self, forKey: .success)

        // Handle dynamic data decoding
        if container.contains(.data) {
            data = try container.decodeIfPresent(AnyCodable.self, forKey: .data)
        } else {
            data = nil
        }

        error = try container.decodeIfPresent(MCPError.self, forKey: .error)
        executionTime = try container.decodeIfPresent(TimeInterval.self, forKey: .executionTime)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(success, forKey: .success)
        try container.encodeIfPresent(data, forKey: .data)
        try container.encodeIfPresent(error, forKey: .error)
        try container.encodeIfPresent(executionTime, forKey: .executionTime)
    }
}

/// Standard MCP error format
struct MCPError: Codable, Error {
    let code: String
    let message: String
    let details: [String: AnyCodable]?

    init(code: String, message: String, details: [String: AnyCodable]? = nil) {
        self.code = code
        self.message = message
        self.details = details
    }

    enum CodingKeys: String, CodingKey {
        case code, message, details
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        code = try container.decode(String.self, forKey: .code)
        message = try container.decode(String.self, forKey: .message)

        // Handle dynamic details decoding
        if container.contains(.details) {
            details = try container.decodeIfPresent([String: AnyCodable].self, forKey: .details)
        } else {
            details = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(code, forKey: .code)
        try container.encode(message, forKey: .message)
        try container.encodeIfPresent(details, forKey: .details)
    }

    // Static error types
    static let timeout = MCPError(code: "TIMEOUT", message: "Operation timed out")
    static let notFound = MCPError(code: "NOT_FOUND", message: "Resource not found")
    static let invalidParameters = MCPError(code: "INVALID_PARAMETERS", message: "Invalid parameters provided")
    static let permissionDenied = MCPError(code: "PERMISSION_DENIED", message: "Permission denied")
    static let internalError = MCPError(code: "INTERNAL_ERROR", message: "Internal server error")
}

// MARK: - Validation Types

/// Validation result with detailed information
struct ValidationResult {
    let isValid: Bool
    let errors: [ValidationError]
    let warnings: [ValidationWarning]

    var hasErrors: Bool { !errors.isEmpty }
    var hasWarnings: Bool { !warnings.isEmpty }

    init(isValid: Bool = true, errors: [ValidationError] = [], warnings: [ValidationWarning] = []) {
        self.isValid = isValid && errors.isEmpty
        self.errors = errors
        self.warnings = warnings
    }

    static func valid() -> ValidationResult {
        return ValidationResult()
    }

    static func invalid(errors: [ValidationError]) -> ValidationResult {
        return ValidationResult(isValid: false, errors: errors)
    }

    static func warning(warnings: [ValidationWarning]) -> ValidationResult {
        return ValidationResult(warnings: warnings)
    }
}

/// Validation error with detailed context
struct ValidationError {
    let code: String
    let message: String
    let field: String?
    let value: Any?

    init(code: String, message: String, field: String? = nil, value: Any? = nil) {
        self.code = code
        self.message = message
        self.field = field
        self.value = value
    }
}

/// Validation warning for non-critical issues
struct ValidationWarning {
    let code: String
    let message: String
    let field: String?
    let recommendation: String?

    init(code: String, message: String, field: String? = nil, recommendation: String? = nil) {
        self.code = code
        self.message = message
        self.field = field
        self.recommendation = recommendation
    }
}

// MARK: - Execution Context Types

/// Context for MCP tool execution
struct MCPExecutionContext: Sendable {
    let clientId: UUID
    let requestId: String
    let toolName: String
    let timestamp: Date
    let metadata: [String: AnyCodable]

    init(clientId: UUID, requestId: String, toolName: String, metadata: [String: Any] = [:]) {
        self.clientId = clientId
        self.requestId = requestId
        self.toolName = toolName
        self.timestamp = Date()
        self.metadata = metadata.mapValues { AnyCodable($0) }
    }
}

/// Performance metrics for operations
struct PerformanceMetrics {
    let operation: String
    let startTime: Date
    let endTime: Date
    let success: Bool
    let metadata: [String: Any]

    var duration: TimeInterval {
        return endTime.timeIntervalSince(startTime)
    }

    init(operation: String, startTime: Date, endTime: Date, success: Bool, metadata: [String: Any] = [:]) {
        self.operation = operation
        self.startTime = startTime
        self.endTime = endTime
        self.success = success
        self.metadata = metadata
    }
}

// MARK: - Utility Types

/// Result type with automatic MCP error conversion
typealias MCPResult<T> = Result<T, Error>

extension MCPResult {
    var mcpResponse: MCPResponse {
        switch self {
        case .success(let data):
            return MCPResponse(success: true, data: AnyCodable(data))
        case .failure(let error):
            return MCPResponse(success: false, error: error.mcpError)
        }
    }
}

/// Generic wrapper for any Codable value
struct AnyCodable: Codable, @unchecked Sendable {
    let value: Any

    init<T>(_ value: T) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported type"))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let bool = value as? Bool {
            try container.encode(bool)
        } else if let int = value as? Int {
            try container.encode(int)
        } else if let double = value as? Double {
            try container.encode(double)
        } else if let string = value as? String {
            try container.encode(string)
        } else if let array = value as? [Any] {
            try container.encode(array.map { AnyCodable($0) })
        } else if let dictionary = value as? [String: Any] {
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        } else {
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Unsupported type"))
        }
    }
}

// MARK: - Constants

struct MCPConstants {
    struct ProtocolInfo {
        static let version = "2024-11-05"
        static let name = "model-context-protocol"
    }

    // Legacy accessors for backward compatibility
    struct `Protocol` {
        static let version = ProtocolInfo.version
        static let name = ProtocolInfo.name
    }

    struct Server {
        static let name = "Apple MCP Server"
        static let version = "1.0.0"
        static let maxConcurrentClients = 10
        static let defaultTimeout: TimeInterval = 30.0
    }

    struct Timeouts {
        static let `default` = 30.0
        static let toolExecution = 10.0
        static let systemInfo = 1.0
        static let voiceCommand = 3.0
    }

    struct Tools {
        static let executeShortcut = "execute_shortcut"
        static let listShortcuts = "list_shortcuts"
        static let voiceCommand = "voice_command"
        static let systemInfo = "system_info"
        static let getPermissionStatus = "get_permission_status"
        static let checkPermission = "check_permission"
    }

    struct Limits {
        static let maxToolNameLength = 64
        static let maxToolDescriptionLength = 500
        static let maxShortcutNameLength = 255
        static let maxShortcutDescriptionLength = 1000
        static let maxVoiceCommandLength = 1000
        static let maxParameterValueLength = 10000
        static let maxResultSize = 1024 * 1024 // 1MB
        static let maxClientNameLength = 255
    }

    struct Performance {
        static let toolDiscoveryTimeout: TimeInterval = 2.0
        static let shortcutExecutionTimeout: TimeInterval = 10.0
        static let systemInfoTimeout: TimeInterval = 1.0
        static let voiceCommandTimeout: TimeInterval = 3.0
    }
}

// MARK: - Helper Functions

/// Create a unique request ID
func generateRequestID() -> String {
    return "req_\(UUID().uuidString.lowercased())"
}

/// Create a unique execution ID
func generateExecutionID() -> String {
    return "exec_\(UUID().uuidString.lowercased())"
}

/// Check if a value is nil or empty
func isEmptyOrNil(_ value: Any?) -> Bool {
    if value == nil { return true }

    if let string = value as? String {
        return string.isEmpty
    }

    if let array = value as? [Any] {
        return array.isEmpty
    }

    if let dictionary = value as? [String: Any] {
        return dictionary.isEmpty
    }

    return false
}

/// Format duration for human readable output
func formatDuration(_ duration: TimeInterval) -> String {
    if duration < 1.0 {
        return "\(Int(duration * 1000))ms"
    } else {
        return String(format: "%.2fs", duration)
    }
}

/// Format file size for human readable output
func formatFileSize(_ bytes: Int64) -> String {
    let units = ["B", "KB", "MB", "GB"]
    var size = Double(bytes)
    var unitIndex = 0

    while size >= 1024 && unitIndex < units.count - 1 {
        size /= 1024
        unitIndex += 1
    }

    return String(format: "%.1f %@", size, units[unitIndex])
}