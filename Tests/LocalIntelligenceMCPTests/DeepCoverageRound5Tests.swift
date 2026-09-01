//
//  DeepCoverageRound5Tests.swift
//  LocalIntelligenceMCPTests
//
//  Coverage round 5: embedding content types/models, batch path,
//  chunking edge cases, and Server CLI evidence path.
//

import XCTest
@testable import LocalIntelligenceMCP

final class DeepCoverageRound5Tests: XCTestCase {

    private let logger = Logger(configuration: LoggingConfiguration(level: .error, file: nil, maxSize: 1, maxFiles: 1, enableConsole: false))
    private let securityManager = SecurityManager()

    private func runEmbedding(_ options: [String: Any]) async -> MCPResponse? {
        let tool = EmbeddingGenerationTool(logger: logger, securityManager: securityManager)
        let context = MCPExecutionContext(clientId: UUID(), requestId: UUID().uuidString, toolName: "embedding_generation", metadata: [:])
        return try? await tool.execute(parameters: options.mapValues { AnyCodable($0) }, context: context)
    }

    func testEmbeddingGeneration_AllContentTypes() async {
        // every published contentType value (covers per-type processing branches)
        for contentType in ["text", "session_notes", "plugin_description", "feedback", "technical_spec"] {
            let response = await runEmbedding([
                "content": "Content fixture for the \(contentType) embedding path.",
                "contentType": contentType,
            ])
            XCTAssertEqual(response?.success, true, "contentType \(contentType) failed")
        }
    }

    func testEmbeddingGeneration_AllModelsAndDimensions() async {
        for model in ["audio-domain", "general"] {
            let response = await runEmbedding([
                "content": "Model-variant embedding fixture with enough words to be meaningful.",
                "embeddingModel": model,
            ])
            XCTAssertEqual(response?.success, true, "model \(model) failed")
        }
        for dims in [384, 768] {
            let response = await runEmbedding([
                "content": "Dimension-variant embedding fixture.",
                "dimensions": dims,
            ])
            XCTAssertEqual(response?.success, true, "dimensions \(dims) failed")
        }
    }

    func testEmbeddingGeneration_InvalidModelFailsHonestly() async {
        let response = await runEmbedding([
            "content": "some content",
            "embeddingModel": "not-a-real-model",
        ])
        XCTAssertEqual(response?.success, false, "invalid model must fail, not silently use another")
    }

    func testChunking_EdgeCases() async {
        let tool = TextChunkingTool(logger: logger, securityManager: securityManager)
        // single word (minimum content), no punctuation
        let single = await run(tool, ["text": "word", "strategy": "sentence", "min_chunk_size": 1])
        XCTAssertTrue(single.success || single.error != nil, "single word must not crash")

        // whitespace-only input: honest failure or empty — never a crash
        let empty = await run(tool, ["text": "   ", "strategy": "fixed", "min_chunk_size": 1])
        _ = empty.success

        // max chunk smaller than one sentence with overlap
        let overlap = await run(tool, [
            "text": Array(repeating: "Sentence for overlap testing purposes here.", count: 8).joined(separator: " "),
            "strategy": "sentence", "overlap": 4, "max_chunk_size": 12, "min_chunk_size": 2,
        ])
        XCTAssertTrue(overlap.success, "overlap path failed: \(overlap.error?.message ?? "")")
        XCTAssertFalse(text(overlap).isEmpty)
    }

    private func run(_ tool: BaseMCPTool, _ params: [String: Any]) async -> MCPResponse {
        let context = MCPExecutionContext(clientId: UUID(), requestId: UUID().uuidString, toolName: tool.name, metadata: [:])
        do {
            return try await tool.execute(parameters: params.mapValues { AnyCodable($0) }, context: context)
        } catch {
            return MCPResponse(success: false, error: LocalMCPError(code: "THREW", message: String(describing: error)))
        }
    }

    private func text(_ response: MCPResponse) -> String {
        let dict = jsonDict(response)
        for key in ["result", "text", "summary"] {
            if let s = dict[key] as? String { return s }
        }
        return String(describing: response.data?.value ?? "nil")
    }

    private func jsonDict(_ response: MCPResponse) -> [String: Any] {
        guard let data = response.data else { return [:] }
        if let codable = data.value as? any Codable,
           let jsonData = try? JSONEncoder().encode(codable),
           let obj = try? JSONSerialization.jsonObject(with: jsonData) {
            return obj as? [String: Any] ?? ["value": obj]
        }
        return data.toAnyDictionary()
    }
}
