import SwiftUI

/// Debug Tools Main View - 调试工具主界面
struct DebugToolsView: View {
    var body: some View {
        List {
            Section("数据调试") {
                NavigationLink {
                    ChatDebugView()
                } label: {
                    Label("SwiftData 聊天消息", systemImage: "internaldrive")
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
