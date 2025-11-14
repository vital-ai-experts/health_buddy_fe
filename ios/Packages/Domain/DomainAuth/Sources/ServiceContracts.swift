import Foundation

/// Authentication service protocol
public protocol AuthenticationService {
    /// Register a new user
    func register(email: String, password: String, fullName: String?, onboardingId: String) async throws -> User

    /// Login with email and password
    func login(email: String, password: String) async throws -> User

    /// Logout current user
    func logout() async throws

    /// Verify and refresh token if needed (根据 IDL，通过获取用户信息来验证 token)
    func verifyAndRefreshTokenIfNeeded() async throws -> Bool

    /// Get current user profile
    func getCurrentUser() async throws -> User

    /// Check if user is authenticated (has valid token)
    func isAuthenticated() -> Bool
    
    /// Check if token is expired or expiring soon
    func isTokenValid() -> Bool

    /// Get current user if authenticated
    func getCurrentUserIfAuthenticated() -> User?
}

/// Token storage protocol
public protocol TokenStorage {
    func saveToken(_ token: String) throws
    func getToken() -> String?
    func deleteToken() throws
    func saveTokenExpiry(_ expiryDate: Date) throws
    func getTokenExpiry() -> Date?
    func isTokenExpired() -> Bool
    func isTokenExpiringSoon() -> Bool
}
