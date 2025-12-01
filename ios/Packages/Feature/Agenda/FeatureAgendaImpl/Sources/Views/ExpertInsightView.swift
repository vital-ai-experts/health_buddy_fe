import SwiftUI
import ThemeKit

/// 专家简报视图 - 引用样式
struct ExpertInsightView: View {
    let insight: ExpertInsight

    var body: some View {
        let accentColor = Color.Palette.warningMain

        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                Text("“")
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundColor(accentColor.opacity(0.9))

                Rectangle()
                    .fill(accentColor.opacity(0.4))
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
                    .padding(.top, -6)
            }
            .frame(width: 18, alignment: .top)

            VStack(alignment: .leading, spacing: 12) {
                // 问候语
                Text(insight.greeting)
                    .font(.system(size: 18, weight: .semibold, design: .serif))
                    .foregroundColor(.Palette.textPrimary)

                // 分析和建议
                VStack(alignment: .leading, spacing: 8) {
                    Text(insight.analysis)
                    Text(insight.recommendation)
                }
                .font(.system(size: 15, weight: .regular, design: .serif))
                .foregroundColor(.Palette.textSecondary)
                .lineSpacing(5)
            }
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    VStack {
        ExpertInsightView(insight: HealthStatus.sample.expertInsight)
        Spacer()
    }
    .background(Color.Palette.bgBase)
}
