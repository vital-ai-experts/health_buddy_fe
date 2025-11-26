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

                    // Display "状态名称 值" format
                    HStack(spacing: 4) {
                        Text(context.state.status.name)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(energyColor)

                        Text(context.state.status.value)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(energyColor)
                    }

                    Spacer()

                    // Buffs with type-specific colors
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
                                    .fill(buffBackgroundColor(for: buff.type))
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
        // Parse percentage from value
        let percentString = context.state.status.value.replacingOccurrences(of: "%", with: "")
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

    /// Returns background color for different buff types
    private func buffBackgroundColor(for type: AgendaActivityAttributes.ContentState.BuffType) -> Color {
        switch type {
        case .positive:
            // Positive buffs: green/gold tones
            return Color.green.opacity(0.3)
        case .negative:
            // Negative buffs/debuffs: red/purple tones
            return Color.red.opacity(0.3)
        case .neutral:
            // Neutral buffs: blue/gray tones
            return Color.blue.opacity(0.25)
        }
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
    // Preview state 1: 光子锚定 - 早晨任务
    AgendaActivityAttributes.ContentState(
        status: .init(
            type: "energy",
            name: "电量",
            value: "30%",
            icon: "battery.25",
            buffs: [
                .init(type: .negative, icon: "moon.stars.fill", label: "褪黑素残留")
            ]
        ),
        task: .init(
            title: "任务：采集光子",
            description: "去窗边/户外晒 5 分钟。向视网膜发送信号，定好今晚的入睡闹钟。",
            button: .init(label: "完成", icon: "checkmark")
        ),
        countdown: .init(
            label: "⏳ 剩余 15 分钟",
            timeRange: "08:00 - 12:00",
            progressColor: "#FFD700",
            progress: 0.75,
            remainingTimeSeconds: 900
        )
    )

    // Preview state 2: 脑部补水任务
    AgendaActivityAttributes.ContentState(
        status: .init(
            type: "brain",
            name: "脑力",
            value: "40%",
            icon: "brain.head.profile",
            buffs: [
                .init(type: .negative, icon: "drop.slash.fill", label: "大脑干旱")
            ]
        ),
        task: .init(
            title: "任务：填充冷却液",
            description: "喝一杯 300ml 温水。让\"缩水\"的脑组织重新膨胀，提升反应速度。",
            button: .init(label: "完成", icon: "checkmark")
        ),
        countdown: .init(
            label: "⏳ 剩余 10 分钟",
            timeRange: "全天",
            progressColor: "#FFD700",
            progress: 0.5,
            remainingTimeSeconds: 600
        )
    )

    // Preview state 3: 压力释放任务
    AgendaActivityAttributes.ContentState(
        status: .init(
            type: "cpu",
            name: "CPU",
            value: "过热",
            icon: "flame.fill",
            buffs: [
                .init(type: .negative, icon: "exclamationmark.triangle.fill", label: "情绪脑劫持")
            ]
        ),
        task: .init(
            title: "任务：系统强制冷却",
            description: "执行\"生理叹息\"（两吸一呼），只需 60 秒，强制重启副交感神经。",
            button: .init(label: "完成", icon: "checkmark")
        ),
        countdown: .init(
            label: "⏳ 立即执行",
            timeRange: "现在",
            progressColor: "#FFD700",
            progress: 0.9,
            remainingTimeSeconds: 60
        )
    )
}
