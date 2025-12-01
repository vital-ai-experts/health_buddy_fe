import SwiftUI

/// 专家简报视图 - 引用样式
struct ExpertInsightView: View {
    let insight: ExpertInsight

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 问候语
            Text(insight.greeting)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.black.opacity(0.85))

            // 分析和建议
            VStack(alignment: .leading, spacing: 8) {
                Text(insight.analysis)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.black.opacity(0.75))
                    .lineSpacing(4)

                Text(insight.recommendation)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.black.opacity(0.75))
                    .lineSpacing(4)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }
}

#Preview {
    VStack {
        ExpertInsightView(insight: HealthStatus.sample.expertInsight)
        Spacer()
    }
    .background(Color(red: 0.98, green: 0.98, blue: 0.96))
}
