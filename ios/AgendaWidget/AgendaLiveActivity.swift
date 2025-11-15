import ActivityKit
import SwiftUI
import WidgetKit

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
                Image(systemName: "figure.walk.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.green)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Task")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(context.state.task)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }

                Spacer()
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
}

// MARK: - AgendaActivityAttributes (Embedded for Widget)

/// Activity Attributes for Agenda Live Activity
/// Note: This is duplicated from LibraryNotification for the Widget Extension
/// as Widget Extensions have limited dependency access
@available(iOS 16.1, *)
public struct AgendaActivityAttributes: ActivityAttributes {
    /// Static attributes that don't change during the activity
    public struct ContentState: Codable, Hashable {
        /// Current weather information
        public var weather: String

        /// Current task for the user
        public var task: String

        /// Last update timestamp
        public var lastUpdate: Date

        public init(weather: String, task: String, lastUpdate: Date = Date()) {
            self.weather = weather
            self.task = task
            self.lastUpdate = lastUpdate
        }
    }

    /// User identifier (static during activity lifetime)
    public var userId: String

    public init(userId: String) {
        self.userId = userId
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
