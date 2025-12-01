import SwiftUI

/// 顶部话题列表视图
struct TopicListView: View {
    let topics: [Topic]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(topics) { topic in
                    TopicCircle(topic: topic)
                }
            }
            .padding(.horizontal, 24)
        }
    }
}

/// 单个话题圆圈
private struct TopicCircle: View {
    let topic: Topic

    var body: some View {
        ZStack {
            Circle()
                .fill(topic.backgroundColor)
                .frame(width: 80, height: 80)

            Text(topic.emoji)
                .font(.system(size: topic.isAddButton ? 48 : 40))
                .fontWeight(topic.isAddButton ? .light : .regular)
        }
    }
}

#Preview {
    TopicListView(topics: Topic.sampleTopics)
        .background(Color(red: 0.96, green: 0.96, blue: 0.94))
}
