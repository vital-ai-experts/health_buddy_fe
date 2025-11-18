import SwiftUI
import LibraryServiceLoader

struct SceneRoot: View {
    @StateObject private var router: RouteManager

    init(router: RouteManager = .shared) {
        _router = StateObject(wrappedValue: router)
    }

    var body: some View {
        RootView()
            .environmentObject(router)
    }
}
