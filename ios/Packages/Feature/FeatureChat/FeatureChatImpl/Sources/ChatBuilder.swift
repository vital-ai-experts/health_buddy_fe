import SwiftUI
import FeatureChatApi

/// Builder for Chat feature views
public final class ChatBuilder: FeatureChatBuildable {
    public init() {}

    public func makeConversationListView() -> AnyView {
        AnyView(ConversationListView())
    }

    public func makeChatView(conversationId: String?) -> AnyView {
        AnyView(ChatView(conversationId: conversationId))
    }

    public func makeChatDemoView() -> AnyView {
        AnyView(ConversationListView())
    }
}
