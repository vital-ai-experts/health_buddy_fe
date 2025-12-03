import Foundation
import SwiftUI
import LibraryChatUI
import FeatureChatApi

enum OnboardingChatMessageRegistrar {
    private static var hasRegistered = false

    private struct HandlerStore {
        static var onViewDungeon: () -> Void = {}
        static var onStartDungeon: () -> Void = {}
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
    }

    static func updateHandlers(
        onViewDungeon: @escaping () -> Void,
        onStartDungeon: @escaping () -> Void
    ) {
        HandlerStore.onViewDungeon = onViewDungeon
        HandlerStore.onStartDungeon = onStartDungeon
    }

    // MARK: - Renderers

    private static func renderProfileCard(
        message: CustomRenderedMessage,
        context: ChatContext
    ) -> AnyView {
        let payload = decode(ProfileCardPayload.self, from: message.data)
        return AnyView(
            OnboardingProfileCardView(
                payload: payload,
                onConfirm: {
                    context.sendUserMessage(OnboardingChatMocking.Command.confirmProfile)
                },
                onSelectIssue: { issueId in
                    let command = "\(OnboardingChatMocking.Command.selectIssuePrefix)\(issueId)"
                    context.sendUserMessage(command)
                }
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        )
    }

    private static func renderCallCard(
        message: CustomRenderedMessage,
        context: ChatContext
    ) -> AnyView {
        let payload = decode(CallCardPayload.self, from: message.data)
        return AnyView(
            OnboardingCallCardView(
                payload: payload
            ) { phone in
                let command = "\(OnboardingChatMocking.Command.bookCallPrefix)\(phone)"
                context.sendUserMessage(command)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        )
    }

    private static func renderDungeonCard(
        message: CustomRenderedMessage,
        context: ChatContext
    ) -> AnyView {
        let payload = decode(DungeonCardPayload.self, from: message.data)
        return AnyView(
            OnboardingDungeonCardView(
                payload: payload,
                onViewDungeon: {
                    context.sendUserMessage(OnboardingChatMocking.Command.viewDungeon)
                    HandlerStore.onViewDungeon()
                },
                onStartDungeon: {
                    context.sendUserMessage(OnboardingChatMocking.Command.startDungeon)
                    HandlerStore.onStartDungeon()
                }
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        )
    }

    // MARK: - Decode helper

    private static func decode<T: Decodable>(_ type: T.Type, from data: String?) -> T? {
        guard let data, let json = data.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(T.self, from: json)
    }
}
