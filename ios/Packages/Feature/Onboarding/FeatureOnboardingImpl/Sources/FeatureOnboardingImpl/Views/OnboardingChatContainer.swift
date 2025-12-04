import SwiftUI
import FeatureChatApi
import LibraryServiceLoader
import LibraryChatUI

struct OnboardingChatContainer: View {
    private let chatFeature: FeatureChatBuildable
    private let onboardingConversationId: String
    private let chatService: ChatService
    @State private var hasTriggeredIntro = false
    @State private var controller: ChatSessionControlling?

    init(
        chatFeature: FeatureChatBuildable = ServiceManager.shared.resolve(FeatureChatBuildable.self),
        chatService: ChatService = OnboardingMockChatService()
    ) {
        self.chatFeature = chatFeature
        self.chatService = chatService
        let storedId = OnboardingStateManager.shared.getOnboardingID()
        let validStoredId = storedId?.hasPrefix(OnboardingChatMocking.onboardingConversationPrefix) == true ? storedId : nil
        self.onboardingConversationId = validStoredId ?? OnboardingChatMocking.makeConversationId()
    }

    var body: some View {
        chatFeature.makeChatView(
            config: ChatConversationConfig(
                initialConversationId: onboardingConversationId,
                navigationTitle: "Pascal",
                showsCloseButton: false,
                topics: [],
                onReady: { controller in
                    self.controller = controller
                    Task { @MainActor in
                        await triggerIntroIfNeeded(using: controller)
                    }
                },
                chatService: chatService
            )
        )
    }

    @MainActor
    private func triggerIntroIfNeeded(using controller: ChatSessionControlling) async {
        guard !hasTriggeredIntro else { return }
        hasTriggeredIntro = true

        // 没有任何消息时，推送引导消息
        if controller.currentMessages().isEmpty {
            await controller.sendSystemCommand(OnboardingChatMocking.Command.start, preferredConversationId: onboardingConversationId)
        }
    }
}
