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
    @Published var isSending = false
    @Published var errorMessage: String?
    @Published var conversationId: String? // 长期持有的对话ID
    @Published var inputText = ""
    @Published var showClearHistoryAlert = false

    private let chatService: ChatService
    private var storageService: ChatStorageService?
    private var hasInitialized = false
    private var messageMap: [String: Int] = [:]
    private var savedMessageIds: Set<String> = []

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

            savedMessageIds = Set(localMessages.map { $0.id })
            rebuildMessageMap()

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

        do {
            try await chatService.sendMessage(
                userInput: text,
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
    private func handleStreamEvent(_ event: ConversationStreamEvent) {
        switch event {
        case .streamMessage(let streamMessage):
            handleStreamMessage(streamMessage)

        case .error(let message):
            print("❌ 流式错误: \(message)")
            errorMessage = message
            isSending = false
        }
    }

    private func handleStreamMessage(_ streamMessage: StreamMessage) {
        let data = streamMessage.data

        if let cid = data.conversationId, conversationId != cid {
            conversationId = cid
        }

        switch data.dataType {
        case .agentStatus:
            handleAgentStatus(data.agentStatus)

        case .agentMessage:
            handleAgentMessage(data)

        case .agentToolCall:
            handleToolCall(data)
        }
    }

    private func handleAgentStatus(_ status: AgentStatus?) {
        guard let status = status else { return }

        switch status {
        case .generating:
            break
        case .finished, .stopped:
            finalizeStreamingMessages(shouldPersist: true)
            isSending = false
        case .error:
            markStreamingMessageAsError("Agent error")
            isSending = false
        }
    }

    private func handleAgentMessage(_ data: StreamMessageData) {
        let msgId = data.msgId

        let hasContent = data.content?.isEmpty == false
        let hasThinking = data.thinkingContent?.isEmpty == false
        let hasToolCalls = data.toolCalls?.isEmpty == false

        guard hasContent || hasThinking || hasToolCalls else {
            return
        }

        let content = data.content ?? ""

        let toolCallInfos = data.toolCalls?.map { toolCall in
            ToolCallInfo(
                id: toolCall.toolCallId,
                name: toolCall.toolCallName,
                args: toolCall.toolCallArgs,
                status: toolCall.toolCallStatus?.description,
                result: toolCall.toolCallResult
            )
        }

        if let index = messageMap[msgId] {
            let existingMessage = displayMessages[index]
            displayMessages[index] = ChatMessage(
                id: existingMessage.id,
                text: content,
                isFromUser: false,
                timestamp: existingMessage.timestamp,
                isStreaming: true,
                thinkingContent: data.thinkingContent ?? existingMessage.thinkingContent,
                toolCalls: toolCallInfos ?? existingMessage.toolCalls
            )
        } else {
            finalizeStreamingMessages(shouldPersist: true)

            let newMessage = ChatMessage(
                id: msgId,
                text: content,
                isFromUser: false,
                timestamp: Date(),
                isStreaming: true,
                thinkingContent: data.thinkingContent,
                toolCalls: toolCallInfos
            )
            displayMessages.append(newMessage)
            messageMap[msgId] = displayMessages.count - 1
        }
    }

    private func handleToolCall(_ data: StreamMessageData) {
        print("🔧 收到工具调用事件: \(data.toolCalls?.count ?? 0) 个调用")
    }

    private func finalizeStreamingMessages(shouldPersist: Bool) {
        for index in displayMessages.indices {
            guard displayMessages[index].isStreaming else { continue }

            let message = displayMessages[index]
            let finalMessage = ChatMessage(
                id: message.id,
                text: message.text,
                isFromUser: message.isFromUser,
                timestamp: message.timestamp,
                isStreaming: false,
                thinkingContent: message.thinkingContent,
                toolCalls: message.toolCalls
            )
            displayMessages[index] = finalMessage

            if shouldPersist {
                persistAssistantMessageIfNeeded(finalMessage)
            }
        }
    }

    private func markStreamingMessageAsError(_ message: String) {
        if let index = displayMessages.firstIndex(where: { $0.isStreaming }) {
            let failedMessage = displayMessages[index]
            displayMessages[index] = ChatMessage(
                id: failedMessage.id,
                text: failedMessage.text,
                isFromUser: false,
                timestamp: failedMessage.timestamp,
                isStreaming: false,
                hasError: true,
                errorMessage: message
            )
        }
    }

    private func persistAssistantMessageIfNeeded(_ message: ChatMessage) {
        guard !message.isFromUser else { return }
        guard !savedMessageIds.contains(message.id) else { return }
        savedMessageIds.insert(message.id)

        Task { @MainActor [weak self] in
            guard let self = self else { return }
            await self.saveMessageToLocal(
                id: message.id,
                content: message.text,
                isFromUser: false,
                timestamp: message.timestamp,
                conversationId: self.conversationId
            )
        }
    }

    /// 保存消息到本地数据库
    private func saveMessageToLocal(
        id: String,
        content: String,
        isFromUser: Bool,
        timestamp: Date,
        conversationId: String? = nil
    ) async {
        guard let storageService = storageService else { return }

        let localMessage = LocalChatMessage(
            id: id,
            content: content,
            isFromUser: isFromUser,
            timestamp: timestamp,
            conversationId: conversationId ?? self.conversationId
        )

        do {
            try storageService.saveMessage(localMessage)
            savedMessageIds.insert(id)
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
            messageMap.removeAll()
            savedMessageIds.removeAll()
            print("✅ 历史记录已清除")
        } catch {
            print("❌ 清除历史记录失败: \(error.localizedDescription)")
            errorMessage = "清除历史记录失败"
        }
    }

    private func rebuildMessageMap() {
        messageMap = [:]
        for (index, message) in displayMessages.enumerated() where !message.isFromUser {
            messageMap[message.id] = index
        }
    }
}

#Preview {
    PersistentChatView()
        .modelContainer(for: [LocalChatMessage.self], inMemory: true)
}
