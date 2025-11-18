import SwiftUI
import FeatureAccountApi
import LibraryServiceLoader

extension AccountModule {
    static func registerRoutes(on router: RouteRegistering) {
        router.register(path: "/login", defaultPresentation: .sheet) { context in
            let accountFeature = ServiceManager.shared.resolve(FeatureAccountBuildable.self)
            let isDismissable = context.queryItems["dismissable"]?.lowercased() != "false"
            return AnyView(LoginRouteView(accountFeature: accountFeature, isDismissable: isDismissable))
        }

        router.register(path: "/settings") { _ in
            AnyView(SettingsView())
        }

        router.register(path: "/settings/account") { _ in
            AnyView(AccountSettingsRouteView())
        }

        router.register(path: "/settings/about") { _ in
            AnyView(AboutView())
        }
    }
}

private struct LoginRouteView: View {
    @EnvironmentObject var router: RouteManager
    let accountFeature: FeatureAccountBuildable
    let isDismissable: Bool

    var body: some View {
        accountFeature.makeAccountLandingView(onSuccess: {
            router.handleLoginSuccess()
        }, isDismissable: isDismissable)
    }
}

private struct AccountSettingsRouteView: View {
    @EnvironmentObject var router: RouteManager

    var body: some View {
        AccountSettingsView(onLogout: {
            router.handleLogoutRequested()
        })
    }
}
