import Foundation

// MARK: - Request Models

public struct ChatMessageRequest: Codable {
    public let message: String
    public let conversationId: String?

    public init(message: String, conversationId: String? = nil) {
        self.message = message
        self.conversationId = conversationId
    }
    // Note: CodingKeys removed - using keyEncodingStrategy = .convertToSnakeCase from APIClient
}

// MARK: - Response Models

public struct ConversationResponse: Codable {
    public let id: String
    public let userId: String
    public let title: String?
    public let createdAt: String
    public let updatedAt: String
    // Note: CodingKeys removed - using keyDecodingStrategy = .convertFromSnakeCase from APIClient
}

public struct MessageResponse: Codable {
    public let id: String
    public let conversationId: String
    public let role: String
    public let content: String
    public let createdAt: String
    // Note: CodingKeys removed - using keyDecodingStrategy = .convertFromSnakeCase from APIClient
}

public struct ConversationWithMessagesResponse: Codable {
    public let id: String
    public let userId: String
    public let title: String?
    public let createdAt: String
    public let updatedAt: String
    public let messages: [MessageResponse]
    // Note: CodingKeys removed - using keyDecodingStrategy = .convertFromSnakeCase from APIClient
}

// MARK: - Domain Models

public struct Conversation: Identifiable {
    public let id: String
    public let userId: String
    public let title: String?
    public let createdAt: String
    public let updatedAt: String

    public init(id: String, userId: String, title: String?, createdAt: String, updatedAt: String) {
        self.id = id
        self.userId = userId
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public init(from response: ConversationResponse) {
        self.id = response.id
        self.userId = response.userId
        self.title = response.title
        self.createdAt = response.createdAt
        self.updatedAt = response.updatedAt
    }
}

public struct Message: Identifiable {
    public let id: String
    public let conversationId: String
    public let role: MessageRole
    public let content: String
    public let createdAt: String

    public init(id: String, conversationId: String, role: MessageRole, content: String, createdAt: String) {
        self.id = id
        self.conversationId = conversationId
        self.role = role
        self.content = content
        self.createdAt = createdAt
    }

    public init(from response: MessageResponse) {
        self.id = response.id
        self.conversationId = response.conversationId
        self.role = MessageRole(rawValue: response.role) ?? .assistant
        self.content = response.content
        self.createdAt = response.createdAt
    }
}

public enum MessageRole: String, Codable {
    case user
    case assistant
    case system
}

// MARK: - Streaming Events

public enum ChatStreamEvent {
    case conversationStart(conversationId: String)
    case messageStart(messageId: String)
    case contentDelta(content: String)
    case messageEnd
    case conversationEnd
    case error(String)
}
