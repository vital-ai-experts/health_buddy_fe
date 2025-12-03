import SwiftUI
import FeatureOnboardingApi
import LibraryBase

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var step: OnboardingStep = .intro
    @Published var visibleScanLines: [OnboardingScanLine] = []
    @Published var isScanCompleted = false

    private let scanLines: [OnboardingScanLine]
    private let stateManager: OnboardingStateManaging
    private let onComplete: () -> Void
    private var scanTask: Task<Void, Never>?
    private var hasRestoredChat = false

    init(
        stateManager: OnboardingStateManaging,
        onComplete: @escaping () -> Void
    ) {
        self.stateManager = stateManager
        self.onComplete = onComplete
        self.scanLines = OnboardingMockData.scanLines
    }

    var primaryButtonTitle: String {
        switch step {
        case .intro:
            return "连接我的身体数据"
        case .scan:
            return isScanCompleted ? "进入对话" : "初步诊断生成中..."
        }
    }

    var isPrimaryButtonDisabled: Bool {
        switch step {
        case .scan:
            return !isScanCompleted
        default:
            return false
        }
    }

    func handlePrimaryAction() {
        switch step {
        case .intro:
            withAnimation(.easeInOut(duration: 0.4)) {
                step = .scan
            }
            startScanIfNeeded()

        case .scan:
            break
        }
    }

    func startScanIfNeeded() {
        guard scanTask == nil else { return }
        visibleScanLines = []
        isScanCompleted = false

        scanTask = Task { [weak self] in
            guard let self else { return }

            for line in scanLines {
                try? await Task.sleep(nanoseconds: 200_000_000)
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        visibleScanLines.append(line)
                    }
                }
            }

            try? await Task.sleep(nanoseconds: 200_000_000)

            await MainActor.run {
                withAnimation {
                    isScanCompleted = true
                }
            }
        }
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

    func shouldRestoreChatDirectly() -> Bool {
        guard !hasRestoredChat else { return false }
        guard !stateManager.hasCompletedOnboarding else { return false }
        if let id = stateManager.getOnboardingID(),
           id.hasPrefix(OnboardingChatMocking.onboardingConversationPrefix) {
            hasRestoredChat = true
            return true
        }
        return false
    }

    var onboardingConversationId: String {
        stateManager.getOnboardingID() ?? OnboardingChatMocking.makeConversationId()
    }

    deinit {
        scanTask?.cancel()
    }
}
