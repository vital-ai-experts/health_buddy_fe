import SwiftUI
import WidgetKit
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

    private let authorizationService: AuthorizationService

    init(
        authorizationService: AuthorizationService = ServiceManager.shared.resolve(AuthorizationService.self)
    ) {
        self.authorizationService = authorizationService
    }

    var body: some View {
        List {
            // 锁屏卡设置
            Section("锁屏卡") {
                NavigationLink {
                    WidgetGuideView()
                } label: {
                    HStack {
                        Label("添加健康任务锁屏卡", systemImage: "square.dashed.inset.filled")
                            .foregroundColor(.primary)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Text("一键查看如何将健康任务卡添加到锁屏")
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

/// Widget 添加引导页面
struct WidgetGuideView: View {
    @State private var currentStep = 0
    @State private var showingSuccessTip = false

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
                            Text("健康任务锁屏卡")
                                .font(.title2)
                                .fontWeight(.bold)

                            Text("待办事项，一目了然")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.leading, 8)

                        Spacer()
                    }

                    Text("每 5 分钟自动更新，显示你的健康任务和待办事项")
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)

                // 添加步骤
                VStack(alignment: .leading, spacing: 16) {
                    Text("添加步骤")
                        .font(.headline)
                        .padding(.horizontal)

                    GuideStepCard(
                        stepNumber: 1,
                        title: "锁定屏幕",
                        description: "在 iPhone 上锁定屏幕",
                        icon: "lock.iphone",
                        isCompleted: currentStep > 0
                    )

                    GuideStepCard(
                        stepNumber: 2,
                        title: "长按锁屏",
                        description: "长按锁屏界面，直到出现「自定」按钮",
                        icon: "hand.tap.fill",
                        isCompleted: currentStep > 1
                    )

                    GuideStepCard(
                        stepNumber: 3,
                        title: "点击自定",
                        description: "点击「自定」或「Customize」按钮",
                        icon: "slider.horizontal.3",
                        isCompleted: currentStep > 2
                    )

                    GuideStepCard(
                        stepNumber: 4,
                        title: "选择锁定画面",
                        description: "在弹出的菜单中选择「锁定画面」",
                        icon: "rectangle.portrait",
                        isCompleted: currentStep > 3
                    )

                    GuideStepCard(
                        stepNumber: 5,
                        title: "添加小组件",
                        description: "点击锁屏上想要添加 Widget 的位置（圆形、矩形或顶部内联区域）",
                        icon: "plus.square.dashed",
                        isCompleted: currentStep > 4
                    )

                    GuideStepCard(
                        stepNumber: 6,
                        title: "搜索健康任务",
                        description: "在 Widget 列表中滚动找到「健康任务」或使用搜索功能",
                        icon: "magnifyingglass",
                        isCompleted: currentStep > 5
                    )

                    GuideStepCard(
                        stepNumber: 7,
                        title: "选择样式",
                        description: "选择喜欢的 Widget 样式（推荐：矩形样式，可显示更多信息）",
                        icon: "square.grid.3x3.fill",
                        isCompleted: currentStep > 6
                    )

                    GuideStepCard(
                        stepNumber: 8,
                        title: "完成设置",
                        description: "点击完成，天气卡将显示在锁屏上",
                        icon: "checkmark.circle.fill",
                        isCompleted: currentStep > 7
                    )
                }

                // Widget 样式预览
                VStack(alignment: .leading, spacing: 12) {
                    Text("Widget 样式")
                        .font(.headline)
                        .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 12) {
                        WidgetStylePreview(
                            title: "矩形卡片（推荐）",
                            description: "显示完整信息，包括任务详情和更新时间（使用天气数据作为测试）",
                            icon: "rectangle.fill",
                            color: .blue
                        )

                        WidgetStylePreview(
                            title: "圆形卡片",
                            description: "简洁显示，包含任务图标和关键信息（使用天气数据作为测试）",
                            icon: "circle.fill",
                            color: .green
                        )

                        WidgetStylePreview(
                            title: "内联卡片",
                            description: "顶部显示，一行文字展示核心信息（使用天气数据作为测试）",
                            icon: "minus.rectangle.fill",
                            color: .orange
                        )
                    }
                    .padding(.horizontal)
                }

                // 提示信息
                VStack(alignment: .leading, spacing: 12) {
                    Label {
                        Text("健康任务每 5 分钟自动更新一次")
                            .font(.callout)
                    } icon: {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundColor(.blue)
                    }

                    Label {
                        Text("Widget 会显示数据的最后更新时间")
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
                        Text("如果 Widget 不更新，可以尝试移除后重新添加")
                            .font(.callout)
                    } icon: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)

                // 快捷操作
                VStack(spacing: 12) {
                    Button {
                        // iOS 不允许直接跳转到 Widget 添加页面
                        // 但可以提示用户操作
                        showingSuccessTip = true
                    } label: {
                        HStack {
                            Image(systemName: "hand.raised.fill")
                                .font(.title3)
                            Text("我已了解如何添加")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }

                    Button {
                        // 刷新所有 Widget
                        WidgetCenter.shared.reloadAllTimelines()
                        showingSuccessTip = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                                .font(.title3)
                            Text("刷新 Widget 数据")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("添加健康任务锁屏卡")
        .navigationBarTitleDisplayMode(.inline)
        .alert("操作成功", isPresented: $showingSuccessTip) {
            Button("好的", role: .cancel) {}
        } message: {
            Text("Widget 数据已刷新，请按照上述步骤添加到锁屏")
        }
    }
}

// MARK: - GuideStepCard

struct GuideStepCard: View {
    let stepNumber: Int
    let title: String
    let description: String
    let icon: String
    let isCompleted: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(isCompleted ? Color.green : Color.blue)
                    .frame(width: 40, height: 40)

                if isCompleted {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                } else {
                    Text("\(stepNumber)")
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(.blue)

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

// MARK: - WidgetStylePreview

struct WidgetStylePreview: View {
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
