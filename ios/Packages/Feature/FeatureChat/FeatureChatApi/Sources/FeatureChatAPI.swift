import SwiftUI
import LibraryChatUI

/// Builder protocol for Chat feature
public protocol FeatureChatBuildable {
    /// Build a configurable chat view (用于 Onboarding 或定制场景)
    func makeChatView(config: ChatConversationConfig) -> AnyView
}

/// 可对接外部定制的聊天会话配置
public struct ChatConversationConfig {
    public var initialConversationId: String?
    public var defaultSelectedGoalId: String?
    public var navigationTitle: String
    public var showsCloseButton: Bool
    /// topics 为 nil 时使用默认 topics；为空数组时不展示
    public var topics: [ChatTopic]?
    public var onReady: ((ChatSessionControlling) -> Void)?
    public var chatService: ChatService?

    public init(
        initialConversationId: String? = nil,
        defaultSelectedGoalId: String? = nil,
        navigationTitle: String = "对话",
        showsCloseButton: Bool = true,
        topics: [ChatTopic]? = nil,
        onReady: ((ChatSessionControlling) -> Void)? = nil,
        chatService: ChatService? = nil
    ) {
        self.initialConversationId = initialConversationId
        self.defaultSelectedGoalId = defaultSelectedGoalId
        self.navigationTitle = navigationTitle
        self.showsCloseButton = showsCloseButton
        self.topics = topics
        self.onReady = onReady
        self.chatService = chatService
    }
}
