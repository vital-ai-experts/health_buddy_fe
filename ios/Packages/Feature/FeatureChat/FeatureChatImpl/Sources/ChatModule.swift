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
        // Register builder to ServiceManager
        manager.register(FeatureChatBuildable.self) { ChatBuilder() }

        // Register routes
        registerRoutes(on: router)
    }

    private static func registerRoutes(on router: RouteRegistering) {
        // /chat - 打开对话页面
        router.register(path: "/chat", defaultSurface: .sheet) { context in
            let defaultGoalId = context.queryItems["goalId"]
            return AnyView(
                PersistentChatView(defaultSelectedGoalId: defaultGoalId)
            )
        }
    }
}
