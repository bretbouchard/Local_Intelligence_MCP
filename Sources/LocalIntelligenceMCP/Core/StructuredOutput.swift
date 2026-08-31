//
//  StructuredOutput.swift
//  LocalIntelligenceMCP
//
//  GSD Plan 3.2 — Extract and validate structured JSON from model output.
//

import Foundation

enum StructuredOutput {

    /// Parse JSON from model text (tolerates markdown code fences and surrounding
    /// prose) and validate it against a JSON Schema subset.
    /// Throws `CapabilityError.unsupported` for out-of-subset schemas and
    /// `CapabilityError.invalidRequest` for parse/validation failures.
    static func validate(_ text: String, against schema: [String: Any]) throws -> [String: Any] {
        try JSONSchemaValidator.validateSupported(schema)

        guard let object = extractJSONObject(from: text) else {
            throw CapabilityError.invalidRequest("Model output contained no parseable JSON object")
        }

        do {
            try JSONSchemaValidator.validate(object, against: schema)
        } catch let failure as JSONSchemaValidator.Failure {
            throw CapabilityError.invalidRequest(
                "Output failed schema validation: \(failure.errors.joined(separator: "; "))"
            )
        } catch let unsupported as JSONSchemaValidator.Unsupported {
            throw CapabilityError.unsupported(reason: unsupported.errorDescription ?? "Unsupported schema")
        }
        return object
    }

    /// Extract the first top-level JSON object from text.
    static func extractJSONObject(from text: String) -> [String: Any]? {
        var candidate = text
        // Strip markdown fences when present.
        if let fenceRange = candidate.range(of: "```") {
            let afterFence = candidate[fenceRange.upperBound...]
            if let closeRange = afterFence.range(of: "```") {
                candidate = String(afterFence[..<closeRange.lowerBound])
            }
            candidate = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
            if candidate.hasPrefix("json") {
                candidate = String(candidate.dropFirst(4)).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        let jsonData = Data(candidate.utf8)
        if let object = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
            return object
        }
        // Fall back to the outermost brace span (model may add prose around the JSON).
        guard let start = candidate.firstIndex(of: "{") else { return nil }
        guard let end = candidate.lastIndex(of: "}") else { return nil }
        guard start < end else { return nil }
        let span = String(candidate[start...end])
        return (try? JSONSerialization.jsonObject(with: Data(span.utf8))) as? [String: Any]
    }
}
