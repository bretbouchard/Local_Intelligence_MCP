//
//  AppleCloudProviders.swift
//  LocalIntelligenceMCP
//
//  GSD Plan 4.5 — Private Cloud Compute as a separate opt-in provider class.
//  Never an invisible fallback from "local": the router registers it
//  pinned-only, registration is policy-gated (LI_ALLOW_PCC=1), and its
//  disabled/disallowed states are distinguishable in local_capabilities.
//

import Foundation

#if canImport(FoundationModels)
import FoundationModels

@available(macOS 27.0, *)
final class ApplePCCProvider: IntelligenceProvider, @unchecked Sendable {

    let metadata = ProviderMetadata(
        id: "apple_pcc",
        displayName: "Apple Private Cloud Compute",
        providerClass: .applePrivateCloudCompute,
        modelId: "pcc_system_language_model"
    )

    /// GSD Plan 4.5: PCC processing leaves the device, so it requires BOTH an
    /// explicit environment opt-in AND a per-request pin. Default: disallowed.
    static var policyAllows: Bool {
        ProcessInfo.processInfo.environment["LI_ALLOW_PCC"] == "1"
    }

    func availability(for capability: StableCapability) async -> CapabilityStatus {
        switch capability {
        case .localGenerate:
            guard Self.policyAllows else {
                return .disabled
            }
            return Self.status(for: PrivateCloudComputeLanguageModel().availability)
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
            model: PrivateCloudComputeLanguageModel(),
            instructions: request.instructions ?? AppleFoundationProvider26.instructions(for: request.capability)
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
        } catch is CancellationError {
            throw CapabilityError.cancelled
        } catch {
            // PCC shares the model error vocabulary; normalize defensively.
            if #available(macOS 27.0, *) {
                throw AppleFoundationProvider26.normalize(error)
            }
            throw CapabilityError.providerFailure(error.localizedDescription)
        }
    }

    static func status(for availability: PrivateCloudComputeLanguageModel.Availability) -> CapabilityStatus {
        switch availability {
        case .available:
            return .available
        case .unavailable(let reason):
            switch reason {
            case .deviceNotEligible:
                return .unsupported
            case .systemNotReady:
                return .notReady
            @unknown default:
                return .unavailable
            }
        @unknown default:
            return .unavailable
        }
    }
}

#endif
