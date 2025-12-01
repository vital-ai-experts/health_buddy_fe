import SwiftUI

struct AgendaCardView: View {
    let task: AgendaTask

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 顶部：标题和奖励
            HStack(alignment: .top, spacing: 12) {
                Text(task.emoji)
                    .font(.system(size: 28))

                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black.opacity(0.9))

                    Text(task.subtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.black.opacity(0.65))
                }

                Spacer()
            }

            // 描述
            Text(task.description)
                .font(.system(size: 14))
                .foregroundColor(.black.opacity(0.7))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            // 时间窗口
            HStack(spacing: 6) {
                Text(task.countdown)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.black.opacity(0.6))
            }
            .padding(.top, 4)

            // 操作按钮
            TaskActionButton(actionType: task.actionType, status: task.status)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.7))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
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
            HStack(spacing: 8) {
                Image(systemName: iconName)
                    .font(.system(size: 14, weight: .medium))
                Text(buttonText)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(status == .completed ? .white : .black.opacity(0.7))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor)
            )
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
            return Color(red: 0.4, green: 0.9, blue: 0.6)
        case .failed:
            return Color.gray.opacity(0.3)
        case .inProgress:
            return Color.white.opacity(0.5)
        }
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
    .background(Color(red: 0.98, green: 0.98, blue: 0.96))
}
