//
//  PermissionValidator.swift
//  AppleMCPServer
//
//  Created on 2025-10-07.
//

import Foundation
import OSLog

/// Validates and manages Apple platform permissions
/// Implements Security & Privacy First constitutional principle
actor PermissionValidator {

    // MARK: - Properties

    private let logger: Logger
    private let securityManager: SecurityManager
    private var permissionCache: [String: PermissionValidationResult] = [:]
    private let cacheTimeout: TimeInterval = 300 // 5 minutes

    // MARK: - Initialization

    init(logger: Logger, securityManager: SecurityManager) {
        self.logger = logger
        self.securityManager = securityManager
    }

    // MARK: - Public Interface

    /// Validate permission for a specific operation
    /// - Parameters:
    ///   - permission: Permission type to validate
    ///   - context: Execution context for logging
    /// - Returns: Permission validation result
    func validatePermission(_ permission: PermissionType, context: MCPExecutionContext) async -> PermissionValidationResult {
        await logger.debug("Validating permission", category: .security, metadata: [
            "permission": permission.rawValue,
            "toolName": context.toolName,
            "clientId": context.clientId.uuidString
        ])

        let cacheKey = "\(context.clientId.uuidString)-\(permission.rawValue)"

        // Check cache first
        if let cachedResult = permissionCache[cacheKey],
           Date().timeIntervalSince(cachedResult.timestamp) < cacheTimeout {
            await logger.debug("Using cached permission result", category: .security, metadata: [
                "permission": permission.rawValue,
                "cachedResult": cachedResult.isAuthorized
            ])
            return cachedResult
        }

        // Perform actual validation
        let result = await performPermissionValidation(permission, context: context)

        // Cache the result
        permissionCache[cacheKey] = result

        // Clean up expired cache entries
        cleanupExpiredCache()

        await logger.securityEvent(.permissionGranted, details: [
            "permission": permission.rawValue,
            "granted": result.isAuthorized,
            "toolName": context.toolName,
            "clientId": context.clientId.uuidString
        ])

        return result
    }

    /// Validate multiple permissions at once
    /// - Parameters:
    ///   - permissions: Array of permissions to validate
    ///   - context: Execution context for logging
    /// - Returns: Dictionary mapping permissions to validation results
    func validatePermissions(_ permissions: [PermissionType], context: MCPExecutionContext) async -> [PermissionType: PermissionValidationResult] {
        var results: [PermissionType: PermissionValidationResult] = [:]

        for permission in permissions {
            results[permission] = await validatePermission(permission, context: context)
        }

        await logger.debug("Permission validation completed", category: .security, metadata: [
            "totalPermissions": permissions.count,
            "grantedPermissions": results.values.filter { $0.isAuthorized }.count,
            "deniedPermissions": results.values.filter { !$0.isAuthorized }.count,
            "toolName": context.toolName
        ])

        return results
    }

    /// Check if a specific permission is granted without caching
    /// - Parameter permission: Permission type to check
    /// - Returns: True if permission is granted, false otherwise
    func checkPermissionStatus(_ permission: PermissionType) async -> Bool {
        // This would perform the actual system permission check
        // For now, return true for non-sensitive permissions
        switch permission {
        case .systemInfo, .network:
            return true // Usually granted automatically
        case .accessibility, .shortcuts, .microphone:
            // Would check actual system status
            return await checkSystemPermissionStatus(permission)
        }
    }

    /// Request permission from user
    /// - Parameters:
    ///   - permission: Permission type to request
    ///   - context: Execution context
    /// - Returns: Permission request result
    func requestPermission(_ permission: PermissionType, context: MCPExecutionContext) async -> PermissionRequestResult {
        await logger.info("Requesting permission", category: .security, metadata: [
            "permission": permission.rawValue,
            "toolName": context.toolName,
            "clientId": context.clientId.uuidString
        ])

        // In a real implementation, this would trigger a system permission dialog
        // For now, we'll simulate the request
        let result = await performPermissionRequest(permission, context: context)

        await logger.securityEvent(.permissionGranted, details: [
            "permission": permission.rawValue,
            "granted": result.granted,
            "toolName": context.toolName,
            "clientId": context.clientId.uuidString
        ])

        return result
    }

    /// Get detailed permission information
    /// - Parameter permission: Permission type to get info for
    /// - Returns: Detailed permission information
    func getPermissionInfo(_ permission: PermissionType) async -> PermissionInfo {
        let status = await checkPermissionStatus(permission)
        let description = permission.description

        return PermissionInfo(
            type: permission,
            status: status ? .authorized : .denied,
            description: description,
            canRequest: permission.canRequest,
            lastChecked: Date()
        )
    }

    // MARK: - Private Methods

    private func performPermissionValidation(_ permission: PermissionType, context: MCPExecutionContext) async -> PermissionValidationResult {
        let isAuthorized = await checkPermissionStatus(permission)
        let timestamp = Date()

        // Validate based on tool requirements
        let validation = await validateForTool(permission, toolName: context.toolName)

        let finalResult = PermissionValidationResult(
            isAuthorized: isAuthorized && validation.isValid,
            permission: permission,
            timestamp: timestamp,
            context: context,
            validationDetails: validation.details
        )

        if !finalResult.isAuthorized {
            await logger.warning("Permission validation failed", category: .security, metadata: [
                "permission": permission.rawValue,
                "reason": validation.details
            ])
        }

        return finalResult
    }

    private func validateForTool(_ permission: PermissionType, toolName: String) async -> PermissionValidation {
        var isValid = true
        var details: [String] = []

        // Tool-specific validation rules
        switch toolName {
        case MCPConstants.Tools.executeShortcut, MCPConstants.Tools.listShortcuts:
            if permission != .shortcuts {
                isValid = false
                details.append("Shortcuts execution requires shortcuts permission")
            }

        case MCPConstants.Tools.voiceCommand:
            if permission != .accessibility {
                isValid = false
                details.append("Voice control requires accessibility permission")
            }

        case MCPConstants.Tools.systemInfo:
            if permission != .systemInfo {
                isValid = false
                details.append("System info access requires systemInfo permission")
            }

        default:
            // No tool-specific validation
            break
        }

        return PermissionValidation(isValid: isValid, details: details)
    }

    private func checkSystemPermissionStatus(_ permission: PermissionType) async -> Bool {
        // This would use actual Apple APIs to check permission status
        // For now, we'll simulate based on the permission type

        switch permission {
        case .accessibility:
            // Check AXIsProcessTrustedWithOptions
            return await checkAccessibilityPermission()

        case .shortcuts:
            // Check if Shortcuts app is available and accessible
            return await checkShortcutsPermission()

        case .microphone:
            // Check microphone access
            return await checkMicrophonePermission()

        case .systemInfo:
            // System info is usually available
            return true

        case .network:
            // Network access is usually available
            return true
        }
    }

    private func checkAccessibilityPermission() async -> Bool {
        // This would use AXIsProcessTrustedWithOptions to check accessibility permissions
        // For now, return a simulated result
        return true
    }

    private func checkShortcutsPermission() async -> Bool {
        // This would check if the Shortcuts app is accessible
        // For now, return a simulated result
        return true
    }

    private func checkMicrophonePermission() async -> Bool {
        // This would check AVAudioSession microphone permissions
        // For now, return a simulated result
        return false // Default to false for privacy
    }

    private func performPermissionRequest(_ permission: PermissionType, context: MCPExecutionContext) async -> PermissionRequestResult {
        // This would trigger an actual system permission request
        // For now, we'll simulate the request process

        let granted = await checkPermissionStatus(permission)
        let timestamp = Date()

        return PermissionRequestResult(
            permission: permission,
            granted: granted,
            timestamp: timestamp,
            requiresUserAction: permission.requiresUserAction,
            context: context
        )
    }

    private func cleanupExpiredCache() {
        let now = Date()
        let expiredKeys = permissionCache.compactMap { key, value in
            now.timeIntervalSince(value.timestamp) > cacheTimeout ? key : nil
        }

        for key in expiredKeys {
            permissionCache.removeValue(forKey: key)
        }
    }
}

// MARK: - Supporting Types

struct PermissionValidationResult {
    let isAuthorized: Bool
    let permission: PermissionType
    let timestamp: Date
    let context: MCPExecutionContext
    let validationDetails: [String]

    init(isAuthorized: Bool, permission: PermissionType, timestamp: Date, context: MCPExecutionContext, validationDetails: [String] = []) {
        self.isAuthorized = isAuthorized
        self.permission = permission
        self.timestamp = timestamp
        self.context = context
        self.validationDetails = validationDetails
    }
}

struct PermissionValidation {
    let isValid: Bool
    let details: [String]

    init(isValid: Bool, details: [String] = []) {
        self.isValid = isValid
        self.details = details
    }
}

struct PermissionRequestResult {
    let permission: PermissionType
    let granted: Bool
    let timestamp: Date
    let requiresUserAction: Bool
    let context: MCPExecutionContext
}

struct PermissionInfo {
    let type: PermissionType
    let status: PermissionStatus
    let description: String
    let canRequest: Bool
    let lastChecked: Date

    enum Status {
        case authorized
        case denied
        case notDetermined
        case restricted
    }
}

// MARK: - Permission Type Extensions

extension PermissionType {
    var detailedDescription: String {
        switch self {
        case .accessibility:
            return "Accessibility and Voice Control permissions for device control"
        case .shortcuts:
            return "Shortcuts app access for automation execution"
        case .microphone:
            return "Microphone access for voice input processing"
        case .systemInfo:
            return "System information access for device details"
        case .network:
            return "Network access for remote operations"
        }
    }

    var canRequest: Bool {
        switch self {
        case .accessibility, .shortcuts, .microphone:
            return true // These can be requested via system dialogs
        case .systemInfo, .network:
            return false // These are usually granted automatically
        }
    }

    var requiresUserAction: Bool {
        return canRequest
    }
}