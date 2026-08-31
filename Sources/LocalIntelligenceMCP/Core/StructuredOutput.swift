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
    /// Order: fenced ```json blocks, then any fence, then a raw parse, then the
    /// outermost brace span (model may wrap JSON in prose).
    static func extractJSONObject(from text: String) -> [String: Any]? {
        // ```json ... ``` fences (language tag optional)
        if let fenceRegex = try? NSRegularExpression(pattern: "```(?:json)?\\s*(\\{[\\s\\S]*?\\})\\s*```") {
            let range = NSRange(text.startIndex..., in: text)
            if let match = fenceRegex.firstMatch(in: text, range: range),
               let span = Range(match.range(at: 1), in: text) {
                if let object = (try? JSONSerialization.jsonObject(with: Data(String(text[span]).utf8))) as? [String: Any] {
                    return object
                }
            }
        }

        if let object = (try? JSONSerialization.jsonObject(with: Data(text.utf8))) as? [String: Any] {
            return object
        }

        // Outermost brace span (model may add prose around the JSON).
        guard let start = text.firstIndex(of: "{"), let end = text.lastIndex(of: "}"), start < end else {
            return nil
        }
        return (try? JSONSerialization.jsonObject(with: Data(String(text[start...end]).utf8))) as? [String: Any]
    }
}
