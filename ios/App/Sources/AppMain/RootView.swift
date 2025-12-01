//
//  RootView.swift
//  ThriveBody
//
//  Created by Codex on 2025/2/14.
//

import SwiftUI
import SwiftData
import FeatureAccountApi
import FeatureChatApi
import FeatureOnboardingApi
import FeatureAgendaApi
import DomainAuth
import LibraryServiceLoader
import LibraryNetworking
import LibraryNotification
import LibraryBase
import LibraryTrack

struct RootView: View {
    @EnvironmentObject var router: RouteManager
    @State private var showingSplash: Bool = true
    @State private var appState: AppState = .initializing
    @State private var networkMonitor: NetworkMonitor?  // 延迟初始化，避免过早触发网络权限弹窗
    @ObservedObject private var notificationManager = NotificationManager.shared

    private let accountFeature: FeatureAccountBuildable
    private let chatFeature: FeatureChatBuildable
    private let agendaFeature: FeatureAgendaBuildable
    private let onboardingFeature: FeatureOnboardingBuildable
    private let authService: AuthenticationService
    private let onboardingStateManager: OnboardingStateManaging
    private let loginURL = URL(string: "thrivebody://login")!
    private let nonDismissableLoginURL = URL(string: "thrivebody://login?dismissable=false")!
    
    // MARK: - App State
    enum AppState {
        case initializing      // 初始化中（Splash阶段）
        case onboarding       // 首次使用引导
        case mainPage         // 进入首页
    }

    init(
        accountFeature: FeatureAccountBuildable = ServiceManager.shared.resolve(FeatureAccountBuildable.self),
        chatFeature: FeatureChatBuildable = ServiceManager.shared.resolve(FeatureChatBuildable.self),
        agendaFeature: FeatureAgendaBuildable = ServiceManager.shared.resolve(FeatureAgendaBuildable.self),
        onboardingFeature: FeatureOnboardingBuildable = ServiceManager.shared.resolve(FeatureOnboardingBuildable.self),
        authService: AuthenticationService = ServiceManager.shared.resolve(AuthenticationService.self),
        onboardingStateManager: OnboardingStateManaging = ServiceManager.shared.resolve(OnboardingStateManaging.self)
    ) {
        self.accountFeature = accountFeature
        self.chatFeature = chatFeature
        self.agendaFeature = agendaFeature
        self.onboardingFeature = onboardingFeature
        self.authService = authService
        self.onboardingStateManager = onboardingStateManager
    }

    var body: some View {
        ZStack {
            Group {
                switch appState {
                case .initializing:
                    Color.clear

                case .onboarding:
                    onboardingFeature.makeOnboardingView {
                        Task { @MainActor in
                            appState = .mainPage
                            // presentLogin(dismissable: false)
                        }
                    }

                case .mainPage:
                    // ⚠️ 关键修改：不用 NavigationStack 包裹 TabView
                    // 每个 tab 会有自己的 NavigationStack（在 builder 中）
                    MainTabView(
                        chatFeature: chatFeature,
                        agendaFeature: agendaFeature,
                        accountFeature: accountFeature,
                        onLogout: handleLogout
                    )
                }
            }

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
        .sheet(item: $router.activeSheet) { match in
            router.buildView(for: match)
        }
        .fullScreenCover(item: $router.activeFullscreen) { match in
            router.buildView(for: match)
        }
        .onAppear(perform: configureRouterCallbacks)
        .onOpenURL { url in
            handleIncomingURL(url)
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
        }

        // 注册设备（异步，不阻塞流程）
        Task {
            await DeviceTrackManager.shared.register()
        }

        // 确定应用初始状态
        let initialState: AppState
        if shouldShowOnboarding {
            // 需要Onboarding
            initialState = .onboarding
        } else {
            // 不需要onboarding，直接进入首页
            initialState = .mainPage // 先进入authenticated状态，然后立即弹出登录页
        }

        // 关闭 Splash，同时设置应用状态
        await MainActor.run {
            appState = initialState
            showingSplash = false

            // 如果未登录但已完成Onboarding，立即弹出登录页
            // if !isAuthenticated && !shouldShowOnboarding {
            //     presentLogin()
            // }
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
        appState = .mainPage
        // 退出登录后，显示登录页
        // presentLogin()
    }

    private func presentLogin(dismissable: Bool = true) {
        let targetURL = dismissable ? loginURL : nonDismissableLoginURL
        // 使用默认的 fullscreen presentation
        router.open(url: targetURL)
    }

    private func configureRouterCallbacks() {
        router.onLoginSuccess = {
            appState = .mainPage
            Task {
                await NotificationManager.shared.reportDeviceInfoIfPossible()
            }
        }
        router.onLogout = { handleLogout() }
    }

    private func handleIncomingURL(_ url: URL) {
        guard url.scheme == "thrivebody" else { return }

        let path = url.host.map { "/\($0)" } ?? (url.path.isEmpty ? "/" : url.path)
        if path == "/main" {
            handleMainDeepLink(url)
        } else {
            router.open(url: url)
        }
    }

    private func handleMainDeepLink(_ url: URL) {
        let queryItems = parseQueryItems(from: url)

        // 切到主页面
        appState = .mainPage

        // 切 tab，默认保持当前 tab
        if let tabValue = queryItems["tab"]?.lowercased() {
            switch tabValue {
            case "agenda":
                router.currentTab = .agenda
            case "profile":
                router.currentTab = .profile
            default:
                break
            }
        }

        // 预置要发送的消息（如果需要发送消息，则打开对话页面）
        if let rawMessage = queryItems["sendmsg"], !rawMessage.isEmpty {
            let cleaned = rawMessage
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            if !cleaned.isEmpty {
                router.enqueueChatMessage(cleaned)
                // 打开对话页面
                if let chatURL = router.buildURL(path: "/chat", queryItems: ["present": "fullscreen"]) {
                    router.open(url: chatURL)
                }
            }
        }

        // 如果是从 Live Activity 完成按钮点击而来，切换到下一条 mock 任务
        if queryItems["complete"] == "1" {
            Task { @MainActor in
                if #available(iOS 16.1, *) {
                    await LiveActivityManager.shared.advanceToNextMockTask()
                }
            }
        }
    }

    private func parseQueryItems(from url: URL) -> [String: String] {
        guard let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems else {
            return [:]
        }

        var result: [String: String] = [:]
        for item in items {
            if let value = item.value {
                result[item.name] = value
            }
        }
        return result
    }
}

#Preview {
    RootView(
        accountFeature: PreviewAccountFeature(),
        chatFeature: PreviewChatFeature(),
        agendaFeature: PreviewAgendaFeature(),
        onboardingFeature: PreviewOnboardingFeature(),
        authService: PreviewAuthService()
    )
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

private struct PreviewAgendaFeature: FeatureAgendaBuildable {
    func makeAgendaTabView() -> AnyView {
        AnyView(Text("Agenda Tab Preview"))
    }

    func makeAgendaSettingsView() -> AnyView {
        AnyView(Text("Agenda Settings Preview"))
    }

    func makeDungeonDetailView() -> AnyView {
        AnyView(Text("Dungeon Detail Preview"))
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
