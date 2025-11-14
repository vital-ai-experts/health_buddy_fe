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
            },
            onLoadMoreHistory: {
                Task {
                    await viewModel.loadMoreMessages()
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
    @Published var isLoadingMore = false  // 正在加载更多消息

    private let chatService: ChatService
    private var storageService: ChatStorageService?
    private var hasInitialized = false
    private var lastDataId: String?  // 用于断线重连
    private var messageMap: [String: Int] = [:]  // msgId -> displayMessages index
    private var savedMessageIds: Set<String> = []  // 已保存到本地的消息ID
    private var loadedMessageCount = 0  // 已加载的消息数量
    private var totalMessageCount = 0  // 数据库中的总消息数量
    private var conversationUpdatedAt: Date?  // 对话的最后更新时间

    private let initialLoadLimit = 10  // 初次加载消息数量
    private let loadMoreLimit = 20  // 每次加载更多的消息数量
    private let conversationTimeoutHours: TimeInterval = 4 * 3600  // 4小时超时

    init(chatService: ChatService) {
        self.chatService = chatService
    }

    var hasMoreMessages: Bool {
        loadedMessageCount < totalMessageCount
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

    /// 从本地数据库加载历史消息（分页加载，初次只加载最近10条）
    private func loadLocalHistory() async {
        guard let storageService = storageService else { return }

        do {
            // 获取总消息数量
            totalMessageCount = try storageService.getMessageCount()

            // 只加载最近的10条消息
            let localMessages = try storageService.fetchRecentMessages(
                limit: initialLoadLimit,
                offset: 0
            )

            displayMessages = localMessages.map { localMsg in
                ChatMessage(
                    id: localMsg.id,
                    text: localMsg.content,
                    isFromUser: localMsg.isFromUser,
                    timestamp: localMsg.timestamp,
                    isStreaming: false
                )
            }

            loadedMessageCount = localMessages.count

            // 如果有消息，尝试恢复conversationId
            if let lastMsg = localMessages.last, let convId = lastMsg.conversationId {
                conversationId = convId
            }

            savedMessageIds = Set(localMessages.map { $0.id })
            rebuildMessageMap()

            print("✅ 加载了 \(localMessages.count) 条本地消息（共 \(totalMessageCount) 条）")
            if hasMoreMessages {
                print("📚 还有 \(totalMessageCount - loadedMessageCount) 条更早的消息")
            }
        } catch {
            print("❌ 加载本地消息失败: \(error.localizedDescription)")
            errorMessage = "加载历史消息失败"
        }
    }

    /// 加载更多历史消息（用户往上滑动时调用）
    func loadMoreMessages() async {
        guard !isLoadingMore else {
            print("⏳ 正在加载中，跳过重复请求")
            return
        }
        guard hasMoreMessages else {
            print("📭 没有更多消息了")
            return
        }
        guard let storageService = storageService else { return }

        isLoadingMore = true
        print("📥 开始加载更多消息，当前已加载: \(loadedMessageCount)")

        do {
            // 从当前已加载的位置继续加载
            let olderMessages = try storageService.fetchRecentMessages(
                limit: loadMoreLimit,
                offset: loadedMessageCount
            )

            if olderMessages.isEmpty {
                print("📭 没有更多消息了")
            } else {
                // 将更早的消息插入到列表前面
                let newChatMessages = olderMessages.map { localMsg in
                    ChatMessage(
                        id: localMsg.id,
                        text: localMsg.content,
                        isFromUser: localMsg.isFromUser,
                        timestamp: localMsg.timestamp,
                        isStreaming: false
                    )
                }

                displayMessages.insert(contentsOf: newChatMessages, at: 0)
                loadedMessageCount += olderMessages.count

                // 更新savedMessageIds
                savedMessageIds.formUnion(olderMessages.map { $0.id })

                // 重建messageMap（索引变了）
                rebuildMessageMap()

                print("✅ 加载了 \(olderMessages.count) 条更早的消息，总计: \(loadedMessageCount)/\(totalMessageCount)")
            }
        } catch {
            print("❌ 加载更多消息失败: \(error.localizedDescription)")
            errorMessage = "加载更多消息失败"
        }

        isLoadingMore = false
    }

    /// 从服务端同步消息
    private func syncWithServer() async {
        // 1. 首先检查是否有最新的conversation
        do {
            let conversations = try await chatService.getConversations(limit: 1, offset: nil)
            guard let latestConversation = conversations.first else {
                print("📝 [PersistentChat] 服务端没有对话记录")
                return
            }

            let serverUpdatedAt = parseDate(latestConversation.updatedAt)

            // 如果本地没有conversationId，直接使用服务端最新的
            if conversationId == nil {
                conversationId = latestConversation.id
                conversationUpdatedAt = serverUpdatedAt
                print("📝 [PersistentChat] 使用最新的conversation: \(latestConversation.id), 更新时间: \(latestConversation.updatedAt)")
            }
            // 如果本地有conversationId，比较更新时间
            else if let localUpdatedAt = conversationUpdatedAt {
                // 比较本地和服务端的更新时间，选择更新的那个
                if serverUpdatedAt > localUpdatedAt {
                    print("📝 [PersistentChat] 服务端对话更新 (\(latestConversation.updatedAt))，切换到最新对话: \(latestConversation.id)")
                    conversationId = latestConversation.id
                    conversationUpdatedAt = serverUpdatedAt
                } else {
                    print("📝 [PersistentChat] 保持本地对话: \(conversationId!), 本地更新时间更近")
                }
            }
            // 本地有conversationId但没有时间戳，比较ID后使用服务端时间
            else if conversationId != latestConversation.id {
                print("📝 [PersistentChat] 本地对话ID与服务端不同，切换到最新对话: \(latestConversation.id)")
                conversationId = latestConversation.id
                conversationUpdatedAt = serverUpdatedAt
            } else {
                // ID相同，更新时间戳
                conversationUpdatedAt = serverUpdatedAt
                print("📝 [PersistentChat] 更新对话时间戳: \(latestConversation.updatedAt)")
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

                // 更新计数器
                loadedMessageCount += missingMessages.count
                if let storageService = storageService {
                    totalMessageCount = (try? storageService.getMessageCount()) ?? totalMessageCount
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

        // 1. 检查对话是否超时（超过4小时）
        var effectiveConversationId = conversationId
        if let conversationId = conversationId, let updatedAt = conversationUpdatedAt {
            let timeSinceLastUpdate = Date().timeIntervalSince(updatedAt)
            if timeSinceLastUpdate > conversationTimeoutHours {
                print("⏰ [PersistentChat] 对话超时 (\(Int(timeSinceLastUpdate/3600))小时)，开始新对话")
                effectiveConversationId = nil
                self.conversationId = nil
                self.conversationUpdatedAt = nil
            } else {
                print("✅ [PersistentChat] 使用现有对话: \(conversationId), 距上次更新: \(Int(timeSinceLastUpdate/60))分钟")
            }
        }

        // 2. 创建用户消息
        let userMessageId = UUID().uuidString
        let userMessage = ChatMessage(
            id: userMessageId,
            text: text,
            isFromUser: true,
            timestamp: Date(),
            isStreaming: false
        )
        displayMessages.append(userMessage)

        // 3. 保存用户消息到本地
        await saveMessageToLocal(
            id: userMessageId,
            content: text,
            isFromUser: true,
            timestamp: userMessage.timestamp
        )

        // 4. 发送到服务器
        isSending = true
        errorMessage = nil

        do {
            try await chatService.sendMessage(
                userInput: text,
                conversationId: effectiveConversationId
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
            print("📩 [PersistentChat] Received stream message")

            // 记录lastDataId用于断线重连
            lastDataId = streamMessage.id

            let data = streamMessage.data

            // 保存conversationId并更新时间戳
            if let cid = data.conversationId {
                if conversationId == nil || conversationId != cid {
                    conversationId = cid
                    conversationUpdatedAt = Date()
                    print("✅ 对话ID: \(cid), 更新时间: \(Date())")
                } else {
                    // 即使是同一个对话，也更新时间戳
                    conversationUpdatedAt = Date()
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
            isSending = false
        }
    }

    /// 处理Agent状态
    private func handleAgentStatus(_ status: AgentStatus?) {
        guard let status = status else { return }

        switch status {
        case .generating:
            print("🤖 Agent 生成中...")

        case .finished:
            print("✅ Agent 完成")
            finalizeStreamingMessages(shouldPersist: true)
            isSending = false

        case .error:
            print("❌ Agent 错误")
            markStreamingMessageAsError("Agent error")
            isSending = false

        case .stopped:
            print("⏸️ Agent 停止")
            finalizeStreamingMessages(shouldPersist: true)
            isSending = false
        }
    }

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

        guard hasContent || hasThinking || hasToolCalls else {
            return
        }

        let content = data.content ?? ""

        // 转换工具调用
        let toolCallInfos: [ToolCallInfo]? = data.toolCalls?.map { toolCall in
            ToolCallInfo(
                id: toolCall.toolCallId,
                name: toolCall.toolCallName,
                args: toolCall.toolCallArgs,
                status: toolCall.toolCallStatus?.description,
                result: toolCall.toolCallResult
            )
        }

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
                thinkingContent: data.thinkingContent ?? existingMessage.thinkingContent,
                toolCalls: toolCallInfos ?? existingMessage.toolCalls
            )
            displayMessages[index] = message

        } else {
            print("  → Creating new message")

            // 新消息到来时，将之前所有消息设为非streaming并保存
            finalizeStreamingMessages(shouldPersist: true)

            // 创建新消息
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

    /// 处理工具调用
    private func handleToolCall(_ data: StreamMessageData) {
        print("🔧 [PersistentChat] handleToolCall")
        print("  msgId: \(data.msgId)")
        print("  toolCalls: \(data.toolCalls?.count ?? 0)")
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
            conversationUpdatedAt = nil
            messageMap.removeAll()
            savedMessageIds.removeAll()
            loadedMessageCount = 0
            totalMessageCount = 0
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
