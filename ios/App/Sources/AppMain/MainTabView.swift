import SwiftUI
import FeatureAccountApi
import FeatureChatApi
import FeatureAgendaApi
import LibraryServiceLoader

/// 主界面 Tab 容器，包含自定义 TabBar 与独立对话按钮
struct MainTabView: View {
    @EnvironmentObject private var router: RouteManager

    private let chatFeature: FeatureChatBuildable
    private let agendaFeature: FeatureAgendaBuildable
    private let accountFeature: FeatureAccountBuildable
    private let onLogout: () -> Void

    init(
        chatFeature: FeatureChatBuildable,
        agendaFeature: FeatureAgendaBuildable,
        accountFeature: FeatureAccountBuildable,
        onLogout: @escaping () -> Void
    ) {
        self.chatFeature = chatFeature
        self.agendaFeature = agendaFeature
        self.accountFeature = accountFeature
        self.onLogout = onLogout
    }

    var body: some View {
        ZStack {
            TabView(selection: Binding(
                get: { router.currentTab },
                set: { router.currentTab = $0 }
            )) {
                agendaFeature.makeAgendaTabView()
                    .tag(RouteManager.Tab.agenda)
                    .toolbar(.hidden, for: .tabBar)

                accountFeature.makeProfileView(onLogout: onLogout)
                    .tag(RouteManager.Tab.profile)
                    .toolbar(.hidden, for: .tabBar)
            }
            .toolbar(.hidden, for: .tabBar)

            VStack {
                Spacer()
                CustomTabBar(
                    selectedTab: Binding(
                        get: { router.currentTab },
                        set: { router.currentTab = $0 }
                    ),
                    onChatTapped: handleChatButtonTapped,
                    onDeveloperTapped: handleDeveloperButtonTapped
                )
            }
        }
    }

    private func handleChatButtonTapped() {
        var queryItems: [String: String] = [:]
        if let goalManager = ServiceManager.shared.resolveOptional(AgendaGoalManaging.self),
           let defaultGoalId = goalManager.defaultSelectedGoalId {
            queryItems["goalId"] = defaultGoalId
        }

        if let chatURL = router.buildURL(path: "/chat", queryItems: queryItems) {
            router.open(url: chatURL)
        }
    }

    private func handleDeveloperButtonTapped() {
        if let debugURL = router.buildURL(path: "/debug_tools") {
            router.open(url: debugURL)
        }
    }
}

#Preview {
    MainTabView(
        chatFeature: PreviewChatFeature(),
        agendaFeature: PreviewAgendaFeature(),
        accountFeature: PreviewAccountFeature(),
        onLogout: {}
    )
    .environmentObject(RouteManager.shared)
}

private struct PreviewAccountFeature: FeatureAccountBuildable {
    func makeLoginView(onLoginSuccess: @escaping () -> Void, isDismissable: Bool) -> AnyView { AnyView(Text("Login")) }
    func makeRegisterView(onRegisterSuccess: @escaping () -> Void) -> AnyView { AnyView(Text("Register")) }
    func makeAccountLandingView(onSuccess: @escaping () -> Void, isDismissable: Bool) -> AnyView { AnyView(Text("Landing")) }
    func makeProfileView(onLogout: @escaping () -> Void) -> AnyView { AnyView(Text("Profile")) }
}

private struct PreviewChatFeature: FeatureChatBuildable {
    func makeConversationListView() -> AnyView { AnyView(Text("Conversations")) }
    func makeChatView(conversationId: String?) -> AnyView { AnyView(Text("Chat")) }
    func makeChatTabView() -> AnyView { AnyView(Text("ChatTab")) }
}

private struct PreviewAgendaFeature: FeatureAgendaBuildable {
    func makeAgendaTabView() -> AnyView { AnyView(Text("Agenda")) }
    func makeAgendaSettingsView() -> AnyView { AnyView(Text("AgendaSettings")) }
    func makeDungeonDetailView() -> AnyView { AnyView(Text("Dungeon")) }
}
