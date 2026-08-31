//
//  ImageUnderstandingProviders.swift
//  LocalIntelligenceMCP
//
//  GSD Plans 4.3/4.4 — `local_image_understand`:
//  - VisionOCRProvider: deterministic on-device text recognition (Vision),
//    the default engine, available on every supported OS tier.
//  - AppleMultimodalImageProvider27: Foundation Models image prompts
//    (macOS 27+; attachment segments are 27-gated in the SDK).
//  File size/type limits and unsupported-state reporting are part of the
//  contract; nothing simulates understanding.
//

import Foundation
import CoreGraphics
import ImageIO
import Vision
import UniformTypeIdentifiers

// MARK: - Contracts

struct ImageUnderstandingRequest: Sendable {
    let imageURL: URL
    let question: String?
    let deadline: TimeInterval?
}

struct ImageUnderstandingResult: Sendable {
    let text: String
    let provider: ProviderMetadata
    let duration: TimeInterval
    /// Mean OCR confidence when the engine reports one (Vision); nil otherwise.
    let confidence: Double?
}

protocol ImageUnderstandingProvider: CapabilityProvider {
    func understand(_ request: ImageUnderstandingRequest) async throws -> ImageUnderstandingResult
}

// MARK: - Shared validation

enum ImageInputValidator {

    static let maxFileBytes = 20 * 1024 * 1024
    static let supportedExtensions: Set<String> = ["png", "jpg", "jpeg", "heic", "tiff", "bmp"]

    static func validate(url: URL) throws {
        let ext = url.pathExtension.lowercased()
        guard supportedExtensions.contains(ext) else {
            throw CapabilityError.invalidRequest(
                "Unsupported image type '\(ext)'. Supported: \(supportedExtensions.sorted().joined(separator: ", "))"
            )
        }
        let size: Int64
        do {
            let resource = try url.resourceValues(forKeys: [.fileSizeKey])
            size = Int64(resource.fileSize ?? 0)
        } catch {
            throw CapabilityError.invalidRequest("Image file not readable: \(error.localizedDescription)")
        }
        guard size > 0 else {
            throw CapabilityError.unavailable(reason: "Image file is empty or missing")
        }
        guard size <= maxFileBytes else {
            throw CapabilityError.invalidRequest("Image exceeds the 20 MB limit (\(size / 1024 / 1024) MB)")
        }
    }

    static func loadCGImage(url: URL) throws -> CGImage {
        try validate(url: url)
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw CapabilityError.invalidRequest("Image could not be decoded")
        }
        return image
    }
}

// MARK: - Vision OCR (deterministic default)

final class VisionOCRProvider: ImageUnderstandingProvider, @unchecked Sendable {

    let metadata = ProviderMetadata(
        id: "vision_ocr",
        displayName: "Apple Vision Text Recognition",
        providerClass: .deterministic
    )

    func availability(for capability: StableCapability) async -> CapabilityStatus {
        capability == .localImageUnderstand ? .available : .unsupported
    }

    func understand(_ request: ImageUnderstandingRequest) async throws -> ImageUnderstandingResult {
        let started = Date()
        let image = try ImageInputValidator.loadCGImage(url: request.imageURL)

        let recognized: (text: String, confidence: Double?) = try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: CapabilityError.providerFailure(error.localizedDescription))
                    return
                }
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: ("", nil))
                    return
                }
                var lines: [String] = []
                var confidences: [Double] = []
                for observation in observations {
                    if let candidate = observation.topCandidates(1).first {
                        lines.append(candidate.string)
                        confidences.append(Double(candidate.confidence))
                    }
                }
                let mean = confidences.isEmpty ? nil : confidences.reduce(0, +) / Double(confidences.count)
                continuation.resume(returning: (lines.joined(separator: "\n"), mean))
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: CapabilityError.providerFailure(error.localizedDescription))
            }
        }

        let text = recognized.text.isEmpty ? "No text recognized." : recognized.text
        return ImageUnderstandingResult(
            text: text,
            provider: metadata,
            duration: Date().timeIntervalSince(started),
            confidence: recognized.confidence
        )
    }
}

// MARK: - Apple multimodal (macOS 27+)

#if canImport(FoundationModels)
import FoundationModels

@available(macOS 27.0, *)
final class AppleMultimodalImageProvider27: ImageUnderstandingProvider, @unchecked Sendable {

    let metadata = ProviderMetadata(
        id: "apple_multimodal_27",
        displayName: "Apple Foundation Models (image)",
        providerClass: .appleFoundationModel,
        modelId: "system_language_model"
    )

    func availability(for capability: StableCapability) async -> CapabilityStatus {
        guard capability == .localImageUnderstand else { return .unsupported }
        return AppleFoundationProvider26.status(for: SystemLanguageModel.default.availability)
    }

    func understand(_ request: ImageUnderstandingRequest) async throws -> ImageUnderstandingResult {
        let started = Date()
        let image = try ImageInputValidator.loadCGImage(url: request.imageURL)

        let question = request.question ?? "Describe this image and transcribe any text it contains."
        let attachment = Attachment(imageURL: request.imageURL)

        let session = LanguageModelSession(
            model: .default,
            instructions: "You analyze images locally. Answer only from what is visible. Transcribe text verbatim when asked."
        )

        do {
            let response = try await session.respond {
                question
                attachment
            }
            return ImageUnderstandingResult(
                text: response.content,
                provider: metadata,
                duration: Date().timeIntervalSince(started),
                confidence: nil
            )
        } catch is CancellationError {
            throw CapabilityError.cancelled
        } catch {
            throw AppleFoundationProvider26.normalize(error)
        }
    }
}

#endif
