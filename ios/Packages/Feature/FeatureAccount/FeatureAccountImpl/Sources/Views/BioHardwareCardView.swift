import SwiftUI
import ThemeKit

/// Bio-Hardware card view displaying physiological information
struct BioHardwareCardView: View {
    let data: BioHardwareData
    let onEdit: () -> Void

    var body: some View {
        AboutMeCardView(
            title: "🧬 生理信息",
            subtitle: "",
            onEdit: onEdit
        ) {
            VStack(alignment: .leading, spacing: 20) {
                // Chronotype section
                VStack(alignment: .leading, spacing: 12) {
                    sectionHeader(title: "昼夜节律——社交时差受害者")

                    Text(data.chronotype)
                        .font(.system(size: 15))
                        .foregroundColor(.Palette.textSecondary)
                        .lineSpacing(6)

                    PascalCommentView(comment: data.chronotypePascalComment)
                }

                Divider()

                // Caffeine Metabolism section
                VStack(alignment: .leading, spacing: 12) {
                    sectionHeader(title: "咖啡因代谢——甚至可以说\"拥堵\"")

                    Text(data.caffeineMetabolism)
                        .font(.system(size: 15))
                        .foregroundColor(.Palette.textSecondary)
                        .lineSpacing(6)

                    if !data.caffeineMetabolismPascalComment.isEmpty {
                        PascalCommentView(comment: data.caffeineMetabolismPascalComment)
                    }
                }

                Divider()

                // Stress Resilience section
                VStack(alignment: .leading, spacing: 12) {
                    sectionHeader(title: "压力耐受——高敏感型")

                    Text(data.stressResilience)
                        .font(.system(size: 15))
                        .foregroundColor(.Palette.textSecondary)
                        .lineSpacing(6)
                }
            }
        }
    }

    @ViewBuilder
    private func sectionHeader(title: String) -> some View {
        Text(title)
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.Palette.textPrimary)
    }
}

#Preview {
    ScrollView {
        BioHardwareCardView(
            data: .mock,
            onEdit: { print("Edit bio-hardware") }
        )
        .padding()
    }
    .background(Color.Palette.bgBase)
}
