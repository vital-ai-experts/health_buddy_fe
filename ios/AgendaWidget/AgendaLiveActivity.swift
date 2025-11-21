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
        VStack(spacing: 12) {
            // Top Status Section
            TopStatusView(status: context.state.status)

            // Middle Task Section
            TaskSectionView(task: context.state.task)

            // Bottom Countdown Section
            CountdownSectionView(countdown: context.state.countdown)
        }
        .padding(16)
    }
}

// MARK: - Top Status Section
@available(iOS 16.1, *)
struct TopStatusView: View {
    let status: AgendaActivityAttributes.ContentState.StatusInfo

    var body: some View {
        HStack(spacing: 12) {
            // Left Side - Energy Status
            HStack(spacing: 8) {
                Image(systemName: status.icon)
                    .font(.system(size: 24))
                    .foregroundStyle(energyColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(status.title)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(energyColor)

                    Text("Energy")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Right Side - Buffs
            HStack(spacing: 8) {
                ForEach(Array(status.buffs.enumerated()), id: \.offset) { _, buff in
                    BuffIconView(buff: buff)
                }
            }
        }
    }

    private var energyColor: Color {
        // Parse percentage from title (e.g., "30%")
        if let percentString = status.title.replacingOccurrences(of: "%", with: ""),
           let percent = Int(percentString) {
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
}

@available(iOS 16.1, *)
struct BuffIconView: View {
    let buff: AgendaActivityAttributes.ContentState.BuffInfo

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: buff.icon)
                .font(.system(size: 18))
                .foregroundStyle(.blue)

            Text(buff.label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.15))
        )
    }
}

// MARK: - Middle Task Section
@available(iOS 16.1, *)
struct TaskSectionView: View {
    let task: AgendaActivityAttributes.ContentState.TaskInfo

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Left Side - Task Text
            VStack(alignment: .leading, spacing: 8) {
                // Quest Label
                Text("QUEST: 光合作用")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                // Task Title
                Text(task.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                // Task Description
                Text(task.description)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }

            Spacer(minLength: 8)

            // Right Side - Complete Button
            CompleteButtonView(button: task.button)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground).opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

@available(iOS 16.1, *)
struct CompleteButtonView: View {
    let button: AgendaActivityAttributes.ContentState.ButtonInfo

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.yellow, Color.orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)
                    .shadow(color: Color.yellow.opacity(0.4), radius: 8, x: 0, y: 4)

                Image(systemName: button.icon)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
            }

            Text(button.label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.primary)
        }
    }
}

// MARK: - Bottom Countdown Section
@available(iOS 16.1, *)
struct CountdownSectionView: View {
    let countdown: AgendaActivityAttributes.ContentState.CountdownInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Label and Time Range
            HStack {
                Text(countdown.label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 11))
                    Text("最佳时间: \(countdown.timeRange)")
                        .font(.system(size: 11))
                }
                .foregroundStyle(.secondary)
            }

            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    Capsule()
                        .fill(Color(.systemGray5))
                        .frame(height: 8)

                    // Progress Fill
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [hexToColor(countdown.progressColor), hexToColor(countdown.progressColor).opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * countdown.progress, height: 8)

                    // Sun icon at start
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(hexToColor(countdown.progressColor))
                        .offset(x: 4)

                    // Moon icon at end
                    Image(systemName: "moon.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .offset(x: geometry.size.width - 18)
                }
            }
            .frame(height: 8)
        }
    }

    private func hexToColor(_ hex: String) -> Color {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6: // RGB (24-bit)
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (255, 215, 0) // Default gold color
        }
        return Color(
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255
        )
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
