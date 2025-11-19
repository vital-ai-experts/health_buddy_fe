import SwiftUI
import FeatureAccountApi
import LibraryServiceLoader

/// Builder for Account feature views
public final class AccountBuilder: FeatureAccountBuildable {
    public init() {}

    public func makeLoginView(onLoginSuccess: @escaping () -> Void, isDismissable: Bool = true) -> AnyView {
        AnyView(LoginView(onLoginSuccess: onLoginSuccess, isDismissable: isDismissable))
    }

    public func makeRegisterView(onRegisterSuccess: @escaping () -> Void) -> AnyView {
        AnyView(RegisterView(onRegisterSuccess: onRegisterSuccess))
    }

    public func makeAccountLandingView(onSuccess: @escaping () -> Void, isDismissable: Bool = true) -> AnyView {
        AnyView(AccountLandingView(onSuccess: onSuccess, isDismissable: isDismissable))
    }

    public func makeProfileView(onLogout: @escaping () -> Void) -> AnyView {
        AnyView(ProfileTabView(onLogout: onLogout))
    }
}

/// ProfileView 的 Tab 包装器，带有独立的 NavigationStack
private struct ProfileTabView: View {
    @EnvironmentObject var router: RouteManager
    let onLogout: () -> Void

    var body: some View {
        NavigationStack(path: $router.profilePath) {
            ProfileView(onLogout: onLogout)
                .navigationDestination(for: RouteMatch.self) { match in
                    print("[ProfileTab] navigationDestination: \(match.path)")
                    return router.buildView(for: match)
                }
        }
        .onAppear {
            // 更新当前 tab
            router.currentTab = .profile
        }
    }
}
