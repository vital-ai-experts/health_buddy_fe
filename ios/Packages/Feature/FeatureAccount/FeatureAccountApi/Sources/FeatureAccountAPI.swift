import SwiftUI

/// Builder protocol for Account feature
public protocol FeatureAccountBuildable {
    /// Build the login view
    /// - Parameters:
    ///   - onLoginSuccess: Callback when login succeeds
    ///   - isDismissable: Whether the view can be dismissed (default: true)
    func makeLoginView(onLoginSuccess: @escaping () -> Void, isDismissable: Bool) -> AnyView

    /// Build the registration view
    func makeRegisterView(onRegisterSuccess: @escaping () -> Void) -> AnyView

    /// Build the account landing view (with login/register options)
    /// - Parameters:
    ///   - onSuccess: Callback when auth succeeds
    ///   - isDismissable: Whether the view can be dismissed (default: true)
    func makeAccountLandingView(onSuccess: @escaping () -> Void, isDismissable: Bool) -> AnyView
}
