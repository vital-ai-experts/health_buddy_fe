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
import LibraryServiceLoader
import LibraryNetworking

struct RootView: View {
    @State private var showingSplash: Bool = true
    @State private var isInitialized: Bool = false
    @State private var showOnboarding: Bool = false
    @State private var isAuthenticated: Bool = false

    private let healthKitFeature: FeatureHealthKitBuildable
    private let accountFeature: FeatureAccountBuildable
    private let chatFeature: FeatureChatBuildable
    private let onboardingFeature: FeatureOnboardingBuildable
    private let authService: AuthenticationService

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
            // Main content - 只在初始化完成后显示
            if isInitialized {
                if isAuthenticated {
                    // 主界面 - TabView包含AI助手、健康数据和我的三个Tab
                    MainTabView(
                        healthKitFeature: healthKitFeature,
                        chatFeature: chatFeature,
                        onLogout: {
                            isAuthenticated = false
                        }
                    )
                } else if showOnboarding {
                    // Onboarding flow
                    onboardingFeature.makeOnboardingView {
                        // Onboarding 完成后跳转到登录页
                        showOnboarding = false
                    }
                } else {
                    // Account landing page (登录页)
                    accountFeature.makeAccountLandingView {
                        isAuthenticated = true
                    }
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

        // Check authentication status
        isAuthenticated = authService.isAuthenticated()

        // 等待最少 Splash 时间
        let elapsedTime = DispatchTime.now().uptimeNanoseconds - startTime.uptimeNanoseconds
        if elapsedTime < minimumSplashDuration {
            try? await Task.sleep(nanoseconds: minimumSplashDuration - elapsedTime)
        }

        // Splash 结束前先标记初始化完成（但还不显示内容）
        await MainActor.run {
            isInitialized = true
        }
        
        // Splash 结束后关闭 Splash 画面
        await MainActor.run {
            showingSplash = false
        }
        
        // 等待 1 秒
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1秒
        
        // 发送健康检查请求，触发网络授权弹窗
        do {
            try await APIClient.shared.healthCheck()
            print("✅ 健康检查成功")
        } catch {
            print("⚠️ 健康检查失败: \(error.localizedDescription)")
            // 即使失败也继续流程
        }
        
        // 如果未登录，显示 Onboarding
        if !isAuthenticated {
            await MainActor.run {
                showOnboarding = true
            }
        }
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

    func makeHealthKitDemoView() -> AnyView {
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
    
    func makeChatDemoView() -> AnyView {
        AnyView(Text("Chat Demo Preview"))
    }
}

private struct PreviewOnboardingFeature: FeatureOnboardingBuildable {
    func makeOnboardingView(onComplete: @escaping () -> Void) -> AnyView {
        AnyView(Text("Onboarding Preview"))
    }
}

private class PreviewAuthService: AuthenticationService {
    func register(email: String, password: String, fullName: String) async throws -> DomainAuth.User {
        fatalError("Preview only")
    }

    func login(email: String, password: String) async throws -> DomainAuth.User {
        fatalError("Preview only")
    }

    func logout() async throws {}

    func refreshToken() async throws {}

    func getCurrentUser() async throws -> DomainAuth.User {
        fatalError("Preview only")
    }

    func isAuthenticated() -> Bool {
        return false
    }

    func getCurrentUserIfAuthenticated() -> DomainAuth.User? {
        return nil
    }
}

// MARK: - MainTabView

/// 主界面TabView，包含AI助手、健康数据和我的三个Tab
struct MainTabView: View {
    private let healthKitFeature: FeatureHealthKitBuildable
    private let chatFeature: FeatureChatBuildable
    private let onLogout: () -> Void
    
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
        TabView {
            // AI助手Tab
            chatFeature.makeChatDemoView()
                .tabItem {
                    Label("AI助手", systemImage: "message.fill")
                }
            
            // 健康数据Tab
            healthKitFeature.makeHealthKitDemoView()
                .tabItem {
                    Label("健康", systemImage: "heart.fill")
                }
            
            // 我的Tab
            ProfileView(onLogout: onLogout)
                .tabItem {
                    Label("我的", systemImage: "person.fill")
                }
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
