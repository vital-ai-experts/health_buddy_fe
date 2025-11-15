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
        // Stop existing activity if any
        await stopAgendaActivity()

        let attributes = AgendaActivityAttributes(userId: userId)
        let contentState = AgendaActivityAttributes.ContentState(
            weather: initialWeather,
            task: initialTask,
            lastUpdate: Date()
        )

        do {
            let activity = try Activity<AgendaActivityAttributes>.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: nil),
                pushType: nil
            )
            currentAgendaActivity = activity
            print("✅ Live Activity started: \(activity.id)")
        } catch {
            print("❌ Failed to start Live Activity: \(error)")
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
            throw LiveActivityError.noActiveActivity
        }

        let newState = AgendaActivityAttributes.ContentState(
            weather: weather,
            task: task,
            lastUpdate: Date()
        )

        let alertConfiguration = AlertConfiguration(
            title: "New Task",
            body: task,
            sound: .default
        )

        await activity.update(
            .init(state: newState, staleDate: nil),
            alertConfiguration: alertConfiguration
        )

        print("✅ Live Activity updated: weather=\(weather), task=\(task)")
    }

    /// Stop the current agenda live activity
    public func stopAgendaActivity() async {
        guard let activity = currentAgendaActivity else {
            return
        }

        let finalState = AgendaActivityAttributes.ContentState(
            weather: "Completed",
            task: "Great job today!",
            lastUpdate: Date()
        )

        await activity.end(
            .init(state: finalState, staleDate: nil),
            dismissalPolicy: .default
        )

        currentAgendaActivity = nil
        print("✅ Live Activity stopped")
    }

    /// Check if there's an active agenda activity
    public var isAgendaActive: Bool {
        currentAgendaActivity != nil && currentAgendaActivity?.activityState == .active
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
