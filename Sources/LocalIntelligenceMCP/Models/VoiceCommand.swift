//
//  VoiceCommand.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-07.
//

import Foundation

/// Data model for Voice Control commands
/// Aligns with the data-model.md specification
struct VoiceCommandDataModel: Codable, Identifiable {
    let id: UUID
    let command: String
    let description: String
    let category: VoiceCommandCategory
    let parameters: [VoiceCommandParameter]
    let requiresPermission: PermissionType
    let confidenceThreshold: Float
    let languageCode: String
    let isActive: Bool
    let isSystemCommand: Bool
    let estimatedDuration: TimeInterval?
    let lastUsed: Date?
    let useCount: Int
    let createdDate: Date
    let modifiedDate: Date

    init(
        id: UUID = UUID(),
        command: String,
        description: String,
        category: VoiceCommandCategory = .general,
        parameters: [VoiceCommandParameter] = [],
        requiresPermission: PermissionType = .accessibility,
        confidenceThreshold: Float = 0.7,
        languageCode: String = "en-US",
        isActive: Bool = true,
        isSystemCommand: Bool = false,
        estimatedDuration: TimeInterval? = nil,
        lastUsed: Date? = nil,
        useCount: Int = 0,
        createdDate: Date = Date(),
        modifiedDate: Date = Date()
    ) {
        self.id = id
        self.command = command
        self.description = description
        self.category = category
        self.parameters = parameters
        self.requiresPermission = requiresPermission
        self.confidenceThreshold = confidenceThreshold
        self.languageCode = languageCode
        self.isActive = isActive
        self.isSystemCommand = isSystemCommand
        self.estimatedDuration = estimatedDuration
        self.lastUsed = lastUsed
        self.useCount = useCount
        self.createdDate = createdDate
        self.modifiedDate = modifiedDate
    }

    /// Update usage information
    func with(usedAt: Date) -> VoiceCommandDataModel {
        return VoiceCommandDataModel(
            id: id,
            command: command,
            description: description,
            category: category,
            parameters: parameters,
            requiresPermission: requiresPermission,
            confidenceThreshold: confidenceThreshold,
            languageCode: languageCode,
            isActive: isActive,
            isSystemCommand: isSystemCommand,
            estimatedDuration: estimatedDuration,
            lastUsed: usedAt,
            useCount: useCount + 1,
            createdDate: createdDate,
            modifiedDate: modifiedDate
        )
    }

    /// Update active status
    func with(isActive: Bool) -> VoiceCommandDataModel {
        return VoiceCommandDataModel(
            id: id,
            command: command,
            description: description,
            category: category,
            parameters: parameters,
            requiresPermission: requiresPermission,
            confidenceThreshold: confidenceThreshold,
            languageCode: languageCode,
            isActive: isActive,
            isSystemCommand: isSystemCommand,
            estimatedDuration: estimatedDuration,
            lastUsed: lastUsed,
            useCount: useCount,
            createdDate: createdDate,
            modifiedDate: Date()
        )
    }

    /// Update confidence threshold
    func with(confidenceThreshold: Float) -> VoiceCommandDataModel {
        return VoiceCommandDataModel(
            id: id,
            command: command,
            description: description,
            category: category,
            parameters: parameters,
            requiresPermission: requiresPermission,
            confidenceThreshold: confidenceThreshold,
            languageCode: languageCode,
            isActive: isActive,
            isSystemCommand: isSystemCommand,
            estimatedDuration: estimatedDuration,
            lastUsed: lastUsed,
            useCount: useCount,
            createdDate: createdDate,
            modifiedDate: Date()
        )
    }

    /// Validate voice command model
    func validate() -> ValidationResult {
        var errors: [ValidationError] = []

        // Validate command
        if command.isEmpty {
            errors.append(ValidationError(
                code: "INVALID_VOICE_COMMAND",
                message: "Voice command cannot be empty",
                field: "command",
                value: command
            ))
        }

        if command.count > MCPConstants.Limits.maxVoiceCommandLength {
            errors.append(ValidationError(
                code: "VOICE_COMMAND_TOO_LONG",
                message: "Voice command cannot exceed \(MCPConstants.Limits.maxVoiceCommandLength) characters",
                field: "command",
                value: command
            ))
        }

        // Validate description
        if description.isEmpty {
            errors.append(ValidationError(
                code: "INVALID_COMMAND_DESCRIPTION",
                message: "Command description cannot be empty",
                field: "description",
                value: description
            ))
        }

        // Validate confidence threshold
        if confidenceThreshold < 0.0 || confidenceThreshold > 1.0 {
            errors.append(ValidationError(
                code: "INVALID_CONFIDENCE_THRESHOLD",
                message: "Confidence threshold must be between 0.0 and 1.0",
                field: "confidenceThreshold",
                value: confidenceThreshold
            ))
        }

        // Validate language code format
        let languageCodePattern = "^[a-z]{2}-[A-Z]{2}$"
        if languageCode.range(of: languageCodePattern, options: .regularExpression) == nil {
            errors.append(ValidationError(
                code: "INVALID_LANGUAGE_CODE",
                message: "Language code must follow format 'xx-XX' (e.g., 'en-US')",
                field: "languageCode",
                value: languageCode
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

        // Validate use count
        if useCount < 0 {
            errors.append(ValidationError(
                code: "INVALID_USE_COUNT",
                message: "Use count cannot be negative",
                field: "useCount",
                value: useCount
            ))
        }

        return ValidationResult(errors: errors)
    }

    /// Check if command can be executed
    func canExecute() -> Bool {
        return isActive
    }

    /// Get parameter by name
    func getParameter(name: String) -> VoiceCommandParameter? {
        return parameters.first { $0.name.lowercased() == name.lowercased() }
    }

    /// Export voice command for MCP format
    func exportForMCP() -> [String: Any] {
        return [
            "id": id.uuidString,
            "command": command,
            "description": description,
            "category": category.rawValue,
            "parameters": parameters.map { $0.export() },
            "requiresPermission": requiresPermission.rawValue,
            "confidenceThreshold": confidenceThreshold,
            "languageCode": languageCode,
            "isActive": isActive,
            "isSystemCommand": isSystemCommand,
            "useCount": useCount
        ]
    }
}

/// Voice command parameter definition
struct VoiceCommandParameter: Codable, Identifiable {
    let id: UUID
    let name: String
    let type: ParameterType
    let description: String
    let required: Bool
    let defaultValue: AnyCodable?
    let allowedValues: [String]?

    init(
        id: UUID = UUID(),
        name: String,
        type: ParameterType,
        description: String,
        required: Bool = false,
        defaultValue: AnyCodable? = nil,
        allowedValues: [String]? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.description = description
        self.required = required
        self.defaultValue = defaultValue
        self.allowedValues = allowedValues
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

        return result
    }
}

/// Voice command category enumeration
enum VoiceCommandCategory: String, Codable, CaseIterable {
    case general = "general"
    case navigation = "navigation"
    case system = "system"
    case accessibility = "accessibility"
    case application = "application"
    case media = "media"
    case text = "text"
    case device = "device"

    var displayName: String {
        switch self {
        case .general:
            return "General"
        case .navigation:
            return "Navigation"
        case .system:
            return "System"
        case .accessibility:
            return "Accessibility"
        case .application:
            return "Application"
        case .media:
            return "Media"
        case .text:
            return "Text"
        case .device:
            return "Device"
        }
    }

    var description: String {
        switch self {
        case .general:
            return "General voice commands"
        case .navigation:
            return "Navigation and interface commands"
        case .system:
            return "System-level commands"
        case .accessibility:
            return "Accessibility and assistive commands"
        case .application:
            return "Application-specific commands"
        case .media:
            return "Media playback and control"
        case .text:
            return "Text editing and dictation"
        case .device:
            return "Device control commands"
        }
    }
}

/// Voice command execution result
struct VoiceCommandExecutionResult {
    let success: Bool
    let recognizedCommand: String?
    let confidence: Float
    let executionTime: TimeInterval
    let executionId: String
    let outputs: [String: Any]?
    let error: String?
    let warnings: [String]?

    init(
        success: Bool,
        recognizedCommand: String? = nil,
        confidence: Float = 0.0,
        executionTime: TimeInterval,
        executionId: String = UUID().uuidString,
        outputs: [String: Any]? = nil,
        error: String? = nil,
        warnings: [String]? = nil
    ) {
        self.success = success
        self.recognizedCommand = recognizedCommand
        self.confidence = confidence
        self.executionTime = executionTime
        self.executionId = executionId
        self.outputs = outputs
        self.error = error
        self.warnings = warnings
    }

    /// Check if confidence meets threshold
    func meetsConfidenceThreshold(_ threshold: Float) -> Bool {
        return confidence >= threshold
    }
}

/// Voice recognition session
struct VoiceRecognitionSession {
    let id: UUID
    let startTime: Date
    let endTime: Date?
    let duration: TimeInterval?
    let languageCode: String
    let recognizedText: String?
    let confidence: Float?
    let commandsDetected: [String]
    let success: Bool
    let error: String?

    init(
        id: UUID = UUID(),
        startTime: Date = Date(),
        endTime: Date? = nil,
        duration: TimeInterval? = nil,
        languageCode: String = "en-US",
        recognizedText: String? = nil,
        confidence: Float? = nil,
        commandsDetected: [String] = [],
        success: Bool = false,
        error: String? = nil
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration ?? endTime.map { $0.timeIntervalSince(startTime) }
        self.languageCode = languageCode
        self.recognizedText = recognizedText
        self.confidence = confidence
        self.commandsDetected = commandsDetected
        self.success = success
        self.error = error
    }

    /// Complete the session
    func completed(recognizedText: String?, confidence: Float?, commandsDetected: [String], success: Bool, error: String? = nil) -> VoiceRecognitionSession {
        let endTime = Date()
        return VoiceRecognitionSession(
            id: id,
            startTime: startTime,
            endTime: endTime,
            duration: endTime.timeIntervalSince(startTime),
            languageCode: languageCode,
            recognizedText: recognizedText,
            confidence: confidence,
            commandsDetected: commandsDetected,
            success: success,
            error: error
        )
    }
}

/// Voice command statistics
struct VoiceCommandStats {
    let totalCommands: Int
    let successfulCommands: Int
    let failedCommands: Int
    let averageConfidence: Float
    let averageExecutionTime: TimeInterval
    let mostUsedCommands: [String: Int]
    let languageDistribution: [String: Int]
    let lastCommandTime: Date?

    init(
        totalCommands: Int = 0,
        successfulCommands: Int = 0,
        failedCommands: Int = 0,
        averageConfidence: Float = 0.0,
        averageExecutionTime: TimeInterval = 0.0,
        mostUsedCommands: [String: Int] = [:],
        languageDistribution: [String: Int] = [:],
        lastCommandTime: Date? = nil
    ) {
        self.totalCommands = totalCommands
        self.successfulCommands = successfulCommands
        self.failedCommands = failedCommands
        self.averageConfidence = averageConfidence
        self.averageExecutionTime = averageExecutionTime
        self.mostUsedCommands = mostUsedCommands
        self.languageDistribution = languageDistribution
        self.lastCommandTime = lastCommandTime
    }

    /// Calculate success rate
    var successRate: Double {
        guard totalCommands > 0 else { return 0.0 }
        return Double(successfulCommands) / Double(totalCommands)
    }

    /// Update statistics with new command execution
    func with(execution: VoiceCommandExecutionResult, originalCommand: String, languageCode: String) -> VoiceCommandStats {
        let newTotal = totalCommands + 1
        let newSuccessful = successfulCommands + (execution.success ? 1 : 0)
        let newFailed = failedCommands + (execution.success ? 0 : 1)

        // Calculate new average confidence
        let newAverageConfidence: Float = {
            guard totalCommands > 0 else { return execution.confidence }
            return (averageConfidence * Float(totalCommands) + execution.confidence) / Float(newTotal)
        }()

        // Calculate new average execution time
        let newAverageExecutionTime = (averageExecutionTime * Double(totalCommands) + execution.executionTime) / Double(newTotal)

        // Update most used commands
        var newMostUsedCommands = mostUsedCommands
        newMostUsedCommands[originalCommand, default: 0] += 1

        // Update language distribution
        var newLanguageDistribution = languageDistribution
        newLanguageDistribution[languageCode, default: 0] += 1

        return VoiceCommandStats(
            totalCommands: newTotal,
            successfulCommands: newSuccessful,
            failedCommands: newFailed,
            averageConfidence: newAverageConfidence,
            averageExecutionTime: newAverageExecutionTime,
            mostUsedCommands: newMostUsedCommands,
            languageDistribution: newLanguageDistribution,
            lastCommandTime: Date()
        )
    }
}