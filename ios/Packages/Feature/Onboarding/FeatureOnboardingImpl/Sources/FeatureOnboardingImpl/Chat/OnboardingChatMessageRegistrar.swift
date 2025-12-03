import Foundation
import SwiftUI
import LibraryChatUI
import FeatureChatApi
import ThemeKit

enum OnboardingChatMessageRegistrar {
    private static var hasRegistered = false

    private struct HandlerStore {
        static var onViewDungeon: () -> Void = {}
        static var onStartDungeon: () -> Void = {}
        static var hasTriggeredSkip = false
    }

    static func registerRenderers() {
        guard !hasRegistered else { return }
        hasRegistered = true

        ChatMessageRendererRegistry.shared.register(
            type: "onboarding_profile_card",
            renderer: renderProfileCard
        )
        ChatMessageRendererRegistry.shared.register(
            type: "onboarding_call_card",
            renderer: renderCallCard
        )
        ChatMessageRendererRegistry.shared.register(
            type: "onboarding_dungeon_card",
            renderer: renderDungeonCard
        )
        ChatMessageRendererRegistry.shared.register(
            type: "onboarding_skip",
            renderer: renderSkipMessage
        )
    }

    static func updateHandlers(
        onViewDungeon: @escaping () -> Void,
        onStartDungeon: @escaping () -> Void
    ) {
        HandlerStore.onViewDungeon = onViewDungeon
        HandlerStore.onStartDungeon = onStartDungeon
        HandlerStore.hasTriggeredSkip = false
    }

    // MARK: - Renderers

    private static func renderProfileCard(
        message: CustomRenderedMessage,
        session: ChatSessionControlling?
    ) -> AnyView {
        let payload = decode(ProfileCardPayload.self, from: message.data)
        return AnyView(
            OnboardingProfileCardView(
                payload: payload,
                onConfirm: {
                    Task { @MainActor in
                        await session?.sendSystemCommand(OnboardingChatMocking.Command.confirmProfile, preferredConversationId: nil)
                    }
                },
                onSelectIssue: { issueId in
                    let command = "\(OnboardingChatMocking.Command.selectIssuePrefix)\(issueId)"
                    Task { @MainActor in
                        await session?.sendSystemCommand(command, preferredConversationId: nil)
                    }
                }
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        )
    }

    private static func renderCallCard(
        message: CustomRenderedMessage,
        session: ChatSessionControlling?
    ) -> AnyView {
        let payload = decode(CallCardPayload.self, from: message.data)
        return AnyView(
            OnboardingCallCardView(
                payload: payload
            ) { phone in
                let command = "\(OnboardingChatMocking.Command.bookCallPrefix)\(phone)"
                Task { @MainActor in
                    await session?.sendSystemCommand(command, preferredConversationId: nil)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        )
    }

    private static func renderDungeonCard(
        message: CustomRenderedMessage,
        session: ChatSessionControlling?
    ) -> AnyView {
        let payload = decode(DungeonCardPayload.self, from: message.data)
        return AnyView(
            OnboardingDungeonCardView(
                payload: payload,
                onViewDungeon: {
                    Task { @MainActor in
                        await session?.sendSystemCommand(OnboardingChatMocking.Command.viewDungeon, preferredConversationId: nil)
                    }
                    HandlerStore.onViewDungeon()
                },
                onStartDungeon: {
                    Task { @MainActor in
                        await session?.sendSystemCommand(OnboardingChatMocking.Command.startDungeon, preferredConversationId: nil)
                    }
                    HandlerStore.onStartDungeon()
                }
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        )
    }

    private static func renderSkipMessage(
        message: CustomRenderedMessage,
        session: ChatSessionControlling?
    ) -> AnyView {
        triggerSkipOnce()
        return AnyView(
            VStack(alignment: .leading, spacing: 8) {
                Text("已跳过引导，正在返回首页")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.Palette.textPrimary)
                Button("立即前往") {
                    triggerSkipOnce()
                }
                .font(.system(size: 14, weight: .semibold))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        )
    }

    private static func triggerSkipOnce() {
        guard !HandlerStore.hasTriggeredSkip else { return }
        HandlerStore.hasTriggeredSkip = true
        Task { @MainActor in
            HandlerStore.onStartDungeon()
        }
    }

    // MARK: - Decode helper

    private static func decode<T: Decodable>(_ type: T.Type, from data: String?) -> T? {
        guard let data, let json = data.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(T.self, from: json)
    }
}
