import SwiftUI
import ThemeKit
import FeatureAgendaApi

/// 顶部目标列表视图
struct TopicBarView: View {
    let goals: [AgendaGoal]
    let onGoalSelected: (AgendaGoal) -> Void
    let onAddTapped: () -> Void

    private let backgroundColors: [Color] = [
        Color.Palette.infoBgSoft,
        Color.Palette.successBgSoft,
        Color.Palette.warningBgSoft,
        Color.Palette.dangerBgSoft,
    ]

    init(
        goals: [AgendaGoal],
        onGoalSelected: @escaping (AgendaGoal) -> Void,
        onAddTapped: @escaping () -> Void = {}
    ) {
        self.goals = goals
        self.onGoalSelected = onGoalSelected
        self.onAddTapped = onAddTapped
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(goals.enumerated()), id: \.element.id) { index, goal in
                    let bgColor = backgroundColors[index % backgroundColors.count]
                    GoalCircleView(goal: goal, backgroundColor: bgColor) {
                        onGoalSelected(goal)
                    }
                }

                AddGoalCircleView(action: onAddTapped)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(Color.Palette.bgBase)
    }
}

/// 单个目标圆圈视图
private struct GoalCircleView: View {
    let goal: AgendaGoal
    let backgroundColor: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .overlay(
                        Circle()
                            .stroke(Color.Palette.surfaceElevatedBorder, lineWidth: 1)
                    )
                    .frame(width: 56, height: 56)

                Text(goal.icon)
                    .font(.system(size: 24))
                    .frame(width: 32, height: 32)
            }
        }
    }
}

/// 添加目标按钮
private struct AddGoalCircleView: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.Palette.bgMuted)
                    .overlay(
                        Circle()
                            .stroke(Color.Palette.surfaceElevatedBorder, lineWidth: 1)
                    )
                    .frame(width: 56, height: 56)

                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color.Palette.textPrimary)
            }
        }
    }
}

#Preview {
    VStack {
        TopicBarView(goals: AgendaGoal.mockGoals, onGoalSelected: { _ in })
        Spacer()
    }
    .background(Color.Palette.bgBase)
}
