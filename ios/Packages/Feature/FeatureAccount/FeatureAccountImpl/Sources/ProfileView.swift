import SwiftUI
import DomainAuth
import DomainHealth
import DomainOnboarding
import LibraryServiceLoader
import FeatureDebugToolsApi
import FeatureAgendaApi

/// Me页面，显示用户信息和设置选项
public struct ProfileView: View {
    @State private var user: DomainAuth.User?
    @State private var isLoading = true

    private let authService: AuthenticationService
    private let onLogout: () -> Void

    public init(
        onLogout: @escaping () -> Void,
        authService: AuthenticationService = ServiceManager.shared.resolve(AuthenticationService.self)
    ) {
        self.onLogout = onLogout
        self.authService = authService
    }

    public var body: some View {
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

                                    Text(user.email.isEmpty ? "user@example.com" : user.email)
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
                Section {
                    NavigationLink {
                        AccountSettingsView(onLogout: onLogout)
                    } label: {
                        Label("账号", systemImage: "person.crop.circle")
                    }

                    NavigationLink {
                        SettingsView()
                    } label: {
                        Label("设置", systemImage: "gearshape")
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
                    if let debugToolsBuilder = ServiceManager.shared.resolveOptional(FeatureDebugToolsBuildable.self) {
                        NavigationLink {
                            debugToolsBuilder.makeDebugToolsView()
                        } label: {
                            Label("开发者工具", systemImage: "wrench.and.screwdriver")
                        }
                    }

                    Button {
                        OnboardingStateManager.shared.resetOnboardingState()
                    } label: {
                        Label("重置Onboarding状态", systemImage: "arrow.counterclockwise")
                            .foregroundColor(.orange)
                    }
                }
                #endif
            }
            .navigationTitle("Me")
            .task {
                await loadUserInfo()
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
}

// MARK: - SettingsView

/// 设置页面
struct SettingsView: View {
    @State private var showingAuthorizationAlert = false
    @State private var authorizationMessage = ""
    @State private var isAuthorizingHealthKit = false

    private let authorizationService: AuthorizationService

    init(
        authorizationService: AuthorizationService = ServiceManager.shared.resolve(AuthorizationService.self)
    ) {
        self.authorizationService = authorizationService
    }

    var body: some View {
        List {
            // HealthKit 设置
            Section("健康数据") {
                Button {
                    Task {
                        await requestHealthKitAuthorization()
                    }
                } label: {
                    HStack {
                        Label("重新授权 HealthKit", systemImage: "heart.text.square")
                            .foregroundColor(.primary)

                        Spacer()

                        if isAuthorizingHealthKit {
                            ProgressView()
                        }
                    }
                }
                .disabled(isAuthorizingHealthKit)

                Text("如果您添加了新的健康数据权限，可以点击此按钮重新授权")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // 通用设置
            Section("通用") {
                if let agendaBuilder = ServiceManager.shared.resolveOptional(FeatureAgendaBuildable.self) {
                    NavigationLink {
                        agendaBuilder.makeAgendaSettingsView()
                    } label: {
                        Label("任务卡 Agenda", systemImage: "figure.walk.circle.fill")
                    }
                }

                NavigationLink {
                    Text("通知设置")
                } label: {
                    Label("通知", systemImage: "bell")
                }

                NavigationLink {
                    Text("隐私设置")
                } label: {
                    Label("隐私", systemImage: "hand.raised")
                }
            }
        }
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
        .alert(
            authorizationMessage,
            isPresented: $showingAuthorizationAlert
        ) {
            Button("确定", role: .cancel) {}
        }
    }

    private func requestHealthKitAuthorization() async {
        isAuthorizingHealthKit = true

        do {
            let status = try await authorizationService.requestAuthorization()

            await MainActor.run {
                switch status {
                case .authorized:
                    authorizationMessage = "HealthKit 授权成功"
                case .denied:
                    authorizationMessage = "HealthKit 授权被拒绝，请在系统设置中手动开启"
                case .notDetermined:
                    authorizationMessage = "HealthKit 授权状态未确定"
                case .unavailable:
                    authorizationMessage = "此设备不支持 HealthKit"
                }

                showingAuthorizationAlert = true
                isAuthorizingHealthKit = false
            }
        } catch {
            await MainActor.run {
                authorizationMessage = "授权失败: \(error.localizedDescription)"
                showingAuthorizationAlert = true
                isAuthorizingHealthKit = false
            }
        }
    }
}

// MARK: - AccountSettingsView

/// 账号设置页面
struct AccountSettingsView: View {
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
        List {
            // 用户信息
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

                                Text(user.email.isEmpty ? "user@example.com" : user.email)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                }
            }

            // 账号操作
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
        .navigationTitle("账号")
        .navigationBarTitleDisplayMode(.inline)
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
