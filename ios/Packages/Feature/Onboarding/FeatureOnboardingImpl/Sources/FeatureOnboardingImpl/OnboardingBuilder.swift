import SwiftUI
import FeatureOnboardingApi

/// Builder for Onboarding feature views
public final class OnboardingBuilder: FeatureOnboardingBuildable {
    public init() {}
    
    public func makeOnboardingView(onComplete: @escaping () -> Void) -> AnyView {
        AnyView(OnboardingView(onComplete: onComplete))
    }
}

