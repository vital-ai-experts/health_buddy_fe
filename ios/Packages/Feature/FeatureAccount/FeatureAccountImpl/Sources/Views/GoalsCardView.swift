import SwiftUI
import ThemeKit

/// Goals card view displaying The Core Drivers
struct GoalsCardView: View {
    let data: GoalsData
    let onEdit: () -> Void

    var body: some View {
        AboutMeCardView(
            title: "🎯 目标与核心驱动",
            subtitle: "",
            onEdit: onEdit
        ) {
            VStack(alignment: .leading, spacing: 16) {
                // Surface Goal Section
                sectionItem(
                    title: "表面意图",
                    content: data.surfaceGoal
                )

                Divider()
                    .padding(.vertical, 4)

                // Deep Motivation Section
                VStack(alignment: .leading, spacing: 12) {
                    Text(data.deepMotivationTitle)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.Palette.textPrimary)

                    Text(data.deepMotivationContent)
                        .font(.system(size: 15))
                        .foregroundColor(.Palette.textSecondary)
                        .lineSpacing(6)
                }

                // Pascal's comment (non-editable)
                PascalCommentView(comment: data.pascalComment)
            }
        }
    }

    @ViewBuilder
    private func sectionItem(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.Palette.textPrimary)

            Text(content)
                .font(.system(size: 15))
                .foregroundColor(.Palette.textSecondary)
                .lineSpacing(6)
        }
    }
}

#Preview {
    ScrollView {
        GoalsCardView(
            data: .mock,
            onEdit: { print("Edit goals") }
        )
        .padding()
    }
    .background(Color.Palette.bgBase)
}
