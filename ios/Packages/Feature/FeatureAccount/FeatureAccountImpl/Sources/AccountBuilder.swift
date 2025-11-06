import SwiftUI
import FeatureAccountApi

/// Builder for Account feature views
public final class AccountBuilder: FeatureAccountBuildable {
    public init() {}

    public func makeLoginView(onLoginSuccess: @escaping () -> Void) -> AnyView {
        AnyView(LoginView(onLoginSuccess: onLoginSuccess))
    }

    public func makeRegisterView(onRegisterSuccess: @escaping () -> Void) -> AnyView {
        AnyView(RegisterView(onRegisterSuccess: onRegisterSuccess))
    }

    public func makeAccountLandingView(onSuccess: @escaping () -> Void) -> AnyView {
        AnyView(AccountLandingView(onSuccess: onSuccess))
    }
}
