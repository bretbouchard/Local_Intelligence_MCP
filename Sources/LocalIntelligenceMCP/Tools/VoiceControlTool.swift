//
//  VoiceControlTool.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-07.
//
//  GSD Plan 0.2 — The previous implementation simulated voice recognition and
//  command execution (fabricated confidence scores and random success). macOS
//  provides no supported external API for driving Voice Control from a
//  background process, so this tool now reports truthful unavailability and
//  never claims a side effect occurred. Do not re-add simulation; genuine
//  accessibility automation, if ever added, must be a separate opt-in
//  provider with explicit permission state (GSD Plan 2.3).
//

import Foundation

/// Tool stub that reports Voice Control as unavailable (no genuine backend).
class VoiceControlTool: BaseMCPTool, @unchecked Sendable {

    init(logger: Logger, securityManager: SecurityManager) {
        let inputSchema: [String: Any] = [
            "type": "object",
            "properties": [
                "command": [
                    "type": "string",
                    "description": "Voice command that would be executed",
                    "minLength": 1,
                    "maxLength": 200
                ]
            ],
            "required": ["command"],
            "description": "Voice Control execution — currently unavailable on all systems"
        ]

        super.init(
            name: MCPConstants.Tools.voiceCommand,
            description: "Voice Control command execution. Unavailable: macOS provides no supported API for external Voice Control automation. This tool never executes anything.",
            inputSchema: inputSchema,
            category: .voiceControl,
            requiresPermission: [], // no backend exists; demanding a grant would imply one enables the tool
            offlineCapable: true,
            logger: logger,
            securityManager: securityManager
        )
    }

    override func performExecution(parameters: [String: AnyCodable], context: MCPExecutionContext) async throws -> MCPResponse {
        let error = CapabilityError.unsupported(
            reason: "Voice Control automation is not implemented: macOS exposes no supported API for an external process to drive Voice Control. Requests are never simulated."
        )

        await logger.info(
            "voice_command reported unavailable (no genuine backend)",
            category: .voiceControl,
            metadata: [:]
        )

        let responseData: [String: Any] = [
            "available": false,
            "reason": "No supported macOS API for external Voice Control automation",
            "errorCode": error.code,
            "note": "Genuine accessibility automation would be a separate opt-in provider (GSD Plan 2.3)."
        ]

        return MCPResponse(success: false, data: AnyCodable(responseData), error: error.localMCPError)
    }
}
