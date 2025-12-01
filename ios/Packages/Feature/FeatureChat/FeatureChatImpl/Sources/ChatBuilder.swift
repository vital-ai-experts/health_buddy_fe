import SwiftUI
import FeatureChatApi
import LibraryServiceLoader

/// Builder for Chat feature views
public final class ChatBuilder: FeatureChatBuildable {
    public init() {}

    public func makeConversationListView() -> AnyView {
        // 不再使用对话列表，直接返回单一对话视图
        AnyView(PersistentChatView())
    }

    public func makeChatView(conversationId: String?) -> AnyView {
        // 忽略conversationId参数，始终返回单一长期对话
        AnyView(PersistentChatView())
    }

    public func makeChatTabView() -> AnyView {
        AnyView(ChatTabView())
    }
}

/// ChatView 包装器，用于fullscreen展示
private struct ChatTabView: View {
    @EnvironmentObject var router: RouteManager

    var body: some View {
        NavigationStack {
            PersistentChatView()
        }
    }
}
