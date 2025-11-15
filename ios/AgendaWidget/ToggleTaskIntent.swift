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
        print("🎯 ToggleTaskIntent: Marking task as complete")

        // Get all active activities
        let activities = Activity<AgendaActivityAttributes>.activities

        guard let activity = activities.first else {
            print("⚠️ No active Agenda activity found")
            return .result()
        }

        let currentState = activity.content.state

        // Step 1: Mark current task as completed
        print("✅ Step 1: Marking task as completed")
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

        // Step 2: Wait 1.5 seconds to show completion
        print("⏳ Step 2: Waiting 1.5 seconds...")
        try? await Task.sleep(nanoseconds: 1_500_000_000)

        // Step 3: Generate and show new task
        print("🆕 Step 3: Generating new task")
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
