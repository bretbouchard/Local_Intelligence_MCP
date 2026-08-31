//
//  ShortcutsTool.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-07.
//
//  GSD Plan 0.2/2.1 — Executes real Shortcuts through the CapabilityRouter
//  (ShortcutsProvider / `shortcuts` CLI). No simulated success: didRun is true
//  only when the shortcut actually executed.
//

import Foundation

/// Tool for executing Apple Shortcuts
class ShortcutsTool: BaseMCPTool, @unchecked Sendable {

    private let router: CapabilityRouter

    init(logger: Logger, securityManager: SecurityManager, router: CapabilityRouter) {
        self.router = router
        let inputSchema: [String: Any] = [
            "type": "object",
            "properties": [
                "shortcutName": [
                    "type": "string",
                    "description": "Name of the shortcut to execute",
                    "minLength": 1,
                    "maxLength": 255
                ],
                "input": [
                    "type": "string",
                    "description": "Optional text piped to the shortcut's standard input"
                ],
                "timeout": [
                    "type": "number",
                    "description": "Maximum execution time in seconds (default: 60)",
                    "minimum": 1,
                    "maximum": 300,
                    "default": 60
                ]
            ],
            "required": ["shortcutName"],
            "description": "Execute an Apple Shortcut for real; reports didRun truthfully"
        ]

        super.init(
            name: MCPConstants.Tools.executeShortcut,
            description: "Execute an Apple Shortcut with timeout handling and truthful execution reporting",
            inputSchema: inputSchema,
            category: .shortcuts,
            requiresPermission: [.shortcuts],
            offlineCapable: true,
            logger: logger,
            securityManager: securityManager
        )
    }

    override func performExecution(parameters: [String: AnyCodable], context: MCPExecutionContext) async throws -> MCPResponse {
        guard let shortcutName = parameters["shortcutName"]?.value as? String else {
            throw CapabilityError.invalidRequest("shortcutName parameter is required")
        }
        guard !shortcutName.isEmpty else {
            throw CapabilityError.invalidRequest("shortcutName cannot be empty")
        }

        let input = parameters["input"]?.value as? String
        let timeout = parameters["timeout"]?.value as? Double ?? 60.0

        let startTime = Date()
        await logger.info("Executing shortcut '\(shortcutName)'", category: .shortcuts, metadata: [:])

        do {
            let execution = try await router.executeAutomation(name: shortcutName, input: input, timeout: timeout)
            let executionTime = Date().timeIntervalSince(startTime)

            await logger.performance(
                "shortcut_execution",
                duration: executionTime,
                metadata: [
                    "shortcutName": AnyCodable(shortcutName),
                    "didRun": AnyCodable(execution.didRun),
                    "success": AnyCodable(execution.didRun)
                ]
            )

            let responseData: [String: Any] = [
                "shortcutName": shortcutName,
                "didRun": execution.didRun,
                "executionTime": executionTime,
                "timestamp": Date().iso8601String,
                "output": execution.output,
                "provider": execution.provider.id
            ]

            return MCPResponse(success: execution.didRun, data: AnyCodable(responseData), executionTime: executionTime)

        } catch let error as CapabilityError {
            let executionTime = Date().timeIntervalSince(startTime)
            await logger.error(
                "Shortcut execution failed for '\(shortcutName)'",
                error: error,
                category: .shortcuts,
                metadata: [:]
            )
            let errorResponse: [String: Any] = [
                "shortcutName": shortcutName,
                "didRun": false,
                "executionTime": executionTime,
                "timestamp": Date().iso8601String,
                "error": error.errorDescription ?? error.code,
                "errorCode": error.code
            ]
            return MCPResponse(success: false, data: AnyCodable(errorResponse), error: error.localMCPError, executionTime: executionTime)
        }
    }
}
