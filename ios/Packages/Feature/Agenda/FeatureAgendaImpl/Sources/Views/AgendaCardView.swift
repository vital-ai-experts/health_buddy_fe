import SwiftUI

struct AgendaCardView: View {
    let task: AgendaTask

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text(task.title)
                    .font(.title3).bold()
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(task.subtitle)
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(2)

                if !task.tags.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(task.tags, id: \.self) { tag in
                            label(text: tag, systemImage: "shield.fill", color: .orange)
                        }
                    }
                }
            }

            Spacer(minLength: 6)

            VStack(alignment: .center, spacing: 6) {
                Button(action: {}) {
                    Text(buttonTitle(for: task.status))
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .foregroundColor(buttonStyle(for: task.status).foreground)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(buttonStyle(for: task.status).background)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(buttonStyle(for: task.status).border, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 3)
                .disabled(task.status == .failed)

                Text(statusText(for: task.status, countdown: task.countdown))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.85))
            }
            .frame(width: 100, alignment: .trailing)
        }
        .padding(12)
        .background(task.accent.gradient)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.35), radius: 12, x: 0, y: 8)
    }

    private func label(text: String, systemImage: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: systemImage)
            Text(text)
        }
        .font(.caption2)
        .foregroundColor(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color.black.opacity(0.25))
        .clipShape(Capsule())
    }

    private func buttonTitle(for status: AgendaTaskStatus) -> String {
        switch status {
        case .completed:
            return "领取奖励"
        case .failed:
            return "已失效"
        case .inProgress:
            return "去完成"
        }
    }

    private func buttonStyle(for status: AgendaTaskStatus) -> (background: Color, foreground: Color, border: Color) {
        switch status {
        case .completed:
            return (
                background: Color(red: 1.0, green: 0.82, blue: 0.3), // 更浓的金色
                foreground: .black,
                border: Color.white.opacity(0.6)
            )
        case .inProgress:
            return (
                background: Color.yellow.opacity(0.65),             // 更浅的黄
                foreground: .black,
                border: Color.black.opacity(0.08)
            )
        case .failed:
            return (
                background: Color.gray.opacity(0.55),               // 更明显的灰
                foreground: .white.opacity(0.85),
                border: Color.black.opacity(0.2)
            )
        }
    }

    private func statusText(for status: AgendaTaskStatus, countdown: String) -> String {
        switch status {
        case .completed:
            return "已完成"
        case .failed:
            return "任务已过期"
        case .inProgress:
            return countdown
        }
    }
}

#Preview {
    let samples = AgendaTask.sampleTasks

    return VStack(spacing: 16) {
        ForEach(Array(samples.prefix(4))) { task in
            AgendaCardView(task: task)
        }
    }
    .padding()
    .background(
        LinearGradient(
            gradient: Gradient(colors: [Color.black.opacity(0.92), Color.blue.opacity(0.4)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
    .environment(\.colorScheme, .dark)
}
