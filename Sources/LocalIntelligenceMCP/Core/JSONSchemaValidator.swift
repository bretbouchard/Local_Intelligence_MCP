//
//  JSONSchemaValidator.swift
//  LocalIntelligenceMCP
//
//  GSD Plan 3.2 / M9 — Minimal JSON Schema (draft 2020-12 subset) validation
//  for structured generation results at the MCP boundary.
//  Unsupported constructs are rejected EXPLICITLY rather than ignored
//  (silently degrading validation would be a false success).
//

import Foundation

enum JSONSchemaValidator {

    struct Unsupported: Error, LocalizedError {
        let keywords: [String]
        var errorDescription: String? {
            "Unsupported JSON Schema keywords: \(keywords.joined(separator: ", ")). "
            + "Supported subset: type, properties, required, items, enum, minimum, maximum, minLength, maxLength, minItems, maxItems, additionalProperties."
        }
    }

    struct Failure: Error, LocalizedError {
        let errors: [String]
        var errorDescription: String? { errors.joined(separator: "; ") }
    }

    private static let supportedKeywords: Set<String> = [
        "$schema", "type", "properties", "required", "items", "enum",
        "minimum", "maximum", "minLength", "maxLength", "minItems", "maxItems",
        "additionalProperties", "description",
    ]

    /// Reject schemas containing constructs this validator does not implement.
    /// The walk is structure-aware: keys under `properties` are property names,
    /// not keywords, and `enum` values are literals.
    static func validateSupported(_ schema: [String: Any]) throws {
        var unsupported = Set<String>()
        func walkSchema(_ node: Any) {
            guard let dict = node as? [String: Any] else { return }
            for (key, value) in dict {
                if !supportedKeywords.contains(key) {
                    unsupported.insert(key)
                    continue
                }
                switch key {
                case "properties":
                    if let properties = value as? [String: Any] {
                        properties.values.forEach(walkSchema)
                    }
                case "items":
                    walkSchema(value)
                case "additionalProperties":
                    // Boolean form is supported; schema form is not implemented.
                    if !(value is Bool) {
                        unsupported.insert("additionalProperties (schema form)")
                    }
                case "minimum", "maximum", "minLength", "maxLength", "minItems", "maxItems":
                    // Bounds are meaningless without the matching type; silently
                    // ignoring them would be a false validation pass.
                    if dict["type"] == nil {
                        unsupported.insert("\(key) requires an explicit \"type\"")
                    }
                default:
                    break // literal values (type, required, enum, bounds, ...)
                }
            }
        }
        walkSchema(schema)
        if !unsupported.isEmpty {
            throw Unsupported(keywords: unsupported.sorted())
        }
    }

    /// Validate a decoded JSON value against a schema. Throws `Failure` listing
    /// every violation, or `Unsupported` for out-of-subset schemas.
    static func validate(_ value: Any, against schema: [String: Any]) throws {
        try validateSupported(schema)
        var errors: [String] = []
        validateValue(value, schema: schema, path: "$", errors: &errors, limit: 50)
        if !errors.isEmpty {
            throw Failure(errors: errors)
        }
    }

    private static func validateValue(_ value: Any, schema: [String: Any], path: String, errors: inout [String], limit: Int) {
        guard errors.count < limit else { return }
        // enum constraint
        if let allowed = schema["enum"] as? [Any] {
            let matches = allowed.contains { jsonEqual($0, value) }
            if !matches {
                errors.append("\(path): value not in enum")
                return
            }
        }

        switch schema["type"] as? String {
        case "object":
            guard let dict = value as? [String: Any] else {
                errors.append("\(path): expected object")
                return
            }
            let properties = schema["properties"] as? [String: Any] ?? [:]
            if let required = schema["required"] as? [String] {
                for key in required where dict[key] == nil {
                    errors.append("\(path).\(key): required property missing")
                }
            }
            let allowAdditional = schema["additionalProperties"] as? Bool ?? true
            if !allowAdditional {
                for key in dict.keys where properties[key] == nil {
                    errors.append("\(path).\(key): additional property not allowed")
                }
            }
            for (key, subschema) in properties {
                if let subvalue = dict[key] {
                    validateValue(subvalue, schema: subschema as? [String: Any] ?? [:], path: "\(path).\(key)", errors: &errors, limit: limit)
                }
            }

        case "array":
            guard let array = value as? [Any] else {
                errors.append("\(path): expected array")
                return
            }
            if let minItems = schema["minItems"] as? Int, array.count < minItems {
                errors.append("\(path): fewer than minItems (\(minItems))")
            }
            if let maxItems = schema["maxItems"] as? Int, array.count > maxItems {
                errors.append("\(path): more than maxItems (\(maxItems))")
            }
            if let itemsSchema = schema["items"] as? [String: Any] {
                for (index, element) in array.enumerated() {
                    validateValue(element, schema: itemsSchema, path: "\(path)[\(index)]", errors: &errors, limit: limit)
                }
            }

        case "string":
            guard let string = value as? String else {
                errors.append("\(path): expected string")
                return
            }
            if let minLength = schema["minLength"] as? Int, string.count < minLength {
                errors.append("\(path): shorter than minLength (\(minLength))")
            }
            if let maxLength = schema["maxLength"] as? Int, string.count > maxLength {
                errors.append("\(path): longer than maxLength (\(maxLength))")
            }

        case "integer":
            guard let number = asDouble(value), number.truncatingRemainder(dividingBy: 1) == 0 else {
                errors.append("\(path): expected integer")
                return
            }
            applyNumericBounds(number, schema: schema, path: path, errors: &errors)

        case "number":
            guard let number = asDouble(value) else {
                errors.append("\(path): expected number")
                return
            }
            applyNumericBounds(number, schema: schema, path: path, errors: &errors)

        case "boolean":
            if !(value is Bool) {
                errors.append("\(path): expected boolean")
            }

        case "null":
            if value is NSNull {
                return
            }
            errors.append("\(path): expected null")

        case nil:
            // Type-less schema (e.g. bare enum): the enum check above applies.
            break

        case .some(let unknown):
            errors.append("\(path): unsupported schema type \(unknown)")
        }
    }

    private static func applyNumericBounds(_ number: Double, schema: [String: Any], path: String, errors: inout [String]) {
        if let minimum = schema["minimum"] as? Double, number < minimum {
            errors.append("\(path): below minimum (\(minimum))")
        }
        if let maximum = schema["maximum"] as? Double, number > maximum {
            errors.append("\(path): above maximum (\(maximum))")
        }
    }

    private static func asDouble(_ value: Any) -> Double? {
        if let double = value as? Double { return double }
        if let int = value as? Int { return Double(int) }
        if let number = value as? NSNumber { return number.doubleValue }
        return nil
    }

    /// JSON equality with strict types: booleans, strings and numbers are
    /// distinct JSON types — `true` never equals `"true"`, `1` never equals `"1"`.
    private static func jsonEqual(_ lhs: Any, _ rhs: Any) -> Bool {
        switch (lhs, rhs) {
        case (let l as Bool, let r as Bool):
            return l == r
        case (let l as String, let r as String):
            return l == r
        case (is NSNull, is NSNull):
            return true
        case (let l as [Any], let r as [Any]):
            return l.count == r.count && zip(l, r).allSatisfy(jsonEqual)
        case (let l as [String: Any], let r as [String: Any]):
            return l.count == r.count && l.allSatisfy { key, value in
                (r[key]).map { jsonEqual($0, value) } ?? false
            }
        default:
            if let l = asDouble(lhs), let r = asDouble(rhs),
               !(lhs is Bool), !(rhs is Bool), !(lhs is String), !(rhs is String) {
                return l == r
            }
            return false
        }
    }
}
