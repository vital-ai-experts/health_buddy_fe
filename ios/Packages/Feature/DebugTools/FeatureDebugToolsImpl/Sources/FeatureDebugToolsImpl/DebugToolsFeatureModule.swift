import SwiftUI
import LibraryServiceLoader
import FeatureDebugToolsApi


public enum DebugToolsFeatureModule {
    public static func register(in manager: ServiceManager = .shared) {
        // Register builder to ServiceManager
        manager.register(FeatureDebugToolsBuildable.self) { DebugToolsBuilder() }
    }
}
