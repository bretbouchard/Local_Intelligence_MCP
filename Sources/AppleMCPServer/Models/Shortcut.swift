//
//  Shortcut.swift
//  AppleMCPServer
//
//  Created on 2025-10-07.
//

import Foundation

/// Data model for Apple Shortcuts
/// Aligns with the data-model.md specification
struct ShortcutDataModel: Codable, Identifiable {
    let id: UUID
    let name: String
    let description: String
    let parameters: [ShortcutParameter]
    let outputs: [ShortcutOutput]
    let category: ShortcutCategory
    let iconName: String?
    let color: ShortcutColor?
    let isAvailable: Bool
    let isEnabled: Bool
    let requiresInput: Bool
    let providesOutput: Bool
    let estimatedExecutionTime: TimeInterval?
    let lastUsed: Date?
    let useCount: Int
    let createdDate: Date
    let modifiedDate: Date
    let fileSize: Int64?
    let systemShortcut: Bool

    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        parameters: [ShortcutParameter] = [],
        outputs: [ShortcutOutput] = [],
        category: ShortcutCategory = .general,
        iconName: String? = nil,
        color: ShortcutColor? = nil,
        isAvailable: Bool = true,
        isEnabled: Bool = true,
        requiresInput: Bool = false,
        providesOutput: Bool = false,
        estimatedExecutionTime: TimeInterval? = nil,
        lastUsed: Date? = nil,
        useCount: Int = 0,
        createdDate: Date = Date(),
        modifiedDate: Date = Date(),
        fileSize: Int64? = nil,
        systemShortcut: Bool = false
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.parameters = parameters
        self.outputs = outputs
        self.category = category
        self.iconName = iconName
        self.color = color
        self.isAvailable = isAvailable
        self.isEnabled = isEnabled
        self.requiresInput = requiresInput
        self.providesOutput = providesOutput
        self.estimatedExecutionTime = estimatedExecutionTime
        self.lastUsed = lastUsed
        self.useCount = useCount
        self.createdDate = createdDate
        self.modifiedDate = modifiedDate
        self.fileSize = fileSize
        self.systemShortcut = systemShortcut

        // Auto-determine input/output requirements
        self._requiresInput = !parameters.isEmpty
        self._providesOutput = !outputs.isEmpty
    }

    private var _requiresInput: Bool
    private var _providesOutput: Bool

    /// Update usage information
    func with(usedAt: Date) -> ShortcutDataModel {
        return ShortcutDataModel(
            id: id,
            name: name,
            description: description,
            parameters: parameters,
            outputs: outputs,
            category: category,
            iconName: iconName,
            color: color,
            isAvailable: isAvailable,
            isEnabled: isEnabled,
            requiresInput: requiresInput,
            providesOutput: providesOutput,
            estimatedExecutionTime: estimatedExecutionTime,
            lastUsed: usedAt,
            useCount: useCount + 1,
            createdDate: createdDate,
            modifiedDate: modifiedDate,
            fileSize: fileSize,
            systemShortcut: systemShortcut
        )
    }

    /// Update availability status
    func with(isAvailable: Bool) -> ShortcutDataModel {
        return ShortcutDataModel(
            id: id,
            name: name,
            description: description,
            parameters: parameters,
            outputs: outputs,
            category: category,
            iconName: iconName,
            color: color,
            isAvailable: isAvailable,
            isEnabled: isEnabled,
            requiresInput: requiresInput,
            providesOutput: providesOutput,
            estimatedExecutionTime: estimatedExecutionTime,
            lastUsed: lastUsed,
            useCount: useCount,
            createdDate: createdDate,
            modifiedDate: Date(),
            fileSize: fileSize,
            systemShortcut: systemShortcut
        )
    }

    /// Update enabled status
    func with(isEnabled: Bool) -> ShortcutDataModel {
        return ShortcutDataModel(
            id: id,
            name: name,
            description: description,
            parameters: parameters,
            outputs: outputs,
            category: category,
            iconName: iconName,
            color: color,
            isAvailable: isAvailable,
            isEnabled: isEnabled,
            requiresInput: requiresInput,
            providesOutput: providesOutput,
            estimatedExecutionTime: estimatedExecutionTime,
            lastUsed: lastUsed,
            useCount: useCount,
            createdDate: createdDate,
            modifiedDate: Date(),
            fileSize: fileSize,
            systemShortcut: systemShortcut
        )
    }

    /// Validate shortcut model
    func validate() -> ValidationResult {
        var errors: [ValidationError] = []

        // Validate name
        if name.isEmpty {
            errors.append(ValidationError(
                code: "INVALID_SHORTCUT_NAME",
                message: "Shortcut name cannot be empty",
                field: "name",
                value: name
            ))
        }

        if name.count > MCPConstants.Limits.maxShortcutNameLength {
            errors.append(ValidationError(
                code: "SHORTCUT_NAME_TOO_LONG",
                message: "Shortcut name cannot exceed \(MCPConstants.Limits.maxShortcutNameLength) characters",
                field: "name",
                value: name
            ))
        }

        // Validate description
        if description.isEmpty {
            errors.append(ValidationError(
                code: "INVALID_SHORTCUT_DESCRIPTION",
                message: "Shortcut description cannot be empty",
                field: "description",
                value: description
            ))
        }

        if description.count > MCPConstants.Limits.maxShortcutDescriptionLength {
            errors.append(ValidationError(
                code: "SHORTCUT_DESCRIPTION_TOO_LONG",
                message: "Shortcut description cannot exceed \(MCPConstants.Limits.maxShortcutDescriptionLength) characters",
                field: "description",
                value: description
            ))
        }

        // Validate parameters
        for (index, parameter) in parameters.enumerated() {
            let paramValidation = parameter.validate()
            errors.append(contentsOf: paramValidation.errors.map { error in
                ValidationError(
                    code: error.code,
                    message: "Parameter '\(parameter.name)': \(error.message)",
                    field: "parameters[\(index)]",
                    value: error.value
                )
            })
        }

        // Validate outputs
        for (index, output) in outputs.enumerated() {
            let outputValidation = output.validate()
            errors.append(contentsOf: outputValidation.errors.map { error in
                ValidationError(
                    code: error.code,
                    message: "Output '\(output.name)': \(error.message)",
                    field: "outputs[\(index)]",
                    value: error.value
                )
            })
        }

        // Validate use count
        if useCount < 0 {
            errors.append(ValidationError(
                code: "INVALID_USE_COUNT",
                message: "Use count cannot be negative",
                field: "useCount",
                value: useCount
            ))
        }

        // Validate file size
        if let fileSize = fileSize, fileSize < 0 {
            errors.append(ValidationError(
                code: "INVALID_FILE_SIZE",
                message: "File size cannot be negative",
                field: "fileSize",
                value: fileSize
            ))
        }

        return ValidationResult(errors: errors)
    }

    /// Check if shortcut can be executed
    func canExecute() -> Bool {
        return isAvailable && isEnabled
    }

    /// Get parameter by name
    func getParameter(name: String) -> ShortcutParameter? {
        return parameters.first { $0.name.lowercased() == name.lowercased() }
    }

    /// Get output by name
    func getOutput(name: String) -> ShortcutOutput? {
        return outputs.first { $0.name.lowercased() == name.lowercased() }
    }

    /// Export shortcut for MCP format
    func exportForMCP() -> [String: Any] {
        return [
            "id": id.uuidString,
            "name": name,
            "description": description,
            "category": category.rawValue,
            "parameters": parameters.map { $0.export() },
            "outputs": outputs.map { $0.export() },
            "isAvailable": isAvailable,
            "isEnabled": isEnabled,
            "requiresInput": requiresInput,
            "providesOutput": providesOutput,
            "useCount": useCount,
            "systemShortcut": systemShortcut
        ]
    }
}

/// Shortcut parameter definition
struct ShortcutParameter: Codable, Identifiable {
    let id: UUID
    let name: String
    let type: ParameterType
    let description: String
    let required: Bool
    let defaultValue: AnyCodable?
    let allowedValues: [String]?
    let minLength: Int?
    let maxLength: Int?
    let minimum: Double?
    let maximum: Double?

    init(
        id: UUID = UUID(),
        name: String,
        type: ParameterType,
        description: String,
        required: Bool = false,
        defaultValue: AnyCodable? = nil,
        allowedValues: [String]? = nil,
        minLength: Int? = nil,
        maxLength: Int? = nil,
        minimum: Double? = nil,
        maximum: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.description = description
        self.required = required
        self.defaultValue = defaultValue
        self.allowedValues = allowedValues
        self.minLength = minLength
        self.maxLength = maxLength
        self.minimum = minimum
        self.maximum = maximum
    }

    /// Validate parameter definition
    func validate() -> ValidationResult {
        var errors: [ValidationError] = []

        // Validate name
        if name.isEmpty {
            errors.append(ValidationError(
                code: "INVALID_PARAMETER_NAME",
                message: "Parameter name cannot be empty",
                field: "name",
                value: name
            ))
        }

        // Validate description
        if description.isEmpty {
            errors.append(ValidationError(
                code: "INVALID_PARAMETER_DESCRIPTION",
                message: "Parameter description cannot be empty",
                field: "description",
                value: description
            ))
        }

        // Validate type-specific constraints
        switch type {
        case .string:
            if let minLength = minLength, let maxLength = maxLength, minLength > maxLength {
                errors.append(ValidationError(
                    code: "INVALID_STRING_LENGTH_RANGE",
                    message: "Minimum length cannot be greater than maximum length",
                    field: "minLength",
                    value: minLength
                ))
            }

        case .number, .integer:
            if let minimum = minimum, let maximum = maximum, minimum > maximum {
                errors.append(ValidationError(
                    code: "INVALID_NUMERIC_RANGE",
                    message: "Minimum value cannot be greater than maximum value",
                    field: "minimum",
                    value: minimum
                ))
            }

        default:
            break
        }

        return ValidationResult(errors: errors)
    }

    /// Validate parameter value
    func validateValue(_ value: Any) -> ValidationResult {
        var errors: [ValidationError] = []

        // Type validation would happen here based on the parameter type
        // This is a simplified implementation

        // String-specific validation
        if type == .string, let stringValue = value as? String {
            if let minLength = minLength, stringValue.count < minLength {
                errors.append(ValidationError(
                    code: "STRING_TOO_SHORT",
                    message: "String value must be at least \(minLength) characters",
                    field: "value",
                    value: stringValue
                ))
            }

            if let maxLength = maxLength, stringValue.count > maxLength {
                errors.append(ValidationError(
                    code: "STRING_TOO_LONG",
                    message: "String value cannot exceed \(maxLength) characters",
                    field: "value",
                    value: stringValue
                ))
            }

            if let allowedValues = allowedValues, !allowedValues.contains(stringValue) {
                errors.append(ValidationError(
                    code: "VALUE_NOT_ALLOWED",
                    message: "Value must be one of: \(allowedValues.joined(separator: ", "))",
                    field: "value",
                    value: stringValue
                ))
            }
        }

        // Number-specific validation
        if (type == .number || type == .integer), let numericValue = value as? Double {
            if let minimum = minimum, numericValue < minimum {
                errors.append(ValidationError(
                    code: "NUMBER_TOO_SMALL",
                    message: "Number value must be at least \(minimum)",
                    field: "value",
                    value: numericValue
                ))
            }

            if let maximum = maximum, numericValue > maximum {
                errors.append(ValidationError(
                    code: "NUMBER_TOO_LARGE",
                    message: "Number value cannot exceed \(maximum)",
                    field: "value",
                    value: numericValue
                ))
            }
        }

        return ValidationResult(errors: errors)
    }

    /// Export parameter for MCP format
    func export() -> [String: Any] {
        var result: [String: Any] = [
            "name": name,
            "type": type.rawValue,
            "description": description,
            "required": required
        ]

        if let defaultValue = defaultValue {
            result["defaultValue"] = defaultValue.value
        }

        if let allowedValues = allowedValues {
            result["allowedValues"] = allowedValues
        }

        if let minLength = minLength {
            result["minLength"] = minLength
        }

        if let maxLength = maxLength {
            result["maxLength"] = maxLength
        }

        if let minimum = minimum {
            result["minimum"] = minimum
        }

        if let maximum = maximum {
            result["maximum"] = maximum
        }

        return result
    }
}

/// Shortcut output definition
struct ShortcutOutput: Codable, Identifiable {
    let id: UUID
    let name: String
    let type: ParameterType
    let description: String
    let optional: Bool

    init(
        id: UUID = UUID(),
        name: String,
        type: ParameterType,
        description: String,
        optional: Bool = false
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.description = description
        self.optional = optional
    }

    /// Validate output definition
    func validate() -> ValidationResult {
        var errors: [ValidationError] = []

        // Validate name
        if name.isEmpty {
            errors.append(ValidationError(
                code: "INVALID_OUTPUT_NAME",
                message: "Output name cannot be empty",
                field: "name",
                value: name
            ))
        }

        // Validate description
        if description.isEmpty {
            errors.append(ValidationError(
                code: "INVALID_OUTPUT_DESCRIPTION",
                message: "Output description cannot be empty",
                field: "description",
                value: description
            ))
        }

        return ValidationResult(errors: errors)
    }

    /// Export output for MCP format
    func export() -> [String: Any] {
        return [
            "name": name,
            "type": type.rawValue,
            "description": description,
            "optional": optional
        ]
    }
}

/// Shortcut category enumeration
enum ShortcutCategory: String, Codable, CaseIterable {
    case general = "General"
    case productivity = "Productivity"
    case communication = "Communication"
    case entertainment = "Entertainment"
    case utilities = "Utilities"
    case automation = "Automation"
    case system = "System"
    case development = "Development"
    case multimedia = "Multimedia"
    case accessibility = "Accessibility"

    var displayName: String {
        return rawValue
    }

    var description: String {
        switch self {
        case .general:
            return "General purpose shortcuts"
        case .productivity:
            return "Productivity and workflow shortcuts"
        case .communication:
            return "Communication and messaging shortcuts"
        case .entertainment:
            return "Entertainment and media shortcuts"
        case .utilities:
            return "Utility and helper shortcuts"
        case .automation:
            return "Automation and scripting shortcuts"
        case .system:
            return "System administration shortcuts"
        case .development:
            return "Development and programming shortcuts"
        case .multimedia:
            return "Multimedia and creative shortcuts"
        case .accessibility:
            return "Accessibility and assistive shortcuts"
        }
    }
}

/// Shortcut color enumeration
enum ShortcutColor: String, Codable, CaseIterable {
    case none = "None"
    case red = "Red"
    case orange = "Orange"
    case yellow = "Yellow"
    case green = "Green"
    case blue = "Blue"
    case purple = "Purple"
    case pink = "Pink"
    case indigo = "Indigo"
    case teal = "Teal"
    case brown = "Brown"
    case gray = "Gray"

    var displayName: String {
        return rawValue
    }
}

/// Parameter type enumeration
enum ParameterType: String, Codable, CaseIterable {
    case string = "String"
    case number = "Number"
    case integer = "Integer"
    case boolean = "Boolean"
    case array = "Array"
    case object = "Object"
    case date = "Date"
    case url = "URL"
    case email = "Email"
    case phoneNumber = "PhoneNumber"

    var displayName: String {
        return rawValue
    }

    var description: String {
        switch self {
        case .string:
            return "Text string"
        case .number:
            return "Decimal number"
        case .integer:
            return "Whole number"
        case .boolean:
            return "True or false value"
        case .array:
            return "List of values"
        case .object:
            return "Dictionary/object"
        case .date:
            return "Date and time"
        case .url:
            return "Web address"
        case .email:
            return "Email address"
        case .phoneNumber:
            return "Phone number"
        }
    }
}

/// Shortcut execution result
struct ShortcutExecutionResult {
    let success: Bool
    let outputs: [String: Any]?
    let executionTime: TimeInterval
    let executionId: String
    let error: String?
    let warnings: [String]?

    init(
        success: Bool,
        outputs: [String: Any]? = nil,
        executionTime: TimeInterval,
        executionId: String = UUID().uuidString,
        error: String? = nil,
        warnings: [String]? = nil
    ) {
        self.success = success
        self.outputs = outputs
        self.executionTime = executionTime
        self.executionId = executionId
        self.error = error
        self.warnings = warnings
    }
}