import SwiftUI
import LibraryServiceLoader
import FeatureAgendaApi
import FeatureChatApi
import LibraryChatUI

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
        let builder = ChatBuilder()
        manager.register(FeatureChatBuildable.self) { builder }

        // Register routes
        registerRoutes(on: router, builder: builder)
    }

    private static func registerRoutes(on router: RouteRegistering, builder: FeatureChatBuildable) {
        // /chat - 打开对话页面
        router.register(path: "/chat", defaultSurface: .fullscreen) { context in
            let defaultGoalId = context.queryItems["goalId"]
            let showsCloseButton = context.queryItems["closable"]?.lowercased() != "false"
            let navigationTitle = context.queryItems["title"] ?? "对话"
            let conversationId = context.queryItems["conversationId"]
            let topics = ServiceManager.shared
                .resolveOptional(AgendaGoalManaging.self)?
                .goals
                .map { ChatTopic(id: $0.id, title: $0.title) } ?? []

            let config = ChatConversationConfig(
                initialConversationId: conversationId,
                defaultSelectedGoalId: defaultGoalId,
                navigationTitle: navigationTitle,
                showsCloseButton: showsCloseButton,
                topics: topics,
            )

            return builder.makeChatView(config: config)
        }
    }
}
