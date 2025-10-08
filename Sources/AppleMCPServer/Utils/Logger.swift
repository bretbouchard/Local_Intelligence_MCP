//
//  Logger.swift
//  AppleMCPServer
//
//  Created on 2025-10-07.
//

import Foundation
import OSLog

/// Centralized logging system for the Apple MCP Server
/// Provides structured logging with security-aware sanitization
actor Logger {

    // MARK: - Properties

    private let subsystem = "com.apple.mcp.server"
    private let osLog: OSLog
    private let config: LoggingConfiguration
    private var fileHandle: FileHandle?
    private var logBuffer: [LogEntry] = []

    // MARK: - Initialization

    init(configuration: LoggingConfiguration = .default) {
        self.config = configuration
        self.osLog = OSLog(subsystem: subsystem, category: "AppleMCPServer")
    }

    // Async setup method for file logging
    func setupFileLoggingIfNeeded() async {
        if let logFile = config.file {
            setupFileLogging(path: logFile)
        }
    }

    // MARK: - Public Logging Interface

    /// Log debug message
    /// - Parameters:
    ///   - message: Message to log
    ///   - category: Log category for grouping
    ///   - metadata: Additional metadata
    func debug(_ message: String, category: LogCategory = .general, metadata: [String: Any] = [:]) {
        log(level: .debug, message: message, category: category, metadata: metadata)
    }

    /// Log info message
    /// - Parameters:
    ///   - message: Message to log
    ///   - category: Log category for grouping
    ///   - metadata: Additional metadata
    func info(_ message: String, category: LogCategory = .general, metadata: [String: Any] = [:]) {
        log(level: .info, message: message, category: category, metadata: metadata)
    }

    /// Log warning message
    /// - Parameters:
    ///   - message: Message to log
    ///   - category: Log category for grouping
    ///   - metadata: Additional metadata
    func warning(_ message: String, category: LogCategory = .general, metadata: [String: Any] = [:]) {
        log(level: .warning, message: message, category: category, metadata: metadata)
    }

    /// Log error message
    /// - Parameters:
    ///   - message: Message to log
    ///   - error: Associated error
    ///   - category: Log category for grouping
    ///   - metadata: Additional metadata
    func error(_ message: String, error: Error? = nil, category: LogCategory = .general, metadata: [String: Any] = [:]) {
        var errorMetadata = metadata
        if let error = error {
            errorMetadata["error"] = error.localizedDescription
            errorMetadata["errorType"] = String(describing: type(of: error))
        }
        log(level: .error, message: message, category: category, metadata: errorMetadata)
    }

    /// Log critical message
    /// - Parameters:
    ///   - message: Message to log
    ///   - error: Associated error
    ///   - category: Log category for grouping
    ///   - metadata: Additional metadata
    func critical(_ message: String, error: Error? = nil, category: LogCategory = .general, metadata: [String: Any] = [:]) {
        var errorMetadata = metadata
        if let error = error {
            errorMetadata["error"] = error.localizedDescription
            errorMetadata["errorType"] = String(describing: type(of: error))
        }
        log(level: .critical, message: message, category: category, metadata: errorMetadata)
    }

    /// Log MCP protocol message
    /// - Parameters:
    ///   - direction: Message direction (inbound/outbound)
    ///   - messageId: MCP message ID
    ///   - method: MCP method name
    ///   - metadata: Additional metadata
    func mcpMessage(direction: MCPMessageDirection, messageId: String, method: String, metadata: [String: Any] = [:]) {
        var mcpMetadata = metadata
        mcpMetadata["direction"] = direction.rawValue
        mcpMetadata["messageId"] = messageId
        mcpMetadata["method"] = method

        let message = "MCP \(direction.rawValue): \(method)"
        log(level: .debug, message: message, category: .mcp, metadata: mcpMetadata)
    }

    /// Log security event
    /// - Parameters:
    ///   - event: Security event type
    ///   - clientId: Client identifier (sanitized)
    ///   - details: Event details (will be sanitized)
    func securityEvent(_ event: SecurityEventType, clientId: String? = nil, details: [String: Any] = [:]) {
        var securityMetadata = details
        securityMetadata["eventType"] = event.rawValue

        if let clientId = clientId {
            securityMetadata["clientId"] = sanitizeClientId(clientId)
        }

        let message = "Security event: \(event.rawValue)"
        log(level: .info, message: message, category: .security, metadata: securityMetadata)
    }

    /// Log performance metric
    /// - Parameters:
    ///   - operation: Operation being measured
    ///   - duration: Duration in seconds
    ///   - metadata: Additional metrics
    func performance(_ operation: String, duration: TimeInterval, metadata: [String: Any] = [:]) {
        var performanceMetadata = metadata
        performanceMetadata["duration"] = duration
        performanceMetadata["operation"] = operation

        let message = "Performance: \(operation) (\(String(format: "%.3f", duration))s)"
        log(level: .debug, message: message, category: .performance, metadata: performanceMetadata)
    }

    // MARK: - Log Management

    /// Get recent log entries
    /// - Parameters:
    ///   - limit: Maximum number of entries to return
    ///   - level: Minimum log level to include
    ///   - category: Filter by category (optional)
    /// - Returns: Array of log entries
    func getRecentEntries(limit: Int = 100, level: LogLevel? = nil, category: LogCategory? = nil) -> [LogEntry] {
        var filtered = logBuffer

        if let level = level {
            filtered = filtered.filter { $0.level >= level }
        }

        if let category = category {
            filtered = filtered.filter { $0.category == category }
        }

        return Array(filtered.suffix(limit))
    }

    /// Clear log buffer
    func clearLogBuffer() {
        logBuffer.removeAll()
    }

    /// Flush logs to file
    func flushToFile() {
        guard let fileHandle = fileHandle else { return }

        for entry in logBuffer {
            if let logLine = formatLogEntry(entry) {
                if let data = (logLine + "\n").data(using: .utf8) {
                    fileHandle.write(data)
                }
            }
        }

        fileHandle.synchronizeFile()
        logBuffer.removeAll()
    }

    // MARK: - Private Methods

    private func log(level: LogLevel, message: String, category: LogCategory, metadata: [String: Any]) {
        // Convert ConfigurationLogLevel (String) to LogLevel (Int) for comparison
        let configLogLevel = LogLevel.fromString(config.level.rawValue)
        guard level.rawValue >= configLogLevel.rawValue else { return }

        let entry = LogEntry(
            timestamp: Date(),
            level: level,
            category: category,
            message: message,
            metadata: sanitizeMetadata(metadata)
        )

        // Add to buffer
        logBuffer.append(entry)

        // Maintain buffer size
        if logBuffer.count > 1000 {
            logBuffer.removeFirst(logBuffer.count - 1000)
        }

        // Console logging
        if config.enableConsole {
            os_log("%{public}@", log: osLog, type: level.osLogType, entry.formattedMessage)
        }

        // File logging (async)
        if config.file != nil {
            Task {
                await flushToFile()
            }
        }
    }

    private func setupFileLogging(path: String) {
        let logURL = URL(fileURLWithPath: path)

        // Create directory if it doesn't exist
        let directory = logURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        // Create or open log file
        if !FileManager.default.fileExists(atPath: path) {
            FileManager.default.createFile(atPath: path, contents: nil)
        }

        do {
            fileHandle = try FileHandle(forWritingTo: logURL)
            fileHandle?.seekToEndOfFile()
        } catch {
            // Fallback to console logging if file setup fails
            print("Failed to setup file logging: \(error)")
        }
    }

    private func sanitizeMetadata(_ metadata: [String: Any]) -> [String: Any] {
        var sanitized = metadata

        // Remove known sensitive keys
        let sensitiveKeys = ["password", "secret", "key", "token", "credential", "apiKey"]
        for key in sensitiveKeys {
            sanitized.removeValue(forKey: key)
        }

        // Sanitize potential sensitive values
        for (key, value) in sanitized {
            if let stringValue = value as? String {
                if looksLikeSensitiveData(stringValue) {
                    sanitized[key] = "[REDACTED]"
                }
            }
        }

        return sanitized
    }

    private func sanitizeClientId(_ clientId: String) -> String {
        // Show only first 4 and last 4 characters of client ID
        guard clientId.count > 8 else {
            return clientId
        }

        let prefix = String(clientId.prefix(4))
        let suffix = String(clientId.suffix(4))
        return "\(prefix)****\(suffix)"
    }

    private func looksLikeSensitiveData(_ string: String) -> Bool {
        let patterns = [
            "^[A-Za-z0-9+/]{40,}=$",  // Base64 encoded data
            "^[a-f0-9]{32,}$",         // Hexadecimal
            "sk_[a-zA-Z0-9]{20,}",      // API key pattern
            "[0-9]{4}-[0-9]{4}-[0-9]{4}-[0-9]{4}"  // UUID pattern
        ]

        return patterns.contains { pattern in
            string.range(of: pattern, options: .regularExpression) != nil
        }
    }

    private func formatLogEntry(_ entry: LogEntry) -> String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        let timestamp = formatter.string(from: entry.timestamp)

        var logLine = "\(timestamp) [\(String(describing: entry.level).uppercased())] [\(entry.category.rawValue)] \(entry.message)"

        if !entry.metadata.isEmpty {
            let metadataString = entry.metadata.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
            logLine += " | \(metadataString)"
        }

        return logLine
    }
}

// MARK: - Supporting Types

enum LogCategory: String, CaseIterable {
    case general = "general"
    case server = "server"
    case mcp = "mcp"
    case security = "security"
    case performance = "performance"
    case shortcuts = "shortcuts"
    case voiceControl = "voiceControl"
    case systemInfo = "systemInfo"
    case productivity = "productivity"
    case communication = "communication"
    case multimedia = "multimedia"
    case system = "system"
    case utilities = "utilities"
}

enum LogLevel: Int, CaseIterable, Comparable {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3
    case critical = 4

    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }

    var osLogType: OSLogType {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .default
        case .error: return .error
        case .critical: return .fault
        }
    }

    static func fromString(_ string: String) -> LogLevel {
        switch string.lowercased() {
        case "debug": return .debug
        case "info": return .info
        case "warning", "warn": return .warning
        case "error": return .error
        case "critical", "crit": return .critical
        default: return .info
        }
    }
}

enum MCPMessageDirection: String {
    case inbound = "INBOUND"
    case outbound = "OUTBOUND"
}

enum SecurityEventType: String {
    case clientConnected = "client_connected"
    case clientDisconnected = "client_disconnected"
    case authenticationSuccess = "auth_success"
    case authenticationFailure = "auth_failure"
    case permissionGranted = "permission_granted"
    case permissionDenied = "permission_denied"
    case rateLimitExceeded = "rate_limit_exceeded"
    case suspiciousActivity = "suspicious_activity"
}

struct LogEntry {
    let timestamp: Date
    let level: LogLevel
    let category: LogCategory
    let message: String
    let metadata: [String: Any]

    var formattedMessage: String {
        var formatted = "[\(category.rawValue)] \(message)"
        if !metadata.isEmpty {
            let metadataString = metadata.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
            formatted += " | \(metadataString)"
        }
        return formatted
    }
}

// MARK: - Convenience Extensions

extension Logger {
    /// Create a logger for specific category
    func category(_ category: LogCategory) -> CategoryLogger {
        return CategoryLogger(logger: self, category: category)
    }
}

struct CategoryLogger {
    private let logger: Logger
    private let category: LogCategory

    init(logger: Logger, category: LogCategory) {
        self.logger = logger
        self.category = category
    }

    func debug(_ message: String, metadata: [String: Any] = [:]) {
        // Simple synchronous call - let caller handle async if needed
        Task { @MainActor in
            await logger.debug(message, category: category, metadata: metadata.sanitizedForLogging())
        }
    }

    func info(_ message: String, metadata: [String: Any] = [:]) {
        // Simple synchronous call - let caller handle async if needed
        Task { @MainActor in
            await logger.info(message, category: category, metadata: metadata.sanitizedForLogging())
        }
    }

    func warning(_ message: String, metadata: [String: Any] = [:]) {
        // Simple synchronous call - let caller handle async if needed
        Task { @MainActor in
            await logger.warning(message, category: category, metadata: metadata.sanitizedForLogging())
        }
    }

    func error(_ message: String, error: Error? = nil, metadata: [String: Any] = [:]) {
        // Simple synchronous call - let caller handle async if needed
        Task { @MainActor in
            await logger.error(message, error: error, category: category, metadata: metadata.sanitizedForLogging())
        }
    }

    func critical(_ message: String, error: Error? = nil, metadata: [String: Any] = [:]) {
        // Simple synchronous call - let caller handle async if needed
        Task { @MainActor in
            await logger.critical(message, error: error, category: category, metadata: metadata.sanitizedForLogging())
        }
    }
}