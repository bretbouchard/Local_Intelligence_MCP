//
//  PermissionTool.swift
//  AppleMCPServer
//
//  Created on 2025-10-07.
//

import Foundation

/// Tool for checking system permission status
class PermissionTool: BaseMCPTool, @unchecked Sendable {

    init(logger: Logger, securityManager: SecurityManager) {
        let inputSchema: [String: Any] = [
            "type": "object",
            "properties": [
                "permissions": [
                    "type": "array",
                    "items": [
                        "type": "string",
                        "enum": ["accessibility", "shortcuts", "microphone", "systemInfo", "network"]
                    ],
                    "description": "Specific permissions to check"
                ]
            ],
            "description": "Check current permission status"
        ]

        super.init(
            name: MCPConstants.Tools.getPermissionStatus,
            description: "Check current permission status for Apple platform features",
            inputSchema: inputSchema,
            category: .utility,
            requiresPermission: [],
            offlineCapable: true,
            logger: logger,
            securityManager: securityManager
        )
    }

    override func performExecution(parameters: [String: AnyCodable], context: MCPExecutionContext) async throws -> MCPResponse {
        let permissionsToCheck = parameters["permissions"]?.value as? [String] ?? []

        let permissionStatuses = try await checkPermissions(permissionsToCheck)

        let result: [String: Any] = [
            "permissions": permissionStatuses.mapValues { $0.export() },
            "timestamp": Date().iso8601String
        ]

        return MCPResponse(success: true, data: AnyCodable(result))
    }

    private func checkPermissions(_ permissions: [String]) async throws -> [String: PermissionToolStatus] {
        var statuses: [String: PermissionToolStatus] = [:]

        for permission in permissions {
            statuses[permission] = try await checkSinglePermission(permission)
        }

        return statuses
    }

    private func checkSinglePermission(_ permission: String) async throws -> PermissionToolStatus {
        // This is a simplified implementation
        // In a real implementation, you would check actual system permissions

        let status: PermissionToolStatus.PermissionStatus
        let canRequest: Bool
        let description: String

        switch permission {
        case "accessibility":
            // Check accessibility permissions
            status = .authorized // Simplified - would check actual status
            canRequest = true
            description = "Accessibility and Voice Control permissions"

        case "shortcuts":
            // Check Shortcuts permissions
            status = .authorized // Simplified - would check actual status
            canRequest = true
            description = "Shortcuts app access permissions"

        case "microphone":
            // Check microphone permissions
            status = .denied // Default to denied for privacy
            canRequest = true
            description = "Microphone access for voice input"

        case "systemInfo":
            // Check system information permissions
            status = .authorized
            canRequest = false // Usually granted automatically
            description = "System information access permissions"

        case "network":
            // Check network permissions
            status = .authorized
            canRequest = false // Usually granted automatically
            description = "Network access permissions"

        default:
            status = .notDetermined
            canRequest = true
            description = "Unknown permission type"
        }

        return PermissionToolStatus(
            status: status,
            description: description,
            canRequest: canRequest
        )
    }
}

struct PermissionToolStatus: Codable {
    let status: PermissionStatus
    let description: String
    let canRequest: Bool

    enum PermissionStatus: String, Codable {
        case authorized = "authorized"
        case denied = "denied"
        case notDetermined = "notDetermined"
        case restricted = "restricted"
    }

    init(status: PermissionStatus, description: String, canRequest: Bool) {
        self.status = status
        self.description = description
        self.canRequest = canRequest
    }

    func export() -> [String: Any] {
        return [
            "status": status.rawValue,
            "description": description,
            "canRequest": canRequest
        ]
    }
}