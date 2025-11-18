import SwiftUI
import LibraryServiceLoader

extension DebugToolsFeatureModule {
    static func registerRoutes(on router: RouteRegistering) {
        router.register(path: "/debug_tools") { _ in
            AnyView(DebugToolsView())
        }
    }
}
