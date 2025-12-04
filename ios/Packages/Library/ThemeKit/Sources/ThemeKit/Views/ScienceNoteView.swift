import SwiftUI

/// 可折叠的科学依据标签视图
public struct ScienceNoteView: View {
    private let tagText: String
    private let content: String

    @State private var isExpanded: Bool

    public init(content: String, tagText: String = "💡 The Science", isExpanded: Bool = false) {
        self.content = content.trimmingCharacters(in: .whitespacesAndNewlines)
        self.tagText = tagText
        _isExpanded = State(initialValue: isExpanded)
    }

    public var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            Text(content)
                .font(.system(size: 14, weight: .medium, design: .serif))
                .foregroundColor(.Palette.textSecondary)
                .lineSpacing(5)
                .italic()
        } label: {
            Text(tagText.trimmingCharacters(in: .whitespacesAndNewlines))
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.Palette.infoMain)
        }
        .disclosureGroupStyle(TrailingChevronDisclosureGroupStyle())
    }
}

// 自定义 DisclosureGroup 样式：保留原先的布局、配色，并让箭头在右侧旋转
private struct TrailingChevronDisclosureGroupStyle: DisclosureGroupStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    configuration.isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    configuration.label

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.Palette.infoMain)
                        .rotationEffect(.degrees(configuration.isExpanded ? 90 : 0))
                        .animation(.easeInOut(duration: 0.2), value: configuration.isExpanded)
                }
                .padding(.vertical, 6)
            }
            .buttonStyle(.plain)

            if configuration.isExpanded {
                configuration.content
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
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
