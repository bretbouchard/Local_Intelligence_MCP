//
//  AppleFoundationProvider26.swift
//  LocalIntelligenceMCP
//
//  GSD Plan 3.1 — Apple Foundation Models provider (macOS 26+).
//  Conditionally compiled; every entry point reports truthful availability so
//  older systems and ineligible hardware fall back instead of failing.
//

import Foundation

#if canImport(FoundationModels)
import FoundationModels

@available(macOS 26.0, *)
@Generable
struct TextCapabilityArguments: Sendable {
    var text: String = ""
}

@available(macOS 26.0, *)
/// Exposes one read-only text capability to the Apple model as a callable tool.
/// GSD Plan 3.3: every invocation is re-routed through the CapabilityRouter, so
/// availability and policy are re-evaluated at execution time — the model can
/// never bypass authorization by naming a function.
struct TextCapabilityAdapter: Tool, @unchecked Sendable {
    typealias Arguments = TextCapabilityArguments
    typealias Output = String

    let capability: StableCapability
    let router: CapabilityRouter

    var name: String { capability.rawValue }
    var description: String {
        switch capability {
        case .localSummarize: return "Summarize a piece of text faithfully without inventing facts."
        case .localClassify: return "Classify text into question/bug_report/feature_request/complaint/praise/general."
        case .localExtract: return "Extract emails, URLs, dates and numbers explicitly present in text."
        default: return "Deterministic text analysis."
        }
    }
    var parameters: GenerationSchema { TextCapabilityArguments.generationSchema }

    func call(arguments: Arguments) async throws -> String {
        let request = GenerationRequest(
            capability: capability,
            input: arguments.text,
            deadline: 60
        )
        return try await router.execute(request).text
    }
}

@available(macOS 26.0, *)
final class AppleFoundationProvider26: IntelligenceProvider, @unchecked Sendable {

    let metadata = ProviderMetadata(
        id: "apple_foundation_models_26",
        displayName: "Apple Foundation Models (on-device)",
        providerClass: .appleFoundationModel,
        modelId: "system_language_model"
    )

    /// Injected at init (GSD Plan 3.3): model-callable tools re-route through
    /// the router so policy is re-evaluated on every invocation.
    let router: CapabilityRouter?

    init(router: CapabilityRouter? = nil) {
        self.router = router
    }

    /// Capabilities the model may call, and explicitly excluded ones.
    /// local_automation_execute is EXCLUDED: a model must not trigger side
    /// effects; local_generate is EXCLUDED: no recursion.
    static let supportedModelTools: Set<StableCapability> = [
        .localSummarize, .localClassify, .localExtract,
    ]

    func availability(for capability: StableCapability) async -> CapabilityStatus {
        switch capability {
        case .localGenerate:
            return Self.status(for: SystemLanguageModel.default.availability)
        case .localSummarize, .localExtract, .localClassify:
            // Opt-in engine for these; deterministic remains the default route.
            return Self.status(for: SystemLanguageModel.default.availability)
        default:
            return .unsupported
        }
    }

    func generate(_ request: GenerationRequest) async throws -> GenerationResult {
        guard let prompt = request.prompt, !prompt.isEmpty else {
            throw CapabilityError.invalidRequest("prompt is required for '\(request.capability.rawValue)'")
        }

        // Build the model-callable tool set from the per-request allowlist.
        // Policy check comes first: rejection must not depend on router state.
        var modelTools: [any Tool] = []
        if let allowlist = request.toolAllowlist, !allowlist.isEmpty {
            for rawName in allowlist {
                guard let capability = StableCapability(rawValue: rawName),
                      Self.supportedModelTools.contains(capability) else {
                    throw CapabilityError.policyDenied(
                        reason: "Tool '\(rawName)' is not in the model-callable allowlist. Allowed: \(Self.supportedModelTools.map(\.rawValue).sorted().joined(separator: ", "))"
                    )
                }
            }
            guard let router = router else {
                throw CapabilityError.unavailable(reason: "Provider is not attached to a capability router")
            }
            modelTools = allowlist.compactMap { rawName in
                guard let capability = StableCapability(rawValue: rawName) else { return nil }
                return TextCapabilityAdapter(capability: capability, router: router)
            }
        }

        // TRUTH-01: sampling controls are applied, never silently ignored.
        var options = GenerationOptions()
        options.temperature = request.temperature
        options.maximumResponseTokens = request.maxOutputTokens

        let started = Date()
        let session = LanguageModelSession(
            model: .default,
            tools: modelTools,
            instructions: Self.instructions(for: request.capability)
        )

        let composedPrompt = request.input.isEmpty
            ? prompt
            : "\(prompt)\n\nInput:\n\(request.input)"

        do {
            let response = try await session.respond(to: Prompt(composedPrompt), options: options)
            return GenerationResult(
                text: response.content,
                provider: metadata,
                duration: Date().timeIntervalSince(started)
            )
        } catch let error as CapabilityError {
            throw error
        } catch {
            throw Self.normalize(error)
        }
    }

    // MARK: - Mapping helpers

    static func status(for availability: SystemLanguageModel.Availability) -> CapabilityStatus {
        switch availability {
        case .available:
            return .available
        case .unavailable(let reason):
            switch reason {
            case .deviceNotEligible:
                return .unsupported
            case .appleIntelligenceNotEnabled:
                return .disabled
            case .modelNotReady:
                return .notReady
            @unknown default:
                return .unavailable
            }
        @unknown default:
            return .unavailable
        }
    }

    static func normalize(_ error: Error) -> CapabilityError {
        if error is CancellationError {
            return .cancelled
        }
        if #available(macOS 27.0, *) {
            return normalizeModern(error)
        }
        return .providerFailure(error.localizedDescription)
    }

    @available(macOS 27.0, *)
    private static func normalizeModern(_ error: Error) -> CapabilityError {
        if let modelError = error as? LanguageModelError {
            switch modelError {
            case .contextSizeExceeded:
                return .invalidRequest("Input exceeds the model context size")
            case .rateLimited:
                return .notReady(reason: "Model is rate limited; retry later")
            case .guardrailViolation:
                return .policyDenied(reason: "Response blocked by model safety guardrails")
            case .refusal:
                return .policyDenied(reason: "Model refused the request")
            case .unsupportedCapability:
                return .unsupported(reason: "Model does not support the requested capability")
            case .timeout:
                return .timeout(0)
            default:
                return .providerFailure(String(describing: modelError))
            }
        }
        return .providerFailure(error.localizedDescription)
    }

    static func instructions(for capability: StableCapability) -> String {
        switch capability {
        case .localSummarize:
            return "Summarize the input faithfully. Preserve the original language. Do not invent facts."
        case .localExtract:
            return "Extract only information explicitly present in the input. Output one item per line."
        case .localClassify:
            return "Classify the input. Answer with the single most appropriate label."
        default:
            return "You are a local, privacy-preserving assistant. Answer helpfully and concisely."
        }
    }
}

#endif
