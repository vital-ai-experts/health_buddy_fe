import SwiftUI

public protocol FeatureHealthKitBuildable {
    func makeAuthorizationView(onAuthorized: @escaping () -> Void) -> AnyView
    func makeDashboardView() -> AnyView
    func makeHealthKitDemoView() -> AnyView
}
