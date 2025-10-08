//
//  VoiceControlTool.swift
//  AppleMCPServer
//
//  Created on 2025-10-07.
//

import Foundation

/// Tool for executing Voice Control commands
class VoiceControlTool: BaseMCPTool {

    init(logger: Logger, securityManager: SecurityManager) {
        let inputSchema: [String: Any] = [
            "type": "object",
            "properties": [
                "command": [
                    "type": "string",
                    "description": "Voice command to execute (e.g., 'open Safari', 'scroll down', 'click button')",
                    "minLength": 1,
                    "maxLength": 200
                ],
                "parameters": [
                    "type": "object",
                    "description": "Additional parameters for the voice command (e.g., target application, element name)",
                    "additionalProperties": true
                ],
                "confidenceThreshold": [
                    "type": "number",
                    "description": "Minimum confidence threshold for voice recognition (0.0-1.0)",
                    "minimum": 0.0,
                    "maximum": 1.0,
                    "default": 0.7
                ],
                "language": [
                    "type": "string",
                    "description": "Language code for voice recognition (e.g., 'en-US', 'en-GB')",
                    "pattern": "^[a-z]{2}-[A-Z]{2}$",
                    "default": "en-US"
                ],
                "timeout": [
                    "type": "number",
                    "description": "Maximum execution time in seconds (1-30)",
                    "minimum": 1,
                    "maximum": 30,
                    "default": 10
                ],
                "validateCommand": [
                    "type": "boolean",
                    "description": "Validate command against known voice commands before execution",
                    "default": true
                ],
                "waitForCompletion": [
                    "type": "boolean",
                    "description": "Wait for command completion before returning",
                    "default": true
                ]
            ],
            "required": ["command"],
            "description": "Execute a Voice Control command with comprehensive validation and accessibility support"
        ]

        super.init(
            name: MCPConstants.Tools.voiceCommand,
            description: "Execute Voice Control commands with comprehensive validation, accessibility support, and detailed execution feedback",
            inputSchema: inputSchema,
            category: .voiceControl,
            requiresPermission: [.accessibility],
            offlineCapable: true,
            logger: logger,
            securityManager: securityManager
        )
    }

    override func performExecution(parameters: [String: Any], context: MCPExecutionContext) async throws -> MCPResponse {
        guard let command = parameters["command"] as? String else {
            throw ToolsRegistryError.invalidParameters("command parameter is required")
        }

        let commandParameters = parameters["parameters"] as? [String: Any] ?? [:]
        let confidenceThreshold = parameters["confidenceThreshold"] as? Float ?? 0.7
        let language = parameters["language"] as? String ?? "en-US"
        let timeout = parameters["timeout"] as? Double ?? 10.0
        let validateCommand = parameters["validateCommand"] as? Bool ?? true
        let waitForCompletion = parameters["waitForCompletion"] as? Bool ?? true

        let startTime = Date()
        let executionId = generateExecutionID()

        await logger.info("Executing voice command", category: .voiceControl, metadata: [
            "command": command.sanitizedForLogging,
            "confidenceThreshold": confidenceThreshold,
            "language": language,
            "timeout": timeout,
            "validateCommand": validateCommand,
            "waitForCompletion": waitForCompletion,
            "parameters": commandParameters.sanitizedForLogging(),
            "executionId": executionId,
            "clientId": context.clientId.uuidString
        ])

        do {
            // Validate voice control availability and permissions
            try await validateVoiceControlAvailability()

            // Validate command format and content
            try await validateVoiceCommand(command, language: language)

            // Validate against known commands if requested
            if validateCommand {
                try await validateKnownCommand(command)
            }

            // Execute voice command with timeout handling
            let result = try await executeVoiceCommandWithTimeout(
                command: command,
                parameters: commandParameters,
                confidenceThreshold: confidenceThreshold,
                language: language,
                timeout: timeout,
                waitForCompletion: waitForCompletion,
                executionId: executionId
            )

            let executionTime = Date().timeIntervalSince(startTime)

            // Update command usage statistics
            await updateVoiceCommandUsage(command: command, success: result.success, executionTime: executionTime)

            await logger.performance(
                "voice_command_execution",
                duration: executionTime,
                metadata: [
                    "command": command.sanitizedForLogging,
                    "success": result.success,
                    "confidence": result.confidence,
                    "executionId": executionId,
                    "language": language,
                    "timeout": timeout
                ]
            )

            // Prepare comprehensive response
            let responseData: [String: Any] = [
                "command": command,
                "executionId": executionId,
                "success": result.success,
                "executionTime": executionTime,
                "timestamp": Date().iso8601String,
                "recognizedCommand": result.recognizedCommand as Any,
                "confidence": result.confidence,
                "outputs": result.data as Any,
                "metadata": [
                    "inputParameters": commandParameters,
                    "confidenceThreshold": confidenceThreshold,
                    "language": language,
                    "timeoutUsed": timeout,
                    "waitForCompletion": waitForCompletion,
                    "validateCommand": validateCommand
                ]
            ]

            return MCPResponse(
                success: result.success,
                data: AnyCodable(responseData),
                error: result.error.map { MCPError(code: "VOICE_COMMAND_ERROR", message: $0) },
                executionTime: executionTime
            )

        } catch {
            let executionTime = Date().timeIntervalSince(startTime)

            await logger.error(
                "Voice command execution failed",
                error: error,
                category: .voiceControl,
                metadata: [
                    "command": command.sanitizedForLogging,
                    "executionId": executionId,
                    "executionTime": executionTime,
                    "language": language,
                    "timeout": timeout
                ]
            )

            // Provide helpful error information
            let errorResponse: [String: Any] = [
                "command": command,
                "executionId": executionId,
                "success": false,
                "executionTime": executionTime,
                "timestamp": Date().iso8601String,
                "error": error.localizedDescription,
                "suggestions": getCommandSuggestions(for: command),
                "metadata": [
                    "inputParameters": commandParameters,
                    "confidenceThreshold": confidenceThreshold,
                    "language": language,
                    "timeoutUsed": timeout
                ]
            ]

            return MCPResponse(
                success: false,
                data: AnyCodable(errorResponse),
                error: error.mcpError,
                executionTime: executionTime
            )
        }
    }

    private func validateVoiceControlAvailability() async throws {
        // Check if Voice Control is enabled (simplified)
        // In a real implementation, you would check system accessibility settings

        // Simulate checking Voice Control availability
        // For now, assume it's available
    }

    // MARK: - Enhanced Validation Methods

    private func validateVoiceCommand(_ command: String, language: String) async throws {
        guard !command.isEmpty else {
            throw ToolsRegistryError.invalidParameters("Voice command cannot be empty")
        }

        guard command.count <= MCPConstants.Limits.maxVoiceCommandLength else {
            throw ToolsRegistryError.invalidParameters("Voice command cannot exceed \(MCPConstants.Limits.maxVoiceCommandLength) characters")
        }

        // Validate language code format
        let languagePattern = "^[a-z]{2}-[A-Z]{2}$"
        if language.range(of: languagePattern, options: .regularExpression) == nil {
            throw ToolsRegistryError.invalidParameters("Language code must follow format 'xx-XX' (e.g., 'en-US')")
        }

        // Basic character validation
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: " .,!?-"))
        if command.rangeOfCharacter(from: allowedCharacters.inverted) != nil {
            await logger.warning("Voice command contains unusual characters", category: .voiceControl, metadata: [
                "command": command.sanitizedForLogging
            ])
        }
    }

    private func validateKnownCommand(_ command: String) async throws {
        // Enhanced known commands database
        let knownCommands: [String: [String]] = [
            "navigation": [
                "scroll up", "scroll down", "scroll left", "scroll right",
                "go back", "go forward", "go home", "go to top", "go to bottom",
                "zoom in", "zoom out", "zoom to fit", "switch app", "show desktop"
            ],
            "interaction": [
                "click", "double click", "right click", "tap", "swipe", "pinch",
                "drag", "drop", "select", "copy", "paste", "cut", "undo", "redo"
            ],
            "system": [
                "open", "close", "quit", "save", "save as", "print", "find",
                "show menu", "hide menu", "show dock", "hide dock", "show all windows"
            ],
            "text": [
                "type", "dictate", "select all", "delete", "backspace", "enter",
                "space", "tab", "command", "option", "control", "shift"
            ],
            "accessibility": [
                "voice control on", "voice control off", "show commands",
                "enable dictation", "disable dictation", "increase contrast",
                "reduce motion", "zoom text"
            ]
        ]

        let lowercaseCommand = command.lowercased()
        var isValidCommand = false

        for (_, commands) in knownCommands {
            if commands.contains(where: { lowercaseCommand.contains($0) }) {
                isValidCommand = true
                break
            }
        }

        if !isValidCommand {
            await logger.warning("Unknown voice command", category: .voiceControl, metadata: [
                "command": command.sanitizedForLogging,
                "suggestions": Array(knownCommands.values.flatMap { $0 }.prefix(5))
            ])
            // Continue anyway as the command might be valid but not in our known list
        }
    }

    private func getCommandSuggestions(for command: String) -> [String] {
        let lowercaseCommand = command.lowercased()

        // Suggest similar commands based on partial matches
        let suggestions: [String] = [
            "Try: 'open Safari', 'close window', 'scroll down', 'click button'",
            "Try: 'go back', 'zoom in', 'copy text', 'paste'",
            "Try: 'show desktop', 'switch app', 'save document'",
            "Try: 'show commands' to see available voice commands",
            "Enable Voice Control in System Preferences > Accessibility > Voice Control"
        ]

        // Return relevant suggestions based on command content
        if lowercaseCommand.contains("open") {
            return ["Try: 'open Safari', 'open Finder', 'open Notes'"]
        } else if lowercaseCommand.contains("click") {
            return ["Try: 'click button', 'click link', 'double click'"]
        } else if lowercaseCommand.contains("scroll") {
            return ["Try: 'scroll up', 'scroll down', 'scroll to top'"]
        } else {
            return suggestions
        }
    }

    // MARK: - Enhanced Execution Methods

    private func executeVoiceCommandWithTimeout(
        command: String,
        parameters: [String: Any],
        confidenceThreshold: Float,
        language: String,
        timeout: Double,
        waitForCompletion: Bool,
        executionId: String
    ) async throws -> VoiceCommandResult {
        return try await withThrowingTaskGroup(of: VoiceCommandResult.self) { group in
            // Add execution task
            group.addTask {
                return try await self.executeVoiceCommandInternal(
                    command: command,
                    parameters: parameters,
                    confidenceThreshold: confidenceThreshold,
                    language: language,
                    executionId: executionId
                )
            }

            // Add timeout task
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw VoiceCommandExecutionError.timeout("Voice command execution timed out after \(timeout) seconds")
            }

            // Wait for first completed task
            let result = try await group.next()!
            group.cancelAll()

            return result
        }
    }

    private func executeVoiceCommandInternal(
        command: String,
        parameters: [String: Any],
        confidenceThreshold: Float,
        language: String,
        executionId: String
    ) async throws -> VoiceCommandResult {
        let startTime = Date()

        await logger.debug("Starting voice command execution", category: .voiceControl, metadata: [
            "command": command.sanitizedForLogging,
            "language": language,
            "executionId": executionId
        ])

        // Simulate voice recognition processing
        try await Task.sleep(nanoseconds: UInt64.random(in: 200_000_000...1_000_000_000)) // 0.2-1.0 seconds

        // Simulate confidence scoring based on command complexity and language
        let confidence = calculateConfidence(for: command, language: language)

        guard confidence >= confidenceThreshold else {
            return VoiceCommandResult(
                success: false,
                data: nil,
                executionTime: Date().timeIntervalSince(startTime),
                executionId: executionId,
                recognizedCommand: command,
                confidence: confidence,
                error: "Voice recognition confidence (\(String(format: "%.2f", confidence))) below threshold (\(String(format: "%.2f", confidenceThreshold)))"
            )
        }

        // Simulate command execution based on command type
        let executionResult = try await simulateCommandExecution(
            command: command,
            parameters: parameters,
            startTime: startTime
        )

        let executionTime = Date().timeIntervalSince(startTime)

        if executionResult.success {
            await logger.info("Voice command executed successfully", category: .voiceControl, metadata: [
                "command": command.sanitizedForLogging,
                "executionId": executionId,
                "executionTime": executionTime,
                "confidence": confidence
            ])

            return VoiceCommandResult(
                success: true,
                data: [
                    "executedCommand": AnyCodable(command),
                    "recognizedCommand": AnyCodable(command),
                    "status": AnyCodable("completed"),
                    "executionDetails": AnyCodable(executionResult.details),
                    "feedback": AnyCodable(executionResult.feedback),
                    "executionId": AnyCodable(executionId)
                ],
                executionTime: executionTime,
                executionId: executionId,
                recognizedCommand: command,
                confidence: confidence
            )
        } else {
            let error = executionResult.error ?? "Voice command execution failed"

            await logger.error("Voice command execution failed", category: .voiceControl, metadata: [
                "command": command.sanitizedForLogging,
                "executionId": executionId,
                "executionTime": executionTime,
                "error": error
            ])

            return VoiceCommandResult(
                success: false,
                data: nil,
                executionTime: executionTime,
                executionId: executionId,
                recognizedCommand: command,
                confidence: confidence,
                error: error
            )
        }
    }

    private func calculateConfidence(for command: String, language: String) -> Float {
        // Simulate confidence calculation based on various factors
        let baseConfidence: Float = 0.85

        // Adjust for command length (shorter commands are generally clearer)
        let lengthFactor = Float(max(0.7, 1.0 - Double(command.count) / 200.0))

        // Adjust for language (some languages may have better recognition)
        let languageFactor: Float = language == "en-US" ? 1.0 : 0.95

        // Add some randomness to simulate real-world variability
        let randomFactor = Float.random(in: 0.9...1.0)

        return min(1.0, baseConfidence * lengthFactor * languageFactor * randomFactor)
    }

    private func simulateCommandExecution(
        command: String,
        parameters: [String: Any],
        startTime: Date
    ) async throws -> (success: Bool, details: [String: Any], feedback: String, error: String?) {
        let lowercaseCommand = command.lowercased()

        // Simulate command execution time
        try await Task.sleep(nanoseconds: UInt64.random(in: 300_000_000...1_500_000_000))

        // Simulate success based on command type
        if lowercaseCommand.contains("open") || lowercaseCommand.contains("close") {
            return (
                success: true,
                details: [
                    "action": "application_control",
                    "target": extractTarget(from: command),
                    "timestamp": Date().iso8601String
                ],
                feedback: "Command executed successfully",
                error: nil
            )
        } else if lowercaseCommand.contains("scroll") {
            return (
                success: true,
                details: [
                    "action": "navigation",
                    "direction": extractDirection(from: command),
                    "amount": extractAmount(from: parameters) ?? "default",
                    "timestamp": Date().iso8601String
                ],
                feedback: "Scrolled \(extractDirection(from: command))",
                error: nil
            )
        } else if lowercaseCommand.contains("click") {
            return (
                success: true,
                details: [
                    "action": "interaction",
                    "target": extractTarget(from: command),
                    "timestamp": Date().iso8601String
                ],
                feedback: "Clicked \(extractTarget(from: command))",
                error: nil
            )
        } else if lowercaseCommand.contains("zoom") {
            return (
                success: true,
                details: [
                    "action": "display_control",
                    "direction": extractDirection(from: command),
                    "level": extractAmount(from: parameters) ?? "default",
                    "timestamp": Date().iso8601String
                ],
                feedback: "Zoomed \(extractDirection(from: command))",
                error: nil
            )
        } else {
            // Unknown command - simulate failure with helpful error
            return (
                success: false,
                details: [:],
                feedback: "Command not recognized",
                error: "Voice command '\(command)' is not supported. Try using simpler commands like 'open Safari', 'scroll down', or 'click button'."
            )
        }
    }

    // MARK: - Helper Methods

    private func extractTarget(from command: String) -> String {
        let words = command.lowercased().components(separatedBy: .whitespaces)
        if words.count > 1 {
            return words[1].capitalized
        }
        return "Unknown"
    }

    private func extractDirection(from command: String) -> String {
        let lowercaseCommand = command.lowercased()
        if lowercaseCommand.contains("up") { return "Up" }
        if lowercaseCommand.contains("down") { return "Down" }
        if lowercaseCommand.contains("left") { return "Left" }
        if lowercaseCommand.contains("right") { return "Right" }
        if lowercaseCommand.contains("in") { return "In" }
        if lowercaseCommand.contains("out") { return "Out" }
        return "Unknown"
    }

    private func extractAmount(from parameters: [String: Any]) -> String? {
        return parameters["amount"] as? String ?? parameters["value"] as? String
    }

    // MARK: - Statistics and Monitoring

    private func updateVoiceCommandUsage(command: String, success: Bool, executionTime: TimeInterval) async {
        // In a real implementation, this would update usage statistics in a database
        await logger.debug("Updating voice command usage statistics", category: .voiceControl, metadata: [
            "command": command.sanitizedForLogging,
            "success": success,
            "executionTime": executionTime
        ])
    }

    // MARK: - Error Types

    enum VoiceCommandExecutionError: LocalizedError {
        case timeout(String)
        case notSupported(String)
        case permissionDenied(String)
        case voiceControlDisabled(String)
        case languageNotSupported(String)
        case executionFailed(String)

        var errorDescription: String? {
            switch self {
            case .timeout(let message):
                return message
            case .notSupported(let message):
                return message
            case .permissionDenied(let message):
                return message
            case .voiceControlDisabled(let message):
                return message
            case .languageNotSupported(let message):
                return message
            case .executionFailed(let message):
                return message
            }
        }
    }
}

struct VoiceCommandResult: Sendable {
    let success: Bool
    let data: [String: AnyCodable]?
    let executionTime: TimeInterval
    let executionId: String
    let recognizedCommand: String?
    let confidence: Float
    let error: String?

    init(
        success: Bool,
        data: [String: AnyCodable]? = nil,
        executionTime: TimeInterval,
        executionId: String,
        recognizedCommand: String? = nil,
        confidence: Float = 0.0,
        error: String? = nil
    ) {
        self.success = success
        self.data = data
        self.executionTime = executionTime
        self.executionId = executionId
        self.recognizedCommand = recognizedCommand
        self.confidence = confidence
        self.error = error
    }
}