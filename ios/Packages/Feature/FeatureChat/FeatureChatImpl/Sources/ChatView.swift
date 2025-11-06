import SwiftUI
import DomainChat
import LibraryServiceLoader

struct ChatView: View {
    @StateObject private var viewModel: ChatViewModel
    @State private var messageText = ""
    @FocusState private var isTextFieldFocused: Bool

    init(conversationId: String? = nil) {
        let chatService = ServiceManager.shared.resolve(ChatService.self)
        _viewModel = StateObject(wrappedValue: ChatViewModel(
            chatService: chatService,
            conversationId: conversationId
        ))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Messages list
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }

                        // Streaming message if active
                        if !viewModel.streamingContent.isEmpty {
                            MessageBubble(
                                message: Message(
                                    id: "streaming",
                                    conversationId: viewModel.conversationId ?? "",
                                    role: .assistant,
                                    content: viewModel.streamingContent,
                                    createdAt: ISO8601DateFormatter().string(from: Date())
                                ),
                                isStreaming: true
                            )
                            .id("streaming")
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    if let lastMessage = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: viewModel.streamingContent) { _, _ in
                    withAnimation {
                        proxy.scrollTo("streaming", anchor: .bottom)
                    }
                }
            }

            // Error message
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
            }

            // Input area
            HStack(spacing: 12) {
                TextField("Type a message...", text: $messageText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                    .lineLimit(1...5)
                    .focused($isTextFieldFocused)

                Button(action: sendMessage) {
                    Image(systemName: viewModel.isSending ? "stop.circle.fill" : "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(canSend ? .blue : .gray)
                }
                .disabled(!canSend && !viewModel.isSending)
            }
            .padding()
            .background(Color(.systemBackground))
        }
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

    private var canSend: Bool {
        !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !viewModel.isSending
    }

    private func sendMessage() {
        guard canSend else { return }

        let message = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        messageText = ""
        isTextFieldFocused = false

        Task {
            await viewModel.sendMessage(message)
        }
    }
}

struct MessageBubble: View {
    let message: Message
    var isStreaming: Bool = false

    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(12)
                    .background(message.role == .user ? Color.blue : Color(.systemGray5))
                    .foregroundColor(message.role == .user ? .white : .primary)
                    .cornerRadius(16)

                if !isStreaming {
                    Text(formatTime(message.createdAt))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: 280, alignment: message.role == .user ? .trailing : .leading)
        }
    }
    
    private func formatTime(_ dateString: String) -> String {
        // Format: "2024-11-05T14:30:00" -> "14:30"
        let components = dateString.split(separator: "T")
        if components.count >= 2 {
            let time = String(components[1].prefix(5)) // Get HH:mm
            return time
        }
        return dateString
    }
}

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var streamingContent = ""
    @Published var isSending = false
    @Published var errorMessage: String?
    @Published var conversationId: String?

    private let chatService: ChatService

    init(chatService: ChatService, conversationId: String? = nil) {
        self.chatService = chatService
        self.conversationId = conversationId
    }

    func loadConversation() async {
        guard let conversationId = conversationId else { return }

        do {
            let (_, messages) = try await chatService.getConversation(id: conversationId)
            self.messages = messages
        } catch {
            errorMessage = "Failed to load conversation: \(error.localizedDescription)"
        }
    }

    func sendMessage(_ text: String) async {
        // Add user message immediately
        let userMessage = Message(
            id: UUID().uuidString,
            conversationId: conversationId ?? "",
            role: .user,
            content: text,
            createdAt: ISO8601DateFormatter().string(from: Date())
        )
        messages.append(userMessage)

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
            errorMessage = "Failed to send message: \(error.localizedDescription)"
        }

        isSending = false
    }

    private func handleStreamEvent(_ event: ChatStreamEvent) {
        switch event {
        case .conversationStart(let id):
            if conversationId == nil {
                conversationId = id
            }

        case .messageStart:
            streamingContent = ""

        case .contentDelta(let content):
            streamingContent += content

        case .messageEnd:
            if !streamingContent.isEmpty {
                let assistantMessage = Message(
                    id: UUID().uuidString,
                    conversationId: conversationId ?? "",
                    role: .assistant,
                    content: streamingContent,
                    createdAt: ISO8601DateFormatter().string(from: Date())
                )
                messages.append(assistantMessage)
                streamingContent = ""
            }

        case .conversationEnd:
            break

        case .error(let error):
            errorMessage = error
        }
    }
}
