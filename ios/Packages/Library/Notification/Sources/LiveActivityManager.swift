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

    /// Live Activity push token (stored in memory)
    @Published public private(set) var liveActivityToken: String?

    /// Push token observation task
    private var pushTokenTask: Task<Void, Never>?

    private init() {}

    /// Start a new agenda live activity with RPG-style mock data
    /// - Parameters:
    ///   - userId: User identifier
    ///   - title: Title of the live activity (deprecated, uses mock data)
    ///   - text: Text content to display (deprecated, uses mock data)
    /// - Throws: ActivityKit errors if activity cannot be started
    public func startAgendaActivity(
        userId: String,
        title: String = "Mission to thrive ✨",
        text: String = "Take a deep breath 🌬️"
    ) async throws {
        Log.i("🚀 Starting RPG-style Live Activity...", category: "Notification")
        Log.i("   - User ID: \(userId)", category: "Notification")

        // Check if activities are enabled
        let areActivitiesEnabled = ActivityAuthorizationInfo().areActivitiesEnabled
        Log.i("   - Activities enabled: \(areActivitiesEnabled)", category: "Notification")

        // Clean up ALL existing activities first
        await cleanupAllActivities()

        let attributes = AgendaActivityAttributes(userId: userId)

        // Mock RPG-style content state
        let contentState = AgendaActivityAttributes.ContentState(
            status: .init(
                type: "energy",
                title: "30%",
                icon: "battery.25",
                buffs: [
                    .init(icon: "moon.stars.fill", label: "褪黑素")
                ]
            ),
            task: .init(
                title: "去阳台进行光合作用",
                description: "别让你的生物钟以为还在深夜。哪怕只把脸伸出去晒 5 分钟,今晚入睡都能快半小时。",
                button: .init(label: "完成", icon: "checkmark")
            ),
            countdown: .init(
                label: "日照充能窗口",
                timeRange: "08:00 - 12:00",
                progressColor: "#FFD700",
                progress: 0.6,
                remainingTimeSeconds: 1200
            )
        )

        do {
            let activity = try Activity<AgendaActivityAttributes>.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: nil),
                pushType: .token
            )
            currentAgendaActivity = activity
            Log.i("✅ RPG-style Live Activity started successfully!", category: "Notification")
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
    ///   - title: New title (deprecated, kept for compatibility)
    ///   - text: New text content (deprecated, kept for compatibility)
    /// - Throws: ActivityKit errors if update fails
    public func updateAgendaActivity(title: String, text: String) async throws {
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

        // Create updated state with mock data (can be replaced with server data later)
        let newState = AgendaActivityAttributes.ContentState(
            status: .init(
                type: "energy",
                title: "60%",
                icon: "battery.75",
                buffs: [
                    .init(icon: "sun.max.fill", label: "活力")
                ]
            ),
            task: .init(
                title: title,
                description: text,
                button: .init(label: "完成", icon: "checkmark")
            ),
            countdown: .init(
                label: "任务窗口",
                timeRange: "10:00 - 14:00",
                progressColor: "#FFD700",
                progress: 0.5,
                remainingTimeSeconds: 900
            )
        )

        let alertConfiguration = AlertConfiguration(
            title: .init(stringLiteral: title),
            body: .init(stringLiteral: text),
            sound: .default
        )

        await activity.update(
            .init(state: newState, staleDate: nil),
            alertConfiguration: alertConfiguration
        )

        Log.i("✅ Live Activity updated: title=\(title), text=\(text)", category: "Notification")
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
                status: .init(
                    type: "energy",
                    title: "100%",
                    icon: "battery.100",
                    buffs: []
                ),
                task: .init(
                    title: "任务完成",
                    description: "下次再见!",
                    button: .init(label: "完成", icon: "checkmark")
                ),
                countdown: .init(
                    label: "已结束",
                    timeRange: "00:00 - 00:00",
                    progressColor: "#4CAF50",
                    progress: 1.0
                )
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

                // Store the token
                self.liveActivityToken = tokenString

                // Report to backend via DeviceTrackManager
                await reportLiveActivityToken(tokenString)
            }
        }
    }

    /// Report Live Activity push token to backend
    private func reportLiveActivityToken(_ token: String) async {
        // Import LibraryTrack to access DeviceTrackManager
        // This will be called by NotificationManager to report the token
        Log.i("📤 Reporting Live Activity token to backend...", category: "Notification")

        // Trigger NotificationManager to report device info with Live Activity token
        Task {
            await NotificationManager.shared.reportDeviceInfoWithLiveActivityToken()
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
