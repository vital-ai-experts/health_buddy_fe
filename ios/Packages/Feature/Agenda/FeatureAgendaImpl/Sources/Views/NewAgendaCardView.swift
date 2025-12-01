import SwiftUI

/// 新设计的任务卡片视图
struct NewAgendaCardView: View {
    let task: AgendaTask

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 顶部：图标、标题、奖励
            HStack(alignment: .top, spacing: 12) {
                Text(task.icon)
                    .font(.system(size: 32))

                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.black)

                    Text(task.reward)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.black.opacity(0.5))
                }

                Spacer()
            }
            .padding(.bottom, 12)

            // 任务描述
            Text(task.description)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.black.opacity(0.7))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 12)

            // 时间标签
            HStack(spacing: 4) {
                Text("⏳")
                    .font(.system(size: 12))
                Text(task.timeTag)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.black.opacity(0.6))
            }
            .padding(.bottom, 12)

            // 操作按钮
            if task.completed {
                CompletedIndicator()
            } else {
                ActionButton(actionType: task.actionType)
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

/// 完成指示器
private struct CompletedIndicator: View {
    var body: some View {
        HStack(spacing: 8) {
            Text("✅")
                .font(.system(size: 16))
            Text("已完成")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.black.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.green.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

/// 操作按钮
private struct ActionButton: View {
    let actionType: TaskActionType

    var body: some View {
        HStack(spacing: 8) {
            Text(actionType.icon)
                .font(.system(size: 16))
            Text(actionType.actionText)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.black)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.black.opacity(0.15), lineWidth: 1.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    VStack(spacing: 16) {
        ForEach(Array(AgendaTask.sampleTasks.prefix(3))) { task in
            NewAgendaCardView(task: task)
        }
    }
    .padding()
    .background(Color(red: 0.96, green: 0.96, blue: 0.94))
}
