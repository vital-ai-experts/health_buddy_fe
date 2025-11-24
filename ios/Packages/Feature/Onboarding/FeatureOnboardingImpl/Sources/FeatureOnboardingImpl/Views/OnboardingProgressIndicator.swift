import SwiftUI

struct OnboardingProgressIndicator: View {
    let step: OnboardingStep

    var body: some View {
        HStack(spacing: 10) {
            ForEach(OnboardingStep.allCases, id: \.self) { current in
                Capsule()
                    .fill(current.rawValue <= step.rawValue ? Color.green.opacity(0.9) : Color.white.opacity(0.25))
                    .frame(height: 4)
            }
        }
        .padding(.vertical, 8)
        .accessibilityHidden(true)
    }
}
