//
//  ShortcutsListTool.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-07.
//
//  GSD Plan 0.2/2.1 — Lists the Shortcuts actually installed on this Mac via
//  the CapabilityRouter (ShortcutsProvider / `shortcuts list`). The previous
//  mock catalog was removed: no fabricated shortcuts, categories, parameters
//  or usage statistics are reported.
//

import Foundation

/// Tool for listing available Apple Shortcuts
class ShortcutsListTool: BaseMCPTool, @unchecked Sendable {

    private let router: CapabilityRouter

    init(logger: Logger, securityManager: SecurityManager, router: CapabilityRouter) {
        self.router = router
        let inputSchema: [String: Any] = [
            "type": "object",
            "properties": [
                "search": [
                    "type": "string",
                    "description": "Filter shortcuts whose name contains this text",
                    "minLength": 1,
                    "maxLength": 100
                ],
                "limit": [
                    "type": "integer",
                    "description": "Maximum number of shortcuts to return (default: 100)",
                    "minimum": 1,
                    "maximum": 500
                ]
            ],
            "description": "List the Shortcuts actually installed on this Mac"
        ]

        super.init(
            name: MCPConstants.Tools.listShortcuts,
            description: "List the Shortcuts actually installed on this Mac (read-only, real enumeration)",
            inputSchema: inputSchema,
            category: .shortcuts,
            requiresPermission: [.shortcuts],
            offlineCapable: true,
            logger: logger,
            securityManager: securityManager
        )
    }

    override func performExecution(parameters: [String: AnyCodable], context: MCPExecutionContext) async throws -> MCPResponse {
        let search = parameters["search"]?.value as? String
        let limit = parameters["limit"]?.value as? Int ?? 100

        let startTime = Date()

        await logger.info("Listing installed shortcuts", category: .shortcuts, metadata: [:])

        do {
            var names = try await router.listAutomation()

            if let search, !search.isEmpty {
                let lowered = search.lowercased()
                names = names.filter { $0.lowercased().contains(lowered) }
            }

            let totalCount = names.count
            let limited = Array(names.sorted().prefix(max(1, min(limit, 500))))

            let executionTime = Date().timeIntervalSince(startTime)

            let result: [String: Any] = [
                "shortcuts": limited,
                "totalCount": totalCount,
                "returnedCount": limited.count,
                "provider": "shortcuts_cli",
                "timestamp": Date().iso8601String,
                "executionTime": executionTime
            ]

            await logger.performance(
                "shortcuts_listing",
                duration: executionTime,
                metadata: [
                    "totalCount": AnyCodable(totalCount),
                    "returnedCount": AnyCodable(limited.count)
                ]
            )

            return MCPResponse(
                success: true,
                data: AnyCodable(result),
                executionTime: executionTime
            )

        } catch let error as CapabilityError {
            let executionTime = Date().timeIntervalSince(startTime)
            await logger.error(
                "Shortcuts listing failed",
                error: error,
                category: .shortcuts,
                metadata: [:]
            )
            return MCPResponse(
                success: false,
                error: error.localMCPError,
                executionTime: executionTime
            )
        }
    }
}
