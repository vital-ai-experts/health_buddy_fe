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
        let routeManager = router ?? RouteManager.shared
        OnboardingChatMessageRegistrar.updateHandlers(
            onViewDungeon: {
                Task { @MainActor in
                    if let url = routeManager.buildURL(path: "/dungeon_detail", queryItems: ["present": "sheet"]) {
                        routeManager.open(url: url)
                    }
                }
            },
            onStartDungeon: {
                Task { @MainActor in
                    // 标记 onboarding 完成
                    let state = OnboardingStateManager.shared
                    state.saveOnboardingID(OnboardingStateManager.mockOnboardingID)
                    state.markOnboardingAsCompleted()
                    routeManager.currentTab = .agenda
                }
            }
        )
    }
}
