import SwiftUI

/// 机体状态模型
struct BodyStatus {
    let overallEfficiency: Double // 0.0 - 1.0
    let cortisolStatus: StatusIndicator
    let sleepDebt: StatusIndicator
    let hydration: StatusIndicator
    let temperature: String

    struct StatusIndicator {
        let icon: String
        let title: String
        let value: String
        let tag: String
        let color: Color
    }
}

extension BodyStatus {
    static let sample = BodyStatus(
        overallEfficiency: 0.78,
        cortisolStatus: StatusIndicator(
            icon: "🔴",
            title: "皮质醇",
            value: "高",
            tag: "压力残留",
            color: .orange
        ),
        sleepDebt: StatusIndicator(
            icon: "🟡",
            title: "睡眠债",
            value: "-2.5h",
            tag: "需要补觉",
            color: .yellow
        ),
        hydration: StatusIndicator(
            icon: "🟢",
            title: "水分",
            value: "优",
            tag: "代谢正常",
            color: .green
        ),
        temperature: "18°C"
    )
}
