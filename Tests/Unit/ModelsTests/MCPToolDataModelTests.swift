//
//  MCPToolDataModelTests.swift
//  AppleMCPServer
//
//  Created on 2025-10-08.
//

import XCTest
@testable import AppleMCPServer

final class MCPToolDataModelTests: XCTestCase {

    // MARK: - Properties

    private var sampleInputSchema: ToolInputSchema!
    private var sampleTool: MCPToolDataModel!

    // MARK: - Setup and Teardown

    override func setUp() async throws {
        try await super.setUp()

        // Create sample input schema
        sampleInputSchema = ToolInputSchema(
            type: "object",
            properties: [
                "command": [
                    "type": "string",
                    "description": "Command to execute"
                ],
                "parameters": [
                    "type": "object",
                    "description": "Command parameters"
                ]
            ],
            required: ["command"]
        )

        // Create sample tool
        sampleTool = MCPToolDataModel(
            name: "test_tool",
            description: "A test tool for unit testing",
            category: .utility,
            inputSchema: sampleInputSchema,
            requiresPermission: [.shortcuts],
            offlineCapable: true,
            isActive: true,
            version: "1.0.0"
        )
    }

    override func tearDown() async throws {
        sampleInputSchema = nil
        sampleTool = nil

        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func testMCPToolDataModelInitialization() async throws {
        // Test basic initialization
        XCTAssertNotNil(sampleTool)
        XCTAssertEqual(sampleTool.name, "test_tool")
        XCTAssertEqual(sampleTool.description, "A test tool for unit testing")
        XCTAssertEqual(sampleTool.category, .utility)
        XCTAssertTrue(sampleTool.offlineCapable)
        XCTAssertTrue(sampleTool.isActive)
        XCTAssertEqual(sampleTool.version, "1.0.0")
        XCTAssertNotNil(sampleTool.registeredAt)
        XCTAssertNil(sampleTool.lastUsed)
    }

    func testMCPToolDataModelWithCustomValues() async throws {
        let customTool = MCPToolDataModel(
            id: UUID(uuidString: "12345678-1234-5678-9abc-123456789abc")!,
            name: "custom_tool",
            description: "A custom tool with specific values",
            category: .shortcuts,
            inputSchema: sampleInputSchema,
            requiresPermission: [.systemInfo, .voiceControl],
            offlineCapable: false,
            isActive: false,
            version: "2.1.0",
            registeredAt: Date(timeIntervalSince1970: 1000000),
            lastUsed: Date(timeIntervalSince1970: 1000100)
        )

        XCTAssertEqual(customTool.name, "custom_tool")
        XCTAssertEqual(customTool.description, "A custom tool with specific values")
        XCTAssertEqual(customTool.category, .shortcuts)
        XCTAssertEqual(customTool.requiresPermission, [.systemInfo, .voiceControl])
        XCTAssertFalse(customTool.offlineCapable)
        XCTAssertFalse(customTool.isActive)
        XCTAssertEqual(customTool.version, "2.1.0")
        XCTAssertNotNil(customTool.lastUsed)
    }

    func testMCPToolDataModelDefaultValues() async throws {
        let defaultTool = MCPToolDataModel(
            name: "default_tool",
            description: "Tool with default values",
            inputSchema: sampleInputSchema
        )

        XCTAssertEqual(defaultTool.category, .general)
        XCTAssertTrue(defaultTool.requiresPermission.isEmpty)
        XCTAssertTrue(defaultTool.offlineCapable)
        XCTAssertTrue(defaultTool.isActive)
        XCTAssertEqual(defaultTool.version, "1.0.0")
        XCTAssertNil(defaultTool.lastUsed)
    }

    // MARK: - Property Validation Tests

    func testNameValidation() async throws {
        // Test valid names
        let validNames = ["test_tool", "shortcuts_runner", "voice_command", "system_info", "health_check"]
        for name in validNames {
            let tool = MCPToolDataModel(
                name: name,
                description: "Valid name test",
                inputSchema: sampleInputSchema
            )
            XCTAssertEqual(tool.name, name)
        }

        // Test edge cases
        let edgeCases = ["a", "tool_with_very_long_name_that_is_still_valid", "tool123", "Tool_With_Caps"]
        for name in edgeCases {
            let tool = MCPToolDataModel(
                name: name,
                description: "Edge case test",
                inputSchema: sampleInputSchema
            )
            XCTAssertEqual(tool.name, name)
        }
    }

    func testDescriptionValidation() async throws {
        // Test various description lengths
        let descriptions = [
            "Short",
            "A medium length description that provides good context",
            String(repeating: "This is a very long description. ", count: 20)
        ]

        for description in descriptions {
            let tool = MCPToolDataModel(
                name: "description_test",
                description: description,
                inputSchema: sampleInputSchema
            )
            XCTAssertEqual(tool.description, description)
        }
    }

    func testVersionValidation() async throws {
        // Test semantic versioning patterns
        let validVersions = ["1.0.0", "2.1.3", "10.5.0", "1.0.0-beta", "2.1.3-alpha.1"]

        for version in validVersions {
            let tool = MCPToolDataModel(
                name: "version_test",
                description: "Version test",
                inputSchema: sampleInputSchema,
                version: version
            )
            XCTAssertEqual(tool.version, version)
        }
    }

    // MARK: - Category Tests

    func testAllToolCategories() async throws {
        let categories: [ToolCategory] = [
            .general, .shortcuts, .voiceControl, .systemInfo, .utility, .system, .accessibility, .security
        ]

        for category in categories {
            let tool = MCPToolDataModel(
                name: "\(category)_tool",
                description: "Tool in \(category) category",
                inputSchema: sampleInputSchema,
                category: category
            )
            XCTAssertEqual(tool.category, category)
        }
    }

    func testToolCategoryRawValues() async throws {
        XCTAssertEqual(ToolCategory.general.rawValue, "general")
        XCTAssertEqual(ToolCategory.shortcuts.rawValue, "shortcuts")
        XCTAssertEqual(ToolCategory.voiceControl.rawValue, "voice_control")
        XCTAssertEqual(ToolCategory.systemInfo.rawValue, "system_info")
        XCTAssertEqual(ToolCategory.utility.rawValue, "utility")
        XCTAssertEqual(ToolCategory.system.rawValue, "system")
        XCTAssertEqual(ToolCategory.accessibility.rawValue, "accessibility")
        XCTAssertEqual(ToolCategory.security.rawValue, "security")
    }

    // MARK: - Permission Tests

    func testPermissionTypes() async throws {
        let permissionSets: [[PermissionType]] = [
            [],
            [.shortcuts],
            [.voiceControl],
            [.systemInfo],
            [.shortcuts, .voiceControl],
            [.systemInfo, .shortcuts, .voiceControl]
        ]

        for permissions in permissionSets {
            let tool = MCPToolDataModel(
                name: "permission_test",
                description: "Permission test",
                inputSchema: sampleInputSchema,
                requiresPermission: permissions
            )
            XCTAssertEqual(tool.requiresPermission, permissions)
        }
    }

    func testPermissionTypeRawValues() async throws {
        XCTAssertEqual(PermissionType.shortcuts.rawValue, "shortcuts")
        XCTAssertEqual(PermissionType.voiceControl.rawValue, "voice_control")
        XCTAssertEqual(PermissionType.systemInfo.rawValue, "system_info")
        XCTAssertEqual(PermissionType.admin.rawValue, "admin")
    }

    // MARK: - Input Schema Tests

    func testInputSchemaValidation() async throws {
        // Test complex input schema
        let complexSchema = ToolInputSchema(
            type: "object",
            properties: [
                "name": [
                    "type": "string",
                    "minLength": 1,
                    "maxLength": 100
                ],
                "age": [
                    "type": "integer",
                    "minimum": 0,
                    "maximum": 150
                ],
                "active": [
                    "type": "boolean",
                    "default": true
                ],
                "tags": [
                    "type": "array",
                    "items": ["type": "string"]
                ]
            ],
            required: ["name"]
        )

        let tool = MCPToolDataModel(
            name: "schema_test",
            description: "Schema test",
            inputSchema: complexSchema
        )

        XCTAssertEqual(tool.inputSchema.type, "object")
        XCTAssertEqual(tool.inputSchema.required, ["name"])
        XCTAssertNotNil(tool.inputSchema.properties["name"])
        XCTAssertNotNil(tool.inputSchema.properties["age"])
        XCTAssertNotNil(tool.inputSchema.properties["active"])
        XCTAssertNotNil(tool.inputSchema.properties["tags"])
    }

    func testMinimalInputSchema() async throws {
        let minimalSchema = ToolInputSchema(
            type: "object",
            properties: [:],
            required: []
        )

        let tool = MCPToolDataModel(
            name: "minimal_test",
            description: "Minimal schema test",
            inputSchema: minimalSchema
        )

        XCTAssertEqual(tool.inputSchema.type, "object")
        XCTAssertTrue(tool.inputSchema.properties.isEmpty)
        XCTAssertTrue(tool.inputSchema.required.isEmpty)
    }

    // MARK: - Codable Tests

    func testToolDataModelEncoding() async throws {
        let jsonData = try JSONEncoder().encode(sampleTool)
        XCTAssertFalse(jsonData.isEmpty)

        // Verify that encoded data contains expected fields
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]
        XCTAssertEqual(jsonObject["name"] as? String, "test_tool")
        XCTAssertEqual(jsonObject["description"] as? String, "A test tool for unit testing")
        XCTAssertEqual(jsonObject["category"] as? String, "utility")
        XCTAssertEqual(jsonObject["version"] as? String, "1.0.0")
        XCTAssertTrue(jsonObject["offlineCapable"] as? Bool ?? false)
        XCTAssertTrue(jsonObject["isActive"] as? Bool ?? false)
    }

    func testToolDataModelDecoding() async throws {
        let toolData: [String: Any] = [
            "id": UUID().uuidString,
            "name": "decoded_tool",
            "description": "Tool created from JSON",
            "category": "shortcuts",
            "inputSchema": [
                "type": "object",
                "properties": ["command": ["type": "string"]],
                "required": ["command"]
            ],
            "requiresPermission": ["shortcuts"],
            "offlineCapable": true,
            "isActive": true,
            "version": "1.2.0",
            "registeredAt": ISO8601DateFormatter().string(from: Date()),
            "lastUsed": nil
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: toolData)
        let decodedTool = try JSONDecoder().decode(MCPToolDataModel.self, from: jsonData)

        XCTAssertEqual(decodedTool.name, "decoded_tool")
        XCTAssertEqual(decodedTool.description, "Tool created from JSON")
        XCTAssertEqual(decodedTool.category, .shortcuts)
        XCTAssertEqual(decodedTool.version, "1.2.0")
        XCTAssertTrue(decodedTool.offlineCapable)
        XCTAssertTrue(decodedTool.isActive)
    }

    func testToolDataModelRoundTripEncoding() async throws {
        // Test that encoding and decoding preserves all data
        let originalTool = MCPToolDataModel(
            name: "roundtrip_test",
            description: "Tool for roundtrip testing",
            category: .security,
            inputSchema: ToolInputSchema(
                type: "object",
                properties: [
                    "action": ["type": "string"],
                    "target": ["type": "string"]
                ],
                required: ["action"]
            ),
            requiresPermission: [.admin],
            offlineCapable: false,
            isActive: true,
            version: "3.0.0",
            lastUsed: Date()
        )

        let encodedData = try JSONEncoder().encode(originalTool)
        let decodedTool = try JSONDecoder().decode(MCPToolDataModel.self, from: encodedData)

        XCTAssertEqual(originalTool.id, decodedTool.id)
        XCTAssertEqual(originalTool.name, decodedTool.name)
        XCTAssertEqual(originalTool.description, decodedTool.description)
        XCTAssertEqual(originalTool.category, decodedTool.category)
        XCTAssertEqual(originalTool.requiresPermission, decodedTool.requiresPermission)
        XCTAssertEqual(originalTool.offlineCapable, decodedTool.offlineCapable)
        XCTAssertEqual(originalTool.isActive, decodedTool.isActive)
        XCTAssertEqual(originalTool.version, decodedTool.version)
        XCTAssertEqual(originalTool.inputSchema.type, decodedTool.inputSchema.type)
        XCTAssertEqual(originalTool.inputSchema.required, decodedTool.inputSchema.required)
    }

    // MARK: - Business Logic Tests

    func testToolDataModelUpdateUsage() async throws {
        let tool = MCPToolDataModel(
            name: "usage_test",
            description: "Tool for usage testing",
            inputSchema: sampleInputSchema
        )

        // Initially should have no last used date
        XCTAssertNil(tool.lastUsed)

        // Create a new tool with updated usage
        let now = Date()
        let updatedTool = MCPToolDataModel(
            id: tool.id,
            name: tool.name,
            description: tool.description,
            category: tool.category,
            inputSchema: tool.inputSchema,
            requiresPermission: tool.requiresPermission,
            offlineCapable: tool.offlineCapable,
            isActive: tool.isActive,
            version: tool.version,
            registeredAt: tool.registeredAt,
            lastUsed: now
        )

        XCTAssertNotNil(updatedTool.lastUsed)
        XCTAssertEqual(updatedTool.lastUsed, now)
    }

    func testToolDataModelActivation() async throws {
        let inactiveTool = MCPToolDataModel(
            name: "inactive_tool",
            description: "Inactive tool",
            inputSchema: sampleInputSchema,
            isActive: false
        )

        XCTAssertFalse(inactiveTool.isActive)

        // Activate the tool
        let activeTool = MCPToolDataModel(
            id: inactiveTool.id,
            name: inactiveTool.name,
            description: inactiveTool.description,
            category: inactiveTool.category,
            inputSchema: inactiveTool.inputSchema,
            requiresPermission: inactiveTool.requiresPermission,
            offlineCapable: inactiveTool.offlineCapable,
            isActive: true,
            version: inactiveTool.version,
            registeredAt: inactiveTool.registeredAt,
            lastUsed: inactiveTool.lastUsed
        )

        XCTAssertTrue(activeTool.isActive)
    }

    // MARK: - Comparison and Equality Tests

    func testToolDataModelEquality() async throws {
        let tool1 = MCPToolDataModel(
            id: UUID(uuidString: "12345678-1234-5678-9abc-123456789abc")!,
            name: "same_tool",
            description: "Same description",
            inputSchema: sampleInputSchema
        )

        let tool2 = MCPToolDataModel(
            id: UUID(uuidString: "12345678-1234-5678-9abc-123456789abc")!,
            name: "same_tool",
            description: "Same description",
            inputSchema: sampleInputSchema
        )

        let tool3 = MCPToolDataModel(
            name: "different_tool",
            description: "Different description",
            inputSchema: sampleInputSchema
        )

        XCTAssertEqual(tool1.id, tool2.id)
        XCTAssertEqual(tool1.name, tool2.name)
        XCTAssertEqual(tool1.description, tool2.description)
        XCTAssertNotEqual(tool1.id, tool3.id)
        XCTAssertNotEqual(tool1.name, tool3.name)
    }

    // MARK: - Edge Cases Tests

    func testEmptyInputSchemaProperties() async throws {
        let emptySchema = ToolInputSchema(
            type: "object",
            properties: [:],
            required: []
        )

        let tool = MCPToolDataModel(
            name: "empty_schema_test",
            description: "Tool with empty schema",
            inputSchema: emptySchema
        )

        XCTAssertTrue(tool.inputSchema.properties.isEmpty)
        XCTAssertTrue(tool.inputSchema.required.isEmpty)
    }

    func testLargeInputSchema() async throws {
        var largeProperties: [String: [String: Any]] = [:]
        for i in 1...100 {
            largeProperties["property_\(i)"] = [
                "type": "string",
                "description": "Property number \(i)"
            ]
        }

        let largeRequired = Array(1...20).map { "property_\($0)" }

        let largeSchema = ToolInputSchema(
            type: "object",
            properties: largeProperties,
            required: largeRequired
        )

        let tool = MCPToolDataModel(
            name: "large_schema_test",
            description: "Tool with large schema",
            inputSchema: largeSchema
        )

        XCTAssertEqual(tool.inputSchema.properties.count, 100)
        XCTAssertEqual(tool.inputSchema.required.count, 20)
    }

    func testSpecialCharactersInNameAndDescription() async throws {
        let specialTool = MCPToolDataModel(
            name: "special_chars_🚀_tool_àéîöü",
            description: "Tool with special chars: 中文, العربية, emojis 🎉",
            inputSchema: sampleInputSchema
        )

        XCTAssertEqual(specialTool.name, "special_chars_🚀_tool_àéîöü")
        XCTAssertEqual(specialTool.description, "Tool with special chars: 中文, العربية, emojis 🎉")
    }
}