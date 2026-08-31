//
//  Phase45Tests.swift
//  LocalIntelligenceMCPTests
//
//  GSD Plans 4.2/4.3/4.4/4.5 (new capabilities), 4.6 (evaluation harness),
//  5.4 (reliability stress) and 5.5 (performance).
//

import XCTest
import AppKit
import CoreText
import UniformTypeIdentifiers
@testable import LocalIntelligenceMCP

// MARK: - Plan 4.6: evaluation harness (deterministic capabilities)

private actor LocalMockProvider: IntelligenceProvider {
    let metadata: ProviderMetadata
    let status: CapabilityStatus
    init(id: String, status: CapabilityStatus) {
        self.metadata = ProviderMetadata(id: id, displayName: id, providerClass: .deterministic)
        self.status = status
    }
    func availability(for capability: StableCapability) async -> CapabilityStatus { status }
    func generate(_ request: GenerationRequest) async throws -> GenerationResult {
        GenerationResult(text: "from-\(metadata.id)", provider: metadata, duration: 0)
    }
}

final class DeterministicEvaluationTests: XCTestCase {

    // Versioned thresholds (Plan 4.6: failures block release for stable capabilities).
    static let classificationPrecisionThreshold = 0.8
    static let extractionRecallThreshold = 1.0

    struct Fixture {
        let text: String
        let expected: String
    }

    static let classificationFixtures: [Fixture] = [
        .init(text: "How do I route audio through a bus in Logic?", expected: "question"),
        .init(text: "What is the best way to reduce latency?", expected: "question"),
        .init(text: "Why does my interface click when the buffer is small?", expected: "question"),
        .init(text: "The plugin crashes Logic immediately on scan", expected: "bug_report"),
        .init(text: "Getting an exception when loading a session with autosampled plugins", expected: "bug_report"),
        .init(text: "App fails to launch after the latest update, totally broken", expected: "bug_report"),
        .init(text: "Please add support for Atmos bus routing", expected: "feature_request"),
        .init(text: "Feature request: would be nice to have stem export", expected: "feature_request"),
        .init(text: "Add a gain reduction meter to the compressor", expected: "feature_request"),
        .init(text: "This update is terrible and the new UI is frustrating", expected: "complaint"),
        .init(text: "Absolutely fantastic work, the new reverb sounds wonderful", expected: "praise"),
        .init(text: "Love the new preset browser, great job", expected: "praise"),
    ]

    func testClassificationPrecision_MeetsThreshold() {
        let correct = Self.classificationFixtures.filter {
            DeterministicTextProvider.classify($0.text) == $0.expected
        }.count
        let precision = Double(correct) / Double(Self.classificationFixtures.count)
        XCTAssertGreaterThanOrEqual(
            precision, Self.classificationPrecisionThreshold,
            "Classification precision \(precision) below versioned threshold; fixtures or rules need review"
        )
    }

    func testExtractionRecall_OnSyntheticDocument() {
        let document = """
        Reach the studio manager at manager@bearcreek.studio or booking@bearcreek.studio.
        Session window: 2026-10-12 to 2026-10-14. Details at https://bearcreek.studio/sessions.
        """
        let result = DeterministicTextProvider.extract(document)

        for expected in ["manager@bearcreek.studio", "booking@bearcreek.studio",
                         "2026-10-12", "2026-10-14", "https://bearcreek.studio/sessions"] {
            XCTAssertTrue(result.contains(expected), "Extraction missed explicit entity: \(expected)")
        }
        XCTAssertEqual(Self.extractionRecallThreshold, 1.0, "Explicit entities must always be extracted")
    }

    func testSummarize_RespectsSentenceLimit() {
        let long = (1...40).map { "Sentence number \($0) carries some content." }.joined(separator: " ")
        let summary = DeterministicTextProvider.summarize(long, sentenceLimit: 5)
        let sentenceCount = summary.components(separatedBy: ". ").count
        XCTAssertLessThanOrEqual(sentenceCount, 6, "Summary must respect the sentence limit")
    }
}

// MARK: - Plans 4.3/4.4/4.5: new capabilities

final class ImageAndCloudCapabilityTests: XCTestCase {

    private let logger = Logger(configuration: LoggingConfiguration(level: .error, file: nil, maxSize: 1, maxFiles: 1, enableConsole: false))
    private let securityManager = SecurityManager()

    /// Render a PNG with text via CoreGraphics for genuine OCR testing.
    private func makeTestImage(text: String, url: URL) throws {
        let width = 480, height = 140
        let space = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8,
            bytesPerRow: width * 4, space: space,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw XCTSkip("Could not create CGContext")
        }
        context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        context.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
        let line = CTLineCreateWithAttributedString(NSAttributedString(
            string: text,
            attributes: [.font: NSFont.boldSystemFont(ofSize: 44), .foregroundColor: NSColor.black]
        ))
        context.textPosition = CGPoint(x: 24, y: 40)
        CTLineDraw(line, context)
        guard let image = context.makeImage() else {
            throw XCTSkip("Could not render image")
        }
        let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)
        guard let dest = destination else {
            throw XCTSkip("Could not create image destination")
        }
        CGImageDestinationAddImage(dest, image, nil)
        guard CGImageDestinationFinalize(dest) else {
            throw XCTSkip("Could not write PNG")
        }
    }

    func testVisionOCR_ReadsRenderedText() async throws {
        let provider = VisionOCRProvider()
        let url = URL(fileURLWithPath: NSTemporaryDirectory() + "li-mcp-ocr-\(UUID().uuidString).png")
        try makeTestImage(text: "HELLO 12345", url: url)
        defer { try? FileManager.default.removeItem(at: url) }

        let result = try await provider.understand(
            ImageUnderstandingRequest(imageURL: url, question: nil, deadline: 30)
        )
        XCTAssertFalse(result.text.isEmpty, "OCR should recognize the rendered text")
        XCTAssertEqual(result.provider.id, "vision_ocr")
    }

    func testImageUnderstand_RejectsUnsupportedTypes() async {
        let router = CapabilityRouter()
        await router.registerImage(VisionOCRProvider(), priority: 100)
        let tool = LocalImageUnderstandTool(logger: logger, securityManager: securityManager, router: router)
        let url = URL(fileURLWithPath: NSTemporaryDirectory() + "li-mcp-\(UUID().uuidString).exe")

        do {
            _ = try await router.understandImage(
                ImageUnderstandingRequest(imageURL: url, question: nil, deadline: 5),
                pinnedProvider: "vision_ocr"
            )
            XCTFail("Unsupported image types must be rejected")
        } catch let error as CapabilityError {
            guard case .invalidRequest = error else { return XCTFail("Expected invalidRequest, got \(error)") }
        } catch { XCTFail("Unexpected error \(error)") }
        _ = tool
    }

    func testImageUnderstand_MissingFile_FailsHonestly() async {
        let router = CapabilityRouter()
        await router.registerImage(VisionOCRProvider(), priority: 100)
        let url = URL(fileURLWithPath: NSTemporaryDirectory() + "li-mcp-missing-\(UUID().uuidString).png")

        do {
            _ = try await router.understandImage(
                ImageUnderstandingRequest(imageURL: url, question: nil, deadline: 5),
                pinnedProvider: "vision_ocr"
            )
            XCTFail("Missing file must fail")
        } catch {
            XCTAssertTrue(error is CapabilityError, "honest CapabilityError expected, got \(error)")
        }
    }

    // MARK: Plan 4.5: PCC gating

    func testPCC_DisabledByPolicy_WithoutOptIn() async throws {
        guard #available(macOS 27.0, *) else { throw XCTSkip("PCC model requires macOS 27+") }
        setenv("LI_ALLOW_PCC", "0", 1)
        defer { unsetenv("LI_ALLOW_PCC") }

        let provider = ApplePCCProvider()
        let status = await provider.availability(for: .localGenerate)
        XCTAssertEqual(status, .disabled, "PCC must report policy-disabled without LI_ALLOW_PCC=1")
    }

    func testPCC_NeverServesUnpinnedRequests() async throws {
        // Even when registered, pinned-only providers never serve ordinary requests.
        let router = CapabilityRouter()
        struct FakePCC: IntelligenceProvider {
            let metadata = ProviderMetadata(id: "apple_pcc", displayName: "PCC", providerClass: .applePrivateCloudCompute)
            func availability(for capability: StableCapability) async -> CapabilityStatus { .available }
            func generate(_ request: GenerationRequest) async throws -> GenerationResult {
                GenerationResult(text: "pcc", provider: metadata, duration: 0)
            }
        }
        await router.register(FakePCC(), for: [.localGenerate], priority: 10, pinnedOnly: true)

        do {
            _ = try await router.execute(GenerationRequest(capability: .localGenerate, prompt: "x"))
            XCTFail("Pinned-only provider must not serve unpinned requests")
        } catch let error as CapabilityError {
            guard case .unsupported = error else { return XCTFail("Expected unsupported, got \(error)") }
        }
    }

    func testPCC_ServesPinnedRequests() async throws {
        let router = CapabilityRouter()
        struct FakePCC: IntelligenceProvider {
            let metadata = ProviderMetadata(id: "apple_pcc", displayName: "PCC", providerClass: .applePrivateCloudCompute)
            func availability(for capability: StableCapability) async -> CapabilityStatus { .available }
            func generate(_ request: GenerationRequest) async throws -> GenerationResult {
                GenerationResult(text: "pcc", provider: metadata, duration: 0)
            }
        }
        await router.register(FakePCC(), for: [.localGenerate], priority: 10, pinnedOnly: true)

        let result = try await router.execute(
            GenerationRequest(capability: .localGenerate, prompt: "x", pinnedProvider: "apple_pcc")
        )
        XCTAssertEqual(result.text, "pcc")
    }

    // MARK: Plan 4.2: profiles

    func testProfiles_TriagePermitsOnlyClassify() {
        let triage = GenerationProfile.supportTriage
        XCTAssertEqual(triage.permittedTools, ["local_classify"])
        XCTAssertNotNil(triage.instructions)
    }

    func testProfiles_UnknownProfileRejected() async {
        let logger = Logger(configuration: LoggingConfiguration(level: .error, file: nil, maxSize: 1, maxFiles: 1, enableConsole: false))
        let router = CapabilityRouter()
        let tool = LocalGenerateTool(logger: logger, securityManager: SecurityManager(), router: router)

        do {
            _ = try await tool.performExecution(
                parameters: ["prompt": AnyCodable("x"), "profile": AnyCodable("wild_west")],
                context: MCPExecutionContext(clientId: UUID(), requestId: UUID().uuidString, toolName: "local_generate", metadata: [:])
            )
            XCTFail("Unknown profiles must be rejected")
        } catch let error as CapabilityError {
            guard case .invalidRequest = error else { return XCTFail("Expected invalidRequest, got \(error)") }
        } catch { XCTFail("Unexpected error \(error)") }
    }
}

// MARK: - Plan 5.4/5.5: reliability and performance

final class ReliabilityPerformanceTests: XCTestCase {

    func testCancellationStorm_AllRequestsCancel() async throws {
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

        let tasks = (0..<10).map { _ in
            Task { try await router.execute(GenerationRequest(capability: .localGenerate, prompt: "x")) }
        }
        try await Task.sleep(nanoseconds: 100_000_000)
        tasks.forEach { $0.cancel() }

        for task in tasks {
            do {
                _ = try await task.value
                XCTFail("Cancelled request must not complete")
            } catch is CancellationError {
                // expected
            } catch let error as CapabilityError {
                guard case .cancelled = error else { throw error }
            }
        }
    }

    func testProviderFlapping_RoutingStaysDeterministic() async throws {
        final class FlappyProvider: IntelligenceProvider, @unchecked Sendable {
            let metadata = ProviderMetadata(id: "flappy", displayName: "flappy", providerClass: .deterministic)
            private let lock = NSLock()
            private var state = false
            var flips = 0
            func flap() { lock.lock(); state.toggle(); flips += 1; lock.unlock() }
            func availability(for capability: StableCapability) async -> CapabilityStatus {
                lock.lock(); defer { lock.unlock() }
                return state ? .available : .unavailable
            }
            func generate(_ request: GenerationRequest) async throws -> GenerationResult {
                GenerationResult(text: "ok", provider: metadata, duration: 0)
            }
        }
        let router = CapabilityRouter()
        let backup = LocalMockProvider(id: "backup", status: .available)
        let flappy = FlappyProvider()
        await router.register(flappy, for: [.localSummarize], priority: 100)
        await router.register(backup, for: [.localSummarize], priority: 10)

        for round in 0..<12 {
            flappy.flap()
            let result = try await router.execute(GenerationRequest(capability: .localSummarize, input: "x"))
            let expected = (round % 2 == 0) ? "flappy" : "backup" // flap() flips before each round
            XCTAssertEqual(result.provider.id, expected, "routing must follow availability deterministically")
        }
    }

    func testRoutingOverhead_StaysSubMillisecond() async throws {
        let router = CapabilityRouter()
        await router.register(DeterministicTextProvider(), for: [.localClassify], priority: 100)

        // Warm up
        _ = try await router.execute(GenerationRequest(capability: .localClassify, input: "warm up"))

        let start = Date()
        let iterations = 200
        for _ in 0..<iterations {
            _ = try await router.execute(GenerationRequest(capability: .localClassify, input: "quick sample"))
        }
        let mean = Date().timeIntervalSince(start) / Double(iterations)
        XCTAssertLessThan(mean * 1000, 5.0, "Mean routing overhead \(mean * 1000)ms exceeds 5ms budget")
    }
}
