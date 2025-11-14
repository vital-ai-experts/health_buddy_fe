import SwiftUI
import DomainChat
import DomainOnboarding  // 导入StreamMessage等共享模型
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
            if let conversationId = viewModel.conversationId {
                Task {
                    await viewModel.loadConversation()
                }
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

    func loadConversation() async {
        guard let conversationId = conversationId else { return }

        do {
            let messages = try await chatService.getConversationHistory(id: conversationId)

            // 清空现有消息和映射
            displayMessages = []
            messageMap = [:]

            // 转换历史消息为ChatMessage
            for message in messages {
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
                displayMessages.append(chatMessage)

                // 非用户消息添加到messageMap
                if message.role != .user {
                    messageMap[message.id] = displayMessages.count - 1
                }
            }
        } catch {
            errorMessage = "Failed to load conversation: \(error.localizedDescription)"
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
