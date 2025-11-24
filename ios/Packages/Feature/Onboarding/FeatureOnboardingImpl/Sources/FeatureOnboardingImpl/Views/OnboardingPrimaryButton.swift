import SwiftUI

struct OnboardingPrimaryButton: View {
    let title: String
    let isDisabled: Bool
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .fontWeight(.semibold)
                Spacer()
                if isLoading {
                    ProgressView()
                        .tint(.black)
                } else {
                    Image(systemName: "arrow.right")
                        .font(.headline.weight(.bold))
                }
            }
            .foregroundColor(.black)
            .padding()
            .background(buttonBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: Color.green.opacity(0.35), radius: 12, y: 6)
        }
        .disabled(isDisabled)
    }

    private var buttonBackground: Color {
        isDisabled ? Color.white.opacity(0.35) : Color.green.opacity(0.95)
    }
}
