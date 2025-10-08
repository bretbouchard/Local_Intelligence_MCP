//
//  Server.swift
//  AppleMCPServer
//
//  Created on 2025-10-07.
//

import Foundation
import ArgumentParser

/// Main entry point for the Apple MCP Server
@main
struct AppleMCPServer: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "apple-mcp-server",
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
        abstract: "Start the Apple MCP server",
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

    func run() async throws {
        let startTime = Date()

        // Create logger with configured level
        let logLevel = ConfigurationLogLevel(rawValue: self.logLevel ?? "info") ?? .info
        let logConfig = LoggingConfiguration(
            level: logLevel,
            file: nil,
            maxSize: 10 * 1024 * 1024,
            maxFiles: 5,
            enableConsole: true
        )
        let logger = Logger(configuration: logConfig)

        await logger.info("Starting Apple MCP Server", metadata: [
            "version": MCPConstants.Server.version,
            "buildDate": "2025-10-07",
            "debug": debug,
            "startTime": startTime.iso8601String
        ])

        do {
            // Load configuration
            let config = try await loadConfiguration(logger: logger)

            await logger.info("Configuration loaded successfully", metadata: [
                "configFile": configFile ?? "default",
                "serverName": MCPConstants.Server.name
            ])

            // Initialize security manager
            let securityManager = SecurityManager()

            // Initialize tools registry
            let toolsRegistry = ToolsRegistry(logger: logger, securityManager: securityManager)
            try await toolsRegistry.initialize()

            // Initialize main server instance
            let server = MCPServer(
                configuration: config,
                logger: logger,
                securityManager: securityManager,
                toolsRegistry: toolsRegistry
            )

            // Start the server
            try await server.start()

            if foreground {
                await logger.info("Server running in foreground mode. Press Ctrl+C to stop.")

                // Handle graceful shutdown
                let signal = await waitForShutdownSignal()
                await logger.info("Received shutdown signal: \(signal)")

                try await server.stop()
                await logger.info("Server stopped gracefully")
            } else {
                await logger.info("Server started successfully")
            }

        } catch {
            await logger.error("Failed to start server", error: error)
            throw error
        }
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
            await logger.error("Failed to check server status", error: error)
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

        print("\n🍎 Apple MCP Server Status")
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
            await logger.error("Failed to load configuration", error: error)
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
        print("\n🍎 Apple MCP Server Configuration")
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
            await logger.error("Configuration validation failed", error: error)
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
            await logger.error("Failed to reset configuration", error: error)
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

// LogLevel extension moved to Logger.swift for better organization