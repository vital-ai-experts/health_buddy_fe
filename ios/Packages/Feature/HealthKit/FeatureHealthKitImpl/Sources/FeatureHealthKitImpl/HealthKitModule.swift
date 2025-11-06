import SwiftUI
import FeatureHealthKitApi
import LibraryServiceLoader

public struct HealthKitBuilder: FeatureHealthKitBuildable {
    public init() {}

    public func makeAuthorizationView(onAuthorized: @escaping () -> Void) -> AnyView {
        AnyView(AuthorizationFeatureView(onAuthorized: onAuthorized))
    }

    public func makeDashboardView() -> AnyView {
        AnyView(DashboardFeatureView())
    }

    public func makeHealthKitTabView() -> AnyView {
        AnyView(HealthKitCoordinator())
    }
}

public enum HealthKitModule {
    public static func register(in manager: ServiceManager = .shared) {
        // Register builder to ServiceManager
        manager.register(FeatureHealthKitBuildable.self) { HealthKitBuilder() }
    }
}
