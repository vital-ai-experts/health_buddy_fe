import SwiftUI
import ThemeKit

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
            case .high: return Color.Palette.dangerMain
            case .low: return Color.Palette.warningMain
            case .normal: return Color.Palette.successMain
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
