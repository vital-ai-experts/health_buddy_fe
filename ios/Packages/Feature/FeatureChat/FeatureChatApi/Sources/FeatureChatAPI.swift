import SwiftUI
import LibraryChatUI

/// Builder protocol for Chat feature
public protocol FeatureChatBuildable {
    /// Build the chat conversation list view
    func makeConversationListView() -> AnyView

    /// Build the chat view for a specific conversation
    func makeChatView(conversationId: String?) -> AnyView

    /// Build the chat tab view for MainTabView
    func makeChatTabView() -> AnyView

    /// Build a configurable chat view (用于 Onboarding 或定制场景)
    func makeChatView(config: ChatConversationConfig) -> AnyView
}

/// 可对接外部定制的聊天会话配置
public struct ChatConversationConfig {
    public var initialConversationId: String?
    public var navigationTitle: String
    public var showsCloseButton: Bool
    public var chatContext: ChatContext
    public var onReady: ((ChatSessionControlling) -> Void)?
    public var chatService: ChatService?

    public init(
        initialConversationId: String? = nil,
        navigationTitle: String = "对话",
        showsCloseButton: Bool = true,
        chatContext: ChatContext = .noop,
        onReady: ((ChatSessionControlling) -> Void)? = nil,
        chatService: ChatService? = nil
    ) {
        self.initialConversationId = initialConversationId
        self.navigationTitle = navigationTitle
        self.showsCloseButton = showsCloseButton
        self.chatContext = chatContext
        self.onReady = onReady
        self.chatService = chatService
    }
}

/// 聊天会话控制接口，供外部触发消息发送
@MainActor
public protocol ChatSessionControlling {
    func sendMessage(_ text: String) async
    func sendSystemCommand(_ text: String, preferredConversationId: String?) async
}
