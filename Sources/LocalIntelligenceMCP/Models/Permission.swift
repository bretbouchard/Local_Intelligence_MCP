//
//  Permission.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-07.
//

import Foundation

/// Data model for Permission management
/// Aligns with the data-model.md specification
struct PermissionDataModel: Codable, Identifiable {
    let id: UUID
    let type: PermissionType
    let status: PermissionStatus
    let grantedAt: Date?
    let revokedAt: Date?
    let expiresAt: Date?
    let requestedBy: String? // Client identifier
    let reason: String?
    let scope: PermissionScope
    let conditions: [PermissionCondition]
    let auditTrail: [PermissionAuditEntry]

    init(
        id: UUID = UUID(),
        type: PermissionType,
        status: PermissionStatus = .notDetermined,
        grantedAt: Date? = nil,
        revokedAt: Date? = nil,
        expiresAt: Date? = nil,
        requestedBy: String? = nil,
        reason: String? = nil,
        scope: PermissionScope = .full,
        conditions: [PermissionCondition] = [],
        auditTrail: [PermissionAuditEntry] = []
    ) {
        self.id = id
        self.type = type
        self.status = status
        self.grantedAt = grantedAt
        self.revokedAt = revokedAt
        self.expiresAt = expiresAt
        self.requestedBy = requestedBy
        self.reason = reason
        self.scope = scope
        self.conditions = conditions
        self.auditTrail = auditTrail
    }

    /// Update permission status
    func with(status: PermissionStatus, reason: String? = nil) -> PermissionDataModel {
        let now = Date()
        let newGrantedAt = (status == .authorized && self.status != .authorized) ? now : grantedAt
        let newRevokedAt = (status == .denied && self.status != .denied) ? now : revokedAt

        let auditEntry = PermissionAuditEntry(
            timestamp: now,
            action: status == .authorized ? .granted : (status == .denied ? .denied : .modified),
            reason: reason,
            performedBy: "system"
        )

        var newAuditTrail = auditTrail
        newAuditTrail.append(auditEntry)

        return PermissionDataModel(
            id: id,
            type: type,
            status: status,
            grantedAt: newGrantedAt,
            revokedAt: newRevokedAt,
            expiresAt: expiresAt,
            requestedBy: requestedBy,
            reason: reason,
            scope: scope,
            conditions: conditions,
            auditTrail: newAuditTrail
        )
    }

    /// Check if permission is currently valid
    func isValid() -> Bool {
        guard status == .authorized else { return false }

        // Check expiration
        if let expiresAt = expiresAt {
            return Date() < expiresAt
        }

        // Check conditions
        return conditions.allSatisfy { $0.isMet() }
    }

    /// Check if permission has expired
    func isExpired() -> Bool {
        guard let expiresAt = expiresAt else { return false }
        return Date() >= expiresAt
    }

    /// Add audit entry
    func withAuditEntry(_ entry: PermissionAuditEntry) -> PermissionDataModel {
        var newAuditTrail = auditTrail
        newAuditTrail.append(entry)

        return PermissionDataModel(
            id: id,
            type: type,
            status: status,
            grantedAt: grantedAt,
            revokedAt: revokedAt,
            expiresAt: expiresAt,
            requestedBy: requestedBy,
            reason: reason,
            scope: scope,
            conditions: conditions,
            auditTrail: newAuditTrail
        )
    }

    /// Validate permission model
    func validate() -> ValidationResult {
        var errors: [ValidationError] = []

        // Validate granted/revoked timestamps
        if let grantedAt = grantedAt, let revokedAt = revokedAt, grantedAt > revokedAt {
            errors.append(ValidationError(
                code: "INVALID_TIMESTAMPS",
                message: "Granted timestamp cannot be after revoked timestamp",
                field: "grantedAt",
                value: grantedAt
            ))
        }

        // Validate expiration timestamp
        if let expiresAt = expiresAt, let grantedAt = grantedAt, expiresAt <= grantedAt {
            errors.append(ValidationError(
                code: "INVALID_EXPIRATION",
                message: "Expiration timestamp must be after granted timestamp",
                field: "expiresAt",
                value: expiresAt
            ))
        }

        // Validate audit trail
        for (index, entry) in auditTrail.enumerated() {
            let entryValidation = entry.validate()
            errors.append(contentsOf: entryValidation.errors.map { error in
                ValidationError(
                    code: error.code,
                    message: "Audit entry[\(index)]: \(error.message)",
                    field: "auditTrail[\(index)]",
                    value: error.value
                )
            })
        }

        return ValidationResult(errors: errors)
    }

    /// Export permission for MCP format
    func exportForMCP() -> [String: Any] {
        var result: [String: Any] = [
            "id": id.uuidString,
            "type": type.rawValue,
            "status": status.rawValue,
            "scope": scope.rawValue,
            "isValid": isValid(),
            "isExpired": isExpired(),
            "conditions": conditions.map { $0.export() }
        ]

        if let grantedAt = grantedAt {
            result["grantedAt"] = grantedAt.iso8601String
        }

        if let revokedAt = revokedAt {
            result["revokedAt"] = revokedAt.iso8601String
        }

        if let expiresAt = expiresAt {
            result["expiresAt"] = expiresAt.iso8601String
        }

        if let requestedBy = requestedBy {
            result["requestedBy"] = requestedBy
        }

        if let reason = reason {
            result["reason"] = reason
        }

        return result
    }
}

/// Permission status enumeration
enum PermissionStatus: String, Codable, CaseIterable {
    case notDetermined = "notDetermined"
    case authorized = "authorized"
    case denied = "denied"
    case restricted = "restricted"
    case expired = "expired"

    var displayName: String {
        switch self {
        case .notDetermined:
            return "Not Determined"
        case .authorized:
            return "Authorized"
        case .denied:
            return "Denied"
        case .restricted:
            return "Restricted"
        case .expired:
            return "Expired"
        }
    }

    var isGranted: Bool {
        switch self {
        case .authorized:
            return true
        case .notDetermined, .denied, .restricted, .expired:
            return false
        }
    }
}

/// Permission type enumeration (from security module)
public enum PermissionType: String, Codable, CaseIterable, Sendable {
    case accessibility = "accessibility"
    case shortcuts = "shortcuts"
    case microphone = "microphone"
    case systemInfo = "systemInfo"
    case network = "network"
    case voiceControl = "voiceControl"

    var displayName: String {
        switch self {
        case .accessibility:
            return "Accessibility"
        case .shortcuts:
            return "Shortcuts"
        case .microphone:
            return "Microphone"
        case .systemInfo:
            return "System Info"
        case .network:
            return "Network"
        case .voiceControl:
            return "Voice Control"
        }
    }

    var description: String {
        switch self {
        case .accessibility:
            return "Access to accessibility features and voice control"
        case .shortcuts:
            return "Access to run and manage Apple Shortcuts"
        case .microphone:
            return "Access to microphone for voice input"
        case .systemInfo:
            return "Access to system information and status"
        case .network:
            return "Access to network operations"
        case .voiceControl:
            return "Access to voice control and speech recognition"
        }
    }

    var isSensitive: Bool {
        switch self {
        case .accessibility, .shortcuts, .microphone, .voiceControl:
            return true
        case .systemInfo, .network:
            return false
        }
    }
}

/// Permission scope enumeration
enum PermissionScope: String, Codable, CaseIterable {
    case read = "read"
    case write = "write"
    case full = "full"
    case custom = "custom"

    var displayName: String {
        switch self {
        case .read:
            return "Read Only"
        case .write:
            return "Write"
        case .full:
            return "Full Access"
        case .custom:
            return "Custom"
        }
    }
}

/// Permission condition
struct PermissionCondition: Codable, Identifiable {
    let id: UUID
    let type: ConditionType
    let parameters: [String: AnyCodable]
    let isActive: Bool

    init(
        id: UUID = UUID(),
        type: ConditionType,
        parameters: [String: AnyCodable] = [:],
        isActive: Bool = true
    ) {
        self.id = id
        self.type = type
        self.parameters = parameters
        self.isActive = isActive
    }

    /// Check if condition is met
    func isMet() -> Bool {
        guard isActive else { return true }

        switch type {
        case .timeBased:
            return checkTimeBasedCondition()
        case .usageCount:
            return checkUsageCountCondition()
        case .clientBased:
            return checkClientBasedCondition()
        case .locationBased:
            return checkLocationBasedCondition()
        case .custom:
            return checkCustomCondition()
        }
    }

    private func checkTimeBasedCondition() -> Bool {
        // Implementation would check time-based constraints
        // This is a simplified placeholder
        return true
    }

    private func checkUsageCountCondition() -> Bool {
        // Implementation would check usage count limits
        // This is a simplified placeholder
        return true
    }

    private func checkClientBasedCondition() -> Bool {
        // Implementation would check client-specific conditions
        // This is a simplified placeholder
        return true
    }

    private func checkLocationBasedCondition() -> Bool {
        // Implementation would check location-based constraints
        // This is a simplified placeholder
        return true
    }

    private func checkCustomCondition() -> Bool {
        // Implementation would check custom conditions
        // This is a simplified placeholder
        return true
    }

    /// Export condition for MCP format
    func export() -> [String: Any] {
        var result: [String: Any] = [
            "type": type.rawValue,
            "isActive": isActive
        ]

        if !parameters.isEmpty {
            result["parameters"] = parameters.mapValues { $0.value }
        }

        return result
    }
}

/// Condition type enumeration
enum ConditionType: String, Codable, CaseIterable {
    case timeBased = "timeBased"
    case usageCount = "usageCount"
    case clientBased = "clientBased"
    case locationBased = "locationBased"
    case custom = "custom"

    var displayName: String {
        switch self {
        case .timeBased:
            return "Time Based"
        case .usageCount:
            return "Usage Count"
        case .clientBased:
            return "Client Based"
        case .locationBased:
            return "Location Based"
        case .custom:
            return "Custom"
        }
    }
}

/// Permission audit entry
struct PermissionAuditEntry: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let action: AuditAction
    let reason: String?
    let performedBy: String

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        action: AuditAction,
        reason: String? = nil,
        performedBy: String = "system"
    ) {
        self.id = id
        self.timestamp = timestamp
        self.action = action
        self.reason = reason
        self.performedBy = performedBy
    }

    /// Validate audit entry
    func validate() -> ValidationResult {
        var errors: [ValidationError] = []

        if performedBy.isEmpty {
            errors.append(ValidationError(
                code: "INVALID_PERFORMED_BY",
                message: "Performed by cannot be empty",
                field: "performedBy",
                value: performedBy
            ))
        }

        return ValidationResult(errors: errors)
    }

    /// Export audit entry for MCP format
    func export() -> [String: Any] {
        var result: [String: Any] = [
            "id": id.uuidString,
            "timestamp": timestamp.iso8601String,
            "action": action.rawValue,
            "performedBy": performedBy
        ]

        if let reason = reason {
            result["reason"] = reason
        }

        return result
    }
}

/// Audit action enumeration
enum AuditAction: String, Codable, CaseIterable {
    case granted = "granted"
    case denied = "denied"
    case revoked = "revoked"
    case modified = "modified"
    case accessed = "accessed"
    case expired = "expired"

    var displayName: String {
        switch self {
        case .granted:
            return "Granted"
        case .denied:
            return "Denied"
        case .revoked:
            return "Revoked"
        case .modified:
            return "Modified"
        case .accessed:
            return "Accessed"
        case .expired:
            return "Expired"
        }
    }
}

/// Permission request
struct PermissionRequest: Codable {
    let id: UUID
    let type: PermissionType
    let requestedBy: String
    let reason: String
    let scope: PermissionScope
    let conditions: [PermissionCondition]
    let requestedAt: Date
    let expiresAt: Date?
    let priority: RequestPriority

    init(
        id: UUID = UUID(),
        type: PermissionType,
        requestedBy: String,
        reason: String,
        scope: PermissionScope = .full,
        conditions: [PermissionCondition] = [],
        requestedAt: Date = Date(),
        expiresAt: Date? = nil,
        priority: RequestPriority = .normal
    ) {
        self.id = id
        self.type = type
        self.requestedBy = requestedBy
        self.reason = reason
        self.scope = scope
        self.conditions = conditions
        self.requestedAt = requestedAt
        self.expiresAt = expiresAt
        self.priority = priority
    }

    /// Validate permission request
    func validate() -> ValidationResult {
        var errors: [ValidationError] = []

        if requestedBy.isEmpty {
            errors.append(ValidationError(
                code: "INVALID_REQUESTED_BY",
                message: "Requested by cannot be empty",
                field: "requestedBy",
                value: requestedBy
            ))
        }

        if reason.isEmpty {
            errors.append(ValidationError(
                code: "INVALID_REASON",
                message: "Reason cannot be empty",
                field: "reason",
                value: reason
            ))
        }

        if let expiresAt = expiresAt, expiresAt <= requestedAt {
            errors.append(ValidationError(
                code: "INVALID_EXPIRATION",
                message: "Expiration timestamp must be after requested timestamp",
                field: "expiresAt",
                value: expiresAt
            ))
        }

        return ValidationResult(errors: errors)
    }
}

/// Request priority enumeration
enum RequestPriority: String, Codable, CaseIterable {
    case low = "low"
    case normal = "normal"
    case high = "high"
    case urgent = "urgent"

    var displayName: String {
        switch self {
        case .low:
            return "Low"
        case .normal:
            return "Normal"
        case .high:
            return "High"
        case .urgent:
            return "Urgent"
        }
    }
}

/// Permission statistics
struct PermissionStats {
    let totalPermissions: Int
    let grantedPermissions: Int
    let deniedPermissions: Int
    let expiredPermissions: Int
    let pendingRequests: Int
    let mostRequestedTypes: [PermissionType: Int]
    let averageGrantTime: TimeInterval

    init(
        totalPermissions: Int = 0,
        grantedPermissions: Int = 0,
        deniedPermissions: Int = 0,
        expiredPermissions: Int = 0,
        pendingRequests: Int = 0,
        mostRequestedTypes: [PermissionType: Int] = [:],
        averageGrantTime: TimeInterval = 0.0
    ) {
        self.totalPermissions = totalPermissions
        self.grantedPermissions = grantedPermissions
        self.deniedPermissions = deniedPermissions
        self.expiredPermissions = expiredPermissions
        self.pendingRequests = pendingRequests
        self.mostRequestedTypes = mostRequestedTypes
        self.averageGrantTime = averageGrantTime
    }

    /// Calculate grant rate
    var grantRate: Double {
        guard totalPermissions > 0 else { return 0.0 }
        return Double(grantedPermissions) / Double(totalPermissions)
    }

    /// Export statistics for MCP format
    func export() -> [String: Any] {
        return [
            "totalPermissions": totalPermissions,
            "grantedPermissions": grantedPermissions,
            "deniedPermissions": deniedPermissions,
            "expiredPermissions": expiredPermissions,
            "pendingRequests": pendingRequests,
            "grantRate": grantRate,
            "mostRequestedTypes": mostRequestedTypes.mapValues { $0 },
            "averageGrantTime": averageGrantTime
        ]
    }
}