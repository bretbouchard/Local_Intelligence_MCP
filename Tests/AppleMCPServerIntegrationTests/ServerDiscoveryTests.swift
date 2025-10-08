//
//  ServerDiscoveryTests.swift
//  AppleMCPServerIntegrationTests
//
//  Created on 2025-10-07.
//

import XCTest
@testable import AppleMCPServer

final class ServerDiscoveryTests: XCTestCase {

    var server: MCPServer!
    var logger: Logger!
    var securityManager: SecurityManager!

    override func setUp() async throws {
        try await super.setUp()

        logger = Logger(level: .debug, category: .test)
        securityManager = SecurityManager(logger: logger)

        let config = ServerConfiguration(
            server: ServerConfig(name: "Test Server", maxClients: 5),
            security: SecurityConfig(requireAuthentication: false),
            network: NetworkConfig(port: 0), // Random port for testing
            features: FeaturesConfig(
                shortcutsEnabled: true,
                voiceControlEnabled: true,
                systemInfoEnabled: true,
                permissionManagement: true
            ),
            logging: LoggingConfig(level: .debug, fileLogging: false, consoleLogging: true),
            api: APIConfig(keys: [:]),
            database: DatabaseConfig(url: "sqlite::memory:")
        )

        server = MCPServer(
            configuration: config,
            logger: logger,
            securityManager: securityManager
        )
    }

    override func tearDown() async throws {
        try await server.stop()
        server = nil
        logger = nil
        securityManager = nil
        try await super.tearDown()
    }

    // MARK: - Server Info Tests

    func testServerInfoEndpoint() async throws {
        // Given
        let tool = SystemInfoTool(logger: logger, securityManager: securityManager)
        let context = MCPExecutionContext(clientId: UUID(), toolName: MCPConstants.Tools.systemInfo)

        // When
        let response = try await tool.performExecution(
            parameters: ["categories": ["server"]],
            context: context
        )

        // Then
        XCTAssertTrue(response.success, "Server info request should succeed")
        XCTAssertNotNil(response.data?.value, "Response should contain data")

        let data = response.data?.value as? [String: Any]
        XCTAssertNotNil(data?["serverInfo"], "Response should contain server info")

        let serverInfo = data?["serverInfo"] as? [String: Any]
        XCTAssertEqual(serverInfo?["name"] as? String, "Apple MCP Server")
        XCTAssertEqual(serverInfo?["version"] as? String, MCPConstants.Server.version)
        XCTAssertEqual(serverInfo?["status"] as? String, "running")
        XCTAssertNotNil(serverInfo?["capabilities"], "Server should list capabilities")

        let capabilities = serverInfo?["capabilities"] as? [String: Any]
        XCTAssertNotNil(capabilities?["tools"], "Capabilities should include tools")
        XCTAssertNotNil(capabilities?["transports"], "Capabilities should include transports")
    }

    func testServerInfoIncludesAllRequiredFields() async throws {
        // Given
        let tool = SystemInfoTool(logger: logger, securityManager: securityManager)
        let context = MCPExecutionContext(clientId: UUID(), toolName: MCPConstants.Tools.systemInfo)

        // When
        let response = try await tool.performExecution(
            parameters: ["categories": ["server"], "includeSensitive": false],
            context: context
        )

        // Then
        let data = response.data?.value as? [String: Any]
        let serverInfo = data?["serverInfo"] as? [String: Any]

        // Verify required server fields
        XCTAssertNotNil(serverInfo?["server"], "Should contain server section")
        XCTAssertNotNil(serverInfo?["capabilities"], "Should contain capabilities section")
        XCTAssertNotNil(serverInfo?["configuration"], "Should contain configuration section")
        XCTAssertNotNil(serverInfo?["statistics"], "Should contain statistics section")

        let server = serverInfo?["server"] as? [String: Any]
        XCTAssertNotNil(server?["name"], "Server should have name")
        XCTAssertNotNil(server?["version"], "Server should have version")
        XCTAssertNotNil(server?["protocolVersion"], "Server should have protocol version")
        XCTAssertNotNil(server?["startTime"], "Server should have start time")
        XCTAssertNotNil(server?["uptime"], "Server should have uptime")
        XCTAssertNotNil(server?["status"], "Server should have status")
    }

    func testServerInfoCapabilities() async throws {
        // Given
        let tool = SystemInfoTool(logger: logger, securityManager: securityManager)
        let context = MCPExecutionContext(clientId: UUID(), toolName: MCPConstants.Tools.systemInfo)

        // When
        let response = try await tool.performExecution(
            parameters: ["categories": ["server"]],
            context: context
        )

        // Then
        let data = response.data?.value as? [String: Any]
        let serverInfo = data?["serverInfo"] as? [String: Any]
        let capabilities = serverInfo?["capabilities"] as? [String: Any]

        let tools = capabilities?["tools"] as? [String]
        XCTAssertTrue(tools?.contains(MCPConstants.Tools.systemInfo) == true, "Should include system info tool")
        XCTAssertTrue(tools?.contains(MCPConstants.Tools.executeShortcut) == true, "Should include shortcuts tool")
        XCTAssertTrue(tools?.contains(MCPConstants.Tools.voiceCommand) == true, "Should include voice control tool")

        let features = capabilities?["features"] as? [String]
        XCTAssertTrue(features?.contains("audit_logging") == true, "Should include audit logging")
        XCTAssertTrue(features?.contains("permission_management") == true, "Should include permission management")
    }

    // MARK: - Health Check Tests

    func testHealthCheckOverallStatus() async throws {
        // Given
        let tool = HealthCheckTool(logger: logger, securityManager: securityManager)
        let context = MCPExecutionContext(clientId: UUID(), toolName: "health_check")

        // When
        let response = try await tool.performExecution(
            parameters: [:],
            context: context
        )

        // Then
        XCTAssertTrue(response.success, "Health check should succeed")
        XCTAssertNotNil(response.data?.value, "Response should contain data")

        let data = response.data?.value as? [String: Any]
        XCTAssertNotNil(data?["status"], "Should contain overall status")
        XCTAssertNotNil(data?["timestamp"], "Should contain timestamp")
        XCTAssertNotNil(data?["executionTime"], "Should contain execution time")
        XCTAssertNotNil(data?["components"], "Should contain component results")

        let status = data?["status"] as? String
        XCTAssertTrue(["healthy", "degraded", "unhealthy"].contains(status ?? ""), "Status should be valid")
    }

    func testHealthCheckServerComponent() async throws {
        // Given
        let tool = HealthCheckTool(logger: logger, securityManager: securityManager)
        let context = MCPExecutionContext(clientId: UUID(), toolName: "health_check")

        // When
        let response = try await tool.performExecution(
            parameters: ["components": ["server"]],
            context: context
        )

        // Then
        let data = response.data?.value as? [String: Any]
        let components = data?["components"] as? [String: Any]
        let server = components?["server"] as? [String: Any]

        XCTAssertNotNil(server?["uptime"], "Server component should have uptime")
        XCTAssertNotNil(server?["memoryUsage"], "Server component should have memory usage")
        XCTAssertNotNil(server?["processCount"], "Server component should have process count")
        XCTAssertEqual(server?["status"] as? String, "running", "Server should be running")
    }

    func testHealthCheckAllComponents() async throws {
        // Given
        let tool = HealthCheckTool(logger: logger, securityManager: securityManager)
        let context = MCPExecutionContext(clientId: UUID(), toolName: "health_check")

        // When
        let response = try await tool.performExecution(
            parameters: [
                "components": ["server", "security", "tools", "permissions", "system", "network", "storage"],
                "detailed": true
            ],
            context: context
        )

        // Then
        let data = response.data?.value as? [String: Any]
        let components = data?["components"] as? [String: Any]

        // Verify all components are present
        XCTAssertNotNil(components?["server"], "Should include server component")
        XCTAssertNotNil(components?["security"], "Should include security component")
        XCTAssertNotNil(components?["tools"], "Should include tools component")
        XCTAssertNotNil(components?["permissions"], "Should include permissions component")
        XCTAssertNotNil(components?["system"], "Should include system component")
        XCTAssertNotNil(components?["network"], "Should include network component")
        XCTAssertNotNil(components?["storage"], "Should include storage component")

        // Verify summary is included in detailed mode
        XCTAssertNotNil(data?["summary"], "Should include summary in detailed mode")
    }

    func testHealthCheckIssuesReporting() async throws {
        // Given
        let tool = HealthCheckTool(logger: logger, securityManager: securityManager)
        let context = MCPExecutionContext(clientId: UUID(), toolName: "health_check")

        // When
        let response = try await tool.performExecution(
            parameters: [:],
            context: context
        )

        // Then
        let data = response.data?.value as? [String: Any]
        let status = data?["status"] as? String

        // If there are issues, they should be reported
        if status != "healthy" {
            XCTAssertNotNil(data?["issues"], "Unhealthy status should include issues")
            let issues = data?["issues"] as? [String]
            XCTAssertFalse(issues?.isEmpty ?? true, "Issues array should not be empty when status is not healthy")
        }
    }

    // MARK: - Performance Tests

    func testServerInfoPerformance() async throws {
        // Given
        let tool = SystemInfoTool(logger: logger, securityManager: securityManager)
        let context = MCPExecutionContext(clientId: UUID(), toolName: MCPConstants.Tools.systemInfo)

        // When
        let startTime = Date()
        let response = try await tool.performExecution(
            parameters: ["categories": ["server"]],
            context: context
        )
        let executionTime = Date().timeIntervalSince(startTime)

        // Then
        XCTAssertTrue(response.success, "Server info request should succeed")
        XCTAssertLessThan(executionTime, 1.0, "Server info should complete within 1 second")
        XCTAssertLessThan(response.executionTime, 1.0, "Response execution time should be reasonable")
    }

    func testHealthCheckPerformance() async throws {
        // Given
        let tool = HealthCheckTool(logger: logger, securityManager: securityManager)
        let context = MCPExecutionContext(clientId: UUID(), toolName: "health_check")

        // When
        let startTime = Date()
        let response = try await tool.performExecution(
            parameters: [:],
            context: context
        )
        let executionTime = Date().timeIntervalSince(startTime)

        // Then
        XCTAssertTrue(response.success, "Health check should succeed")
        XCTAssertLessThan(executionTime, 2.0, "Health check should complete within 2 seconds")
        XCTAssertLessThan(response.executionTime, 2.0, "Response execution time should be reasonable")
    }

    // MARK: - Error Handling Tests

    func testSystemInfoInvalidParameters() async throws {
        // Given
        let tool = SystemInfoTool(logger: logger, securityManager: securityManager)
        let context = MCPExecutionContext(clientId: UUID(), toolName: MCPConstants.Tools.systemInfo)

        // When
        let response = try await tool.performExecution(
            parameters: ["categories": "invalid"], // Should be array
            context: context
        )

        // Then
        XCTAssertFalse(response.success, "Invalid parameters should fail")
        XCTAssertNotNil(response.error, "Should include error information")
    }

    func testSystemInfoEmptyCategories() async throws {
        // Given
        let tool = SystemInfoTool(logger: logger, securityManager: securityManager)
        let context = MCPExecutionContext(clientId: UUID(), toolName: MCPConstants.Tools.systemInfo)

        // When
        let response = try await tool.performExecution(
            parameters: ["categories": []],
            context: context
        )

        // Then
        XCTAssertTrue(response.success, "Empty categories should succeed")
        let data = response.data?.value as? [String: Any]
        XCTAssertNotNil(data?["timestamp"], "Should still include timestamp")
        XCTAssertNotNil(data?["executionTime"], "Should still include execution time")
    }

    func testSystemInfoInvalidCategory() async throws {
        // Given
        let tool = SystemInfoTool(logger: logger, securityManager: securityManager)
        let context = MCPExecutionContext(clientId: UUID(), toolName: MCPConstants.Tools.systemInfo)

        // When
        let response = try await tool.performExecution(
            parameters: ["categories": ["invalid_category"]],
            context: context
        )

        // Then
        XCTAssertTrue(response.success, "Invalid category should be ignored")
        let data = response.data?.value as? [String: Any]
        XCTAssertNotNil(data?["timestamp"], "Should still include basic response fields")
    }

    // MARK: - Security Tests

    func testSystemInfoRequiresPermission() async throws {
        // Given
        let tool = SystemInfoTool(logger: logger, securityManager: securityManager)

        // Verify tool requires systemInfo permission
        XCTAssertTrue(tool.requiresPermission.contains(.systemInfo), "System info tool should require systemInfo permission")
    }

    func testSystemInfoOfflineCapability() async throws {
        // Given
        let tool = SystemInfoTool(logger: logger, securityManager: securityManager)

        // Verify tool is offline capable
        XCTAssertTrue(tool.offlineCapable, "System info tool should be offline capable")
    }

    func testHealthCheckSecurity() async throws {
        // Given
        let tool = HealthCheckTool(logger: logger, securityManager: securityManager)

        // Verify health check requires appropriate permissions
        XCTAssertTrue(tool.requiresPermission.contains(.systemInfo), "Health check should require systemInfo permission")
        XCTAssertTrue(tool.offlineCapable, "Health check should be offline capable")
    }
}