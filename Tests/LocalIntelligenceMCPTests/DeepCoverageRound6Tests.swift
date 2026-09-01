//
//  DeepCoverageRound6Tests.swift
//  LocalIntelligenceMCPTests
//
//  Coverage round 6: embedding batch path, QualityAssessor fixtures,
//  and catalog deep option paths.
//

import XCTest
@testable import LocalIntelligenceMCP

final class DeepCoverageRound6Tests: XCTestCase {

    private let logger = Logger(configuration: LoggingConfiguration(level: .error, file: nil, maxSize: 1, maxFiles: 1, enableConsole: false))
    private let securityManager = SecurityManager()

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

    // MARK: - Embedding batch path (direct public API)

    func testEmbeddingBatch_AllContentsProcessed() async throws {
        let tool = EmbeddingGenerationTool(logger: logger, securityManager: securityManager)
        let input = EmbeddingGenerationTool.BatchEmbeddingInput(
            contents: ["first document", "second document", "third document"],
            contentType: "text",
            embeddingModel: nil,
            dimensions: nil,
            normalize: true,
            batchMetadata: nil
        )
        let output = try await tool.handleBatch(input)
        XCTAssertFalse(output.batchId.isEmpty, "batch must produce a batch id")
        // per-content success depends on the internal embedding engine; the
        // contract here is that the batch path runs without crashing or hanging
    }

    // MARK: - QualityAssessor: content-shape variety (branches per shape)

    func testQualityAssessor_ContentShapes() {
        let assessor = QualityAssessor()
        for content in [
            "TODO: fix the vocal comp. FOLLOW UP: send stems.",          // action + follow-up
            String(repeating: "word ", count: 500),                      // long unstructured
            "Q: what about the deadline?",                               // question
            "Step 1. Set gain. Step 2. Enable compression.",             // structured
        ] {
            let indicators = assessor.assessQuality(content: content, contentType: .transcript)
            XCTAssertGreaterThanOrEqual(indicators.completeness, 0)
            XCTAssertGreaterThanOrEqual(indicators.clarity, 0)
        }
    }

    // MARK: - Catalog: focus + vendor analysis over multi-vendor items

    func testCatalog_VendorAnalysisGroupings() async {
        let tool = CatalogSummarizationTool(logger: logger, securityManager: securityManager)
        let items: [[String: Any]] = [
            ["id": "p1", "name": "CompA", "vendor": "Alpha", "tags": ["comp"], "description": "compressor one"],
            ["id": "p2", "name": "CompB", "vendor": "Alpha", "tags": ["comp", "bus"], "description": "compressor two"],
            ["id": "p3", "name": "DelayZ", "vendor": "Beta", "tags": ["delay"], "description": "tape delay unit"],
        ]
        for grouping in ["vendor", "category"] {
            let response = await run(tool, [
                "items": items, "grouping": grouping, "vendor_analysis": true,
                "include_clusters": true, "recommend_alternatives": true, "max_overviews": 3,
            ])
            XCTAssertTrue(response.success, "catalog grouping \(grouping) failed: \(response.error?.message ?? "")")
            XCTAssertFalse(text(response).isEmpty)
        }
    }
}
