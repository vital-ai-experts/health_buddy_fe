import AppIntents
import ActivityKit
import LibraryNotification
import LibraryBase
import Foundation

/// App Intent to mark task as complete and switch to next task
@available(iOS 16.4, *)
struct ToggleTaskIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Complete Task"
    static var description = IntentDescription("Mark current task as complete and get a new one")

    /// Execute the intent to update content
    /// Note: This intent is no longer used after Live Activity simplification
    /// Kept for backward compatibility
    func perform() async throws -> some IntentResult {
        Log.i("🎯 ToggleTaskIntent: This intent is deprecated", category: "AgendaWidget")

        // Get all active activities
        let activities = Activity<AgendaActivityAttributes>.activities

        guard let activity = activities.first else {
            Log.w("⚠️ No active Agenda activity found", category: "AgendaWidget")
            return .result()
        }

        let currentState = activity.content.state
        let userId = activity.attributes.userId

        // Simply update with a new message
        Log.i("🆕 Updating Live Activity content", category: "AgendaWidget")
        let newTaskTitle = generateNextMessage()

        // Create updated state with new task
        let newState = AgendaActivityAttributes.ContentState(
            status: .init(
                type: currentState.status.type,
                title: currentState.status.title,
                icon: currentState.status.icon,
                buffs: currentState.status.buffs
            ),
            task: .init(
                title: newTaskTitle,
                description: "完成这个任务以继续你的健康之旅!",
                button: .init(label: "完成", icon: "checkmark")
            ),
            countdown: currentState.countdown
        )

        let alertConfig = AlertConfiguration(
            title: .init(stringLiteral: newTaskTitle),
            body: .init(stringLiteral: "完成这个任务以继续你的健康之旅!"),
            sound: .default
        )

        await activity.update(
            ActivityContent(
                state: newState,
                staleDate: nil
            ),
            alertConfiguration: alertConfig
        )

        Log.i("✅ Content updated to: \(newTaskTitle)", category: "AgendaWidget")
        Log.i("💡 Server will push updated content via APNs when available", category: "AgendaWidget")
        return .result()
    }

    /// Generate a new wellness message
    private func generateNextMessage() -> String {
        let messages = [
            "Take a 5-minute walk",
            "Do some stretches",
            "Drink water",
            "Take deep breaths",
            "Stand and move around",
            "Rest your eyes",
            "Stay active"
        ]

        return messages.randomElement() ?? "Stay healthy! 💪"
    }
}
