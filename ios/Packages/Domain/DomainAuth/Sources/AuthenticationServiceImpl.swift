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
            print("🔑 [AuthService] 初始化时从 Keychain 恢复 token: \(token.prefix(20))...")
            if let expiry = tokenStorage.getTokenExpiry() {
                print("🔑 [AuthService] Token 过期时间: \(expiry)")
                print("🔑 [AuthService] 当前时间: \(Date())")
                print("🔑 [AuthService] Token 是否过期: \(tokenStorage.isTokenExpired())")
            } else {
                print("⚠️ [AuthService] 没有找到 token 过期时间")
            }
            apiClient.setAuthToken(token)
        } else {
            print("⚠️ [AuthService] Keychain 中没有 token")
        }
    }

    public func register(email: String, password: String, fullName: String?, onboardingId: String) async throws -> User {
        let request = UserRegisterRequest(email: email, password: password, fullName: fullName, onboardingId: onboardingId)

        let endpoint = APIEndpoint(
            path: "/auth/register",
            method: .post,
            body: request,
            requiresAuth: false
        )

        let tokenResponse: TokenResponse = try await apiClient.request(endpoint, responseType: TokenResponse.self)

        // Save token and expiry time
        try saveTokenWithExpiry(token: tokenResponse.accessToken, expiresIn: tokenResponse.expiresIn)

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

        print("🔑 [AuthService] 登录成功，收到 token: \(tokenResponse.accessToken.prefix(20))...")
        print("🔑 [AuthService] Token 有效期（秒）: \(tokenResponse.expiresIn)")

        // Save token and expiry time
        try saveTokenWithExpiry(token: tokenResponse.accessToken, expiresIn: tokenResponse.expiresIn)

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

    /// 根据 IDL，通过获取用户信息来验证 token 是否有效
    /// 如果 token 即将过期或已过期，返回 false
    public func verifyAndRefreshTokenIfNeeded() async throws -> Bool {
        // 检查是否有 token
        guard tokenStorage.getToken() != nil else {
            return false
        }
        
        // 检查 token 是否过期
        if tokenStorage.isTokenExpired() {
            // Token 已过期，无法刷新（因为 IDL 中没有 refresh 接口）
            return false
        }
        
        // 检查 token 是否即将过期（5分钟内）
        if tokenStorage.isTokenExpiringSoon() {
            // Token 即将过期，尝试获取用户信息来验证
            do {
                _ = try await getCurrentUser()
                return true
            } catch {
                // 获取失败，token 可能无效
                return false
            }
        }
        
        // Token 有效且未过期
        return true
    }

    public func getCurrentUser() async throws -> User {
        // 根据 IDL，用户信息接口路径为 /user/info
        let endpoint = APIEndpoint(
            path: "/user/info",
            method: .get,
            requiresAuth: true
        )

        let userResponse: UserResponse = try await apiClient.request(endpoint, responseType: UserResponse.self)
        let user = User(from: userResponse)
        self.currentUser = user

        return user
    }

    public func isAuthenticated() -> Bool {
        let hasToken = tokenStorage.getToken() != nil
        let isExpired = tokenStorage.isTokenExpired()
        let isAuth = hasToken && !isExpired

        print("🔑 [AuthService] isAuthenticated 检查:")
        print("  - 有 token: \(hasToken)")
        print("  - token 已过期: \(isExpired)")
        print("  - 最终结果: \(isAuth)")

        return isAuth
    }
    
    public func isTokenValid() -> Bool {
        guard tokenStorage.getToken() != nil else {
            return false
        }
        return !tokenStorage.isTokenExpired()
    }

    public func getCurrentUserIfAuthenticated() -> User? {
        return currentUser
    }
    
    // MARK: - Private Methods
    
    /// 保存 token 和过期时间
    private func saveTokenWithExpiry(token: String, expiresIn: Int) throws {
        print("🔑 [AuthService] 开始保存 token 到 Keychain...")
        try tokenStorage.saveToken(token)
        print("🔑 [AuthService] Token 保存成功")

        apiClient.setAuthToken(token)

        // 计算过期时间（当前时间 + expiresIn 秒）
        let expiryDate = Date().addingTimeInterval(TimeInterval(expiresIn))
        print("🔑 [AuthService] 计算过期时间: \(expiryDate)")

        try tokenStorage.saveTokenExpiry(expiryDate)
        print("🔑 [AuthService] 过期时间保存成功")

        // 验证保存
        if let savedToken = tokenStorage.getToken() {
            print("🔑 [AuthService] 验证：成功读取保存的 token: \(savedToken.prefix(20))...")
        } else {
            print("❌ [AuthService] 验证失败：无法读取刚保存的 token")
        }

        if let savedExpiry = tokenStorage.getTokenExpiry() {
            print("🔑 [AuthService] 验证：成功读取保存的过期时间: \(savedExpiry)")
        } else {
            print("❌ [AuthService] 验证失败：无法读取刚保存的过期时间")
        }
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
    
    public func saveTokenExpiry(_ expiryDate: Date) throws {
        try keychainManager.saveTokenExpiry(expiryDate)
    }
    
    public func getTokenExpiry() -> Date? {
        return keychainManager.getTokenExpiry()
    }
    
    public func isTokenExpired() -> Bool {
        return keychainManager.isTokenExpired()
    }
    
    public func isTokenExpiringSoon() -> Bool {
        return keychainManager.isTokenExpiringSoon()
    }
}
