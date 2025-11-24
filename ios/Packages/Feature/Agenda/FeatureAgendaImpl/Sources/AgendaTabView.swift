import SwiftUI
import LibraryServiceLoader

/// Agenda 主 Tab 视图，展示 RPG 风格的每日任务清单
struct AgendaTabView: View {
    @EnvironmentObject private var router: RouteManager

    private let viewModel = AgendaTabViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(viewModel.tasks) { task in
                        AgendaCardView(task: task)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.black.opacity(0.9), Color.blue.opacity(0.35)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle("今日任务")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            router.currentTab = .agenda
        }
    }
}

#Preview {
    AgendaTabView()
        .environmentObject(RouteManager())
        .environment(\.colorScheme, .dark)
}

// MARK: - View Model

private final class AgendaTabViewModel {
    let tasks: [AgendaTask] = AgendaTask.sampleTasks
}
