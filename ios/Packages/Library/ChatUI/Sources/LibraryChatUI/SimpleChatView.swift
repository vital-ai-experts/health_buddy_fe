import SwiftUI

/// 简单聊天视图 - 专为 AI 对话场景优化
public struct SimpleChatView: View {
    @Binding public var messages: [ChatMessage]
    @Binding public var inputText: String
    public let isLoading: Bool
    public let configuration: ChatConfiguration
    public let bottomPadding: CGFloat
    public let onSendMessage: (String) -> Void

    @FocusState private var isInputFocused: Bool

    public init(
        messages: Binding<[ChatMessage]>,
        inputText: Binding<String>,
        isLoading: Bool = false,
        configuration: ChatConfiguration = .default,
        bottomPadding: CGFloat = 0,
        onSendMessage: @escaping (String) -> Void
    ) {
        self._messages = messages
        self._inputText = inputText
        self.isLoading = isLoading
        self.configuration = configuration
        self.bottomPadding = bottomPadding
        self.onSendMessage = onSendMessage
    }

    public var body: some View {
        VStack(spacing: 0) {
            // 消息列表
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(Array(messages.enumerated()), id: \.element.id) { index, message in
                            MessageBubbleView(
                                message: message,
                                configuration: configuration,
                                showAvatar: shouldShowAvatar(at: index)
                            )
                            .id(message.id)
                        }

                        // Loading indicator
                        if isLoading && !hasStreamingMessage {
                            HStack(alignment: .top, spacing: 8) {
                                // Bot 头像 - 根据前一条消息决定是否显示
                                if configuration.showAvatar {
                                    if shouldShowTypingIndicatorAvatar {
                                        typingIndicatorAvatarView
                                            .padding(.top, 6)
                                    } else {
                                        // 占位空间，保持对齐
                                        Color.clear
                                            .frame(width: 32, height: 32)
                                            .padding(.top, 6)
                                    }
                                }

                                // Typing indicator 气泡
                                TypingIndicatorView()
                                    .padding(16)
                                    .background(configuration.botMessageColor)
                                    .cornerRadius(configuration.cornerRadius)

                                Spacer(minLength: 60)
                            }
                            .padding(.horizontal, 16)
                            .id("loading")
                        }
                    }
                    .padding(.top, 12)
                    .padding(.bottom, bottomPadding)  // 可配置的底部空间
                }
                .onChange(of: messages.count) { _, _ in
                    scrollToBottom(proxy: proxy, animated: true)
                }
                .onChange(of: isLoading) { _, newValue in
                    if newValue {
                        scrollToBottom(proxy: proxy, animated: false)
                    }
                }
                // 监听流式消息的变化（限流以避免过度滚动）
                .onChange(of: streamingMessageText) { oldValue, newValue in
                    // 只在文本显著变化时滚动（例如，每增加20个字符）
                    if abs(newValue.count - oldValue.count) >= 20 || newValue.count < oldValue.count {
                        scrollToBottom(proxy: proxy, animated: false)
                    }
                }
            }

            Divider()

            // 输入框
            ChatInputView(
                text: $inputText,
                isFocused: $isInputFocused,
                isLoading: isLoading,
                onSend: handleSend
            )
        }
        .background(Color(.systemBackground))
        .onChange(of: isLoading) { oldValue, newValue in
            // 当 loading 从 true 变为 false（AI 回复完成），根据配置决定是否自动聚焦
            if oldValue && !newValue && configuration.autoFocusAfterBotMessage {
                // 延迟一下，确保 UI 已经更新
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isInputFocused = true
                }
            }
        }
    }

    // Typing indicator 的头像视图
    @ViewBuilder
    private var typingIndicatorAvatarView: some View {
        if let avatarURL = configuration.botAvatarURL {
            AsyncImage(url: avatarURL) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                defaultBotAvatarPlaceholder
            }
            .frame(width: 32, height: 32)
            .clipShape(Circle())
        } else {
            defaultBotAvatarPlaceholder
        }
    }

    private var defaultBotAvatarPlaceholder: some View {
        ZStack {
            Circle()
                .fill(Color(.systemGray4))
            Image(systemName: "brain.head.profile")
                .font(.system(size: 16))
                .foregroundColor(.white)
        }
        .frame(width: 32, height: 32)
    }

    // 判断 typing indicator 是否应该显示头像
    private var shouldShowTypingIndicatorAvatar: Bool {
        // 如果没有消息，显示头像
        guard let lastMessage = messages.last else {
            return true
        }

        // 如果前一条消息是用户消息，显示头像
        // 如果前一条消息是 bot 消息，不显示头像（连续消息）
        return lastMessage.isFromUser
    }

    // 判断是否应该显示头像
    private func shouldShowAvatar(at index: Int) -> Bool {
        let message = messages[index]

        // 如果是第一条消息，显示头像
        if index == 0 {
            return true
        }

        // 获取前一条消息
        let previousMessage = messages[index - 1]

        // 如果当前消息和前一条消息来自不同的发送者，显示头像
        if message.isFromUser != previousMessage.isFromUser {
            return true
        }

        // 如果是连续的同一发送者消息，不显示头像
        return false
    }

    private var hasStreamingMessage: Bool {
        messages.contains { $0.isStreaming }
    }

    private var streamingMessageText: String {
        messages.first { $0.isStreaming }?.text ?? ""
    }

    private func scrollToBottom(proxy: ScrollViewProxy, animated: Bool = true) {
        // 减少延迟以提高响应性，并避免过度排队
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            let scrollAction = {
                if isLoading && !hasStreamingMessage {
                    proxy.scrollTo("loading", anchor: .top)
                } else if let lastMessage = messages.last {
                    proxy.scrollTo(lastMessage.id, anchor: .top)
                }
            }
            
            if animated {
                withAnimation(.easeOut(duration: 0.3)) {
                    scrollAction()
                }
            } else {
                scrollAction()
            }
        }
    }

    private func handleSend() {
        let trimmedText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty, !isLoading else { return }

        onSendMessage(trimmedText)
        inputText = ""
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var messages: [ChatMessage] = [
            ChatMessage(text: "Hello! How can I help you today?", isFromUser: false, timestamp: Date().addingTimeInterval(-3600)),
            ChatMessage(text: "Let me know if you have any questions.", isFromUser: false, timestamp: Date().addingTimeInterval(-3550)),
            ChatMessage(text: "I need help with my health data", isFromUser: true, timestamp: Date().addingTimeInterval(-3500)),
            ChatMessage(text: "Also, can you explain the charts?", isFromUser: true, timestamp: Date().addingTimeInterval(-3450)),
            ChatMessage(text: "I'd be happy to help you with that.", isFromUser: false, timestamp: Date().addingTimeInterval(-3400)),
        ]
        @State private var inputText = ""
        @State private var isLoading = false

        var body: some View {
            NavigationView {
                SimpleChatView(
                    messages: $messages,
                    inputText: $inputText,
                    isLoading: isLoading,
                    configuration: .default,
                    onSendMessage: { text in
                        // 添加用户消息
                        messages.append(ChatMessage(text: text, isFromUser: true))

                        // 模拟 AI 响应
                        isLoading = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            isLoading = false
                            messages.append(ChatMessage(
                                text: "I understand. Let me help you with that.",
                                isFromUser: false
                            ))
                        }
                    }
                )
                .navigationTitle("Chat")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }

    return PreviewWrapper()
}

