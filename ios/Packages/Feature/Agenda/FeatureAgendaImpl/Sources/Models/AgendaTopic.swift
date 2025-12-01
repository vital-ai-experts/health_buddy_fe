import SwiftUI
import ThemeKit

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
        AgendaTopic(icon: "moon.zzz.fill", backgroundColor: Color.Palette.infoBgSoft),
        AgendaTopic(icon: "figure.run", backgroundColor: Color.Palette.successBgSoft),
        AgendaTopic(icon: "plus", backgroundColor: Color.Palette.bgMuted, isAddButton: true)
    ]
}
