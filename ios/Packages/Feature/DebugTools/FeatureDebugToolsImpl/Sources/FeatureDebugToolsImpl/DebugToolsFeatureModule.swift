import SwiftUI
import LibraryServiceLoader
import FeatureDebugToolsApi

struct DebugToolsFeatureView: View {
    var body: some View {
        Text("DebugTools Feature")
    }
}

public struct DebugToolsFeatureBuilder: FeatureDebugToolsBuildable {
    public init() {}
    public func makeDebugToolsView() -> AnyView { AnyView(DebugToolsFeatureView()) }
}

public enum DebugToolsFeatureModule {
    public static func register(in manager: ServiceManager = .shared) {
        // Register builder to ServiceManager
        manager.register(FeatureDebugToolsBuildable.self) { DebugToolsFeatureBuilder() }
    }
}
