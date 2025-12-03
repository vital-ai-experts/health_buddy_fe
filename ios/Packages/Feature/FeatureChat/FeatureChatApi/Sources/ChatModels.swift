import Foundation
import LibraryChatUI

// MARK: - Shared SSE Stream Models

public enum MessageType: Int, Codable {
    case chunk = 1
    case whole = 2
}

public enum DataType: Int, Codable {
    case agentStatus = 1
    case agentMessage = 2
    case agentToolCall = 3
}

public enum AgentStatus: Int, Codable {
    case generating = 1
    case finished = 2
    case error = 3
    case stopped = 4
}

public enum ToolCallStatus: Int, Codable {
    case started = 1
    case success = 2
    case failed = 3

    public var description: String {
        switch self {
        case .started: return "开始"
        case .success: return "成功"
        case .failed: return "失败"
        }
    }
}

public struct ToolCall: Codable {
    public let toolCallId: String
    public let toolCallName: String
    public let toolCallArgs: String?
    public let toolCallStatus: ToolCallStatus?
    public let toolCallResult: String?

    public init(
        toolCallId: String,
        toolCallName: String,
        toolCallArgs: String? = nil,
        toolCallStatus: ToolCallStatus? = nil,
        toolCallResult: String? = nil
    ) {
        self.toolCallId = toolCallId
        self.toolCallName = toolCallName
        self.toolCallArgs = toolCallArgs
        self.toolCallStatus = toolCallStatus
        self.toolCallResult = toolCallResult
    }
}

public struct StreamMessageData: Codable {
    public let conversationId: String?
    public let onboardingId: String?
    public let msgId: String
    public let dataType: DataType
    public let msgIdx: Int?
    public let agentStatus: AgentStatus?
    public let messageType: MessageType?
    public let thinkingContent: String?
    public let content: String?
    public let toolCalls: [ToolCall]?
    public let specialMessageType: String?
    public let specialMessageData: String?

    public init(
        conversationId: String? = nil,
        onboardingId: String? = nil,
        msgId: String,
        dataType: DataType,
        msgIdx: Int? = nil,
        agentStatus: AgentStatus? = nil,
        messageType: MessageType? = nil,
        thinkingContent: String? = nil,
        content: String? = nil,
        toolCalls: [ToolCall]? = nil,
        specialMessageType: String? = nil,
        specialMessageData: String? = nil
    ) {
        self.conversationId = conversationId
        self.onboardingId = onboardingId
        self.msgId = msgId
        self.dataType = dataType
        self.msgIdx = msgIdx
        self.agentStatus = agentStatus
        self.messageType = messageType
        self.thinkingContent = thinkingContent
        self.content = content
        self.toolCalls = toolCalls
        self.specialMessageType = specialMessageType
        self.specialMessageData = specialMessageData
    }
}

public struct StreamMessage: Codable {
    public let id: String
    public let data: StreamMessageData

    public init(id: String, data: StreamMessageData) {
        self.id = id
        self.data = data
    }
}

// MARK: - Requests / Responses

public struct SendConversationMessageRequest: Codable {
    public let conversationId: String?
    public let userInput: String?

    public init(conversationId: String? = nil, userInput: String? = nil) {
        self.conversationId = conversationId
        self.userInput = userInput
    }
}

public struct ResumeConversationMessageRequest: Codable {
    public let conversationId: String
    public let lastDataId: String?

    public init(conversationId: String, lastDataId: String? = nil) {
        self.conversationId = conversationId
        self.lastDataId = lastDataId
    }
}

public struct BaseResp: Codable {
    public let code: Int
    public let message: String
}

public struct ConversationResponse: Codable {
    public let conversationId: String
    public let createdAt: String
}

public struct ListConversationsResponse: Codable {
    public let conversations: [ConversationResponse]
}

public enum Role: Int, Codable {
    case user = 1
    case assistant = 2
}

public struct UserMessageData: Codable {
    public let userInput: String?
}

public struct ConversationMessage: Codable {
    public let role: Role
    public let data: StreamMessageData?
    public let userData: UserMessageData?
    public let createdAt: String
}

public struct GetConversationHistoryResponse: Codable {
    public let messages: [ConversationMessage]
}

// MARK: - Domain Models

public struct Conversation: Identifiable {
    public let id: String
    public let createdAt: String

    public init(id: String, createdAt: String) {
        self.id = id
        self.createdAt = createdAt
    }

    public init(from response: ConversationResponse) {
        self.id = response.conversationId
        self.createdAt = response.createdAt
    }
}

public struct Message: Identifiable {
    public let id: String
    public let conversationId: String
    public let role: Role
    public let content: String
    public let createdAt: String
    public let thinkingContent: String?
    public let toolCalls: [ToolCall]?
    public let specialMessageType: String?
    public let specialMessageData: String?

    public init(
        id: String,
        conversationId: String,
        role: Role,
        content: String,
        createdAt: String,
        thinkingContent: String? = nil,
        toolCalls: [ToolCall]? = nil,
        specialMessageType: String? = nil,
        specialMessageData: String? = nil
    ) {
        self.id = id
        self.conversationId = conversationId
        self.role = role
        self.content = content
        self.createdAt = createdAt
        self.thinkingContent = thinkingContent
        self.toolCalls = toolCalls
        self.specialMessageType = specialMessageType
        self.specialMessageData = specialMessageData
    }

    public init(from response: ConversationMessage, conversationId: String) {
        self.id = response.data?.msgId ?? UUID().uuidString
        self.conversationId = conversationId
        self.role = response.role

        if response.role == .user {
            self.content = response.userData?.userInput ?? ""
            self.thinkingContent = nil
            self.toolCalls = nil
            self.specialMessageType = nil
            self.specialMessageData = nil
        } else {
            self.content = response.data?.content ?? ""
            self.thinkingContent = response.data?.thinkingContent
            self.toolCalls = response.data?.toolCalls
            self.specialMessageType = nil
            self.specialMessageData = nil
        }

        self.createdAt = response.createdAt
    }
}

// MARK: - Streaming Events

public enum ConversationStreamEvent {
    case streamMessage(StreamMessage)
    case error(String)
}
