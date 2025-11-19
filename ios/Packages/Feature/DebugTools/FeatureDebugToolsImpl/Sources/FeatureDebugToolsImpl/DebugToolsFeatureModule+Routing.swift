import SwiftUI
import LibraryServiceLoader

extension DebugToolsFeatureModule {
    static func registerRoutes(on router: RouteRegistering) {
        router.register(path: "/debug_tools", defaultPresentation: .push) { _ in
            AnyView(DebugToolsView())
        }
    }
}
