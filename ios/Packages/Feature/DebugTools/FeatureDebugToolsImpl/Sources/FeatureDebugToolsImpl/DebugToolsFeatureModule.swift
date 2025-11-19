import SwiftUI
import FeatureDebugToolsApi
import LibraryServiceLoader


public enum DebugToolsFeatureModule {
    public static func register(
        in manager: ServiceManager = .shared,
        router: RouteRegistering
    ) {
        // Register builder to ServiceManager
        manager.register(FeatureDebugToolsBuildable.self) { DebugToolsBuilder() }

        registerRoutes(on: router)
    }
}
