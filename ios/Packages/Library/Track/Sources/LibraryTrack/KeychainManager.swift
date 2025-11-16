//
//  KeychainManager.swift
//  LibraryTrack
//
//  Keychain storage manager for secure data persistence
//

import Foundation
import Security

/// Manager for storing and retrieving data from Keychain
public final class KeychainManager {
    /// Shared singleton instance
    public static let shared = KeychainManager()

    private init() {}

    // MARK: - Public Methods

    /// Save a string value to Keychain
    /// - Parameters:
    ///   - value: The string value to save
    ///   - key: The key to store the value under
    /// - Throws: KeychainError if the operation fails
    public func save(_ value: String, forKey key: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.encodingFailed
        }

        // Check if item already exists
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: KeychainManager.serviceName
        ]

        let status = SecItemCopyMatching(query as CFDictionary, nil)

        if status == errSecSuccess {
            // Item exists, update it
            let attributes: [String: Any] = [
                kSecValueData as String: data
            ]

            let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
            guard updateStatus == errSecSuccess else {
                throw KeychainError.updateFailed(status: updateStatus)
            }
        } else if status == errSecItemNotFound {
            // Item doesn't exist, add it
            var addQuery = query
            addQuery[kSecValueData as String] = data

            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw KeychainError.saveFailed(status: addStatus)
            }
        } else {
            throw KeychainError.unexpectedStatus(status: status)
        }
    }

    /// Retrieve a string value from Keychain
    /// - Parameter key: The key to retrieve the value for
    /// - Returns: The string value if found, nil otherwise
    public func get(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: KeychainManager.serviceName,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }

        return value
    }

    /// Delete a value from Keychain
    /// - Parameter key: The key to delete
    /// - Throws: KeychainError if the operation fails
    public func delete(forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: KeychainManager.serviceName
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status: status)
        }
    }

    // MARK: - Private Properties

    private static let serviceName = "com.hehigh.thrivebody.keychain"
}

// MARK: - Error Types

public enum KeychainError: LocalizedError {
    case encodingFailed
    case saveFailed(status: OSStatus)
    case updateFailed(status: OSStatus)
    case deleteFailed(status: OSStatus)
    case unexpectedStatus(status: OSStatus)

    public var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode string to data"
        case .saveFailed(let status):
            return "Failed to save to Keychain (status: \(status))"
        case .updateFailed(let status):
            return "Failed to update Keychain item (status: \(status))"
        case .deleteFailed(let status):
            return "Failed to delete from Keychain (status: \(status))"
        case .unexpectedStatus(let status):
            return "Unexpected Keychain status (status: \(status))"
        }
    }
}
