import SwiftUI
import LibraryServiceLoader

/// Agenda 主 Tab 视图，展示健康管理任务清单
struct AgendaTabView: View {
    @EnvironmentObject private var router: RouteManager

    private let viewModel = AgendaTabViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // 顶部话题列表
                TopicBarView(topics: viewModel.topics)

                // 今天 - 全局状态区
                TodayStatusView(healthStatus: viewModel.healthStatus)
                    .padding(.bottom, 20)

                // 专家简报
                ExpertInsightView(insight: viewModel.healthStatus.expertInsight)
                    .padding(.bottom, 32)

                // 任务标题
                Text("任务")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.black.opacity(0.9))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                // 任务列表
                VStack(spacing: 16) {
                    ForEach(viewModel.tasks) { task in
                        AgendaCardView(task: task)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
        .background(Color(red: 0.98, green: 0.98, blue: 0.96))
        .ignoresSafeArea(edges: .top)
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
    let topics: [AgendaTopic] = AgendaTopic.sampleTopics
    let healthStatus: HealthStatus = HealthStatus.sample
    let tasks: [AgendaTask] = AgendaTask.sampleTasks
}
