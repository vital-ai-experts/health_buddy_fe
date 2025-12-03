import SwiftUI
import ThemeKit
import LibraryNotification
import FeatureOnboardingApi
import DomainAuth
import LibraryServiceLoader
import LibraryBase
import FeatureChatImpl
import SwiftData

/// Debug Tools Main View - 调试工具主界面
struct DebugToolsView: View {
    @ObservedObject private var notificationManager = NotificationManager.shared
    @State private var showCopiedAlert = false
    @State private var hasJustReset = false
    @Environment(\.modelContext) private var modelContext
    private let onboardingManager = ServiceManager.shared.resolve(OnboardingStateManaging.self)
    private let authService = ServiceManager.shared.resolve(AuthenticationService.self)

    var body: some View {
        List {
            Section("数据调试") {
                NavigationLink {
                    ChatDebugView()
                } label: {
                    Label("SwiftData 聊天消息", systemImage: "internaldrive")
                }

                VStack(alignment: .leading, spacing: 4) {
                    Button {
                        resetOnboardingState()
                    } label: {
                        Label("清除 Onboarding & 对话历史", systemImage: "trash")
                            .foregroundColor(.Palette.warningMain)
                    }

                    Text(onboardingStatusText)
                        .font(.caption)
                        .foregroundColor(hasJustReset ? .green : .secondary)
                }
                .padding(.vertical, 4)
            }

            Section("功能调试") {
                Button {
                    openDungeonDetail()
                } label: {
                    Label("打开副本详情页", systemImage: "gamecontroller")
                }
            }

            // 推送通知
            Section("推送通知") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Device Token")
                        .font(.caption)
                        .foregroundColor(.Palette.textSecondary)

                    if let token = notificationManager.deviceToken {
                        Text(token)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.Palette.textPrimary)
                            .textSelection(.enabled)
                    } else {
                        Text("未获取到 Device Token")
                            .font(.caption)
                            .foregroundColor(.Palette.warningMain)
                    }
                }
                .padding(.vertical, 4)

                if notificationManager.deviceToken != nil {
                    Button {
                        copyDeviceToken()
                    } label: {
                        Label("复制 Device Token", systemImage: "doc.on.doc")
                    }
                }
            }

            Section("应用信息") {
                HStack {
                    Text("Bundle ID")
                    Spacer()
                    Text(Bundle.main.bundleIdentifier ?? "Unknown")
                        .foregroundColor(.Palette.textSecondary)
                        .font(.caption)
                }

                HStack {
                    Text("Version")
                    Spacer()
                    Text(appVersion)
                        .foregroundColor(.Palette.textSecondary)
                }

                HStack {
                    Text("Build")
                    Spacer()
                    Text(appBuild)
                        .foregroundColor(.Palette.textSecondary)
                }
            }

            Section("系统信息") {
                HStack {
                    Text("iOS Version")
                    Spacer()
                    Text(UIDevice.current.systemVersion)
                        .foregroundColor(.Palette.textSecondary)
                }

                HStack {
                    Text("Device Model")
                    Spacer()
                    Text(UIDevice.current.model)
                        .foregroundColor(.Palette.textSecondary)
                }
            }
        }
        .navigationTitle("开发者工具")
        .navigationBarTitleDisplayMode(.inline)
        .alert("已复制", isPresented: $showCopiedAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text("Device Token 已复制到剪切板")
        }
    }

    /// Onboarding 状态文字
    private var onboardingStatusText: String {
        if hasJustReset {
            return "已清除 Onboarding 状态，App 将在 3 秒后自动重启"
        } else {
            return onboardingManager.hasCompletedOnboarding ? "已完成onboarding" : "未完成onboarding"
        }
    }

    /// 重置 Onboarding 状态
    private func resetOnboardingState() {
        onboardingManager.resetOnboardingState()
        clearChatHistory()
        hasJustReset = true
        Task {
            await logoutAfterReset()
            await killAppAfterDelay()
        }
    }

    private func logoutAfterReset() async {
        do {
            try await authService.logout()
            await MainActor.run {
                RouteManager.shared.handleLogoutRequested()
            }
        } catch {
            Log.e("退出登录失败: \(error.localizedDescription)", error: error, category: "DebugTools")
        }
    }

    /// 复制 Device Token 到剪切板
    private func copyDeviceToken() {
        guard let token = notificationManager.deviceToken else { return }
        UIPasteboard.general.string = token
        showCopiedAlert = true
    }

    private func openDungeonDetail() {
        guard let url = RouteManager.shared.buildURL(path: "/dungeon_detail") else { return }
        RouteManager.shared.open(url: url)
    }

    /// 清空本地聊天记录
    private func clearChatHistory() {
        let storage = ChatStorageService(modelContext: modelContext)
        do {
            try storage.deleteAllMessages()
            Log.i("✅ 已清空本地聊天记录", category: "DebugTools")
        } catch {
            Log.e("❌ 清空聊天记录失败: \(error.localizedDescription)", error: error, category: "DebugTools")
        }
    }

    /// 3 秒后杀掉 App，确保状态彻底重置
    private func killAppAfterDelay() async {
        try? await Task.sleep(nanoseconds: 3_000_000_000)
        exit(0)
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    private var appBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
}

#Preview {
    NavigationStack {
        DebugToolsView()
    }
    .modelContainer(for: [LocalChatMessage.self], inMemory: true)
}
