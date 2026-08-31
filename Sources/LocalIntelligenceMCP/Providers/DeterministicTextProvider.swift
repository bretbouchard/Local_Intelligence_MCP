//
//  DeterministicTextProvider.swift
//  LocalIntelligenceMCP
//
//  Deterministic implementations for summarize/extract/classify.
//  Deterministic work stays deterministic (Master Plan invariant): these are the
//  default routes; the Apple model is opt-in per request via `pinnedProvider`.
//

import Foundation

final class DeterministicTextProvider: IntelligenceProvider, @unchecked Sendable {

    let metadata = ProviderMetadata(
        id: "deterministic_text",
        displayName: "Deterministic Text Analysis",
        providerClass: .deterministic
    )

    func availability(for capability: StableCapability) async -> CapabilityStatus {
        switch capability {
        case .localSummarize, .localExtract, .localClassify:
            return .available
        default:
            return .unsupported
        }
    }

    func generate(_ request: GenerationRequest) async throws -> GenerationResult {
        let started = Date()
        let text: String
        switch request.capability {
        case .localSummarize:
            text = Self.summarize(request.input, sentenceLimit: request.maxOutputTokens ?? 5)
        case .localExtract:
            text = Self.extract(request.input)
        case .localClassify:
            text = Self.classify(request.input)
        default:
            throw CapabilityError.unsupported(reason: "Provider does not support '\(request.capability.rawValue)'")
        }
        return GenerationResult(
            text: text,
            provider: metadata,
            duration: Date().timeIntervalSince(started)
        )
    }

    // MARK: - Summarize (extractive, frequency-ranked, order-preserving)

    static func summarize(_ input: String, sentenceLimit: Int) -> String {
        let limit = max(1, min(sentenceLimit, 50))
        let sentences = input
            .replacingOccurrences(of: "\n", with: " ")
            .components(separatedBy: ". ")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        guard sentences.count > limit else {
            return sentences.joined(separator: ". ") + (sentences.isEmpty ? "" : ".")
        }

        var frequencies: [String: Int] = [:]
        let stopwords: Set<String> = ["the", "a", "an", "and", "or", "but", "of", "to", "in", "on", "for",
                                      "is", "are", "was", "were", "it", "its", "this", "that", "with", "as",
                                      "at", "by", "from", "be", "has", "have", "had", "not", "no"]
        for word in input.split(separator: " ") {
            let clean = word.trimmingCharacters(in: .punctuationCharacters).lowercased()
            if clean.count > 2 && !stopwords.contains(clean) {
                frequencies[clean, default: 0] += 1
            }
        }

        func score(_ sentence: String) -> Int {
            sentence.split(separator: " ").reduce(0) { total, word in
                total + (frequencies[word.trimmingCharacters(in: .punctuationCharacters).lowercased()] ?? 0)
            }
        }

        let topSentences = Set(sentences.sorted { score($0) > score($1) }.prefix(limit))
        return sentences.filter { topSentences.contains($0) }.joined(separator: ". ") + "."
    }

    // MARK: - Extract (pattern-based; only information explicitly present)

    static func extract(_ input: String) -> String {
        var lines: [String] = []
        let patterns: [(String, String)] = [
            ("email", #"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}"#),
            ("url", #"https?://[^\s<>)\"']+"#),
            ("date", #"\b\d{4}-\d{2}-\d{2}\b|\b\d{1,2}/\d{1,2}/\d{2,4}\b"#),
            ("number", #"\b\d+(?:\.\d+)?\b"#),
        ]
        for (label, pattern) in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            let range = NSRange(input.startIndex..., in: input)
            let matches = regex.matches(in: input, range: range).compactMap {
                Range($0.range, in: input).map { String(input[$0]) }
            }
            for match in Set(matches).sorted() {
                lines.append("\(label): \(match)")
            }
        }
        return lines.isEmpty ? "No extractable entities found." : lines.joined(separator: "\n")
    }

    // MARK: - Classify (transparent keyword rules)

    static func classify(_ input: String) -> String {
        let rules: [(label: String, keywords: Set<String>)] = [
            ("question", ["?", "how", "what", "why", "when", "where", "who", "which"]),
            ("bug_report", ["error", "crash", "fails", "broken", "bug", "exception", "stack trace"]),
            ("feature_request", ["feature", "request", "enhancement", "would be nice", "add support", "wish"]),
            ("complaint", ["disappointed", "unacceptable", "terrible", "frustrating", "annoying"]),
            ("praise", ["great", "excellent", "love", "awesome", "fantastic", "wonderful"]),
        ]
        let lowered = input.lowercased()
        var best: (label: String, hits: Int)?
        for rule in rules {
            let hits = rule.keywords.filter { lowered.contains($0) }.count
            if hits > 0 && hits > (best?.hits ?? 0) {
                best = (rule.label, hits)
            }
        }
        return best?.label ?? "general"
    }
}
