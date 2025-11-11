import Foundation
import Security

/// Secure storage for authentication tokens using Keychain
public final class KeychainManager {
    public static let shared = KeychainManager()

    private let service = "com.thrivebuddy.auth"
    private let tokenKey = "authToken"
    private let tokenExpiryKey = "tokenExpiry"

    private init() {}

    /// Save token to Keychain
    public func saveToken(_ token: String) throws {
        let data = token.data(using: .utf8)!

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: tokenKey,
            kSecValueData as String: data
        ]

        // Delete existing item first
        SecItemDelete(query as CFDictionary)

        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    /// Retrieve token from Keychain
    public func getToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: tokenKey,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }

        return token
    }

    /// Delete token from Keychain
    public func deleteToken() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: tokenKey
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
        
        // 同时删除过期时间
        try? deleteTokenExpiry()
    }
    
    /// Save token expiry time to Keychain
    public func saveTokenExpiry(_ expiryDate: Date) throws {
        let timestamp = String(expiryDate.timeIntervalSince1970)
        let data = timestamp.data(using: .utf8)!

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: tokenExpiryKey,
            kSecValueData as String: data
        ]

        // Delete existing item first
        SecItemDelete(query as CFDictionary)

        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    /// Retrieve token expiry time from Keychain
    public func getTokenExpiry() -> Date? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: tokenExpiryKey,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let timestamp = String(data: data, encoding: .utf8),
              let timeInterval = TimeInterval(timestamp) else {
            return nil
        }

        return Date(timeIntervalSince1970: timeInterval)
    }
    
    /// Delete token expiry time from Keychain
    private func deleteTokenExpiry() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: tokenExpiryKey
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
    
    /// Check if token is expired
    public func isTokenExpired() -> Bool {
        guard let expiry = getTokenExpiry() else {
            return true // 没有过期时间信息，认为已过期
        }
        return Date() >= expiry
    }
    
    /// Check if token will expire soon (within 5 minutes)
    public func isTokenExpiringSoon() -> Bool {
        guard let expiry = getTokenExpiry() else {
            return true
        }
        let fiveMinutesFromNow = Date().addingTimeInterval(5 * 60)
        return fiveMinutesFromNow >= expiry
    }
}

public enum KeychainError: LocalizedError {
    case saveFailed(OSStatus)
    case deleteFailed(OSStatus)

    public var errorDescription: String? {
        switch self {
        case .saveFailed(let status):
            return "Failed to save to Keychain (status: \(status))"
        case .deleteFailed(let status):
            return "Failed to delete from Keychain (status: \(status))"
        }
    }
}
