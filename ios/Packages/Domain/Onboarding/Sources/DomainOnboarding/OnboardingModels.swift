import Foundation

// MARK: - Request Models

/// 开始Onboarding请求（无参数）
public struct StartOnboardingRequest: Codable {
    public init() {}
}

/// 继续Onboarding请求
public struct ContinueOnboardingRequest: Codable {
    public let onboardingId: String
    public let userInput: String?
    public let healthData: String?  // JSON字符串
    public let extraParams: [String: String]?
    
    public init(
        onboardingId: String,
        userInput: String? = nil,
        healthData: String? = nil,
        extraParams: [String: String]? = nil
    ) {
        self.onboardingId = onboardingId
        self.userInput = userInput
        self.healthData = healthData
        self.extraParams = extraParams
    }
}

/// 恢复Onboarding请求
public struct ResumeOnboardingRequest: Codable {
    public let onboardingId: String
    public let lastDataId: String?
    
    public init(onboardingId: String, lastDataId: String? = nil) {
        self.onboardingId = onboardingId
        self.lastDataId = lastDataId
    }
}

// MARK: - SSE Stream Models

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
    public let msgId: String
    public let dataType: DataType
    public let msgIdx: Int?
    public let agentStatus: AgentStatus?
    public let messageType: MessageType?
    public let onboardingId: String?
    public let thinkingContent: String?
    public let content: String?
    public let toolCalls: [ToolCall]?
    
    public init(
        msgId: String,
        dataType: DataType,
        msgIdx: Int? = nil,
        agentStatus: AgentStatus? = nil,
        messageType: MessageType? = nil,
        onboardingId: String? = nil,
        thinkingContent: String? = nil,
        content: String? = nil,
        toolCalls: [ToolCall]? = nil
    ) {
        self.msgId = msgId
        self.dataType = dataType
        self.msgIdx = msgIdx
        self.agentStatus = agentStatus
        self.messageType = messageType
        self.onboardingId = onboardingId
        self.thinkingContent = thinkingContent
        self.content = content
        self.toolCalls = toolCalls
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

// MARK: - Response Models (for non-SSE responses if needed)

/// Base响应
public struct BaseResp: Codable {
    public let code: Int
    public let message: String
    
    public init(code: Int, message: String) {
        self.code = code
        self.message = message
    }
}

/// Bot 消息动作（保留用于UI显示）
public enum BotMessageAction: String, Codable {
    case notiPermit = "noti_permit"           // 通知权限
    case healthPermit = "health_permit"       // 健康数据权限
    case finishOnboarding = "finish_onboarding" // 完成引导
}

/// Bot 消息操作信息
public struct BotMessageActionInfo: Codable {
    public let type: BotMessageAction
    public let title: String

    public init(type: BotMessageAction, title: String) {
        self.type = type
        self.title = title
    }
}

