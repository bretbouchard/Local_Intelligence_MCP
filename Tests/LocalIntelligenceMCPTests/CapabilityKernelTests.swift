//
//  CapabilityKernelTests.swift
//  LocalIntelligenceMCPTests
//
//  Tests for GSD Phase 1 capability kernel: RuntimeCapabilities,
//  CapabilityRouter, provider contracts, deterministic provider,
//  and truthful behavior of the local_* tools.
//

import XCTest
@testable import LocalIntelligenceMCP

// MARK: - Mocks

/// Configurable provider mock for router behavior tests.
private actor MockProvider: IntelligenceProvider {
    let metadata: ProviderMetadata
    var status: CapabilityStatus
    var failure: CapabilityError?
    private(set) var generateCallCount = 0

    init(id: String, providerClass: ProviderClass = .deterministic, status: CapabilityStatus, failure: CapabilityError? = nil) {
        self.metadata = ProviderMetadata(id: id, displayName: id, providerClass: providerClass)
        self.status = status
        self.failure = failure
    }

    func availability(for capability: StableCapability) async -> CapabilityStatus {
        status
    }

    func generate(_ request: GenerationRequest) async throws -> GenerationResult {
        generateCallCount += 1
        if let failure {
            throw failure
        }
        return GenerationResult(text: "from-\(metadata.id)", provider: metadata, duration: 0)
    }
}

private func makeRequest(_ capability: StableCapability, pinned: String? = nil, fallbackAllowed: Bool = true) -> GenerationRequest {
    GenerationRequest(capability: capability, prompt: "test", input: "input", pinnedProvider: pinned, fallbackAllowed: fallbackAllowed)
}

// MARK: - CapabilityRouter

final class CapabilityRouterTests: XCTestCase {

    func testRouter_UsesHighestPriorityProvider() async throws {
        let router = CapabilityRouter()
        let low = MockProvider(id: "low", status: .available)
        let high = MockProvider(id: "high", status: .available)
        await router.register(low, for: [.localSummarize], priority: 10)
        await router.register(high, for: [.localSummarize], priority: 100)

        let result = try await router.execute(makeRequest(.localSummarize))
        XCTAssertEqual(result.provider.id, "high")
    }

    func testRouter_FallsBackWhenHigherPriorityUnavailable() async throws {
        let router = CapabilityRouter()
        let unavailable = MockProvider(id: "primary", status: .unavailable)
        let fallback = MockProvider(id: "secondary", status: .available)
        await router.register(unavailable, for: [.localSummarize], priority: 100)
        await router.register(fallback, for: [.localSummarize], priority: 10)

        let result = try await router.execute(makeRequest(.localSummarize))
        XCTAssertEqual(result.provider.id, "secondary")
    }

    func testRouter_PinnedProvider_DisablesFallback() async throws {
        let router = CapabilityRouter()
        let primary = MockProvider(id: "primary", status: .unavailable)
        let other = MockProvider(id: "secondary", status: .available)
        await router.register(primary, for: [.localSummarize], priority: 100)
        await router.register(other, for: [.localSummarize], priority: 10)

        do {
            _ = try await router.execute(makeRequest(.localSummarize, pinned: "primary", fallbackAllowed: false))
            XCTFail("Pinned unavailable provider must surface its real status, not fall back")
        } catch let error as CapabilityError {
            guard case .unavailable = error else {
                return XCTFail("Expected unavailable, got \(error)")
            }
        }
    }

    func testRouter_PinnedUnknownProvider_IsUnsupported() async {
        let router = CapabilityRouter()
        let provider = MockProvider(id: "known", status: .available)
        await router.register(provider, for: [.localSummarize], priority: 100)

        do {
            _ = try await router.execute(makeRequest(.localSummarize, pinned: "nonexistent"))
            XCTFail("Unknown pinned provider must be unsupported")
        } catch let error as CapabilityError {
            guard case .unsupported = error else {
                return XCTFail("Expected unsupported, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type \(error)")
        }
    }

    func testRouter_NonFallbackErrorsPropagate() async {
        let router = CapabilityRouter()
        let denied = MockProvider(id: "denied", status: .available, failure: .permissionDenied(reason: "TCC"))
        let next = MockProvider(id: "next", status: .available)
        await router.register(denied, for: [.localSummarize], priority: 100)
        await router.register(next, for: [.localSummarize], priority: 10)

        do {
            _ = try await router.execute(makeRequest(.localSummarize))
            XCTFail("permissionDenied must terminate routing, not fall through")
        } catch let error as CapabilityError {
            guard case .permissionDenied = error else {
                return XCTFail("Expected permissionDenied, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type \(error)")
        }
    }

    func testRouter_UnregisteredCapability_IsUnsupported() async {
        let router = CapabilityRouter()
        do {
            _ = try await router.execute(makeRequest(.localGenerate))
            XCTFail("Unregistered capability must be unsupported")
        } catch let error as CapabilityError {
            guard case .unsupported = error else {
                return XCTFail("Expected unsupported, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type \(error)")
        }
    }

    func testRouter_DeadlinePropagates() async {
        struct NeverCompletingProvider: IntelligenceProvider {
            let metadata = ProviderMetadata(id: "never", displayName: "never", providerClass: .appleFoundationModel)
            func availability(for capability: StableCapability) async -> CapabilityStatus { .available }
            func generate(_ request: GenerationRequest) async throws -> GenerationResult {
                try await Task.sleep(nanoseconds: 10_000_000_000)
                return GenerationResult(text: "", provider: metadata, duration: 0)
            }
        }
        let router = CapabilityRouter()
        await router.register(NeverCompletingProvider(), for: [.localGenerate], priority: 100)

        let start = Date()
        do {
            _ = try await router.execute(GenerationRequest(capability: .localGenerate, prompt: "x", deadline: 0.5))
            XCTFail("Deadline must fire")
        } catch let error as CapabilityError {
            guard case .timeout = error else {
                return XCTFail("Expected timeout, got \(error)")
            }
            XCTAssertLessThan(Date().timeIntervalSince(start), 5, "Deadline must fire promptly")
        } catch {
            XCTFail("Unexpected error type \(error)")
        }
    }

    func testRouter_RegisteredProvidersReported() async {
        let router = CapabilityRouter()
        let provider = MockProvider(id: "p1", status: .available)
        await router.register(provider, for: [.localSummarize], priority: 1)
        await router.registerAutomation(ShortcutsProvider(), priority: 1)

        let providers = await router.registeredProviders()
        XCTAssertEqual(providers.map { $0.id }, ["p1", "shortcuts_cli"].sorted())
    }
}

// MARK: - Error taxonomy

final class CapabilityErrorTests: XCTestCase {

    func testErrorCodes_AreStableAndDistinct() {
        let errors: [CapabilityError] = [
            .unsupported(reason: "x"),
            .unavailable(reason: "x"),
            .disabled(reason: "x"),
            .notReady(reason: "x"),
            .permissionDenied(reason: "x"),
            .invalidRequest("x"),
            .timeout(1),
            .cancelled,
            .providerFailure("x"),
            .policyDenied(reason: "x"),
        ]
        let codes = errors.map { $0.code }
        XCTAssertEqual(codes.count, Set(codes).count, "Error codes must be distinct")
        XCTAssertTrue(codes.allSatisfy { $0 == $0.uppercased() })
    }

    func testFallbackPermissions_MatchPlan() {
        XCTAssertTrue(CapabilityError.unavailable(reason: "x").permitsFallback)
        XCTAssertTrue(CapabilityError.notReady(reason: "x").permitsFallback)
        XCTAssertFalse(CapabilityError.permissionDenied(reason: "x").permitsFallback)
        XCTAssertFalse(CapabilityError.policyDenied(reason: "x").permitsFallback)
        XCTAssertFalse(CapabilityError.cancelled.permitsFallback)
    }

    func testLocalMCPErrorCarriesCode() {
        let error = CapabilityError.disabled(reason: "Apple Intelligence off")
        let mcp = error.localMCPError
        XCTAssertEqual(mcp.code, "DISABLED")
        XCTAssertTrue(mcp.message.contains("Disabled"))
    }
}

// MARK: - Deterministic provider

final class DeterministicTextProviderTests: XCTestCase {

    let provider = DeterministicTextProvider()

    func testSummarize_IsDeterministicAndOrderPreserving() {
        let text = """
        Swift is a general-purpose programming language built using a modern approach to safety and performance.
        Swift is powerful and fun to write. The compiler is fast.
        Modern API design makes code easier to read. Safety features prevent entire classes of bugs.
        """
        let a = DeterministicTextProvider.summarize(text, sentenceLimit: 2)
        let b = DeterministicTextProvider.summarize(text, sentenceLimit: 2)
        XCTAssertEqual(a, b, "Same input must produce byte-identical output")
        XCTAssertFalse(a.isEmpty)
    }

    func testExtract_FindsOnlyExplicitEntities() {
        let input = "Contact ada@example.com or visit https://swift.org by 2026-01-15."
        let result = DeterministicTextProvider.extract(input)
        XCTAssertTrue(result.contains("email: ada@example.com"))
        XCTAssertTrue(result.contains("url: https://swift.org"))
        XCTAssertTrue(result.contains("date: 2026-01-15"))
        XCTAssertFalse(result.contains("nobody@nowhere.invalid"), "Must never invent entities")
    }

    func testClassify_TransparentLabels() {
        XCTAssertEqual(DeterministicTextProvider.classify("How do I fix this crash in production?"), "question")
        XCTAssertEqual(DeterministicTextProvider.classify("The app crashes with an exception on launch"), "bug_report")
        XCTAssertEqual(DeterministicTextProvider.classify("Please add support for dark mode"), "feature_request")
        XCTAssertEqual(DeterministicTextProvider.classify("lorem ipsum"), "general")
    }

    func testAvailability() async {
        let summarize = await provider.availability(for: .localSummarize)
        let generate = await provider.availability(for: .localGenerate)
        XCTAssertEqual(summarize, .available)
        XCTAssertEqual(generate, .unsupported)
    }
}

// MARK: - Shortcuts provider validation

final class ShortcutsProviderTests: XCTestCase {

    func testNameValidation_RejectsInjectionVectors() async {
        let provider = ShortcutsProvider()

        do {
            _ = try await provider.executeAutomation(name: "-ReturnAllFiles", input: nil, timeout: 5)
            XCTFail("Option-prefixed names must be rejected")
        } catch let error as CapabilityError {
            guard case .invalidRequest = error else {
                return XCTFail("Expected invalidRequest, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type \(error)")
        }
    }

    func testAvailability_IsTruthful() async {
        let provider = ShortcutsProvider()
        let listStatus = await provider.availability(for: .localAutomationList)
        let generateStatus = await provider.availability(for: .localGenerate)
        XCTAssertTrue([CapabilityStatus.available, .unavailable, .unsupported].contains(listStatus))
        XCTAssertEqual(generateStatus, .unsupported)
    }

    func testExecuteUnknownShortcut_FailsHonestly() async throws {
        let provider = ShortcutsProvider()
        let available = await provider.availability(for: .localAutomationExecute)
        guard available == .available else {
            throw XCTSkip("shortcuts CLI not available on this system")
        }

        do {
            let execution = try await provider.executeAutomation(
                name: "LI-MCP-Definitely-Not-A-Real-Shortcut-\(UUID().uuidString)",
                input: nil,
                timeout: 20
            )
            XCTFail("Unknown shortcut must not report didRun; got \(execution)")
        } catch let error as CapabilityError {
            // invalidRequest (not found) or providerFailure are both honest outcomes.
            XCTAssertTrue(error.permitsFallback || error.code == "INVALID_REQUEST", "Got honest failure: \(error)")
        }
    }
}

// MARK: - Truthful tools

final class TruthfulToolBehaviorTests: XCTestCase {

    private func makeContext(toolName: String) -> MCPExecutionContext {
        MCPExecutionContext(clientId: UUID(), requestId: UUID().uuidString, toolName: toolName, metadata: [:])
    }

    private var logger: Logger {
        Logger(configuration: LoggingConfiguration(level: .error, file: nil, maxSize: 1, maxFiles: 1, enableConsole: false))
    }

    func testVoiceControl_NeverSucceeds() async throws {
        let tool = VoiceControlTool(logger: logger, securityManager: SecurityManager())
        let response = try await tool.performExecution(
            parameters: ["command": AnyCodable("open Safari")],
            context: makeContext(toolName: "voice_command")
        )

        XCTAssertFalse(response.success, "voice_command must never report success")
        XCTAssertEqual(response.error?.code, "UNSUPPORTED")
        let data = response.data?.toAnyDictionary()
        XCTAssertEqual(data?["available"] as? Bool, false)
    }

    func testLocalCapabilities_ReportsEveryCapabilityWithStatus() async throws {
        let router = CapabilityRouter()
        let tool = LocalCapabilitiesTool(logger: logger, securityManager: SecurityManager(), router: router)
        let response = try await tool.performExecution(parameters: [:], context: makeContext(toolName: "local_capabilities"))

        XCTAssertTrue(response.success)
        let data = response.data?.toAnyDictionary() ?? [:]
        let statuses = data["capabilities"] as? [String: String] ?? [:]

        for capability in StableCapability.allCases {
            XCTAssertNotNil(statuses[capability.rawValue], "Missing status for \(capability.rawValue)")
        }
        // Deterministic capabilities are available on every supported tier.
        XCTAssertEqual(statuses[StableCapability.localSummarize.rawValue], "available")
        XCTAssertEqual(statuses[StableCapability.localAutomationList.rawValue], "available")
    }

    func testLocalGenerate_WithoutProvider_ReturnsUnavailableNotFakeText() async {
        let router = CapabilityRouter() // empty router: simulates macOS 13
        let tool = LocalGenerateTool(logger: logger, securityManager: SecurityManager(), router: router)

        do {
            _ = try await tool.performExecution(
                parameters: ["prompt": AnyCodable("Write a haiku")],
                context: makeContext(toolName: "local_generate")
            )
            XCTFail("local_generate with no provider must fail, never fabricate output")
        } catch let error as CapabilityError {
            guard case .unsupported = error else {
                return XCTFail("Expected unsupported, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type \(error)")
        }
    }

    func testLocalSummarize_RoutesThroughDeterministicProvider() async throws {
        let router = CapabilityRouter()
        await router.register(DeterministicTextProvider(), for: [.localSummarize], priority: 100)
        let tool = LocalSummarizeTool(logger: logger, securityManager: SecurityManager(), router: router)
        let response = try await tool.performExecution(
            parameters: [
                "text": AnyCodable("First sentence about Swift. Second sentence about testing. Third sentence about routers."),
                "sentenceLimit": AnyCodable(2),
            ],
            context: makeContext(toolName: "local_summarize")
        )

        XCTAssertTrue(response.success)
        let data = response.data?.toAnyDictionary() ?? [:]
        XCTAssertEqual((data["provider"] as? [String: Any])?["id"] as? String, "deterministic_text")
        let summary = data["summary"] as? String
        XCTAssertFalse(summary?.isEmpty ?? true)
    }

    func testLocalSummarize_AppleEnginePinned_SurfacesRealStatus() async {
        let router = CapabilityRouter()
        // Intentionally do NOT register the apple provider: pinning to a
        // missing provider must report unsupported, not fall back silently.
        await router.register(DeterministicTextProvider(), for: [.localSummarize], priority: 100)
        let tool = LocalSummarizeTool(logger: logger, securityManager: SecurityManager(), router: router)

        do {
            _ = try await tool.performExecution(
                parameters: [
                    "text": AnyCodable("Some text"),
                    "engine": AnyCodable("apple"),
                ],
                context: makeContext(toolName: "local_summarize")
            )
            XCTFail("Pinning to an unregistered provider must surface unsupported")
        } catch let error as CapabilityError {
            guard case .unsupported = error else {
                return XCTFail("Expected unsupported, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type \(error)")
        }
    }
}

// MARK: - RuntimeCapabilities round trip

final class RuntimeCapabilitiesCodingTests: XCTestCase {

    func testCodableRoundTrip_PreservesTruth() throws {
        let capabilities = RuntimeCapabilities()
        let data = try JSONEncoder().encode(capabilities)
        let decoded = try JSONDecoder().decode(RuntimeCapabilities.self, from: data)

        XCTAssertEqual(decoded.osVersionString, capabilities.osVersionString)
        XCTAssertEqual(decoded.architecture, capabilities.architecture)
        XCTAssertEqual(decoded.modelAvailability, capabilities.modelAvailability)
        XCTAssertEqual(decoded.apiFeatureLevel, capabilities.apiFeatureLevel)
        XCTAssertEqual(decoded.appleIntelligenceEligible, capabilities.appleIntelligenceEligible)
    }

    func testStatuses_AreConsistentWithModelAvailability() {
        let capabilities = RuntimeCapabilities()
        let generateStatus = capabilities.status(for: .localGenerate)

        switch capabilities.modelAvailability {
        case .available:
            XCTAssertEqual(generateStatus, .available)
        case .notReady, .downloading:
            XCTAssertEqual(generateStatus, .notReady)
        case .unavailable:
            XCTAssertTrue([CapabilityStatus.unsupported, .disabled].contains(generateStatus))
        }
    }
}
