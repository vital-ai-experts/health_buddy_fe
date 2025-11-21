import ActivityKit
import Foundation
import SwiftUI
import WidgetKit
import LibraryNotification
import AppIntents

/// Live Activity Widget for Agenda
@available(iOS 16.1, *)
struct AgendaLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AgendaActivityAttributes.self) { context in
            // Lock screen UI
            AgendaLiveActivityView(context: context)
                .activityBackgroundTint(Color.blue.opacity(0.1))
                .activitySystemActionForegroundColor(Color.blue)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded region
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "heart.circle.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.blue, .white)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.purple)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(context.state.task.title)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(context.state.task.description)
                            .font(.body)
                            .fontWeight(.semibold)
                            .lineLimit(2)
                    }
                    .padding(.horizontal)
                }
            } compactLeading: {
                Image(systemName: "heart.circle.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.blue, .white)
            } compactTrailing: {
                Text("✨")
                    .font(.caption2)
            } minimal: {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.blue)
            }
        }
    }
}

/// Main view for the Live Activity on lock screen
@available(iOS 16.1, *)
struct AgendaLiveActivityView: View {
    let context: ActivityViewContext<AgendaActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Top: Status
            HStack {
                Image(systemName: context.state.status.icon)
                Text(context.state.status.title)
                    .font(.title2.bold())

                Spacer()

                ForEach(context.state.status.buffs, id: \.icon) { buff in
                    HStack(spacing: 2) {
                        Image(systemName: buff.icon)
                            .font(.caption)
                        Text(buff.label)
                            .font(.caption)
                    }
                }
            }

            // Middle: Task
            VStack(alignment: .leading, spacing: 4) {
                Text(context.state.task.title)
                    .font(.headline)
                Text(context.state.task.description)
                    .font(.caption)
                    .lineLimit(2)
            }

            // Bottom: Countdown
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(context.state.countdown.label)
                        .font(.caption2)
                    Spacer()
                    Text(context.state.countdown.timeRange)
                        .font(.caption2)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 4)

                        Capsule()
                            .fill(Color.yellow)
                            .frame(width: geometry.size.width * context.state.countdown.progress, height: 4)
                    }
                }
                .frame(height: 4)
            }
        }
        .padding()
    }
}


// MARK: - Preview

@available(iOS 16.1, *)
#Preview("Live Activity", as: .content, using: AgendaActivityAttributes(userId: "preview")) {
    AgendaLiveActivity()
} contentStates: {
    // Preview state 1: Morning sunlight quest
    AgendaActivityAttributes.ContentState(
        status: .init(
            type: "energy",
            title: "30%",
            icon: "battery.25",
            buffs: [
                .init(icon: "moon.stars.fill", label: "褪黑素")
            ]
        ),
        task: .init(
            title: "去阳台进行光合作用",
            description: "别让你的生物钟以为还在深夜。哪怕只把脸伸出去晒 5 分钟,今晚入睡都能快半小时。",
            button: .init(label: "完成", icon: "checkmark")
        ),
        countdown: .init(
            label: "日照充能窗口",
            timeRange: "08:00 - 12:00",
            progressColor: "#FFD700",
            progress: 0.6,
            remainingTimeSeconds: 1200
        )
    )

    // Preview state 2: High energy state
    AgendaActivityAttributes.ContentState(
        status: .init(
            type: "energy",
            title: "85%",
            icon: "battery.100",
            buffs: [
                .init(icon: "sun.max.fill", label: "活力"),
                .init(icon: "leaf.fill", label: "专注")
            ]
        ),
        task: .init(
            title: "完成深度工作任务",
            description: "你的能量和注意力都处于最佳状态,现在是完成重要工作的黄金时间。",
            button: .init(label: "完成", icon: "checkmark")
        ),
        countdown: .init(
            label: "专注时段",
            timeRange: "09:00 - 11:00",
            progressColor: "#4CAF50",
            progress: 0.35,
            remainingTimeSeconds: 3600
        )
    )
}
