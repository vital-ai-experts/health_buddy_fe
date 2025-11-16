import AppIntents
import ActivityKit
import LibraryNotification
import Foundation

/// App Intent to mark task as complete and switch to next task
@available(iOS 16.4, *)
struct ToggleTaskIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Complete Task"
    static var description = IntentDescription("Mark current task as complete and get a new one")

    /// Execute the intent to complete task and get new one
    func perform() async throws -> some IntentResult {
        print("🎯 ToggleTaskIntent: Starting task completion flow")

        // Get all active activities
        let activities = Activity<AgendaActivityAttributes>.activities

        guard let activity = activities.first else {
            print("⚠️ No active Agenda activity found")
            return .result()
        }

        let currentState = activity.content.state
        let userId = activity.attributes.userId
        let taskId = UUID().uuidString // Generate task ID

        // Step 1: Notify server about task completion (best-effort, non-blocking)
        print("📤 Step 1: Notifying server of task completion")
        Task.detached(priority: .utility) {
            do {
                _ = try await AgendaAPIClient.shared.notifyTaskCompletion(
                    userId: userId,
                    taskId: taskId,
                    task: currentState.task
                )
            } catch {
                print("⚠️ Server notification failed (continuing): \(error)")
            }
        }

        // Step 2: Mark current task as completed (immediate UI feedback)
        print("✅ Step 2: Marking task as completed")
        let completedState = AgendaActivityAttributes.ContentState(
            weather: currentState.weather,
            task: currentState.task,
            isCompleted: true,
            lastUpdate: Date()
        )

        await activity.update(
            ActivityContent(
                state: completedState,
                staleDate: nil
            )
        )

        // Step 3: Wait 1.5 seconds to show completion
        print("⏳ Step 3: Waiting 1.5 seconds...")
        try? await Task.sleep(nanoseconds: 1_500_000_000)

        // Step 4: Generate and show new task
        // Note: In production, this should come from server push notification
        // For now, we generate locally as fallback
        print("🆕 Step 4: Generating new task (local fallback)")
        let newTask = generateNextTask()

        let newState = AgendaActivityAttributes.ContentState(
            weather: currentState.weather,
            task: newTask,
            isCompleted: false,
            lastUpdate: Date()
        )

        let alertConfig = AlertConfiguration(
            title: .init(stringLiteral: "New Task"),
            body: .init(stringLiteral: newTask),
            sound: .default
        )

        await activity.update(
            ActivityContent(
                state: newState,
                staleDate: nil
            ),
            alertConfiguration: alertConfig
        )

        print("✅ Task completed and switched to: \(newTask)")
        print("💡 Server will push updated task via APNs when available")
        return .result()
    }

    /// Generate a new task
    private func generateNextTask() -> String {
        let tasks = [
            "Take a 5-minute walk 🚶",
            "Do 15 push-ups 💪",
            "Drink a glass of water 💧",
            "Stretch for 3 minutes 🧘",
            "Do 20 jumping jacks 🤸",
            "Take 5 deep breaths 🌬️",
            "Stand up and move around 🏃",
            "Do 10 squats 🦵",
            "Roll your shoulders 5 times 🔄",
            "Look away from screen for 20 seconds 👀"
        ]

        return tasks.randomElement() ?? "Stay active! 💪"
    }
}
