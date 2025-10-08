//
//  ShortcutDataModelTests.swift
//  AppleMCPServer
//
//  Created on 2025-10-08.
//

import XCTest
@testable import AppleMCPServer

final class ShortcutDataModelTests: XCTestCase {

    // MARK: - Properties

    private var sampleParameter: ShortcutParameter!
    private var sampleOutput: ShortcutOutput!
    private var sampleShortcut: ShortcutDataModel!

    // MARK: - Setup and Teardown

    override func setUp() async throws {
        try await super.setUp()

        // Create sample parameter
        sampleParameter = ShortcutParameter(
            name: "text_input",
            type: "string",
            description: "Text input parameter",
            required: true,
            defaultValue: nil
        )

        // Create sample output
        sampleOutput = ShortcutOutput(
            name: "result",
            type: "string",
            description: "Execution result"
        )

        // Create sample shortcut
        sampleShortcut = ShortcutDataModel(
            name: "test_shortcut",
            description: "A test shortcut for unit testing",
            parameters: [sampleParameter],
            outputs: [sampleOutput],
            category: .productivity,
            iconName: "test_icon",
            color: .blue,
            requiresInput: true,
            providesOutput: true,
            estimatedExecutionTime: 5.0,
            useCount: 10
        )
    }

    override func tearDown() async throws {
        sampleParameter = nil
        sampleOutput = nil
        sampleShortcut = nil

        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func testShortcutDataModelInitialization() async throws {
        // Test basic initialization
        XCTAssertNotNil(sampleShortcut)
        XCTAssertEqual(sampleShortcut.name, "test_shortcut")
        XCTAssertEqual(sampleShortcut.description, "A test shortcut for unit testing")
        XCTAssertEqual(sampleShortcut.category, .productivity)
        XCTAssertEqual(sampleShortcut.iconName, "test_icon")
        XCTAssertEqual(sampleShortcut.color, .blue)
        XCTAssertTrue(sampleShortcut.isAvailable)
        XCTAssertTrue(sampleShortcut.isEnabled)
        XCTAssertTrue(sampleShortcut.requiresInput)
        XCTAssertTrue(sampleShortcut.providesOutput)
        XCTAssertEqual(sampleShortcut.estimatedExecutionTime, 5.0)
        XCTAssertEqual(sampleShortcut.useCount, 10)
        XCTAssertNotNil(sampleShortcut.createdDate)
        XCTAssertNotNil(sampleShortcut.modifiedDate)
        XCTAssertNil(sampleShortcut.lastUsed)
        XCTAssertNil(sampleShortcut.fileSize)
        XCTAssertFalse(sampleShortcut.systemShortcut)
    }

    func testShortcutDataModelWithCustomValues() async throws {
        let customShortcut = ShortcutDataModel(
            id: UUID(uuidString: "12345678-1234-5678-9abc-123456789abc")!,
            name: "custom_shortcut",
            description: "A custom shortcut with specific values",
            parameters: [],
            outputs: [],
            category: .automation,
            iconName: "custom_icon",
            color: .red,
            isAvailable: false,
            isEnabled: false,
            requiresInput: false,
            providesOutput: false,
            estimatedExecutionTime: 10.5,
            lastUsed: Date(timeIntervalSince1970: 1000000),
            useCount: 100,
            createdDate: Date(timeIntervalSince1970: 900000),
            modifiedDate: Date(timeIntervalSince1970: 950000),
            fileSize: 1024000,
            systemShortcut: true
        )

        XCTAssertEqual(customShortcut.name, "custom_shortcut")
        XCTAssertEqual(customShortcut.category, .automation)
        XCTAssertEqual(customShortcut.iconName, "custom_icon")
        XCTAssertEqual(customShortcut.color, .red)
        XCTAssertFalse(customShortcut.isAvailable)
        XCTAssertFalse(customShortcut.isEnabled)
        XCTAssertFalse(customShortcut.requiresInput)
        XCTAssertFalse(customShortcut.providesOutput)
        XCTAssertEqual(customShortcut.estimatedExecutionTime, 10.5)
        XCTAssertEqual(customShortcut.useCount, 100)
        XCTAssertEqual(customShortcut.fileSize, 1024000)
        XCTAssertTrue(customShortcut.systemShortcut)
    }

    func testShortcutDataModelDefaultValues() async throws {
        let defaultShortcut = ShortcutDataModel(
            name: "default_shortcut",
            description: "Shortcut with default values"
        )

        XCTAssertEqual(defaultShortcut.category, .general)
        XCTAssertNil(defaultShortcut.iconName)
        XCTAssertNil(defaultShortcut.color)
        XCTAssertTrue(defaultShortcut.isAvailable)
        XCTAssertTrue(defaultShortcut.isEnabled)
        XCTAssertFalse(defaultShortcut.requiresInput)
        XCTAssertFalse(defaultShortcut.providesOutput)
        XCTAssertNil(defaultShortcut.estimatedExecutionTime)
        XCTAssertNil(defaultShortcut.lastUsed)
        XCTAssertEqual(defaultShortcut.useCount, 0)
        XCTAssertNil(defaultShortcut.fileSize)
        XCTAssertFalse(defaultShortcut.systemShortcut)
    }

    // MARK: - Parameter Tests

    func testShortcutParameterValidation() async throws {
        let parameter = ShortcutParameter(
            name: "test_param",
            type: "string",
            description: "Test parameter",
            required: true,
            defaultValue: "default_value"
        )

        XCTAssertEqual(parameter.name, "test_param")
        XCTAssertEqual(parameter.type, "string")
        XCTAssertEqual(parameter.description, "Test parameter")
        XCTAssertTrue(parameter.required)
        XCTAssertEqual(parameter.defaultValue, "default_value")
    }

    func testShortcutWithMultipleParameters() async throws {
        let parameters = [
            ShortcutParameter(name: "text", type: "string", description: "Text input", required: true),
            ShortcutParameter(name: "number", type: "integer", description: "Number input", required: false, defaultValue: 42),
            ShortcutParameter(name: "flag", type: "boolean", description: "Boolean flag", required: false, defaultValue: true)
        ]

        let shortcut = ShortcutDataModel(
            name: "multi_param_shortcut",
            description: "Shortcut with multiple parameters",
            parameters: parameters
        )

        XCTAssertEqual(shortcut.parameters.count, 3)
        XCTAssertEqual(shortcut.parameters[0].name, "text")
        XCTAssertEqual(shortcut.parameters[1].name, "number")
        XCTAssertEqual(shortcut.parameters[2].name, "flag")
        XCTAssertTrue(shortcut.requiresInput) // Should be true because at least one parameter is required
    }

    // MARK: - Output Tests

    func testShortcutOutputValidation() async throws {
        let output = ShortcutOutput(
            name: "test_output",
            type: "string",
            description: "Test output"
        )

        XCTAssertEqual(output.name, "test_output")
        XCTAssertEqual(output.type, "string")
        XCTAssertEqual(output.description, "Test output")
    }

    func testShortcutWithMultipleOutputs() async throws {
        let outputs = [
            ShortcutOutput(name: "result", type: "string", description: "Primary result"),
            ShortcutOutput(name: "status", type: "integer", description: "Status code"),
            ShortcutOutput(name: "metadata", type: "object", description: "Additional metadata")
        ]

        let shortcut = ShortcutDataModel(
            name: "multi_output_shortcut",
            description: "Shortcut with multiple outputs",
            outputs: outputs
        )

        XCTAssertEqual(shortcut.outputs.count, 3)
        XCTAssertEqual(shortcut.outputs[0].name, "result")
        XCTAssertEqual(shortcut.outputs[1].name, "status")
        XCTAssertEqual(shortcut.outputs[2].name, "metadata")
        XCTAssertTrue(shortcut.providesOutput)
    }

    // MARK: - Category Tests

    func testAllShortcutCategories() async throws {
        let categories: [ShortcutCategory] = [
            .general, .productivity, .automation, .system, .utilities, .communication,
            .development, .media, .web, .security, .accessibility, .custom
        ]

        for category in categories {
            let shortcut = ShortcutDataModel(
                name: "\(category)_shortcut",
                description: "Shortcut in \(category) category",
                category: category
            )
            XCTAssertEqual(shortcut.category, category)
        }
    }

    func testShortcutCategoryRawValues() async throws {
        XCTAssertEqual(ShortcutCategory.general.rawValue, "general")
        XCTAssertEqual(ShortcutCategory.productivity.rawValue, "productivity")
        XCTAssertEqual(ShortcutCategory.automation.rawValue, "automation")
        XCTAssertEqual(ShortcutCategory.system.rawValue, "system")
        XCTAssertEqual(ShortcutCategory.utilities.rawValue, "utilities")
        XCTAssertEqual(ShortcutCategory.communication.rawValue, "communication")
        XCTAssertEqual(ShortcutCategory.development.rawValue, "development")
        XCTAssertEqual(ShortcutCategory.media.rawValue, "media")
        XCTAssertEqual(ShortcutCategory.web.rawValue, "web")
        XCTAssertEqual(ShortcutCategory.security.rawValue, "security")
        XCTAssertEqual(ShortcutCategory.accessibility.rawValue, "accessibility")
        XCTAssertEqual(ShortcutCategory.custom.rawValue, "custom")
    }

    // MARK: - Color Tests

    func testAllShortcutColors() async throws {
        let colors: [ShortcutColor] = [
            .red, .orange, .yellow, .green, .blue, .purple, .pink, .brown, .gray, .none
        ]

        for color in colors {
            let shortcut = ShortcutDataModel(
                name: "\(color)_shortcut",
                description: "Shortcut with \(color) color",
                color: color
            )
            XCTAssertEqual(shortcut.color, color)
        }
    }

    func testShortcutColorRawValues() async throws {
        XCTAssertEqual(ShortcutColor.red.rawValue, "red")
        XCTAssertEqual(ShortcutColor.orange.rawValue, "orange")
        XCTAssertEqual(ShortcutColor.yellow.rawValue, "yellow")
        XCTAssertEqual(ShortcutColor.green.rawValue, "green")
        XCTAssertEqual(ShortcutColor.blue.rawValue, "blue")
        XCTAssertEqual(ShortcutColor.purple.rawValue, "purple")
        XCTAssertEqual(ShortcutColor.pink.rawValue, "pink")
        XCTAssertEqual(ShortcutColor.brown.rawValue, "brown")
        XCTAssertEqual(ShortcutColor.gray.rawValue, "gray")
        XCTAssertEqual(ShortcutColor.none.rawValue, "none")
    }

    // MARK: - Codable Tests

    func testShortcutDataModelEncoding() async throws {
        let jsonData = try JSONEncoder().encode(sampleShortcut)
        XCTAssertFalse(jsonData.isEmpty)

        // Verify that encoded data contains expected fields
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]
        XCTAssertEqual(jsonObject["name"] as? String, "test_shortcut")
        XCTAssertEqual(jsonObject["description"] as? String, "A test shortcut for unit testing")
        XCTAssertEqual(jsonObject["category"] as? String, "productivity")
        XCTAssertEqual(jsonObject["iconName"] as? String, "test_icon")
        XCTAssertEqual(jsonObject["color"] as? String, "blue")
        XCTAssertTrue(jsonObject["isAvailable"] as? Bool ?? false)
        XCTAssertTrue(jsonObject["isEnabled"] as? Bool ?? false)
        XCTAssertTrue(jsonObject["requiresInput"] as? Bool ?? false)
        XCTAssertTrue(jsonObject["providesOutput"] as? Bool ?? false)
        XCTAssertEqual(jsonObject["useCount"] as? Int, 10)
    }

    func testShortcutDataModelDecoding() async throws {
        let shortcutData: [String: Any] = [
            "id": UUID().uuidString,
            "name": "decoded_shortcut",
            "description": "Shortcut created from JSON",
            "parameters": [
                [
                    "name": "input_text",
                    "type": "string",
                    "description": "Text input",
                    "required": true,
                    "defaultValue": nil
                ]
            ],
            "outputs": [
                [
                    "name": "result",
                    "type": "string",
                    "description": "Output result"
                ]
            ],
            "category": "automation",
            "iconName": "decoded_icon",
            "color": "green",
            "isAvailable": true,
            "isEnabled": true,
            "requiresInput": true,
            "providesOutput": true,
            "estimatedExecutionTime": 3.5,
            "lastUsed": ISO8601DateFormatter().string(from: Date()),
            "useCount": 5,
            "createdDate": ISO8601DateFormatter().string(from: Date()),
            "modifiedDate": ISO8601DateFormatter().string(from: Date()),
            "fileSize": 512000,
            "systemShortcut": false
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: shortcutData)
        let decodedShortcut = try JSONDecoder().decode(ShortcutDataModel.self, from: jsonData)

        XCTAssertEqual(decodedShortcut.name, "decoded_shortcut")
        XCTAssertEqual(decodedShortcut.description, "Shortcut created from JSON")
        XCTAssertEqual(decodedShortcut.category, .automation)
        XCTAssertEqual(decodedShortcut.iconName, "decoded_icon")
        XCTAssertEqual(decodedShortcut.color, .green)
        XCTAssertTrue(decodedShortcut.isAvailable)
        XCTAssertTrue(decodedShortcut.isEnabled)
        XCTAssertTrue(decodedShortcut.requiresInput)
        XCTAssertTrue(decodedShortcut.providesOutput)
        XCTAssertEqual(decodedShortcut.estimatedExecutionTime, 3.5)
        XCTAssertEqual(decodedShortcut.useCount, 5)
        XCTAssertEqual(decodedShortcut.fileSize, 512000)
        XCTAssertFalse(decodedShortcut.systemShortcut)
    }

    func testShortcutDataModelRoundTripEncoding() async throws {
        // Test that encoding and decoding preserves all data
        let originalShortcut = ShortcutDataModel(
            name: "roundtrip_shortcut",
            description: "Shortcut for roundtrip testing",
            parameters: [
                ShortcutParameter(name: "text", type: "string", description: "Text", required: true)
            ],
            outputs: [
                ShortcutOutput(name: "result", type: "string", description: "Result")
            ],
            category: .development,
            iconName: "roundtrip_icon",
            color: .purple,
            requiresInput: true,
            providesOutput: true,
            estimatedExecutionTime: 7.5,
            lastUsed: Date(),
            useCount: 25,
            fileSize: 2048000,
            systemShortcut: false
        )

        let encodedData = try JSONEncoder().encode(originalShortcut)
        let decodedShortcut = try JSONDecoder().decode(ShortcutDataModel.self, from: encodedData)

        XCTAssertEqual(originalShortcut.id, decodedShortcut.id)
        XCTAssertEqual(originalShortcut.name, decodedShortcut.name)
        XCTAssertEqual(originalShortcut.description, decodedShortcut.description)
        XCTAssertEqual(originalShortcut.category, decodedShortcut.category)
        XCTAssertEqual(originalShortcut.iconName, decodedShortcut.iconName)
        XCTAssertEqual(originalShortcut.color, decodedShortcut.color)
        XCTAssertEqual(originalShortcut.isAvailable, decodedShortcut.isAvailable)
        XCTAssertEqual(originalShortcut.isEnabled, decodedShortcut.isEnabled)
        XCTAssertEqual(originalShortcut.requiresInput, decodedShortcut.requiresInput)
        XCTAssertEqual(originalShortcut.providesOutput, decodedShortcut.providesOutput)
        XCTAssertEqual(originalShortcut.estimatedExecutionTime, decodedShortcut.estimatedExecutionTime)
        XCTAssertEqual(originalShortcut.useCount, decodedShortcut.useCount)
        XCTAssertEqual(originalShortcut.fileSize, decodedShortcut.fileSize)
        XCTAssertEqual(originalShortcut.systemShortcut, decodedShortcut.systemShortcut)
        XCTAssertEqual(originalShortcut.parameters.count, decodedShortcut.parameters.count)
        XCTAssertEqual(originalShortcut.outputs.count, decodedShortcut.outputs.count)
    }

    // MARK: - Business Logic Tests

    func testShortcutUsageTracking() async throws {
        let shortcut = ShortcutDataModel(
            name: "usage_test_shortcut",
            description: "Shortcut for usage testing",
            useCount: 5
        )

        XCTAssertEqual(shortcut.useCount, 5)

        // Simulate usage increment
        let updatedShortcut = ShortcutDataModel(
            id: shortcut.id,
            name: shortcut.name,
            description: shortcut.description,
            parameters: shortcut.parameters,
            outputs: shortcut.outputs,
            category: shortcut.category,
            iconName: shortcut.iconName,
            color: shortcut.color,
            isAvailable: shortcut.isAvailable,
            isEnabled: shortcut.isEnabled,
            requiresInput: shortcut.requiresInput,
            providesOutput: shortcut.providesOutput,
            estimatedExecutionTime: shortcut.estimatedExecutionTime,
            lastUsed: Date(),
            useCount: shortcut.useCount + 1,
            createdDate: shortcut.createdDate,
            modifiedDate: Date(),
            fileSize: shortcut.fileSize,
            systemShortcut: shortcut.systemShortcut
        )

        XCTAssertEqual(updatedShortcut.useCount, 6)
        XCTAssertNotNil(updatedShortcut.lastUsed)
        XCTAssertGreaterThan(updatedShortcut.modifiedDate, shortcut.modifiedDate)
    }

    func testShortcutAvailabilityManagement() async throws {
        let availableShortcut = ShortcutDataModel(
            name: "available_shortcut",
            description: "Available shortcut",
            isAvailable: true,
            isEnabled: true
        )

        XCTAssertTrue(availableShortcut.isAvailable)
        XCTAssertTrue(availableShortcut.isEnabled)

        // Disable the shortcut
        let disabledShortcut = ShortcutDataModel(
            id: availableShortcut.id,
            name: availableShortcut.name,
            description: availableShortcut.description,
            parameters: availableShortcut.parameters,
            outputs: availableShortcut.outputs,
            category: availableShortcut.category,
            iconName: availableShortcut.iconName,
            color: availableShortcut.color,
            isAvailable: false,
            isEnabled: false,
            requiresInput: availableShortcut.requiresInput,
            providesOutput: availableShortcut.providesOutput,
            estimatedExecutionTime: availableShortcut.estimatedExecutionTime,
            lastUsed: availableShortcut.lastUsed,
            useCount: availableShortcut.useCount,
            createdDate: availableShortcut.createdDate,
            modifiedDate: Date(),
            fileSize: availableShortcut.fileSize,
            systemShortcut: availableShortcut.systemShortcut
        )

        XCTAssertFalse(disabledShortcut.isAvailable)
        XCTAssertFalse(disabledShortcut.isEnabled)
    }

    func testShortcutInputOutputRequirements() async throws {
        // Test shortcut with no parameters or outputs
        let simpleShortcut = ShortcutDataModel(
            name: "simple_shortcut",
            description: "Simple shortcut",
            parameters: [],
            outputs: []
        )

        XCTAssertFalse(simpleShortcut.requiresInput)
        XCTAssertFalse(simpleShortcut.providesOutput)

        // Test shortcut with parameters but no outputs
        let inputOnlyShortcut = ShortcutDataModel(
            name: "input_only_shortcut",
            description: "Input only shortcut",
            parameters: [sampleParameter],
            outputs: []
        )

        XCTAssertTrue(inputOnlyShortcut.requiresInput)
        XCTAssertFalse(inputOnlyShortcut.providesOutput)

        // Test shortcut with outputs but no parameters
        let outputOnlyShortcut = ShortcutDataModel(
            name: "output_only_shortcut",
            description: "Output only shortcut",
            parameters: [],
            outputs: [sampleOutput]
        )

        XCTAssertFalse(outputOnlyShortcut.requiresInput)
        XCTAssertTrue(outputOnlyShortcut.providesOutput)
    }

    // MARK: - Performance and Execution Tests

    func testEstimatedExecutionTimeValidation() async throws {
        let executionTimes: [TimeInterval?] = [
            nil, 0.1, 1.0, 5.5, 30.0, 120.0
        ]

        for executionTime in executionTimes {
            let shortcut = ShortcutDataModel(
                name: "performance_test_shortcut",
                description: "Performance test shortcut",
                estimatedExecutionTime: executionTime
            )
            XCTAssertEqual(shortcut.estimatedExecutionTime, executionTime)
        }
    }

    func testSystemShortcutIdentification() async throws {
        let userShortcut = ShortcutDataModel(
            name: "user_shortcut",
            description: "User-created shortcut",
            systemShortcut: false
        )

        let systemShortcut = ShortcutDataModel(
            name: "system_shortcut",
            description: "System-provided shortcut",
            systemShortcut: true
        )

        XCTAssertFalse(userShortcut.systemShortcut)
        XCTAssertTrue(systemShortcut.systemShortcut)
    }

    // MARK: - File Size Tests

    func testFileSizeValidation() async throws {
        let fileSizes: [Int64?] = [
            nil, 0, 1024, 1024000, 10485760
        ]

        for fileSize in fileSizes {
            let shortcut = ShortcutDataModel(
                name: "file_size_test_shortcut",
                description: "File size test shortcut",
                fileSize: fileSize
            )
            XCTAssertEqual(shortcut.fileSize, fileSize)
        }
    }

    // MARK: - Edge Cases Tests

    func testShortcutWithEmptyName() async throws {
        let emptyNameShortcut = ShortcutDataModel(
            name: "",
            description: "Shortcut with empty name"
        )

        XCTAssertEqual(emptyNameShortcut.name, "")
        XCTAssertFalse(emptyNameShortcut.name.isEmpty == false)
    }

    func testShortcutWithVeryLongDescription() async throws {
        let longDescription = String(repeating: "This is a very long description. ", count: 50)
        let longDescShortcut = ShortcutDataModel(
            name: "long_desc_shortcut",
            description: longDescription
        )

        XCTAssertEqual(longDescShortcut.description, longDescription)
    }

    func testShortcutWithSpecialCharacters() async throws {
        let specialShortcut = ShortcutDataModel(
            name: "special_chars_🚀_shortcut_àéîöü",
            description: "Shortcut with special chars: 中文, العربية, emojis 🎉",
            iconName: "icon_🎨_测试"
        )

        XCTAssertEqual(specialShortcut.name, "special_chars_🚀_shortcut_àéîöü")
        XCTAssertEqual(specialShortcut.description, "Shortcut with special chars: 中文, العربية, emojis 🎉")
        XCTAssertEqual(specialShortcut.iconName, "icon_🎨_测试")
    }

    func testShortcutWithMaximumParameters() async throws {
        var maxParameters: [ShortcutParameter] = []
        for i in 1...50 {
            maxParameters.append(ShortcutParameter(
                name: "parameter_\(i)",
                type: "string",
                description: "Parameter number \(i)",
                required: i <= 10
            ))
        }

        let maxParamShortcut = ShortcutDataModel(
            name: "max_param_shortcut",
            description: "Shortcut with maximum parameters",
            parameters: maxParameters
        )

        XCTAssertEqual(maxParamShortcut.parameters.count, 50)
        XCTAssertTrue(maxParamShortcut.requiresInput)
    }

    func testShortcutWithMaximumOutputs() async throws {
        var maxOutputs: [ShortcutOutput] = []
        for i in 1...20 {
            maxOutputs.append(ShortcutOutput(
                name: "output_\(i)",
                type: "string",
                description: "Output number \(i)"
            ))
        }

        let maxOutputShortcut = ShortcutDataModel(
            name: "max_output_shortcut",
            description: "Shortcut with maximum outputs",
            outputs: maxOutputs
        )

        XCTAssertEqual(maxOutputShortcut.outputs.count, 20)
        XCTAssertTrue(maxOutputShortcut.providesOutput)
    }
}