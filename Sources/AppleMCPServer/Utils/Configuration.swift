//
//  Configuration.swift
//  AppleMCPServer
//
//  Created on 2025-10-07.
//

import Foundation

/// Configuration management for the Apple MCP Server
/// Supports loading from files, environment variables, and runtime updates
class Configuration {

    // MARK: - Properties

    private var serverConfig: ServerConfiguration
    private var securityConfig: SecurityConfiguration
    private var featureConfig: FeatureConfiguration
    private var loggingConfig: LoggingConfiguration

    // MARK: - Initialization

    init() {
        self.serverConfig = ServerConfiguration.default
        self.securityConfig = SecurityConfiguration.default
        self.featureConfig = FeatureConfiguration.default
        self.loggingConfig = LoggingConfiguration.default

        // Load configuration from default sources
        loadFromDefaults()
    }

    init(configPath: String) throws {
        self.serverConfig = ServerConfiguration.default
        self.securityConfig = SecurityConfiguration.default
        self.featureConfig = FeatureConfiguration.default
        self.loggingConfig = LoggingConfiguration.default

        try loadFromFile(path: configPath)
    }

    // MARK: - Public Interface

    /// Get server configuration
    var server: ServerConfiguration {
        return serverConfig
    }

    /// Get security configuration
    var security: SecurityConfiguration {
        return securityConfig
    }

    /// Get feature configuration
    var features: FeatureConfiguration {
        return featureConfig
    }

    /// Get logging configuration
    var logging: LoggingConfiguration {
        return loggingConfig
    }

    /// Load configuration from file
    /// - Parameter path: Path to configuration file
    /// - Throws: ConfigurationError if loading fails
    func loadFromFile(path: String) throws {
        let url = URL(fileURLWithPath: path)
        let data = try Data(contentsOf: url)
        let configDict = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        guard let configDict = configDict else {
            throw ConfigurationError.invalidFormat("Configuration file is not valid JSON")
        }

        try parseConfiguration(configDict)
    }

    /// Load configuration from environment variables
    func loadFromEnvironment() {
        // Server configuration from environment
        if let host = ProcessInfo.processInfo.environment["MCP_SERVER_HOST"] {
            serverConfig.host = host
        }

        if let portString = ProcessInfo.processInfo.environment["MCP_SERVER_PORT"],
           let port = Int(portString) {
            serverConfig.port = port
        }

        if let maxClientsString = ProcessInfo.processInfo.environment["MCP_MAX_CLIENTS"],
           let maxClients = Int(maxClientsString) {
            serverConfig.maxClients = maxClients
        }

        // Security configuration from environment
        if let authRequired = ProcessInfo.processInfo.environment["MCP_REQUIRE_AUTH"] {
            securityConfig.requireAuthentication = authRequired.lowercased() == "true"
        }

        if let apiKey = ProcessInfo.processInfo.environment["MCP_API_KEY"] {
            securityConfig.apiKey = apiKey
        }

        // Feature configuration from environment
        if let shortcutsEnabled = ProcessInfo.processInfo.environment["MCP_ENABLE_SHORTCUTS"] {
            featureConfig.shortcuts.enabled = shortcutsEnabled.lowercased() == "true"
        }

        if let voiceControlEnabled = ProcessInfo.processInfo.environment["MCP_ENABLE_VOICE_CONTROL"] {
            featureConfig.voiceControl.enabled = voiceControlEnabled.lowercased() == "true"
        }

        if let systemInfoEnabled = ProcessInfo.processInfo.environment["MCP_ENABLE_SYSTEM_INFO"] {
            featureConfig.systemInfo.enabled = systemInfoEnabled.lowercased() == "true"
        }

        // Logging configuration from environment
        if let logLevel = ProcessInfo.processInfo.environment["MCP_LOG_LEVEL"],
           let level = ConfigurationLogLevel(rawValue: logLevel.lowercased()) {
            loggingConfig.level = level
        }
    }

    /// Load configuration from defaults
    func loadFromDefaults() {
        // Try to load from user's home directory
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let defaultConfigPath = homeDir
            .appendingPathComponent(".config")
            .appendingPathComponent("apple-mcp-server")
            .appendingPathComponent("config.json")
            .path

        if FileManager.default.fileExists(atPath: defaultConfigPath) {
            try? loadFromFile(path: defaultConfigPath)
        }

        // Override with environment variables
        loadFromEnvironment()
    }

    /// Validate current configuration
    /// - Returns: Validation result with any issues found
    func validate() -> ConfigurationValidation {
        var issues: [ConfigurationIssue] = []

        // Validate server configuration
        if serverConfig.port < 1024 || serverConfig.port > 65535 {
            issues.append(.invalidPort(serverConfig.port))
        }

        if serverConfig.maxClients < 1 || serverConfig.maxClients > 100 {
            issues.append(.invalidMaxClients(serverConfig.maxClients))
        }

        // Validate security configuration
        if securityConfig.requireAuthentication && securityConfig.apiKey.isEmpty {
            issues.append(.missingApiKey)
        }

        // Validate feature configuration
        let enabledFeatures = featureConfig.enabledFeatures
        if enabledFeatures.isEmpty {
            issues.append(.noFeaturesEnabled)
        }

        return ConfigurationValidation(
            isValid: issues.isEmpty,
            issues: issues
        )
    }

    /// Export current configuration to dictionary
    /// - Returns: Configuration as dictionary
    func export() -> [String: Any] {
        return [
            "server": serverConfig.export(),
            "security": securityConfig.export(),
            "features": featureConfig.export(),
            "logging": loggingConfig.export()
        ]
    }

    // MARK: - Private Methods

    private func parseConfiguration(_ dict: [String: Any]) throws {
        if let serverDict = dict["server"] as? [String: Any] {
            serverConfig = try ServerConfiguration(from: serverDict)
        }

        if let securityDict = dict["security"] as? [String: Any] {
            securityConfig = try SecurityConfiguration(from: securityDict)
        }

        if let featuresDict = dict["features"] as? [String: Any] {
            featureConfig = try FeatureConfiguration(from: featuresDict)
        }

        if let loggingDict = dict["logging"] as? [String: Any] {
            loggingConfig = try LoggingConfiguration(from: loggingDict)
        }
    }
}

// MARK: - Configuration Types

struct ServerConfiguration: Codable {
    var host: String
    var port: Int
    var maxClients: Int
    var enableTLS: Bool
    var certFile: String?
    var keyFile: String?

    init(
        host: String,
        port: Int,
        maxClients: Int,
        enableTLS: Bool,
        certFile: String?,
        keyFile: String?
    ) {
        self.host = host
        self.port = port
        self.maxClients = maxClients
        self.enableTLS = enableTLS
        self.certFile = certFile
        self.keyFile = keyFile
    }

    static let `default` = ServerConfiguration(
        host: "localhost",
        port: 8050,
        maxClients: 10,
        enableTLS: false,
        certFile: nil,
        keyFile: nil
    )

    init(from dict: [String: Any]) throws {
        host = dict["host"] as? String ?? Self.default.host
        port = dict["port"] as? Int ?? Self.default.port
        maxClients = dict["maxClients"] as? Int ?? Self.default.maxClients
        enableTLS = dict["enableTLS"] as? Bool ?? Self.default.enableTLS
        certFile = dict["certFile"] as? String
        keyFile = dict["keyFile"] as? String
    }

    func export() -> [String: Any] {
        var dict: [String: Any] = [
            "host": host,
            "port": port,
            "maxClients": maxClients,
            "enableTLS": enableTLS
        ]

        if let certFile = certFile {
            dict["certFile"] = certFile
        }

        if let keyFile = keyFile {
            dict["keyFile"] = keyFile
        }

        return dict
    }
}

struct SecurityConfiguration: Codable {
    var requireAuthentication: Bool
    var apiKey: String
    var allowedClients: [String]
    var sessionTimeout: TimeInterval
    var maxAuditEntries: Int
    var requireCredentialsEncryption: Bool

    init(
        requireAuthentication: Bool = false,
        apiKey: String = "",
        allowedClients: [String] = ["localhost", "127.0.0.1"],
        sessionTimeout: TimeInterval = 3600,
        maxAuditEntries: Int = 1000,
        requireCredentialsEncryption: Bool = true
    ) {
        self.requireAuthentication = requireAuthentication
        self.apiKey = apiKey
        self.allowedClients = allowedClients
        self.sessionTimeout = sessionTimeout
        self.maxAuditEntries = maxAuditEntries
        self.requireCredentialsEncryption = requireCredentialsEncryption
    }

    static let `default` = SecurityConfiguration()

    init(from dict: [String: Any]) throws {
        requireAuthentication = dict["requireAuthentication"] as? Bool ?? Self.default.requireAuthentication
        apiKey = dict["apiKey"] as? String ?? Self.default.apiKey
        allowedClients = dict["allowedClients"] as? [String] ?? Self.default.allowedClients
        sessionTimeout = dict["sessionTimeout"] as? TimeInterval ?? Self.default.sessionTimeout
        maxAuditEntries = dict["maxAuditEntries"] as? Int ?? Self.default.maxAuditEntries
        requireCredentialsEncryption = dict["requireCredentialsEncryption"] as? Bool ?? Self.default.requireCredentialsEncryption
    }

    func export() -> [String: Any] {
        return [
            "requireAuthentication": requireAuthentication,
            "apiKey": apiKey.isEmpty ? "" : "[REDACTED]",
            "allowedClients": allowedClients,
            "sessionTimeout": sessionTimeout,
            "maxAuditEntries": maxAuditEntries,
            "requireCredentialsEncryption": requireCredentialsEncryption
        ]
    }
}

struct FeatureConfiguration: Codable {
    var shortcuts: ShortcutConfig
    var voiceControl: VoiceControlConfig
    var systemInfo: SystemInfoConfig

    init(
        shortcuts: ShortcutConfig = ShortcutConfig(enabled: true, cacheTimeout: 300),
        voiceControl: VoiceControlConfig = VoiceControlConfig(enabled: true, confidenceThreshold: 0.7),
        systemInfo: SystemInfoConfig = SystemInfoConfig(enabled: true, refreshInterval: 60)
    ) {
        self.shortcuts = shortcuts
        self.voiceControl = voiceControl
        self.systemInfo = systemInfo
    }

    static let `default` = FeatureConfiguration()

    init(from dict: [String: Any]) throws {
        if let shortcutsDict = dict["shortcuts"] as? [String: Any] {
            shortcuts = try ShortcutConfig(from: shortcutsDict)
        } else {
            shortcuts = Self.default.shortcuts
        }

        if let voiceControlDict = dict["voiceControl"] as? [String: Any] {
            voiceControl = try VoiceControlConfig(from: voiceControlDict)
        } else {
            voiceControl = Self.default.voiceControl
        }

        if let systemInfoDict = dict["systemInfo"] as? [String: Any] {
            systemInfo = try SystemInfoConfig(from: systemInfoDict)
        } else {
            systemInfo = Self.default.systemInfo
        }
    }

    var enabledFeatures: [String] {
        var features: [String] = []
        if shortcuts.enabled { features.append("shortcuts") }
        if voiceControl.enabled { features.append("voiceControl") }
        if systemInfo.enabled { features.append("systemInfo") }
        return features
    }

    func export() -> [String: Any] {
        return [
            "shortcuts": shortcuts.export(),
            "voiceControl": voiceControl.export(),
            "systemInfo": systemInfo.export()
        ]
    }
}

struct ShortcutConfig: Codable {
    var enabled: Bool
    var cacheTimeout: TimeInterval

    init(enabled: Bool, cacheTimeout: TimeInterval) {
        self.enabled = enabled
        self.cacheTimeout = cacheTimeout
    }

    init(from dict: [String: Any]) throws {
        enabled = dict["enabled"] as? Bool ?? true
        cacheTimeout = dict["cacheTimeout"] as? TimeInterval ?? 300
    }

    func export() -> [String: Any] {
        return [
            "enabled": enabled,
            "cacheTimeout": cacheTimeout
        ]
    }
}

struct VoiceControlConfig: Codable {
    var enabled: Bool
    var confidenceThreshold: Float

    init(enabled: Bool, confidenceThreshold: Float) {
        self.enabled = enabled
        self.confidenceThreshold = confidenceThreshold
    }

    init(from dict: [String: Any]) throws {
        enabled = dict["enabled"] as? Bool ?? true
        confidenceThreshold = dict["confidenceThreshold"] as? Float ?? 0.7
    }

    func export() -> [String: Any] {
        return [
            "enabled": enabled,
            "confidenceThreshold": confidenceThreshold
        ]
    }
}

struct SystemInfoConfig: Codable {
    var enabled: Bool
    var refreshInterval: TimeInterval

    init(enabled: Bool, refreshInterval: TimeInterval) {
        self.enabled = enabled
        self.refreshInterval = refreshInterval
    }

    init(from dict: [String: Any]) throws {
        enabled = dict["enabled"] as? Bool ?? true
        refreshInterval = dict["refreshInterval"] as? TimeInterval ?? 60
    }

    func export() -> [String: Any] {
        return [
            "enabled": enabled,
            "refreshInterval": refreshInterval
        ]
    }
}

struct LoggingConfiguration: Codable {
    var level: ConfigurationLogLevel
    var file: String?
    var maxSize: Int
    var maxFiles: Int
    var enableConsole: Bool

    init(level: ConfigurationLogLevel, file: String?, maxSize: Int, maxFiles: Int, enableConsole: Bool) {
        self.level = level
        self.file = file
        self.maxSize = maxSize
        self.maxFiles = maxFiles
        self.enableConsole = enableConsole
    }

    static let `default` = LoggingConfiguration(
        level: .info,
        file: nil,
        maxSize: 10 * 1024 * 1024, // 10MB
        maxFiles: 5,
        enableConsole: true
    )

    init(from dict: [String: Any]) throws {
        if let levelString = dict["level"] as? String,
           let foundLevel = ConfigurationLogLevel(rawValue: levelString.lowercased()) {
            self.level = foundLevel
        } else {
            self.level = Self.default.level
        }

        file = dict["file"] as? String
        maxSize = dict["maxSize"] as? Int ?? Self.default.maxSize
        maxFiles = dict["maxFiles"] as? Int ?? Self.default.maxFiles
        enableConsole = dict["enableConsole"] as? Bool ?? Self.default.enableConsole
    }

    func export() -> [String: Any] {
        return [
            "level": level.rawValue,
            "file": file as Any,
            "maxSize": maxSize,
            "maxFiles": maxFiles,
            "enableConsole": enableConsole
        ]
    }
}

enum ConfigurationLogLevel: String, Codable, CaseIterable {
    case debug = "debug"
    case info = "info"
    case warning = "warning"
    case error = "error"
    case critical = "critical"
}

// MARK: - Error Types

enum ConfigurationError: Error, LocalizedError {
    case fileNotFound(String)
    case invalidFormat(String)
    case parseError(String)
    case validationError(String)

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "Configuration file not found: \(path)"
        case .invalidFormat(let message):
            return "Invalid configuration format: \(message)"
        case .parseError(let message):
            return "Configuration parsing error: \(message)"
        case .validationError(let message):
            return "Configuration validation error: \(message)"
        }
    }
}

struct ConfigurationValidation {
    let isValid: Bool
    let issues: [ConfigurationIssue]
}

enum ConfigurationIssue {
    case invalidPort(Int)
    case invalidMaxClients(Int)
    case missingApiKey
    case noFeaturesEnabled
    case invalidLogLevel(String)
    case invalidFilePermission(String)

    var description: String {
        switch self {
        case .invalidPort(let port):
            return "Invalid port number: \(port). Must be between 1024 and 65535."
        case .invalidMaxClients(let maxClients):
            return "Invalid max clients: \(maxClients). Must be between 1 and 100."
        case .missingApiKey:
            return "API key is required when authentication is enabled."
        case .noFeaturesEnabled:
            return "At least one feature must be enabled."
        case .invalidLogLevel(let level):
            return "Invalid log level: \(level)."
        case .invalidFilePermission(let file):
            return "Invalid file permissions for: \(file)."
        }
    }
}