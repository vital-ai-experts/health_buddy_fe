import Foundation

/// Onboarding 状态管理接口，暴露给其他功能模块（如 DebugTools）使用
public protocol OnboardingStateManaging {
    var hasCompletedOnboarding: Bool { get set }

    func markOnboardingAsCompleted()
    func resetOnboardingState()
    func shouldShowOnboarding(isAuthenticated: Bool) -> Bool
    func saveOnboardingID(_ id: String)
    func getOnboardingID() -> String?
    func clearOnboardingID()
}
