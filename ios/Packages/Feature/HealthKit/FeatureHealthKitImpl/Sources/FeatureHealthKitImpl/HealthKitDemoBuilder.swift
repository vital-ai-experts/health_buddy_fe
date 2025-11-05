import SwiftUI
import FeatureHealthKitApi

public struct HealthKitDemoBuilder {
    public init() {}

    public func makeHealthKitDemoView() -> AnyView {
        AnyView(HealthKitDemoCoordinator())
    }
}
