import SwiftUI
import LibraryNotification
import DomainOnboarding

/// Debug Tools Main View - 调试工具主界面
struct DebugToolsView: View {
    @ObservedObject private var notificationManager = NotificationManager.shared
    @State private var showCopiedAlert = false
    @State private var hasJustReset = false

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
                        Label("重置Onboarding状态", systemImage: "arrow.counterclockwise")
                            .foregroundColor(.orange)
                    }

                    Text(onboardingStatusText)
                        .font(.caption)
                        .foregroundColor(hasJustReset ? .green : .secondary)
                }
                .padding(.vertical, 4)
            }

            // 推送通知
            Section("推送通知") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Device Token")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let token = notificationManager.deviceToken {
                        Text(token)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.primary)
                            .textSelection(.enabled)
                    } else {
                        Text("未获取到 Device Token")
                            .font(.caption)
                            .foregroundColor(.orange)
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
                        .foregroundColor(.secondary)
                        .font(.caption)
                }

                HStack {
                    Text("Version")
                    Spacer()
                    Text(appVersion)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Build")
                    Spacer()
                    Text(appBuild)
                        .foregroundColor(.secondary)
                }
            }

            Section("系统信息") {
                HStack {
                    Text("iOS Version")
                    Spacer()
                    Text(UIDevice.current.systemVersion)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Device Model")
                    Spacer()
                    Text(UIDevice.current.model)
                        .foregroundColor(.secondary)
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
            return "已重置onboarding状态"
        } else {
            return OnboardingStateManager.shared.hasCompletedOnboarding ? "已完成onboarding" : "未完成onboarding"
        }
    }

    /// 重置 Onboarding 状态
    private func resetOnboardingState() {
        OnboardingStateManager.shared.resetOnboardingState()
        hasJustReset = true
    }

    /// 复制 Device Token 到剪切板
    private func copyDeviceToken() {
        guard let token = notificationManager.deviceToken else { return }
        UIPasteboard.general.string = token
        showCopiedAlert = true
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
}
