import SwiftUI
import Charts
import ThemeKit

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
                    Text("\(data.title) \(data.currentDay)/\(data.totalDays)")
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
                .frame(height: 160)

                // 底部：说明文字
                Text(data.message)
                    .font(.system(size: 15))
                    .foregroundColor(Color.Palette.textSecondary)
                    .lineSpacing(4)
            }
            .padding(20)
            .background(Color.Palette.surfaceElevated)
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
                    x: .value("Day", dateForDay(point.day)),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(Color.red)
                .lineStyle(StrokeStyle(lineWidth: 2))

                PointMark(
                    x: .value("Day", dateForDay(point.day)),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(Color.red)
                .symbolSize(40)
            }
        }
        .chartYScale(domain: 30...80)
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                AxisGridLine()
                    .foregroundStyle(Color.gray.opacity(0.2))
                AxisValueLabel()
                    .font(.system(size: 10))
                    .foregroundStyle(Color.gray)
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 3)) { value in
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    .font(.system(size: 9))
                    .foregroundStyle(Color.gray.opacity(0.7))
            }
        }
        .chartYAxisLabel("HRV", position: .top, alignment: .leading, spacing: 20)
    }
    
    // 计算每一天对应的日期（从今天往回推）
    private func dateForDay(_ day: Int) -> Date {
        let calendar = Calendar.current
        let today = Date()
        // 假设 day 1 是最早的，day 12 是最近的（今天或接近今天）
        // 我们从今天开始往回推
        let maxDay = dataPoints.map { $0.day }.max() ?? 12
        let daysAgo = maxDay - day
        return calendar.date(byAdding: .day, value: -daysAgo, to: today) ?? today
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        DigestReportView(
            reportData: .mock
        )
        .padding()
    }
}

