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
    private var lastDataId: String?  // 用于断线重连
    private var messageMap: [String: Int] = [:]  // msgId -> displayMessages index
    private var savedMessageIds: Set<String> = []  // 已保存到本地的消息ID

    init(chatService: ChatService) {
        self.chatService = chatService
    }

    func initialize(modelContext: ModelContext) async {
        guard !hasInitialized else { return }
        hasInitialized = true

        storageService = ChatStorageService(modelContext: modelContext)

        // 从本地加载历史消息
        await loadLocalHistory()

        // 检查是否需要从服务端同步消息
        await syncWithServer()

        // 检查是否需要恢复streaming
        await checkAndResumeIfNeeded()
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

    /// 从服务端同步消息
    private func syncWithServer() async {
        // 1. 首先检查是否有最新的conversation
        do {
            let conversations = try await chatService.getConversations(limit: 1, offset: nil)
            if let latestConversation = conversations.first {
                // 如果本地没有conversationId，使用最新的
                if conversationId == nil {
                    conversationId = latestConversation.id
                    print("📝 [PersistentChat] 使用最新的conversation: \(latestConversation.id)")
                }
                // 如果本地的conversationId与最新不同，更新为最新
                else if conversationId != latestConversation.id {
                    print("📝 [PersistentChat] 更新到最新的conversation: \(latestConversation.id)")
                    conversationId = latestConversation.id
                }
            }
        } catch {
            print("⚠️ [PersistentChat] 获取最新conversation失败: \(error)")
            // 不阻塞，继续执行
        }

        // 2. 如果有conversationId，同步消息
        guard let conversationId = conversationId else {
            print("📝 [PersistentChat] 没有conversationId，跳过同步")
            return
        }

        do {
            let serverMessages = try await chatService.getConversationHistory(id: conversationId)

            // 创建本地消息ID集合
            let localMessageIds = Set(displayMessages.map { $0.id })

            // 找出服务端有但本地没有的消息
            let missingMessages = serverMessages.filter { !localMessageIds.contains($0.id) }

            if !missingMessages.isEmpty {
                print("📥 [PersistentChat] 同步 \(missingMessages.count) 条缺失的消息")

                // 将缺失的消息添加到本地
                for message in missingMessages {
                    let chatMessage = ChatMessage(
                        id: message.id,
                        text: message.content,
                        isFromUser: message.role == .user,
                        timestamp: parseDate(message.createdAt),
                        isStreaming: false,
                        thinkingContent: message.thinkingContent,
                        toolCalls: message.toolCalls?.map { ToolCallInfo(
                            id: $0.toolCallId,
                            name: $0.toolCallName,
                            args: $0.toolCallArgs,
                            status: $0.toolCallStatus?.description,
                            result: $0.toolCallResult
                        )}
                    )

                    // 按时间顺序插入
                    if let insertIndex = displayMessages.firstIndex(where: {
                        $0.timestamp > chatMessage.timestamp
                    }) {
                        displayMessages.insert(chatMessage, at: insertIndex)
                    } else {
                        displayMessages.append(chatMessage)
                    }

                    // 保存到本地数据库
                    await saveMessageToLocal(
                        id: message.id,
                        content: message.content,
                        isFromUser: message.role == .user,
                        timestamp: chatMessage.timestamp
                    )
                }
            }
        } catch {
            print("⚠️ [PersistentChat] 同步消息失败: \(error)")
            // 不阻塞，继续执行
        }
    }

    /// 检查是否需要恢复streaming
    private func checkAndResumeIfNeeded() async {
        guard let conversationId = conversationId else { return }
        guard !displayMessages.isEmpty else { return }

        // 检查最后一条消息
        let lastMessage = displayMessages.last!

        // 情况1: 最后一条是用户消息，说明还没有收到assistant回复
        if lastMessage.isFromUser {
            print("⏸️ [PersistentChat] 最后一条是用户消息，尝试恢复...")
            await resumeConversation()
            return
        }

        // 情况2: 最后一条assistant消息可能未完成
        // 检查消息是否为空（可能被中断）
        if lastMessage.text.isEmpty && lastMessage.thinkingContent == nil {
            print("⚠️ [PersistentChat] 最后一条assistant消息为空，尝试恢复...")
            await resumeConversation()
            return
        }

        print("✅ [PersistentChat] 消息完整，无需恢复")
    }

    /// 恢复对话streaming
    private func resumeConversation() async {
        guard let conversationId = conversationId else { return }

        print("🔄 [PersistentChat] 恢复对话: \(conversationId)")
        isSending = true

        do {
            try await chatService.resumeConversation(
                conversationId: conversationId,
                lastDataId: lastDataId
            ) { [weak self] event in
                Task { @MainActor in
                    self?.handleStreamEvent(event)
                }
            }
        } catch {
            print("❌ [PersistentChat] 恢复失败: \(error)")
            // Resume失败不算严重错误
        }

        isSending = false
    }

    private func parseDate(_ dateString: String) -> Date {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: dateString) ?? Date()
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
<<<<<<< Updated upstream
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

=======
            print("📩 [PersistentChat] Received stream message")

            // 记录lastDataId用于断线重连
            lastDataId = streamMessage.id

            let data = streamMessage.data

            // 保存conversationId
            if let cid = data.conversationId {
                if conversationId == nil {
                    conversationId = cid
                    print("✅ 新对话ID: \(cid)")
                }
            }

            // 根据dataType分派处理
            switch data.dataType {
            case .agentStatus:
                handleAgentStatus(data.agentStatus)

            case .agentMessage:
                handleAgentMessage(data)

            case .agentToolCall:
                handleToolCall(data)
            }

        case .error(let message):
            print("❌ [PersistentChat] Stream error: \(message)")
            errorMessage = message
        }
    }

    /// 处理Agent状态
>>>>>>> Stashed changes
    private func handleAgentStatus(_ status: AgentStatus?) {
        guard let status = status else { return }

        switch status {
        case .generating:
<<<<<<< Updated upstream
            break
        case .finished, .stopped:
            finalizeStreamingMessages(shouldPersist: true)
            isSending = false
        case .error:
            markStreamingMessageAsError("Agent error")
=======
            print("🤖 Agent 生成中...")

        case .finished:
            print("✅ Agent 完成")
            // 将所有streaming消息设为non-streaming并保存
            for (index, message) in displayMessages.enumerated() {
                if message.isStreaming {
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

                    // 保存到本地
                    Task {
                        await saveMessageToLocal(
                            id: finalMessage.id,
                            content: finalMessage.text,
                            isFromUser: false,
                            timestamp: finalMessage.timestamp
                        )
                    }
                }
            }
            isSending = false

        case .error:
            print("❌ Agent 错误")
            isSending = false

        case .stopped:
            print("⏸️ Agent 停止")
>>>>>>> Stashed changes
            isSending = false
        }
    }

<<<<<<< Updated upstream
    private func handleAgentMessage(_ data: StreamMessageData) {
        let msgId = data.msgId

        let hasContent = data.content?.isEmpty == false
        let hasThinking = data.thinkingContent?.isEmpty == false
        let hasToolCalls = data.toolCalls?.isEmpty == false
=======
    /// 处理Agent消息
    private func handleAgentMessage(_ data: StreamMessageData) {
        let msgId = data.msgId

        print("💭 [PersistentChat] handleAgentMessage")
        print("  msgId: \(msgId)")
        print("  messageType: \(String(describing: data.messageType))")

        // 检查是否有内容
        let hasContent = data.content != nil && !data.content!.isEmpty
        let hasThinking = data.thinkingContent != nil && !data.thinkingContent!.isEmpty
        let hasToolCalls = data.toolCalls != nil && !data.toolCalls!.isEmpty
>>>>>>> Stashed changes

        guard hasContent || hasThinking || hasToolCalls else {
            return
        }

        let content = data.content ?? ""

<<<<<<< Updated upstream
        let toolCallInfos = data.toolCalls?.map { toolCall in
=======
        // 转换工具调用
        let toolCallInfos: [ToolCallInfo]? = data.toolCalls?.map { toolCall in
>>>>>>> Stashed changes
            ToolCallInfo(
                id: toolCall.toolCallId,
                name: toolCall.toolCallName,
                args: toolCall.toolCallArgs,
                status: toolCall.toolCallStatus?.description,
                result: toolCall.toolCallResult
            )
        }

<<<<<<< Updated upstream
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

=======
        // 查找或创建消息
        if let index = messageMap[msgId] {
            print("  → Updating existing message at index \(index)")
            let existingMessage = displayMessages[index]

            let message = ChatMessage(
                id: existingMessage.id,
                text: content,
                isFromUser: existingMessage.isFromUser,
                timestamp: existingMessage.timestamp,
                isStreaming: true,
                thinkingContent: data.thinkingContent,
                toolCalls: toolCallInfos
            )
            displayMessages[index] = message

        } else {
            print("  → Creating new message")

            // 新消息到来时，将之前所有消息设为非streaming
            for (idx, msg) in displayMessages.enumerated() {
                if msg.isStreaming {
                    displayMessages[idx] = ChatMessage(
                        id: msg.id,
                        text: msg.text,
                        isFromUser: msg.isFromUser,
                        timestamp: msg.timestamp,
                        isStreaming: false,
                        thinkingContent: msg.thinkingContent,
                        toolCalls: msg.toolCalls
                    )
                }
            }

            // 创建新消息
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
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
=======
>>>>>>> Stashed changes
        }
    }

    /// 处理工具调用
    private func handleToolCall(_ data: StreamMessageData) {
        print("🔧 [PersistentChat] handleToolCall")
        print("  msgId: \(data.msgId)")
        print("  toolCalls: \(data.toolCalls?.count ?? 0)")
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
