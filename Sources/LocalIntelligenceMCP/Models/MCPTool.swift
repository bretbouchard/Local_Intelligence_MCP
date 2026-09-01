//
//  MCPTool.swift
//  LocalIntelligenceMCP
//
//  Tool category taxonomy. The legacy MCPToolDataModel/schema types were
//  removed (dead code, 2026-08-31) — `tools/list` emits authoritative
//  schemas from each tool's registered contract.
//

import Foundation

enum ToolCategory: String, Codable, CaseIterable {
    case general = "general"
    case shortcuts = "shortcuts"
    case voiceControl = "voiceControl"
    case systemInfo = "systemInfo"
    case permission = "permission"
    case security = "security"
    case utility = "utility"
    case textProcessing = "textProcessing"
    case audioDomain = "audioDomain"

    var displayName: String {
        switch self {
        case .general:
            return "General"
        case .shortcuts:
            return "Shortcuts"
        case .voiceControl:
            return "Voice Control"
        case .systemInfo:
            return "System Information"
        case .permission:
            return "Permissions"
        case .security:
            return "Security"
        case .utility:
            return "Utilities"
        case .textProcessing:
            return "Text Processing"
        case .audioDomain:
            return "Audio Domain"
        }
    }

    var description: String {
        switch self {
        case .general:
            return "General purpose tools"
        case .shortcuts:
            return "Apple Shortcuts execution and management"
        case .voiceControl:
            return "Voice control and accessibility commands"
        case .systemInfo:
            return "System information and status"
        case .permission:
            return "Permission management and validation"
        case .security:
            return "Security and privacy tools"
        case .utility:
            return "Utility and helper tools"
        case .textProcessing:
            return "Text analysis, summarization, and processing tools"
        case .audioDomain:
            return "Audio production and engineering domain tools"
        }
    }
}
