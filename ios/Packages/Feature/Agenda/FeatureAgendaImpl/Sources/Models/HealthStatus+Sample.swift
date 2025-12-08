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
            title: "✈︎ 差旅模式：强制减负",
            body: """
            看你定位变到上海了，在出差吗？这一路奔波够辛苦的。
            今晚咱们不硬撑，我已经把你原定的“高强度训练”全砍了，临时替换成了一组“酒店恢复”任务。今晚的目标就一个：让身体真正落地。
            """,
            science: """
            “长途旅行会导致‘神经肌肉功能’暂时性下降，并伴随皮质醇水平升高。在抵达后的 24 小时内进行高强度训练，受伤风险比平时高出 2.7 倍。” —— International Journal of Sports Physiology and Performance
            """
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
            title: "⚠️ 皮质醇过载预警",
            body: """
            监测到你的压力读数正在爬坡，大脑已经进入了“低效疲劳区”。再硬撑下去也只是在做无用功。
            现在的策略必须是“物理降温”。我为你生成了一个 3 分钟的呼吸微任务 🌬️，去下面点击执行，先把状态找回来。
            """,
            science: """
            “每天仅需 5 分钟的‘循环叹气’（Cyclic Sighing），在改善情绪和降低生理唤醒方面，效果优于正念冥想。” —— Cell Reports Medicine, 2023
            """
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
            title: "🩹 主动恢复日",
            body: """
            昨晚的酒精还在影响心率，你的身体现在正忙着“排毒”，实在分不出能量去举铁了 。
            今天千万别逞强，我把原本的高强度计划全撤了，替换成了一组“主动恢复”任务。今天的目标就一个：让自己舒服点😌。
            """,
            science: """
            “酒精会显著抑制雷帕霉素靶蛋白（mTOR）的信号传导，从而阻碍肌肉蛋白质的合成。此时强行训练，不仅无法增肌，反而会加剧皮质醇分泌，导致肌肉分解。” —— Journal of Applied Physiology
            """
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
            title: "⚡️ 黄金专注窗口",
            body: """
            满血复活！各项恢复数据都冲到了本周巅峰。这种黄金状态很稀缺，别浪费在回邮件这种琐事上 📧。
            建议把火力集中在最难的工作上。为此，我给你准备了几个能把“专注力”锁住的任务，去试试看。
            """,
            science: """
            “大脑的高强度专注遵循‘次昼夜节律’。利用好清醒后的黄金 90 分钟周期进行深度工作，其产出效率是碎片化时间的 5 倍以上。” —— Andrew Huberman, Huberman Lab Podcast
            """
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
            title: "🧠 大脑还债模式",
            body: """
            是不是感觉有点低落和脑雾？其实不是工作的问题，这是周六那顿酒的回旋镖飞回来了。
            昨晚你的身体为了补齐之前被酒精压抑的缺口，开启了“报复性做梦”。这种高强度的脑部活动把你的神经递质耗干了。这只是生理波动，不是心理问题。早点睡，明天就能满血复活。
            """,
            science: """
            “酒精会显著抑制快速眼动睡眠（REM）。当酒精代谢完毕，大脑会产生强烈的‘REM 反弹’效应。这种剧烈的脑活动不仅无法恢复精力，还会导致次日皮质醇水平升高和情绪调节能力下降。” —— Sleep Medicine Reviews
            """
        )
    )

    /// 断食反噬
    static let sampleFastingBackfire = HealthStatus(
        overallPerformance: 62,
        temperature: 17,
        metrics: [
            HealthMetric(
                icon: "🔴",
                name: "HRV",
                value: "砸穿",
                status: .low,
                description: "生存危机模式"
            ),
            HealthMetric(
                icon: "🔴",
                name: "皮质醇",
                value: "飙升",
                status: .high,
                description: "HPA轴激活"
            ),
            HealthMetric(
                icon: "🟡",
                name: "糖原",
                value: "亏空",
                status: .low,
                description: "急需碳水"
            )
        ],
        expertInsight: ExpertInsight(
            title: "⚠️ 被断食反噬中",
            body: """
            最近 HRV 走低的原因我找到了：因为你断食没选对日子。每天上午你都有一场 2 小时的例会，配合断食策略，直接把身体逼急了，为了给大脑供能，皮质醇飙升，这种人为制造的生存危机直接砸穿了你的 HRV。
            赶紧吃口碳水，别让身体以为你在遭灾。
            """,
            science: """
            “空腹叠加高脑力负荷会激活 HPA 轴，引发皮质醇飙升。这种急性应激不仅阻断燃脂，更会持续压低 HRV。” —— Journal of Clinical Endocrinology
            """
        )
    )

    static let samples: [HealthStatus] = [
        sampleChallenge,
        sampleRecovery,
        sampleTravelFatigue,
        sampleFocus,
        sampleEvening,
        sampleFastingBackfire,
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
