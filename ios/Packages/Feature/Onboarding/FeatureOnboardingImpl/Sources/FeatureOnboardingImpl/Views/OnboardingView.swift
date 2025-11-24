import SwiftUI
import FeatureOnboardingApi
import LibraryServiceLoader
import ThemeKit

struct OnboardingView: View {
    @StateObject private var viewModel: OnboardingViewModel
    @State private var introLine1Started = false
    @State private var introLine2Started = false
    @State private var introLine3Started = false
    @State private var introTypingCompleted = false

    private var shouldShowProgressAndButton: Bool {
        viewModel.step != .intro || introTypingCompleted
    }

    init(
        onComplete: @escaping () -> Void,
        stateManager: OnboardingStateManaging = ServiceManager.shared.resolve(OnboardingStateManaging.self)
    ) {
        _viewModel = StateObject(wrappedValue: OnboardingViewModel(
            stateManager: stateManager,
            onComplete: onComplete
        ))
    }

    var body: some View {
        ZStack {
            background(for: viewModel.step)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer(minLength: 0)

                switch viewModel.step {
                case .intro:
                    IntroSectionView(
                        line1Started: introLine1Started,
                        line2Started: introLine2Started,
                        line3Started: introLine3Started,
                        onLine1Completed: { introLine2Started = true },
                        onLine2Completed: { introLine3Started = true },
                        onTypingCompleted: { introTypingCompleted = true }
                    )

                case .scan:
                    ScanSectionView(
                        isCompleted: viewModel.isScanCompleted,
                        lines: viewModel.visibleScanLines
                    )

                case .profile:
                    ProfileSectionView(
                        snapshot: viewModel.profileSnapshot,
                        issueOptions: viewModel.issueOptions,
                        selectedIssueID: viewModel.selectedIssueID,
                        selectedIssue: viewModel.selectedIssue,
                        onIssueSelect: { viewModel.selectIssue($0) }
                    )

                case .call:
                    CallSectionView(
                        name: binding(\.name),
                        phoneNumber: binding(\.phoneNumber),
                        callState: viewModel.callState
                    )
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 20)
        }
        .overlay(alignment: .bottomTrailing) {
            if viewModel.step == .intro {
                BreathingDotView()
                    .padding(.trailing, -12)
                    .padding(.bottom, 100)
            }
        }
        .overlay(alignment: .top) {
            if shouldShowProgressAndButton {
                OnboardingProgressIndicator(step: viewModel.step)
                    .padding(.top, 8)
                    .padding(.horizontal, 24)
                    .transition(.opacity)
            }
        }
        .overlay(alignment: .bottom) {
            if shouldShowProgressAndButton {
                OnboardingPrimaryButton(
                    title: viewModel.primaryButtonTitle,
                    isDisabled: viewModel.isPrimaryButtonDisabled,
                    isLoading: viewModel.isPrimaryButtonLoading,
                    action: {
                        viewModel.handlePrimaryAction()
                    }
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
                .transition(.opacity)
            }
        }
        .onChange(of: viewModel.step) { _, newValue in
            if newValue == .scan {
                viewModel.startScanIfNeeded()
            }
            if newValue == .intro && !introLine1Started {
                introLine1Started = true
            }
        }
        .onAppear {
            if !introLine1Started {
                introLine1Started = true
            }
        }
        .animation(.easeInOut(duration: 0.35), value: shouldShowProgressAndButton)
    }

    private func binding<Value>(_ keyPath: ReferenceWritableKeyPath<OnboardingViewModel, Value>) -> Binding<Value> {
        Binding(
            get: { viewModel[keyPath: keyPath] },
            set: { viewModel[keyPath: keyPath] = $0 }
        )
    }

    @ViewBuilder
    private func background(for step: OnboardingStep) -> some View {
        Color.black
    }
}

private final class PreviewOnboardingStateManager: OnboardingStateManaging {
    var hasCompletedOnboarding = false
    private var onboardingID: String?

    func markOnboardingAsCompleted() {
        hasCompletedOnboarding = true
    }

    func resetOnboardingState() {
        hasCompletedOnboarding = false
        onboardingID = nil
    }

    func shouldShowOnboarding(isAuthenticated: Bool) -> Bool {
        !isAuthenticated && !hasCompletedOnboarding
    }

    func saveOnboardingID(_ id: String) {
        onboardingID = id
    }

    func getOnboardingID() -> String? {
        onboardingID
    }

    func clearOnboardingID() {
        onboardingID = nil
    }
}

#Preview {
    OnboardingView(
        onComplete: {},
        stateManager: PreviewOnboardingStateManager()
    )
        .environment(\.colorScheme, .dark)
}
