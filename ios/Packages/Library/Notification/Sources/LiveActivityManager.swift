import ActivityKit
import Foundation
import LibraryBase

/// Manager for handling Live Activities
@available(iOS 16.1, *)
@MainActor
public final class LiveActivityManager: ObservableObject {
    /// Singleton instance
    public static let shared = LiveActivityManager()

    /// Current active agenda activity
    @Published public private(set) var currentAgendaActivity: Activity<AgendaActivityAttributes>?

    /// Push token observation task
    private var pushTokenTask: Task<Void, Never>?

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
        Log.i("🚀 Starting Live Activity...", category: "Notification")
        Log.i("   - User ID: \(userId)", category: "Notification")
        Log.i("   - Weather: \(initialWeather)", category: "Notification")
        Log.i("   - Task: \(initialTask)", category: "Notification")

        // Check if activities are enabled
        let areActivitiesEnabled = ActivityAuthorizationInfo().areActivitiesEnabled
        Log.i("   - Activities enabled: \(areActivitiesEnabled)", category: "Notification")

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
                pushType: .token
            )
            currentAgendaActivity = activity
            Log.i("✅ Live Activity started successfully!", category: "Notification")
            Log.i("   - Activity ID: \(activity.id)", category: "Notification")
            Log.i("   - Activity State: \(activity.activityState)", category: "Notification")

            // Start observing push token updates
            startObservingPushToken(for: activity)
        } catch {
            Log.e("❌ Failed to start Live Activity: \(error)", category: "Notification")
            Log.i("   - Error type: \(type(of: error))", category: "Notification")
            Log.i("   - Error description: \(error.localizedDescription)", category: "Notification")
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
            Log.w("⚠️ No currentAgendaActivity stored, cannot update", category: "Notification")
            throw LiveActivityError.noActiveActivity
        }

        // Check if activity is still active
        guard activity.activityState == .active else {
            Log.w("⚠️ Activity is no longer active (state: \(activity.activityState)), clearing reference", category: "Notification")
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

        Log.i("✅ Live Activity updated: weather=\(weather), task=\(task), completed=\(currentIsCompleted)", category: "Notification")
    }

    /// Stop the current agenda live activity
    public func stopAgendaActivity() async {
        // Stop observing push tokens
        stopObservingPushToken()

        // Clean up all activities to ensure nothing is left running
        await cleanupAllActivities()
        Log.i("✅ Live Activity stopped", category: "Notification")
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
            Log.i("🧹 Cleaning up \(count) existing Live Activity(ies)...", category: "Notification")
        }

        for activity in activities {
            Log.i("   - Ending activity: \(activity.id) (state: \(activity.activityState))", category: "Notification")
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
            Log.i("✅ Cleanup completed, all activities ended", category: "Notification")
        }
    }

    // MARK: - Push Token Management

    /// Start observing push token updates for the activity
    private func startObservingPushToken(for activity: Activity<AgendaActivityAttributes>) {
        // Cancel any existing observation
        stopObservingPushToken()

        Log.i("🔔 Starting push token observation...", category: "Notification")

        pushTokenTask = Task {
            for await pushToken in activity.pushTokenUpdates {
                let tokenString = pushToken.map { String(format: "%02x", $0) }.joined()
                Log.i("📱 Live Activity Push Token Updated:", category: "Notification")
                Log.i("   - Activity ID: \(activity.id)", category: "Notification")
                Log.i("   - Push Token: \(tokenString)", category: "Notification")
                Log.i("   - Token Data: \(pushToken.base64EncodedString())", category: "Notification")

                // TODO: Send this token to your backend server
                // await sendPushTokenToServer(activityId: activity.id, token: tokenString)
            }
        }
    }

    /// Stop observing push token updates
    private func stopObservingPushToken() {
        pushTokenTask?.cancel()
        pushTokenTask = nil
        Log.i("🔕 Stopped push token observation", category: "Notification")
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
