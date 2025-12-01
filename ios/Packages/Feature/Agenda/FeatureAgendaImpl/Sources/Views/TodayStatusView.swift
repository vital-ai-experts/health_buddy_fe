import SwiftUI

/// "今天"全局状态区视图
struct TodayStatusView: View {
    let bodyStatus: BodyStatus
    let expertInsight: ExpertInsight

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // 标题和天气
            HStack {
                Text("今天")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.black)

                Spacer()

                HStack(spacing: 4) {
                    Text("☀️")
                        .font(.system(size: 18))
                    Text(bodyStatus.temperature)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black.opacity(0.7))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.7))
                .clipShape(Capsule())
            }

            // 环形图
            CircularProgressView(percentage: bodyStatus.overallEfficiency)
                .frame(height: 220)
                .padding(.vertical, 12)

            // 身体状态指标
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    StatusIndicatorRow(indicator: bodyStatus.cortisolStatus)
                    StatusIndicatorRow(indicator: bodyStatus.sleepDebt)
                }
                StatusIndicatorRow(indicator: bodyStatus.hydration)
            }

            // 专家简报
            ExpertInsightView(insight: expertInsight)
                .padding(.top, 8)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }
}

/// 环形进度视图
private struct CircularProgressView: View {
    let percentage: Double

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // 背景圆环
                Circle()
                    .stroke(Color.gray.opacity(0.15), lineWidth: 20)
                    .frame(width: 180, height: 180)

                // 进度圆环
                Circle()
                    .trim(from: 0, to: percentage)
                    .stroke(
                        Color(red: 0.76, green: 0.62, blue: 0.35),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(-90))

                // 百分比文字
                Text("\(Int(percentage * 100))%")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundColor(.black)
            }

            Text("当前机体效能")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.black.opacity(0.6))
        }
    }
}

/// 状态指标行
private struct StatusIndicatorRow: View {
    let indicator: BodyStatus.StatusIndicator

    var body: some View {
        HStack(spacing: 8) {
            Text(indicator.icon)
                .font(.system(size: 16))

            Text("\(indicator.title)：")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.black.opacity(0.8))

            Text(indicator.value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.black)

            Spacer()

            Text(indicator.tag)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.black)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(indicator.color.opacity(0.15))
                .clipShape(Capsule())
        }
    }
}

/// 专家简报视图
private struct ExpertInsightView: View {
    let insight: ExpertInsight

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 0) {
                Text(insight.greeting)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                + Text(" \(insight.userName)。")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                + Text(insight.analysis)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.black.opacity(0.75))
            }

            Text(insight.recommendation)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.black.opacity(0.75))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .background(Color.gray.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    ScrollView {
        TodayStatusView(
            bodyStatus: .sample,
            expertInsight: .sample
        )
    }
    .background(Color(red: 0.96, green: 0.96, blue: 0.94))
}
