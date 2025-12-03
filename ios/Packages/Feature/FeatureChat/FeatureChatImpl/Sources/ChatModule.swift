import SwiftUI
import LibraryServiceLoader
import FeatureChatApi

/// Chat feature module registration
public enum ChatModule {
    /// Register the Chat feature
    public static func register(
        in manager: ServiceManager = .shared,
        router: RouteRegistering
    ) {
        // Register chat service & mock-wrapped service to容器
        manager.register(ChatService.self) {
            ChatServiceImpl()
        }

        // Register builder to ServiceManager
        manager.register(FeatureChatBuildable.self) { ChatBuilder() }

        // Register routes
        registerRoutes(on: router)
    }

    private static func registerRoutes(on router: RouteRegistering) {
        // /chat - 打开对话页面
        router.register(path: "/chat", defaultSurface: .fullscreen) { context in
            let defaultGoalId = context.queryItems["goalId"]
            let showsCloseButton = context.queryItems["closable"]?.lowercased() != "false"
            let navigationTitle = context.queryItems["title"] ?? "对话"
            let conversationId = context.queryItems["conversationId"]
            return AnyView(
                PersistentChatView(
                    defaultSelectedGoalId: defaultGoalId,
                    initialConversationId: conversationId,
                    showsCloseButton: showsCloseButton,
                    navigationTitle: navigationTitle
                )
            )
        }
    }
}
