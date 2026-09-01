//
//  EndToEndTests.swift
//  LocalIntelligenceMCPTests
//
//  GSD Plan 5.4/M12/M13 — true end-to-end tests: spawn the real server
//  executable as a child process, connect a real MCP client over stdio,
//  and verify the complete wire journey (the path no in-process test covers).
//

import XCTest
import MCP
import System
@testable import LocalIntelligenceMCP

final class EndToEndTests: XCTestCase {

    // MARK: - Server process harness

    private func serverBinaryPath() -> String? {
        // Tests run from the package root; the executable is a sibling build product.
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // Tests/LocalIntelligenceMCPTests
            .deletingLastPathComponent()   // Tests
            .deletingLastPathComponent()   // package root
        for candidate in [".build/debug/LocalIntelligenceMCP", ".build/release/LocalIntelligenceMCP"] {
            let path = root.appendingPathComponent(candidate).path
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }
        return nil
    }

    private final class SpawnedServer {
        let process = Process()
        let inputPipe = Pipe()
        let outputPipe = Pipe()
        let client = Client(name: "e2e-test", version: "1.0.0")

        init(serverPath: String) throws {
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
            return try await client.connect(transport: StdioTransport(input: output, output: input))
        }

        func shutdown() async {
            await client.disconnect()
            if process.isRunning {
                process.terminate()
            }
        }
    }

    private func withServer(_ body: (SpawnedServer) async throws -> Void) async throws {
        guard let path = serverBinaryPath() else {
            throw XCTSkip("Server executable not built")
        }
        let server = try SpawnedServer(serverPath: path)
        do {
            _ = try await server.connect()
            try await body(server)
            await server.shutdown()
        } catch {
            await server.shutdown()
            throw error
        }
    }

    private func text(_ result: (content: [Tool.Content], isError: Bool?)) -> String {
        result.content.compactMap { content -> String? in
            if case .text(let t) = content { return t.text }
            return nil
        }.joined()
    }

    // MARK: - M13 scenarios

    func testE2E_Discover_List_Call() async throws {
        try await withServer { server in
            // discover: capabilities negotiated
            let (tools, _) = try await server.client.listTools()
            let names = tools.map { $0.name }
            XCTAssertGreaterThanOrEqual(tools.count, 30, "full registry should be advertised")
            for required in ["local_capabilities", "local_generate", "local_summarize",
                             "local_extract", "local_classify", "local_automation_list",
                             "local_automation_execute", "local_image_understand"] {
                XCTAssertTrue(names.contains(required), "missing \(required)")
            }

            // real input schemas (not the empty-schema regression)
            let generate = tools.first { $0.name == "local_generate" }
            let schemaString = String(describing: generate?.inputSchema)
            XCTAssertTrue(schemaString.contains("prompt"), "tools/list must carry real schemas: \(schemaString)")

            // call: deterministic tool over the wire
            let summary = try await server.client.callTool(name: "local_summarize", arguments: [
                "text": .string("First sentence has content. Second sentence has more. Third concludes."),
                "sentenceLimit": .int(2),
            ])
            XCTAssertEqual(summary.isError, false)
            XCTAssertTrue(text(summary).contains("provider"), "result must attribute its provider")
        }
    }

    func testE2E_CapabilityDiscovery_DistinctFromProtocolDiscovery() async throws {
        try await withServer { server in
            let caps = try await server.client.callTool(name: "local_capabilities", arguments: [:])
            XCTAssertEqual(caps.isError, false)
            let payload = text(caps)
            for capability in ["local_generate", "local_summarize", "local_automation_execute"] {
                XCTAssertTrue(payload.contains(capability), "missing runtime status for \(capability)")
            }
            XCTAssertTrue(payload.contains("osVersion"), "runtime truth must include OS tier")
        }
    }

    func testE2E_DenialAndUnavailablePaths() async throws {
        try await withServer { server in
            // destructive automation name without confirmation → POLICY_DENIED
            let denied = try await server.client.callTool(name: "local_automation_execute", arguments: [
                "name": .string("Delete Everything Important"),
            ])
            XCTAssertEqual(denied.isError, true)
            XCTAssertTrue(text(denied).contains("POLICY_DENIED"), "got: \(text(denied))")

            // never-simulated capability → UNSUPPORTED
            let voice = try await server.client.callTool(name: "voice_command", arguments: [
                "command": .string("open Safari"),
            ])
            XCTAssertEqual(voice.isError, true)
            XCTAssertTrue(text(voice).contains("UNSUPPORTED"), "got: \(text(voice))")
        }
    }

    func testE2E_RestartBetweenCalls() async throws {
        // M13: independent calls must survive a full server restart (no hidden session state).
        let first = Date()
        try await withServer { server in
            let r = try await server.client.callTool(name: "local_summarize", arguments: [
                "text": .string("Restart test one."),
            ])
            XCTAssertEqual(r.isError, false)
        }
        XCTAssertGreaterThan(Date().timeIntervalSince(first), 0)

        try await withServer { server in
            let r = try await server.client.callTool(name: "local_summarize", arguments: [
                "text": .string("Restart test two after a fresh process."),
            ])
            XCTAssertEqual(r.isError, false, "fresh process must serve independently: \(text(r))")
        }
    }

    func testE2E_ConcurrentClients() async throws {
        guard let path = serverBinaryPath() else { throw XCTSkip("Server executable not built") }

        async let first: Void = withServer { server in
            let r = try await server.client.callTool(name: "local_classify", arguments: [
                "text": .string("Please add support for dark mode"),
            ])
            XCTAssertEqual(r.isError, false)
        }
        async let second: Void = withServer { server in
            let r = try await server.client.callTool(name: "local_extract", arguments: [
                "text": .string("Contact a@b.com about 2026-01-15"),
            ])
            XCTAssertEqual(r.isError, false)
        }
        _ = try await (first, second)
    }
}
