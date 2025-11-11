import SwiftUI
import DomainHealth
import FeatureHealthKitApi
import LibraryServiceLoader

struct HealthKitCoordinator: View {
    @State private var isAuthorized = false
    @State private var isLoading = true
    @State private var hasCheckedAuthorization = false

    private let authorizationService: AuthorizationService
    private let healthKitBuilder: FeatureHealthKitBuildable

    init(
        authorizationService: AuthorizationService = ServiceManager.shared.resolve(AuthorizationService.self),
        healthKitBuilder: FeatureHealthKitBuildable = ServiceManager.shared.resolve(FeatureHealthKitBuildable.self)
    ) {
        self.authorizationService = authorizationService
        self.healthKitBuilder = healthKitBuilder
    }

    var body: some View {
        Group {
            if isLoading {
                loadingView
            } else if isAuthorized {
                healthKitBuilder.makeDashboardView()
            } else {
                healthKitBuilder.makeAuthorizationView(onAuthorized: {
                    withAnimation {
                        isAuthorized = true
                    }
                })
            }
        }
        .onAppear {
            if !hasCheckedAuthorization {
                Task {
                    await checkAuthorization()
                }
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)

            Text("检查 HealthKit 授权状态...")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

    private func checkAuthorization() async {
        let state = await authorizationService.currentStatus()
        await MainActor.run {
            isAuthorized = (state == .authorized)
            isLoading = false
            hasCheckedAuthorization = true
        }
    }
}

#Preview {
    HealthKitDemoCoordinator()
}
