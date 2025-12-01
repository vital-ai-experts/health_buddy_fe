import SwiftUI

/// 顶部话题模型
struct Topic: Identifiable {
    let id = UUID()
    let emoji: String
    let backgroundColor: Color
    let isAddButton: Bool

    init(emoji: String, backgroundColor: Color, isAddButton: Bool = false) {
        self.emoji = emoji
        self.backgroundColor = backgroundColor
        self.isAddButton = isAddButton
    }
}

extension Topic {
    static let sampleTopics: [Topic] = [
        Topic(emoji: "😴", backgroundColor: Color.purple.opacity(0.2)),
        Topic(emoji: "💪", backgroundColor: Color.green.opacity(0.2)),
        Topic(emoji: "+", backgroundColor: Color.gray.opacity(0.2), isAddButton: true)
    ]
}
