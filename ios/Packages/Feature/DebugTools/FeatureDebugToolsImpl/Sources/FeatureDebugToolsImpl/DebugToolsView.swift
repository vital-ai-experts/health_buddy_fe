import SwiftUI

/// 设备令牌环境键
private struct DeviceTokenKey: EnvironmentKey {
    static let defaultValue: String? = nil
}

extension EnvironmentValues {
    fileprivate var deviceToken: String? {
        get { self[DeviceTokenKey.self] }
        set { self[DeviceTokenKey.self] = newValue }
    }
}

/// Debug Tools Main View - 调试工具主界面
struct DebugToolsView: View {
    @Environment(\.deviceToken) private var deviceToken
    @State private var showCopiedAlert = false

    var body: some View {
        List {
            Section("数据调试") {
                NavigationLink {
                    ChatDebugView()
                } label: {
                    Label("SwiftData 聊天消息", systemImage: "internaldrive")
                }
            }

            // 推送通知
            Section("推送通知") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Device Token")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let token = deviceToken {
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

                if deviceToken != nil {
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

    /// 复制 Device Token 到剪切板
    private func copyDeviceToken() {
        guard let token = deviceToken else { return }
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
