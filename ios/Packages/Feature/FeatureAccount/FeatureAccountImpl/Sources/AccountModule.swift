import Foundation
import SwiftUI
import LibraryServiceLoader
import FeatureAccountApi

/// Account feature module registration
public enum AccountModule {
    /// Register the Account feature
    public static func register(in manager: ServiceManager = .shared) {
        // Register builder to ServiceManager
        manager.register(FeatureAccountBuildable.self) { AccountBuilder() }
    }

    /// Register account-related routes
    /// - Parameter router: The router to register routes on
    public static func registerRoutes(on router: RouteRegistering) {
        // Login route: thrivebody://account/login
        // Can be presented as sheet (default) or push
        router.register(
            path: "/account/login",
            defaultPresentation: .sheet
        ) { context in
            let isDismissable = context.query["dismissable"] != "false"
            return AnyView(
                LoginView(
                    onLoginSuccess: {
                        // After successful login, post notification to refresh app state
                        NotificationCenter.default.post(
                            name: NSNotification.Name("LoginSuccessful"),
                            object: nil
                        )
                    },
                    isDismissable: isDismissable
                )
            )
        }

        // Register route: thrivebody://account/register
        router.register(
            path: "/account/register",
            defaultPresentation: .push
        ) { _ in
            AnyView(
                RegisterView(
                    onRegisterSuccess: {
                        // After successful registration, post notification
                        NotificationCenter.default.post(
                            name: NSNotification.Name("RegistrationSuccessful"),
                            object: nil
                        )
                    }
                )
            )
        }

        // Account settings route: thrivebody://account/settings
        router.register(
            path: "/account/settings",
            defaultPresentation: .push
        ) { _ in
            AnyView(
                AccountSettingsView(
                    onLogout: {
                        // Post logout notification to be handled by app
                        NotificationCenter.default.post(
                            name: NSNotification.Name("UserLoggedOut"),
                            object: nil
                        )
                    }
                )
            )
        }
    }
}
