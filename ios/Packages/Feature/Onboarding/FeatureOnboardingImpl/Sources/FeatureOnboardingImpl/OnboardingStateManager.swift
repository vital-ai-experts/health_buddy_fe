import Foundation
import FeatureOnboardingApi
import LibraryBase

/// Onboarding 状态管理器实现
final class OnboardingStateManager: OnboardingStateManaging {
    static let mockOnboardingID = "\(OnboardingChatMocking.onboardingConversationPrefix)legacy"
    static let shared = OnboardingStateManager()

    private let userDefaults = UserDefaults.standard
    private let hasCompletedOnboardingKey = "com.hehigh.thrivebody.hasCompletedOnboarding"
    private let onboardingIDKey = "com.hehigh.thrivebody.onboardingID"
    private let initialQueryKey = "com.hehigh.thrivebody.onboardingInitialQuery"
    private let healthAuthorizedKey = "com.hehigh.thrivebody.onboardingHealthAuthorized"
    private let selectedGenderKey = "com.hehigh.thrivebody.onboardingSelectedGender"
    private let callCompletedKey = "com.hehigh.thrivebody.onboardingCallCompleted"

    private init() {}

    var hasCompletedOnboarding: Bool {
        get { userDefaults.bool(forKey: hasCompletedOnboardingKey) }
        set {
            userDefaults.set(newValue, forKey: hasCompletedOnboardingKey)
            Log.i("✅ Onboarding 状态已更新: \(newValue ? "已完成" : "未完成")", category: "Onboarding")
        }
    }

    func markOnboardingAsCompleted() {
        hasCompletedOnboarding = true
    }

    func resetOnboardingState() {
        hasCompletedOnboarding = false
        clearOnboardingID()
        clearInitialQuery()
        clearHealthAuthorized()
        clearSelectedGender()
        clearCallCompleted()
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

    /// 获取现有 Onboarding ID，如不存在则生成一个带前缀的 ID
    func ensureOnboardingID() -> String {
        if let existing = getOnboardingID() {
            return existing
        }
        let newId = OnboardingChatMocking.makeConversationId()
        saveOnboardingID(newId)
        return newId
    }

    func saveInitialQuery(_ query: String) {
        userDefaults.set(query, forKey: initialQueryKey)
        Log.i("✅ Onboarding 首次提问已保存: \(query)", category: "Onboarding")
    }

    func getInitialQuery() -> String? {
        let query = userDefaults.string(forKey: initialQueryKey)
        if let query {
            Log.i("ℹ️ 获取 Onboarding 首次提问: \(query)", category: "Onboarding")
        } else {
            Log.w("⚠️ 尚未保存 Onboarding 首次提问", category: "Onboarding")
        }
        return query
    }

    func clearInitialQuery() {
        userDefaults.removeObject(forKey: initialQueryKey)
        Log.i("✅ Onboarding 首次提问已清除", category: "Onboarding")
    }

    // MARK: - Health data & profile persistence

    var hasAuthorizedHealth: Bool {
        get { userDefaults.bool(forKey: healthAuthorizedKey) }
        set { userDefaults.set(newValue, forKey: healthAuthorizedKey) }
    }

    func clearHealthAuthorized() {
        userDefaults.removeObject(forKey: healthAuthorizedKey)
    }

    var selectedGender: String? {
        get { userDefaults.string(forKey: selectedGenderKey) }
        set { userDefaults.set(newValue, forKey: selectedGenderKey) }
    }

    func clearSelectedGender() {
        userDefaults.removeObject(forKey: selectedGenderKey)
    }

    var hasCompletedCall: Bool {
        get { userDefaults.bool(forKey: callCompletedKey) }
        set { userDefaults.set(newValue, forKey: callCompletedKey) }
    }

    func clearCallCompleted() {
        userDefaults.removeObject(forKey: callCompletedKey)
    }
}
