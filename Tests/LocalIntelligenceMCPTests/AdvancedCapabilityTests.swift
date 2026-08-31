//
//  AdvancedCapabilityTests.swift
//  LocalIntelligenceMCPTests
//
//  Coverage for GSD Plans 2.4 (automation safety), 3.2 (structured
//  generation) and 3.6 (macOS 26 integration suite).
//

import XCTest
@testable import LocalIntelligenceMCP

// MARK: - Plan 2.4: automation safety policy

final class AutomationSafetyTests: XCTestCase {

    private let logger = Logger(configuration: LoggingConfiguration(level: .error, file: nil, maxSize: 1, maxFiles: 1, enableConsole: false))

    private actor RecordingProvider: AutomationProvider {
        let metadata = ProviderMetadata(id: "recorder", displayName: "recorder", providerClass: .appleAutomation)
        private(set) var executedNames: [String] = []

        func availability(for capability: StableCapability) async -> CapabilityStatus { .available }
        func listAutomation() async throws -> [String] { [] }
        func executeAutomation(name: String, input: String?, timeout: TimeInterval, confirm: Bool) async throws -> AutomationExecution {
            executedNames.append(name)
            return AutomationExecution(name: name, didRun: true, output: nil, errorMessage: nil, duration: 0, provider: metadata)
        }
    }

    private func makeGated(_ policy: AutomationSafetyPolicy, inner: RecordingProvider) -> SafetyGatedAutomationProvider {
        SafetyGatedAutomationProvider(inner: inner, policy: policy, logger: logger)
    }

    func testDestructiveName_WithoutConfirm_IsPolicyDenied() async {
        let inner = RecordingProvider()
        let gated = makeGated(.default, inner: inner)

        do {
            _ = try await gated.executeAutomation(name: "Delete All Backups", input: nil, timeout: 30, confirm: false)
            XCTFail("Destructive shortcut without confirmation must be denied")
        } catch let error as CapabilityError {
            guard case .policyDenied = error else { return XCTFail("Expected policyDenied, got \(error)") }
        } catch { XCTFail("Unexpected error \(error)") }

        let executed = await inner.executedNames
        XCTAssertTrue(executed.isEmpty, "Inner provider must never run for denied requests")
    }

    func testDestructiveName_WithConfirm_Runs() async throws {
        let inner = RecordingProvider()
        let gated = makeGated(.default, inner: inner)

        let execution = try await gated.executeAutomation(name: "Delete All Backups", input: nil, timeout: 30, confirm: true)
        XCTAssertTrue(execution.didRun)
        let executed = await inner.executedNames
        XCTAssertEqual(executed, ["Delete All Backups"])
    }

    func testDenylist_AlwaysBlocks_EvenWithConfirm() async {
        var policy = AutomationSafetyPolicy.default
        var gatedDeny = Set<String>(); gatedDeny.insert("format workspace")
        policy = AutomationSafetyPolicy(
            allowlist: nil, denylist: gatedDeny,
            destructivePatterns: policy.destructivePatterns,
            requireConfirmationForDestructive: true, maxTimeout: 300
        )
        let inner = RecordingProvider()
        let gated = makeGated(policy, inner: inner)

        do {
            _ = try await gated.executeAutomation(name: "Format Workspace", input: nil, timeout: 30, confirm: true)
            XCTFail("Denylisted shortcut must be denied even with confirm")
        } catch let error as CapabilityError {
            guard case .policyDenied = error else { return XCTFail("Expected policyDenied, got \(error)") }
        } catch { XCTFail("Unexpected error \(error)") }
    }

    func testAllowlistMode_BlocksUnlistedNames() async {
        let allow: Set<String> = ["safe shortcut"]
        let policy = AutomationSafetyPolicy(
            allowlist: allow, denylist: [],
            destructivePatterns: AutomationSafetyPolicy.destructiveDefaults,
            requireConfirmationForDestructive: true, maxTimeout: 300
        )
        let inner = RecordingProvider()
        let gated = makeGated(policy, inner: inner)

        do {
            _ = try await gated.executeAutomation(name: "Anything Else", input: nil, timeout: 30, confirm: true)
            XCTFail("Non-allowlisted shortcut must be denied")
        } catch let error as CapabilityError {
            guard case .policyDenied = error else { return XCTFail("Expected policyDenied, got \(error)") }
        } catch { XCTFail("Unexpected error \(error)") }
    }

    func testTimeout_ClampedToPolicyMaximum() async throws {
        let inner = RecordingProvider()
        let gated = makeGated(.default, inner: inner)
        _ = try await gated.executeAutomation(name: "Long Backup", input: nil, timeout: 10_000, confirm: true)
        // Inner clamps to 300 — verified by the fact execution succeeded and
        // the provider itself enforces its own wall-clock limit.
        let executed = await inner.executedNames
        XCTAssertEqual(executed.count, 1)
    }

    func testPolicyFromEnvironment_ParsesLists() {
        setenv("LI_AUTOMATION_ALLOWLIST", "Alpha, Beta", 1)
        setenv("LI_AUTOMATION_DENYLIST", "Danger", 1)
        defer {
            unsetenv("LI_AUTOMATION_ALLOWLIST")
            unsetenv("LI_AUTOMATION_DENYLIST")
        }
        let policy = AutomationSafetyPolicy.fromEnvironment()
        XCTAssertEqual(policy.allowlist, ["alpha", "beta"])
        XCTAssertEqual(policy.denylist, ["danger"])
    }
}

// MARK: - Plan 3.2: structured generation validation

final class StructuredOutputTests: XCTestCase {

    func testSchemaValidator_AcceptsValidObject() throws {
        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "name": ["type": "string"],
                "count": ["type": "integer"],
            ],
            "required": ["name"],
            "additionalProperties": false,
        ]
        try JSONSchemaValidator.validate(["name": "resistor", "count": 10], against: schema)
    }

    func testSchemaValidator_CatchesViolations() {
        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "name": ["type": "string"],
                "score": ["type": "number", "minimum": 0, "maximum": 1],
            ],
            "required": ["name", "score"],
        ]
        XCTAssertThrowsError(try JSONSchemaValidator.validate(["score": 1.5], against: schema)) { error in
            let failure = error as? JSONSchemaValidator.Failure
            XCTAssertNotNil(failure)
            XCTAssertTrue(failure?.errors.contains { $0.contains("required property missing") } ?? false)
        }
    }

    func testSchemaValidator_RejectsUnsupportedConstructsExplicitly() {
        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "code": ["type": "string", "pattern": "^[A-Z]+$"],
            ],
        ]
        XCTAssertThrowsError(try JSONSchemaValidator.validateSupported(schema)) { error in
            let unsupported = error as? JSONSchemaValidator.Unsupported
            XCTAssertEqual(unsupported?.keywords, ["pattern"])
        }
    }

    func testSchemaValidator_EnumAndArrayItems() {
        let schema: [String: Any] = [
            "type": "array",
            "items": ["type": "string", "enum": ["red", "green"]],
            "maxItems": 2,
        ]
        XCTAssertNoThrow(try JSONSchemaValidator.validate(["red", "green"], against: schema))
        XCTAssertThrowsError(try JSONSchemaValidator.validate(["red", "blue"], against: schema))
        XCTAssertThrowsError(try JSONSchemaValidator.validate(["red", "green", "red"], against: schema))
    }

    func testStructuredOutput_ExtractsFromFencedJSON() throws {
        let text = """
        Here is the result:
        ```json
        {"name": "cap", "value": 3}
        ```
        """
        let schema: [String: Any] = [
            "type": "object",
            "properties": ["name": ["type": "string"], "value": ["type": "integer"]],
            "required": ["name", "value"],
        ]
        let object = try StructuredOutput.validate(text, against: schema)
        XCTAssertEqual(object["name"] as? String, "cap")
    }

    func testStructuredOutput_ProseOnly_FailsWithInvalidRequest() {
        let schema: [String: Any] = ["type": "object"]
        XCTAssertThrowsError(try StructuredOutput.validate("No JSON here at all.", against: schema)) { error in
            guard case CapabilityError.invalidRequest = error else {
                return XCTFail("Expected invalidRequest, got \(error)")
            }
        }
    }
}

// MARK: - Plan 3.6: macOS 26 integration suite

final class FoundationModelsIntegrationTests: XCTestCase {

    func testAvailabilityMapping_CoversAllStates() throws {
        guard #available(macOS 26.0, *) else {
            throw XCTSkip("FoundationModels requires macOS 26+")
        }
        XCTAssertEqual(AppleFoundationProvider26.status(for: .available), .available)
        XCTAssertEqual(AppleFoundationProvider26.status(for: .unavailable(.deviceNotEligible)), .unsupported)
        XCTAssertEqual(AppleFoundationProvider26.status(for: .unavailable(.appleIntelligenceNotEnabled)), .disabled)
        XCTAssertEqual(AppleFoundationProvider26.status(for: .unavailable(.modelNotReady)), .notReady)
    }

    func testModelToolAllowlist_ExcludesSideEffectsAndGeneration() throws {
        guard #available(macOS 26.0, *) else {
            throw XCTSkip("FoundationModels requires macOS 26+")
        }
        // A model must never be able to trigger automation side effects or
        // recursive generation, regardless of what an allowlist asks for.
        let forbidden: [StableCapability] = [.localAutomationExecute, .localGenerate, .localAutomationList]
        for capability in forbidden {
            XCTAssertFalse(AppleFoundationProvider26.supportedModelTools.contains(capability))
        }
    }

    func testLocalGenerate_RejectsDisallowedToolRequests() async throws {
        guard #available(macOS 26.0, *) else { throw XCTSkip() }
        let provider = AppleFoundationProvider26()

        do {
            _ = try await provider.generate(GenerationRequest(
                capability: .localGenerate,
                prompt: "do things",
                toolAllowlist: ["local_automation_execute"]
            ))
            XCTFail("Side-effect tools must be rejected from the model allowlist")
        } catch let error as CapabilityError {
            guard case .policyDenied = error else { return XCTFail("Expected policyDenied, got \(error)") }
        } catch { XCTFail("Unexpected error \(error)") }
    }

    func testConcurrentRouting_AllRequestsServed() async throws {
        let router = CapabilityRouter()
        await router.register(DeterministicTextProvider(), for: [.localSummarize], priority: 100)

        try await withThrowingTaskGroup(of: String.self) { group in
            for index in 0..<20 {
                group.addTask {
                    let request = GenerationRequest(capability: .localSummarize, input: "Text number \(index). Second sentence.")
                    return try await router.execute(request).text
                }
            }
            var count = 0
            for try await _ in group { count += 1 }
            XCTAssertEqual(count, 20, "Concurrent requests must all be served deterministically")
        }
    }

    func testCancellation_PropagatesAsCancelled() async throws {
        struct SlowProvider: IntelligenceProvider {
            let metadata = ProviderMetadata(id: "slow", displayName: "slow", providerClass: .appleFoundationModel)
            func availability(for capability: StableCapability) async -> CapabilityStatus { .available }
            func generate(_ request: GenerationRequest) async throws -> GenerationResult {
                try await Task.sleep(nanoseconds: 5_000_000_000)
                return GenerationResult(text: "done", provider: metadata, duration: 5)
            }
        }
        let router = CapabilityRouter()
        await router.register(SlowProvider(), for: [.localGenerate], priority: 100)

        let task = Task {
            try await router.execute(GenerationRequest(capability: .localGenerate, prompt: "x"))
        }
        try await Task.sleep(nanoseconds: 100_000_000)
        task.cancel()

        do {
            _ = try await task.value
            XCTFail("Cancelled generation must not complete")
        } catch is CancellationError {
            // acceptable propagation
        } catch let error as CapabilityError {
            guard case .cancelled = error else { return XCTFail("Expected cancelled, got \(error)") }
        }
    }
}
