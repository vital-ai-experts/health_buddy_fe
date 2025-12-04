import SwiftUI
import FeatureChatApi
import LibraryServiceLoader
import LibraryChatUI

/// Builder for Chat feature views
public final class ChatBuilder: FeatureChatBuildable {
    public init() {}

    public func makeChatView(config: ChatConversationConfig) -> AnyView {
        AnyView(
            PersistentChatView(
                defaultSelectedGoalId: config.defaultSelectedGoalId,
                initialConversationId: config.initialConversationId,
                chatService: config.chatService ?? defaultChatService(),
                chatSessionBuilder: { viewModel in
                    ChatSessionController(viewModel: viewModel)
                },
                showsCloseButton: config.showsCloseButton,
                navigationTitle: config.navigationTitle,
                topics: config.topics,
                onReady: { controller in
                    config.onReady?(controller)
                }
            )
        )
    }
}

// MARK: - Helpers

private func defaultChatService() -> ChatService {
    // 默认使用带真实服务回落的 Mock，实现统一 mock 入口
    let real = ServiceManager.shared.resolve(ChatService.self)
    return MockChatService(realService: real)
}

/// 会话控制器实现，将外部调用转发给内部 ViewModel
@MainActor
final class ChatSessionController: ChatSessionControlling {
    private weak var viewModel: PersistentChatViewModel?

    init(viewModel: PersistentChatViewModel) {
        self.viewModel = viewModel
    }

    func sendMessage(_ text: String) async {
        guard let viewModel else { return }
        await viewModel.sendMessage(text)
    }

    func sendSystemCommand(_ text: String, preferredConversationId: String?) async {
        guard let viewModel else { return }
        await viewModel.sendSystemCommand(text, preferredConversationId: preferredConversationId)
    }

    func currentMessages() -> [ChatMessage] {
        guard let viewModel else { return [] }
        return viewModel.displayMessages
    }
}
