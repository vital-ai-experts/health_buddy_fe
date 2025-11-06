import SwiftUI
import LibraryServiceLoader
import FeatureChatApi

/// Chat feature module registration
public enum ChatModule {
    /// Register the Chat feature
    public static func register(in manager: ServiceManager = .shared) {
        // Register builder to ServiceManager
        manager.register(FeatureChatBuildable.self) { ChatBuilder() }
    }
}
