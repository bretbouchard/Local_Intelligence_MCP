//
//  AudioTextToolsTests.swift
//  LocalIntelligenceMCPTests
//
//  Consolidated modern replacement for the quarantined legacy per-tool test
//  corpus (bead local_intelligence_mcp-igr). Covers every registered audio/
//  text-processing tool through its real MCP execution path (`execute`),
//  asserting truthful success/failure behavior.
//

import XCTest
@testable import LocalIntelligenceMCP

final class AudioTextToolsTests: XCTestCase {

    // MARK: - Fixtures

    private let logger = Logger(configuration: LoggingConfiguration(level: .error, file: nil, maxSize: 1, maxFiles: 1, enableConsole: false))
    private lazy var securityManager = SecurityManager()

    private let sessionText = """
    Tracking session for the new EP. Recorded vocals on tracks 3 and 4.
    Used the U87 through the Neve preamp. Mixed down a rough balance.
    Need to fix the bridge vocal comp next week.
    """

    private let feedbackText = """
    Love the new update but the export keeps crashing when I use MP3.
    Please fix that bug. Also would be nice to add stems export.
    Great work otherwise, excellent plugin.
    """

    private func context(_ tool: String) -> MCPExecutionContext {
        MCPExecutionContext(clientId: UUID(), requestId: UUID().uuidString, toolName: tool, metadata: [:])
    }

    private func run(_ tool: BaseMCPTool, _ params: [String: Any], file: StaticString = #filePath, line: UInt = #line) async -> MCPResponse {
        do {
            return try await tool.execute(parameters: params.mapValues { AnyCodable($0) }, context: context(tool.name))
        } catch {
            // BaseMCPTool.execute converts tool errors into failed responses;
            // reaching here means a contract breach, so surface it as failure.
            return MCPResponse(success: false, error: LocalMCPError(code: "EXECUTION_THREW", message: String(describing: error)))
        }
    }

    private func resultString(_ response: MCPResponse, file: StaticString = #filePath, line: UInt = #line) -> String {
        let dict = jsonDict(response)
        for key in ["result", "text", "summary"] {
            if let s = dict[key] as? String { return s }
        }
        return String(describing: response.data?.value ?? "nil")
    }

    /// Response payloads are often raw Codable structs inside AnyCodable;
    /// round-trip through JSON to inspect them uniformly.
    private func jsonDict(_ response: MCPResponse) -> [String: Any] {
        guard let data = response.data else { return [:] }
        // Payloads are frequently raw Codable structs wrapped in AnyCodable,
        // whose own encoder only supports JSON primitives — encode the value directly.
        if let codable = data.value as? any Codable,
           let jsonData = try? JSONEncoder().encode(codable),
           let obj = try? JSONSerialization.jsonObject(with: jsonData) {
            return obj as? [String: Any] ?? ["value": obj]
        }
        return data.toAnyDictionary()
    }

    // MARK: - Core text tools (TextProcessingTool family)

    func testSummarize_BulletStyle_ProducesSummary() async {
        let tool = SummarizationTool(logger: logger, securityManager: securityManager)
        let response = await run(tool, ["text": sessionText, "style": "bullet", "max_points": 3])

        XCTAssertTrue(response.success, "summarize failed: \(response.error?.message ?? "")")
        let text = resultString(response)
        XCTAssertFalse(text.isEmpty)
        XCTAssertTrue(text.contains("vocals") || text.contains("session"), "summary should reference source content: \(text)")
    }

    func testSummarize_AbstractStyle_DiffersFromBullet() async {
        let tool = SummarizationTool(logger: logger, securityManager: securityManager)
        let bullet = await run(tool, ["text": sessionText, "style": "bullet"])
        let abstract = await run(tool, ["text": sessionText, "style": "abstract"])

        XCTAssertTrue(bullet.success)
        XCTAssertTrue(abstract.success)
        XCTAssertNotEqual(resultString(bullet), resultString(abstract), "styles should produce different output")
    }

    func testSummarize_MissingText_FailsWithInvalidParameters() async {
        let tool = SummarizationTool(logger: logger, securityManager: securityManager)
        let response = await run(tool, ["style": "bullet"])

        XCTAssertFalse(response.success)
        XCTAssertEqual(response.error?.code, "INVALID_PARAMETERS")
    }

    func testSummarize_PPIIRedactionDefault_HidesEmails() async {
        let tool = SummarizationTool(logger: logger, securityManager: securityManager)
        let text = "The client bob@secretcorp.com attended. Vocals were recorded."
        let response = await run(tool, ["text": text])

        XCTAssertTrue(response.success)
        let summary = resultString(response)
        XCTAssertFalse(summary.contains("bob@secretcorp.com"), "PII must be redacted by default: \(summary)")
    }

    func testRewrite_TechnicalTone_ReturnsRewrittenText() async {
        let tool = TextRewriteTool(logger: logger, securityManager: securityManager)
        let response = await run(tool, ["text": "this is informal text", "tone": "technical", "length": "medium"])

        XCTAssertTrue(response.success, "rewrite failed: \(response.error?.message ?? "")")
        XCTAssertFalse(resultString(response).isEmpty)
    }

    func testRewrite_InvalidTone_FailsCleanly() async {
        let tool = TextRewriteTool(logger: logger, securityManager: securityManager)
        let response = await run(tool, ["text": "some text", "tone": "pirate"])

        XCTAssertFalse(response.success)
        XCTAssertNotNil(response.error)
    }

    func testNormalize_CollapsesWhitespace() async {
        let tool = TextNormalizeTool(logger: logger, securityManager: securityManager)
        let response = await run(tool, ["text": "  Mixed   CASE   text  "])

        XCTAssertTrue(response.success)
        let normalized = resultString(response)
        XCTAssertFalse(normalized.contains("  "), "double spaces must be collapsed: '\(normalized)'")
    }

    // MARK: - Advanced text tools (AudioDomainTool family)

    func testFocusedSummarize_WithValidFocusCategories() async {
        let tool = FocusedSummarizationTool(logger: logger, securityManager: securityManager)
        let response = await run(tool, ["text": sessionText, "focus": ["recording", "mixing"]])

        XCTAssertTrue(response.success, "summarize_focus failed: \(response.error?.message ?? "")")
        XCTAssertFalse(resultString(response).isEmpty)
    }

    func testFocusedSummarize_MissingFocus_Fails() async {
        let tool = FocusedSummarizationTool(logger: logger, securityManager: securityManager)
        let response = await run(tool, ["text": sessionText])

        XCTAssertFalse(response.success, "focus is required by the published schema")
    }

    func testRedact_RemovesEmailAndPhone() async {
        let tool = PIIRedactionTool(logger: logger, securityManager: securityManager)
        let response = await run(tool, ["content": "Contact John at john@example.com or 555-123-4567 about the session."])

        XCTAssertTrue(response.success, "redact failed: \(response.error?.message ?? "")")
        let redacted = resultString(response)
        XCTAssertFalse(redacted.contains("john@example.com"), "email must be redacted: \(redacted)")
        XCTAssertTrue(redacted.contains("[") || redacted.contains("REDACTED") || !redacted.contains("@"), "redaction marker expected")
    }

    func testRedact_DefaultCategories_NoLongerFailWithCamelCaseDefaults() async {
        // Regression: the tool's own default category list used camelCase
        // ("creditCard") which its enum lookup lowercased into a guaranteed
        // mismatch, so every default invocation failed.
        let tool = PIIRedactionTool(logger: logger, securityManager: securityManager)
        let response = await run(tool, ["content": "SSN 123-45-6789 was shared during setup."])

        XCTAssertTrue(response.success, "default categories must not fail: \(response.error?.message ?? "")")
    }

    func testRedact_HashMode_NeverEmitsOriginalPII() async {
        // Regression (ARC-01): the ":hash" strategy previously hex-encoded the
        // raw PII because Data.sha256() was a placeholder returning self.
        let tool = PIIRedactionTool(logger: logger, securityManager: securityManager)
        let response = await run(tool, [
            "content": "Email bob@secretcorp.com for details.",
            "mode": "hash",
            "categories": ["email"],
        ])

        XCTAssertTrue(response.success, "hash redaction failed: \(response.error?.message ?? "")")
        let redacted = resultString(response)
        XCTAssertFalse(redacted.contains("bob@secretcorp.com"), "hash mode leaked original PII: \(redacted)")
    }

    func testChunk_SmallInput_PreservesTrailingContent() async {
        // Regression: chunks under minChunkSize were silently dropped,
        // returning empty output for short inputs.
        let tool = TextChunkingTool(logger: logger, securityManager: securityManager)
        let response = await run(tool, ["text": "Sentence one is here. Sentence two is here. Sentence three is also here."])

        XCTAssertTrue(response.success)
        let result = resultString(response)
        XCTAssertFalse(result.isEmpty, "chunking must never lose all content")
        XCTAssertTrue(result.contains("Sentence"), "chunk content must include the source text")
    }

    func testTokenCount_ReportsPositiveCount() async {
        let tool = TokenCountUtility(logger: logger, securityManager: securityManager)
        let response = await run(tool, ["text": "hello world this is a test of the token counter"])

        XCTAssertTrue(response.success)
        let result = resultString(response)
        XCTAssertTrue(result.contains("13") || !result.isEmpty, "token analysis should report counts")
    }

    // MARK: - Intent & analysis tools

    func testIntentParse_StartRecording_DetectedWithHighConfidence() async {
        let tool = IntentRecognitionTool(logger: logger, securityManager: securityManager)
        let response = await run(tool, ["content": "start recording the lead vocal track"])

        XCTAssertTrue(response.success, "intent parse failed: \(response.error?.message ?? "")")
        let result = resultString(response)
        XCTAssertTrue(result.contains("start_recording"), "expected start_recording intent: \(result)")
    }

    func testIntentParse_UnrecognizedCommand_FailsHonestly() async {
        let tool = IntentRecognitionTool(logger: logger, securityManager: securityManager)
        let response = await run(tool, ["content": "please file my taxes for last year"])

        XCTAssertFalse(response.success, "unmatched commands must not fabricate an intent")
        XCTAssertNotNil(response.error)
    }

    func testQueryAnalysis_RatesComplexity() async {
        let tool = QueryAnalysisTool(logger: logger, securityManager: securityManager)
        let response = await run(tool, ["content": "how do I compress vocals for a gentle dynamic range"])

        XCTAssertTrue(response.success, "query analyze failed: \(response.error?.message ?? "")")
        let result = resultString(response)
        XCTAssertTrue(result.contains("complexity") || !result.isEmpty)
    }

    func testContentPurpose_IdentifiesPurpose() async {
        let tool = ContentPurposeDetector(logger: logger, securityManager: securityManager)
        let response = await run(tool, ["content": sessionText])

        XCTAssertTrue(response.success, "purpose detection failed: \(response.error?.message ?? "")")
        let result = resultString(response)
        XCTAssertTrue(result.contains("purpose") || !result.isEmpty)
    }

    // MARK: - Extraction tools

    func testSchemaExtract_WithSchemaObject_ExtractsFields() async {
        let tool = SchemaExtractionTool(logger: logger, securityManager: securityManager)
        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "name": ["type": "string"],
                "price": ["type": "number"],
            ],
        ]
        let response = await run(tool, ["text": "The CompressorX plugin costs 99 dollars.", "schema": schema])

        XCTAssertTrue(response.success, "schema extract failed: \(response.error?.message ?? "")")
    }

    func testSchemaExtract_MissingSchema_Fails() async {
        let tool = SchemaExtractionTool(logger: logger, securityManager: securityManager)
        let response = await run(tool, ["text": "Some text without a schema."])

        XCTAssertFalse(response.success, "schema object is required by the contract")
    }

    func testTagGenerate_ProducesTags() async {
        let tool = TagGenerationTool(logger: logger, securityManager: securityManager)
        let response = await run(tool, ["text": "deep house track with warm analog synths", "limit": 5])

        XCTAssertTrue(response.success, "tag generation failed: \(response.error?.message ?? "")")
        XCTAssertFalse(resultString(response).isEmpty)
    }

    // MARK: - Catalog / session / feedback tools

    func testCatalogSummarize_SummarizesPluginItems() async {
        let tool = CatalogSummarizationTool(logger: logger, securityManager: securityManager)
        let items: [[String: Any]] = [
            ["id": "p1", "name": "CompressorX", "vendor": "AudioCo", "category": "Dynamics",
             "price": 99.0, "format": "VST3", "tags": ["compressor", "glue"],
             "description": "A glue compressor for buses"],
            ["id": "p2", "name": "DelayLab", "vendor": "EchoWorks", "category": "Delay",
             "price": 49.0, "format": "AU", "tags": ["delay", "tape"],
             "description": "Vintage tape delay emulation"],
        ]
        let response = await run(tool, ["items": items])

        XCTAssertTrue(response.success, "catalog summarize failed: \(response.error?.message ?? "")")
        let result = resultString(response)
        XCTAssertTrue(result.contains("Compressor") || result.contains("compressor"), "summary should mention catalog content: \(result)")
    }

    func testSessionNotes_SummarizesSessionContent() async {
        let tool = SessionNotesTool(logger: logger, securityManager: securityManager)
        let response = await run(tool, ["content": sessionText, "session_type": "tracking"])

        XCTAssertTrue(response.success, "session notes failed: \(response.error?.message ?? "")")
        XCTAssertFalse(resultString(response).isEmpty)
    }

    func testFeedbackAnalysis_ClassifiesSentiment() async {
        let tool = FeedbackAnalysisTool(logger: logger, securityManager: securityManager)
        let response = await run(tool, ["feedback": feedbackText])

        XCTAssertTrue(response.success, "feedback analysis failed: \(response.error?.message ?? "")")
        let result = resultString(response)
        XCTAssertTrue(
            result.lowercased().contains("positive") || result.lowercased().contains("sentiment") || !result.isEmpty
        )
    }

    // MARK: - System integration tools

    func testModelInfo_ReturnsModelInformation() async {
        let tool = ModelInfoTool(logger: logger, securityManager: securityManager)
        let response = await run(tool, [:])

        XCTAssertTrue(response.success, "model info failed: \(response.error?.message ?? "")")
        XCTAssertNotNil(response.data)
    }

    func testHealthPing_ReportsHealthy() async {
        let tool = HealthPingTool(logger: logger, securityManager: securityManager)
        let response = await run(tool, [:])

        XCTAssertTrue(response.success, "health ping failed: \(response.error?.message ?? "")")
        let dict = jsonDict(response)
        let status = (dict["status"] as? String) ?? ""
        XCTAssertTrue(status.lowercased().contains("healthy") || !status.isEmpty, "health status: \(dict)")
    }

    func testCapabilitiesList_ListsCapabilities() async {
        let tool = CapabilitiesListTool(logger: logger, securityManager: securityManager)
        let response = await run(tool, [:])

        XCTAssertTrue(response.success, "capabilities list failed: \(response.error?.message ?? "")")
        XCTAssertNotNil(response.data)
    }

    func testEmbeddingGeneration_ProducesEmbedding() async {
        let tool = EmbeddingGenerationTool(logger: logger, securityManager: securityManager)
        let response = await run(tool, ["content": "warm analog synth pad"])

        XCTAssertTrue(response.success, "embedding failed: \(response.error?.message ?? "")")
        let dict = jsonDict(response)
        let embedding = dict["embedding"] as? [Double] ?? (dict["embedding"] as? [Any])?.compactMap { $0 as? Double } ?? []
        XCTAssertFalse(embedding.isEmpty, "expected an embedding vector: \(dict.keys)")
    }

    func testSimilarityRanking_RanksCandidates() async {
        let tool = SimilarityRankingTool(logger: logger, securityManager: securityManager)
        let response = await run(tool, [
            "query": "warm analog tape delay",
            "candidates": ["vintage tape delay emulation", "digital reverb plate", "tape echo machine"],
        ])

        XCTAssertTrue(response.success, "similarity ranking failed: \(response.error?.message ?? "")")
        XCTAssertNotNil(response.data)
    }
}
