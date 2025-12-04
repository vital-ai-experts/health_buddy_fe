import SwiftUI
import FeatureChatApi
import FeatureOnboardingApi
import LibraryServiceLoader
import LibraryChatUI

struct OnboardingChatContainer: View {
    private let chatFeature: FeatureChatBuildable
    private let conversationId: String
    private let chatService: ChatService
    private let initialUserMessage: String?
    @State private var hasTriggeredIntro = false
    @State private var controller: ChatSessionControlling?

    init(
        initialUserMessage: String? = nil,
        conversationId: String? = nil,
        chatFeature: FeatureChatBuildable = ServiceManager.shared.resolve(FeatureChatBuildable.self),
        chatService: ChatService = OnboardingMockChatService(),
        stateManager: OnboardingStateManaging = OnboardingStateManager.shared
    ) {
        let trimmedMessage = initialUserMessage?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        self.initialUserMessage = (trimmedMessage?.isEmpty == false) ? trimmedMessage : nil

        self.chatFeature = chatFeature
        self.chatService = chatService

        let baseConversationId = conversationId ?? stateManager.ensureOnboardingID()
        let validConversationId = baseConversationId.hasPrefix(OnboardingChatMocking.onboardingConversationPrefix)
        ? baseConversationId
        : OnboardingChatMocking.makeConversationId()
        self.conversationId = validConversationId
        stateManager.saveOnboardingID(validConversationId)
    }

    var body: some View {
        chatFeature.makeChatView(
            config: ChatConversationConfig(
                initialConversationId: conversationId,
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

        if let initialUserMessage {
            await controller.sendMessage(initialUserMessage)
            await controller.sendSystemCommand(
                OnboardingChatMocking.Command.start,
                preferredConversationId: conversationId
            )
            return
        }

        if controller.currentMessages().isEmpty {
            await controller.sendSystemCommand(
                OnboardingChatMocking.Command.start,
                preferredConversationId: conversationId
            )
        }
    }
}
