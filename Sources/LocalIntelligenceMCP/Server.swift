//
//  Server.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-07.
//

import Foundation
import ArgumentParser
import MCP

/// Main entry point for the Local Intelligence MCP
@main
struct LocalIntelligenceMCP: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "local-intelligence-mcp",
        abstract: "Apple Ecosystem MCP Server - Exposes Apple platform capabilities to AI agents",
        discussion: """
        A Swift-based Model Context Protocol server that provides secure access to Apple ecosystem features
        including Shortcuts, Voice Control, System Information, and Accessibility features.

        Built with Security & Privacy First principles using Apple Keychain for secure credential storage
        and comprehensive audit logging for all operations.
        """,
        version: MCPConstants.Server.version,
        subcommands: [StartCommand.self, StatusCommand.self, ConfigCommand.self],
        defaultSubcommand: StartCommand.self
    )
}

/// Start the MCP server
struct StartCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Start the Local Intelligence MCP server",
        discussion: "Starts the MCP server with optional configuration overrides"
    )

    @Option(name: .long, help: "Path to configuration file")
    var configFile: String?

    @Option(name: .long, help: "Log level (trace, debug, info, warning, error)")
    var logLevel: String?

    @Option(name: .long, help: "Server port (for HTTP/WebSocket transport)")
    var port: Int?

    @Flag(name: .long, help: "Enable debug mode")
    var debug: Bool = false

    @Flag(name: .long, help: "Run in foreground")
    var foreground: Bool = false

    @Flag(name: .long, help: "MCP mode - disable console logging for clean JSON-RPC communication")
    var mcpMode: Bool = false

    func run() async throws {
        // Create minimal logger for startup (stdio transport will handle main communication)
        let logLevel = ConfigurationLogLevel(rawValue: self.logLevel ?? "error") ?? .error
        let logConfig = LoggingConfiguration(
            level: logLevel,
            file: nil,
            maxSize: 10 * 1024 * 1024,
            maxFiles: 5,
            enableConsole: !mcpMode && debug // Only enable console logging in debug mode
        )
        let logger = Logger(configuration: logConfig)

        // Initialize components
        let securityManager = SecurityManager()
        let toolsRegistry = ToolsRegistry(logger: logger, securityManager: securityManager)

        // Initialize tools
        try await toolsRegistry.initialize()
        try await toolsRegistry.initializeAudioTools()

        // Create the MCP server with tools capability
        let server = Server(
            name: "Local Intelligence MCP",
            version: MCPConstants.Server.version,
            instructions: "Apple Ecosystem MCP Server - Provides access to Shortcuts, Voice Control, System Information, and Accessibility features",
            capabilities: .init(
                tools: .init(listChanged: true)  // Enable tools capability
            )
        )

        await logger.info("Creating MCP server with tools registry", category: .server, metadata: [:])

        // Register ListTools handler - converts tools to MCP Tool format
        await server.withMethodHandler(ListTools.self) { _ in
            let availableTools = await toolsRegistry.getAvailableTools()
            let mcpTools = availableTools.map { toolInfo in
                // Create a proper input schema - for now use a simple object schema
                // until we can properly convert AnyCodable to JSON-serializable types
                let inputSchema = Value.object([
                    "type": .string("object"),
                    "properties": .object([:])
                ])

                return Tool(
                    name: toolInfo.name,
                    description: toolInfo.description,
                    inputSchema: inputSchema
                )
            }
            return ListTools.Result(tools: mcpTools)
        }

        // Register CallTool handler - handles tool execution
        await server.withMethodHandler(CallTool.self) { request in
            // Use the existing tool call handler
            return await StartCommand.handleToolCall(
                name: request.name,
                arguments: request.arguments,
                toolsRegistry: toolsRegistry
            )
        }

        // Create stdio transport for MCP communication
        let transport = StdioTransport()

        // Start the MCP server with stdio transport
        try await server.start(transport: transport) { clientInfo, clientCapabilities in
            await logger.info("MCP client connected", category: .server, metadata: [
                "clientName": AnyCodable(clientInfo.name),
                "clientVersion": AnyCodable(clientInfo.version)
            ])
        }

        // Wait for the server to complete (will run until interrupted)
        await server.waitUntilCompleted()
    }

  

    private func loadConfiguration(logger: Logger) async throws -> ServerConfiguration {
        let configuration = Configuration()

        if let configFile = configFile {
            // Load from specific file
            try await configuration.loadFromFile(path: configFile)
        } else {
            // Load from defaults and environment
            configuration.loadFromDefaults()
            configuration.loadFromEnvironment()
        }

        return configuration.server
    }

    private func waitForShutdownSignal() async -> String {
        return await withCheckedContinuation { continuation in
            // Setup signal handlers for graceful shutdown
            let source = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
            source.setEventHandler {
                source.cancel()
                continuation.resume(returning: "SIGINT")
            }
            source.resume()

            let termSource = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
            termSource.setEventHandler {
                termSource.cancel()
                source.cancel()
                continuation.resume(returning: "SIGTERM")
            }
            termSource.resume()
        }
    }
}

/// Check server status
struct StatusCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Check server status and health"
    )

    @Option(name: .long, help: "Path to configuration file")
    var configFile: String?

    func run() async throws {
        let logger = Logger(configuration: .default)

        do {
            // Load configuration
            let config = try await loadConfiguration(logger: logger)

            // Initialize components
            let securityManager = SecurityManager()
            let toolsRegistry = ToolsRegistry(logger: logger, securityManager: securityManager)
            let server = MCPServer(
                configuration: config,
                logger: logger,
                securityManager: securityManager,
                toolsRegistry: toolsRegistry
            )

            // Check health
            let healthResult = await server.healthCheck()
            let healthStatus: [String: Any] = [
                "status": healthResult.isHealthy ? "healthy" : "unhealthy",
                "uptime": healthResult.uptime,
                "activeConnections": healthResult.activeConnections,
                "checks": healthResult.checks
            ]

            // Display status
            await displayStatus(healthStatus: healthStatus)

        } catch {
            await logger.error("Failed to check server status", error: error, category: .server, metadata: [:])
            throw error
        }
    }

    private func loadConfiguration(logger: Logger) async throws -> ServerConfiguration {
        let configuration = Configuration()

        if let configFile = configFile {
            try await configuration.loadFromFileAsync(path: configFile)
        } else {
            configuration.loadFromDefaults()
            configuration.loadFromEnvironment()
        }

        return configuration.server
    }

    private func displayStatus(healthStatus: [String: Any]) async {
        let logger = Logger(configuration: .default)

        print("\n🍎 Local Intelligence MCP Status")
        print("=" * 30)
        print("Status: \(healthStatus["status"] as? String ?? "unknown")")
        print("Uptime: \(healthStatus["uptime"] as? String ?? "unknown")")
        print("Version: \(MCPConstants.Server.version)")
        print("Active Connections: \(healthStatus["activeConnections"] as? Int ?? 0)")

        if let systemInfo = healthStatus["systemInfo"] as? [String: Any], !systemInfo.isEmpty {
            print("\nSystem Information:")
            for (key, value) in systemInfo {
                print("  \(key): \(value)")
            }
        }

        if let errors = healthStatus["errors"] as? [String], !errors.isEmpty {
            print("\n⚠️  Errors:")
            for error in errors {
                print("  • \(error)")
            }
        }

        if let warnings = healthStatus["warnings"] as? [String], !warnings.isEmpty {
            print("\n⚠️  Warnings:")
            for warning in warnings {
                print("  • \(warning)")
            }
        }

        print("=" * 30)
    }
}

/// Manage server configuration
struct ConfigCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Manage server configuration",
        subcommands: [ShowConfigCommand.self, ValidateConfigCommand.self, ResetConfigCommand.self]
    )
}

/// Show current configuration
struct ShowConfigCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Show current configuration"
    )

    @Option(name: .long, help: "Path to configuration file")
    var configFile: String?

    @Flag(name: .long, help: "Show sensitive values (use with caution)")
    var showSensitive: Bool = false

    func run() async throws {
        let logger = Logger(configuration: .default)

        do {
            let config = try await loadConfiguration(logger: logger)
            await displayConfiguration(config: config, showSensitive: showSensitive)
        } catch {
            await logger.error("Failed to load configuration", error: error, category: .server, metadata: [:])
            throw error
        }
    }

    private func loadConfiguration(logger: Logger) async throws -> ServerConfiguration {
        let configuration = Configuration()

        if let configFile = configFile {
            try await configuration.loadFromFileAsync(path: configFile)
        } else {
            configuration.loadFromDefaults()
            configuration.loadFromEnvironment()
        }

        return configuration.server
    }

    private func displayConfiguration(config: ServerConfiguration, showSensitive: Bool) async {
        print("\n🍎 Local Intelligence MCP Configuration")
        print("=" * 40)

        print("\n📋 Server Configuration:")
        print("  Host: \(config.host)")
        print("  Port: \(config.port)")
        print("  Max Clients: \(config.maxClients)")
        print("  TLS Enabled: \(config.enableTLS)")
        if let certFile = config.certFile {
            print("  Certificate File: \(certFile)")
        }

        print("=" * 40)
    }
}

/// Validate configuration
struct ValidateConfigCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Validate configuration file"
    )

    @Option(name: .long, help: "Path to configuration file")
    var configFile: String?

    func run() async throws {
        let logger = Logger(configuration: .default)

        do {
            let config = try await loadConfiguration(logger: logger)
            let validation = await config.validate()

            if validation.isValid {
                print("✅ Configuration is valid")
            } else {
                print("❌ Configuration validation failed:")
                for issue in validation.issues {
                    print("  • \(issue.description)")
                }
                throw ConfigurationError.validationError("Configuration validation failed")
            }

        } catch {
            await logger.error("Configuration validation failed", error: error, category: .server, metadata: [:])
            throw error
        }
    }

    private func loadConfiguration(logger: Logger) async throws -> ServerConfiguration {
        let configuration = Configuration()

        if let configFile = configFile {
            try await configuration.loadFromFileAsync(path: configFile)
        } else {
            configuration.loadFromDefaults()
            configuration.loadFromEnvironment()
        }

        return configuration.server
    }
}

/// Reset configuration to defaults
struct ResetConfigCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Reset configuration to defaults"
    )

    @Flag(name: .long, help: "Confirm reset without interactive prompt")
    var force: Bool = false

    func run() async throws {
        let logger = Logger(configuration: .default)

        if !force {
            print("⚠️  This will reset the configuration to default values.")
            print("Are you sure you want to continue? (y/N): ", terminator: "")

            guard let response = readLine()?.lowercased(), response == "y" || response == "yes" else {
                print("Operation cancelled.")
                return
            }
        }

        do {
            // Configuration reset is just loading defaults
            let configuration = Configuration()
            configuration.loadFromDefaults()
            print("✅ Configuration reset to defaults successfully")

        } catch {
            await logger.error("Failed to reset configuration", error: error, category: .server, metadata: [:])
            throw error
        }
    }
}

// MARK: - Extensions

extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}

extension TimeInterval {
    var formattedDuration: String {
        let hours = Int(self) / 3600
        let minutes = Int(self) % 3600 / 60
        let seconds = Int(self) % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Static Tool Handler

extension StartCommand {
    /// Handle tool calls from MCP server
    /// - Parameters:
    ///   - name: Tool name
    ///   - arguments: Tool arguments
    ///   - toolsRegistry: Tools registry instance
    /// - Returns: Tool execution result
    static func handleToolCall(name: String, arguments: [String: Value]?, toolsRegistry: ToolsRegistry) async -> CallTool.Result {
        do {
            // Create tool instance and execute
            let tool = try await toolsRegistry.createTool(name: name)

            // Create execution context
            let context = MCPExecutionContext(
                clientId: UUID(),
                requestId: UUID().uuidString,
                toolName: name,
                metadata: [:]
            )

            // Convert Value arguments to AnyCodable - properly extract values from MCP Value enum
            let codableArgs: [String: AnyCodable] = arguments?.mapValues { value in
                switch value {
                case .string(let stringValue):
                    return AnyCodable(stringValue)
                case .int(let intValue):
                    return AnyCodable(intValue)
                case .double(let doubleValue):
                    return AnyCodable(doubleValue)
                case .bool(let boolValue):
                    return AnyCodable(boolValue)
                case .array(let arrayValue):
                    // For arrays, we need to determine the best common type
                    // For now, assume string arrays since that's most common for tool parameters
                    let stringArray = arrayValue.map { element in
                        switch element {
                        case .string(let stringValue): return stringValue
                        case .int(let intValue): return String(intValue)
                        case .double(let doubleValue): return String(doubleValue)
                        case .bool(let boolValue): return String(boolValue)
                        default: return String(describing: element)
                        }
                    }
                    return AnyCodable(stringArray)
                case .object(let objectValue):
                    // Convert object values to strings for consistency
                    let stringObject = objectValue.mapValues { element in
                        switch element {
                        case .string(let stringValue): return stringValue
                        case .int(let intValue): return String(intValue)
                        case .double(let doubleValue): return String(doubleValue)
                        case .bool(let boolValue): return String(boolValue)
                        default: return String(describing: element)
                        }
                    }
                    return AnyCodable(stringObject)
                default:
                    return AnyCodable(String(describing: value))
                }
            } ?? [:]

            // Execute tool
            let result = try await tool.execute(parameters: codableArgs, context: context)

            // Extract text content from result
            let responseText: String
            if let data = result.data {
                if let text = data.asText {
                    responseText = text
                } else if let jsonData = try? JSONSerialization.data(withJSONObject: data.toAnyDictionary()),
                          let jsonString = String(data: jsonData, encoding: .utf8) {
                    responseText = jsonString
                } else {
                    responseText = "Tool executed successfully"
                }
            } else {
                responseText = "Tool executed successfully"
            }

            
            return CallTool.Result(
                content: [
                    .text(responseText)
                ],
                isError: !result.success
            )

        } catch {
            return CallTool.Result(
                content: [
                    .text("Error executing tool \(name): \(error.localizedDescription)")
                ],
                isError: true
            )
        }
    }
}

// LogLevel extension moved to Logger.swift for better organization