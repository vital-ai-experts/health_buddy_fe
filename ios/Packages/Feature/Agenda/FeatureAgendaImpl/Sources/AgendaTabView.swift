import SwiftUI
import LibraryServiceLoader
import FeatureAgendaApi
import ThemeKit

/// Agenda 主 Tab 视图，展示健康管理任务清单
struct AgendaTabView: View {
    @EnvironmentObject private var router: RouteManager

    private let viewModel = AgendaTabViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // 顶部目标列表
                TopicBarView(
                    goals: viewModel.goals,
                    onGoalSelected: handleGoalSelection,
                    onAddTapped: handleAddGoalTapped
                )

                // 此刻 - 全局状态区
                TodayStatusView(healthStatus: viewModel.healthStatus)
                    .padding(.bottom, 20)

                // 专家简报
                ExpertInsightView(insight: viewModel.healthStatus.expertInsight)
                    .padding(.bottom, 32)

                // 任务标题
                Text("任务")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.Palette.textPrimary)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                // 任务列表
                VStack(spacing: 16) {
                    ForEach(viewModel.tasks) { task in
                        AgendaCardView(task: task)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 56)
            }
        }
        .background(Color.Palette.bgBase)
        .onAppear {
            router.currentTab = .agenda
        }
    }

    private func handleGoalSelection(_ goal: AgendaGoal) {
        viewModel.setDefaultGoal(goal.id)
        if let chatURL = router.buildURL(
            path: "/chat",
            queryItems: [
                "goalId": goal.id
            ]
        ) {
            router.open(url: chatURL)
        }
    }

    private func handleAddGoalTapped() {
        // 预留：未来可跳转到新增目标页面
    }
}

#Preview {
    AgendaTabView()
        .environmentObject(RouteManager())
}

// MARK: - View Model

private final class AgendaTabViewModel {
    private let goalManager: AgendaGoalManaging

    init(goalManager: AgendaGoalManaging = ServiceManager.shared.resolve(AgendaGoalManaging.self)) {
        self.goalManager = goalManager
    }

    var goals: [AgendaGoal] {
        goalManager.goals
    }

    func setDefaultGoal(_ goalId: String) {
        goalManager.defaultSelectedGoalId = goalId
    }

    let healthStatus: HealthStatus = HealthStatus.randomSample()
    let tasks: [AgendaTask] = AgendaTask.sampleTasks
}
