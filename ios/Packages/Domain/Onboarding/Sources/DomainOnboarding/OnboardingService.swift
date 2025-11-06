import Foundation

/// Onboarding 服务协议
public protocol OnboardingService {
    /// 发送消息到 Onboarding 接口
    /// - Parameters:
    ///   - sessionId: 会话ID，第一次为nil
    ///   - userMessage: 用户消息
    /// - Returns: Onboarding 响应
    func sendMessage(sessionId: String?, userMessage: UserMessage) async throws -> OnboardingResponseData
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

