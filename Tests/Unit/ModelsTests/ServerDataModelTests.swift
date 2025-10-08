//
//  ServerDataModelTests.swift
//  AppleMCPServer
//
//  Created on 2025-10-08.
//

import XCTest
@testable import AppleMCPServer

final class ServerDataModelTests: XCTestCase {

    // MARK: - Properties

    private var sampleServerDataModel: MCPServerDataModel!
    private var sampleCapabilities: ServerCapabilitiesDataModel!

    // MARK: - Setup and Teardown

    override func setUp() async throws {
        try await super.setUp()

        // Create sample capabilities
        sampleCapabilities = ServerCapabilitiesDataModel(
            tools: [
                ToolCapability(name: "execute_shortcut", description: "Execute Apple Shortcuts"),
                ToolCapability(name: "voice_command", description: "Execute voice commands"),
                ToolCapability(name: "system_info", description: "Get system information")
            ],
            permissions: [
                PermissionCapability(name: "shortcuts", description: "Access to Apple Shortcuts"),
                PermissionCapability(name: "voice_control", description: "Access to voice control"),
                PermissionCapability(name: "system_info", description: "Access to system information")
            ],
            features: [
                "shortcuts_execution",
                "voice_control",
                "system_monitoring",
                "real_time_updates"
            ]
        )

        // Create sample server data model
        sampleServerDataModel = MCPServerDataModel(
            id: UUID(uuidString: "12345678-1234-5678-9abc-123456789abc")!,
            version: "1.0.0",
            capabilities: sampleCapabilities,
            status: .running,
            startTime: Date(timeIntervalSince1970: 1000000),
            activeConnections: 5
        )
    }

    override func tearDown() async throws {
        sampleServerDataModel = nil
        sampleCapabilities = nil

        try await super.tearDown()
    }

    // MARK: - MCPServerDataModel Tests

    func testMCPServerDataModelInitialization() async throws {
        XCTAssertNotNil(sampleServerDataModel)
        XCTAssertEqual(sampleServerDataModel.version, "1.0.0")
        XCTAssertNotNil(sampleServerDataModel.capabilities)
        XCTAssertEqual(sampleServerDataModel.status, .running)
        XCTAssertNotNil(sampleServerDataModel.startTime)
        XCTAssertEqual(sampleServerDataModel.activeConnections, 5)
    }

    func testMCPServerDataModelDefaultValues() async throws {
        let defaultServer = MCPServerDataModel()

        XCTAssertEqual(defaultServer.version, MCPConstants.Server.version)
        XCTAssertNotNil(defaultServer.capabilities)
        XCTAssertEqual(defaultServer.status, .starting)
        XCTAssertNil(defaultServer.startTime)
        XCTAssertEqual(defaultServer.activeConnections, 0)
    }

    func testMCPServerDataModelWithStatus() async throws {
        let updatedServer = sampleServerDataModel.with(status: .stopped)
        XCTAssertEqual(updatedServer.status, .stopped)
        XCTAssertEqual(updatedServer.id, sampleServerDataModel.id)
        XCTAssertEqual(updatedServer.version, sampleServerDataModel.version)
        XCTAssertEqual(updatedServer.capabilities, sampleServerDataModel.capabilities)
        XCTAssertEqual(updatedServer.startTime, sampleServerDataModel.startTime)
        XCTAssertEqual(updatedServer.activeConnections, sampleServerDataModel.activeConnections)
    }

    func testMCPServerDataModelWithActiveConnections() async throws {
        let updatedServer = sampleServerDataModel.with(activeConnections: 10)
        XCTAssertEqual(updatedServer.activeConnections, 10)
        XCTAssertEqual(updatedServer.id, sampleServerDataModel.id)
        XCTAssertEqual(updatedServer.version, sampleServerDataModel.version)
        XCTAssertEqual(updatedServer.capabilities, sampleServerDataModel.capabilities)
        XCTAssertEqual(updatedServer.status, sampleServerDataModel.status)
        XCTAssertEqual(updatedServer.startTime, sampleServerDataModel.startTime)
    }

    func testMCPServerDataModelValidation() async throws {
        let validation = sampleServerDataModel.validate()
        XCTAssertTrue(validation.isValid)
        XCTAssertTrue(validation.errors.isEmpty)
    }

    func testMCPServerDataModelValidationInvalidVersion() async throws {
        let invalidServer = MCPServerDataModel(
            version: "invalid_version",
            capabilities: sampleCapabilities,
            status: .running
        )

        let validation = invalidServer.validate()
        XCTAssertFalse(validation.isValid)
        XCTAssertFalse(validation.errors.isEmpty)

        let hasVersionError = validation.errors.contains { error in
            error.code == "INVALID_VERSION_FORMAT"
        }
        XCTAssertTrue(hasVersionError)
    }

    func testMCPServerDataModelValidationInvalidConnections() async throws {
        let invalidServer = MCPServerDataModel(
            capabilities: sampleCapabilities,
            status: .running,
            activeConnections: -1
        )

        let validation = invalidServer.validate()
        XCTAssertFalse(validation.isValid)
        XCTAssertFalse(validation.errors.isEmpty)

        let hasConnectionError = validation.errors.contains { error in
            error.code == "INVALID_ACTIVE_CONNECTIONS"
        }
        XCTAssertTrue(hasConnectionError)
    }

    func testMCPServerDataModelValidationInvalidStatus() async throws {
        let invalidServer = MCPServerDataModel(
            capabilities: sampleCapabilities,
            status: .error
        )

        let validation = invalidServer.validate()
        XCTAssertFalse(validation.isValid)
        XCTAssertFalse(validation.errors.isEmpty)

        let hasStatusError = validation.errors.contains { error in
            error.code == "INVALID_SERVER_STATUS"
        }
        XCTAssertTrue(hasStatusError)
    }

    func testMCPServerDataModelCodable() async throws {
        let encodedData = try JSONEncoder().encode(sampleServerDataModel)
        XCTAssertFalse(encodedData.isEmpty)

        let decodedServer = try JSONDecoder().decode(MCPServerDataModel.self, from: encodedData)
        XCTAssertEqual(decodedServer.id, sampleServerDataModel.id)
        XCTAssertEqual(decodedServer.version, sampleServerDataModel.version)
        XCTAssertEqual(decodedServer.status, sampleServerDataModel.status)
        XCTAssertEqual(decodedServer.activeConnections, sampleServerDataModel.activeConnections)
        XCTAssertEqual(decodedServer.capabilities.tools.count, sampleServerDataModel.capabilities.tools.count)
    }

    // MARK: - ServerStatusDataModel Tests

    func testServerStatusDataModelRawValues() async throws {
        XCTAssertEqual(ServerStatusDataModel.starting.rawValue, "starting")
        XCTAssertEqual(ServerStatusDataModel.running.rawValue, "running")
        XCTAssertEqual(ServerStatusDataModel.stopping.rawValue, "stopping")
        XCTAssertEqual(ServerStatusDataModel.stopped.rawValue, "stopped")
        XCTAssertEqual(ServerStatusDataModel.error.rawValue, "error")
    }

    func testServerStatusDataModelInitialization() async throws {
        let statuses: [ServerStatusDataModel] = [.starting, .running, .stopping, .stopped, .error]

        for status in statuses {
            let server = MCPServerDataModel(status: status)
            XCTAssertEqual(server.status, status)
        }
    }

    func testServerStatusDataModelCodable() async throws {
        let statuses: [ServerStatusDataModel] = [.starting, .running, .stopping, .stopped, .error]

        for status in statuses {
            let encodedData = try JSONEncoder().encode(status)
            XCTAssertFalse(encodedData.isEmpty)

            let decodedStatus = try JSONDecoder().decode(ServerStatusDataModel.self, from: encodedData)
            XCTAssertEqual(decodedStatus, status)
        }
    }

    func testServerStatusDataModelIsHealthy() async throws {
        XCTAssertTrue(ServerStatusDataModel.running.isHealthy)
        XCTAssertTrue(ServerStatusDataModel.starting.isHealthy)
        XCTAssertFalse(ServerStatusDataModel.stopping.isHealthy)
        XCTAssertFalse(ServerStatusDataModel.stopped.isHealthy)
        XCTAssertFalse(ServerStatusDataModel.error.isHealthy)
    }

    func testServerStatusDataModelIsActive() async throws {
        XCTAssertTrue(ServerStatusDataModel.running.isActive)
        XCTAssertTrue(ServerStatusDataModel.starting.isActive)
        XCTAssertTrue(ServerStatusDataModel.stopping.isActive)
        XCTAssertFalse(ServerStatusDataModel.stopped.isActive)
        XCTAssertFalse(ServerStatusDataModel.error.isActive)
    }

    // MARK: - ServerCapabilitiesDataModel Tests

    func testServerCapabilitiesDataModelInitialization() async throws {
        XCTAssertEqual(sampleCapabilities.tools.count, 3)
        XCTAssertEqual(sampleCapabilities.permissions.count, 3)
        XCTAssertEqual(sampleCapabilities.features.count, 4)

        let firstTool = sampleCapabilities.tools.first!
        XCTAssertEqual(firstTool.name, "execute_shortcut")
        XCTAssertEqual(firstTool.description, "Execute Apple Shortcuts")

        let firstPermission = sampleCapabilities.permissions.first!
        XCTAssertEqual(firstPermission.name, "shortcuts")
        XCTAssertEqual(firstPermission.description, "Access to Apple Shortcuts")

        XCTAssertEqual(sampleCapabilities.features.first, "shortcuts_execution")
    }

    func testServerCapabilitiesDataModelDefaultValues() async throws {
        let defaultCapabilities = ServerCapabilitiesDataModel()

        XCTAssertTrue(defaultCapabilities.tools.isEmpty)
        XCTAssertTrue(defaultCapabilities.permissions.isEmpty)
        XCTAssertTrue(defaultCapabilities.features.isEmpty)
    }

    func testServerCapabilitiesDataModelWithEmptyCapabilities() async throws {
        let emptyCapabilities = ServerCapabilitiesDataModel(
            tools: [],
            permissions: [],
            features: []
        )

        XCTAssertTrue(emptyCapabilities.tools.isEmpty)
        XCTAssertTrue(emptyCapabilities.permissions.isEmpty)
        XCTAssertTrue(emptyCapabilities.features.isEmpty)
    }

    func testServerCapabilitiesDataModelWithMaxCapabilities() async throws {
        var maxTools: [ToolCapability] = []
        var maxPermissions: [PermissionCapability] = []
        var maxFeatures: [String] = []

        for i in 1...100 {
            maxTools.append(ToolCapability(
                name: "tool_\(i)",
                description: "Tool number \(i)"
            ))
        }

        for i in 1...50 {
            maxPermissions.append(PermissionCapability(
                name: "permission_\(i)",
                description: "Permission number \(i)"
            ))
        }

        for i in 1...200 {
            maxFeatures.append("feature_\(i)")
        }

        let maxCapabilities = ServerCapabilitiesDataModel(
            tools: maxTools,
            permissions: maxPermissions,
            features: maxFeatures
        )

        XCTAssertEqual(maxCapabilities.tools.count, 100)
        XCTAssertEqual(maxCapabilities.permissions.count, 50)
        XCTAssertEqual(maxCapabilities.features.count, 200)
    }

    func testServerCapabilitiesDataModelCodable() async throws {
        let encodedData = try JSONEncoder().encode(sampleCapabilities)
        XCTAssertFalse(encodedData.isEmpty)

        let decodedCapabilities = try JSONDecoder().decode(ServerCapabilitiesDataModel.self, from: encodedData)
        XCTAssertEqual(decodedCapabilities.tools.count, sampleCapabilities.tools.count)
        XCTAssertEqual(decodedCapabilities.permissions.count, sampleCapabilities.permissions.count)
        XCTAssertEqual(decodedCapabilities.features.count, sampleCapabilities.features.count)

        let decodedTool = decodedCapabilities.tools.first!
        let originalTool = sampleCapabilities.tools.first!
        XCTAssertEqual(decodedTool.name, originalTool.name)
        XCTAssertEqual(decodedTool.description, originalTool.description)

        let decodedPermission = decodedCapabilities.permissions.first!
        let originalPermission = sampleCapabilities.permissions.first!
        XCTAssertEqual(decodedPermission.name, originalPermission.name)
        XCTAssertEqual(decodedPermission.description, originalPermission.description)
    }

    // MARK: - ToolCapability Tests

    func testToolCapabilityInitialization() async throws {
        let tool = ToolCapability(
            name: "test_tool",
            description: "A test tool"
        )

        XCTAssertEqual(tool.name, "test_tool")
        XCTAssertEqual(tool.description, "A test tool")
    }

    func testToolCapabilityWithSpecialCharacters() async throws {
        let tool = ToolCapability(
            name: "special_tool_🚀_测试",
            description: "Tool with special chars: àéîöü, 中文, العربية"
        )

        XCTAssertEqual(tool.name, "special_tool_🚀_测试")
        XCTAssertEqual(tool.description, "Tool with special chars: àéîöü, 中文, العربية")
    }

    func testToolCapabilityCodable() async throws {
        let tool = ToolCapability(
            name: "codable_test_tool",
            description: "Tool for Codable testing"
        )

        let encodedData = try JSONEncoder().encode(tool)
        XCTAssertFalse(encodedData.isEmpty)

        let decodedTool = try JSONDecoder().decode(ToolCapability.self, from: encodedData)
        XCTAssertEqual(decodedTool.name, tool.name)
        XCTAssertEqual(decodedTool.description, tool.description)
    }

    // MARK: - PermissionCapability Tests

    func testPermissionCapabilityInitialization() async throws {
        let permission = PermissionCapability(
            name: "test_permission",
            description: "A test permission"
        )

        XCTAssertEqual(permission.name, "test_permission")
        XCTAssertEqual(permission.description, "A test permission")
    }

    func testPermissionCapabilityWithSpecialCharacters() async throws {
        let permission = PermissionCapability(
            name: "special_permission_🔐_тест",
            description: "Permission with special chars: ñ, üß, кириллица"
        )

        XCTAssertEqual(permission.name, "special_permission_🔐_тест")
        XCTAssertEqual(permission.description, "Permission with special chars: ñ, üß, кириллица")
    }

    func testPermissionCapabilityCodable() async throws {
        let permission = PermissionCapability(
            name: "codable_test_permission",
            description: "Permission for Codable testing"
        )

        let encodedData = try JSONEncoder().encode(permission)
        XCTAssertFalse(encodedData.isEmpty)

        let decodedPermission = try JSONDecoder().decode(PermissionCapability.self, from: encodedData)
        XCTAssertEqual(decodedPermission.name, permission.name)
        XCTAssertEqual(decodedPermission.description, permission.description)
    }

    // MARK: - Integration Tests

    func testMCPServerDataModelRoundTrip() async throws {
        let originalServer = MCPServerDataModel(
            id: UUID(uuidString: "98765432-4321-8765-cba9-87654321cba9")!,
            version: "2.1.0",
            capabilities: ServerCapabilitiesDataModel(
                tools: [
                    ToolCapability(name: "custom_tool", description: "Custom tool"),
                    ToolCapability(name: "another_tool", description: "Another tool")
                ],
                permissions: [
                    PermissionCapability(name: "custom_permission", description: "Custom permission")
                ],
                features: ["custom_feature", "another_feature"]
            ),
            status: .stopping,
            startTime: Date(timeIntervalSince1970: 2000000),
            activeConnections: 3
        )

        let encodedData = try JSONEncoder().encode(originalServer)
        let decodedServer = try JSONDecoder().decode(MCPServerDataModel.self, from: encodedData)

        XCTAssertEqual(originalServer.id, decodedServer.id)
        XCTAssertEqual(originalServer.version, decodedServer.version)
        XCTAssertEqual(originalServer.status, decodedServer.status)
        XCTAssertEqual(originalServer.activeConnections, decodedServer.activeConnections)
        XCTAssertEqual(originalServer.capabilities.tools.count, decodedServer.capabilities.tools.count)
        XCTAssertEqual(originalServer.capabilities.permissions.count, decodedServer.capabilities.permissions.count)
        XCTAssertEqual(originalServer.capabilities.features.count, decodedServer.capabilities.features.count)
    }

    func testMCPServerDataModelStatusTransitions() async throws {
        let server = MCPServerDataModel(status: .starting)

        let runningServer = server.with(status: .running)
        XCTAssertEqual(runningServer.status, .running)

        let stoppingServer = runningServer.with(status: .stopping)
        XCTAssertEqual(stoppingServer.status, .stopping)

        let stoppedServer = stoppingServer.with(status: .stopped)
        XCTAssertEqual(stoppedServer.status, .stopped)

        let errorServer = stoppedServer.with(status: .error)
        XCTAssertEqual(errorServer.status, .error)
    }

    func testMCPServerDataModelConnectionCountChanges() async throws {
        let server = MCPServerDataModel(activeConnections: 0)

        let connections: [Int] = [1, 5, 10, 25, 50]
        var currentServer = server

        for connectionCount in connections {
            currentServer = currentServer.with(activeConnections: connectionCount)
            XCTAssertEqual(currentServer.activeConnections, connectionCount)
        }

        // Test back to zero
        let emptyServer = currentServer.with(activeConnections: 0)
        XCTAssertEqual(emptyServer.activeConnections, 0)
    }

    // MARK: - Edge Cases Tests

    func testMCPServerDataModelWithEmptyVersion() async throws {
        let emptyVersionServer = MCPServerDataModel(
            version: "",
            capabilities: sampleCapabilities,
            status: .running
        )

        XCTAssertEqual(emptyVersionServer.version, "")

        let validation = emptyVersionServer.validate()
        XCTAssertFalse(validation.isValid)
    }

    func testMCPServerDataModelWithMaximumConnections() async throws {
        let maxConnectionsServer = MCPServerDataModel(
            capabilities: sampleCapabilities,
            status: .running,
            activeConnections: MCPConstants.Server.maxConcurrentClients
        )

        XCTAssertEqual(maxConnectionsServer.activeConnections, MCPConstants.Server.maxConcurrentClients)

        let validation = maxConnectionsServer.validate()
        XCTAssertTrue(validation.isValid)
    }

    func testMCPServerDataModelWithExceededConnections() async throws {
        let exceededConnectionsServer = MCPServerDataModel(
            capabilities: sampleCapabilities,
            status: .running,
            activeConnections: MCPConstants.Server.maxConcurrentClients + 1
        )

        let validation = exceededConnectionsServer.validate()
        XCTAssertFalse(validation.isValid)

        let hasConnectionError = validation.errors.contains { error in
            error.code == "INVALID_ACTIVE_CONNECTIONS"
        }
        XCTAssertTrue(hasConnectionError)
    }

    func testMCPServerDataModelWithComplexCapabilities() async throws {
        let complexCapabilities = ServerCapabilitiesDataModel(
            tools: [
                ToolCapability(name: "tool_1", description: "First tool"),
                ToolCapability(name: "tool_2", description: "Second tool"),
                ToolCapability(name: "tool_3", description: "Third tool")
            ],
            permissions: [
                PermissionCapability(name: "perm_1", description: "First permission"),
                PermissionCapability(name: "perm_2", description: "Second permission")
            ],
            features: [
                "feature_1",
                "feature_2",
                "feature_3",
                "feature_4",
                "feature_5"
            ]
        )

        let complexServer = MCPServerDataModel(
            capabilities: complexCapabilities,
            status: .running,
            activeConnections: 2
        )

        XCTAssertEqual(complexServer.capabilities.tools.count, 3)
        XCTAssertEqual(complexServer.capabilities.permissions.count, 2)
        XCTAssertEqual(complexServer.capabilities.features.count, 5)
        XCTAssertEqual(complexServer.activeConnections, 2)
    }

    func testMCPServerDataModelWithNilStartTime() async throws {
        let noStartTimeServer = MCPServerDataModel(
            capabilities: sampleCapabilities,
            status: .starting,
            startTime: nil
        )

        XCTAssertNil(noStartTimeServer.startTime)
        XCTAssertEqual(noStartTimeServer.status, .starting)
    }

    func testMCPServerDataModelWithFutureStartTime() async throws {
        let futureTime = Date().addingTimeInterval(3600) // 1 hour in future
        let futureStartTimeServer = MCPServerDataModel(
            capabilities: sampleCapabilities,
            status: .starting,
            startTime: futureTime
        )

        XCTAssertEqual(futureStartTimeServer.startTime, futureTime)
        XCTAssertGreaterThan(futureStartTimeServer.startTime!, Date())
    }
}