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
        stateManager.saveOnboardingID(OnboardingStateManager.mockOnboardingID)
        stateManager.markOnboardingAsCompleted()
        Log.i("✅ Onboarding 完成，使用 mock ID: \(OnboardingStateManager.mockOnboardingID)", category: "Onboarding")
        onComplete()
    }

    func completeAfterDungeonStart() {
        finishOnboarding()
    }

    deinit {
        scanTask?.cancel()
    }
}
