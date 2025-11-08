import Foundation

/// Onboarding 流式事件
public enum OnboardingStreamEvent {
    case sessionStart(sessionId: String)
    case messageStart(messageId: String)
    case contentDelta(content: String)
    case messageEnd(action: BotMessageActionInfo?)  // messageEnd 时可选地携带 action 信息
    case error(String)
}

/// Onboarding 服务协议
public protocol OnboardingService {
    /// 发送消息到 Onboarding 接口（SSE 流式）
    /// - Parameters:
    ///   - sessionId: 会话ID，第一次为nil
    ///   - userMessage: 用户消息
    ///   - eventHandler: 流式事件处理回调
    func sendMessage(
        sessionId: String?,
        userMessage: UserMessage,
        eventHandler: @escaping (OnboardingStreamEvent) -> Void
    ) async throws
}

/// Onboarding 服务错误
public enum OnboardingServiceError: LocalizedError {
    case invalidResponse
    case serverError(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let message):
            return "Server error: \(message)"
        }
    }
}
