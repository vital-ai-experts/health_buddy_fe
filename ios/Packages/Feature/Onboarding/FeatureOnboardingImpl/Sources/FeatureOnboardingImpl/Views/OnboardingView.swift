import SwiftUI
import FeatureOnboardingApi
import FeatureChatApi
import LibraryServiceLoader
import ThemeKit

struct OnboardingView: View {
    @StateObject private var viewModel: OnboardingViewModel
    @State private var showChat = false
    @State private var pendingChatPayload: OnboardingInitialChatPayload?
    @State private var introTypingCompleted = false
    @FocusState private var isInputFocused: Bool
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
    }

    var body: some View {
        ZStack(alignment: .center) {
            Color.Palette.bgBase
                .ignoresSafeArea()

            IntroSectionView(onTypingCompleted: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    introTypingCompleted = true
                }
            })
                .padding(.horizontal, 16)
            
            VStack(alignment: .center) {
                Spacer()

                if introTypingCompleted {
                    bottomInputArea
                        .transition(.opacity)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: introTypingCompleted)
        .fullScreenCover(isPresented: $showChat) {
            OnboardingChatContainer(
                initialUserMessage: pendingChatPayload?.query,
                conversationId: pendingChatPayload?.conversationId,
                chatFeature: chatFeature
            )
            .environmentObject(OnboardingFlowController(finish: {
                viewModel.completeAfterDungeonStart()
                RouteManager.shared.currentTab = .agenda
            }))
        }
    }

    private var bottomInputArea: some View {
        VStack(alignment: .leading, spacing: 0) {
            suggestionCapsules
            messageField
        }
    }

    private var suggestionCapsules: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(viewModel.suggestionRows.enumerated()), id: \.offset) { _, row in
                    HStack(spacing: 10) {
                        ForEach(row, id: \.self) { suggestion in
                            Button {
                                handleSuggestionTap(suggestion)
                            } label: {
                                Text(suggestion)
                                    .font(.callout.weight(.medium))
                                    .foregroundColor(.Palette.textPrimary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.Palette.surfaceElevated)
                                    .clipShape(Capsule())
                                    .shadow(color: Color.black.opacity(0.06), radius: 6, y: 6)
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
        }
    }

    private var messageField: some View {
        TextField(
            "我想...（例如：每天下午3点不再犯困）",
            text: $viewModel.inputText
        )
        .submitLabel(.send)
        .textInputAutocapitalization(.sentences)
        .disableAutocorrection(true)
        .foregroundColor(.Palette.textPrimary)
        .focused($isInputFocused)
        .onSubmit { submitInput() }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(Color.Palette.surfaceElevated)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.Palette.borderSubtle, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 12, y: 6)
        .padding(.horizontal, 16)
    }

    private func submitInput() {
        guard let payload = viewModel.submitCurrentInput() else { return }
        pendingChatPayload = payload
        showChat = true
        isInputFocused = false
    }

    private func handleSuggestionTap(_ suggestion: String) {
        viewModel.inputText = suggestion
        submitInput()
    }
}

private final class PreviewOnboardingStateManager: OnboardingStateManaging {
    var hasCompletedOnboarding = false
    private var onboardingID: String?
    private var initialQuery: String?

    func markOnboardingAsCompleted() {
        hasCompletedOnboarding = true
    }

    func resetOnboardingState() {
        hasCompletedOnboarding = false
        onboardingID = nil
        initialQuery = nil
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

    func ensureOnboardingID() -> String {
        onboardingID ?? {
            let newId = OnboardingChatMocking.makeConversationId()
            onboardingID = newId
            return newId
        }()
    }

    func saveInitialQuery(_ query: String) {
        initialQuery = query
    }

    func getInitialQuery() -> String? {
        initialQuery
    }

    func clearInitialQuery() {
        initialQuery = nil
    }
}

private struct PreviewChatFeature: FeatureChatBuildable {
    func makeConversationListView() -> AnyView { AnyView(Text("Conversations")) }
    func makeChatView(conversationId: String?) -> AnyView { AnyView(Text("Chat")) }
    func makeChatTabView() -> AnyView { AnyView(Text("ChatTab")) }
    func makeChatView(config: ChatConversationConfig) -> AnyView { AnyView(Text(config.navigationTitle)) }
}

#Preview {
    OnboardingView(
        onComplete: {},
        stateManager: PreviewOnboardingStateManager(),
        chatFeature: PreviewChatFeature()
    )
        .environment(\.colorScheme, .light)
        .environmentObject(RouteManager.shared)
}
