import Foundation
import LibraryNetworking

/// Default implementation of AuthenticationService
public final class AuthenticationServiceImpl: AuthenticationService {
    private let apiClient: APIClient
    private let tokenStorage: TokenStorage
    private var currentUser: User?

    public init(
        apiClient: APIClient = .shared,
        tokenStorage: TokenStorage = KeychainTokenStorage()
    ) {
        self.apiClient = apiClient
        self.tokenStorage = tokenStorage

        // Restore token if available
        if let token = tokenStorage.getToken() {
            apiClient.setAuthToken(token)
        }
    }

    public func register(email: String, password: String, fullName: String) async throws -> User {
        let request = UserRegisterRequest(email: email, password: password, fullName: fullName)

        let endpoint = APIEndpoint(
            path: "/auth/register",
            method: .post,
            body: request,
            requiresAuth: false
        )

        let tokenResponse: TokenResponse = try await apiClient.request(endpoint, responseType: TokenResponse.self)

        // Save token
        try tokenStorage.saveToken(tokenResponse.accessToken)
        apiClient.setAuthToken(tokenResponse.accessToken)

        // Fetch user profile
        let user = try await getCurrentUser()
        self.currentUser = user

        return user
    }

    public func login(email: String, password: String) async throws -> User {
        let request = UserLoginRequest(email: email, password: password)

        let endpoint = APIEndpoint(
            path: "/auth/login",
            method: .post,
            body: request,
            requiresAuth: false
        )

        let tokenResponse: TokenResponse = try await apiClient.request(endpoint, responseType: TokenResponse.self)

        // Save token
        try tokenStorage.saveToken(tokenResponse.accessToken)
        apiClient.setAuthToken(tokenResponse.accessToken)

        // Fetch user profile
        let user = try await getCurrentUser()
        self.currentUser = user

        return user
    }

    public func logout() async throws {
        try tokenStorage.deleteToken()
        apiClient.setAuthToken(nil)
        currentUser = nil
    }

    public func refreshToken() async throws {
        let endpoint = APIEndpoint(
            path: "/auth/refresh",
            method: .post,
            requiresAuth: true
        )

        let tokenResponse: TokenResponse = try await apiClient.request(endpoint, responseType: TokenResponse.self)

        // Save new token
        try tokenStorage.saveToken(tokenResponse.accessToken)
        apiClient.setAuthToken(tokenResponse.accessToken)
    }

    public func getCurrentUser() async throws -> User {
        let endpoint = APIEndpoint(
            path: "/auth/me",
            method: .get,
            requiresAuth: true
        )

        let userResponse: UserResponse = try await apiClient.request(endpoint, responseType: UserResponse.self)
        let user = User(from: userResponse)
        self.currentUser = user

        return user
    }

    public func isAuthenticated() -> Bool {
        return tokenStorage.getToken() != nil
    }

    public func getCurrentUserIfAuthenticated() -> User? {
        return currentUser
    }
}

/// Keychain-based token storage
public final class KeychainTokenStorage: TokenStorage {
    private let keychainManager: KeychainManager

    public init(keychainManager: KeychainManager = .shared) {
        self.keychainManager = keychainManager
    }

    public func saveToken(_ token: String) throws {
        try keychainManager.saveToken(token)
    }

    public func getToken() -> String? {
        return keychainManager.getToken()
    }

    public func deleteToken() throws {
        try keychainManager.deleteToken()
    }
}
