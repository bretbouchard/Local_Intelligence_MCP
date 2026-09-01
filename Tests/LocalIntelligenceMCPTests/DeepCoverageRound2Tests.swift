//
//  DeepCoverageRound2Tests.swift
//  LocalIntelligenceMCPTests
//
//  Coverage push round 2: option-matrix paths across the audio/text tools —
//  every enum value, flag, and analyzer branch that round 1 did not reach.
//

import XCTest
@testable import LocalIntelligenceMCP

final class DeepCoverageRound2Tests: XCTestCase {

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

    private let sessionBody = """
    Mixing session for the debut EP. Printed the vocal chain through the 1073.
    Decision: automate the chorus level ride. TODO: print alternate guitar take.
    Client approved the low-end approach on the second listen.
    """

    // MARK: - Session notes: remaining session types, depths, focus areas

    func testSessionNotes_SessionTypesAndDepths() async {
        let tool = SessionNotesTool(logger: logger, securityManager: securityManager)
        for options in [
            ["session_type": "mixing", "detail_level": "brief"],
            ["session_type": "mastering", "detail_level": "comprehensive"],
            ["session_type": "general", "focus_areas": ["mixing", "production"] as [String]],
            ["session_type": "tracking", "duration_estimate": 90.0, "include_technical": true],
        ] {
            var params = options
            params["content"] = sessionBody
            let response = await run(tool, params)
            XCTAssertTrue(response.success, "session notes \(options) failed: \(response.error?.message ?? "")")
            XCTAssertFalse(text(response).isEmpty)
        }
    }

    // MARK: - Feedback analysis: types, project context, template variants

    func testFeedbackAnalysis_TypesAndContext() async {
        let tool = FeedbackAnalysisTool(logger: logger, securityManager: securityManager)
        let feedback = "The compressor sounds fantastic but the installer fails on Windows. Please fix."
        for options in [
            ["feedback_type": "bug"],
            ["feedback_type": "feature"],
            ["feedback_type": "general"],
            ["project_context": "desktop plugin suite"],
            ["use_template": true, "template_type": "general"],
        ] {
            var params = options
            params["feedback"] = feedback
            let response = await run(tool, params)
            XCTAssertTrue(response.success, "feedback \(options) failed: \(response.error?.message ?? "")")
        }
    }

    // MARK: - Catalog summarization: clustering, vendor analysis, recommendations

    func testCatalogSummarize_ClustersVendorAndRecommendations() async {
        let tool = CatalogSummarizationTool(logger: logger, securityManager: securityManager)
        let items: [[String: Any]] = [
            ["id": "p1", "name": "CompX", "vendor": "AudioCo", "category": "Dynamics",
             "price": "$99", "tags": ["compressor"], "description": "Glue compressor with sidechain filter"],
            ["id": "p2", "name": "CompY", "vendor": "AudioCo", "category": "Dynamics",
             "price": "$79", "tags": ["compressor", "bus"], "description": "Bus compressor, parallel dry path"],
            ["id": "p3", "name": "DelayLab", "vendor": "EchoWorks", "category": "Delay",
             "price": "$49", "tags": ["delay", "tape"], "description": "Vintage tape delay emulation"],
        ]
        for options in [
            ["items": items, "vendor_analysis": true, "grouping": "vendor"],
            ["items": items, "include_clusters": true, "summary_length": "detailed"],
            ["items": items, "recommend_alternatives": true, "max_overviews": 2],
            ["items": items, "focus": "pricing"],
        ] {
            let response = await run(tool, options)
            XCTAssertTrue(response.success, "catalog \(options.keys) failed: \(response.error?.message ?? "")")
            XCTAssertFalse(text(response).isEmpty)
        }
    }

    // MARK: - Embedding generation: content types and metadata

    func testEmbeddingGeneration_MetadataAndModelVariants() async {
        let tool = EmbeddingGenerationTool(logger: logger, securityManager: securityManager)
        for options in [
            ["content": "tape saturation warmth", "metadata": ["source": "test"] as [String: String]],
            ["content": "sub bass drone", "normalize": false],
        ] {
            let response = await run(tool, options)
            XCTAssertTrue(response.success, "embedding \(options.keys) failed: \(response.error?.message ?? "")")
        }
    }

    // MARK: - Text chunking: audio_session strategy, overlap, metadata

    func testChunking_AudioSessionStrategyAndOverlap() async {
        let tool = TextChunkingTool(logger: logger, securityManager: securityManager)
        let body = """
        [00:00] Session start. We set the headphone mix first.
        [00:10] Vocal take one, the chorus felt rushed.
        [00:30] Playback with the band, agreement on the arrangement.
        """
        for options in [
            ["text": body, "strategy": "audio_session", "min_chunk_size": 1],
            ["text": body, "strategy": "sentence", "overlap": 3, "include_metadata": true],
            ["text": body, "strategy": "paragraph", "preserve_audio_structure": true, "min_chunk_size": 1],
        ] {
            let response = await run(tool, options)
            XCTAssertTrue(response.success, "chunking \(options["strategy"] ?? "?") failed: \(response.error?.message ?? "")")
            XCTAssertFalse(text(response).isEmpty)
        }
    }

    // MARK: - Similarity ranking: methods, thresholds, details

    func testSimilarityRanking_RankingMethodsAndThresholds() async {
        let tool = SimilarityRankingTool(logger: logger, securityManager: securityManager)
        let candidates = ["tape delay emulation", "plate reverb", "digital delay with modulation"]
        for options in [
            ["query": "warm tape delay", "candidates": candidates, "rankingMethod": "euclidean"],
            ["query": "warm tape delay", "candidates": candidates, "rankingMethod": "jaccard"],
            ["query": "warm tape delay", "candidates": candidates, "rankingMethod": "weighted", "includeDetails": true],
            ["query": "warm tape delay", "candidates": candidates, "threshold": 0.9, "maxResults": 1],
        ] {
            let response = await run(tool, options)
            XCTAssertTrue(response.success, "similarity \(options["rankingMethod"] ?? "?") failed: \(response.error?.message ?? "")")
        }
    }

    // MARK: - PII redaction: every mode, sensitivities, whitelist

    func testPIIRedaction_AllModes() async {
        let tool = PIIRedactionTool(logger: logger, securityManager: securityManager)
        let content = "Call jane.doe@example.com or 555-867-5309 regarding invoice 4111-1111-1111-1111."
        for mode in ["replace", "mask", "remove"] {
            let response = await run(tool, ["content": content, "mode": mode])
            XCTAssertTrue(response.success, "redact mode \(mode) failed: \(response.error?.message ?? "")")
            XCTAssertFalse(text(response).contains("@example.com"), "mode \(mode) left the email behind")
        }
    }

    func testPIIRedaction_SensitivityAndWhitelist() async {
        let tool = PIIRedactionTool(logger: logger, securityManager: securityManager)
        let high = await run(tool, ["content": "Reach jane.doe@example.com.", "sensitivity": "high", "mode": "hash"])
        XCTAssertTrue(high.success)
        let whitelisted = await run(tool, [
            "content": "Contact support@example.com.",
            "whitelist": ["support@example.com"],
        ])
        XCTAssertTrue(whitelisted.success, "whitelisted redaction failed: \(whitelisted.error?.message ?? "")")
    }

    // MARK: - Text rewrite: every tone

    func testRewrite_AllTones() async {
        let tool = TextRewriteTool(logger: logger, securityManager: securityManager)
        for tone in ["technical", "friendly", "neutral", "executive"] {
            for length in ["short", "medium", "long"] {
                let response = await run(tool, ["text": "this text needs a different voice", "tone": tone, "length": length])
                XCTAssertTrue(response.success, "rewrite tone=\(tone) length=\(length) failed: \(response.error?.message ?? "")")
            }
        }
    }

    // MARK: - Intent recognition: confidence, alternatives, allowed lists

    func testIntentParse_ThresholdsAndAlternatives() async {
        let tool = IntentRecognitionTool(logger: logger, securityManager: securityManager)
        let low = await run(tool, ["content": "apply eq to the vocals with a boost at 3k", "confidence_threshold": 0.1])
        XCTAssertTrue(low.success, "low-threshold intent parse failed: \(low.error?.message ?? "")")

        let restricted = await run(tool, [
            "content": "start recording the lead vocal track",
            "allowed": ["start_recording"],
        ])
        XCTAssertTrue(restricted.success)

        let alternatives = await run(tool, [
            "content": "stop recording now",
            "include_alternatives": true,
            "extract_context": true,
        ])
        XCTAssertTrue(alternatives.success)
    }

    // MARK: - Token counting: breakdown, strategies, content types

    func testTokenCount_BreakdownAndStrategies() async {
        let tool = TokenCountUtility(logger: logger, securityManager: securityManager)
        let body = Array(repeating: "count these tokens for the analysis path", count: 6).joined(separator: " ")
        for options in [
            ["text": body, "include_breakdown": true],
            ["text": body, "content_type": "transcript"],
            ["text": body, "chunk_size": 20, "chunk_analysis": true],
        ] {
            let response = await run(tool, options)
            XCTAssertTrue(response.success, "token count \(options) failed: \(response.error?.message ?? "")")
        }
    }
}
