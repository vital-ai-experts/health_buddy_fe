import Foundation

/// 副本简报数据模型
public struct DigestReportData: Codable, Equatable, Hashable {
    public let title: String             // 副本标题
    public let currentDay: Int           // 当前天数
    public let totalDays: Int            // 总天数
    public let progressStatus: String    // 进度状态：超前、正常、落后
    public let targetValue: Double       // 目标值（虚线）
    public let dataPoints: [DataPoint]   // 折线图数据点
    public let message: String           // 底部说明文字

    public struct DataPoint: Codable, Equatable, Hashable, Identifiable {
        public let id: String
        public let day: Int
        public let value: Double

        public init(id: String = UUID().uuidString, day: Int, value: Double) {
            self.id = id
            self.day = day
            self.value = value
        }
    }

    public init(
        title: String,
        currentDay: Int,
        totalDays: Int,
        progressStatus: String,
        targetValue: Double,
        dataPoints: [DataPoint],
        message: String
    ) {
        self.title = title
        self.currentDay = currentDay
        self.totalDays = totalDays
        self.progressStatus = progressStatus
        self.targetValue = targetValue
        self.dataPoints = dataPoints
        self.message = message
    }

    /// 从JSON字符串解析
    public static func from(jsonString: String) -> DigestReportData? {
        guard let data = jsonString.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(DigestReportData.self, from: data)
    }

    /// 转换为JSON字符串
    public func toJSONString() -> String? {
        guard let data = try? JSONEncoder().encode(self),
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        return string
    }
}

public extension DigestReportData {
    static let mock = DigestReportData(
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
