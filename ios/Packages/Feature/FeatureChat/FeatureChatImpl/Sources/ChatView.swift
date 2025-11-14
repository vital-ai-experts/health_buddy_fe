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
    @Published var streamingContent = ""
    @Published var isSending = false
    @Published var errorMessage: String?
    @Published var conversationId: String?
    @Published var inputText = ""

    private let chatService: ChatService
    private var lastUserMessage: String?  // 保存最后发送的消息用于重试

    init(chatService: ChatService, conversationId: String? = nil) {
        self.chatService = chatService
        self.conversationId = conversationId
    }

    func loadConversation() async {
        guard let conversationId = conversationId else { return }

        do {
            let (_, messages) = try await chatService.getConversation(id: conversationId)
            self.displayMessages = messages.map { msg in
                ChatMessage(
                    id: msg.id,
                    text: msg.content,
                    isFromUser: msg.role == .user,
                    timestamp: parseDate(msg.createdAt),
                    isStreaming: false
                )
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

    private func handleStreamEvent(_ event: ChatStreamEvent) {
        switch event {
        case .conversationStart(let id):
            if conversationId == nil {
                conversationId = id
            }

        case .messageStart(let messageId):
            streamingContent = ""
            // Add streaming message placeholder
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

            // 如果还没有流式消息，先创建一个（处理服务端没有发送 messageStart 的情况）
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
                // Update the streaming message
                if let index = displayMessages.firstIndex(where: { $0.isStreaming }) {
                    displayMessages[index] = ChatMessage(
                        id: displayMessages[index].id,
                        text: streamingContent,
                        isFromUser: false,
                        timestamp: Date(),
                        isStreaming: true
                    )
                }
            }

        case .messageEnd:
            // Replace streaming message with final message
            if let index = displayMessages.firstIndex(where: { $0.isStreaming }) {
                displayMessages[index] = ChatMessage(
                    id: displayMessages[index].id,
                    text: streamingContent,
                    isFromUser: false,
                    timestamp: Date(),
                    isStreaming: false
                )
                streamingContent = ""
            }

        case .conversationEnd:
            break

        case .error(let errorMsg):
            errorMessage = errorMsg
            // 标记当前消息为失败
            if let index = displayMessages.firstIndex(where: { $0.isStreaming }) {
                let failedMessage = displayMessages[index]
                displayMessages[index] = ChatMessage(
                    id: failedMessage.id,
                    text: streamingContent.isEmpty ? "" : streamingContent,
                    isFromUser: false,
                    timestamp: failedMessage.timestamp,
                    isStreaming: false,
                    hasError: true,
                    errorMessage: errorMsg
                )
            } else {
                // 如果没有流式消息，创建一个新的错误消息
                let errorMessage = ChatMessage(
                    id: UUID().uuidString,
                    text: "",
                    isFromUser: false,
                    timestamp: Date(),
                    isStreaming: false,
                    hasError: true,
                    errorMessage: errorMsg
                )
                displayMessages.append(errorMessage)
            }
            streamingContent = ""

        case .ignored:
            break // Silently ignore unknown SSE events
        }
    }

    private func parseDate(_ dateString: String) -> Date {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: dateString) ?? Date()
    }
}
