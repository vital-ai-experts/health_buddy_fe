//
//  RootView.swift
//  ThriveBody
//
//  Created by Codex on 2025/2/14.
//

import SwiftUI
import SwiftData
import FeatureHealthKitApi
import FeatureAccountApi
import FeatureChatApi
import FeatureOnboardingApi
import FeatureAgendaApi
import DomainAuth
import DomainOnboarding
import LibraryServiceLoader
import LibraryNetworking
import LibraryNotification
import LibraryBase
import LibraryTrack

struct RootView: View {
    @State private var showingSplash: Bool = true
    @State private var appState: AppState = .initializing
    @State private var showLoginSheet: Bool = false
    @State private var showLoginFullScreen: Bool = false
    @State private var networkMonitor: NetworkMonitor?  // 延迟初始化，避免过早触发网络权限弹窗
    @ObservedObject private var notificationManager = NotificationManager.shared

    private let healthKitFeature: FeatureHealthKitBuildable
    private let accountFeature: FeatureAccountBuildable
    private let chatFeature: FeatureChatBuildable
    private let onboardingFeature: FeatureOnboardingBuildable
    private let authService: AuthenticationService
    
    // MARK: - App State
    enum AppState {
        case initializing      // 初始化中（Splash阶段）
        case onboarding       // 首次使用引导
        case authenticated    // 已登录
    }

    init(
        healthKitFeature: FeatureHealthKitBuildable = ServiceManager.shared.resolve(FeatureHealthKitBuildable.self),
        accountFeature: FeatureAccountBuildable = ServiceManager.shared.resolve(FeatureAccountBuildable.self),
        chatFeature: FeatureChatBuildable = ServiceManager.shared.resolve(FeatureChatBuildable.self),
        onboardingFeature: FeatureOnboardingBuildable = ServiceManager.shared.resolve(FeatureOnboardingBuildable.self),
        authService: AuthenticationService = ServiceManager.shared.resolve(AuthenticationService.self)
    ) {
        self.healthKitFeature = healthKitFeature
        self.accountFeature = accountFeature
        self.chatFeature = chatFeature
        self.onboardingFeature = onboardingFeature
        self.authService = authService
    }

    var body: some View {
        ZStack {
            // Main content - 根据 appState 显示对应内容
            Group {
                switch appState {
                case .initializing:
                    // 初始化阶段不显示任何内容，等待 Splash
                    Color.clear
                    
                case .onboarding:
                    // Onboarding 引导流程
                    onboardingFeature.makeOnboardingView {
                        // Onboarding 完成后，标记为已完成并弹出全屏登录页
                        OnboardingStateManager.shared.markOnboardingAsCompleted()
                        showLoginFullScreen = true
                    }
                    
                case .authenticated:
                    // 主界面 - TabView包含AI助手、健康数据和我的三个Tab
                    MainTabView(
                        healthKitFeature: healthKitFeature,
                        chatFeature: chatFeature,
                        accountFeature: accountFeature,
                        onLogout: handleLogout
                    )
                }
            }
            .sheet(isPresented: $showLoginSheet) {
                // 登录页面以 Sheet 形式按需弹出（可关闭）
                accountFeature.makeAccountLandingView(onSuccess: {
                    // 登录成功
                    showLoginSheet = false
                    appState = .authenticated
                }, isDismissable: true)
            }
            .fullScreenCover(isPresented: $showLoginFullScreen) {
                // Onboarding 后的全屏登录页面（不可关闭）
                accountFeature.makeAccountLandingView(onSuccess: {
                    // 登录成功
                    showLoginFullScreen = false
                    appState = .authenticated
                }, isDismissable: false)
            }

            // Splash 启动画面 - 完全覆盖在最上层
            if showingSplash {
                Color.black
                    .ignoresSafeArea()
                    .overlay {
                        SplashView()
                    }
                    .zIndex(999)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.5), value: showingSplash)
                    .task {
                        await initializeApp()
                    }
            }
        }
    }

    // MARK: - Private Methods

    /// 初始化应用，显示启动画面
    private func initializeApp() async {
        let minimumSplashDuration: UInt64 = 1_500_000_000 // 1.5秒
        let startTime = DispatchTime.now()

        // 检查认证状态
        let isAuthenticated = await checkAuthentication()

        // 检查是否需要显示Onboarding
        let onboardingStateManager = OnboardingStateManager.shared
        let shouldShowOnboarding = onboardingStateManager.shouldShowOnboarding(isAuthenticated: isAuthenticated)

        // 等待最少 Splash 时间（动画播放）
        let elapsedTime = DispatchTime.now().uptimeNanoseconds - startTime.uptimeNanoseconds
        if elapsedTime < minimumSplashDuration {
            try? await Task.sleep(nanoseconds: minimumSplashDuration - elapsedTime)
        }

        // ⭐️ 如果需要Onboarding，在Splash动画结束后延迟1秒，然后检测网络
        if shouldShowOnboarding {
            Log.i("ℹ️ Splash动画已结束，延迟1秒后开始检测网络...", category: "App")
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1秒

            Log.i("ℹ️ 开始检测网络连接（仍在Splash状态）...", category: "App")
            // 等待网络连接（无超时限制）- 此时仍在Splash页面
            await waitForNetworkAvailable()
            Log.i("✅ 网络已连接，准备跳转到Onboarding", category: "App")

            // 发送健康检查请求，触发网络授权弹窗（仍在Splash状态）
            await triggerNetworkPermissionWithRetry()

            // 注册设备（异步，不阻塞流程）
            Task {
                await registerDevice()
            }
        }

        // 确定应用初始状态
        let initialState: AppState
        if isAuthenticated {
            // 已登录，直接进入主界面
            initialState = .authenticated
        } else if shouldShowOnboarding {
            // 未登录且需要Onboarding
            initialState = .onboarding
        } else {
            // 未登录但已完成过Onboarding，直接显示登录页
            initialState = .authenticated // 先进入authenticated状态，然后立即弹出登录页
        }

        // 关闭 Splash，同时设置应用状态
        await MainActor.run {
            appState = initialState
            showingSplash = false

            // 如果未登录但已完成Onboarding，立即弹出登录页
            if !isAuthenticated && !shouldShowOnboarding {
                showLoginSheet = true
            }
        }

        // 请求推送通知权限
        await requestNotificationPermission()

        // 如果用户已登录，尝试恢复之前的 Agenda 状态并上报设备信息
        if isAuthenticated {
            await restoreAgendaIfNeeded()
            // 上报设备信息（如果有 device token）
            await NotificationManager.shared.reportDeviceInfoIfPossible()
        }
    }

    /// 请求推送通知权限
    private func requestNotificationPermission() async {
        do {
            try await NotificationManager.shared.requestAuthorization()
        } catch {
            Log.e("❌ 请求通知权限失败: \(error.localizedDescription)", error: error, category: "App")
        }
    }

    /// 恢复之前的 Agenda 状态（如果之前开启了）
    private func restoreAgendaIfNeeded() async {
        let agendaService = ServiceManager.shared.resolve(AgendaService.self)
        await agendaService.restoreAgendaIfNeeded()
    }

    /// 等待网络可用（带30秒超时）
    /// ⭐️ 在这里才初始化 NetworkMonitor，触发网络权限弹窗
    private func waitForNetworkAvailable() async {
        // 延迟初始化 NetworkMonitor - 在需要检测网络时才创建
        // 这样可以确保在 Splash 动画结束 + 延迟1秒后才触发网络权限弹窗
        if networkMonitor == nil {
            Log.d("🔧 [RootView] 初始化 NetworkMonitor (将触发网络权限弹窗)", category: "App")
            networkMonitor = NetworkMonitor.shared

            // 给 NetworkMonitor 一点时间启动并检测网络状态
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
        }

        // 如果已经连接，直接返回
        guard let monitor = networkMonitor else {
            Log.w("⚠️ [RootView] NetworkMonitor 初始化失败", category: "App")
            return
        }

        if monitor.isConnected {
            Log.i("✅ [RootView] 网络已连接", category: "App")
            return
        }

        Log.i("⏳ [RootView] 等待网络连接...", category: "App")

        // 使用 NetworkMonitor 的带超时机制的方法（默认30秒超时）
        let success = await monitor.waitForConnection(timeout: 30)

        if success {
            Log.i("✅ [RootView] 网络连接已建立", category: "App")
        } else {
            Log.w("⚠️ [RootView] 网络连接超时，继续启动应用", category: "App")
        }
    }

    /// 注册设备到服务器
    /// 异步调用，不阻塞后续流程
    private func registerDevice() async {
        await DeviceTrackManager.shared.register()
    }

    /// 触发网络权限请求，带智能重试
    /// iOS无法直接检测网络权限授权状态，因此采用指数退避重试策略
    private func triggerNetworkPermissionWithRetry() async {
        let retryDelays: [UInt64] = [
            2_000_000_000,  // 2秒 - 给用户时间看弹窗和授权
            3_000_000_000,  // 3秒
            5_000_000_000   // 5秒
        ]

        // 首次请求 - 触发系统网络权限弹窗
        do {
            try await APIClient.shared.healthCheck()
            Log.i("✅ 健康检查成功", category: "App")
            return
        } catch {
            Log.w("⚠️ 首次健康检查失败: \(error.localizedDescription)", category: "App")
            Log.i("ℹ️ 可能原因: 用户尚未授权网络权限，或网络不可用", category: "App")
        }

        // 重试逻辑 - 使用指数退避
        for (index, delay) in retryDelays.enumerated() {
            Log.i("⏳ 等待 \(Double(delay) / 1_000_000_000)秒后重试...", category: "App")
            try? await Task.sleep(nanoseconds: delay)

            do {
                try await APIClient.shared.healthCheck()
                Log.i("✅ 健康检查成功 (重试 \(index + 1) 后)", category: "App")
                return
            } catch {
                Log.w("⚠️ 健康检查失败 (重试 \(index + 1)/\(retryDelays.count)): \(error.localizedDescription)", category: "App")
            }
        }

        Log.w("⚠️ 健康检查最终失败，用户可能拒绝了网络权限或网络不可用", category: "App")
        Log.i("ℹ️ 应用仍可使用，但部分功能可能受限", category: "App")
    }
    
    /// 检查认证状态，返回是否已登录
    private func checkAuthentication() async -> Bool {
        // 首先检查是否有 token 且未过期
        guard authService.isAuthenticated() else {
            Log.w("⚠️ 无有效 token，需要登录", category: "App")
            return false
        }

        // 如果 token 存在且未过期，直接返回 true
        // 避免因为网络问题或后端服务未启动导致用户被登出
        Log.i("✅ 本地 token 有效，用户已登录", category: "App")

        // 后台异步验证 token（不阻塞启动流程）
        Task {
            do {
                _ = try await authService.verifyAndRefreshTokenIfNeeded()
                Log.i("✅ Token 远程验证成功", category: "App")
            } catch {
                Log.w("⚠️ Token 远程验证失败（网络或服务器问题）: \(error.localizedDescription)", error: error, category: "App")
                // 注意：即使远程验证失败，也不登出用户，只要本地 token 未过期
            }
        }

        return true
    }
    
    /// 处理退出登录
    private func handleLogout() {
        appState = .onboarding
        // 退出登录后，显示登录页
        showLoginSheet = true
    }
}

#Preview {
    RootView(
        healthKitFeature: PreviewHealthKitFeature(),
        accountFeature: PreviewAccountFeature(),
        chatFeature: PreviewChatFeature(),
        onboardingFeature: PreviewOnboardingFeature(),
        authService: PreviewAuthService()
    )
}

private struct PreviewHealthKitFeature: FeatureHealthKitBuildable {
    func makeAuthorizationView(onAuthorized: @escaping () -> Void) -> AnyView {
        AnyView(Text("Authorization Preview"))
    }

    func makeDashboardView() -> AnyView {
        AnyView(Text("Dashboard Preview"))
    }

    func makeHealthKitTabView() -> AnyView {
        AnyView(Text("HealthKit Preview"))
    }
}

private struct PreviewAccountFeature: FeatureAccountBuildable {
    func makeLoginView(onLoginSuccess: @escaping () -> Void, isDismissable: Bool = true) -> AnyView {
        AnyView(Text("Login Preview"))
    }

    func makeRegisterView(onRegisterSuccess: @escaping () -> Void) -> AnyView {
        AnyView(Text("Register Preview"))
    }

    func makeAccountLandingView(onSuccess: @escaping () -> Void, isDismissable: Bool = true) -> AnyView {
        AnyView(Text("Account Landing Preview"))
    }

    func makeProfileView(onLogout: @escaping () -> Void) -> AnyView {
        AnyView(Text("Profile Preview"))
    }
}

private struct PreviewChatFeature: FeatureChatBuildable {
    func makeConversationListView() -> AnyView {
        AnyView(Text("Conversation List Preview"))
    }
    
    func makeChatView(conversationId: String?) -> AnyView {
        AnyView(Text("Chat Preview"))
    }
    
    func makeChatTabView() -> AnyView {
        AnyView(Text("Chat Tab Preview"))
    }
}

private struct PreviewOnboardingFeature: FeatureOnboardingBuildable {
    func makeOnboardingView(onComplete: @escaping () -> Void) -> AnyView {
        AnyView(Text("Onboarding Preview"))
    }
}

private class PreviewAuthService: AuthenticationService {
    func register(email: String, password: String, fullName: String?, onboardingId: String) async throws -> DomainAuth.User {
        fatalError("Preview only")
    }

    func login(email: String, password: String) async throws -> DomainAuth.User {
        fatalError("Preview only")
    }

    func logout() async throws {}

    func verifyAndRefreshTokenIfNeeded() async throws -> Bool {
        return false
    }

    func getCurrentUser() async throws -> DomainAuth.User {
        fatalError("Preview only")
    }

    func isAuthenticated() -> Bool {
        return false
    }
    
    func isTokenValid() -> Bool {
        return false
    }

    func getCurrentUserIfAuthenticated() -> DomainAuth.User? {
        return nil
    }
}

// MARK: - MainTabView

/// 主界面TabView，包含AI助手、健康数据和我的三个Tab
struct MainTabView: View {
    @State private var selectedTab: Tab = .chat
    @State private var chatParameters: [String: String]?
    @ObservedObject private var deeplinkHandler = DeeplinkHandler.shared

    private let healthKitFeature: FeatureHealthKitBuildable
    private let chatFeature: FeatureChatBuildable
    private let accountFeature: FeatureAccountBuildable
    private let onLogout: () -> Void

    enum Tab {
        case chat
        case agenda
        case health
        case profile
    }

    init(
        healthKitFeature: FeatureHealthKitBuildable,
        chatFeature: FeatureChatBuildable,
        accountFeature: FeatureAccountBuildable,
        onLogout: @escaping () -> Void
    ) {
        self.healthKitFeature = healthKitFeature
        self.chatFeature = chatFeature
        self.accountFeature = accountFeature
        self.onLogout = onLogout
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // Talk Tab
            chatFeature.makeChatTabView()
                .environment(\.notificationParameters, chatParameters)
                .tabItem {
                    Label("Talk", systemImage: "message.fill")
                }
                .tag(Tab.chat)

            // Agenda Tab (Placeholder)
            AgendaPlaceholderView()
                .tabItem {
                    Label("Agenda", systemImage: "checklist")
                }
                .tag(Tab.agenda)

            // Report Tab
            healthKitFeature.makeHealthKitTabView()
                .tabItem {
                    Label("Report", systemImage: "heart.fill")
                }
                .tag(Tab.health)

            // Me Tab
            accountFeature.makeProfileView(onLogout: onLogout)
                .tabItem {
                    Label("Me", systemImage: "person.fill")
                }
                .tag(Tab.profile)
        }
        .onChange(of: deeplinkHandler.pendingDeeplink) { _, newValue in
            handleDeeplink(newValue)
        }
    }

    /// 处理 deeplink
    private func handleDeeplink(_ deeplink: DeeplinkDestination?) {
        guard let deeplink = deeplink else { return }

        switch deeplink {
        case .dailyReport(let msgId, let from):
            Log.i("📍 导航到 Talk Tab，参数: msg_id=\(msgId), from=\(from)", category: "App")
            // 设置参数
            chatParameters = ["msg_id": msgId, "from": from]
            // 切换到 Talk Tab
            selectedTab = .chat
            // 清除 deeplink
            deeplinkHandler.clearPendingDeeplink()

        case .unknown(let url):
            Log.w("⚠️ 未知的 deeplink: \(url)", category: "App")
            deeplinkHandler.clearPendingDeeplink()
        }
    }
}

// MARK: - AgendaPlaceholderView

/// Agenda页面占位视图
struct AgendaPlaceholderView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "checklist")
                    .font(.system(size: 80))
                    .foregroundColor(.gray)

                Text("Agenda")
                    .font(.title)
                    .fontWeight(.semibold)

                Text("Coming Soon")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Agenda")
        }
    }
}
