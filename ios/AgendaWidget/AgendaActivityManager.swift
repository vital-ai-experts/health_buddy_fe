import ActivityKit
import Foundation

/// Live Activity 管理器
/// 用于启动、更新和结束健康任务 Live Activity
@available(iOS 16.1, *)
public class AgendaActivityManager {
    public static let shared = AgendaActivityManager()

    private var currentActivity: Activity<AgendaAttributes>?

    private init() {}

    // MARK: - Public Methods

    /// 启动 Live Activity
    public func startActivity(userName: String = "健康助手") async {
        // 检查是否已经有活动的 Live Activity
        guard currentActivity == nil else {
            print("Live Activity already running")
            return
        }

        // 检查 Live Activity 是否可用
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities are not enabled")
            return
        }

        do {
            // 获取初始数据（使用天气 API mock）
            let initialState = try await fetchAgendaData()

            // 创建 attributes
            let attributes = AgendaAttributes(userName: userName)

            // 启动 Live Activity
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil // 暂不使用推送通知
            )

            currentActivity = activity
            print("Live Activity started successfully")

            // 启动定时更新（每5分钟）
            startPeriodicUpdates()
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }

    /// 更新 Live Activity
    public func updateActivity() async {
        guard let activity = currentActivity else {
            print("No active Live Activity to update")
            return
        }

        do {
            let newState = try await fetchAgendaData()
            await activity.update(
                .init(state: newState, staleDate: nil)
            )
            print("Live Activity updated successfully")
        } catch {
            print("Failed to update Live Activity: \(error)")
        }
    }

    /// 结束 Live Activity
    public func endActivity(dismissalPolicy: ActivityUIDismissalPolicy = .default) async {
        guard let activity = currentActivity else {
            print("No active Live Activity to end")
            return
        }

        await activity.end(
            .init(state: activity.content.state, staleDate: nil),
            dismissalPolicy: dismissalPolicy
        )

        currentActivity = nil
        print("Live Activity ended")
    }

    /// 检查是否有活动的 Live Activity
    public var isActivityRunning: Bool {
        return currentActivity != nil
    }

    // MARK: - Private Methods

    /// 定时更新（每5分钟）
    private func startPeriodicUpdates() {
        Task {
            while currentActivity != nil {
                try? await Task.sleep(for: .seconds(300)) // 5分钟
                if currentActivity != nil {
                    await updateActivity()
                }
            }
        }
    }

    /// 获取健康任务数据（Mock: 使用天气 API）
    private func fetchAgendaData() async throws -> AgendaAttributes.ContentState {
        let weatherData = try await AgendaService.shared.fetchAgenda()

        return AgendaAttributes.ContentState(
            temperature: weatherData.temperature,
            feelsLike: weatherData.feelsLike,
            weatherDescription: weatherData.weatherDescription,
            humidity: weatherData.humidity,
            windSpeed: weatherData.windSpeed,
            weatherCode: weatherData.weatherCode,
            updateTime: weatherData.updateTime
        )
    }

    // MARK: - Utility Methods

    /// 获取所有活动的 Live Activities
    public static func getAllActivities() -> [Activity<AgendaAttributes>] {
        return Activity<AgendaAttributes>.activities
    }

    /// 结束所有活动的 Live Activities
    public static func endAllActivities() async {
        for activity in Activity<AgendaAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
}
