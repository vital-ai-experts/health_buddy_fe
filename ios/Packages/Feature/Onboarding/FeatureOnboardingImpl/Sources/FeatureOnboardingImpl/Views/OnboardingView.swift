import SwiftUI
import FeatureOnboardingApi
import FeatureChatApi
import LibraryServiceLoader
import ThemeKit

struct OnboardingView: View {
    @StateObject private var viewModel: OnboardingViewModel
    @State private var introLine1Started = false
    @State private var introLine2Started = false
    @State private var introLine3Started = false
    @State private var introTypingCompleted = false
    @State private var showChat = false
    private let chatFeature: FeatureChatBuildable

    init(
        onComplete: @escaping () -> Void,
        stateManager: OnboardingStateManaging = ServiceManager.shared.resolve(OnboardingStateManaging.self),
        chatFeature: FeatureChatBuildable = ServiceManager.shared.resolve(FeatureChatBuildable.self)
    ) {
        let storedId = stateManager.getOnboardingID()
        let hasExistingOnboarding = (!stateManager.hasCompletedOnboarding) &&
            (storedId?.hasPrefix(OnboardingChatMocking.onboardingConversationPrefix) == true)

        _viewModel = StateObject(wrappedValue: OnboardingViewModel(
            stateManager: stateManager,
            onComplete: onComplete
        ))
        self.chatFeature = chatFeature
        self._showChat = State(initialValue: hasExistingOnboarding)
        if hasExistingOnboarding {
            // 避免首屏闪过 Intro
            _introLine1Started = State(initialValue: true)
        }
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
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 20)
        }
        .overlay(alignment: .bottom) {
            OnboardingPrimaryButton(
                title: viewModel.primaryButtonTitle,
                isDisabled: viewModel.isPrimaryButtonDisabled,
                isLoading: false,
                action: {
                    handlePrimaryAction()
                }
            )
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
            .transition(.opacity)
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
            if !introLine1Started && !showChat {
                introLine1Started = true
            }
        }
        .animation(.easeInOut(duration: 0.35), value: viewModel.step)
        .fullScreenCover(isPresented: $showChat) {
            OnboardingChatContainer(
                chatFeature: chatFeature
            )
            .environmentObject(OnboardingFlowController(finish: {
                viewModel.completeAfterDungeonStart()
                RouteManager.shared.currentTab = .agenda
            }))
        }
    }

    @ViewBuilder
    private func background(for step: OnboardingStep) -> some View {
        Color.black
    }

    private func handlePrimaryAction() {
        switch viewModel.step {
        case .intro:
            viewModel.handlePrimaryAction()
        case .scan:
            guard viewModel.isScanCompleted else { return }
            openChat()
        }
    }

    private func openChat() {
        showChat = true
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
        .environmentObject(RouteManager.shared)
}
