import SwiftUI
import FeatureOnboardingApi
import LibraryBase

struct OnboardingInitialChatPayload {
    let conversationId: String
    let query: String
}

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var inputText: String = ""

    let suggestionRows: [[String]] = [
        ["提升睡眠质量", "消除日间疲劳", "科学减脂"],
        ["增强肌肉力量", "缓解焦虑/压力"]
    ]

    private let stateManager: OnboardingStateManaging
    private let onComplete: () -> Void

    init(
        stateManager: OnboardingStateManaging,
        onComplete: @escaping () -> Void
    ) {
        self.stateManager = stateManager
        self.onComplete = onComplete
    }

    func submitCurrentInput() -> OnboardingInitialChatPayload? {
        submit(text: inputText)
    }

    func submit(text: String) -> OnboardingInitialChatPayload? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let conversationId = stateManager.ensureOnboardingID()
        stateManager.saveInitialQuery(trimmed)
        inputText = ""
        return OnboardingInitialChatPayload(
            conversationId: conversationId,
            query: trimmed
        )
    }

    func finishOnboarding() {
        let id = stateManager.getOnboardingID() ?? OnboardingChatMocking.makeConversationId()
        stateManager.saveOnboardingID(id)
        stateManager.markOnboardingAsCompleted()
        Log.i("✅ Onboarding 完成，使用 ID: \(id)", category: "Onboarding")
        onComplete()
    }

    func completeAfterDungeonStart() {
        finishOnboarding()
    }
}
