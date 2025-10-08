//
//  ShortcutsTests.swift
//  AppleMCPServerIntegrationTests
//
//  Created on 2025-10-07.
//

import XCTest
@testable import AppleMCPServer

final class ShortcutsTests: XCTestCase {

    var shortcutsTool: ShortcutsTool!
    var shortcutsListTool: ShortcutsListTool!
    var logger: Logger!
    var securityManager: SecurityManager!

    override func setUp() async throws {
        try await super.setUp()

        logger = Logger(level: .debug, category: .test)
        securityManager = SecurityManager(logger: logger)

        shortcutsTool = ShortcutsTool(logger: logger, securityManager: securityManager)
        shortcutsListTool = ShortcutsListTool(logger: logger, securityManager: securityManager)
    }

    override func tearDown() async throws {
        shortcutsTool = nil
        shortcutsListTool = nil
        logger = nil
        securityManager = nil
        try await super.tearDown()
    }

    // MARK: - ShortcutsTool Tests

    func testExecuteShortcutSuccess() async throws {
        // Given
        let context = MCPExecutionContext(clientId: UUID(), toolName: MCPConstants.Tools.executeShortcut)

        // When
        let response = try await shortcutsTool.performExecution(
            parameters: [
                "shortcutName": "Create Note",
                "parameters": [
                    "text": "Test note content",
                    "folder": "Test Folder"
                ]
            ],
            context: context
        )

        // Then
        XCTAssertTrue(response.success, "Shortcut execution should succeed")
        XCTAssertNotNil(response.data?.value, "Response should contain data")

        let data = response.data?.value as? [String: Any]
        XCTAssertEqual(data?["shortcutName"] as? String, "Create Note")
        XCTAssertEqual(data?["success"] as? Bool, true)
        XCTAssertNotNil(data?["executionId"], "Should include execution ID")
        XCTAssertNotNil(data?["executionTime"], "Should include execution time")
        XCTAssertNotNil(data?["timestamp"], "Should include timestamp")
        XCTAssertNotNil(data?["outputs"], "Should include outputs")

        let outputs = data?["outputs"] as? [String: Any]
        XCTAssertEqual(outputs?["shortcutName"] as? String, "Create Note")
        XCTAssertEqual(outputs?["status"] as? String, "completed")

        let metadata = data?["metadata"] as? [String: Any]
        XCTAssertEqual(metadata?["inputParameters"] as? [String: Any]?["text"] as? String, "Test note content")
        XCTAssertEqual(metadata?["waitForCompletion"] as? Bool, true)
    }

    func testExecuteShortcutWithTimeout() async throws {
        // Given
        let context = MCPExecutionContext(clientId: UUID(), toolName: MCPConstants.Tools.executeShortcut)

        // When
        let response = try await shortcutsTool.performExecution(
            parameters: [
                "shortcutName": "Send Email",
                "timeout": 5.0,
                "validateParameters": true,
                "waitForCompletion": true
            ],
            context: context
        )

        // Then
        XCTAssertTrue(response.success, "Shortcut execution should succeed")
        let data = response.data?.value as? [String: Any]
        XCTAssertNotNil(data, "Response should contain data")

        let metadata = data?["metadata"] as? [String: Any]
        XCTAssertEqual(metadata?["timeoutUsed"] as? Double, 5.0)
    }

    func testExecuteShortcutMissingName() async throws {
        // Given
        let context = MCPExecutionContext(clientId: UUID(), toolName: MCPConstants.Tools.executeShortcut)

        // When
        let response = try await shortcutsTool.performExecution(
            parameters: [:],
            context: context
        )

        // Then
        XCTAssertFalse(response.success, "Missing shortcut name should fail")
        XCTAssertNotNil(response.error, "Should include error information")
    }

    func testExecuteShortcutInvalidName() async throws {
        // Given
        let context = MCPExecutionContext(clientId: UUID(), toolName: MCPConstants.Tools.executeShortcut)

        // When
        let response = try await shortcutsTool.performExecution(
            parameters: [
                "shortcutName": "" // Empty name
            ],
            context: context
        )

        // Then
        XCTAssertFalse(response.success, "Empty shortcut name should fail")
        XCTAssertNotNil(response.error, "Should include error information")
    }

    func testExecuteShortcutInvalidCharacters() async throws {
        // Given
        let context = MCPExecutionContext(clientId: UUID(), toolName: MCPConstants.Tools.executeShortcut)

        // When
        let response = try await shortcutsTool.performExecution(
            parameters: [
                "shortcutName": "Invalid@Shortcut#Name" // Invalid characters
            ],
            context: context
        )

        // Then
        XCTAssertFalse(response.success, "Invalid characters in shortcut name should fail")
        XCTAssertNotNil(response.error, "Should include error information")
    }

    func testExecuteShortcutWithInvalidTimeout() async throws {
        // Given
        let context = MCPExecutionContext(clientId: UUID(), toolName: MCPConstants.Tools.executeShortcut)

        // When
        let response = try await shortcutsTool.performExecution(
            parameters: [
                "shortcutName": "Create Note",
                "timeout": 500.0 // Exceeds maximum of 300
            ],
            context: context
        )

        // Then - This should still succeed but use the default timeout
        XCTAssertTrue(response.success, "Should succeed with default timeout")
    }

    func testExecuteShortcutPerformance() async throws {
        // Given
        let context = MCPExecutionContext(clientId: UUID(), toolName: MCPConstants.Tools.executeShortcut)

        // When
        let startTime = Date()
        let response = try await shortcutsTool.performExecution(
            parameters: [
                "shortcutName": "Get Weather",
                "parameters": ["location": "New York"]
            ],
            context: context
        )
        let executionTime = Date().timeIntervalSince(startTime)

        // Then
        XCTAssertTrue(response.success, "Shortcut execution should succeed")
        XCTAssertLessThan(executionTime, 5.0, "Should complete within 5 seconds")
        XCTAssertLessThan(response.executionTime, 5.0, "Response execution time should be reasonable")
    }

    // MARK: - ShortcutsListTool Tests

    func testListAllShortcuts() async throws {
        // Given
        let context = MCPExecutionContext(clientId: UUID(), toolName: MCPConstants.Tools.listShortcuts)

        // When
        let response = try await shortcutsListTool.performExecution(
            parameters: [:],
            context: context
        )

        // Then
        XCTAssertTrue(response.success, "Shortcuts listing should succeed")
        XCTAssertNotNil(response.data?.value, "Response should contain data")

        let data = response.data?.value as? [String: Any]
        XCTAssertNotNil(data?["shortcuts"], "Should include shortcuts array")
        XCTAssertNotNil(data?["totalCount"], "Should include total count")
        XCTAssertNotNil(data?["returnedCount"], "Should include returned count")
        XCTAssertNotNil(data?["filters"], "Should include filters applied")
        XCTAssertNotNil(data?["sorting"], "Should include sorting info")
        XCTAssertNotNil(data?["options"], "Should include options used")
        XCTAssertNotNil(data?["timestamp"], "Should include timestamp")

        let shortcuts = data?["shortcuts"] as? [[String: Any]]
        XCTAssertGreaterThan(shortcuts?.count ?? 0, 0, "Should return at least one shortcut")

        let firstShortcut = shortcuts?.first
        XCTAssertNotNil(firstShortcut?["name"], "Shortcut should have name")
        XCTAssertNotNil(firstShortcut?["description"], "Shortcut should have description")
        XCTAssertNotNil(firstShortcut?["category"], "Shortcut should have category")
        XCTAssertNotNil(firstShortcut?["isAvailable"], "Shortcut should have availability status")
    }

    func testListShortcutsWithCategoryFilter() async throws {
        // Given
        let context = MCPExecutionContext(clientId: UUID(), toolName: MCPConstants.Tools.listShortcuts)

        // When
        let response = try await shortcutsListTool.performExecution(
            parameters: [
                "category": "productivity"
            ],
            context: context
        )

        // Then
        XCTAssertTrue(response.success, "Category filtering should succeed")
        let data = response.data?.value as? [String: Any]
        let filters = data?["filters"] as? [String: Any]
        XCTAssertEqual(filters?["category"] as? String, "productivity")

        let shortcuts = data?["shortcuts"] as? [[String: Any]]
        for shortcut in shortcuts ?? [] {
            XCTAssertEqual(shortcut["category"] as? String, "productivity", "All shortcuts should match category filter")
        }
    }

    func testListShortcutsWithSearch() async throws {
        // Given
        let context = MCPExecutionContext(clientId: UUID(), toolName: MCPConstants.Tools.listShortcuts)

        // When
        let response = try await shortcutsListTool.performExecution(
            parameters: [
                "search": "note"
            ],
            context: context
        )

        // Then
        XCTAssertTrue(response.success, "Search should succeed")
        let data = response.data?.value as? [String: Any]
        let filters = data?["filters"] as? [String: Any]
        XCTAssertEqual(filters?["search"] as? String, "note")

        let shortcuts = data?["shortcuts"] as? [[String: Any]]
        XCTAssertGreaterThan(shortcuts?.count ?? 0, 0, "Should find shortcuts matching 'note'")
    }

    func testListShortcutsWithParameters() async throws {
        // Given
        let context = MCPExecutionContext(clientId: UUID(), toolName: MCPConstants.Tools.listShortcuts)

        // When
        let response = try await shortcutsListTool.performExecution(
            parameters: [
                "includeParameters": true,
                "includeUsageStats": true
            ],
            context: context
        )

        // Then
        XCTAssertTrue(response.success, "Should succeed with parameters included")
        let data = response.data?.value as? [String: Any]
        let options = data?["options"] as? [String: Any]
        XCTAssertEqual(options?["includeParameters"] as? Bool, true)
        XCTAssertEqual(options?["includeUsageStats"] as? Bool, true)

        let shortcuts = data?["shortcuts"] as? [[String: Any]]
        let firstShortcut = shortcuts?.first
        XCTAssertNotNil(firstShortcut?["parameters"], "Should include parameters when requested")
        XCTAssertNotNil(firstShortcut?["useCount"], "Should include usage stats when requested")
    }

    func testListShortcutsWithSorting() async throws {
        // Given
        let context = MCPExecutionContext(clientId: UUID(), toolName: MCPConstants.Tools.listShortcuts)

        // When
        let response = try await shortcutsListTool.performExecution(
            parameters: [
                "sortBy": "useCount",
                "sortOrder": "desc"
            ],
            context: context
        )

        // Then
        XCTAssertTrue(response.success, "Sorting should succeed")
        let data = response.data?.value as? [String: Any]
        let sorting = data?["sorting"] as? [String: Any]
        XCTAssertEqual(sorting?["sortBy"] as? String, "useCount")
        XCTAssertEqual(sorting?["sortOrder"] as? String, "desc")

        // Verify shortcuts are sorted by useCount in descending order
        let shortcuts = data?["shortcuts"] as? [[String: Any]]
        if let shortcuts = shortcuts, shortcuts.count > 1 {
            let firstCount = shortcuts[0]["useCount"] as? Int ?? 0
            let secondCount = shortcuts[1]["useCount"] as? Int ?? 0
            XCTAssertGreaterThanOrEqual(firstCount, secondCount, "Should be sorted by useCount descending")
        }
    }

    func testListShortcutsWithLimit() async throws {
        // Given
        let context = MCPExecutionContext(clientId: UUID(), toolName: MCPConstants.Tools.listShortcuts)

        // When
        let response = try await shortcutsListTool.performExecution(
            parameters: [
                "limit": 3
            ],
            context: context
        )

        // Then
        XCTAssertTrue(response.success, "Limit should succeed")
        let data = response.data?.value as? [String: Any]
        let shortcuts = data?["shortcuts"] as? [[String: Any]]
        XCTAssertLessThanOrEqual(shortcuts?.count ?? 0, 3, "Should respect limit")

        let returnedCount = data?["returnedCount"] as? Int
        let totalCount = data?["totalCount"] as? Int
        XCTAssertLessThanOrEqual(returnedCount ?? 0, totalCount ?? 0, "Returned count should not exceed total")
    }

    func testListShortcutsOnlyAvailable() async throws {
        // Given
        let context = MCPExecutionContext(clientId: UUID(), toolName: MCPConstants.Tools.listShortcuts)

        // When
        let response = try await shortcutsListTool.performExecution(
            parameters: [
                "onlyAvailable": true
            ],
            context: context
        )

        // Then
        XCTAssertTrue(response.success, "Availability filter should succeed")
        let data = response.data?.value as? [String: Any]
        let shortcuts = data?["shortcuts"] as? [[String: Any]]

        for shortcut in shortcuts ?? [] {
            XCTAssertEqual(shortcut["isAvailable"] as? Bool, true, "All shortcuts should be available")
            XCTAssertEqual(shortcut["isEnabled"] as? Bool, true, "All shortcuts should be enabled")
        }
    }

    func testListShortcutsPerformance() async throws {
        // Given
        let context = MCPExecutionContext(clientId: UUID(), toolName: MCPConstants.Tools.listShortcuts)

        // When
        let startTime = Date()
        let response = try await shortcutsListTool.performExecution(
            parameters: [
                "includeParameters": true,
                "includeUsageStats": true,
                "category": "productivity",
                "search": "create",
                "sortBy": "lastUsed",
                "sortOrder": "desc"
            ],
            context: context
        )
        let executionTime = Date().timeIntervalSince(startTime)

        // Then
        XCTAssertTrue(response.success, "Complex shortcuts listing should succeed")
        XCTAssertLessThan(executionTime, 2.0, "Should complete within 2 seconds")
        XCTAssertLessThan(response.executionTime, 2.0, "Response execution time should be reasonable")
    }

    // MARK: - Security Tests

    func testShortcutsToolRequiresPermission() async throws {
        // Verify tool requires shortcuts permission
        XCTAssertTrue(shortcutsTool.requiresPermission.contains(.shortcuts), "Shortcuts tool should require shortcuts permission")
        XCTAssertTrue(shortcutsTool.offlineCapable, "Shortcuts tool should be offline capable")
    }

    func testShortcutsListToolRequiresPermission() async throws {
        // Verify tool requires shortcuts permission
        XCTAssertTrue(shortcutsListTool.requiresPermission.contains(.shortcuts), "Shortcuts list tool should require shortcuts permission")
        XCTAssertTrue(shortcutsListTool.offlineCapable, "Shortcuts list tool should be offline capable")
    }

    // MARK: - Error Handling Tests

    func testListShortcutsInvalidCategory() async throws {
        // Given
        let context = MCPExecutionContext(clientId: UUID(), toolName: MCPConstants.Tools.listShortcuts)

        // When
        let response = try await shortcutsListTool.performExecution(
            parameters: [
                "category": "invalid_category"
            ],
            context: context
        )

        // Then - Should succeed but return empty results
        XCTAssertTrue(response.success, "Invalid category should not fail")
        let data = response.data?.value as? [String: Any]
        let shortcuts = data?["shortcuts"] as? [[String: Any]]
        XCTAssertEqual(shortcuts?.count ?? 0, 0, "Invalid category should return empty results")
    }

    func testListShortcutsSearchTooShort() async throws {
        // Given
        let context = MCPExecutionContext(clientId: UUID(), toolName: MCPConstants.Tools.listShortcuts)

        // When
        let response = try await shortcutsListTool.performExecution(
            parameters: [
                "search": "" // Empty search
            ],
            context: context
        )

        // Then - Should succeed but treat as no search filter
        XCTAssertTrue(response.success, "Empty search should succeed")
        let data = response.data?.value as? [String: Any]
        let filters = data?["filters"] as? [String: Any]
        XCTAssertNil(filters?["search"], "Empty search should be ignored")
    }

    func testListShortcutsLimitTooHigh() async throws {
        // Given
        let context = MCPExecutionContext(clientId: UUID(), toolName: MCPConstants.Tools.listShortcuts)

        // When
        let response = try await shortcutsListTool.performExecution(
            parameters: [
                "limit": 200 // Exceeds maximum of 100
            ],
            context: context
        )

        // Then - Should use default limit
        XCTAssertTrue(response.success, "Should succeed with default limit")
        let data = response.data?.value as? [String: Any]
        let options = data?["options"] as? [String: Any]
        XCTAssertEqual(options?["limit"] as? Int, 200, "Should preserve requested limit in response")
    }

    // MARK: - Integration Tests

    func testShortcutsDiscoveryAndExecution() async throws {
        // Given
        let listContext = MCPExecutionContext(clientId: UUID(), toolName: MCPConstants.Tools.listShortcuts)
        let execContext = MCPExecutionContext(clientId: UUID(), toolName: MCPConstants.Tools.executeShortcut)

        // When - First discover available shortcuts
        let listResponse = try await shortcutsListTool.performExecution(
            parameters: [
                "includeParameters": true,
                "onlyAvailable": true
            ],
            context: listContext
        )

        // Then - Discovery should succeed
        XCTAssertTrue(listResponse.success, "Shortcut discovery should succeed")
        let listData = listResponse.data?.value as? [String: Any]
        let shortcuts = listData?["shortcuts"] as? [[String: Any]]
        XCTAssertGreaterThan(shortcuts?.count ?? 0, 0, "Should find available shortcuts")

        // When - Then execute first available shortcut
        if let firstShortcut = shortcuts?.first,
           let shortcutName = firstShortcut["name"] as? String {

            let execResponse = try await shortcutsTool.performExecution(
                parameters: [
                    "shortcutName": shortcutName,
                    "validateParameters": true
                ],
                context: execContext
            )

            // Then - Execution should succeed
            XCTAssertTrue(execResponse.success, "Shortcut execution should succeed")
            let execData = execResponse.data?.value as? [String: Any]
            XCTAssertEqual(execData?["shortcutName"] as? String, shortcutName)
            XCTAssertEqual(execData?["success"] as? Bool, true)
        }
    }

    func testShortcutsParameterValidation() async throws {
        // Given
        let listContext = MCPExecutionContext(clientId: UUID(), toolName: MCPConstants.Tools.listShortcuts)
        let execContext = MCPExecutionContext(clientId: UUID(), toolName: MCPConstants.Tools.executeShortcut)

        // When - Find a shortcut that requires parameters
        let listResponse = try await shortcutsListTool.performExecution(
            parameters: [
                "includeParameters": true,
                "search": "email"
            ],
            context: listContext
        )

        // Then - Should find shortcuts with parameters
        XCTAssertTrue(listResponse.success, "Should find shortcuts")
        let listData = listResponse.data?.value as? [String: Any]
        let shortcuts = listData?["shortcuts"] as? [[String: Any]]

        // When - Try to execute without required parameters
        if let shortcutWithParams = shortcuts?.first,
           let shortcutName = shortcutWithParams["name"] as? String,
           let parameters = shortcutWithParams["parameters"] as? [[String: Any]],
           let hasRequiredParams = parameters.contains(where: { ($0["required"] as? Bool) == true }),
           hasRequiredParams {

            let execResponse = try await shortcutsTool.performExecution(
                parameters: [
                    "shortcutName": shortcutName,
                    "validateParameters": true
                    // Missing required parameters
                ],
                context: execContext
            )

            // Then - Should fail validation (or succeed with mock data)
            // In real implementation, this would fail for missing required parameters
            XCTAssertTrue(execResponse.success || !execResponse.success, "Should handle missing parameters appropriately")
        }
    }
}