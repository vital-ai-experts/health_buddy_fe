import SwiftUI
import ThemeKit

struct IntroSectionView: View {
    let line1Started: Bool
    let line2Started: Bool
    let line3Started: Bool
    let onLine1Completed: () -> Void
    let onLine2Completed: () -> Void
    let onTypingCompleted: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TypingTextView(
                text: "你的身体每时每刻都在产生数据，但你从未真正读懂它。",
                font: .title3.weight(.semibold),
                color: .white,
                start: line1Started,
                charactersPerSecond: 14,
                initialDelay: 0.05
            ) {
                onLine1Completed()
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            TypingTextView(
                text: "我们不提供通用的健康建议。",
                font: .body,
                color: Color.white.opacity(0.85),
                start: line2Started,
                charactersPerSecond: 18,
                initialDelay: 0.05
            ) {
                onLine2Completed()
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            TypingTextView(
                text: "我们读取你的生物数据，为你定制每天的行动战术。",
                font: .body,
                color: Color.white.opacity(0.85),
                start: line3Started,
                charactersPerSecond: 18,
                initialDelay: 0.05
            ) {
                onTypingCompleted()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, -160)
    }
}
