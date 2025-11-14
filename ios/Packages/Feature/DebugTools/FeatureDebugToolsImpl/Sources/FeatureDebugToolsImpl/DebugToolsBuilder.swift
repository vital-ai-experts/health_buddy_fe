import SwiftUI
import FeatureDebugToolsApi

public final class DebugToolsBuilder: FeatureDebugToolsBuildable {
    public init() {}

    public func makeDebugToolsView() -> AnyView {
        AnyView(DebugToolsView())
    }
}
