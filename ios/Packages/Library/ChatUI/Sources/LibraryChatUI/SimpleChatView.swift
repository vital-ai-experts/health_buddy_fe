import SwiftUI

/// 简单聊天视图 - 专为 AI 对话场景优化
public struct SimpleChatView: View {
    @Binding public var messages: [ChatMessage]
    @Binding public var inputText: String
    public let isLoading: Bool
    public let configuration: ChatConfiguration
    public let bottomPadding: CGFloat
    public let onSendMessage: (String) -> Void
    public let onSpecialMessageAction: ((String, String) -> Void)?
    public let onRetry: ((String) -> Void)?

    @FocusState private var isInputFocused: Bool

    public init(
        messages: Binding<[ChatMessage]>,
        inputText: Binding<String>,
        isLoading: Bool = false,
        configuration: ChatConfiguration = .default,
        bottomPadding: CGFloat = 0,
        onSendMessage: @escaping (String) -> Void,
        onSpecialMessageAction: ((String, String) -> Void)? = nil,
        onRetry: ((String) -> Void)? = nil
    ) {
        self._messages = messages
        self._inputText = inputText
        self.isLoading = isLoading
        self.configuration = configuration
        self.bottomPadding = bottomPadding
        self.onSendMessage = onSendMessage
        self.onSpecialMessageAction = onSpecialMessageAction
        self.onRetry = onRetry
    }

    public var body: some View {
        VStack(spacing: 0) {
            // 消息列表 - 使用新的 UICollectionView-based 组件
            MessageListView(
                messages: messageItems,
                configuration: configuration,
                onLoadMoreHistory: nil,
                onHealthProfileConfirm: {
                    onSpecialMessageAction?("userHealthProfile", "confirm")
                },
                onHealthProfileReject: {
                    onSpecialMessageAction?("userHealthProfile", "reject")
                },
                onRetry: onRetry
            )
            .contentShape(Rectangle())
            .onTapGesture {
                // 点击消息列表区域，收起键盘
                isInputFocused = false
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

    // 将 ChatMessage 转换为 MessageItem
    private var messageItems: [MessageItem] {
        var items: [MessageItem] = messages.map { MessageItem.from(chatMessage: $0) }

        // 如果正在加载且没有流式消息，添加一个 loading indicator
        if isLoading && !hasStreamingMessage {
            items.append(.loading(SystemLoading(id: "loading")))
        }

        return items
    }

    private var hasStreamingMessage: Bool {
        messages.contains { $0.isStreaming }
    }

    private func handleSend() {
        let trimmedText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty, !isLoading else { return }

        onSendMessage(trimmedText)
        inputText = ""
        
        // 根据配置决定是否收起键盘
        if configuration.dismissKeyboardAfterSend {
            isInputFocused = false
        }
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

