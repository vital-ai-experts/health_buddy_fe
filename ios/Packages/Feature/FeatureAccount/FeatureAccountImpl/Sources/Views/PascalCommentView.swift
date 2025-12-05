import SwiftUI
import ThemeKit

/// Pascal's comment bubble view - non-editable special style
struct PascalCommentView: View {
    let comment: String

    var body: some View {
        if !comment.isEmpty {
            HStack(alignment: .top, spacing: 12) {
                // Pascal avatar/icon
                Text("Pascal 🤔:")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.Palette.infoMain)
                    .fixedSize(horizontal: true, vertical: false)

                // Comment text
                Text(comment)
                    .font(.system(size: 15))
                    .foregroundColor(.Palette.infoMain.opacity(0.9))
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.Palette.infoBgSoft)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.Palette.infoMain.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        PascalCommentView(comment: "用恐惧当燃料，跑得确实快，但积碳也严重。这种搞法，等到 35 岁那天，你迎接的不是财务自由，而是肾上腺枯竭。咱们得换种活法，兄弟。")

        PascalCommentView(comment: "这几天我会强制降低你的任务难度。别想着破纪录了，这段时间先保证能睡个好觉。")
    }
    .padding()
    .background(Color.Palette.bgBase)
}
