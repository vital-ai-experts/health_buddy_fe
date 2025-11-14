import Foundation
import DomainOnboarding  // 导入共享的StreamMessage等模型

// MARK: - Request Models

/// 发送对话消息请求（IDL: SendConversationMessageReq）
public struct SendConversationMessageRequest: Codable {
    public let conversationId: String?  // 如果为空，则创建新对话
    public let userInput: String?

    public init(conversationId: String? = nil, userInput: String? = nil) {
        self.conversationId = conversationId
        self.userInput = userInput
    }
}

/// 恢复对话消息请求（IDL: ResumeConversationMessageReq）
public struct ResumeConversationMessageRequest: Codable {
    public let conversationId: String
    public let lastDataId: String?

    public init(conversationId: String, lastDataId: String? = nil) {
        self.conversationId = conversationId
        self.lastDataId = lastDataId
    }
}

// MARK: - Response Models

/// Base响应（IDL: BaseResp）
public struct BaseResp: Codable {
    public let code: Int
    public let message: String
}

/// 发送对话消息响应（IDL: SendConversationMessageResp）
public struct SendConversationMessageResponse: Codable {
    public let baseResp: BaseResp
}

/// 恢复对话消息响应（IDL: ResumeConversationMessageResp）
public struct ResumeConversationMessageResponse: Codable {
    public let baseResp: BaseResp
}

/// 对话列表项（IDL: Conversation）
public struct ConversationResponse: Codable {
    public let conversationId: String
    public let createdAt: String
    public let updatedAt: String
}

/// 对话列表响应（IDL: ListConversationsResp）
public struct ListConversationsResponse: Codable {
    public let conversations: [ConversationResponse]
}

/// 角色（IDL: Role）
public enum Role: Int, Codable {
    case user = 1         // ROLE_USER
    case assistant = 2    // ROLE_ASSISTANT
}

/// 用户消息数据（IDL: UserMessageData）
public struct UserMessageData: Codable {
    public let userInput: String?
}

/// 对话历史消息（IDL: ConversationMessage）
public struct ConversationMessage: Codable {
    public let role: Role
    public let data: StreamMessageData?       // Agent消息数据
    public let userData: UserMessageData?     // 用户消息数据
    public let createdAt: String
}

/// 对话历史响应（IDL: GetConversationHistoryResp）
public struct GetConversationHistoryResponse: Codable {
    public let messages: [ConversationMessage]
}

// MARK: - Domain Models

/// 对话领域模型
public struct Conversation: Identifiable {
    public let id: String
    public let title: String?
    public let createdAt: String
    public let updatedAt: String

    public init(id: String, title: String?, createdAt: String, updatedAt: String) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public init(from response: ConversationResponse) {
        self.id = response.conversationId
        self.title = nil  // IDL中的Conversation没有title字段
        self.createdAt = response.createdAt
        self.updatedAt = response.updatedAt
    }
}

/// 消息领域模型（用于历史消息）
public struct Message: Identifiable {
    public let id: String
    public let conversationId: String
    public let role: Role
    public let content: String
    public let createdAt: String
    public let thinkingContent: String?
    public let toolCalls: [ToolCall]?

    public init(
        id: String,
        conversationId: String,
        role: Role,
        content: String,
        createdAt: String,
        thinkingContent: String? = nil,
        toolCalls: [ToolCall]? = nil
    ) {
        self.id = id
        self.conversationId = conversationId
        self.role = role
        self.content = content
        self.createdAt = createdAt
        self.thinkingContent = thinkingContent
        self.toolCalls = toolCalls
    }

    public init(from response: ConversationMessage, conversationId: String) {
        self.id = response.data?.msgId ?? UUID().uuidString
        self.conversationId = conversationId
        self.role = response.role

        // 用户消息使用userData，Agent消息使用data
        if response.role == .user {
            self.content = response.userData?.userInput ?? ""
            self.thinkingContent = nil
            self.toolCalls = nil
        } else {
            self.content = response.data?.content ?? ""
            self.thinkingContent = response.data?.thinkingContent
            self.toolCalls = response.data?.toolCalls
        }

        self.createdAt = response.createdAt
    }
}

// MARK: - Streaming Events

/// 对话流事件（类似OnboardingStreamEvent）
public enum ConversationStreamEvent {
    case streamMessage(StreamMessage)  // 复用DomainOnboarding的StreamMessage
    case error(String)
}
