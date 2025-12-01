import SwiftUI
import ThemeKit

/// 顶部话题列表视图
struct TopicBarView: View {
    let topics: [AgendaTopic]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(topics) { topic in
                    TopicCircleView(topic: topic)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(Color.Palette.bgBase)
    }
}

/// 单个话题圆圈视图
private struct TopicCircleView: View {
    let topic: AgendaTopic

    var body: some View {
        Button(action: {
            // TODO: 处理话题点击
        }) {
            ZStack {
                Circle()
                    .fill(topic.backgroundColor)
                    .frame(width: 56, height: 56)

                Image(systemName: topic.icon)
                    .font(.system(size: topic.isAddButton ? 32 : 28))
                    .foregroundColor(topic.isAddButton ? Color.Palette.textSecondary : Color.Palette.textPrimary)
            }
        }
    }
}

#Preview {
    VStack {
        TopicBarView(topics: AgendaTopic.sampleTopics)
        Spacer()
    }
    .background(Color.Palette.bgBase)
}
