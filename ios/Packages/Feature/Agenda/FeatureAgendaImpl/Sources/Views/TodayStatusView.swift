import SwiftUI

/// 全局状态区 - "今天"模块
struct TodayStatusView: View {
    let healthStatus: HealthStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // 标题和天气
            HStack {
                Text("今天")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundColor(.black.opacity(0.9))

                Spacer()

                HStack(spacing: 6) {
                    Text("☀️")
                        .font(.system(size: 20))
                    Text("\(healthStatus.temperature)°C")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.black.opacity(0.7))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.6))
                .clipShape(Capsule())
            }
            .padding(.horizontal, 20)

            // 圆环进度和健康指标
            VStack(spacing: 20) {
                // 圆环进度
                PerformanceCircleView(percentage: healthStatus.overallPerformance)
                    .frame(height: 240)

                // 健康指标
                HealthMetricsView(metrics: healthStatus.metrics)
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 24)
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
                .frame(width: 200, height: 200)

            // 进度圆环
            Circle()
                .trim(from: 0, to: CGFloat(percentage) / 100)
                .stroke(
                    Color(red: 0.8, green: 0.7, blue: 0.4),
                    style: StrokeStyle(lineWidth: 32, lineCap: .round)
                )
                .frame(width: 200, height: 200)
                .rotationEffect(.degrees(-90))

            // 中间的百分比文字
            VStack(spacing: 4) {
                Text("\(percentage)%")
                    .font(.system(size: 52, weight: .bold))
                    .foregroundColor(.black.opacity(0.9))

                Text("当前机体效能")
                    .font(.system(size: 14))
                    .foregroundColor(.black.opacity(0.6))
            }
        }
    }
}

/// 健康指标视图
private struct HealthMetricsView: View {
    let metrics: [HealthMetric]

    var body: some View {
        HStack(spacing: 0) {
            // 左侧指标
            VStack(alignment: .leading, spacing: 8) {
                ForEach(metrics) { metric in
                    HStack(spacing: 8) {
                        Text("\(metric.status.emoji)")
                            .font(.system(size: 16))

                        Text("\(metric.name)：")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.black.opacity(0.8))

                        Text(metric.value)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.black.opacity(0.9))

                        Text("]")
                            .font(.system(size: 15))
                            .foregroundColor(.black.opacity(0.6))
                    }
                }
            }

            Spacer()

            // 右侧描述
            VStack(alignment: .trailing, spacing: 8) {
                ForEach(metrics) { metric in
                    Text(metric.description)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.black.opacity(0.7))
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
    .background(Color(red: 0.98, green: 0.98, blue: 0.96))
}
