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
        HStack(spacing: 16) {
            // Logo - Beautiful gradient heart icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)

                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 32))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        Color.white
                    )
            }

            // Content
            VStack(alignment: .leading, spacing: 8) {
                // Title
                Text(context.state.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)

                // Text content - larger and more prominent
                Text(context.state.text)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
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
        title: "Mission to thrive ✨",
        text: "Take a deep breath 🌬️"
    )
    AgendaActivityAttributes.ContentState(
        title: "Wellness journey 🌟",
        text: "Stretch and feel amazing 💫"
    )
}
