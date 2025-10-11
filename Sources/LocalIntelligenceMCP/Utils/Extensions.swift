//
//  Extensions.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-07.
//

import Foundation

// MARK: - Error Handling Extensions
// Note: Error.mcpError extension is in Types.swift to avoid conflicts

// Result extension moved to Types.swift to avoid conflicts

// MARK: - Validation Extensions

extension String {
    /// Validate as MCP tool name
    var isValidMCPToolName: Bool {
        let pattern = "^[a-zA-Z][a-zA-Z0-9_.]*$"
        return range(of: pattern, options: .regularExpression) != nil && count <= 64
    }

    /// Validate as shortcut name
    var isValidShortcutName: Bool {
        return !isEmpty && count <= 255
    }

    /// Validate as voice command phrase
    var isValidVoiceCommand: Bool {
        return !isEmpty && count <= 1000
    }

    /// Check if string contains sensitive data patterns
    func looksLikeSensitiveData() -> Bool {
        let patterns = [
            "^[A-Za-z0-9+/]{40,}=$",  // Base64 encoded data
            "^[a-f0-9]{32,}$",         // Hexadecimal
            "sk_[a-zA-Z0-9]{20,}",      // API key pattern
            "[0-9]{4}-[0-9]{4}-[0-9]{4}-[0-9]{4}"  // UUID pattern
        ]

        for pattern in patterns {
            if range(of: pattern, options: .regularExpression) != nil {
                return true
            }
        }
        return false
    }

    /// Sanitize for logging
    var sanitizedForLogging: String {
        if looksLikeSensitiveData(self) {
            return "[REDACTED]"
        }
        return self
    }

    func looksLikeSensitiveData(_ string: String) -> Bool {
        let patterns = [
            "^[A-Za-z0-9+/]{40,}=$",  // Base64 encoded data
            "^[a-f0-9]{32,}$",         // Hexadecimal
            "sk_[a-zA-Z0-9]{20,}",      // API key pattern
            "[0-9]{4}-[0-9]{4}-[0-9]{4}-[0-9]{4}"  // UUID pattern
        ]

        return patterns.contains { pattern in
            range(of: pattern, options: .regularExpression) != nil
        }
    }
}

// MARK: - Dictionary Extensions

extension Dictionary where Key == String, Value == Any {
    /// Sanitize dictionary for logging by removing sensitive data
    func sanitizedForLogging() -> [String: Any] {
        var sanitized = self

        // Remove known sensitive keys
        let sensitiveKeys = ["password", "secret", "key", "token", "credential", "apiKey", "authorization"]
        for key in sensitiveKeys {
            sanitized.removeValue(forKey: key)
        }

        // Sanitize values that might contain sensitive data
        for (key, value) in sanitized {
            if let stringValue = value as? String {
                if stringValue.looksLikeSensitiveData() {
                    sanitized[key] = "[REDACTED]"
                }
            }
        }

        return sanitized
    }

    /// Get value with type safety and default
    func value<T>(for key: String, default defaultValue: T) -> T {
        return (self[key] as? T) ?? defaultValue
    }

    /// Get optional value with type safety
    func optionalValue<T>(for key: String) -> T? {
        return self[key] as? T
    }
}

// MARK: - JSON Extensions

extension Encodable {
    /// Convert to JSON Data
    func jsonData() throws -> Data {
        return try JSONEncoder().encode(self)
    }

    /// Convert to JSON String
    func jsonString() throws -> String {
        let data = try jsonData()
        return String(data: data, encoding: .utf8) ?? ""
    }
}

extension Decodable {
    /// Initialize from JSON Data
    init(jsonData: Data) throws {
        self = try JSONDecoder().decode(Self.self, from: jsonData)
    }

    /// Initialize from JSON String
    init(jsonString: String) throws {
        guard let data = jsonString.data(using: .utf8) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Invalid UTF-8 string"))
        }
        try self.init(jsonData: data)
    }
}

// MARK: - Date Extensions

extension Date {
    /// Format as ISO8601 string
    var iso8601String: String {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone.current
        return formatter.string(from: self)
    }

    /// Check if date is in the past
    var isPast: Bool {
        return self < Date()
    }

    /// Check if date is within specified interval from now
    func isWithin(_ interval: TimeInterval) -> Bool {
        let now = Date()
        return self >= now.addingTimeInterval(-interval) && self <= now.addingTimeInterval(interval)
    }
}

// MARK: - UUID Extensions

extension UUID {
    /// Generate a short UUID (first 8 characters)
    static func shortUUID() -> String {
        return UUID().uuidString.prefix(8).description
    }
}

// MARK: - Array Extensions

extension Array {
    /// Safe subscript with default value
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }

    /// Chunk array into smaller arrays
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

// MARK: - URL Extensions

extension URL {
    /// Append path component safely (using built-in method)
    func safeAppendPathComponent(_ component: String) -> URL {
        return self.appending(path: component)
    }

    /// Check if URL exists
    var exists: Bool {
        return FileManager.default.fileExists(atPath: self.path)
    }

    /// Create directory if it doesn't exist
    func createDirectory() throws {
        let directory = self.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }
}

// MARK: - ProcessInfo Extensions

extension ProcessInfo {
    /// Get environment variable with default value
    func environmentVariable(_ key: String, default defaultValue: String = "") -> String {
        return environment[key] ?? defaultValue
    }

    /// Check if running in debug mode
    var isDebugging: Bool {
        return environment["DEBUG"] != nil
    }
}

// MARK: - Actor Extensions

extension Actor {
    /// Execute code on actor with timeout
    func withTimeout<T: Sendable>(_ timeout: TimeInterval, operation: @escaping @Sendable () async throws -> T) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                return try await operation()
            }

            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw LocalMCPError.timeout
            }

            guard let result = try await group.next() else {
                throw LocalMCPError.timeout
            }
            group.cancelAll()
            return result
        }
    }
}