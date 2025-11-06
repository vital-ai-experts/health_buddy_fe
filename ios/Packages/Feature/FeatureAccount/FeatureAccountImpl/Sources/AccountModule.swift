import Foundation
import LibraryServiceLoader
import FeatureAccountApi

/// Account feature module registration
public enum AccountModule {
    /// Register the Account feature
    public static func register(in manager: ServiceManager = .shared) {
        // Register builder to ServiceManager
        manager.register(FeatureAccountBuildable.self) { AccountBuilder() }
    }
}
