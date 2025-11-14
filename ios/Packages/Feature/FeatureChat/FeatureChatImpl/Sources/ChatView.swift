import SwiftUI
import DomainChat
import LibraryServiceLoader
import LibraryChatUI

struct ChatView: View {
    @StateObject private var viewModel: ChatViewModel

    init(conversationId: String? = nil) {
        let chatService = ServiceManager.shared.resolve(ChatService.self)
        _viewModel = StateObject(wrappedValue: ChatViewModel(
            chatService: chatService,
            conversationId: conversationId
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
            onRetry: { messageId in
                Task {
                    await viewModel.retryMessage(messageId)
                }
            }
        )
        .navigationTitle(viewModel.conversationId == nil ? "New Chat" : "Chat")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                await viewModel.initializeConversation()
            }
        }
    }
}

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var displayMessages: [ChatMessage] = []
    @Published var isSending = false
    @Published var errorMessage: String?
    @Published var conversationId: String?
    @Published var inputText = ""

    private let chatService: ChatService
    private var lastUserMessage: String?  // 保存最后发送的消息用于重试
    private var lastDataId: String?  // 用于断线重连
    private var messageMap: [String: Int] = [:]  // msgId -> displayMessages index

    init(chatService: ChatService, conversationId: String? = nil) {
        self.chatService = chatService
        self.conversationId = conversationId
    }

    /// 初始化对话（在onAppear时调用）
    func initializeConversation() async {
        // 如果已经有conversationId，加载对话
        if conversationId != nil {
            await loadConversation()
            return
        }

        // 如果没有conversationId，尝试获取最新的conversation
        do {
            let conversations = try await chatService.getConversations(limit: 1, offset: nil)
            if let latestConversation = conversations.first {
                print("📝 [ChatViewModel] No conversation ID provided, using latest: \(latestConversation.id)")
                conversationId = latestConversation.id
                await loadConversation()
            } else {
                print("📝 [ChatViewModel] No existing conversations, starting fresh")
                // 没有conversation，保持nil（新对话）
            }
        } catch {
            print("⚠️ [ChatViewModel] Failed to get latest conversation: \(error)")
            // 失败也不影响，保持nil（新对话）
        }
    }

    func loadConversation() async {
        guard let conversationId = conversationId else { return }

        do {
            // 1. 检查是否是最新的conversation
            await checkAndUpdateToLatestConversation()

            // 2. 加载历史消息并同步
            try await syncConversationMessages()

            // 3. 检查是否需要恢复streaming
            await checkAndResumeIfNeeded()

        } catch {
            errorMessage = "Failed to load conversation: \(error.localizedDescription)"
        }
    }

    /// 检查并更新到最新的conversation
    private func checkAndUpdateToLatestConversation() async {
        do {
            let conversations = try await chatService.getConversations(limit: 1, offset: nil)

            // 如果有conversation且与当前不同，更新为最新的
            if let latestConversation = conversations.first {
                if latestConversation.id != conversationId {
                    print("📝 [ChatViewModel] Updating to latest conversation: \(latestConversation.id)")
                    conversationId = latestConversation.id
                }
            }
        } catch {
            print("⚠️ [ChatViewModel] Failed to check latest conversation: \(error)")
            // 不阻塞加载流程，继续使用当前conversationId
        }
    }

    /// 同步conversation消息
    private func syncConversationMessages() async throws {
        guard let conversationId = conversationId else { return }

        let serverMessages = try await chatService.getConversationHistory(id: conversationId)

        // 创建本地消息ID集合
        let localMessageIds = Set(displayMessages.map { $0.id })

        // 找出服务端有但本地没有的消息
        let missingMessages = serverMessages.filter { !localMessageIds.contains($0.id) }

        if !missingMessages.isEmpty {
            print("📥 [ChatViewModel] Syncing \(missingMessages.count) missing messages")
        }

        // 如果本地为空，直接加载所有消息
        if displayMessages.isEmpty {
            displayMessages = []
            messageMap = [:]

            for message in serverMessages {
                let chatMessage = convertToChatMessage(message)
                displayMessages.append(chatMessage)

                // 非用户消息添加到messageMap
                if message.role != .user {
                    messageMap[message.id] = displayMessages.count - 1
                }
            }
        } else {
            // 同步缺失的消息
            for message in missingMessages {
                let chatMessage = convertToChatMessage(message)

                // 按时间顺序插入
                if let insertIndex = displayMessages.firstIndex(where: {
                    $0.timestamp > chatMessage.timestamp
                }) {
                    displayMessages.insert(chatMessage, at: insertIndex)
                    // 更新messageMap
                    rebuildMessageMap()
                } else {
                    displayMessages.append(chatMessage)
                    if message.role != .user {
                        messageMap[message.id] = displayMessages.count - 1
                    }
                }
            }
        }
    }

    /// 检查是否需要恢复streaming状态
    private func checkAndResumeIfNeeded() async {
        guard let conversationId = conversationId else { return }
        guard !displayMessages.isEmpty else { return }

        // 检查最后一条消息
        let lastMessage = displayMessages.last!

        // 情况1: 最后一条是用户消息，说明还没有收到assistant回复
        // 这种情况肯定需要resume
        if lastMessage.isFromUser {
            print("⏸️ [ChatViewModel] Last message is from user, resuming to get assistant response...")
            await tryResumeConversation()
            return
        }

        // 情况2: 最后一条是assistant消息
        // 我们无法从历史消息中准确判断消息是否完整
        // 但可以检查一些指标：

        // 2.1 检查消息是否为空（可能被中断）
        if lastMessage.text.isEmpty && lastMessage.thinkingContent == nil {
            print("⚠️ [ChatViewModel] Last assistant message is empty, resuming...")
            await tryResumeConversation()
            return
        }

        // 2.2 如果有本地保存的lastDataId，说明之前有streaming session
        if lastDataId != nil {
            print("🔄 [ChatViewModel] Found lastDataId from previous session, resuming...")
            await tryResumeConversation()
            return
        }

        // 2.3 检查是否有streaming标记（虽然从历史加载的消息都是false，但以防万一）
        if lastMessage.isStreaming {
            print("🔄 [ChatViewModel] Last message has streaming flag, resuming...")
            await tryResumeConversation()
            return
        }

        print("✅ [ChatViewModel] Last message appears complete, no need to resume")
    }

    /// 尝试恢复对话streaming
    private func tryResumeConversation() async {
        print("🔄 [ChatViewModel] Attempting to resume conversation")
        await resumeConversation()
    }

    /// 转换Message为ChatMessage
    private func convertToChatMessage(_ message: Message) -> ChatMessage {
        return ChatMessage(
            id: message.id,
            text: message.content,
            isFromUser: message.role == .user,
            timestamp: parseDate(message.createdAt),
            isStreaming: false,  // 历史消息都是完成状态
            thinkingContent: message.thinkingContent,
            toolCalls: message.toolCalls?.map { ToolCallInfo(
                id: $0.toolCallId,
                name: $0.toolCallName,
                args: $0.toolCallArgs,
                status: $0.toolCallStatus?.description,
                result: $0.toolCallResult
            )}
        )
    }

    /// 重建messageMap
    private func rebuildMessageMap() {
        messageMap = [:]
        for (index, message) in displayMessages.enumerated() {
            if !message.isFromUser {
                messageMap[message.id] = index
            }
        }
    }

    func sendMessage(_ text: String) async {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        // 保存用户消息用于重试
        lastUserMessage = text

        // Add user message
        let userMessage = ChatMessage(
            id: UUID().uuidString,
            text: text,
            isFromUser: true,
            timestamp: Date(),
            isStreaming: false
        )
        displayMessages.append(userMessage)

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
            // 处理错误：标记当前流式消息为失败
            handleError(error: error)
        }

        isSending = false
    }

    func retryMessage(_ failedMessageId: String) async {
        // 移除错误消息
        displayMessages.removeAll { message in
            message.id == failedMessageId || message.hasError
        }

        // 重新发送最后的用户消息
        if let lastMessage = lastUserMessage {
            await sendMessage(lastMessage)
        }
    }

    func resumeConversation() async {
        guard let conversationId = conversationId else { return }

        isSending = true
        errorMessage = nil

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
            handleError(error: error)
        }

        isSending = false
    }

    // MARK: - Private Methods

    private func handleError(error: Error) {
        errorMessage = "Failed to send message: \(error.localizedDescription)"

        // 如果有流式消息正在进行，标记为失败
        if let index = displayMessages.firstIndex(where: { $0.isStreaming }) {
            let failedMessage = displayMessages[index]
            displayMessages[index] = ChatMessage(
                id: failedMessage.id,
                text: failedMessage.text,
                isFromUser: false,
                timestamp: failedMessage.timestamp,
                isStreaming: false,
                hasError: true,
                errorMessage: error.localizedDescription
            )
        } else {
            // 如果没有流式消息，创建一个新的错误消息
            let errorMsg = ChatMessage(
                id: UUID().uuidString,
                text: "",
                isFromUser: false,
                timestamp: Date(),
                isStreaming: false,
                hasError: true,
                errorMessage: error.localizedDescription
            )
            displayMessages.append(errorMsg)
        }
    }

    /// 处理流事件（参考OnboardingViewModel的实现）
    private func handleStreamEvent(_ event: ConversationStreamEvent) {
        switch event {
        case .streamMessage(let streamMessage):
            print("📩 [ChatViewModel] Received stream message")

            // 1. 记录最新data id（用于断线重连）
            lastDataId = streamMessage.id

            let data = streamMessage.data

            // 2. 保存conversationId
            if let cid = data.conversationId {
                conversationId = cid
            }

            // 3. 根据dataType分派处理
            switch data.dataType {
            case .agentStatus:
                handleAgentStatus(data.agentStatus)

            case .agentMessage:
                handleAgentMessage(data)

            case .agentToolCall:
                handleToolCall(data)
            }

        case .error(let message):
            print("❌ [ChatViewModel] Stream error: \(message)")
            isSending = false
            errorMessage = message
        }
    }

    /// Agent状态处理
    private func handleAgentStatus(_ status: AgentStatus?) {
        guard let status = status else { return }

        switch status {
        case .generating:
            print("🤖 Agent 生成中...")

        case .finished:
            print("✅ Agent 完成")
            // 将所有streaming消息设为non-streaming
            for (index, message) in displayMessages.enumerated() {
                if message.isStreaming {
                    displayMessages[index] = ChatMessage(
                        id: message.id,
                        text: message.text,
                        isFromUser: message.isFromUser,
                        timestamp: message.timestamp,
                        isStreaming: false,
                        thinkingContent: message.thinkingContent,
                        toolCalls: message.toolCalls
                    )
                }
            }
            isSending = false

        case .error:
            print("❌ Agent 错误")
            // 标记消息为失败
            if let index = displayMessages.firstIndex(where: { $0.isStreaming }) {
                let failedMessage = displayMessages[index]
                displayMessages[index] = ChatMessage(
                    id: failedMessage.id,
                    text: failedMessage.text,
                    isFromUser: false,
                    timestamp: failedMessage.timestamp,
                    isStreaming: false,
                    hasError: true,
                    errorMessage: "Agent error"
                )
            }
            isSending = false

        case .stopped:
            print("⏸️ Agent 停止")
            // 停止时也将所有消息设为非streaming
            for (index, message) in displayMessages.enumerated() {
                if message.isStreaming {
                    displayMessages[index] = ChatMessage(
                        id: message.id,
                        text: message.text,
                        isFromUser: message.isFromUser,
                        timestamp: message.timestamp,
                        isStreaming: false,
                        thinkingContent: message.thinkingContent,
                        toolCalls: message.toolCalls
                    )
                }
            }
            isSending = false
        }
    }

    /// Agent消息处理（核心逻辑，参考OnboardingViewModel）
    private func handleAgentMessage(_ data: StreamMessageData) {
        let msgId = data.msgId

        print("💭 [ChatViewModel] handleAgentMessage")
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
            // 更新现有消息
            let existingMessage = displayMessages[index]

            let message = ChatMessage(
                id: existingMessage.id,
                text: content,
                isFromUser: existingMessage.isFromUser,
                timestamp: existingMessage.timestamp,
                isStreaming: true,  // 保持streaming状态直到Agent.finished
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
            let newMessage = ChatMessage(
                id: msgId,
                text: content,
                isFromUser: false,
                timestamp: Date(),
                isStreaming: true,  // 新消息以streaming状态创建
                thinkingContent: data.thinkingContent,
                toolCalls: toolCallInfos
            )
            displayMessages.append(newMessage)
            messageMap[msgId] = displayMessages.count - 1
        }
    }

    /// 工具调用处理
    private func handleToolCall(_ data: StreamMessageData) {
        print("🔧 [ChatViewModel] handleToolCall")
        print("  msgId: \(data.msgId)")
        print("  toolCalls: \(data.toolCalls?.count ?? 0)")

        // 对话中的工具调用可能需要特殊处理
        // 目前暂时不做额外处理，工具调用信息会在handleAgentMessage中显示
    }

    private func parseDate(_ dateString: String) -> Date {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: dateString) ?? Date()
    }
}
