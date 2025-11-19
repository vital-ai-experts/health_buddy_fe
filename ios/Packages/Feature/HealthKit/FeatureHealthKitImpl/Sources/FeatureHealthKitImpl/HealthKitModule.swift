import SwiftUI
import FeatureHealthKitApi
import LibraryServiceLoader
import DomainHealth

public struct HealthKitBuilder: FeatureHealthKitBuildable {
    public init() {}

    public func makeAuthorizationView(onAuthorized: @escaping () -> Void) -> AnyView {
        AnyView(AuthorizationFeatureView(onAuthorized: onAuthorized))
    }

    public func makeDashboardView() -> AnyView {
        AnyView(DashboardFeatureView())
    }

    public func makeHealthKitTabView() -> AnyView {
        AnyView(HealthKitTabView())
    }
}

/// HealthKit 的 Tab 包装器，带有独立的 NavigationStack
private struct HealthKitTabView: View {
    @EnvironmentObject var router: RouteManager

    var body: some View {
        NavigationStack(path: $router.healthPath) {
            HealthKitCoordinator(
                authorizationService: ServiceManager.shared.resolve(AuthorizationService.self),
                healthKitBuilder: ServiceManager.shared.resolve(FeatureHealthKitBuildable.self)
            )
            .navigationDestination(for: RouteMatch.self) { match in
                print("[HealthTab] navigationDestination: \(match.path)")
                return router.buildView(for: match)
            }
        }
        .onAppear {
            // 更新当前 tab
            router.currentTab = .health
        }
    }
}

public enum HealthKitModule {
    public static func register(in manager: ServiceManager = .shared) {
        // Register builder to ServiceManager
        manager.register(FeatureHealthKitBuildable.self) { HealthKitBuilder() }
    }
}
