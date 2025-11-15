import SwiftUI
import WidgetKit
import ActivityKit
import DomainAuth
import DomainHealth
import DomainOnboarding
import LibraryServiceLoader
import FeatureDebugToolsApi

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
    @State private var isActivityRunning = false
    @State private var isStartingActivity = false
    @State private var isStoppingActivity = false

    private let authorizationService: AuthorizationService

    init(
        authorizationService: AuthorizationService = ServiceManager.shared.resolve(AuthorizationService.self)
    ) {
        self.authorizationService = authorizationService
    }

    var body: some View {
        List {
            // 锁屏卡设置
            Section("健康任务 Live Activity") {
                // 启动/停止按钮
                if #available(iOS 16.1, *) {
                    VStack(spacing: 12) {
                        if !isActivityRunning {
                            Button {
                                Task {
                                    await startLiveActivity()
                                }
                            } label: {
                                HStack {
                                    if isStartingActivity {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Image(systemName: "play.circle.fill")
                                            .font(.title3)
                                    }
                                    Text(isStartingActivity ? "启动中..." : "启动健康任务卡")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            .disabled(isStartingActivity)
                        } else {
                            Button {
                                Task {
                                    await stopLiveActivity()
                                }
                            } label: {
                                HStack {
                                    if isStoppingActivity {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Image(systemName: "stop.circle.fill")
                                            .font(.title3)
                                    }
                                    Text(isStoppingActivity ? "停止中..." : "停止健康任务卡")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            .disabled(isStoppingActivity)
                        }
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }

                NavigationLink {
                    WidgetGuideView()
                } label: {
                    HStack {
                        Label("使用说明", systemImage: "info.circle")
                            .foregroundColor(.primary)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Text(isActivityRunning ? "Live Activity 正在运行，将在锁屏显示健康任务" : "点击启动按钮在锁屏显示 Live Activity")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

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

    @available(iOS 16.1, *)
    private func startLiveActivity() async {
        isStartingActivity = true

        // Check if Live Activities are enabled
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            await MainActor.run {
                authorizationMessage = "Live Activities 未启用\n请在系统设置 > ThriveBody 中启用 Live Activities"
                showingAuthorizationAlert = true
                isStartingActivity = false
            }
            return
        }

        // Start the Live Activity
        await AgendaActivityManager.shared.startActivity(userName: "健康助手")

        await MainActor.run {
            isActivityRunning = AgendaActivityManager.shared.isActivityRunning
            isStartingActivity = false

            if isActivityRunning {
                authorizationMessage = "Live Activity 已启动\n请锁定屏幕查看健康任务卡"
                showingAuthorizationAlert = true
            } else {
                authorizationMessage = "启动失败\n请检查网络连接或稍后重试"
                showingAuthorizationAlert = true
            }
        }
    }

    @available(iOS 16.1, *)
    private func stopLiveActivity() async {
        isStoppingActivity = true

        // Stop the Live Activity
        await AgendaActivityManager.shared.endActivity()

        await MainActor.run {
            isActivityRunning = AgendaActivityManager.shared.isActivityRunning
            isStoppingActivity = false
            authorizationMessage = "Live Activity 已停止"
            showingAuthorizationAlert = true
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

// MARK: - WidgetGuideView

/// Live Activity 使用引导页面
struct WidgetGuideView: View {
    @State private var showingSuccessTip = false
    @State private var tipMessage = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 头部说明
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "list.clipboard.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text("健康任务 Live Activity")
                                .font(.title2)
                                .fontWeight(.bold)

                            Text("实时显示，动态更新")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.leading, 8)

                        Spacer()
                    }

                    Text("通过 Live Activity 在锁屏和灵动岛实时显示你的健康任务")
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)

                // Live Activity 功能介绍
                VStack(alignment: .leading, spacing: 12) {
                    Text("功能特点")
                        .font(.headline)
                        .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 12) {
                        FeatureCard(
                            title: "锁屏显示",
                            description: "在锁屏界面全宽显示健康任务信息，无需解锁即可查看",
                            icon: "lock.iphone",
                            color: .blue
                        )

                        FeatureCard(
                            title: "灵动岛集成",
                            description: "在 iPhone 14 Pro 及以上机型的灵动岛中实时显示任务状态",
                            icon: "iphone.gen3",
                            color: .purple
                        )

                        FeatureCard(
                            title: "自动更新",
                            description: "每 5 分钟自动更新数据，确保信息始终保持最新状态",
                            icon: "arrow.triangle.2.circlepath",
                            color: .green
                        )

                        FeatureCard(
                            title: "Mock 数据测试",
                            description: "目前使用天气数据作为测试，未来将替换为真实健康任务",
                            icon: "cloud.sun.fill",
                            color: .orange
                        )
                    }
                    .padding(.horizontal)
                }

                // 使用说明
                VStack(alignment: .leading, spacing: 16) {
                    Text("使用说明")
                        .font(.headline)
                        .padding(.horizontal)

                    InfoCard(
                        stepNumber: 1,
                        title: "在设置页启动",
                        description: "返回设置页面，点击「启动健康任务卡」按钮即可在锁屏显示 Live Activity",
                        icon: "play.circle.fill",
                        color: .blue
                    )

                    InfoCard(
                        stepNumber: 2,
                        title: "锁屏查看",
                        description: "锁定 iPhone 屏幕后，Live Activity 会以全宽卡片形式显示在锁屏界面",
                        icon: "lock.iphone",
                        color: .green
                    )

                    InfoCard(
                        stepNumber: 3,
                        title: "灵动岛查看",
                        description: "如果使用 iPhone 14 Pro 及以上机型，可在灵动岛中点击查看详细信息",
                        icon: "sparkles",
                        color: .purple
                    )

                    InfoCard(
                        stepNumber: 4,
                        title: "停止显示",
                        description: "不需要时，可在设置页点击「停止健康任务卡」按钮关闭 Live Activity",
                        icon: "stop.circle.fill",
                        color: .red
                    )
                }

                // 系统要求
                VStack(alignment: .leading, spacing: 12) {
                    Text("系统要求")
                        .font(.headline)
                        .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 8) {
                        RequirementRow(
                            icon: "iphone",
                            text: "iOS 16.1 或更高版本",
                            isMet: true
                        )

                        RequirementRow(
                            icon: "sparkles",
                            text: "灵动岛功能需要 iPhone 14 Pro 或更高机型",
                            isMet: false
                        )

                        RequirementRow(
                            icon: "wifi",
                            text: "需要网络连接以获取最新数据",
                            isMet: true
                        )
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }

                // 提示信息
                VStack(alignment: .leading, spacing: 12) {
                    Label {
                        Text("Live Activity 会每 5 分钟自动更新数据")
                            .font(.callout)
                    } icon: {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundColor(.blue)
                    }

                    Label {
                        Text("在锁屏和通知中心都可以看到 Live Activity")
                            .font(.callout)
                    } icon: {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                    }

                    Label {
                        Text("目前使用天气数据作为测试，未来将替换为真实健康任务")
                            .font(.callout)
                    } icon: {
                        Image(systemName: "info.bubble")
                            .foregroundColor(.orange)
                    }

                    Label {
                        Text("Live Activity 最长可持续 8 小时，之后需要重新启动")
                            .font(.callout)
                    } icon: {
                        Image(systemName: "hourglass")
                            .foregroundColor(.purple)
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)

                // 快捷操作
                VStack(spacing: 12) {
                    Button {
                        tipMessage = "请返回设置页面，使用「启动健康任务卡」按钮来启动 Live Activity"
                        showingSuccessTip = true
                    } label: {
                        HStack {
                            Image(systemName: "hand.raised.fill")
                                .font(.title3)
                            Text("我已了解如何使用")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("健康任务 Live Activity")
        .navigationBarTitleDisplayMode(.inline)
        .alert("温馨提示", isPresented: $showingSuccessTip) {
            Button("好的", role: .cancel) {}
        } message: {
            Text(tipMessage)
        }
    }
}

// MARK: - FeatureCard

struct FeatureCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.2))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
    }
}

// MARK: - InfoCard

struct InfoCard: View {
    let stepNumber: Int
    let title: String
    let description: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 40, height: 40)

                Text("\(stepNumber)")
                    .foregroundColor(.white)
                    .fontWeight(.bold)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)

                    Text(title)
                        .font(.headline)
                }

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - RequirementRow

struct RequirementRow: View {
    let icon: String
    let text: String
    let isMet: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(isMet ? .green : .orange)
                .frame(width: 24, height: 24)

            Text(text)
                .font(.callout)

            Spacer()

            if isMet {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.orange)
            }
        }
    }
}
