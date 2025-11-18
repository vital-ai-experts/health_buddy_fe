import SwiftUI
import LibraryServiceLoader
import FeatureDebugToolsApi


public enum DebugToolsFeatureModule {
    public static func register(in manager: ServiceManager = .shared) {
        // Register builder to ServiceManager
        manager.register(FeatureDebugToolsBuildable.self) { DebugToolsBuilder() }
    }

    /// Register debug tools-related routes (DEBUG only)
    /// - Parameter router: The router to register routes on
    public static func registerRoutes(on router: RouteRegistering) {
        // Debug tools route: thrivebody://debug/tools
        router.register(
            path: "/debug/tools",
            defaultPresentation: .push
        ) { _ in
            AnyView(DebugToolsView())
        }

        // Chat debug route: thrivebody://debug/chat
        router.register(
            path: "/debug/chat",
            defaultPresentation: .push
        ) { _ in
            AnyView(ChatDebugView())
        }
    }
}
