import SwiftUI
import FeatureAccountApi
import LibraryServiceLoader

extension AccountModule {
    static func registerRoutes(on router: RouteRegistering) {
        router.register(path: "/login", defaultSurface: .fullscreen) { context in
            let accountFeature = ServiceManager.shared.resolve(FeatureAccountBuildable.self)
            let isDismissable = context.queryItems["dismissable"]?.lowercased() != "false"
            return AnyView(LoginRouteView(accountFeature: accountFeature, isDismissable: isDismissable))
        }

        router.register(path: "/settings", defaultSurface: .tab) { _ in
            AnyView(SettingsView())
        }

        router.register(path: "/settings/account", defaultSurface: .tab) { _ in
            AnyView(AccountSettingsRouteView())
        }

        router.register(path: "/settings/about", defaultSurface: .tab) { _ in
            AnyView(AboutView())
        }

        router.register(path: "/settings/profile", defaultSurface: .tab) { _ in
            AnyView(ProfileSettingsRouteView())
        }
    }
}

private struct ProfileSettingsRouteView: View {
    @EnvironmentObject var router: RouteManager

    var body: some View {
        ProfileView(onLogout: {
            router.handleLogoutRequested()
        })
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
