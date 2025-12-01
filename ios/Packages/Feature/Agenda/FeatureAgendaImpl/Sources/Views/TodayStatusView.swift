import SwiftUI
import ThemeKit

/// 全局状态区 - "今天"模块
struct TodayStatusView: View {
    let healthStatus: HealthStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // 标题和天气
            HStack {
                Text("今天")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.Palette.textPrimary)

                Spacer()

                HStack(spacing: 6) {
                    Text("☀️")
                        .font(.system(size: 20))
                    Text("\(healthStatus.temperature)°C")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.Palette.textSecondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.Palette.infoBgSoft)
                .clipShape(Capsule())
            }
            .padding(.horizontal, 20)

            // 圆环进度和健康指标
            VStack(spacing: 20) {
                // 圆环进度
                PerformanceCircleView(percentage: healthStatus.overallPerformance)
                    .frame(height: 200)

                // 健康指标
                HealthMetricsView(metrics: healthStatus.metrics)
            }
            .padding(.horizontal, 20)
        }
    }
}

/// 圆环进度视图
private struct PerformanceCircleView: View {
    let percentage: Int

    var body: some View {
        ZStack {
            // 背景圆环
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 32)
                .frame(width: 180, height: 180)

            // 进度圆环
            Circle()
                .trim(from: 0, to: CGFloat(percentage) / 100)
                .stroke(
                    ringColor,
                    style: StrokeStyle(lineWidth: 32, lineCap: .round)
                )
                .frame(width: 180, height: 180)
                .rotationEffect(.degrees(-90))

            // 中间的百分比文字
            VStack(spacing: 4) {
                Text("\(percentage)%")
                    .font(.system(size: 46, weight: .bold))
                    .foregroundColor(.Palette.textPrimary)

                Text("当前机体效能")
                    .font(.system(size: 14))
                    .foregroundColor(.Palette.textSecondary)
            }
        }
    }

    private var ringColor: Color {
        if percentage >= 80 {
            return Color.Palette.successMain
        } else if percentage >= 60 {
            return Color.Palette.warningMain
        } else {
            return Color.Palette.dangerMain
        }
    }
}

/// 健康指标视图
private struct HealthMetricsView: View {
    let metrics: [HealthMetric]

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            ForEach(metrics) { metric in
                HStack(spacing: 8) {
                    Text("\(metric.status.emoji)")
                        .font(.system(size: 16))

                    Text("\(metric.name)：")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.Palette.textPrimary)

                    Text(metric.value)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.Palette.textPrimary)
                    
                    Spacer()
                    
                    Text(metric.description)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.Palette.warningText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.Palette.warningBgSoft)
                        )
                }
            }
        }
    }
}

#Preview {
    VStack {
        TodayStatusView(healthStatus: HealthStatus.sample)
        Spacer()
    }
    .background(Color.Palette.bgBase)
}
