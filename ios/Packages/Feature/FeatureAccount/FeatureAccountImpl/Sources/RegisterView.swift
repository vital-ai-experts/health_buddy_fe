import SwiftUI
import DomainAuth
import FeatureOnboardingApi
import LibraryServiceLoader

struct RegisterView: View {
    @StateObject private var viewModel: RegisterViewModel
    let onRegisterSuccess: () -> Void

    init(onRegisterSuccess: @escaping () -> Void) {
        let authService = ServiceManager.shared.resolve(AuthenticationService.self)
        let onboardingManager = ServiceManager.shared.resolve(OnboardingStateManaging.self)
        _viewModel = StateObject(wrappedValue: RegisterViewModel(
            authService: authService,
            onboardingManager: onboardingManager
        ))
        self.onRegisterSuccess = onRegisterSuccess
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "person.badge.plus.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)

                    Text("Create Account")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Join us today")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)

                // Form
                VStack(spacing: 16) {
                    // Full name field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Full Name")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        TextField("Enter your full name", text: $viewModel.fullName)
                            .textFieldStyle(.plain)
                            .textContentType(.name)
                            .autocapitalization(.words)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }

                    // Email field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        TextField("Enter your email", text: $viewModel.email)
                            .textFieldStyle(.plain)
                            .textContentType(.emailAddress)
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
                            .textContentType(.newPassword)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)

                        Text("Password must be at least 6 characters")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Confirm password field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confirm Password")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        SecureField("Confirm your password", text: $viewModel.confirmPassword)
                            .textFieldStyle(.plain)
                            .textContentType(.newPassword)
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

                    // Register button
                    Button(action: {
                        Task {
                            await viewModel.register()
                            if viewModel.isRegisterSuccessful {
                                onRegisterSuccess()
                            }
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Create Account")
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
        .navigationTitle("Register")
    }
}

@MainActor
final class RegisterViewModel: ObservableObject {
    @Published var fullName = ""
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var isRegisterSuccessful = false

    private let authService: AuthenticationService
    private let onboardingManager: OnboardingStateManaging

    var isFormValid: Bool {
        !fullName.isEmpty &&
        !email.isEmpty &&
        email.contains("@") &&
        password.count >= 6 &&
        password == confirmPassword
    }

    init(authService: AuthenticationService, onboardingManager: OnboardingStateManaging) {
        self.authService = authService
        self.onboardingManager = onboardingManager
    }

    func register() async {
        guard isFormValid else {
            errorMessage = "Please fill in all fields correctly"
            return
        }

        // 获取 onboarding_id
        guard let onboardingId = onboardingManager.getOnboardingID() else {
            errorMessage = "Onboarding ID not found. Please restart the onboarding process."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            _ = try await authService.register(email: email, password: password, fullName: fullName, onboardingId: onboardingId)
            isRegisterSuccessful = true
            // 注册成功后清除 onboarding_id
            onboardingManager.clearOnboardingID()
        } catch {
            errorMessage = error.localizedDescription
            isRegisterSuccessful = false
        }

        isLoading = false
    }
}
