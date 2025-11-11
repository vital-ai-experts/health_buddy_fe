//
//  RootView.swift
//  HealthBuddy
//
//  Created by Codex on 2025/2/14.
//

import SwiftUI
import FeatureHealthKitApi
import FeatureAccountApi
import FeatureChatApi
import FeatureOnboardingApi
import DomainAuth
import DomainOnboarding
import LibraryServiceLoader
import LibraryNetworking

struct RootView: View {
    @State private var showingSplash: Bool = true
    @State private var appState: AppState = .initializing
    @State private var showLoginSheet: Bool = false

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
                        // Onboarding 完成后，标记为已完成并弹出登录页
                        OnboardingStateManager.shared.markOnboardingAsCompleted()
                        showLoginSheet = true
                    }
                    
                case .authenticated:
                    // 主界面 - TabView包含AI助手、健康数据和我的三个Tab
                    MainTabView(
                        healthKitFeature: healthKitFeature,
                        chatFeature: chatFeature,
                        onLogout: handleLogout
                    )
                }
            }
            .sheet(isPresented: $showLoginSheet) {
                // 登录页面以 Sheet 形式按需弹出
                accountFeature.makeAccountLandingView {
                    // 登录成功
                    showLoginSheet = false
                    appState = .authenticated
                }
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

        // 等待最少 Splash 时间
        let elapsedTime = DispatchTime.now().uptimeNanoseconds - startTime.uptimeNanoseconds
        if elapsedTime < minimumSplashDuration {
            try? await Task.sleep(nanoseconds: minimumSplashDuration - elapsedTime)
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

        // 如果需要显示Onboarding，延迟触发网络权限请求
        if shouldShowOnboarding {
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1秒

            // 发送健康检查请求，触发网络授权弹窗
            do {
                try await APIClient.shared.healthCheck()
                print("✅ 健康检查成功")
            } catch {
                print("⚠️ 健康检查失败: \(error.localizedDescription)")
            }
        }
    }
    
    /// 检查认证状态，返回是否已登录
    private func checkAuthentication() async -> Bool {
        // 首先检查是否有 token 且未过期
        guard authService.isAuthenticated() else {
            print("⚠️ 无有效 token，需要登录")
            return false
        }

        // 如果 token 存在且未过期，直接返回 true
        // 避免因为网络问题或后端服务未启动导致用户被登出
        print("✅ 本地 token 有效，用户已登录")

        // 后台异步验证 token（不阻塞启动流程）
        Task {
            do {
                _ = try await authService.verifyAndRefreshTokenIfNeeded()
                print("✅ Token 远程验证成功")
            } catch {
                print("⚠️ Token 远程验证失败（网络或服务器问题）: \(error.localizedDescription)")
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
    func makeLoginView(onLoginSuccess: @escaping () -> Void) -> AnyView {
        AnyView(Text("Login Preview"))
    }

    func makeRegisterView(onRegisterSuccess: @escaping () -> Void) -> AnyView {
        AnyView(Text("Register Preview"))
    }

    func makeAccountLandingView(onSuccess: @escaping () -> Void) -> AnyView {
        AnyView(Text("Account Landing Preview"))
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
    func register(email: String, password: String, fullName: String?) async throws -> DomainAuth.User {
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

    private let healthKitFeature: FeatureHealthKitBuildable
    private let chatFeature: FeatureChatBuildable
    private let onLogout: () -> Void

    enum Tab {
        case chat
        case health
        case profile
    }

    init(
        healthKitFeature: FeatureHealthKitBuildable,
        chatFeature: FeatureChatBuildable,
        onLogout: @escaping () -> Void
    ) {
        self.healthKitFeature = healthKitFeature
        self.chatFeature = chatFeature
        self.onLogout = onLogout
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // AI助手Tab
            chatFeature.makeChatTabView()
                .tabItem {
                    Label("AI助手", systemImage: "message.fill")
                }
                .tag(Tab.chat)

            // 健康数据Tab
            healthKitFeature.makeHealthKitTabView()
                .tabItem {
                    Label("健康", systemImage: "heart.fill")
                }
                .tag(Tab.health)

            // 我的Tab
            ProfileView(onLogout: onLogout)
                .tabItem {
                    Label("我的", systemImage: "person.fill")
                }
                .tag(Tab.profile)
        }
    }
}

// MARK: - ProfileView

/// 我的页面，显示用户信息和设置选项
struct ProfileView: View {
    @State private var user: DomainAuth.User?
    @State private var isLoading = true
    @State private var showingLogoutAlert = false
    
    private let authService: AuthenticationService
    private let onLogout: () -> Void
    
    init(
        onLogout: @escaping () -> Void,
        authService: AuthenticationService = ServiceManager.shared.resolve(AuthenticationService.self)
    ) {
        self.onLogout = onLogout
        self.authService = authService
    }
    
    var body: some View {
        NavigationStack {
            List {
                // 用户信息部分
                Section {
                    if isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else if let user = user {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.blue)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(user.fullName)
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                    
                                    Text(user.email)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                
                // 设置选项
                Section("设置") {
                    NavigationLink {
                        AccountSettingsView()
                    } label: {
                        Label("账号设置", systemImage: "person.crop.circle")
                    }

                    NavigationLink {
                        AboutView()
                    } label: {
                        Label("关于", systemImage: "info.circle")
                    }
                }

                // 开发者选项
                #if DEBUG
                Section("开发者选项") {
                    Button {
                        OnboardingStateManager.shared.resetOnboardingState()
                    } label: {
                        Label("重置Onboarding状态", systemImage: "arrow.counterclockwise")
                            .foregroundColor(.orange)
                    }
                }
                #endif
                
                // 退出登录
                Section {
                    Button(role: .destructive) {
                        showingLogoutAlert = true
                    } label: {
                        HStack {
                            Spacer()
                            Label("退出登录", systemImage: "rectangle.portrait.and.arrow.right")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("我的")
            .task {
                await loadUserInfo()
            }
            .alert("确认退出", isPresented: $showingLogoutAlert) {
                Button("取消", role: .cancel) {}
                Button("退出", role: .destructive) {
                    Task {
                        await logout()
                    }
                }
            } message: {
                Text("确定要退出登录吗？")
            }
        }
    }
    
    private func loadUserInfo() async {
        isLoading = true
        do {
            user = try await authService.getCurrentUser()
        } catch {
            print("Failed to load user info: \(error)")
        }
        isLoading = false
    }
    
    private func logout() async {
        do {
            try await authService.logout()
            await MainActor.run {
                onLogout()
            }
        } catch {
            print("Failed to logout: \(error)")
        }
    }
}

// MARK: - AccountSettingsView

/// 账号设置页面
struct AccountSettingsView: View {
    var body: some View {
        List {
            Section("个人信息") {
                NavigationLink {
                    Text("编辑个人资料")
                } label: {
                    Label("编辑资料", systemImage: "pencil")
                }
                
                NavigationLink {
                    Text("修改密码")
                } label: {
                    Label("修改密码", systemImage: "lock")
                }
            }
            
            Section("隐私") {
                NavigationLink {
                    Text("隐私设置")
                } label: {
                    Label("隐私设置", systemImage: "hand.raised")
                }
            }
        }
        .navigationTitle("账号设置")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - AboutView

/// 关于页面
struct AboutView: View {
    var body: some View {
        List {
            Section {
                HStack {
                    Text("版本")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
            }
            
            Section {
                Link(destination: URL(string: "https://github.com")!) {
                    Label("GitHub", systemImage: "link")
                }
                
                Link(destination: URL(string: "https://example.com/privacy")!) {
                    Label("隐私政策", systemImage: "lock.doc")
                }
                
                Link(destination: URL(string: "https://example.com/terms")!) {
                    Label("服务条款", systemImage: "doc.text")
                }
            }
        }
        .navigationTitle("关于")
        .navigationBarTitleDisplayMode(.inline)
    }
}
