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
    
    /// Mock 任务列表（本地持久化）
    private var mockTasks: [AgendaActivityAttributes.ContentState] = []
    /// 当前展示的 mock 任务索引（本地持久化）
    private var currentMockTaskIndex: Int = 0
    /// 记录当前使用的用户ID，便于重启或切换任务时复用
    private var currentUserId: String = "guest"

    /// Push token observation task
    private var pushTokenTask: Task<Void, Never>?
    
    private let mockTasksKey = "com.thrivebody.liveactivity.mockTasks"
    private let mockTaskIndexKey = "com.thrivebody.liveactivity.mockTaskIndex"

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
        text: String = "Take a deep breath 🌬️",
        initialState: AgendaActivityAttributes.ContentState? = nil
    ) async throws {
        Log.i("🚀 Starting RPG-style Live Activity...", category: "Notification")
        Log.i("   - User ID: \(userId)", category: "Notification")
        currentUserId = userId

        // Check if activities are enabled
        let areActivitiesEnabled = ActivityAuthorizationInfo().areActivitiesEnabled
        Log.i("   - Activities enabled: \(areActivitiesEnabled)", category: "Notification")

        // Clean up ALL existing activities first
        await cleanupAllActivities()

        let attributes = AgendaActivityAttributes(userId: userId)

        // 读取/生成 mock 任务列表
        loadMockTasksIfNeeded()
        let tasks = mockTasks.isEmpty ? defaultMockTasks() : mockTasks
        if mockTasks.isEmpty {
            mockTasks = tasks
            persistMockTasks(tasks)
        }
        currentMockTaskIndex = loadCurrentMockIndex(max: tasks.count)

        // 当前要展示的内容
        let selectedState: AgendaActivityAttributes.ContentState
        if let initialState {
            selectedState = initialState
        } else if currentMockTaskIndex < tasks.count {
            selectedState = tasks[currentMockTaskIndex]
        } else {
            selectedState = tasks.first!
            currentMockTaskIndex = 0
            persistCurrentMockIndex(0)
        }
        let contentState = prepareState(selectedState)

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
            .init(state: prepareState(newState), staleDate: nil),
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
    
    /// 切换到下一条 mock 任务（会保存索引并立即更新 Live Activity）
    public func advanceToNextMockTask() async {
        loadMockTasksIfNeeded()
        guard !mockTasks.isEmpty else {
            Log.w("⚠️ [LiveActivity] 没有可用的 mock 任务", category: "Notification")
            return
        }
        
        let nextIndex = (currentMockTaskIndex + 1) % mockTasks.count
        currentMockTaskIndex = nextIndex
        persistCurrentMockIndex(nextIndex)
        
        let nextState: AgendaActivityAttributes.ContentState
        if nextIndex < mockTasks.count {
            nextState = prepareState(mockTasks[nextIndex])
        } else {
            nextState = prepareState(mockTasks.first!)
            currentMockTaskIndex = 0
            persistCurrentMockIndex(0)
        }

        if let activity = currentAgendaActivity, activity.activityState == .active {
            await activity.update(.init(state: nextState, staleDate: nil))
            Log.i("✅ [LiveActivity] 切换到下一任务: \(nextState.task.title)", category: "Notification")
        } else {
            Log.w("ℹ️ [LiveActivity] 当前没有活动，尝试重启并展示下一任务", category: "Notification")
            do {
                try await startAgendaActivity(
                    userId: currentUserId,
                    initialState: nextState
                )
            } catch {
                Log.e("❌ [LiveActivity] 重启活动失败: \(error)", category: "Notification")
            }
        }
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
    
    private func prepareState(_ state: AgendaActivityAttributes.ContentState) -> AgendaActivityAttributes.ContentState {
        var newState = state
        var countdown = newState.countdown

        // 如果传入了总时长但没有剩余时间，则用 progress 推导初始剩余时间
        if countdown.remainingTimeSeconds == nil,
           let total = countdown.totalTimeSeconds {
            let initialRemaining = max(0, Int(Double(total) * (1 - countdown.progress)))
            countdown.remainingTimeSeconds = initialRemaining
        }

        if let remaining = countdown.remainingTimeSeconds {
            if countdown.totalTimeSeconds == nil {
                countdown.totalTimeSeconds = remaining
            }
            if countdown.startAt == nil {
                countdown.startAt = Date()
            }
            newState.countdown = countdown
        }
        return newState
    }
    
    // MARK: - Mock 任务管理（本地持久化）
    
    private func loadMockTasksIfNeeded() {
        if !mockTasks.isEmpty { return }
        if let data = UserDefaults.standard.data(forKey: mockTasksKey),
           let tasks = try? JSONDecoder().decode([AgendaActivityAttributes.ContentState].self, from: data),
           !tasks.isEmpty {
            mockTasks = tasks
            currentMockTaskIndex = loadCurrentMockIndex(max: tasks.count)
            return
        }
        
        let defaults = defaultMockTasks()
        mockTasks = defaults
        persistMockTasks(defaults)
        currentMockTaskIndex = 0
        persistCurrentMockIndex(0)
    }
    
    private func persistMockTasks(_ tasks: [AgendaActivityAttributes.ContentState]) {
        guard let data = try? JSONEncoder().encode(tasks) else { return }
        UserDefaults.standard.set(data, forKey: mockTasksKey)
    }
    
    private func loadCurrentMockIndex(max count: Int) -> Int {
        guard count > 0 else { return 0 }
        let stored = UserDefaults.standard.integer(forKey: mockTaskIndexKey)
        return stored % count
    }
    
    private func persistCurrentMockIndex(_ index: Int) {
        UserDefaults.standard.set(index, forKey: mockTaskIndexKey)
    }
    
    /// 参考 Agenda 样式的 5 条 mock 任务
    private func defaultMockTasks() -> [AgendaActivityAttributes.ContentState] {
        func makeState(
            type: String,
            title: String,
            icon: String,
            buffs: [AgendaActivityAttributes.ContentState.BuffInfo],
            taskTitle: String,
            taskDesc: String,
            countdownLabel: String,
            timeRange: String,
            progress: Double,
            remaining: Int?
        ) -> AgendaActivityAttributes.ContentState {
            AgendaActivityAttributes.ContentState(
                status: .init(type: type, title: title, icon: icon, buffs: buffs),
                task: .init(
                    title: taskTitle,
                    description: taskDesc,
                    button: .init(label: "完成", icon: "checkmark")
                ),
                countdown: .init(
                    label: countdownLabel,
                    timeRange: timeRange,
                    progressColor: "#FFD700",
                    progress: progress,
                    remainingTimeSeconds: remaining,
                    totalTimeSeconds: remaining,
                    startAt: nil
                )
            )
        }
        
        return [
            makeState(
                type: "energy",
                title: "65%",
                icon: "bolt.fill",
                buffs: [.init(icon: "sun.max.fill", label: "觉醒")],
                taskTitle: "任务：采集光子",
                taskDesc: "去窗边/户外晒 5 分钟。向视网膜发送信号，定好今晚的入睡闹钟。",
                countdownLabel: "日照充能窗口",
                timeRange: "08:00 - 12:00",
                progress: 0.55,
                remaining: 1200
            ),
            makeState(
                type: "hydration",
                title: "74%",
                icon: "drop.fill",
                buffs: [.init(icon: "cup.and.saucer.fill", label: "补水")],
                taskTitle: "任务：填充冷却液",
                taskDesc: "喝一杯 300ml 温水，让“缩水”的脑组织重新膨胀，提升反应速度。",
                countdownLabel: "水分补给窗口",
                timeRange: "全天",
                progress: 0.4,
                remaining: 900
            ),
            makeState(
                type: "focus",
                title: "58%",
                icon: "brain.head.profile",
                buffs: [.init(icon: "flame.fill", label: "心肺")],
                taskTitle: "史诗任务：引擎重铸",
                taskDesc: "进行 4 组 2 分钟全力冲刺，把心率推到 160+。",
                countdownLabel: "心肺训练窗口",
                timeRange: "18:00 - 21:00",
                progress: 0.3,
                remaining: 2400
            ),
            makeState(
                type: "calm",
                title: "70%",
                icon: "lungs.fill",
                buffs: [.init(icon: "wind", label: "冷静值")],
                taskTitle: "任务：系统强制冷却",
                taskDesc: "执行“生理叹息”（两吸一呼），只需 60 秒，重启副交感神经。",
                countdownLabel: "立即执行",
                timeRange: "现在",
                progress: 0.8,
                remaining: 60
            ),
            makeState(
                type: "vision",
                title: "80%",
                icon: "eye.fill",
                buffs: [.init(icon: "viewfinder.circle", label: "鹰眼")],
                taskTitle: "任务：全景扫描",
                taskDesc: "去窗边盯着远处看 30 秒，解除眼部肌肉痉挛，降低焦虑。",
                countdownLabel: "视神经重置",
                timeRange: "每 60 分钟一次",
                progress: 0.2,
                remaining: 600
            )
        ]
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
