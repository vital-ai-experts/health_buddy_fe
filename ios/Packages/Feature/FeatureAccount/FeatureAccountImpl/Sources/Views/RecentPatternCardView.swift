import SwiftUI
import ThemeKit

/// Recent Pattern card view displaying pattern analysis
struct RecentPatternCardView: View {
    let data: RecentPatternData
    let onEdit: () -> Void

    var body: some View {
        AboutMeCardView(
            title: "📅 近期模式回溯",
            subtitle: "12/02-12/05",
            onEdit: onEdit
        ) {
            VStack(alignment: .leading, spacing: 16) {
                // User's pattern content (editable)
                Text(data.content)
                    .font(.system(size: 15))
                    .foregroundColor(.Palette.textSecondary)
                    .lineSpacing(6)

                // Pascal's comment (non-editable, special bubble style)
                PascalCommentView(comment: data.pascalComment)
            }
        }
    }
}

#Preview {
    ScrollView {
        RecentPatternCardView(
            data: .mock,
            onEdit: { print("Edit recent pattern") }
        )
        .padding()
    }
    .background(Color.Palette.bgBase)
}
