import SwiftUI
import ThemeKit

/// 专家简报视图 - 引用样式
struct ExpertInsightView: View {
    let insight: ExpertInsight

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(insight.title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.Palette.textPrimary)
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)

            Text(insight.body)
                .font(.system(size: 16))
                .foregroundColor(.Palette.textSecondary)
                .lineSpacing(6)

            ScienceNoteView(content: insight.science)
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
