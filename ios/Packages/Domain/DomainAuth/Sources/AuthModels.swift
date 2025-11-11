import Foundation

// MARK: - Request Models

public struct UserRegisterRequest: Codable {
    public let email: String
    public let password: String
    public let fullName: String?  // 根据 IDL，fullName 是可选的

    public init(email: String, password: String, fullName: String? = nil) {
        self.email = email
        self.password = password
        self.fullName = fullName
    }
    // Note: CodingKeys removed - using keyDecodingStrategy = .convertFromSnakeCase from APIClient
}

public struct UserLoginRequest: Codable {
    public let email: String
    public let password: String

    public init(email: String, password: String) {
        self.email = email
        self.password = password
    }
}

// MARK: - Response Models

public struct TokenResponse: Codable {
    public let accessToken: String
    public let tokenType: String
    public let expiresIn: Int
    // Note: CodingKeys removed - using keyDecodingStrategy = .convertFromSnakeCase from APIClient
}

public struct UserResponse: Codable {
    public let id: String
    public let email: String?  // 根据 IDL，email 是可选的
    public let fullName: String?  // 根据 IDL，fullName 是可选的
    public let createdAt: String
    public let updatedAt: String  // 根据 IDL，添加 updatedAt 字段
    // Note: CodingKeys removed - using keyDecodingStrategy = .convertFromSnakeCase from APIClient
}

// MARK: - Domain Models

public struct User {
    public let id: String
    public let email: String
    public let fullName: String
    public let createdAt: String
    public let updatedAt: String

    public init(id: String, email: String, fullName: String, createdAt: String, updatedAt: String) {
        self.id = id
        self.email = email
        self.fullName = fullName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public init(from response: UserResponse) {
        self.id = response.id
        self.email = response.email ?? ""
        self.fullName = response.fullName ?? ""
        self.createdAt = response.createdAt
        self.updatedAt = response.updatedAt
    }
}
