import SwiftUI

/// Builder protocol for Onboarding feature
public protocol FeatureOnboardingBuildable {
    /// Build the onboarding view
    /// - Parameter onComplete: Callback when onboarding is completed
    func makeOnboardingView(onComplete: @escaping () -> Void) -> AnyView
}
