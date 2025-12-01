import Foundation

// MARK: - Sample Data Extensions

extension GoalsData {
    static let mock = GoalsData(
        surfaceGoal: "提升精力，消除下午的脑雾。",
        deepMotivation: "[职业恐惧]：你曾在对话中提到\"担心35岁后拼不过年轻人\"。你的核心驱动力不是健康本身，而是**\"保持职场竞争力\"和\"认知敏锐度\"**。",
        obstacle: "[全有全无心态]：你倾向于制定完美的计划,一旦有一天没做到（比如偷吃了），就会产生强烈的挫败感并彻底放弃。",
        obstacleAIThinking: "需为你提供高容错率的方案。"
    )
}

extension BioHardwareData {
    static let mock = BioHardwareData(
        chronotype: "[夜猫子型 (Wolf)]：数据显示你的自然觉醒时间在 09:30。强迫 06:00 起床会让你皮质醇飙升。",
        chronotypeAIThinking: "当前策略 - 推迟高强度任务至 10:00 以后。",
        caffeineSensitivity: "[慢代谢者]：你在下午 14:00 喝咖啡会导致当晚入睡潜伏期增加 45 分钟。",
        caffeineSensitivityAIThinking: "当前策略 - 为你设置了 12:00 的咖啡因熔断机制。",
        stressResilience: "[中低]：静息心率 (RHR) 对压力反应敏感。高压会议后，你的 HRV 恢复时间通常需要 4 小时。"
    )
}

extension NeuroSoftwareData {
    static let mock = NeuroSoftwareData(
        dietaryKryptonite: "[碳水安抚]：在高压状态下（心率 > 100），你点\"高碳水外卖\"的概率高达 90%。",
        exercisePreference: "[独狼模式] & [数据驱动]：你不喜欢团课，喜欢盯着 Apple Watch 的圆环看。你更愿意执行\"且有明确数据反馈\"的任务（如 Zone 2 跑步），而不是模糊的任务（如冥想）。",
        sleepTrigger: "[声音敏感]：白噪音对你无效，但\"播客（人声）\"能让你在 15 分钟内入睡。"
    )
}

extension ArchivesData {
    static let mock = ArchivesData(
        failedProjects: [
            FailedProject(
                name: "生酮饮食",
                duration: "坚持了 2 周。",
                failureReason: "社交困扰，无法和同事聚餐。"
            ),
            FailedProject(
                name: "晨跑计划",
                duration: "坚持了 3 天。",
                failureReason: "起不来，导致全天精神萎靡。"
            )
        ],
        strategyAdjustments: [
            "不采用极端饮食，改为\"饮食顺序调整法\"。",
            "不强迫晨跑，改为\"下班后快走\"。"
        ]
    )
}

extension AboutMeData {
    static let mock = AboutMeData(
        goals: .mock,
        bioHardware: .mock,
        neuroSoftware: .mock,
        archives: .mock
    )
}
