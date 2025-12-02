import Foundation

// MARK: - Shared SSE Stream Models (used by both Chat and Onboarding)

/// 消息类型：CHUNK（分片）或 WHOLE（完整）
public enum MessageType: Int, Codable {
    case chunk = 1   // 分片数据
    case whole = 2   // 完整数据
}

/// 数据类型
public enum DataType: Int, Codable {
    case agentStatus = 1     // Agent状态
    case agentMessage = 2    // Agent消息
    case agentToolCall = 3   // Agent工具调用
}

/// Agent状态
public enum AgentStatus: Int, Codable {
    case generating = 1  // 生成中
    case finished = 2    // 已完成
    case error = 3       // 错误
    case stopped = 4     // 已停止
}

/// 工具调用状态
public enum ToolCallStatus: Int, Codable {
    case started = 1   // 开始
    case success = 2   // 成功
    case failed = 3    // 失败

    public var description: String {
        switch self {
        case .started:
            return "开始"
        case .success:
            return "成功"
        case .failed:
            return "失败"
        }
    }
}

/// 工具调用
public struct ToolCall: Codable {
    public let toolCallId: String
    public let toolCallName: String
    public let toolCallArgs: String?  // JSON字符串
    public let toolCallStatus: ToolCallStatus?
    public let toolCallResult: String?  // JSON字符串

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

/// 流消息数据
public struct StreamMessageData: Codable {
    public let conversationId: String?  // 对话ID
    public let onboardingId: String?    // Onboarding ID
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

/// 流消息（SSE事件的data字段反序列化后的结构）
public struct StreamMessage: Codable {
    public let id: String  // SSE event的id
    public let data: StreamMessageData

    public init(id: String, data: StreamMessageData) {
        self.id = id
        self.data = data
    }
}

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

/// 消息领域模型（用于历史消息）
public struct Message: Identifiable {
    public let id: String
    public let conversationId: String
    public let role: Role
    public let content: String
    public let createdAt: String
    public let thinkingContent: String?
    public let toolCalls: [ToolCall]?
    public let specialMessageType: String?  // 特殊消息类型（如 "digest_report"）
    public let specialMessageData: String?  // 特殊消息数据（JSON字符串）

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

        // 用户消息使用userData，Agent消息使用data
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
            self.specialMessageType = nil  // TODO: 从服务器响应中获取
            self.specialMessageData = nil  // TODO: 从服务器响应中获取
        }

        self.createdAt = response.createdAt
    }
}

// MARK: - Streaming Events

/// 对话流事件
public enum ConversationStreamEvent {
    case streamMessage(StreamMessage)
    case error(String)
}
