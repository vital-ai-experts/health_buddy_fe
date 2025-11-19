import Foundation
import FeatureAccountApi
import LibraryServiceLoader

/// Account feature module registration
public enum AccountModule {
    /// Register the Account feature
    public static func register(
        in manager: ServiceManager = .shared,
        router: RouteRegistering
    ) {
        // Register builder to ServiceManager
        manager.register(FeatureAccountBuildable.self) { AccountBuilder() }

        registerRoutes(on: router)
    }
}
