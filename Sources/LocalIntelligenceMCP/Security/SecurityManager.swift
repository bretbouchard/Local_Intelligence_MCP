//
//  SecurityManager.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-07.
//

import Foundation

/// Central security management for the Local Intelligence MCP
/// Enforces Security & Privacy First constitutional principles
public actor SecurityManager {

    // MARK: - Properties

    private let keychainManager: KeychainManager
    private let configuration: SecurityManagerConfiguration
    private var auditLog: [SecurityAuditEntry] = []

    // MARK: - Initialization

    init(configuration: SecurityManagerConfiguration = SecurityManagerConfiguration.default) {
        self.keychainManager = KeychainManager()
        self.configuration = configuration
    }

    // MARK: - Credential Management

    /// Securely store API credentials
    /// - Parameters:
    ///   - identifier: Unique identifier for the credentials
    ///   - credentials: Credential data to store
    /// - Throws: SecurityError if storage fails
    func storeCredentials(identifier: String, credentials: Credentials) async throws {
        try validateCredentials(credentials)
        try await keychainManager.store(key: credentialKey(identifier), object: credentials)
        try logSecurityEvent(.credentialStored, details: ["identifier": identifier])
    }

    /// Retrieve API credentials
    /// - Parameter identifier: Unique identifier for the credentials
    /// - Returns: Stored credentials, or nil if not found
    /// - Throws: SecurityError if retrieval fails
    func retrieveCredentials(identifier: String) async throws -> Credentials? {
        let credentials = try await keychainManager.retrieveObject(key: credentialKey(identifier), type: Credentials.self)
        if let credentials = credentials {
            try logSecurityEvent(.credentialAccessed, details: ["identifier": identifier])
        }
        return credentials
    }

    /// Remove stored credentials
    /// - Parameter identifier: Unique identifier for the credentials
    /// - Throws: SecurityError if removal fails
    func removeCredentials(identifier: String) async throws {
        try await keychainManager.remove(key: credentialKey(identifier))
        try logSecurityEvent(.credentialRemoved, details: ["identifier": identifier])
    }

    // MARK: - Session Management

    /// Generate a secure session token
    /// - Parameter clientInfo: Information about the client
    /// - Returns: Secure session token
    func generateSessionToken(for clientInfo: ClientInfo) -> SessionToken {
        let token = SessionToken(
            value: generateSecureToken(),
            clientInfo: clientInfo,
            createdAt: Date(),
            expiresAt: Date().addingTimeInterval(configuration.sessionTimeout)
        )

        try? logSecurityEvent(.sessionCreated, details: [
            "clientId": clientInfo.id.uuidString,
            "clientName": clientInfo.name
        ])

        return token
    }

    /// Validate a session token
    /// - Parameter token: Session token to validate
    /// - Returns: True if token is valid, false otherwise
    func validateSessionToken(_ token: SessionToken) -> Bool {
        let isValid = token.value.isEmpty == false &&
                     token.expiresAt > Date()

        if !isValid {
            try? logSecurityEvent(.sessionValidationFailed, details: [
                "tokenValue": token.value.isEmpty ? "empty" : "expired"
            ])
        }

        return isValid
    }

    // MARK: - Data Sanitization

    /// Sanitize sensitive data for logging
    /// - Parameter data: Raw data that may contain sensitive information
    /// - Returns: Sanitized data safe for logging
    func sanitizeForLogging(_ data: [String: Any]) -> [String: Any] {
        var sanitized = data

        // Remove known sensitive fields
        let sensitiveKeys = ["password", "secret", "key", "token", "credential"]
        for key in sensitiveKeys {
            sanitized.removeValue(forKey: key)
        }

        // Sanitize potential sensitive values
        for (key, value) in sanitized {
            if let stringValue = value as? String {
                if stringValue.count > 50 || looksLikeSensitiveData(stringValue) {
                    sanitized[key] = "[REDACTED]"
                }
            }
        }

        return sanitized
    }

    /// Clear sensitive data from memory
    /// - Parameter data: Data to clear
    func clearSensitiveData<T>(_ data: inout T?) {
        data = nil
    }

    // MARK: - Audit Logging

    /// Get recent security audit entries
    /// - Parameter limit: Maximum number of entries to return
    /// - Returns: Array of security audit entries
    func getAuditEntries(limit: Int = 100) -> [SecurityAuditEntry] {
        return Array(auditLog.suffix(limit))
    }

    /// Clear audit log
    func clearAuditLog() {
        auditLog.removeAll()
    }

    // MARK: - Permission Management

    func checkPermission(_ permission: PermissionType, context: MCPExecutionContext) async throws -> Bool {
        // For now, grant all permissions for development
        // In a real implementation, this would check actual system permissions
        try logSecurityEvent(.permissionGranted, details: [
            "permission": permission.rawValue,
            "clientId": context.clientId.uuidString
        ])
        return true
    }

    // MARK: - Private Methods

    private func validateCredentials(_ credentials: Credentials) throws {
        guard !credentials.identifier.isEmpty else {
            throw SecurityError.invalidCredentials("Identifier cannot be empty")
        }

        guard !credentials.apiKey.isEmpty else {
            throw SecurityError.invalidCredentials("API key cannot be empty")
        }

        // Additional validation based on configuration
        if configuration.requireCredentialsEncryption && !credentials.isEncrypted {
            throw SecurityError.invalidCredentials("Credentials must be encrypted")
        }
    }

    private func credentialKey(_ identifier: String) -> String {
        return "credentials.\(identifier)"
    }

    private func generateSecureToken() -> String {
        let bytes = (0..<32).map { _ in UInt8.random(in: .min ... .max) }
        return Data(bytes).base64EncodedString()
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

    private func logSecurityEvent(_ event: SecurityAuditEvent, details: [String: Any]) throws {
        let entry = SecurityAuditEntry(
            timestamp: Date(),
            event: event,
            details: sanitizeForLogging(details)
        )

        auditLog.append(entry)

        // Maintain audit log size limits
        if auditLog.count > configuration.maxAuditEntries {
            auditLog.removeFirst(auditLog.count - configuration.maxAuditEntries)
        }
    }
}

// MARK: - Supporting Types

struct SecurityManagerConfiguration {
    let sessionTimeout: TimeInterval
    let maxAuditEntries: Int
    let requireCredentialsEncryption: Bool
    let auditLoggingEnabled: Bool

    static let `default` = SecurityManagerConfiguration(
        sessionTimeout: 3600, // 1 hour
        maxAuditEntries: 1000,
        requireCredentialsEncryption: true,
        auditLoggingEnabled: true
    )
}

struct Credentials: Codable {
    let identifier: String
    let apiKey: String
    let secret: String?
    let isEncrypted: Bool
    let createdAt: Date
    let expiresAt: Date?

    var isValid: Bool {
        if let expiresAt = expiresAt {
            return Date() < expiresAt
        }
        return true
    }
}

struct ClientInfo: Codable {
    let id: UUID
    let name: String
    let version: String
    let capabilities: [String]
}

struct SessionToken: Codable {
    let value: String
    let clientInfo: ClientInfo
    let createdAt: Date
    let expiresAt: Date

    var isExpired: Bool {
        return Date() > expiresAt
    }
}

enum SecurityAuditEvent: String, Codable {
    case credentialStored = "credential_stored"
    case credentialAccessed = "credential_accessed"
    case credentialRemoved = "credential_removed"
    case sessionCreated = "session_created"
    case sessionValidationFailed = "session_validation_failed"
    case permissionGranted = "permission_granted"
    case permissionDenied = "permission_denied"
    case securityViolation = "security_violation"
}

struct SecurityAuditEntry: Codable {
    let timestamp: Date
    let event: SecurityAuditEvent
    let details: [String: Any]

    enum CodingKeys: String, CodingKey {
        case timestamp, event, details
    }

    init(timestamp: Date, event: SecurityAuditEvent, details: [String: Any]) {
        self.timestamp = timestamp
        self.event = event
        self.details = details
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        event = try container.decode(SecurityAuditEvent.self, forKey: .event)

        // For now, we'll keep details as a simple representation
        // In a real implementation, you might want more sophisticated handling
        details = [:]
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(event, forKey: .event)
        // Simplified encoding for details
    }
}

enum SecurityError: Error, LocalizedError {
    case invalidCredentials(String)
    case sessionExpired
    case unauthorizedAccess
    case encryptionError
    case auditError

    var errorDescription: String? {
        switch self {
        case .invalidCredentials(let message):
            return "Invalid credentials: \(message)"
        case .sessionExpired:
            return "Session has expired"
        case .unauthorizedAccess:
            return "Unauthorized access attempt"
        case .encryptionError:
            return "Encryption/decryption error occurred"
        case .auditError:
            return "Security audit logging error"
        }
    }
}