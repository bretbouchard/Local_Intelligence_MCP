//
//  KeychainManager.swift
//  AppleMCPServer
//
//  Created on 2025-10-07.
//

import Foundation
import Security

/// Manages secure storage of sensitive data using Apple Keychain
/// Implements Security & Privacy First constitutional principle
actor KeychainManager {

    // MARK: - Configuration

    private let serviceIdentifier: String
    private let accessGroup: String?

    // MARK: - Initialization

    init(serviceIdentifier: String = "com.apple.mcp.server", accessGroup: String? = nil) {
        self.serviceIdentifier = serviceIdentifier
        self.accessGroup = accessGroup
    }

    // MARK: - Public Interface

    /// Store sensitive data securely in Keychain
    /// - Parameters:
    ///   - key: Unique identifier for the data
    ///   - data: Sensitive data to store
    /// - Throws: KeychainError if storage fails
    func store(key: String, data: Data) throws {
        let query = createQuery(key: key)
        var addQuery = query
        addQuery[kSecValueData as String] = data

        // Delete any existing item first
        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.storageFailed(status)
        }
    }

    /// Retrieve sensitive data from Keychain
    /// - Parameter key: Unique identifier for the data
    /// - Returns: Stored data, or nil if not found
    /// - Throws: KeychainError if retrieval fails
    func retrieve(key: String) throws -> Data? {
        var query = createQuery(key: key)
        query[kSecReturnData as String] = kCFBooleanTrue
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            return result as? Data
        case errSecItemNotFound:
            return nil
        default:
            throw KeychainError.retrievalFailed(status)
        }
    }

    /// Remove sensitive data from Keychain
    /// - Parameter key: Unique identifier for the data
    /// - Throws: KeychainError if deletion fails
    func remove(key: String) throws {
        let query = createQuery(key: key)
        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deletionFailed(status)
        }
    }

    /// Check if data exists in Keychain
    /// - Parameter key: Unique identifier for the data
    /// - Returns: True if data exists, false otherwise
    func exists(key: String) -> Bool {
        let query = createQuery(key: key)
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    // MARK: - Private Helpers

    private func createQuery(key: String) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: key
        ]

        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }

        return query
    }
}

// MARK: - Error Types

enum KeychainError: Error, LocalizedError {
    case storageFailed(OSStatus)
    case retrievalFailed(OSStatus)
    case deletionFailed(OSStatus)
    case invalidKey
    case systemError

    var errorDescription: String? {
        switch self {
        case .storageFailed(let status):
            let errorMessage = SecCopyErrorMessageString(status, nil)
            return "Failed to store data in Keychain: \(errorMessage as String? ?? "Unknown error")"
        case .retrievalFailed(let status):
            let errorMessage = SecCopyErrorMessageString(status, nil)
            return "Failed to retrieve data from Keychain: \(errorMessage as String? ?? "Unknown error")"
        case .deletionFailed(let status):
            let errorMessage = SecCopyErrorMessageString(status, nil)
            return "Failed to delete data from Keychain: \(errorMessage as String? ?? "Unknown error")"
        case .invalidKey:
            return "Invalid key provided"
        case .systemError:
            return "System error occurred while accessing Keychain"
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