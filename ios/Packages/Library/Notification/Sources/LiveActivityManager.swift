import ActivityKit
import Foundation

/// Manager for handling Live Activities
@available(iOS 16.1, *)
@MainActor
public final class LiveActivityManager: ObservableObject {
    /// Singleton instance
    public static let shared = LiveActivityManager()

    /// Current active agenda activity
    @Published public private(set) var currentAgendaActivity: Activity<AgendaActivityAttributes>?

    private init() {}

    /// Start a new agenda live activity
    /// - Parameters:
    ///   - userId: User identifier
    ///   - initialWeather: Initial weather information
    ///   - initialTask: Initial task for the user
    /// - Throws: ActivityKit errors if activity cannot be started
    public func startAgendaActivity(
        userId: String,
        initialWeather: String,
        initialTask: String
    ) async throws {
        print("🚀 Starting Live Activity...")
        print("   - User ID: \(userId)")
        print("   - Weather: \(initialWeather)")
        print("   - Task: \(initialTask)")

        // Check if activities are enabled
        let areActivitiesEnabled = ActivityAuthorizationInfo().areActivitiesEnabled
        print("   - Activities enabled: \(areActivitiesEnabled)")

        // Clean up ALL existing activities first
        await cleanupAllActivities()

        let attributes = AgendaActivityAttributes(userId: userId)
        let contentState = AgendaActivityAttributes.ContentState(
            weather: initialWeather,
            task: initialTask,
            isCompleted: false,
            lastUpdate: Date()
        )

        do {
            let activity = try Activity<AgendaActivityAttributes>.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: nil),
                pushType: nil
            )
            currentAgendaActivity = activity
            print("✅ Live Activity started successfully!")
            print("   - Activity ID: \(activity.id)")
            print("   - Activity State: \(activity.activityState)")
        } catch {
            print("❌ Failed to start Live Activity: \(error)")
            print("   - Error type: \(type(of: error))")
            print("   - Error description: \(error.localizedDescription)")
            throw error
        }
    }

    /// Update the current agenda live activity
    /// - Parameters:
    ///   - weather: New weather information
    ///   - task: New task for the user
    /// - Throws: ActivityKit errors if update fails
    public func updateAgendaActivity(weather: String, task: String) async throws {
        guard let activity = currentAgendaActivity else {
            print("⚠️ No currentAgendaActivity stored, cannot update")
            throw LiveActivityError.noActiveActivity
        }

        // Check if activity is still active
        guard activity.activityState == .active else {
            print("⚠️ Activity is no longer active (state: \(activity.activityState)), clearing reference")
            currentAgendaActivity = nil
            throw LiveActivityError.noActiveActivity
        }

        // Preserve the current isCompleted status
        let currentIsCompleted = activity.content.state.isCompleted

        let newState = AgendaActivityAttributes.ContentState(
            weather: weather,
            task: task,
            isCompleted: currentIsCompleted, // Preserve the completion status
            lastUpdate: Date()
        )

        let alertConfiguration = AlertConfiguration(
            title: .init(stringLiteral: "New Task"),
            body: .init(stringLiteral: task),
            sound: .default
        )

        await activity.update(
            .init(state: newState, staleDate: nil),
            alertConfiguration: alertConfiguration
        )

        print("✅ Live Activity updated: weather=\(weather), task=\(task), completed=\(currentIsCompleted)")
    }

    /// Stop the current agenda live activity
    public func stopAgendaActivity() async {
        // Clean up all activities to ensure nothing is left running
        await cleanupAllActivities()
        print("✅ Live Activity stopped")
    }

    /// Check if there's an active agenda activity
    public var isAgendaActive: Bool {
        currentAgendaActivity != nil && currentAgendaActivity?.activityState == .active
    }

    /// Clean up all existing agenda activities
    /// This ensures we don't have duplicate activities
    private func cleanupAllActivities() async {
        let activities = Activity<AgendaActivityAttributes>.activities
        let count = activities.count

        if count > 0 {
            print("🧹 Cleaning up \(count) existing Live Activity(ies)...")
        }

        for activity in activities {
            print("   - Ending activity: \(activity.id) (state: \(activity.activityState))")
            let finalState = AgendaActivityAttributes.ContentState(
                weather: "Session ended",
                task: "See you next time!",
                isCompleted: false,
                lastUpdate: Date()
            )
            await activity.end(
                .init(state: finalState, staleDate: nil),
                dismissalPolicy: .immediate
            )
        }

        // Clear our reference
        currentAgendaActivity = nil

        if count > 0 {
            print("✅ Cleanup completed, all activities ended")
        }
    }
}

/// Errors that can occur when managing live activities
public enum LiveActivityError: LocalizedError {
    case noActiveActivity
    case activityNotSupported

    public var errorDescription: String? {
        switch self {
        case .noActiveActivity:
            return "No active live activity found"
        case .activityNotSupported:
            return "Live Activities are not supported on this device"
        }
    }
}
