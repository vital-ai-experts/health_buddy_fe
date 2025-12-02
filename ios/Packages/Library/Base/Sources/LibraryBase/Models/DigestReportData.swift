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
