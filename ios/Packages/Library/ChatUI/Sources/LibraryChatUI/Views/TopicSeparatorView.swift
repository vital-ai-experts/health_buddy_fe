import SwiftUI
import ThemeKit

/// SwiftUI view for displaying topic separators between messages
public struct TopicSeparatorView: View {
    let separator: TopicSeparator

    public init(separator: TopicSeparator) {
        self.separator = separator
    }

    public var body: some View {
        Text(separator.topicTitle)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(Color.Palette.textDisabled)
            .padding(.top, 32)
            .padding(.bottom, 16)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        TopicSeparatorView(separator: TopicSeparator(topicTitle: "睡眠大师"))
        TopicSeparatorView(separator: TopicSeparator(topicTitle: "健康饮食"))
        TopicSeparatorView(separator: TopicSeparator(topicTitle: "运动计划"))
    }
    .padding()
}
