import Foundation

/// Onboarding 流式事件
public enum OnboardingStreamEvent {
    case streamMessage(StreamMessage)  // SSE流消息
    case error(String)
}

/// Onboarding 服务协议
public protocol OnboardingService {
    /// 开始Onboarding（获取AI的第一条消息）
    /// - Parameter eventHandler: 流式事件处理回调
    func startOnboarding(
        eventHandler: @escaping (OnboardingStreamEvent) -> Void
    ) async throws
    
    /// 继续Onboarding（用户交互后继续）
    /// - Parameters:
    ///   - onboardingId: onboarding会话ID
    ///   - userInput: 用户文字输入（可选）
    ///   - healthData: 健康数据JSON字符串（可选）
    ///   - eventHandler: 流式事件处理回调
    func continueOnboarding(
        onboardingId: String,
        userInput: String?,
        healthData: String?,
        eventHandler: @escaping (OnboardingStreamEvent) -> Void
    ) async throws
    
    /// 恢复Onboarding（网络异常后重新恢复）
    /// - Parameters:
    ///   - onboardingId: onboarding会话ID
    ///   - lastDataId: 最后收到的data id
    ///   - eventHandler: 流式事件处理回调
    func resumeOnboarding(
        onboardingId: String,
        lastDataId: String?,
        eventHandler: @escaping (OnboardingStreamEvent) -> Void
    ) async throws
}

/// Onboarding 服务错误
public enum OnboardingServiceError: LocalizedError {
    case invalidResponse
    case serverError(String)
    case networkError(Error)
    case decodingError(Error)
    
    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let message):
            return "Server error: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        }
    }
}
