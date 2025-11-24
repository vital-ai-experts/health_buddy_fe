import SwiftUI
import FeatureOnboardingApi
import LibraryBase

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var step: OnboardingStep = .intro
    @Published var visibleScanLines: [OnboardingScanLine] = []
    @Published var isScanCompleted = false
    @Published var selectedIssueID: String
    @Published var name: String = ""
    @Published var phoneNumber: String = ""
    @Published var callState: OnboardingCallState = .idle

    let issueOptions: [OnboardingIssueOption]
    let profileSnapshot: OnboardingProfileSnapshot

    private let scanLines: [OnboardingScanLine]
    private let stateManager: OnboardingStateManaging
    private let onComplete: () -> Void
    private var scanTask: Task<Void, Never>?
    private var callTask: Task<Void, Never>?

    init(
        stateManager: OnboardingStateManaging,
        onComplete: @escaping () -> Void
    ) {
        self.stateManager = stateManager
        self.onComplete = onComplete
        self.issueOptions = OnboardingMockData.issueOptions
        self.profileSnapshot = OnboardingMockData.profileSnapshot
        self.scanLines = OnboardingMockData.scanLines
        self.selectedIssueID = issueOptions.first?.id ?? ""
    }

    var primaryButtonTitle: String {
        switch step {
        case .intro:
            return "连接我的身体数据"
        case .scan:
            return isScanCompleted ? "查看 AI 生成的信息" : "初步诊断生成中..."
        case .profile:
            return "确认并生成战术"
        case .call:
            return callState.buttonTitle
        }
    }

    var isPrimaryButtonDisabled: Bool {
        switch step {
        case .scan:
            return !isScanCompleted
        case .call:
            return !isCallFormValid || callState.isProcessing
        default:
            return false
        }
    }

    var isPrimaryButtonLoading: Bool {
        step == .call && callState.isProcessing
    }

    var selectedIssue: OnboardingIssueOption? {
        issueOptions.first { $0.id == selectedIssueID }
    }

    func handlePrimaryAction() {
        switch step {
        case .intro:
            withAnimation(.easeInOut(duration: 0.4)) {
                step = .scan
            }
            startScanIfNeeded()

        case .scan:
            guard isScanCompleted else { return }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.9)) {
                step = .profile
            }

        case .profile:
            withAnimation(.spring(response: 0.5, dampingFraction: 0.9)) {
                step = .call
            }

        case .call:
            handleCallAction()
        }
    }

    func selectIssue(_ id: String) {
        selectedIssueID = id
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
        callTask?.cancel()
    }
}

// MARK: - Call flow

private extension OnboardingViewModel {
    var isCallFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && isPhoneValid(phoneNumber)
    }

    func handleCallAction() {
        switch callState {
        case .idle:
            startCallFlow()
        case .completed:
            break
        case .waiting, .inCall:
            break
        }
    }

    func startCallFlow() {
        guard callTask == nil, isCallFormValid else { return }

        callState = .waiting
        callTask = Task { [weak self] in
            guard let self else { return }

            try? await Task.sleep(nanoseconds: 5_000_000_000)
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.35)) {
                    callState = .inCall
                }
            }

            try? await Task.sleep(nanoseconds: 10_000_000_000)
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.35)) {
                    callState = .completed
                }
                callTask = nil
            }
        }
    }

    func isPhoneValid(_ phone: String) -> Bool {
        let trimmed = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        let digits = trimmed.filter { $0.isNumber }
        return !trimmed.isEmpty && digits.count >= 6
    }
}
