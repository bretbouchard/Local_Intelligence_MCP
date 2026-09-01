//
//  DeepCoverageTests.swift
//  LocalIntelligenceMCPTests
//
//  Coverage push: SystemInfo, registry internals, Configuration,
//  ErrorHandlingUtils, TextValidationUtils, VendorNeutralAnalyzer, and
//  deep option paths of the audio/text tools.
//

import XCTest
@testable import LocalIntelligenceMCP

final class DeepCoverageTests: XCTestCase {

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

    // MARK: - SystemInfoTool (was 6% covered)

    func testSystemInfo_CategoryQueries() async {
        let tool = SystemInfoTool(logger: logger, securityManager: securityManager)
        for categories in [["device"], ["os"], ["hardware"], ["network"], ["permissions"], ["server"], ["device", "os"]] {
            let response = await run(tool, ["categories": categories])
            XCTAssertTrue(response.success, "system_info \(categories) failed: \(response.error?.message ?? "")")
            XCTAssertFalse(text(response).isEmpty)
        }
    }

    // MARK: - ToolsRegistry internals (validation, search, categories, stats)

    func testRegistry_SearchCategoriesAndStats() async throws {
        let registry = ToolsRegistry(logger: logger, securityManager: securityManager)
        try await registry.initialize()
        try await registry.initializeAudioTools()

        let matches = await registry.searchTools("summar")
        XCTAssertFalse(matches.isEmpty, "search should find summarize tools")

        let stats = await registry.getCategoryStatistics()
        XCTAssertFalse(stats.isEmpty)
        let textTools = await registry.getToolsByCategory(.textProcessing)
        XCTAssertTrue(textTools.contains { $0.name == "apple_summarize" })
        let offline = await registry.getOfflineCapableTools()
        XCTAssertFalse(offline.isEmpty)
    }

    func testRegistry_DuplicateRegistrationFails() async throws {
        let registry = ToolsRegistry(logger: logger, securityManager: securityManager)
        try await registry.initialize()
        let duplicate = SystemInfoTool(logger: logger, securityManager: securityManager)
        do {
            try await registry.registerTool(duplicate)
            XCTFail("duplicate tool registration must fail")
        } catch { /* expected */ }
    }

    func testRegistry_ParameterValidation_RejectsOversizedValues() async throws {
        let registry = ToolsRegistry(logger: logger, securityManager: securityManager)
        try await registry.initialize()
        try await registry.initializeAudioTools()
        let huge = String(repeating: "x", count: MCPConstants.Limits.maxParameterValueLength + 1)
        let response = try await registry.executeTool(
            name: "apple_text_normalize",
            parameters: ["text": huge],
            context: MCPExecutionContext(clientId: UUID(), requestId: UUID().uuidString, toolName: "apple_text_normalize", metadata: [:])
        )
        XCTAssertFalse(response.success, "over-limit parameter must be rejected")
        XCTAssertEqual(response.error?.code, "INVALID_PARAMETERS")
    }

    // MARK: - Configuration

    func testConfiguration_LoadsDefaultsAndValidates() {
        let config = Configuration()
        config.loadFromDefaults()
        let server = config.server
        XCTAssertFalse(server.host.isEmpty)
        XCTAssertGreaterThan(server.port, 0)
        let validation = config.validate()
        XCTAssertTrue(validation.isValid, "defaults must validate: \(validation.issues.map { $0.description })")
    }

    // MARK: - ErrorHandlingUtils + TextValidationUtils

    func testErrorHandlingUtils_CreatesTypedErrors() {
        let validation = ErrorHandlingUtils.createValidationError(message: "bad input", toolName: "test_tool")
        XCTAssertNotNil(validation)
    }

    func testTextValidationUtils_RejectsBadInput() {
        XCTAssertThrowsError(try TextValidationUtils.validateTextContent(""))
        XCTAssertNoThrow(try TextValidationUtils.validateTextContent("valid content"))
        XCTAssertThrowsError(try TextValidationUtils.validateIntParameter(5, parameterName: "n", minValue: 10, maxValue: 20))
        XCTAssertNoThrow(try TextValidationUtils.validateDoubleParameter(0.5, parameterName: "d", minValue: 0, maxValue: 1))
    }

    // MARK: - VendorNeutralAnalyzer (direct)

    func testVendorNeutralAnalyzer_PluginAnalysisAndRecommendations() {
        let target = CatalogSummarizationTool.PluginItem(
            id: "p1", name: "CompX", vendor: "AudioCo",
            tags: ["compressor", "dynamics", "glue"], description: "Glue compressor with sidechain",
            price: "$99", category: "Dynamics"
        )
        let analysis = VendorNeutralAnalyzer.analyzePluginFeatures(target)
        XCTAssertFalse(analysis.capabilities.isEmpty)

        let recommendations = VendorNeutralAnalyzer.generateRecommendations(for: target, from: [
            CatalogSummarizationTool.PluginItem(
                id: "p2", name: "CompY", vendor: "OtherCo",
                tags: ["compressor", "bus"], description: "Bus compressor",
                price: "$79", category: "Dynamics"
            ),
        ])
        XCTAssertFalse(recommendations.isEmpty)
    }

    // MARK: - Deep option paths

    func testChunking_AllStrategies() async {
        let tool = TextChunkingTool(logger: logger, securityManager: securityManager)
        let body = Array(repeating: "This sentence provides padding content for the chunk strategy under test.", count: 12).joined(separator: " ")
        for strategy in ["sentence", "paragraph", "semantic", "fixed"] {
            let response = await run(tool, ["text": body, "strategy": strategy, "max_chunk_size": 40, "min_chunk_size": 5])
            XCTAssertTrue(response.success, "chunk strategy \(strategy) failed: \(response.error?.message ?? "")")
            XCTAssertFalse(text(response).isEmpty, "strategy \(strategy) produced no chunks")
        }
    }

    func testSessionNotes_DeepOptions() async {
        let tool = SessionNotesTool(logger: logger, securityManager: securityManager)
        let content = """
        Tracking session for the new single. Recorded lead vocals on track 3 with the U87.
        Decision: keep the natural reverb. TODO: comp the bridge vocal. Used the Neve preamp.
        """
        for options in [
            ["content": content, "session_type": "tracking", "include_action_items": true],
            ["content": content, "detail_level": "detailed", "include_technical": true],
            ["content": content, "use_template": true, "template_type": "tracking"],
        ] {
            let response = await run(tool, options)
            XCTAssertTrue(response.success, "session notes failed: \(response.error?.message ?? "")")
            XCTAssertFalse(text(response).isEmpty)
        }
    }

    func testFeedbackAnalysis_DeepOptions() async {
        let tool = FeedbackAnalysisTool(logger: logger, securityManager: securityManager)
        let feedback = "Export crashes with MP3. Please fix this bug. Also add stems. Great plugin otherwise."
        for options in [
            ["feedback": feedback, "extract_action_items": true, "identify_priorities": true],
            ["feedback": feedback, "sentiment_analysis": true, "summarize_feedback": true],
        ] {
            let response = await run(tool, options)
            XCTAssertTrue(response.success, "feedback analysis failed: \(response.error?.message ?? "")")
            XCTAssertFalse(text(response).isEmpty)
        }
    }

    func testEmbeddingGeneration_Variants() async {
        let tool = EmbeddingGenerationTool(logger: logger, securityManager: securityManager)
        for options in [
            ["content": "warm analog pad", "normalize": true],
            ["content": "bright digital bell", "contentType": "text"],
        ] {
            let response = await run(tool, options)
            XCTAssertTrue(response.success, "embedding failed: \(response.error?.message ?? "")")
        }
    }
}
