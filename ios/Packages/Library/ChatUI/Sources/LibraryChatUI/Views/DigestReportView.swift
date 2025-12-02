import SwiftUI
import Charts
import ThemeKit

/// 副本简报数据模型
public struct DigestReportData: Codable, Equatable, Hashable {
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
        currentDay: Int,
        totalDays: Int,
        progressStatus: String,
        targetValue: Double,
        dataPoints: [DataPoint],
        message: String
    ) {
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

/// 副本简报卡片视图
public struct DigestReportView: View {
    let reportData: DigestReportData?

    public init(reportData: DigestReportData?) {
        self.reportData = reportData
    }

    public var body: some View {
        if let data = reportData {
            VStack(alignment: .leading, spacing: 16) {
                // 顶部：日期和进度状态
                HStack {
                    Text("Day \(data.currentDay)/\(data.totalDays)")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color.Palette.textPrimary)

                    Spacer()

                    HStack(spacing: 6) {
                        Circle()
                            .fill(progressColor(for: data.progressStatus))
                            .frame(width: 10, height: 10)

                        Text("进度：\(data.progressStatus)")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(progressColor(for: data.progressStatus))
                    }
                }

                // 中间：折线图
                ChartView(
                    dataPoints: data.dataPoints,
                    targetValue: data.targetValue
                )
                .frame(height: 120)

                // 底部：说明文字
                Text(data.message)
                    .font(.system(size: 15))
                    .foregroundColor(Color.Palette.textSecondary)
                    .lineSpacing(4)
            }
            .padding(20)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.08),
                        Color.purple.opacity(0.08)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.Palette.surfaceElevatedBorder, lineWidth: 1)
            )
            .shadow(color: Color.Palette.textPrimary.opacity(0.08), radius: 8, x: 0, y: 4)
        } else {
            EmptyView()
        }
    }

    private func progressColor(for status: String) -> Color {
        switch status {
        case "超前":
            return Color.green
        case "正常":
            return Color.blue
        case "落后":
            return Color.red
        default:
            return Color.gray
        }
    }
}

/// 折线图视图
private struct ChartView: View {
    let dataPoints: [DigestReportData.DataPoint]
    let targetValue: Double

    var body: some View {
        Chart {
            // 目标虚线
            RuleMark(y: .value("Target", targetValue))
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [8, 4]))
                .foregroundStyle(Color.red.opacity(0.6))

            // 数据折线
            ForEach(dataPoints) { point in
                LineMark(
                    x: .value("Day", point.day),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(Color.red)
                .lineStyle(StrokeStyle(lineWidth: 2))

                PointMark(
                    x: .value("Day", point.day),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(Color.red)
                .symbolSize(40)
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        DigestReportView(
            reportData: DigestReportData(
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
                message: "得益于你连续 5 天完成了"数字日落"任务，你的入睡潜伏期（Latency）缩短了 40%。大脑现在已经学会了关灯即睡的条件反射，我们正在赢得这场战役！"
            )
        )
        .padding()
    }
}
