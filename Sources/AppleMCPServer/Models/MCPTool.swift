//
//  MCPTool.swift
//  AppleMCPServer
//
//  Created on 2025-10-07.
//

import Foundation

/// Data model for MCP Tool components
/// Aligns with the data-model.md specification
struct MCPToolDataModel: Codable, Identifiable {
    let id: UUID
    let name: String
    let description: String
    let category: ToolCategory
    let inputSchema: ToolInputSchema
    let requiresPermission: [PermissionType]
    let offlineCapable: Bool
    let isActive: Bool
    let version: String
    let registeredAt: Date
    let lastUsed: Date?

    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        category: ToolCategory = .general,
        inputSchema: ToolInputSchema,
        requiresPermission: [PermissionType] = [],
        offlineCapable: Bool = true,
        isActive: Bool = true,
        version: String = "1.0.0",
        registeredAt: Date = Date(),
        lastUsed: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.inputSchema = inputSchema
        self.requiresPermission = requiresPermission
        self.offlineCapable = offlineCapable
        self.isActive = isActive
        self.version = version
        self.registeredAt = registeredAt
        self.lastUsed = lastUsed
    }

    /// Update tool usage timestamp
    func with(lastUsed: Date) -> MCPToolDataModel {
        return MCPToolDataModel(
            id: id,
            name: name,
            description: description,
            category: category,
            inputSchema: inputSchema,
            requiresPermission: requiresPermission,
            offlineCapable: offlineCapable,
            isActive: isActive,
            version: version,
            registeredAt: registeredAt,
            lastUsed: lastUsed
        )
    }

    /// Update tool active status
    func with(isActive: Bool) -> MCPToolDataModel {
        return MCPToolDataModel(
            id: id,
            name: name,
            description: description,
            category: category,
            inputSchema: inputSchema,
            requiresPermission: requiresPermission,
            offlineCapable: offlineCapable,
            isActive: isActive,
            version: version,
            registeredAt: registeredAt,
            lastUsed: lastUsed
        )
    }

    /// Validate tool model
    func validate() -> ValidationResult {
        var errors: [ValidationError] = []

        // Validate name
        if name.isEmpty {
            errors.append(ValidationError(
                code: "INVALID_TOOL_NAME",
                message: "Tool name cannot be empty",
                field: "name",
                value: name
            ))
        }

        if name.count > MCPConstants.Limits.maxToolNameLength {
            errors.append(ValidationError(
                code: "TOOL_NAME_TOO_LONG",
                message: "Tool name cannot exceed \(MCPConstants.Limits.maxToolNameLength) characters",
                field: "name",
                value: name
            ))
        }

        // Validate description
        if description.isEmpty {
            errors.append(ValidationError(
                code: "INVALID_TOOL_DESCRIPTION",
                message: "Tool description cannot be empty",
                field: "description",
                value: description
            ))
        }

        if description.count > MCPConstants.Limits.maxToolDescriptionLength {
            errors.append(ValidationError(
                code: "TOOL_DESCRIPTION_TOO_LONG",
                message: "Tool description cannot exceed \(MCPConstants.Limits.maxToolDescriptionLength) characters",
                field: "description",
                value: description
            ))
        }

        // Validate version format
        let versionPattern = "^\\d+\\.\\d+\\.\\d+$"
        if version.range(of: versionPattern, options: .regularExpression) == nil {
            errors.append(ValidationError(
                code: "INVALID_VERSION_FORMAT",
                message: "Version must follow semantic versioning (x.y.z)",
                field: "version",
                value: version
            ))
        }

        // Validate input schema
        let schemaValidation = inputSchema.validate()
        errors.append(contentsOf: schemaValidation.errors)

        return ValidationResult(errors: errors)
    }

    /// Check if tool requires specific permission
    func requiresPermission(_ permission: PermissionType) -> Bool {
        return requiresPermission.contains(permission)
    }

    /// Check if tool can be used offline
    func canUseOffline() -> Bool {
        return offlineCapable && isActive
    }

    /// Export tool as MCP-compatible format
    func exportForMCP() -> [String: Any] {
        return [
            "name": name,
            "description": description,
            "inputSchema": inputSchema.export(),
            "category": category.rawValue,
            "offlineCapable": offlineCapable,
            "version": version,
            "permissions": requiresPermission.map { $0.rawValue }
        ]
    }
}

/// Tool category enumeration
enum ToolCategory: String, Codable, CaseIterable {
    case general = "general"
    case shortcuts = "shortcuts"
    case voiceControl = "voiceControl"
    case systemInfo = "systemInfo"
    case permission = "permission"
    case security = "security"
    case utility = "utility"

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
        }
    }
}

/// Tool input schema structure
struct ToolInputSchema: Codable {
    let type: String
    let properties: [String: ToolProperty]
    let required: [String]
    let additionalProperties: Bool?

    init(
        type: String = "object",
        properties: [String: ToolProperty] = [:],
        required: [String] = [],
        additionalProperties: Bool? = false
    ) {
        self.type = type
        self.properties = properties
        self.required = required
        self.additionalProperties = additionalProperties
    }

    /// Validate input schema
    func validate() -> ValidationResult {
        var errors: [ValidationError] = []

        // Check required properties exist in properties
        for requiredProperty in required {
            if !properties.keys.contains(requiredProperty) {
                errors.append(ValidationError(
                    code: "MISSING_REQUIRED_PROPERTY",
                    message: "Required property '\(requiredProperty)' not found in properties",
                    field: "required",
                    value: requiredProperty
                ))
            }
        }

        // Validate each property
        for (name, property) in properties {
            let propertyValidation = property.validate()
            errors.append(contentsOf: propertyValidation.errors.map { error in
                ValidationError(
                    code: error.code,
                    message: "Property '\(name)': \(error.message)",
                    field: "properties.\(name)",
                    value: error.value
                )
            })
        }

        return ValidationResult(errors: errors)
    }

    /// Export schema for MCP format
    func export() -> [String: Any] {
        var result: [String: Any] = [
            "type": type,
            "properties": properties.mapValues { $0.export() }
        ]

        if !required.isEmpty {
            result["required"] = required
        }

        if let additionalProperties = additionalProperties {
            result["additionalProperties"] = additionalProperties
        }

        return result
    }
}

/// Tool property definition
struct ToolProperty: Codable {
    let type: String
    let description: String?
    let defaultValue: AnyCodable?
    let enumeration: [String]?
    let minimum: Double?
    let maximum: Double?
    let minLength: Int?
    let maxLength: Int?
    let pattern: String?

    init(
        type: String,
        description: String? = nil,
        defaultValue: AnyCodable? = nil,
        enumeration: [String]? = nil,
        minimum: Double? = nil,
        maximum: Double? = nil,
        minLength: Int? = nil,
        maxLength: Int? = nil,
        pattern: String? = nil
    ) {
        self.type = type
        self.description = description
        self.defaultValue = defaultValue
        self.enumeration = enumeration
        self.minimum = minimum
        self.maximum = maximum
        self.minLength = minLength
        self.maxLength = maxLength
        self.pattern = pattern
    }

    /// Validate property definition
    func validate() -> ValidationResult {
        var errors: [ValidationError] = []

        // Validate type
        let validTypes = ["string", "number", "integer", "boolean", "array", "object"]
        if !validTypes.contains(type) {
            errors.append(ValidationError(
                code: "INVALID_PROPERTY_TYPE",
                message: "Property type must be one of: \(validTypes.joined(separator: ", "))",
                field: "type",
                value: type
            ))
        }

        // Validate numeric constraints
        if let minimum = minimum, let maximum = maximum, minimum > maximum {
            errors.append(ValidationError(
                code: "INVALID_NUMERIC_RANGE",
                message: "Minimum value cannot be greater than maximum value",
                field: "minimum",
                value: minimum
            ))
        }

        // Validate string length constraints
        if let minLength = minLength, let maxLength = maxLength, minLength > maxLength {
            errors.append(ValidationError(
                code: "INVALID_STRING_LENGTH_RANGE",
                message: "Minimum length cannot be greater than maximum length",
                field: "minLength",
                value: minLength
            ))
        }

        return ValidationResult(errors: errors)
    }

    /// Export property for MCP format
    func export() -> [String: Any] {
        var result: [String: Any] = ["type": type]

        if let description = description {
            result["description"] = description
        }

        if let defaultValue = defaultValue {
            result["default"] = defaultValue.value
        }

        if let enumeration = enumeration {
            result["enum"] = enumeration
        }

        if let minimum = minimum {
            result["minimum"] = minimum
        }

        if let maximum = maximum {
            result["maximum"] = maximum
        }

        if let minLength = minLength {
            result["minLength"] = minLength
        }

        if let maxLength = maxLength {
            result["maxLength"] = maxLength
        }

        if let pattern = pattern {
            result["pattern"] = pattern
        }

        return result
    }
}

/// Tool execution statistics
struct ToolExecutionStats {
    let totalExecutions: Int
    let successfulExecutions: Int
    let failedExecutions: Int
    let averageExecutionTime: TimeInterval
    let lastExecutionTime: Date?
    let mostUsedBy: [UUID: Int] // Client ID -> Usage count

    init(
        totalExecutions: Int = 0,
        successfulExecutions: Int = 0,
        failedExecutions: Int = 0,
        averageExecutionTime: TimeInterval = 0.0,
        lastExecutionTime: Date? = nil,
        mostUsedBy: [UUID: Int] = [:]
    ) {
        self.totalExecutions = totalExecutions
        self.successfulExecutions = successfulExecutions
        self.failedExecutions = failedExecutions
        self.averageExecutionTime = averageExecutionTime
        self.lastExecutionTime = lastExecutionTime
        self.mostUsedBy = mostUsedBy
    }

    /// Calculate success rate
    var successRate: Double {
        guard totalExecutions > 0 else { return 0.0 }
        return Double(successfulExecutions) / Double(totalExecutions)
    }

    /// Update statistics with new execution
    func with(execution: ToolExecution) -> ToolExecutionStats {
        let newTotal = totalExecutions + 1
        let newSuccessful = successfulExecutions + (execution.success ? 1 : 0)
        let newFailed = failedExecutions + (execution.success ? 0 : 1)

        // Calculate new average execution time
        let newAverageExecutionTime = (averageExecutionTime * Double(totalExecutions) + execution.executionTime) / Double(newTotal)

        // Update most used by
        var newMostUsedBy = mostUsedBy
        let clientId = execution.clientId
        newMostUsedBy[clientId, default: 0] += 1

        return ToolExecutionStats(
            totalExecutions: newTotal,
            successfulExecutions: newSuccessful,
            failedExecutions: newFailed,
            averageExecutionTime: newAverageExecutionTime,
            lastExecutionTime: execution.timestamp,
            mostUsedBy: newMostUsedBy
        )
    }
}

/// Tool execution record
struct ToolExecution {
    let id: UUID
    let toolName: String
    let clientId: UUID
    let success: Bool
    let executionTime: TimeInterval
    let timestamp: Date
    let parameters: [String: Any]?
    let error: String?

    init(
        id: UUID = UUID(),
        toolName: String,
        clientId: UUID,
        success: Bool,
        executionTime: TimeInterval,
        timestamp: Date = Date(),
        parameters: [String: Any]? = nil,
        error: String? = nil
    ) {
        self.id = id
        self.toolName = toolName
        self.clientId = clientId
        self.success = success
        self.executionTime = executionTime
        self.timestamp = timestamp
        self.parameters = parameters
        self.error = error
    }
}