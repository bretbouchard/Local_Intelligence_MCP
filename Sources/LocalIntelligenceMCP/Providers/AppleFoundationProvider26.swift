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
final class AppleFoundationProvider26: IntelligenceProvider, @unchecked Sendable {

    let metadata = ProviderMetadata(
        id: "apple_foundation_models_26",
        displayName: "Apple Foundation Models (on-device)",
        providerClass: .appleFoundationModel,
        modelId: "system_language_model"
    )

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

        let started = Date()
        let session = LanguageModelSession(
            model: .default,
            instructions: Self.instructions(for: request.capability)
        )

        let composedPrompt = request.input.isEmpty
            ? prompt
            : "\(prompt)\n\nInput:\n\(request.input)"

        do {
            let response = try await session.respond(to: Prompt(composedPrompt))
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
