//
//  WireLevelTests.swift
//  LocalIntelligenceMCPTests
//
//  TEST-01: exercises StartCommand.handleToolCall — the actual MCP wire
//  boundary — where argument conversion, permission verification, and error
//  surfacing live. Regression coverage for council findings SEC-01/SEC-02.
//

import XCTest
import MCP
@testable import LocalIntelligenceMCP

final class WireLevelTests: XCTestCase {

    private var registry: ToolsRegistry!

    override func setUp() async throws {
        let logger = Logger(configuration: LoggingConfiguration(level: .error, file: nil, maxSize: 1, maxFiles: 1, enableConsole: false))
        registry = ToolsRegistry(logger: logger, securityManager: SecurityManager())
        try await registry.initialize()
    }

    private func call(_ tool: String, _ args: [String: Value]) async -> CallTool.Result {
        await StartCommand.handleToolCall(name: tool, arguments: args, toolsRegistry: registry)
    }

    private func text(_ result: CallTool.Result) -> String {
        result.content.compactMap { content -> String? in
            if case .text(let t) = content { return t.text }
            return nil
        }.joined()
    }

    private var errored: (CallTool.Result) -> Bool { { $0.isError == true } }

    // MARK: SEC-01 regression: nested arguments must survive the boundary

    func testNestedArguments_SurviveConversion() async throws {
        // responseSchema contains a nested object; if the boundary flattened
        // nested structures to strings, the validator would never see
        // "unsupported_keyword" and the call shape would degrade silently.
        let result = await call("local_generate", [
            "prompt": .string("irrelevant"),
            "responseSchema": .object([
                "type": .string("object"),
                "properties": .object([
                    "code": .object(["type": .string("string"), "pattern": .string("^[A-Z]+$")]),
                ]),
            ]),
        ])

        XCTAssertTrue(errored(result))
        let payload = text(result)
        XCTAssertTrue(payload.contains("Unsupported JSON Schema"), "nested schema must reach the validator verbatim: \(payload)")
    }

    func testNestedArrayArguments_SurviveConversion() async throws {
        // apple_tags_generate takes text + limit; a nested-array case is
        // exercised via local_generate's tools allowlist (array of strings).
        let result = await call("local_generate", [
            "prompt": .string("irrelevant"),
            "tools": .array([.string("local_automation_execute")]),
        ])

        guard #available(macOS 26.0, *) else {
            // On portable tiers the router fails earlier — still must not crash.
            XCTAssertTrue(errored(result) || !text(result).isEmpty)
            return
        }
        XCTAssertTrue(errored(result), "side-effect tools must be rejected from the model allowlist")
        XCTAssertTrue(text(result).contains("POLICY_DENIED"), "got: \(text(result))")
    }

    // MARK: SEC-02 regression: hostile timeout values cannot trap

    func testNegativeTimeout_RejectedNotCrash() async {
        let result = await call("local_generate", [
            "prompt": .string("x"),
            "timeout": .double(-1),
        ])

        XCTAssertTrue(errored(result), "negative timeout must fail cleanly")
        XCTAssertTrue(text(result).contains("1 and 600"), "got: \(text(result))")
    }

    func testHugeTimeout_RejectedNotCrash() async {
        let result = await call("local_generate", [
            "prompt": .string("x"),
            "timeout": .double(1e308),
        ])

        XCTAssertTrue(errored(result), "overflow timeout must fail cleanly")
        XCTAssertTrue(text(result).contains("1 and 600"), "got: \(text(result))")
    }

    func testWrongTypeTimeout_RejectedNotCrash() async {
        let result = await call("local_automation_execute", [
            "name": .string("Anything At All"),
            "timeout": .string("not a number"),
        ])

        XCTAssertTrue(errored(result) || !text(result).isEmpty, "wrong-typed timeout must not trap the process")
    }

    // MARK: error envelopes surface verbatim (SEC-01 follow-on)

    func testErrorEnvelope_SurfacesStableCode() async {
        let result = await call("voice_command", ["command": .string("open Safari")])

        XCTAssertTrue(errored(result))
        XCTAssertTrue(text(result).contains("UNSUPPORTED"), "got: \(text(result))")
    }

    func testLongText_Above10k_Processes() async {
        // NEW-01 regression: the registry's parameter-length cap (now 50k)
        // must not reject the long documents the audio/text tools advertise.
        let longText = String(repeating: "Sentence for the long-document path. ", count: 400) // ~15.6k chars
        let result = await call("local_summarize", [
            "text": .string(longText),
            "sentenceLimit": .int(3),
        ])

        XCTAssertTrue((result.isError ?? false) == false, "long text must be accepted: \(text(result))")
    }

    func testTypelessEnumSchema_ReachesValidator() async throws {
        // GAP-01: enum-only schemas (no "type") validate via the enum check.
        let result = await call("local_generate", [
            "prompt": .string("irrelevant"),
            "responseSchema": .object([
                "enum": .array([.string("red"), .string("green")]),
            ]),
        ])

        // The contract: an enum-only schema is IN-subset, so the failure must
        // never be about unsupported schema constructs — any later failure
        // (e.g. the model's output not parsing as JSON) is fine.
        XCTAssertFalse(text(result).contains("Unsupported JSON Schema"),
                       "enum-only schema must pass the supported-subset check: \(text(result))")
    }

    func testNullArguments_RoundTrip() async {
        // NSNull arguments must neither crash nor corrupt the envelope.
        let result = await call("local_generate", [
            "prompt": .string("x"),
            "input": .null,
        ])

        // On macOS 26+ with the model available this may even succeed; the
        // contract under test is only that null handling does not trap.
        _ = errored(result)
    }
}
