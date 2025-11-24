import Foundation
import FeatureOnboardingApi
import LibraryBase

/// Onboarding 状态管理器实现
final class OnboardingStateManager: OnboardingStateManaging {
    static let mockOnboardingID = "mock-onboarding-id"
    static let shared = OnboardingStateManager()

    private let userDefaults = UserDefaults.standard
    private let hasCompletedOnboardingKey = "com.hehigh.thrivebody.hasCompletedOnboarding"
    private let onboardingIDKey = "com.hehigh.thrivebody.onboardingID"

    private init() {}

    var hasCompletedOnboarding: Bool {
        get { userDefaults.bool(forKey: hasCompletedOnboardingKey) }
        set {
            userDefaults.set(newValue, forKey: hasCompletedOnboardingKey)
            Log.i("✅ Onboarding 状态已更新: \(newValue ? "已完成" : "未完成")", category: "Onboarding")
        }
    }

    func markOnboardingAsCompleted() {
        // hasCompletedOnboarding = true
    }

    func resetOnboardingState() {
        hasCompletedOnboarding = false
        clearOnboardingID()
        Log.w("⚠️ Onboarding 状态已重置", category: "Onboarding")
    }

    func shouldShowOnboarding(isAuthenticated: Bool) -> Bool {
        if isAuthenticated {
            Log.i("ℹ️ 用户已登录，跳过 Onboarding", category: "Onboarding")
            return false
        }

        if hasCompletedOnboarding {
            Log.i("ℹ️ 用户已完成过 Onboarding，直接进入登录/主流程", category: "Onboarding")
            return false
        }

        Log.i("ℹ️ 新用户，需要展示 Onboarding", category: "Onboarding")
        return true
    }

    func saveOnboardingID(_ id: String) {
        userDefaults.set(id, forKey: onboardingIDKey)
        Log.i("✅ Onboarding ID 已保存: \(id)", category: "Onboarding")
    }

    func getOnboardingID() -> String? {
        let id = userDefaults.string(forKey: onboardingIDKey)
        if let id {
            Log.i("ℹ️ 获取 Onboarding ID: \(id)", category: "Onboarding")
        } else {
            Log.w("⚠️ 没有找到 Onboarding ID", category: "Onboarding")
        }
        return id
    }

    func clearOnboardingID() {
        userDefaults.removeObject(forKey: onboardingIDKey)
        Log.i("✅ Onboarding ID 已清除", category: "Onboarding")
    }
}
