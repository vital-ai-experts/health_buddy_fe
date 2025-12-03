import SwiftUI
import FeatureChatApi
import LibraryServiceLoader
import LibraryChatUI

struct OnboardingChatContainer: View {
    private let onFinish: () -> Void
    private let onViewDungeon: () -> Void
    private let chatFeature: FeatureChatBuildable
    @State private var hasTriggeredIntro = false
    @State private var controller: ChatSessionControlling?

    init(
        onFinish: @escaping () -> Void,
        onViewDungeon: @escaping () -> Void,
        chatFeature: FeatureChatBuildable = ServiceManager.shared.resolve(FeatureChatBuildable.self)
    ) {
        self.onFinish = onFinish
        self.onViewDungeon = onViewDungeon
        self.chatFeature = chatFeature
    }

    var body: some View {
        chatFeature.makeChatView(
            config: ChatConversationConfig(
                initialConversationId: OnboardingChatMocking.onboardingConversationId,
                navigationTitle: "对话引导",
                showsCloseButton: false,
                chatContext: ChatContext { text in
                    Task { @MainActor in
                        await sendMessage(text)
                    }
                },
                onReady: { controller in
                    self.controller = controller
                    Task { @MainActor in
                        await triggerIntroIfNeeded(using: controller)
                    }
                }
            )
        )
        .onAppear {
            OnboardingChatMessageRegistrar.updateHandlers(
                onViewDungeon: {
                    onViewDungeon()
                },
                onStartDungeon: {
                    onFinish()
                }
            )
        }
        .onDisappear {
            let routeManager = RouteManager.shared
            OnboardingChatMessageRegistrar.updateHandlers(
                onViewDungeon: {
                    Task { @MainActor in
                        if let url = routeManager.buildURL(path: "/dungeon_detail", queryItems: ["present": "sheet"]) {
                            routeManager.open(url: url)
                        }
                    }
                },
                onStartDungeon: {
                    Task { @MainActor in
                        routeManager.currentTab = .agenda
                    }
                }
            )
        }
    }

    @MainActor
    private func triggerIntroIfNeeded(using controller: ChatSessionControlling) async {
        guard !hasTriggeredIntro else { return }
        hasTriggeredIntro = true

        await controller.sendSystemCommand(OnboardingChatMocking.Command.start, preferredConversationId: OnboardingChatMocking.onboardingConversationId)
    }

    @MainActor
    private func sendMessage(_ text: String) async {
        guard let controller else { return }
        await controller.sendMessage(text)
    }
}
