import SwiftUI
import FeatureAccountApi

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
}
