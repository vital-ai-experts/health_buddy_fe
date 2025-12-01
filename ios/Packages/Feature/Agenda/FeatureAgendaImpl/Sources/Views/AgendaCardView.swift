import SwiftUI
import ThemeKit

struct AgendaCardView: View {
    let task: AgendaTask

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 顶部：标题和奖励
            HStack(alignment: .center, spacing: 12) {
                Text(task.emoji)
                    .font(.system(size: 28))

                Text(task.title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.Palette.textPrimary)

                Spacer()
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.reward)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.Palette.textPrimary)
//                    Text(task.rewardDescription)
//                        .font(.system(size: 10, weight: .medium))
//                        .foregroundColor(.black.opacity(0.6))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.Palette.warningBgSoft)
                .cornerRadius(12)
            }

            HStack(alignment: .top, spacing: 0) {
                Text(task.description)
                    .font(.system(size: 14))
                    .foregroundColor(.Palette.textSecondary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(3)

                Spacer()
                
                // 操作按钮（圆形 + 文本）
                TaskActionButton(actionType: task.actionType, status: task.status)
            }
            
            // 时间窗口 + 进度
            VStack(alignment: .leading, spacing: 6) {
                Text(task.timeWindow)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.Palette.textSecondary)

                ProgressView(value: clampedProgress)
                    .progressViewStyle(.linear)
                    .tint(Color.Palette.warningMain)
                    .background(Color.Palette.warningBgSoft.opacity(0.6))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.Palette.surfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.Palette.surfaceElevatedBorder, lineWidth: 1)
        )
        .shadow(color: Color.Palette.textPrimary.opacity(0.08), radius: 8, x: 0, y: 4)
    }

    private var clampedProgress: Double {
        min(max(task.progress, 0), 1)
    }
}

/// 任务操作按钮
private struct TaskActionButton: View {
    let actionType: AgendaTask.TaskActionType
    let status: AgendaTaskStatus

    var body: some View {
        Button(action: {
            // TODO: 处理任务操作
        }) {
            VStack(spacing: 6) {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: iconName)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(iconColor)
                    )

                Text(buttonText)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.Palette.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .frame(maxWidth: 60)
            }
        }
        .disabled(status == .failed)
    }

    private var iconName: String {
        switch actionType {
        case .photo: return "camera.fill"
        case .check: return "checkmark.circle.fill"
        case .play: return "play.circle.fill"
        case .sync: return "arrow.triangle.2.circlepath"
        }
    }

    private var buttonText: String {
        switch actionType {
        case .photo(let text): return text
        case .check(let text): return text
        case .play(let text): return text
        case .sync(let text): return text
        }
    }

    private var backgroundColor: Color {
        switch status {
        case .completed:
            return Color.Palette.successMain
        case .failed:
            return Color.Palette.textDisabled.opacity(0.4)
        case .inProgress:
            return Color.Palette.successBgSoft
        }
    }

    private var iconColor: Color {
        status == .completed ? Color.Palette.textOnAccent : Color.Palette.textSecondary
    }
}

#Preview {
    let samples = AgendaTask.sampleTasks

    return ScrollView {
        VStack(spacing: 16) {
            ForEach(Array(samples.prefix(3))) { task in
                AgendaCardView(task: task)
            }
        }
        .padding()
    }
    .background(Color.Palette.bgBase)
}
