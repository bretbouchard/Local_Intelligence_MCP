//
//  Server.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-07.
//

import Foundation
import ArgumentParser
import MCP

#if canImport(FoundationModels)
import FoundationModels
#endif

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
        subcommands: [StartCommand.self, ConfigCommand.self, EvidenceCommand.self],
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
            instructions: """
            Local Intelligence MCP provides truthful local capabilities: runtime \
            capability discovery (local_capabilities), on-device Apple generation on \
            macOS 26+ (local_generate), deterministic text tools (local_summarize, \
            local_extract, local_classify), and real Apple Shortcuts automation \
            (local_automation_list, local_automation_execute). Unavailable \
            capabilities report distinguishable machine-readable errors; nothing \
            simulates success.
            """,
            capabilities: .init(
                tools: .init(listChanged: true)  // Enable tools capability
            )
        )

        await logger.info("Creating MCP server with tools registry", category: .server, metadata: [:])

        // Register ListTools handler - converts tools to MCP Tool format with real schemas
        await server.withMethodHandler(ListTools.self) { _ in
            let availableTools = await toolsRegistry.getAvailableTools()
            let mcpTools = availableTools.map { toolInfo in
                // Expose each tool's authoritative input schema — an empty schema here
                // would misrepresent the contract clients are calling.
                let inputSchema = Value.object(
                    toolInfo.inputSchema.mapValues { StartCommand.toMCPValue($0.value) }
                )
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

/// GSD Plan 5.6 — machine-readable release evidence bundle.
struct EvidenceCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "evidence",
        abstract: "Emit a machine-readable evidence bundle (runtime truth for this release)"
    )

    func run() async throws {
        let logger = Logger(configuration: LoggingConfiguration(level: .error, file: nil, maxSize: 1, maxFiles: 1, enableConsole: false))
        let securityManager = SecurityManager()
        let registry = ToolsRegistry(logger: logger, securityManager: securityManager)
        try await registry.initialize()
        try await registry.initializeAudioTools()

        let capabilities = RuntimeCapabilities(providers: await registry.capabilityRouter.registeredProviders())
        var statuses: [String: String] = [:]
        for capability in StableCapability.allCases {
            statuses[capability.rawValue] = capabilities.status(for: capability).rawValue
        }

        var bundle: [String: Any] = [
            "serverVersion": MCPConstants.Server.version,
            "generatedAt": Date().iso8601String,
            "runtime": (try? JSONSerialization.jsonObject(with: JSONEncoder().encode(capabilities))) ?? [:],
            "capabilityStatuses": statuses.sorted { $0.key < $1.key }.reduce(into: [String: Any]()) { $0[$1.key] = $1.value },
            "toolCount": await registry.toolCount(),
        ]

        if #available(macOS 27.0, *) {
            #if canImport(FoundationModels)
            bundle["pccPolicyAllowed"] = ApplePCCProvider.policyAllows
            bundle["pccAvailability"] = ApplePCCProvider.status(for: PrivateCloudComputeLanguageModel().availability).rawValue
            #endif
        }

        let data = try JSONSerialization.data(withJSONObject: bundle, options: [.prettyPrinted, .sortedKeys])
        if let json = String(data: data, encoding: .utf8) {
            print(json)
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
    /// Convert a decoded JSON value to an MCP protocol Value (recursive).
    static func toMCPValue(_ any: Any) -> Value {
        switch any {
        case let value as Value:
            return value
        case let value as String:
            return .string(value)
        case let value as Bool:
            return .bool(value)
        case let value as Int:
            return .int(value)
        case let value as Double:
            return .double(value)
        case let value as [Any]:
            return .array(value.map(toMCPValue))
        case let value as [String: Any]:
            return .object(value.mapValues(toMCPValue))
        default:
            return .string(String(describing: any))
        }
    }

    /// Convert an MCP protocol Value to a plain JSON value wrapped in AnyCodable
    /// (recursive; nulls preserved as NSNull so JSON round-trips).
    static func toAnyCodable(_ value: Value) -> AnyCodable {
        switch value {
        case .null:
            return AnyCodable(NSNull())
        case .bool(let bool):
            return AnyCodable(bool)
        case .int(let int):
            return AnyCodable(int)
        case .double(let double):
            return AnyCodable(double)
        case .string(let string):
            return AnyCodable(string)
        case .data(_, let data):
            // Binary has no JSON representation; surface as base64.
            return AnyCodable(data.base64EncodedString())
        case .array(let array):
            return AnyCodable(array.map { toAnyCodable($0).value })
        case .object(let object):
            return AnyCodable(object.mapValues { toAnyCodable($0).value })
        }
    }

    /// Handle tool calls from MCP server
    /// - Parameters:
    ///   - name: Tool name
    ///   - arguments: Tool arguments
    ///   - toolsRegistry: Tools registry instance
    /// - Returns: Tool execution result
    static func handleToolCall(name: String, arguments: [String: Value]?, toolsRegistry: ToolsRegistry) async -> CallTool.Result {
        do {
            // Create execution context
            let context = MCPExecutionContext(
                clientId: UUID(),
                requestId: UUID().uuidString,
                toolName: name,
                metadata: [:]
            )

            // Convert Value arguments to AnyCodable, preserving nested structure:
            // flattening objects/arrays to strings destroyed responseSchema and
            // broke every tool that consumes structured arguments.
            let codableArgs: [String: AnyCodable] = (arguments ?? [:]).mapValues {
                StartCommand.toAnyCodable($0)
            }

            // Route through the registry so declared permissions are actually
            // verified before execution (SEC-03) and audit logging applies.
            let plainArgs: [String: Any] = codableArgs.mapValues { $0.value }
            let result = try await toolsRegistry.executeTool(
                name: name,
                parameters: plainArgs,
                context: context
            )

            // Extract text content from result; surface error envelopes verbatim
            // instead of hiding failures behind a generic success string.
            let responseText: String
            if let error = result.error {
                var payload: [String: Any] = ["errorCode": error.code, "message": error.message]
                if let details = error.details {
                    payload["details"] = AnyCodable.toAnyDictionary(details)
                }
                if let jsonData = try? JSONSerialization.data(withJSONObject: payload),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    responseText = jsonString
                } else {
                    responseText = "Error [\(error.code)]: \(error.message)"
                }
            } else if let data = result.data {
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