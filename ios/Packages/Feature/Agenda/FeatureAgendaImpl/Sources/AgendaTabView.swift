import SwiftUI
import LibraryServiceLoader

/// Agenda 主 Tab 视图，展示健康管理每日任务
struct AgendaTabView: View {
    @EnvironmentObject private var router: RouteManager

    private let viewModel = AgendaTabViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // 顶部话题列表
                TopicListView(topics: viewModel.topics)
                    .padding(.top, 16)
                    .padding(.bottom, 24)

                // 全局状态区（"今天"模块）
                TodayStatusView(
                    bodyStatus: viewModel.bodyStatus,
                    expertInsight: viewModel.expertInsight
                )
                .padding(.bottom, 32)

                // 任务列表
                VStack(alignment: .leading, spacing: 16) {
                    Text("任务")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 24)

                    ForEach(viewModel.tasks) { task in
                        NewAgendaCardView(task: task)
                            .padding(.horizontal, 24)
                    }
                }
                .padding(.bottom, 32)
            }
        }
        .background(Color(red: 0.96, green: 0.96, blue: 0.94))
        .onAppear {
            router.currentTab = .agenda
        }
    }
}

#Preview {
    AgendaTabView()
        .environmentObject(RouteManager())
}

// MARK: - View Model

private final class AgendaTabViewModel {
    let topics: [Topic] = Topic.sampleTopics
    let bodyStatus: BodyStatus = .sample
    let expertInsight: ExpertInsight = .sample
    let tasks: [AgendaTask] = AgendaTask.sampleTasks
}
