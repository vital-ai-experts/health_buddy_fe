import SwiftUI

/// 可折叠的科学依据标签视图
public struct ScienceNoteView: View {
    private let tagText: String
    private let content: String

    @State private var isExpanded: Bool

    public init(content: String, tagText: String = "💡 The Science >", isExpanded: Bool = false) {
        self.content = content.trimmingCharacters(in: .whitespacesAndNewlines)
        self.tagText = tagText
        _isExpanded = State(initialValue: isExpanded)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: toggle) {
                Text(tagText)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.Palette.infoMain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.Palette.infoBgSoft)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            if isExpanded {
                Text(content)
                    .font(.system(size: 14))
                    .foregroundColor(.Palette.textSecondary)
                    .lineSpacing(5)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.Palette.surfaceElevated)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.Palette.surfaceElevatedBorder, lineWidth: 1)
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func toggle() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isExpanded.toggle()
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 16) {
        ScienceNoteView(
            content: "“每天仅需 5 分钟的‘循环叹气’（Cyclic Sighing），在改善情绪和降低生理唤醒方面，效果优于正念冥想。” —— Cell Reports Medicine, 2023",
            isExpanded: true
        )

        ScienceNoteView(
            content: "“酒精会显著抑制快速眼动睡眠（REM）。当酒精代谢完毕，大脑会产生强烈的‘REM 反弹’效应。这种剧烈的脑活动不仅无法恢复精力，还会导致次日皮质醇水平升高和情绪调节能力下降。” —— Sleep Medicine Reviews"
        )
    }
    .padding()
    .background(Color.Palette.bgBase)
}
