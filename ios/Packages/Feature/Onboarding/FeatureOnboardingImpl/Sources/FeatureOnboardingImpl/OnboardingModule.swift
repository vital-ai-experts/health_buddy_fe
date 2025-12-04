import Foundation
import LibraryServiceLoader
import FeatureOnboardingApi
import FeatureChatApi
import LibraryChatUI

/// Onboarding feature module registration
public enum OnboardingModule {
    /// Register the Onboarding feature
    public static func register(
        in manager: ServiceManager = .shared,
        router: RouteManager? = nil
    ) {
        // Register builder to ServiceManager
        manager.register(FeatureOnboardingBuildable.self) { OnboardingBuilder() }
        // Expose state manager for other modules (e.g., DebugTools) to reset onboarding status
        manager.register(OnboardingStateManaging.self) { OnboardingStateManager.shared }

        // 注册对话卡片渲染
        OnboardingChatMessageRegistrar.registerRenderers()
    }
}
