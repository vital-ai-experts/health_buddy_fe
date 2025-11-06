import SwiftUI

/// Builder protocol for Account feature
public protocol FeatureAccountBuildable {
    /// Build the login view
    func makeLoginView(onLoginSuccess: @escaping () -> Void) -> AnyView

    /// Build the registration view
    func makeRegisterView(onRegisterSuccess: @escaping () -> Void) -> AnyView

    /// Build the account landing view (with login/register options)
    func makeAccountLandingView(onSuccess: @escaping () -> Void) -> AnyView
}
