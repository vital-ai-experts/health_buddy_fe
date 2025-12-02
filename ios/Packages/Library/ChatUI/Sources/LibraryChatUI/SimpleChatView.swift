import SwiftUI
import ThemeKit

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
    public let onLoadMoreHistory: (() -> Void)?

    @FocusState private var isInputFocused: Bool
    @State private var loadingId = UUID().uuidString  // Stable ID for loading indicator

    public init(
        messages: Binding<[ChatMessage]>,
        inputText: Binding<String>,
        isLoading: Bool = false,
        configuration: ChatConfiguration = .default,
        bottomPadding: CGFloat = 0,
        onSendMessage: @escaping (String) -> Void,
        onSpecialMessageAction: ((String, String) -> Void)? = nil,
        onRetry: ((String) -> Void)? = nil,
        onLoadMoreHistory: (() -> Void)? = nil
    ) {
        self._messages = messages
        self._inputText = inputText
        self.isLoading = isLoading
        self.configuration = configuration
        self.bottomPadding = bottomPadding
        self.onSendMessage = onSendMessage
        self.onSpecialMessageAction = onSpecialMessageAction
        self.onRetry = onRetry
        self.onLoadMoreHistory = onLoadMoreHistory
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            // 背景色
            Color.Palette.bgBase
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 顶部拖动指示器
                DragIndicator()
                    .padding(.top, 8)
                    .padding(.bottom, 4)

                // 消息列表 - 使用新的 UICollectionView-based 组件
                MessageListView(
                    messages: messageItems,
                    configuration: configuration,
                    onLoadMoreHistory: onLoadMoreHistory,
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
                .padding(.bottom, 100)  // 为悬浮输入框留出空间
            }

            // 悬浮输入框 - 毛玻璃效果
            VStack(spacing: 0) {
                ChatInputView(
                    text: $inputText,
                    isFocused: $isInputFocused,
                    isLoading: isLoading,
                    onSend: handleSend
                )
            }
            .background(.ultraThinMaterial)
            .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: -4)
        }
        .onChange(of: isLoading) { oldValue, newValue in
            // When loading starts, generate a new unique ID for the loading indicator
            if !oldValue && newValue {
                loadingId = UUID().uuidString
            }

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

        // 去重 - 使用字典按 ID 去重，保留最后一个（最新的）
        var uniqueItems: [String: MessageItem] = [:]
        for item in items {
            uniqueItems[item.id] = item
        }
        items = Array(uniqueItems.values).sorted { item1, item2 in
            // 保持原始顺序 - 通过时间戳排序
            let timestamp1 = getTimestamp(for: item1)
            let timestamp2 = getTimestamp(for: item2)
            return timestamp1 < timestamp2
        }

        // 如果正在加载且没有流式消息，添加一个 loading indicator
        if isLoading && !hasStreamingMessage {
            items.append(.loading(SystemLoading(id: loadingId)))
        }

        return items
    }

    private func getTimestamp(for item: MessageItem) -> Date {
        switch item {
        case .user(let message):
            return message.timestamp
        case .system(let message):
            return message.timestamp
        case .error(let error):
            return error.timestamp
        case .loading:
            return Date()  // loading always appears last
        }
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

// MARK: - Drag Indicator

/// 拖动指示器 - 用于 sheet 展示
private struct DragIndicator: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 2.5)
            .fill(Color.Palette.borderSubtle)
            .frame(width: 36, height: 5)
    }
}

