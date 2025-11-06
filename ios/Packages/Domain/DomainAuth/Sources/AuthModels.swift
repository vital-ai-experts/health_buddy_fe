import Foundation

// MARK: - Request Models

public struct UserRegisterRequest: Codable {
    public let email: String
    public let password: String
    public let fullName: String

    public init(email: String, password: String, fullName: String) {
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
    public let email: String
    public let fullName: String
    public let isActive: Bool
    public let createdAt: String  // Changed from Date to String to avoid date parsing issues
    // Note: CodingKeys removed - using keyDecodingStrategy = .convertFromSnakeCase from APIClient
}

// MARK: - Domain Models

public struct User {
    public let id: String
    public let email: String
    public let fullName: String
    public let isActive: Bool
    public let createdAt: String

    public init(id: String, email: String, fullName: String, isActive: Bool, createdAt: String) {
        self.id = id
        self.email = email
        self.fullName = fullName
        self.isActive = isActive
        self.createdAt = createdAt
    }

    public init(from response: UserResponse) {
        self.id = response.id
        self.email = response.email
        self.fullName = response.fullName
        self.isActive = response.isActive
        self.createdAt = response.createdAt
    }
}
