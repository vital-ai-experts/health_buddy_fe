import ActivityKit
import Foundation
import SwiftUI
import WidgetKit
import LibraryNotification
import LibraryBase
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
    @State private var countdownStart: Date
    @State private var initialRemaining: Double
    @State private var totalSeconds: Double

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
                                    .colorScheme(.dark)
                                Text(buff.label)
                                    .font(.system(size: 10, weight: .medium))
                                    .colorScheme(.dark)
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
                        Text(context.state.task.title)
                            .font(.system(size: 14, weight: .bold))
                            .colorScheme(.dark)
                            .lineLimit(1)

                        Text(context.state.task.description)
                            .font(.system(size: 11))
                            .colorScheme(.dark)
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
                                .frame(width: 28, height: 28)
                                .shadow(color: Color.yellow.opacity(0.5), radius: 6, x: 0, y: 3)

                            Image(systemName: context.state.task.button.icon)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                        }

                        Text(context.state.task.button.label)
                            .font(.system(size: 9, weight: .semibold))
                            .colorScheme(.dark)
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

                // Bottom: Countdown with system-driven timer progress (auto-updates)
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(context.state.countdown.label)
                            .font(.system(size: 11, weight: .medium))
                            .colorScheme(.dark)

                        Spacer()

                        HStack(spacing: 2) {
                            Image(systemName: "clock")
                                .font(.system(size: 9))
                            Text("最佳时间: \(context.state.countdown.timeRange)")
                                .font(.system(size: 9))
                                .colorScheme(.dark)
                        }
                        .foregroundStyle(.secondary)
                    }

                    if let interval = timerInterval() {
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color(.systemGray6))
                                .opacity(0.4)
                                .frame(height: 8)

                            // 使用 ProgressView 的 timerInterval，叠加渐变遮罩
                            ProgressView(timerInterval: interval, countsDown: true) {
                                EmptyView()
                            } currentValueLabel: {
                                EmptyView()
                            }
                            .progressViewStyle(.linear)
                            .tint(Color.clear)
                            .frame(height: 8)
                            .overlay {
                                LinearGradient(
                                    colors: [
                                        Color(red: 1, green: 0.84, blue: 0),
                                        Color(red: 1, green: 0.65, blue: 0)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .mask(
                                    ProgressView(timerInterval: interval, countsDown: true) {
                                        EmptyView()
                                    } currentValueLabel: {
                                        EmptyView()
                                    }
                                    .progressViewStyle(.linear)
                                    .tint(Color.white)
                                )
                            }
                        }
                    } else {
                        let staticProgress = min(max(context.state.countdown.progress, 0), 1)
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color(.systemGray6))
                                .opacity(0.4)
                                .frame(height: 8)

                            GeometryReader { geometry in
                                LinearGradient(
                                    colors: [
                                        Color(red: 1, green: 0.84, blue: 0),
                                        Color(red: 1, green: 0.65, blue: 0)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .frame(width: geometry.size.width * staticProgress, height: 8)
                            }
                            .frame(height: 8)
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .widgetURL(deepLinkURL)
    }
    
    init(context: ActivityViewContext<AgendaActivityAttributes>) {
        self.context = context
        let countdown = context.state.countdown
        let startAt = countdown.startAt ?? Date()
        let remaining = Double(countdown.remainingTimeSeconds ?? 0)
        let total = Double(countdown.totalTimeSeconds ?? 0)
        let inferredRemaining: Double
        if remaining > 0 {
            inferredRemaining = remaining
        } else if total > 0 {
            inferredRemaining = max(0, total * (1 - countdown.progress))
        } else {
            inferredRemaining = 0
        }

        _countdownStart = State(initialValue: startAt)
        _initialRemaining = State(initialValue: inferredRemaining)
        _totalSeconds = State(initialValue: total > 0 ? total : (inferredRemaining > 0 ? inferredRemaining : 0))
        
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

    private func timerInterval() -> ClosedRange<Date>? {
        let countdown = context.state.countdown
        let start = countdown.startAt ?? countdownStart
        let total = totalSeconds > 0 ? totalSeconds : max(initialRemaining, 0)
        guard total > 0 else {
            return nil
        }
        let end = start.addingTimeInterval(total)
        return start...end
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
