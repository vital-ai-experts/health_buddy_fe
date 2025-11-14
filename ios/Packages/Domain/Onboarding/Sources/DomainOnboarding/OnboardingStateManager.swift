import Foundation

/// Onboarding状态管理器
/// 使用UserDefaults记录用户是否已完成Onboarding流程
public final class OnboardingStateManager {
    public static let shared = OnboardingStateManager()

    private let userDefaults = UserDefaults.standard
    private let hasCompletedOnboardingKey = "com.hehigh.thrivebody.hasCompletedOnboarding"
    private let onboardingIDKey = "com.hehigh.thrivebody.onboardingID"

    private init() {}

    /// 检查用户是否已完成Onboarding
    public var hasCompletedOnboarding: Bool {
        get {
            userDefaults.bool(forKey: hasCompletedOnboardingKey)
        }
        set {
            userDefaults.set(newValue, forKey: hasCompletedOnboardingKey)
            print("✅ Onboarding状态已更新: \(newValue ? "已完成" : "未完成")")
        }
    }

    /// 标记Onboarding为已完成
    public func markOnboardingAsCompleted() {
        // TODO: 暂时未登录就每次都出
        // hasCompletedOnboarding = true
    }

    /// 重置Onboarding状态（用于测试或重新引导）
    public func resetOnboardingState() {
        hasCompletedOnboarding = false
        print("⚠️ Onboarding状态已重置")
    }

    /// 检查是否需要显示Onboarding
    /// - Parameter isAuthenticated: 用户是否已登录
    /// - Returns: 是否需要显示Onboarding
    public func shouldShowOnboarding(isAuthenticated: Bool) -> Bool {
        // 如果用户已登录，不显示Onboarding
        if isAuthenticated {
            print("ℹ️ 用户已登录，跳过Onboarding")
            return false
        }

        // 如果用户未登录但已完成过Onboarding，也不显示
        if hasCompletedOnboarding {
            print("ℹ️ 用户已完成过Onboarding，跳过")
            return false
        }

        // 未登录且未完成Onboarding，需要显示
        print("ℹ️ 新用户，需要显示Onboarding")
        return true
    }

    // MARK: - Onboarding ID Management

    /// 保存 Onboarding ID
    public func saveOnboardingID(_ id: String) {
        userDefaults.set(id, forKey: onboardingIDKey)
        print("✅ Onboarding ID 已保存: \(id)")
    }

    /// 获取 Onboarding ID
    public func getOnboardingID() -> String? {
        let id = userDefaults.string(forKey: onboardingIDKey)
        if let id = id {
            print("ℹ️ 获取 Onboarding ID: \(id)")
        } else {
            print("⚠️ 没有找到 Onboarding ID")
        }
        return id
    }

    /// 清除 Onboarding ID
    public func clearOnboardingID() {
        userDefaults.removeObject(forKey: onboardingIDKey)
        print("✅ Onboarding ID 已清除")
    }
}
