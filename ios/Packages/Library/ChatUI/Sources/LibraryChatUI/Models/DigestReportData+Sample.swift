import Foundation

extension DigestReportData {
    public static let mock = DigestReportData(
        title: "观呼吸菩萨",
        currentDay: 12,
        totalDays: 30,
        progressStatus: "超前",
        targetValue: 65,
        dataPoints: [
            .init(day: 1, value: 45),
            .init(day: 2, value: 55),
            .init(day: 3, value: 52),
            .init(day: 4, value: 58),
            .init(day: 5, value: 50),
            .init(day: 6, value: 48),
            .init(day: 7, value: 62),
            .init(day: 8, value: 60),
            .init(day: 9, value: 70),
            .init(day: 10, value: 68),
            .init(day: 11, value: 72),
            .init(day: 12, value: 75)
        ],
        message: "得益于你坚持完成「深度呼吸」和「正念冥想」任务，你的心率变异性（HRV）提升了 18%！这意味着你的自主神经系统正在恢复平衡，抗压能力显著增强。继续保持，你的身体正在变得更强韧！"
    )
}
