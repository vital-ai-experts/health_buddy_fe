import SwiftUI
import ThemeKit

struct AccountLandingView: View {
    let onSuccess: () -> Void
    let isDismissable: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var showingLogin = false
    @State private var showingRegister = false

    init(onSuccess: @escaping () -> Void, isDismissable: Bool = true) {
        self.onSuccess = onSuccess
        self.isDismissable = isDismissable
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                Spacer()

                // App branding
                VStack(spacing: 16) {
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 100))
                        .foregroundColor(.Palette.infoMain)

                    Text("ThriveBody")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(.Palette.textPrimary)

                    Text("Your AI Health Assistant")
                        .font(.title3)
                        .foregroundColor(.Palette.textSecondary)
                }

                Spacer()

                // Action buttons
                VStack(spacing: 16) {
                    // Login button
                    NavigationLink(destination: LoginView(onLoginSuccess: onSuccess, isDismissable: false)) {
                        Text("Sign In")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.Palette.infoMain)
                            .foregroundColor(.Palette.textOnAccent)
                            .cornerRadius(12)
                    }

                    // Register button
                    NavigationLink(destination: RegisterView(onRegisterSuccess: onSuccess)) {
                        Text("Create Account")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.Palette.bgBase)
                            .foregroundColor(.Palette.infoMain)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.Palette.infoMain, lineWidth: 2)
                            )
                    }

                    // Guest mode (optional)
                    Button(action: {
                        // For now, just continue without login
                        // In future, this could be a limited guest mode
                    }) {
                        Text("Continue as Guest")
                            .font(.subheadline)
                            .foregroundColor(.Palette.textSecondary)
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
            .background(Color.Palette.bgBase)
            .navigationBarHidden(!isDismissable)
            .toolbar {
                if isDismissable {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("关闭") {
                            dismiss()
                        }
                    }
                }
            }
            .interactiveDismissDisabled(!isDismissable)
        }
    }
}
