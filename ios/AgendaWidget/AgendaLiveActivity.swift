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
                    Image(systemName: "figure.walk")
                        .foregroundStyle(.blue)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Image(systemName: "figure.walk")
                        .foregroundStyle(.green)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(context.state.title)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(context.state.text)
                            .font(.body)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal)
                }
            } compactLeading: {
                Image(systemName: "figure.walk.circle.fill")
                    .foregroundStyle(.blue)
            } compactTrailing: {
                Text("💪")
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
        VStack(spacing: 16) {
            // Title
            HStack {
                Text(context.state.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)

                Spacer()
            }

            // Text content - larger and more prominent
            HStack {
                Text(context.state.text)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)

                Spacer()
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
    AgendaActivityAttributes.ContentState(
        title: "Thrive mission 💪",
        text: "Take a 10-minute walk"
    )
    AgendaActivityAttributes.ContentState(
        title: "Wellness reminder",
        text: "Deep breath and relax"
    )
}
