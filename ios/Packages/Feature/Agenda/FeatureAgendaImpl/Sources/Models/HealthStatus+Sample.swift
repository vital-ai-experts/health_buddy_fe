import SwiftUI
import Foundation

extension HealthStatus {
    /// 挑战型日程（参考左图）
    static let sampleChallenge = HealthStatus(
        overallPerformance: 78,
        temperature: 18,
        metrics: [
            HealthMetric(
                icon: "🟢",
                name: "机能",
                value: "充盈",
                status: .normal,
                description: "身体恢复情况良好"
            ),
            HealthMetric(
                icon: "🔴",
                name: "皮质醇",
                value: "超限",
                status: .high,
                description: "当前会议过多"
            ),
            HealthMetric(
                icon: "🟡",
                name: "水  分",
                value: "不足",
                status: .low,
                description: "需要补充水分"
            )
        ],
        expertInsight: ExpertInsight(
            greeting: "早上好，凌安。",
            analysis: "你的生理状态已就位，但这将是极具挑战的一天。数据显示你的小肠今天补给不足，脾的供养大约 30%，综合就绪度不足 70%。建议你砍掉上午 10 点的非核心会议，把注意力留给关键汇报。",
            recommendation: "保持专注，不要让市场舆情干扰你的数据汇报，非关键会议尽量委派或延后。"
        )
    )

    /// 恢复提醒型日程（参考右图）
    static let sampleRecovery = HealthStatus(
        overallPerformance: 78,
        temperature: 18,
        metrics: [
            HealthMetric(
                icon: "🔴",
                name: "皮质醇",
                value: "高",
                status: .high,
                description: "压力残留"
            ),
            HealthMetric(
                icon: "🟡",
                name: "睡眠债",
                value: "-2.5h",
                status: .low,
                description: "需要补觉"
            ),
            HealthMetric(
                icon: "🟢",
                name: "水  分",
                value: "优",
                status: .normal,
                description: "代谢正常"
            )
        ],
        expertInsight: ExpertInsight(
            greeting: "晚上好，凌安。",
            analysis: "一路奔波让去甲肾上腺素持续偏高，HRV 较昨日下降，恢复不足。",
            recommendation: "今晚不要熬夜，做 1 组 10 秒胸椎伸展，洗澡时放松肩颈，给神经系统足够恢复时间。"
        )
    )

    /// 时差/旅途疲劳
    static let sampleTravelFatigue = HealthStatus(
        overallPerformance: 72,
        temperature: 16,
        metrics: [
            HealthMetric(
                icon: "🟡",
                name: "睡眠债",
                value: "-3h",
                status: .low,
                description: "需要午后短休"
            ),
            HealthMetric(
                icon: "🔴",
                name: "皮质醇",
                value: "偏高",
                status: .high,
                description: "时差压力"
            ),
            HealthMetric(
                icon: "🟢",
                name: "水  分",
                value: "良好",
                status: .normal,
                description: "补水到位"
            )
        ],
        expertInsight: ExpertInsight(
            greeting: "中午好，凌安。",
            analysis: "长途飞行让你的交感神经仍在高转速，睡眠债累积，HRV 偏低，但补水做得不错。",
            recommendation: "建议 14:00 前安排 15 分钟 NSFR，晚间避免咖啡因，拉伸胸椎和腘绳肌，帮助神经系统从“战斗模式”切回恢复态。"
        )
    )

    /// 深度工作窗口
    static let sampleFocus = HealthStatus(
        overallPerformance: 84,
        temperature: 21,
        metrics: [
            HealthMetric(
                icon: "🟢",
                name: "情绪",
                value: "稳",
                status: .normal,
                description: "易于专注"
            ),
            HealthMetric(
                icon: "🟢",
                name: "HRV",
                value: "均衡",
                status: .normal,
                description: "自主神经平衡"
            ),
            HealthMetric(
                icon: "🟡",
                name: "葡萄糖",
                value: "偏低",
                status: .low,
                description: "适合深度工作"
            )
        ],
        expertInsight: ExpertInsight(
            greeting: "早安，凌安。",
            analysis: "当前神经张力低、情绪平稳，是今天最适合深度工作的 3 小时窗口。",
            recommendation: "先处理需要逻辑推演的任务，咖啡保持 1 杯内。深度工作后做 5 分钟快走，避免血糖骤降带来的疲劳。"
        )
    )

    /// 夜间放松/蓝光管理
    static let sampleEvening = HealthStatus(
        overallPerformance: 65,
        temperature: 19,
        metrics: [
            HealthMetric(
                icon: "🔴",
                name: "皮质醇",
                value: "偏高",
                status: .high,
                description: "需要降压呼吸"
            ),
            HealthMetric(
                icon: "🟢",
                name: "水  分",
                value: "充足",
                status: .normal,
                description: "代谢正常"
            ),
            HealthMetric(
                icon: "🟡",
                name: "蓝光暴露",
                value: "偏高",
                status: .low,
                description: "减少屏幕光线"
            )
        ],
        expertInsight: ExpertInsight(
            greeting: "晚上好，凌安。",
            analysis: "晚间皮质醇回落不理想，蓝光暴露拉高了觉醒度，可能影响入睡潜伏期。",
            recommendation: "调暗室内灯光，做 4-7-8 呼吸 5 轮，屏幕切夜间模式，睡前 30 分钟用 60lux 暖光代替白光。"
        )
    )

    static let samples: [HealthStatus] = [
        sampleChallenge,
        sampleRecovery,
        sampleTravelFatigue,
        sampleFocus,
        sampleEvening
    ]

    static var sample: HealthStatus {
        samples.first ?? sampleRecovery
    }

    private static var cachedRandomSample: HealthStatus?
    private static var cachedRandomDate: Date?

    /// 返回缓存 3 分钟的随机样本，避免短时间内频繁切换
    static func randomSample(cacheDuration: TimeInterval = 180) -> HealthStatus {
        let now = Date()
        if let cached = cachedRandomSample,
           let cachedDate = cachedRandomDate,
           now.timeIntervalSince(cachedDate) < cacheDuration {
            return cached
        }

        let newSample = samples.randomElement() ?? sample
        cachedRandomSample = newSample
        cachedRandomDate = now
        return newSample
    }
}
