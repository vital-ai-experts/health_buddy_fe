import SwiftUI

/// Builder protocol for Chat feature
public protocol FeatureChatBuildable {
    /// Build the chat conversation list view
    func makeConversationListView() -> AnyView

    /// Build the chat view for a specific conversation
    func makeChatView(conversationId: String?) -> AnyView

    /// Build the chat tab view for MainTabView
    func makeChatTabView() -> AnyView
}
