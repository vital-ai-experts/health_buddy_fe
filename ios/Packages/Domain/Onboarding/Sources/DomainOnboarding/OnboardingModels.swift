import Foundation

// MARK: - Request Models

/// 用户消息类型
public enum UserMessageType: Int, Codable {
    case initialize = 0  // 初始化
    case textReply = 1   // 文字回复
}

/// 用户消息
public struct UserMessage: Codable {
    public let type: UserMessageType
    public let text: String?
    
    public init(type: UserMessageType, text: String? = nil) {
        self.type = type
        self.text = text
    }
}

/// Onboarding 请求
public struct OnboardingRequest: Codable {
    public let onboardSessionId: String?
    public let userMessage: UserMessage
    
    public init(onboardSessionId: String?, userMessage: UserMessage) {
        self.onboardSessionId = onboardSessionId
        self.userMessage = userMessage
    }
}

// MARK: - Response Models

/// Bot 消息类型
public enum BotMessageType: Int, Codable {
    case text = 1           // 文字消息
    case actionButton = 2   // 操作按钮
}

/// Bot 消息动作
public enum BotMessageAction: String, Codable {
    case notiPermit = "noti_permit"           // 通知权限
    case healthPermit = "health_permit"       // 健康数据权限
    case finishOnboarding = "finish_onboarding" // 完成引导
}

/// Bot 消息
public struct BotMessage: Codable, Identifiable {
    public let id: String
    public let type: BotMessageType
    public let text: String?
    public let action: BotMessageAction?
    
    public init(id: String = UUID().uuidString, type: BotMessageType, text: String?, action: BotMessageAction? = nil) {
        self.id = id
        self.type = type
        self.text = text
        self.action = action
    }
}

/// Onboarding 响应数据
public struct OnboardingResponseData: Codable {
    public let sessionId: String
    public let botMessages: [BotMessage]
    
    public init(sessionId: String, botMessages: [BotMessage]) {
        self.sessionId = sessionId
        self.botMessages = botMessages
    }
}

/// Onboarding 响应
public struct OnboardingResponse: Codable {
    public let code: Int
    public let message: String
    public let data: OnboardingResponseData?
    
    public init(code: Int, message: String, data: OnboardingResponseData?) {
        self.code = code
        self.message = message
        self.data = data
    }
}

