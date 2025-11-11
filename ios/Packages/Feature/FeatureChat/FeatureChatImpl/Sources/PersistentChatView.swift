import SwiftUI
import SwiftData
import DomainChat
import LibraryServiceLoader
import LibraryChatUI

/// 单一长期对话视图，对话历史保存在本地
struct PersistentChatView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: PersistentChatViewModel

    init() {
        let chatService = ServiceManager.shared.resolve(ChatService.self)
        _viewModel = StateObject(wrappedValue: PersistentChatViewModel(
            chatService: chatService
        ))
    }

    var body: some View {
        SimpleChatView(
            messages: $viewModel.displayMessages,
            inputText: $viewModel.inputText,
            isLoading: viewModel.isSending,
            onSendMessage: { text in
                Task {
                    await viewModel.sendMessage(text)
                }
            }
        )
        .navigationTitle("AI助手")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(role: .destructive) {
                        viewModel.showClearHistoryAlert = true
                    } label: {
                        Label("清除历史记录", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("清除历史记录", isPresented: $viewModel.showClearHistoryAlert) {
            Button("取消", role: .cancel) {}
            Button("清除", role: .destructive) {
                Task {
                    await viewModel.clearHistory()
                }
            }
        } message: {
            Text("确定要清除所有对话历史吗？此操作不可撤销。")
        }
        .task {
            await viewModel.initialize(modelContext: modelContext)
        }
    }
}

@MainActor
final class PersistentChatViewModel: ObservableObject {
    @Published var displayMessages: [ChatMessage] = []
    @Published var streamingContent = ""
    @Published var isSending = false
    @Published var errorMessage: String?
    @Published var conversationId: String? // 长期持有的对话ID
    @Published var inputText = ""
    @Published var showClearHistoryAlert = false

    private let chatService: ChatService
    private var storageService: ChatStorageService?
    private var hasInitialized = false

    init(chatService: ChatService) {
        self.chatService = chatService
    }

    func initialize(modelContext: ModelContext) async {
        guard !hasInitialized else { return }
        hasInitialized = true

        storageService = ChatStorageService(modelContext: modelContext)

        // 从本地加载历史消息
        await loadLocalHistory()
    }

    /// 从本地数据库加载历史消息
    private func loadLocalHistory() async {
        guard let storageService = storageService else { return }

        do {
            let localMessages = try storageService.fetchAllMessages()
            displayMessages = localMessages.map { localMsg in
                ChatMessage(
                    id: localMsg.id,
                    text: localMsg.content,
                    isFromUser: localMsg.isFromUser,
                    timestamp: localMsg.timestamp,
                    isStreaming: false
                )
            }

            // 如果有消息，尝试恢复conversationId
            if let lastMsg = localMessages.last, let convId = lastMsg.conversationId {
                conversationId = convId
            }

            print("✅ 加载了 \(localMessages.count) 条本地消息")
        } catch {
            print("❌ 加载本地消息失败: \(error.localizedDescription)")
            errorMessage = "加载历史消息失败"
        }
    }

    /// 发送消息
    func sendMessage(_ text: String) async {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        // 1. 创建用户消息
        let userMessageId = UUID().uuidString
        let userMessage = ChatMessage(
            id: userMessageId,
            text: text,
            isFromUser: true,
            timestamp: Date(),
            isStreaming: false
        )
        displayMessages.append(userMessage)

        // 2. 保存用户消息到本地
        await saveMessageToLocal(
            id: userMessageId,
            content: text,
            isFromUser: true,
            timestamp: userMessage.timestamp
        )

        // 3. 发送到服务器
        isSending = true
        errorMessage = nil
        streamingContent = ""

        do {
            try await chatService.sendMessage(
                message: text,
                conversationId: conversationId
            ) { [weak self] event in
                Task { @MainActor in
                    self?.handleStreamEvent(event)
                }
            }
        } catch {
            errorMessage = "发送消息失败: \(error.localizedDescription)"
        }

        isSending = false
    }

    /// 处理流式响应事件
    private func handleStreamEvent(_ event: ChatStreamEvent) {
        switch event {
        case .conversationStart(let id):
            // 保存conversationId用于后续消息
            if conversationId == nil {
                conversationId = id
                print("✅ 新对话ID: \(id)")
            }

        case .messageStart(let messageId):
            streamingContent = ""
            // 添加流式消息占位符
            let streamingMsg = ChatMessage(
                id: messageId,
                text: "",
                isFromUser: false,
                timestamp: Date(),
                isStreaming: true
            )
            displayMessages.append(streamingMsg)

        case .contentDelta(let content):
            streamingContent += content

            // 如果没有流式消息，创建一个
            if !displayMessages.contains(where: { $0.isStreaming }) {
                let streamingMsg = ChatMessage(
                    id: UUID().uuidString,
                    text: content,
                    isFromUser: false,
                    timestamp: Date(),
                    isStreaming: true
                )
                displayMessages.append(streamingMsg)
            } else {
                // 更新流式消息
                if let index = displayMessages.firstIndex(where: { $0.isStreaming }) {
                    displayMessages[index] = ChatMessage(
                        id: displayMessages[index].id,
                        text: streamingContent,
                        isFromUser: false,
                        timestamp: displayMessages[index].timestamp,
                        isStreaming: true
                    )
                }
            }

        case .messageEnd:
            // 完成流式消息，保存到本地
            if let index = displayMessages.firstIndex(where: { $0.isStreaming }) {
                let finalMessage = ChatMessage(
                    id: displayMessages[index].id,
                    text: streamingContent,
                    isFromUser: false,
                    timestamp: displayMessages[index].timestamp,
                    isStreaming: false
                )
                displayMessages[index] = finalMessage

                // 保存AI消息到本地
                Task {
                    await saveMessageToLocal(
                        id: finalMessage.id,
                        content: finalMessage.text,
                        isFromUser: false,
                        timestamp: finalMessage.timestamp
                    )
                }

                streamingContent = ""
            }

        case .conversationEnd:
            break

        case .error(let error):
            errorMessage = error

        case .ignored:
            break
        }
    }

    /// 保存消息到本地数据库
    private func saveMessageToLocal(
        id: String,
        content: String,
        isFromUser: Bool,
        timestamp: Date
    ) async {
        guard let storageService = storageService else { return }

        let localMessage = LocalChatMessage(
            id: id,
            content: content,
            isFromUser: isFromUser,
            timestamp: timestamp,
            conversationId: conversationId
        )

        do {
            try storageService.saveMessage(localMessage)
            print("✅ 消息已保存到本地: \(content.prefix(20))...")
        } catch {
            print("❌ 保存消息失败: \(error.localizedDescription)")
        }
    }

    /// 清除所有历史记录
    func clearHistory() async {
        guard let storageService = storageService else { return }

        do {
            try storageService.deleteAllMessages()
            displayMessages.removeAll()
            conversationId = nil
            print("✅ 历史记录已清除")
        } catch {
            print("❌ 清除历史记录失败: \(error.localizedDescription)")
            errorMessage = "清除历史记录失败"
        }
    }
}

#Preview {
    PersistentChatView()
        .modelContainer(for: [LocalChatMessage.self], inMemory: true)
}
