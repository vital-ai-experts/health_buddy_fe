import SwiftUI

struct AccountLandingView: View {
    let onSuccess: () -> Void
    @State private var showingLogin = false
    @State private var showingRegister = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                Spacer()

                // App branding
                VStack(spacing: 16) {
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 100))
                        .foregroundColor(.blue)

                    Text("ThriveBuddy")
                        .font(.system(size: 42, weight: .bold))

                    Text("Your AI Health Assistant")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Action buttons
                VStack(spacing: 16) {
                    // Login button
                    NavigationLink(destination: LoginView(onLoginSuccess: onSuccess)) {
                        Text("Sign In")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }

                    // Register button
                    NavigationLink(destination: RegisterView(onRegisterSuccess: onSuccess)) {
                        Text("Create Account")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.blue)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.blue, lineWidth: 2)
                            )
                    }

                    // Guest mode (optional)
                    Button(action: {
                        // For now, just continue without login
                        // In future, this could be a limited guest mode
                    }) {
                        Text("Continue as Guest")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
            .navigationBarHidden(true)
        }
    }
}
