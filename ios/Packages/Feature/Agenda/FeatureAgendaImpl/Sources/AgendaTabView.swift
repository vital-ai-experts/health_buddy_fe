import SwiftUI
import LibraryServiceLoader

/// Agenda 主 Tab 视图，包含占位内容
struct AgendaTabView: View {
    @EnvironmentObject private var router: RouteManager

    var body: some View {
        NavigationStack {
            AgendaPlaceholderView()
                .navigationTitle("Agenda")
        }
        .onAppear {
            router.currentTab = .agenda
        }
    }
}

/// Agenda 页面占位视图
struct AgendaPlaceholderView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checklist")
                .font(.system(size: 80))
                .foregroundColor(.gray)

            Text("Agenda")
                .font(.title)
                .fontWeight(.semibold)

            Text("Coming Soon")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}
