import Foundation
import DomainChat  // 导入共享的StreamMessage、ToolCall等模型

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

// MARK: - Onboarding-specific Models

/// Bot 消息动作（UI显示用）
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

