import SwiftUI
import ThemeKit

struct IntroSectionView: View {
    let onTypingCompleted: () -> Void

    @State private var currentTypingIndex = 0
    @State private var hasCompletedTyping = false

    private let lines: [String] = [
        "Hi！我是 Pascal，你的私人AI健康教练",
        "🙅提前说好，我不是那种只会喊加油的气氛组",
        "我是来帮你作弊的——帮你规划阻力最小的变好捷径，然后推你一把",
        "好了，你先告诉我，咱们的目标是什么 👀"
    ]

    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                TypingTextView(
                    text: line,
                    font: font(for: index),
                    color: textColor(for: index),
                    alignment: .leading,
                    start: index <= currentTypingIndex,
                    charactersPerSecond: typingSpeed(for: index),
                    initialDelay: 0.05
                ) {
                    handleLineCompleted(at: index)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .onAppear {
            restartTyping()
        }
    }

    private func handleLineCompleted(at index: Int) {
        guard index == currentTypingIndex else { return }
        let nextIndex = index + 1
        if nextIndex < lines.count {
            currentTypingIndex = nextIndex
        } else if !hasCompletedTyping {
            hasCompletedTyping = true
            onTypingCompleted()
        }
    }

    private func restartTyping() {
        currentTypingIndex = 0
        hasCompletedTyping = false
        if lines.isEmpty {
            hasCompletedTyping = true
            onTypingCompleted()
        }
    }

    private func font(for index: Int) -> Font {
//        index == 0 ? .title3.weight(.semibold) : .body
        .body
    }

    private func textColor(for index: Int) -> Color {
//        index == 0 ? .Palette.textPrimary : .Palette.textSecondary
        .Palette.textPrimary
    }

    private func typingSpeed(for index: Int) -> Double {
        // index == 0 ? 14 : 18
        14
    }
}
