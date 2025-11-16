import SwiftUI
import SwiftData
import FeatureChatImpl
import LibraryBase

/// 调试视图：查看本地存储的聊天消息
struct ChatDebugView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var messages: [LocalChatMessage] = []
    @State private var messageCount: Int = 0
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section("数据库统计") {
                HStack {
                    Text("消息总数")
                    Spacer()
                    Text("\(messageCount)")
                        .foregroundColor(.secondary)
                }
            }

            Section("所有消息") {
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else if let error = errorMessage {
                    Text("错误: \(error)")
                        .foregroundColor(.red)
                } else if messages.isEmpty {
                    Text("暂无消息")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(messages, id: \.id) { message in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(message.isFromUser ? "用户" : "助手")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(message.isFromUser ? Color.blue.opacity(0.2) : Color.green.opacity(0.2))
                                    .cornerRadius(4)

                                Spacer()

                                Text(formatDate(message.createdAt))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Text(message.content)
                                .font(.body)

                            HStack {
                                Text("ID: \(message.id)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)

                                Spacer()

                                if let convId = message.conversationId {
                                    Text("会话: \(convId.prefix(8))...")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            Section("操作") {
                Button(role: .destructive) {
                    deleteAllMessages()
                } label: {
                    HStack {
                        Spacer()
                        Label("清空所有数据", systemImage: "trash")
                        Spacer()
                    }
                }

                Button {
                    exportDatabasePath()
                } label: {
                    HStack {
                        Spacer()
                        Label("打印数据库路径", systemImage: "info.circle")
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("SwiftData 调试")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    loadMessages()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .task {
            loadMessages()
        }
    }

    private func loadMessages() {
        isLoading = true
        errorMessage = nil

        do {
            let storageService = ChatStorageService(modelContext: modelContext)

            // 获取消息总数
            messageCount = try storageService.getMessageCount()

            // 获取所有消息
            let allMessages = try storageService.fetchAllMessages()
            messages = allMessages

            Log.i("✅ [Debug] 加载了 \(allMessages.count) 条消息", category: "Debug")
        } catch {
            errorMessage = error.localizedDescription
            Log.e("❌ [Debug] 加载失败: \(error)", category: "Debug")
        }

        isLoading = false
    }

    private func deleteAllMessages() {
        do {
            let storageService = ChatStorageService(modelContext: modelContext)
            try storageService.deleteAllMessages()
            loadMessages()
            Log.i("✅ [Debug] 已清空所有消息", category: "Debug")
        } catch {
            errorMessage = error.localizedDescription
            Log.e("❌ [Debug] 清空失败: \(error)", category: "Debug")
        }
    }

    private func exportDatabasePath() {
        // 打印数据库文件路径
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        if let appSupportPath = paths.first {
            Log.i("📂 [Debug] 应用支持目录: \(appSupportPath.path)", category: "Debug")

            // 列出所有文件
            do {
                let files = try FileManager.default.contentsOfDirectory(at: appSupportPath, includingPropertiesForKeys: nil)
                Log.i("📂 [Debug] 目录下的文件:", category: "Debug")
                for file in files {
                    let fileSize = try? FileManager.default.attributesOfItem(atPath: file.path)[.size] as? Int64
                    let sizeStr = fileSize.map { "\($0 / 1024) KB" } ?? "未知"
                    Log.i("  - \(file.lastPathComponent) (\(sizeStr))", category: "Debug")
                }
            } catch {
                Log.e("❌ [Debug] 无法列出文件: \(error)", category: "Debug")
            }
        }

        // 也打印Documents目录
        let docPaths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        if let docPath = docPaths.first {
            Log.i("📂 [Debug] Documents目录: \(docPath.path)", category: "Debug")
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationStack {
        ChatDebugView()
            .modelContainer(for: [LocalChatMessage.self], inMemory: true)
    }
}
