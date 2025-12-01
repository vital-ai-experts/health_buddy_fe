import Foundation

/// 专家简报模型
struct ExpertInsight {
    let greeting: String
    let userName: String
    let analysis: String
    let recommendation: String
}

extension ExpertInsight {
    static let sample = ExpertInsight(
        greeting: "早！",
        userName: "凌安",
        analysis: "数据显示你的副交感神经昨晚未能完全接管，导致心率变异性 (HRV) 偏低。",
        recommendation: "这意味着你今天的'情绪刹车片'比较薄，容易焦虑。 建议将今天的高压会议推后，优先保证神经系统的恢复。"
    )
}
