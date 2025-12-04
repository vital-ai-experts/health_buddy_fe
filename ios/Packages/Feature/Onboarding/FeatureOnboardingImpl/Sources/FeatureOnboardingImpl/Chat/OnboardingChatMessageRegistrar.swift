import Foundation
import SwiftUI
import LibraryChatUI
import FeatureChatApi
import ThemeKit
import FeatureOnboardingApi
import FeatureAgendaApi
import LibraryServiceLoader

enum OnboardingChatMessageRegistrar {
    private static var hasRegistered = false

    static func registerRenderers() {
        guard !hasRegistered else { return }
        hasRegistered = true

        ChatMessageRendererRegistry.shared.register(
            type: "onboarding_profile_info_card",
            renderer: renderProfileInfoCard
        )
        ChatMessageRendererRegistry.shared.register(
            type: "onboarding_issue_card",
            renderer: renderIssueCard
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
            type: "onboarding_finish_card",
            renderer: renderFinishCard
        )
    }

    // MARK: - Renderers

    private static func renderProfileInfoCard(
        message: CustomRenderedMessage,
        session: ChatSessionControlling?
    ) -> AnyView {
        let payload = decode(ProfileCardPayload.self, from: message.data)
        return AnyView(
            OnboardingProfileInfoCardView(
                payload: payload,
                onConfirm: { draft in
                    Task { @MainActor in
                        let command = "\(OnboardingChatMocking.Command.updateProfilePrefix)gender=\(draft.gender);age=\(draft.age);height=\(draft.height);weight=\(draft.weight)"
                        await session?.sendSystemCommand(command, preferredConversationId: nil)
                        await session?.sendSystemCommand(OnboardingChatMocking.Command.confirmProfile, preferredConversationId: nil)
                    }
                }
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        )
    }

    private static func renderIssueCard(
        message: CustomRenderedMessage,
        session: ChatSessionControlling?
    ) -> AnyView {
        let payload = decode(ProfileCardPayload.self, from: message.data)
        return AnyView(
            OnboardingIssueCardView(
                payload: payload,
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
                onStartDungeon: {
                    Task { @MainActor in
                        await session?.sendSystemCommand(OnboardingChatMocking.Command.startDungeon, preferredConversationId: nil)
                    }
                }
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        )
    }

    private static func renderFinishCard(
        message: CustomRenderedMessage,
        session: ChatSessionControlling?
    ) -> AnyView {
        AnyView(
            OnboardingFinishCardView()
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
