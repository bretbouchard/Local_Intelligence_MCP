//
//  Permission.swift
//  LocalIntelligenceMCP
//
//  Permission taxonomy. The legacy permission workflow data models were
//  removed (dead code, 2026-08-31) — enforcement lives in
//  ToolsRegistry.validatePermissions (real AX/CLI verification).
//

import Foundation

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
