import Foundation

/// 聊天上下文，供自定义卡片在当前会话内发送用户消息
public struct ChatContext {
    /// 发送一条用户消息到当前会话
    public let sendUserMessage: (String) -> Void

    public init(sendUserMessage: @escaping (String) -> Void) {
        self.sendUserMessage = sendUserMessage
    }

    /// 空操作上下文，适用于未提供上下文的兜底场景
    public static let noop = ChatContext { _ in }
}
