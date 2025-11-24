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
        ZStack {
            // Background gradient for RPG atmosphere
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.15, blue: 0.2),
                    Color(red: 0.15, green: 0.2, blue: 0.25)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(0.95)

            VStack(alignment: .leading, spacing: 8) {
                // Top: Status with dynamic color
                HStack(spacing: 6) {
                    Image(systemName: context.state.status.icon)
                        .font(.system(size: 20))
                        .foregroundStyle(energyColor)

                    Text(context.state.status.title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(energyColor)

                    Spacer()

                    // Buffs with rounded background
                    HStack(spacing: 4) {
                        ForEach(context.state.status.buffs, id: \.icon) { buff in
                            HStack(spacing: 2) {
                                Image(systemName: buff.icon)
                                    .font(.system(size: 12))
                                Text(buff.label)
                                    .font(.system(size: 10, weight: .medium))
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.blue.opacity(0.25))
                            )
                        }
                    }
                }

                // Middle: Task card with frosted glass effect
                HStack(alignment: .center, spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("QUEST: 光合作用")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)

                        Text(context.state.task.title)
                            .font(.system(size: 14, weight: .bold))
                            .lineLimit(1)

                        Text(context.state.task.description)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    Spacer(minLength: 6)

                    // Complete button - gold circle (smaller)
                    VStack(spacing: 1) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(red: 1, green: 0.84, blue: 0), Color(red: 1, green: 0.65, blue: 0)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 44, height: 44)
                                .shadow(color: Color.yellow.opacity(0.5), radius: 6, x: 0, y: 3)

                            Image(systemName: context.state.task.button.icon)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.white)
                        }

                        Text(context.state.task.button.label)
                            .font(.system(size: 9, weight: .semibold))
                    }
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                )

                // Bottom: Countdown with gradient progress bar
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(context.state.countdown.label)
                            .font(.system(size: 11, weight: .medium))

                        Spacer()

                        HStack(spacing: 2) {
                            Image(systemName: "clock")
                                .font(.system(size: 9))
                            Text("最佳时间: \(context.state.countdown.timeRange)")
                                .font(.system(size: 9))
                        }
                        .foregroundStyle(.secondary)
                    }

                    // Progress bar with fixed height
                    ZStack(alignment: .leading) {
                        // Background track
                        Capsule()
                            .fill(Color(.systemGray6))
                            .frame(height: 8)

                        // Progress fill with gradient
                        GeometryReader { geometry in
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 1, green: 0.84, blue: 0),
                                            Color(red: 1, green: 0.65, blue: 0)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * context.state.countdown.progress, height: 8)
                        }
                        .frame(height: 8)

                        // Sun icon at start
                        HStack {
                            Image(systemName: "sun.max.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(Color(red: 1, green: 0.84, blue: 0))
                                .padding(.leading, 3)

                            Spacer()

                            // Moon icon at end
                            Image(systemName: "moon.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                                .padding(.trailing, 3)
                        }
                    }
                    .frame(height: 8)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .widgetURL(deepLinkURL)
    }

    private var energyColor: Color {
        // Parse percentage from title
        let percentString = context.state.status.title.replacingOccurrences(of: "%", with: "")
        if let percent = Int(percentString) {
            if percent > 60 {
                return .green
            } else if percent > 30 {
                return .orange
            } else {
                return .red
            }
        }
        return .green
    }

    /// Build deep link to open app and send mock completion message
    private var deepLinkURL: URL? {
        let message = "#mock#完成\(context.state.task.title)任务"
        var components = URLComponents()
        components.scheme = "thrivebody"
        components.host = "main"
        components.queryItems = [
            URLQueryItem(name: "tab", value: "chat"),
            URLQueryItem(name: "sendmsg", value: message),
            URLQueryItem(name: "complete", value: "1")
        ]
        return components.url
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
