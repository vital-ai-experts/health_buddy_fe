import SwiftUI

/// 话题模型
struct AgendaTopic: Identifiable {
    let id = UUID()
    let icon: String // SF Symbol name
    let backgroundColor: Color
    let isAddButton: Bool

    init(icon: String, backgroundColor: Color, isAddButton: Bool = false) {
        self.icon = icon
        self.backgroundColor = backgroundColor
        self.isAddButton = isAddButton
    }
}

extension AgendaTopic {
    static let sampleTopics: [AgendaTopic] = [
        AgendaTopic(icon: "moon.zzz.fill", backgroundColor: Color(red: 0.8, green: 0.8, blue: 1.0)),
        AgendaTopic(icon: "figure.run", backgroundColor: Color(red: 0.8, green: 1.0, blue: 0.9)),
        AgendaTopic(icon: "plus", backgroundColor: Color(red: 0.85, green: 0.85, blue: 0.85), isAddButton: true)
    ]
}
