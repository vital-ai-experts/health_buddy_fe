import SwiftUI
import ThemeKit

/// SwiftUI view for displaying topic separators between messages
public struct TopicSeparatorView: View {
    let separator: TopicSeparator

    public init(separator: TopicSeparator) {
        self.separator = separator
    }

    public var body: some View {
        HStack(spacing: 8) {
            // Left line
            Rectangle()
                .fill(Color.Palette.textSecondary.opacity(0.3))
                .frame(height: 1)

            // Label
            Text("副本：\(separator.topicTitle)")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color.Palette.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.Palette.bgMuted)
                )

            // Right line
            Rectangle()
                .fill(Color.Palette.textSecondary.opacity(0.3))
                .frame(height: 1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
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
