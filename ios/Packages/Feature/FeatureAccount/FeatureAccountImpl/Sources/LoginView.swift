import SwiftUI
import DomainAuth
import LibraryServiceLoader

struct LoginView: View {
    @StateObject private var viewModel: LoginViewModel
    @Environment(\.dismiss) private var dismiss
    let onLoginSuccess: () -> Void
    let isDismissable: Bool

    init(onLoginSuccess: @escaping () -> Void, isDismissable: Bool = true) {
        let authService = ServiceManager.shared.resolve(AuthenticationService.self)
        _viewModel = StateObject(wrappedValue: LoginViewModel(authService: authService))
        self.onLoginSuccess = onLoginSuccess
        self.isDismissable = isDismissable
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)

                        Text("Welcome Back")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Sign in to continue")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)

                // Form
                VStack(spacing: 16) {
                    // Email field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        TextField("Enter your email", text: $viewModel.email)
                            .textFieldStyle(.plain)
                            .textContentType(.username)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }

                    // Password field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        SecureField("Enter your password", text: $viewModel.password)
                            .textFieldStyle(.plain)
                            .textContentType(.password)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }

                    // Error message
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Login button
                    Button(action: {
                        Task {
                            await viewModel.login()
                            if viewModel.isLoginSuccessful {
                                onLoginSuccess()
                            }
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Sign In")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.isFormValid ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(!viewModel.isFormValid || viewModel.isLoading)
                }
                .padding(.horizontal, 24)

                Spacer()
            }
        }
        .navigationTitle("Login")
        .navigationBarTitleDisplayMode(.inline)
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

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var isLoginSuccessful = false

    private let authService: AuthenticationService

    var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && email.contains("@")
    }

    init(authService: AuthenticationService) {
        self.authService = authService
    }

    func login() async {
        guard isFormValid else { return }

        isLoading = true
        errorMessage = nil

        do {
            _ = try await authService.login(email: email, password: password)
            isLoginSuccessful = true
        } catch {
            errorMessage = error.localizedDescription
            isLoginSuccessful = false
        }

        isLoading = false
    }
}
