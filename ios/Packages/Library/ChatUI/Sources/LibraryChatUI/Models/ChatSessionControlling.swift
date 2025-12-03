import Foundation

/// 聊天会话控制接口，供外部触发消息发送或读取上下文
public protocol ChatSessionControlling: AnyObject {
    func sendMessage(_ text: String) async
    func sendSystemCommand(_ text: String, preferredConversationId: String?) async
    func currentMessages() -> [ChatMessage]
}
