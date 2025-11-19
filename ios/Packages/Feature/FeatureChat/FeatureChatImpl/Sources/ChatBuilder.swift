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

/// ChatView 的 Tab 包装器，带有独立的 NavigationStack
private struct ChatTabView: View {
    @EnvironmentObject var router: RouteManager

    var body: some View {
        NavigationStack(path: $router.chatPath) {
            PersistentChatView()
                .navigationDestination(for: RouteMatch.self) { match in
                    print("[ChatTab] navigationDestination: \(match.path)")
                    return router.buildView(for: match)
                }
        }
        .onAppear {
            // 更新当前 tab
            router.currentTab = .chat
        }
    }
}
