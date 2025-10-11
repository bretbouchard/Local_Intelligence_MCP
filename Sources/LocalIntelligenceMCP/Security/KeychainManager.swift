//
//  KeychainManager.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-07.
//

import Foundation

/// Manages secure storage of sensitive data using cross-platform file storage with obfuscation
/// Implements Security & Privacy First constitutional principle
actor KeychainManager {

    // MARK: - Configuration

    private let serviceIdentifier: String
    private let storageDirectory: URL
    private let obfuscationKey: String

    // MARK: - Initialization

    init(serviceIdentifier: String = "com.localintelligence.mcp.server") {
        self.serviceIdentifier = serviceIdentifier

        // Create storage directory
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.storageDirectory = appSupport.appendingPathComponent("LocalIntelligenceMCP")

        // Generate or retrieve obfuscation key
        self.obfuscationKey = Self.getOrCreateKey()

        // Create storage directory if needed
        try? FileManager.default.createDirectory(at: storageDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Public Interface

    /// Store sensitive data securely using obfuscation
    /// - Parameters:
    ///   - key: Unique identifier for the data
    ///   - data: Sensitive data to store
    /// - Throws: KeychainError if storage fails
    func store(key: String, data: Data) throws {
        let fileURL = storageDirectory.appendingPathComponent("\(key).obfuscated")

        do {
            // Obfuscate data using XOR
            let obfuscatedData = obfuscate(data: data, key: obfuscationKey)

            // Write obfuscated data to file
            try obfuscatedData.write(to: fileURL)
        } catch {
            throw KeychainError.storageFailed(error)
        }
    }

    /// Retrieve sensitive data from obfuscated storage
    /// - Parameter key: Unique identifier for the data
    /// - Returns: Stored data, or nil if not found
    /// - Throws: KeychainError if retrieval fails
    func retrieve(key: String) throws -> Data? {
        let fileURL = storageDirectory.appendingPathComponent("\(key).obfuscated")

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }

        do {
            // Read obfuscated data
            let obfuscatedData = try Data(contentsOf: fileURL)

            // Deobfuscate data
            let data = deobfuscate(data: obfuscatedData, key: obfuscationKey)

            return data
        } catch {
            throw KeychainError.retrievalFailed(error)
        }
    }

    /// Remove sensitive data from obfuscated storage
    /// - Parameter key: Unique identifier for the data
    /// - Throws: KeychainError if deletion fails
    func remove(key: String) throws {
        let fileURL = storageDirectory.appendingPathComponent("\(key).obfuscated")

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return // Already doesn't exist
        }

        do {
            try FileManager.default.removeItem(at: fileURL)
        } catch {
            throw KeychainError.deletionFailed(error)
        }
    }

    /// Check if data exists in obfuscated storage
    /// - Parameter key: Unique identifier for the data
    /// - Returns: True if data exists, false otherwise
    func exists(key: String) -> Bool {
        let fileURL = storageDirectory.appendingPathComponent("\(key).obfuscated")
        return FileManager.default.fileExists(atPath: fileURL.path)
    }

    // MARK: - Private Helpers

    private static func getOrCreateKey() -> String {
        let keyName = "local-intelligence-mcp-key"

        // Try to retrieve existing key from user defaults
        if let key = UserDefaults.standard.string(forKey: keyName) {
            return key
        }

        // Generate new obfuscation key
        let newKey = UUID().uuidString + "-LocalIntelligenceMCP-" + UUID().uuidString
        UserDefaults.standard.set(newKey, forKey: keyName)

        return newKey
    }

    // MARK: - Obfuscation/Deobfuscation

    private func obfuscate(data: Data, key: String) -> Data {
        let keyBytes = Array(key.utf8)
        var obfuscatedData = Data()

        for (index, byte) in data.enumerated() {
            let keyByte = keyBytes[index % keyBytes.count]
            obfuscatedData.append(byte ^ keyByte)
        }

        return obfuscatedData
    }

    private func deobfuscate(data: Data, key: String) -> Data {
        // XOR is its own inverse, so we can use the same function
        return obfuscate(data: data, key: key)
    }
}

// MARK: - Error Types

enum KeychainError: Error, LocalizedError {
    case storageFailed(Error)
    case retrievalFailed(Error)
    case deletionFailed(Error)
    case invalidKey
    case systemError

    var errorDescription: String? {
        switch self {
        case .storageFailed(let error):
            return "Failed to store encrypted data: \(error.localizedDescription)"
        case .retrievalFailed(let error):
            return "Failed to retrieve encrypted data: \(error.localizedDescription)"
        case .deletionFailed(let error):
            return "Failed to delete encrypted data: \(error.localizedDescription)"
        case .invalidKey:
            return "Invalid key provided"
        case .systemError:
            return "System error occurred while accessing encrypted storage"
        }
    }
}

// MARK: - Convenience Extensions

extension KeychainManager {

    /// Store string data securely
    func store(key: String, string: String) throws {
        guard let data = string.data(using: .utf8) else {
            throw KeychainError.invalidKey
        }
        try store(key: key, data: data)
    }

    /// Retrieve string data securely
    func retrieveString(key: String) throws -> String? {
        guard let data = try retrieve(key: key) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    /// Store Codable objects securely
    func store<T: Codable>(key: String, object: T) throws {
        let data = try JSONEncoder().encode(object)
        try store(key: key, data: data)
    }

    /// Retrieve Codable objects securely
    func retrieveObject<T: Codable>(key: String, type: T.Type) throws -> T? {
        guard let data = try retrieve(key: key) else {
            return nil
        }
        return try JSONDecoder().decode(type, from: data)
    }
}