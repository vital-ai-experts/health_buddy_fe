import ActivityKit
import Foundation
import LibraryBase

/// 混合卡片类型（包含 Agenda 任务卡和 Inquiry 问询卡）
enum MixedCardType {
    case agenda(AgendaActivityAttributes.ContentState)
    case inquiry(question: String, options: [InquiryActivityAttributes.ContentState.InquiryOption])
}

/// Manager for handling Live Activities
@available(iOS 16.1, *)
@MainActor
public final class LiveActivityManager: ObservableObject {
    /// Singleton instance
    public static let shared = LiveActivityManager()

    /// Current active agenda activity
    @Published public private(set) var currentAgendaActivity: Activity<AgendaActivityAttributes>?

    /// Current active inquiry activity (问询卡片)
    @Published public private(set) var currentInquiryActivity: Activity<InquiryActivityAttributes>?

    /// Live Activity push token (stored in memory)
    @Published public private(set) var liveActivityToken: String?

    /// Inquiry Activity push token (stored in memory)
    @Published public private(set) var inquiryActivityToken: String?

    /// 混合卡片列表（包含 Agenda 和 Inquiry 两种类型，随机打散）
    private var mixedCards: [MixedCardType] = []
    /// 当前展示的混合卡片索引
    private var currentCardIndex: Int = 0
    /// 记录当前使用的用户ID，便于重启或切换任务时复用
    private var currentUserId: String = "guest"

    /// Push token observation task (for Agenda activity)
    private var pushTokenTask: Task<Void, Never>?

    /// Push token observation task (for Inquiry activity)
    private var inquiryPushTokenTask: Task<Void, Never>?

    private let cardIndexKey = "com.thrivebody.liveactivity.cardIndex"

    private init() {}

    /// Start a new mixed card (Agenda or Inquiry) with current or next card from the mixed list
    /// - Parameters:
    ///   - userId: User identifier
    /// - Throws: ActivityKit errors if activity cannot be started
    public func startAgendaActivity(
        userId: String,
        title: String = "Mission to thrive ✨",
        text: String = "Take a deep breath 🌬️",
        initialState: AgendaActivityAttributes.ContentState? = nil
    ) async throws {
        Log.i("🚀 Starting Live Activity (Mixed Cards)...", category: "Notification")
        Log.i("   - User ID: \(userId)", category: "Notification")
        currentUserId = userId

        // Check if activities are enabled
        let areActivitiesEnabled = ActivityAuthorizationInfo().areActivitiesEnabled
        Log.i("   - Activities enabled: \(areActivitiesEnabled)", category: "Notification")

        // Clean up ALL existing activities first
        stopObservingPushToken()
        stopObservingInquiryPushToken()
        await cleanupAllActivities()
        await cleanupAllInquiryActivities()

        // 如果有 initialState，直接启动 Agenda 卡片
        if let initialState {
            let attributes = AgendaActivityAttributes(userId: userId)
            let contentState = prepareState(initialState)

            do {
                let activity = try Activity<AgendaActivityAttributes>.request(
                    attributes: attributes,
                    content: .init(state: contentState, staleDate: nil),
                    pushType: .token
                )
                currentAgendaActivity = activity
                Log.i("✅ Agenda Live Activity started successfully!", category: "Notification")
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
            return
        }

        // 否则使用混合卡片机制
        loadMixedCardsIfNeeded()
        guard !mixedCards.isEmpty else {
            Log.w("⚠️ [LiveActivity] 没有可用的卡片", category: "Notification")
            throw LiveActivityError.noActiveActivity
        }

        // 加载当前卡片索引
        currentCardIndex = loadCurrentCardIndex(max: mixedCards.count)
        let currentCard = mixedCards[currentCardIndex]

        // 根据卡片类型启动相应的 Live Activity
        switch currentCard {
        case .agenda(let state):
            let attributes = AgendaActivityAttributes(userId: userId)
            let contentState = prepareState(state)

            do {
                let activity = try Activity<AgendaActivityAttributes>.request(
                    attributes: attributes,
                    content: .init(state: contentState, staleDate: nil),
                    pushType: .token
                )
                currentAgendaActivity = activity
                Log.i("✅ Agenda Live Activity started successfully!", category: "Notification")
                Log.i("   - Activity ID: \(activity.id)", category: "Notification")
                Log.i("   - Activity State: \(activity.activityState)", category: "Notification")

                // Start observing push token updates
                startObservingPushToken(for: activity)
            } catch {
                Log.e("❌ Failed to start Live Activity: \(error)", category: "Notification")
                throw error
            }

        case .inquiry(let question, let options):
            try await startInquiryActivity(userId: userId, question: question, options: options)
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
                name: "电量",
                value: "60%",
                icon: "battery.75",
                buffs: [
                    .init(type: .positive, icon: "sun.max.fill", label: "活力")
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
    
    /// 切换到下一张混合卡片（包含 Agenda 任务卡和 Inquiry 问询卡，随机轮换）
    public func advanceToNextMockTask() async {
        // 加载混合卡片列表
        loadMixedCardsIfNeeded()
        guard !mixedCards.isEmpty else {
            Log.w("⚠️ [LiveActivity] 没有可用的卡片", category: "Notification")
            return
        }

        // 切换到下一张卡片
        let nextIndex = (currentCardIndex + 1) % mixedCards.count
        currentCardIndex = nextIndex
        persistCurrentCardIndex(nextIndex)

        let nextCard = mixedCards[nextIndex]

        // 根据卡片类型启动相应的 Live Activity
        switch nextCard {
        case .agenda(let state):
            await switchToAgendaCard(state)

        case .inquiry(let question, let options):
            await switchToInquiryCard(question: question, options: options)
        }
    }

    /// 切换到 Agenda 卡片
    private func switchToAgendaCard(_ state: AgendaActivityAttributes.ContentState) async {
        let preparedState = prepareState(state)

        // 清理 Inquiry 卡片（如果有）
        if isInquiryActive {
            await stopInquiryActivity()
        }

        // 更新或启动 Agenda 卡片
        if let activity = currentAgendaActivity, activity.activityState == .active {
            await activity.update(.init(state: preparedState, staleDate: nil))
            Log.i("✅ [LiveActivity] 切换到 Agenda 卡片: \(preparedState.task.title)", category: "Notification")
        } else {
            Log.i("ℹ️ [LiveActivity] 启动 Agenda 卡片: \(preparedState.task.title)", category: "Notification")
            do {
                try await startAgendaActivity(
                    userId: currentUserId,
                    initialState: preparedState
                )
            } catch {
                Log.e("❌ [LiveActivity] 启动 Agenda 卡片失败: \(error)", category: "Notification")
            }
        }
    }

    /// 切换到 Inquiry 卡片
    private func switchToInquiryCard(question: String, options: [InquiryActivityAttributes.ContentState.InquiryOption]) async {
        // 清理 Agenda 卡片（如果有）
        if isAgendaActive {
            await stopAgendaActivity()
        }

        // 启动 Inquiry 卡片
        Log.i("ℹ️ [LiveActivity] 启动 Inquiry 卡片: \(question)", category: "Notification")
        do {
            try await startInquiryActivity(
                userId: currentUserId,
                question: question,
                options: options
            )
        } catch {
            Log.e("❌ [LiveActivity] 启动 Inquiry 卡片失败: \(error)", category: "Notification")
        }
    }

    /// Clean up all existing agenda activities
    /// This ensures we don't have duplicate activities
    private func cleanupAllActivities() async {
        // 停止之前的推送 token 监听，避免残留任务
        stopObservingPushToken()

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
                    name: "电量",
                    value: "100%",
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
        
        // 确保有 startAt
        if countdown.startAt == nil {
            countdown.startAt = Date()
        }

        // 如果没有 totalTimeSeconds，用 remaining 或 progress 推导
        if countdown.totalTimeSeconds == nil {
            if let remaining = countdown.remainingTimeSeconds {
                countdown.totalTimeSeconds = remaining
            } else {
                let totalFromProgress = countdown.progress > 0 ? Int(Double(countdown.remainingTimeSeconds ?? 0) / (1 - countdown.progress)) : nil
                countdown.totalTimeSeconds = totalFromProgress
            }
        }

        // 如果有 total 且没有 remaining，用 progress 推一个初始剩余
        if countdown.remainingTimeSeconds == nil, let total = countdown.totalTimeSeconds {
            let initialRemaining = max(0, Int(Double(total) * (1 - countdown.progress)))
            countdown.remainingTimeSeconds = initialRemaining
        }

        newState.countdown = countdown
        return newState
    }
    
    // MARK: - 混合卡片管理（本地持久化）

    /// 加载混合卡片列表（如果未加载）
    private func loadMixedCardsIfNeeded() {
        if !mixedCards.isEmpty { return }
        mixedCards = generateMixedCards()
    }

    /// 生成混合卡片列表（包含 Agenda 和 Inquiry 两种类型，交错排列）
    private func generateMixedCards() -> [MixedCardType] {
        // 获取两种类型的卡片
        let agendaTasks = defaultMockTasks()
        let agendaCards: [MixedCardType] = agendaTasks.map { .agenda($0) }
        
        let inquiries = defaultInquiryCards()
        let inquiryCards: [MixedCardType] = inquiries.map {
            .inquiry(question: $0.question, options: $0.options)
        }
        
        // 交错合并：一张 Agenda，一张 Inquiry，交替排列
        var result: [MixedCardType] = []
        let maxCount = max(agendaCards.count, inquiryCards.count)
        
        for i in 0..<maxCount {
            if i < agendaCards.count {
                result.append(agendaCards[i])
            }
            if i < inquiryCards.count {
                result.append(inquiryCards[i])
            }
        }
        
        return result
    }

    /// 加载当前卡片索引
    private func loadCurrentCardIndex(max count: Int) -> Int {
        guard count > 0 else { return 0 }
        let stored = UserDefaults.standard.integer(forKey: cardIndexKey)
        return stored % count
    }

    /// 持久化当前卡片索引
    private func persistCurrentCardIndex(_ index: Int) {
        UserDefaults.standard.set(index, forKey: cardIndexKey)
    }

    /// 默认问询卡片列表
    private func defaultInquiryCards() -> [(question: String, options: [InquiryActivityAttributes.ContentState.InquiryOption])] {
        return [
            // 卡片1：入睡时间计算前的干扰项问询
            (
                question: "👀 正在为你计算今晚的最佳入睡时间，在我运行模型前，有没有什么干扰项需要我手动录入的？",
                options: [
                    .init(emoji: "🥗", text: "我很健康", id: "healthy"),
                    .init(emoji: "🍺", text: "喝了酒", id: "alcohol"),
                    .init(emoji: "🍔", text: "吃了夜宵", id: "late_snack")
                ]
            ),
            // 卡片2：睡眠体感问询
            (
                question: "👀 数据说你昨晚只睡了 6 小时，但我想知道你的真实体感。你现在感觉怎么样？",
                options: [
                    .init(emoji: "🚀", text: "满血复活", id: "energized"),
                    .init(emoji: "😑", text: "有点脑雾", id: "foggy"),
                    .init(emoji: "🧟‍♂️", text: "像卡车碾过", id: "exhausted")
                ]
            ),
            // 卡片3：心率异常问询
            (
                question: "👀 虽然你坐着没动，但心率数据越来越高了，是遇到什么棘手的情况了吗？",
                options: [
                    .init(emoji: "😨", text: "突发焦虑", id: "anxiety"),
                    .init(emoji: "🤮", text: "开了个烂会", id: "bad_meeting"),
                    .init(emoji: "☕️", text: "咖啡因上头", id: "caffeine")
                ]
            ),
            // 卡片4：HRV 下降问询
            (
                question: "👀 HRV 已经连跌 3 天了，深睡也一直在减少，最近是不是遇到了什么事情？",
                options: [
                    .init(emoji: "🤯", text: "工作太卷", id: "overwork"),
                    .init(emoji: "🦠", text: "感觉要病", id: "getting_sick"),
                    .init(emoji: "💔", text: "情绪烂事", id: "emotional")
                ]
            ),
            // 卡片5：午餐拍照提醒
            (
                question: "👀 中午啦。别让自己饿着，吃的什么，随手拍一张给我看看？我来帮你记录今天的卡路里摄入。",
                options: [
                    .init(emoji: "📷", text: "随手拍", id: "take_photo")
                ]
            )
        ]
    }
    
    /// 5 条 mock 任务
    private func defaultMockTasks() -> [AgendaActivityAttributes.ContentState] {
        func makeState(
            type: String,
            name: String,
            value: String,
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
                status: .init(type: type, name: name, value: value, icon: icon, buffs: buffs),
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
            // 卡片1：光子锚定（早晨）
            makeState(
                type: "energy",
                name: "电量",
                value: "30%",
                icon: "battery.25",
                buffs: [.init(type: .negative, icon: "moon.stars.fill", label: "褪黑素残留")],
                taskTitle: "任务：采集光子",
                taskDesc: "去窗边/户外晒 5 分钟。向视网膜发送信号，定好今晚的入睡闹钟。",
                countdownLabel: "⏳ 剩余 15 分钟",
                timeRange: "08:00 - 12:00",
                progress: 0.75,
                remaining: 900
            ),
            // 卡片2：脑部补水
            makeState(
                type: "brain",
                name: "脑力",
                value: "40%",
                icon: "brain.head.profile",
                buffs: [.init(type: .negative, icon: "drop.slash.fill", label: "大脑干旱")],
                taskTitle: "任务：填充冷却液",
                taskDesc: "喝一杯 300ml 温水。让\"缩水\"的脑组织重新膨胀，提升反应速度。",
                countdownLabel: "⏳ 剩余 10 分钟",
                timeRange: "全天",
                progress: 0.5,
                remaining: 600
            ),
            // 卡片3：咖啡因最后窗口
            makeState(
                type: "excitement",
                name: "兴奋度",
                value: "80%",
                icon: "bolt.fill",
                buffs: [.init(type: .positive, icon: "cup.and.saucer.fill", label: "咖啡因即将失效")],
                taskTitle: "任务：最后一杯☕️",
                taskDesc: "如果要喝，必须现在喝。再晚摄入将变成今晚的\"失眠毒药\"。",
                countdownLabel: "⏳ 14:00 窗口关闭",
                timeRange: "13:30 - 14:00",
                progress: 0.6,
                remaining: 1800
            ),
            // 卡片4：餐后血糖防御
            makeState(
                type: "bloodSugar",
                name: "血糖",
                value: "预警",
                icon: "waveform.path.ecg",
                buffs: [.init(type: .negative, icon: "chart.line.downtrend.xyaxis", label: "智商掉线")],
                taskTitle: "任务：燃烧葡萄糖",
                taskDesc: "饭后别坐下！快走 10 分钟。让大腿肌肉像海绵一样吸走血糖。",
                countdownLabel: "⏳ 剩余 20 分钟",
                timeRange: "餐后黄金窗口",
                progress: 0.3,
                remaining: 1200
            ),
            // 卡片5：压力阀释放
            makeState(
                type: "cpu",
                name: "CPU",
                value: "过热",
                icon: "flame.fill",
                buffs: [.init(type: .negative, icon: "exclamationmark.triangle.fill", label: "情绪脑劫持")],
                taskTitle: "任务：系统强制冷却",
                taskDesc: "执行\"生理叹息\"（两吸一呼），只需 60 秒，强制重启副交感神经。",
                countdownLabel: "⏳ 立即执行",
                timeRange: "现在",
                progress: 0.9,
                remaining: 60
            ),
        ]
    }

    // MARK: - Inquiry Activity Management

    /// Start a new inquiry live activity (问询卡片)
    /// - Parameters:
    ///   - userId: User identifier
    ///   - question: Question text
    ///   - options: List of inquiry options
    /// - Throws: ActivityKit errors if activity cannot be started
    public func startInquiryActivity(
        userId: String,
        question: String,
        options: [InquiryActivityAttributes.ContentState.InquiryOption]
    ) async throws {
        Log.i("🚀 Starting Inquiry Live Activity...", category: "Notification")
        Log.i("   - User ID: \(userId)", category: "Notification")
        Log.i("   - Question: \(question)", category: "Notification")

        // Check if activities are enabled
        let areActivitiesEnabled = ActivityAuthorizationInfo().areActivitiesEnabled
        Log.i("   - Activities enabled: \(areActivitiesEnabled)", category: "Notification")

        // Clean up existing inquiry activities first
        stopObservingInquiryPushToken()
        await cleanupAllInquiryActivities()

        let attributes = InquiryActivityAttributes(userId: userId)
        let contentState = InquiryActivityAttributes.ContentState(
            question: question,
            options: options,
            createdAt: Date()
        )

        do {
            let activity = try Activity<InquiryActivityAttributes>.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: nil),
                pushType: .token
            )
            currentInquiryActivity = activity
            Log.i("✅ Inquiry Live Activity started successfully!", category: "Notification")
            Log.i("   - Activity ID: \(activity.id)", category: "Notification")
            Log.i("   - Activity State: \(activity.activityState)", category: "Notification")

            // Start observing push token updates
            startObservingInquiryPushToken(for: activity)
        } catch {
            Log.e("❌ Failed to start Inquiry Live Activity: \(error)", category: "Notification")
            Log.i("   - Error type: \(type(of: error))", category: "Notification")
            Log.i("   - Error description: \(error.localizedDescription)", category: "Notification")
            throw error
        }
    }

    /// Update the current inquiry live activity
    /// - Parameters:
    ///   - question: New question text
    ///   - options: New list of options
    /// - Throws: ActivityKit errors if update fails
    public func updateInquiryActivity(
        question: String,
        options: [InquiryActivityAttributes.ContentState.InquiryOption]
    ) async throws {
        guard let activity = currentInquiryActivity else {
            Log.w("⚠️ No currentInquiryActivity stored, cannot update", category: "Notification")
            throw LiveActivityError.noActiveActivity
        }

        // Check if activity is still active
        guard activity.activityState == .active else {
            Log.w("⚠️ Inquiry Activity is no longer active (state: \(activity.activityState)), clearing reference", category: "Notification")
            currentInquiryActivity = nil
            throw LiveActivityError.noActiveActivity
        }

        let newState = InquiryActivityAttributes.ContentState(
            question: question,
            options: options,
            createdAt: Date()
        )

        let alertConfiguration = AlertConfiguration(
            title: .init(stringLiteral: "新的问询"),
            body: .init(stringLiteral: question),
            sound: .default
        )

        await activity.update(
            .init(state: newState, staleDate: nil),
            alertConfiguration: alertConfiguration
        )

        Log.i("✅ Inquiry Live Activity updated: question=\(question)", category: "Notification")
    }

    /// Stop the current inquiry live activity
    public func stopInquiryActivity() async {
        // Stop observing push tokens
        stopObservingInquiryPushToken()

        // Clean up all inquiry activities
        await cleanupAllInquiryActivities()
        Log.i("✅ Inquiry Live Activity stopped", category: "Notification")
    }

    /// Check if there's an active inquiry activity
    public var isInquiryActive: Bool {
        currentInquiryActivity != nil && currentInquiryActivity?.activityState == .active
    }

    /// Clean up all existing inquiry activities
    private func cleanupAllInquiryActivities() async {
        stopObservingInquiryPushToken()

        let activities = Activity<InquiryActivityAttributes>.activities
        let count = activities.count

        if count > 0 {
            Log.i("🧹 Cleaning up \(count) existing Inquiry Activity(ies)...", category: "Notification")
        }

        for activity in activities {
            Log.i("   - Ending inquiry activity: \(activity.id) (state: \(activity.activityState))", category: "Notification")
            let finalState = InquiryActivityAttributes.ContentState(
                question: "感谢回复！",
                options: [],
                createdAt: Date()
            )
            await activity.end(
                .init(state: finalState, staleDate: nil),
                dismissalPolicy: .immediate
            )
        }

        // Clear our reference
        currentInquiryActivity = nil

        if count > 0 {
            Log.i("✅ Inquiry cleanup completed, all activities ended", category: "Notification")
        }
    }

    // MARK: - Inquiry Push Token Management

    /// Start observing push token updates for the inquiry activity
    private func startObservingInquiryPushToken(for activity: Activity<InquiryActivityAttributes>) {
        // Cancel any existing observation
        stopObservingInquiryPushToken()

        Log.i("🔔 Starting inquiry push token observation...", category: "Notification")

        inquiryPushTokenTask = Task {
            for await pushToken in activity.pushTokenUpdates {
                let tokenString = pushToken.map { String(format: "%02x", $0) }.joined()
                Log.i("📱 Inquiry Live Activity Push Token Updated:", category: "Notification")
                Log.i("   - Activity ID: \(activity.id)", category: "Notification")
                Log.i("   - Push Token: \(tokenString)", category: "Notification")
                Log.i("   - Token Data: \(pushToken.base64EncodedString())", category: "Notification")

                // Store the token
                self.inquiryActivityToken = tokenString

                // Report to backend via DeviceTrackManager
                await reportInquiryActivityToken(tokenString)
            }
        }
    }

    /// Report Inquiry Activity push token to backend
    private func reportInquiryActivityToken(_ token: String) async {
        Log.i("📤 Reporting Inquiry Activity token to backend...", category: "Notification")

        // Trigger NotificationManager to report device info with Inquiry Activity token
        Task {
            await NotificationManager.shared.reportDeviceInfoWithLiveActivityToken()
        }
    }

    /// Stop observing inquiry push token updates
    private func stopObservingInquiryPushToken() {
        inquiryPushTokenTask?.cancel()
        inquiryPushTokenTask = nil
        Log.i("🔕 Stopped inquiry push token observation", category: "Notification")
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
