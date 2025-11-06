import Foundation

/// Authentication service protocol
public protocol AuthenticationService {
    /// Register a new user
    func register(email: String, password: String, fullName: String) async throws -> User

    /// Login with email and password
    func login(email: String, password: String) async throws -> User

    /// Logout current user
    func logout() async throws

    /// Refresh authentication token
    func refreshToken() async throws

    /// Get current user profile
    func getCurrentUser() async throws -> User

    /// Check if user is authenticated
    func isAuthenticated() -> Bool

    /// Get current user if authenticated
    func getCurrentUserIfAuthenticated() -> User?
}

/// Token storage protocol
public protocol TokenStorage {
    func saveToken(_ token: String) throws
    func getToken() -> String?
    func deleteToken() throws
}
