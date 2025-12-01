import SwiftUI

/// 健康状态模型
struct HealthStatus {
    let overallPerformance: Int // 当前机体效能百分比
    let temperature: Int // 温度
    let metrics: [HealthMetric]
    let expertInsight: ExpertInsight
}

/// 健康指标
struct HealthMetric: Identifiable {
    let id = UUID()
    let icon: String // emoji
    let name: String
    let value: String
    let status: MetricStatus
    let description: String

    enum MetricStatus {
        case high
        case low
        case normal

        var color: Color {
            switch self {
            case .high: return Color(red: 1.0, green: 0.4, blue: 0.4)
            case .low: return Color(red: 1.0, green: 0.8, blue: 0.3)
            case .normal: return Color(red: 0.4, green: 0.9, blue: 0.6)
            }
        }

        var emoji: String {
            switch self {
            case .high: return "🔴"
            case .low: return "🟡"
            case .normal: return "🟢"
            }
        }
    }
}

/// 专家简报
struct ExpertInsight {
    let greeting: String
    let analysis: String
    let recommendation: String
}

extension HealthStatus {
    static let sample = HealthStatus(
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
                name: "水分",
                value: "优",
                status: .normal,
                description: "代谢正常"
            )
        ],
        expertInsight: ExpertInsight(
            greeting: "早！凌安。",
            analysis: "数据显示你的副交感神经昨晚未能完全接管，导致心率变异性 (HRV) 偏低。",
            recommendation: "这意味着你今天的'情绪刹车片'比较薄，容易焦虑、容易焦虑。建议将今天的高压会议推后，优先保证神经系统的恢复。"
        )
    )
}
