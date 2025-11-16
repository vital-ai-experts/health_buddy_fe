import Foundation

/// Local storage for authentication tokens using UserDefaults
/// Note: Token will be automatically cleared when app is uninstalled
public final class UserDefaultsTokenStorage {
    public static let shared = UserDefaultsTokenStorage()

    private let tokenKey = "com.hehigh.thrivebody.authToken"
    private let tokenExpiryKey = "com.hehigh.thrivebody.tokenExpiry"
    private let defaults = UserDefaults.standard

    private init() {}

    /// Save token to UserDefaults
    public func saveToken(_ token: String) throws {
        defaults.set(token, forKey: tokenKey)
    }

    /// Retrieve token from UserDefaults
    public func getToken() -> String? {
        return defaults.string(forKey: tokenKey)
    }

    /// Delete token from UserDefaults
    public func deleteToken() throws {
        defaults.removeObject(forKey: tokenKey)
        defaults.removeObject(forKey: tokenExpiryKey)
    }

    /// Save token expiry time to UserDefaults
    public func saveTokenExpiry(_ expiryDate: Date) throws {
        defaults.set(expiryDate.timeIntervalSince1970, forKey: tokenExpiryKey)
    }

    /// Retrieve token expiry time from UserDefaults
    public func getTokenExpiry() -> Date? {
        let timeInterval = defaults.double(forKey: tokenExpiryKey)
        guard timeInterval > 0 else {
            return nil
        }
        return Date(timeIntervalSince1970: timeInterval)
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

public enum TokenStorageError: LocalizedError {
    case saveFailed(OSStatus)
    case deleteFailed(OSStatus)

    public var errorDescription: String? {
        switch self {
        case .saveFailed(let status):
            return "Failed to save token (status: \(status))"
        case .deleteFailed(let status):
            return "Failed to delete token (status: \(status))"
        }
    }
}
