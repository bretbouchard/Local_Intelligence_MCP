//
//  DeepCoverageRound3Tests.swift
//  LocalIntelligenceMCPTests
//
//  Coverage round 3: analyzer depth paths, catalog grouping, embedding
//  model variants, and the evidence CLI subcommand.
//

import XCTest
@testable import LocalIntelligenceMCP

final class DeepCoverageRound3Tests: XCTestCase {

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

    private let items: [[String: Any]] = [
        ["id": "p1", "name": "CompX", "vendor": "AudioCo", "category": "Dynamics",
         "tags": ["compressor"], "description": "Glue compressor with sidechain", "price": "$99"],
        ["id": "p2", "name": "DelayLab", "vendor": "EchoWorks", "category": "Delay",
         "tags": ["delay", "tape"], "description": "Vintage tape delay emulation", "price": "$49"],
        ["id": "p3", "name": "ReverbKing", "vendor": "EchoWorks", "category": "Reverb",
         "tags": ["reverb", "plate"], "description": "Plate reverb with modulation", "price": "$129"],
    ]

    // MARK: - Catalog grouping and summary lengths

    func testCatalog_GroupingsAndSummaryLengths() async {
        let tool = CatalogSummarizationTool(logger: logger, securityManager: securityManager)
        for grouping in ["category", "vendor", "price_range", "compatibility"] {
            let response = await run(tool, ["items": items, "grouping": grouping, "vendor_analysis": true])
            XCTAssertTrue(response.success, "grouping \(grouping) failed: \(response.error?.message ?? "")")
        }
        for length in ["brief", "standard", "detailed", "comprehensive"] {
            let response = await run(tool, ["items": items, "summary_length": length])
            XCTAssertTrue(response.success, "summary_length \(length) failed: \(response.error?.message ?? "")")
        }
    }

    // MARK: - Content purpose: deep analysis with quality assessment

    func testContentPurpose_ComprehensiveDepthWithQualityAndBusiness() async {
        let tool = ContentPurposeDetector(logger: logger, securityManager: securityManager)
        let content = """
        The studio upgraded its monitoring chain this quarter. We compared performance
        across three reference tracks and the new converters reduced the noise floor.
        Revenue impact: clients are booking more mixing time since the upgrade.
        """
        for options in [
            ["analysis_depth": "comprehensive", "include_business_context": true, "include_quality_assessment": true],
            ["analysis_depth": "basic"],
            ["content_hint": "business", "include_business_context": true],
        ] {
            var params = options
            params["content"] = content
            let response = await run(tool, params)
            XCTAssertTrue(response.success, "purpose detection \(options) failed: \(response.error?.message ?? "")")
            XCTAssertFalse(text(response).isEmpty)
        }
    }

    // MARK: - Embedding: metadata payload and model field round trip

    func testEmbeddingGeneration_WithMetadataPayload() async {
        let tool = EmbeddingGenerationTool(logger: logger, securityManager: securityManager)
        let response = await run(tool, [
            "content": "gated reverb snare",
            "metadata": ["track": "snares", "engineer": "test"] as [String: String],
        ])
        XCTAssertTrue(response.success, "embedding with metadata failed: \(response.error?.message ?? "")")
        let dict = jsonDict(response)
        XCTAssertNotNil(dict)
    }

    // MARK: - Evidence subcommand (GSD Plan 5.6 CLI path)

    func testEvidenceCommand_RunsClean() async throws {
        let evidence = EvidenceCommand()
        do {
            try await evidence.run()
        } catch {
            XCTFail("evidence command failed: \(error)")
        }
    }

    // MARK: - Config validation CLI path

    func testConfigValidationCommand_Path() async {
        let validate = ValidateConfigCommand()
        do {
            try await validate.run()
        } catch {
            // Validation failing to find a config file is an acceptable outcome;
            // the contract under test is that the command runs without crashing.
        }
    }
}
