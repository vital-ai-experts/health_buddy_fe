import ActivityKit
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
                    HStack {
                        Image(systemName: "cloud.sun.fill")
                            .foregroundStyle(.blue)
                        Text(context.state.weather)
                            .font(.caption)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Image(systemName: "figure.walk")
                        .foregroundStyle(.green)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Task")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Text(context.state.task)
                            .font(.body)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal)
                }
            } compactLeading: {
                Image(systemName: "figure.walk.circle.fill")
                    .foregroundStyle(.blue)
            } compactTrailing: {
                Text(context.state.weather.prefix(4))
                    .font(.caption2)
            } minimal: {
                Image(systemName: "figure.walk")
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
            // Header with weather
            HStack {
                Image(systemName: "cloud.sun.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)

                Text(context.state.weather)
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Text(timeAgo)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Divider()

            // Current task
            HStack(alignment: .top, spacing: 12) {
                // Interactive Checkbox (requires iOS 16.4+ for LiveActivityIntent)
                if #available(iOS 16.4, *) {
                    Button(intent: ToggleTaskIntent()) {
                        Image(systemName: context.state.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 28))
                            .foregroundStyle(context.state.isCompleted ? .green : .gray)
                    }
                    .buttonStyle(.plain)
                } else {
                    // Fallback for iOS 16.1-16.3 (non-interactive)
                    Image(systemName: context.state.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 28))
                        .foregroundStyle(context.state.isCompleted ? .green : .gray)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Current Task")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(context.state.task)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .strikethrough(context.state.isCompleted, color: .secondary)

                    // Additional information lines
                    Text(context.state.isCompleted ? "✅ Task completed!" : "💪 Keep up the great work!")
                        .font(.caption)
                        .foregroundStyle(context.state.isCompleted ? .green : .secondary)

                    Text("Next update: \(nextUpdateTime)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                // Task icon
                Image(systemName: "figure.walk.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(context.state.isCompleted ? .gray : .blue)
                    .opacity(context.state.isCompleted ? 0.5 : 1.0)
            }
        }
        .padding()
    }

    private var timeAgo: String {
        let interval = Date().timeIntervalSince(context.state.lastUpdate)
        let minutes = Int(interval / 60)

        if minutes < 1 {
            return "Just now"
        } else if minutes < 60 {
            return "\(minutes)m ago"
        } else {
            let hours = minutes / 60
            return "\(hours)h ago"
        }
    }

    private var nextUpdateTime: String {
        let updateInterval: TimeInterval = 10 // 10 seconds
        let nextUpdate = context.state.lastUpdate.addingTimeInterval(updateInterval)
        let secondsUntilUpdate = Int(nextUpdate.timeIntervalSinceNow)

        if secondsUntilUpdate <= 0 {
            return "Updating..."
        } else {
            return "\(secondsUntilUpdate)s"
        }
    }
}

// MARK: - Preview

@available(iOS 16.1, *)
#Preview("Live Activity", as: .content, using: AgendaActivityAttributes(userId: "preview")) {
    AgendaLiveActivity()
} contentStates: {
    AgendaActivityAttributes.ContentState(
        weather: "Sunny ☀️ 22°C",
        task: "Take a 10-minute walk 🚶",
        lastUpdate: Date()
    )
    AgendaActivityAttributes.ContentState(
        weather: "Cloudy ☁️ 18°C",
        task: "Do 20 push-ups 💪",
        lastUpdate: Date().addingTimeInterval(-300)
    )
}
