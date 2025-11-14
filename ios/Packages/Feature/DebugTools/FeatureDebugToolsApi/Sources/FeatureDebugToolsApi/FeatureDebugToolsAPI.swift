import SwiftUI

/// Debug Tools Feature Builder Protocol
public protocol FeatureDebugToolsBuildable {
    /// Create the debug tools main view
    func makeDebugToolsView() -> AnyView

    /// Create the SwiftData chat debug view
    func makeChatDebugView() -> AnyView
}
