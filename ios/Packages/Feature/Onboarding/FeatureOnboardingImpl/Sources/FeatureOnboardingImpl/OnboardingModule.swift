import Foundation
import LibraryServiceLoader
import FeatureOnboardingApi

/// Onboarding feature module registration
public enum OnboardingModule {
    /// Register the Onboarding feature
    public static func register(in manager: ServiceManager = .shared) {
        // Register builder to ServiceManager
        manager.register(FeatureOnboardingBuildable.self) { OnboardingBuilder() }
        // Expose state manager for other modules (e.g., DebugTools) to reset onboarding status
        manager.register(OnboardingStateManaging.self) { OnboardingStateManager.shared }
    }
}
