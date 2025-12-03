import SwiftUI

/// SwiftUI wrapper for UICollectionView-based message list
public struct MessageListView: UIViewRepresentable {

    // MARK: - Properties

    let messages: [MessageItem]
    let configuration: ChatConfiguration
    let onLoadMoreHistory: (() -> Void)?
    let onHealthProfileConfirm: (() -> Void)?
    let onHealthProfileReject: (() -> Void)?
    let onRetry: ((String) -> Void)?
    let chatContext: ChatContext

    // MARK: - Initialization

    public init(
        messages: [MessageItem],
        configuration: ChatConfiguration = .default,
        onLoadMoreHistory: (() -> Void)? = nil,
        onHealthProfileConfirm: (() -> Void)? = nil,
        onHealthProfileReject: (() -> Void)? = nil,
        onRetry: ((String) -> Void)? = nil,
        chatContext: ChatContext = .noop
    ) {
        self.messages = messages
        self.configuration = configuration
        self.onLoadMoreHistory = onLoadMoreHistory
        self.onHealthProfileConfirm = onHealthProfileConfirm
        self.onHealthProfileReject = onHealthProfileReject
        self.onRetry = onRetry
        self.chatContext = chatContext
    }

    // MARK: - UIViewRepresentable

    public func makeUIView(context: Context) -> MessageListCollectionView {
        let collectionView = MessageListCollectionView()
        collectionView.configuration = configuration
        collectionView.onLoadMoreHistory = onLoadMoreHistory
        collectionView.onHealthProfileConfirm = onHealthProfileConfirm
        collectionView.onHealthProfileReject = onHealthProfileReject
        collectionView.onRetry = onRetry
        collectionView.chatContext = chatContext

        // Initial data
        collectionView.updateMessages(messages, animated: false)

        return collectionView
    }

    public func updateUIView(_ uiView: MessageListCollectionView, context: Context) {
        // Update configuration
        uiView.configuration = configuration
        uiView.onLoadMoreHistory = onLoadMoreHistory
        uiView.onHealthProfileConfirm = onHealthProfileConfirm
        uiView.onHealthProfileReject = onHealthProfileReject
        uiView.onRetry = onRetry
        uiView.chatContext = chatContext

        // Update messages
        uiView.updateMessages(messages, animated: context.transaction.animation != nil)
    }
}

// MARK: - Preview

#Preview {
    MessageListView(
        messages: [
            .user(UserMessage(text: "Hello!", timestamp: Date())),
            .system(SystemMessage(
                text: "Hi! How can I help you today?",
                timestamp: Date()
            )),
            .user(UserMessage(text: "Tell me about my health data", timestamp: Date())),
            .system(SystemMessage(
                text: "Let me check your recent activity fe ...",
                timestamp: Date(),
                isStreaming: true,
                thinkingContent: "Analyzing user's health data from the past week"
            )),
            .loading(SystemLoading())
        ]
    )
}
