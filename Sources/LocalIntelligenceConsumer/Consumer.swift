//
//  Consumer.swift
//  LocalIntelligenceConsumer
//
//  Reference MCP client (GSD Plan 4.7 / LOCAL_KNOWLEDGE_MCP_CLIENT_REVIEW.md):
//  spawns the Local Intelligence MCP server over stdio and exercises it the way
//  a real consumer (e.g. the local_knowledge app) should — initialize, discover,
//  call, surface errors verbatim.
//

import ArgumentParser
import Foundation
import MCP
import System

/// Owns the child server process and the connected MCP client.
final class ServerSession {
    private let process = Process()
    private let inputPipe = Pipe()   // parent writes → child stdin
    private let outputPipe = Pipe()  // child stdout → parent reads
    let client: Client

    init(serverPath: String) throws {
        client = Client(name: "li-consumer", version: "1.0.0")
        process.executableURL = URL(fileURLWithPath: serverPath)
        process.arguments = ["start-command", "--mcp-mode"]
        process.standardInput = inputPipe
        process.standardOutput = outputPipe
        process.standardError = FileHandle.nullDevice
        try process.run()
    }

    func connect() async throws -> Initialize.Result {
        let input = FileDescriptor(rawValue: inputPipe.fileHandleForWriting.fileDescriptor)
        let output = FileDescriptor(rawValue: outputPipe.fileHandleForReading.fileDescriptor)
        // connect performs the initialize handshake itself.
        return try await client.connect(transport: StdioTransport(input: output, output: input))
    }

    func shutdown() async {
        await client.disconnect()
        if process.isRunning {
            process.terminate()
        }
    }
}

@main
struct LocalIntelligenceConsumer: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "li-consumer",
        abstract: "Reference MCP consumer for Local Intelligence MCP",
        subcommands: [Capabilities.self, Tools.self, Call.self, Generate.self, Demo.self],
        defaultSubcommand: Demo.self
    )

    static let defaultServerPath = ".build/debug/LocalIntelligenceMCP"
}

// MARK: - Shared session helpers

struct Session: AsyncParsableCommand {
    @Option(name: .long, help: "Path to the server executable")
    var serverPath = LocalIntelligenceConsumer.defaultServerPath
}

func withSession<T>(_ serverPath: String, _ body: (ServerSession) async throws -> T) async throws -> T {
    let session = try ServerSession(serverPath: serverPath)
    do {
        let info = try await session.connect()
        print("— server: \(info.serverInfo.name) v\(info.serverInfo.version) (protocol \(info.protocolVersion))")
        let result = try await body(session)
        await session.shutdown()
        return result
    } catch {
        await session.shutdown()
        throw error
    }
}

func printContent(_ result: (content: [Tool.Content], isError: Bool?)) {
    print(result.isError == true ? "ERR" : "OK ", terminator: " ")
    for content in result.content {
        if case .text(let t) = content {
            print(t.text)
        }
    }
}

// MARK: - capabilities

extension LocalIntelligenceConsumer {
    struct Capabilities: AsyncParsableCommand {
        @Option(name: .long) var serverPath = LocalIntelligenceConsumer.defaultServerPath

        func run() async throws {
            try await withSession(serverPath) { session in
                let result = try await session.client.callTool(name: "local_capabilities", arguments: [:])
                printContent(result)
            }
        }
    }
}

// MARK: - tools

extension LocalIntelligenceConsumer {
    struct Tools: AsyncParsableCommand {
        @Option(name: .long) var serverPath = LocalIntelligenceConsumer.defaultServerPath

        func run() async throws {
            try await withSession(serverPath) { session in
                let (tools, _) = try await session.client.listTools()
                print("\(tools.count) tools:")
                for tool in tools.map({ $0.name }).sorted() {
                    print("  \(tool)")
                }
            }
        }
    }
}

// MARK: - call

extension LocalIntelligenceConsumer {
    struct Call: AsyncParsableCommand {
        @Option(name: .long) var serverPath = LocalIntelligenceConsumer.defaultServerPath
        @Option(name: .long) var name: String
        @Option(name: .long, help: "Arguments as a JSON object string") var args = "{}"

        func run() async throws {
            guard let value = try? JSONDecoder().decode(Value.self, from: Data(args.utf8)),
                  case .object(let object) = value else {
                throw ValidationError("--args must be a JSON object string")
            }
            try await withSession(serverPath) { session in
                let result = try await session.client.callTool(name: name, arguments: object)
                printContent(result)
            }
        }
    }
}

// MARK: - generate

extension LocalIntelligenceConsumer {
    struct Generate: AsyncParsableCommand {
        @Option(name: .long) var serverPath = LocalIntelligenceConsumer.defaultServerPath
        @Argument var prompt: String

        func run() async throws {
            try await withSession(serverPath) { session in
                let result = try await session.client.callTool(
                    name: "local_generate",
                    arguments: ["prompt": .string(prompt)]
                )
                printContent(result)
            }
        }
    }
}

// MARK: - demo (default): the full consumer journey

extension LocalIntelligenceConsumer {
    struct Demo: AsyncParsableCommand {
        @Option(name: .long) var serverPath = LocalIntelligenceConsumer.defaultServerPath

        func run() async throws {
            try await withSession(serverPath) { session in
                let client = session.client

                // 1. Capability discovery — what can THIS Mac do?
                let caps = try await client.callTool(name: "local_capabilities", arguments: [:])
                print("1. capability discovery:")
                printContent(caps)

                // 2. Deterministic utility.
                let summary = try await client.callTool(name: "local_summarize", arguments: [
                    "text": .string("The session ran long. We tracked vocals for two hours. Rough mix printed at the end."),
                    "sentenceLimit": .int(2),
                ])
                print("2. deterministic summarize:")
                printContent(summary)

                // 3. Real automation discovery.
                let shortcuts = try await client.callTool(name: "local_automation_list", arguments: [:])
                print("3. automation discovery:")
                printContent(shortcuts)

                // 4. Truthful unavailability — never a simulated success.
                let voice = try await client.callTool(name: "voice_command", arguments: ["command": .string("open Safari")])
                print("4. unavailable capability:")
                printContent(voice)
            }
        }
    }
}
