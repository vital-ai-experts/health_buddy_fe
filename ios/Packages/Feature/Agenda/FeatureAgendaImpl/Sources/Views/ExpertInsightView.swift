import SwiftUI
import ThemeKit

/// 专家简报视图 - 引用样式
struct ExpertInsightView: View {
    let insight: ExpertInsight

    var body: some View {
        let accentColor = Color.Palette.warningMain

        VStack(alignment: .leading, spacing: 16) {
            Text(insight.title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.Palette.textPrimary)
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)

            HStack(alignment: .top, spacing: 8) {
                VStack(spacing: 0) {
                    Text("“")
                        .font(.system(size: 22, weight: .bold, design: .serif))
                        .foregroundColor(accentColor.opacity(0.9))
                        .padding(.top, -4)

                    Rectangle()
                        .fill(accentColor.opacity(0.4))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                        .padding(.top, -2)
                }
                .frame(width: 18, alignment: .top)

                VStack(alignment: .leading, spacing: 12) {
                    Text(insight.body)
                        .font(.system(size: 16))
                        .foregroundColor(.Palette.textSecondary)
                        .lineSpacing(6)

                    ScienceNoteView(content: insight.science)
                }
            }
        }
        .padding(.horizontal, 12)
    }
}

#Preview {
    VStack {
        ExpertInsightView(insight: HealthStatus.sample.expertInsight)
        Spacer()
    }
    .background(Color.Palette.bgBase)
}
