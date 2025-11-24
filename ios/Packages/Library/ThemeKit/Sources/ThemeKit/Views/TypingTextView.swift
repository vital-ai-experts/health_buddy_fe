import SwiftUI

public struct TypingTextView: View {
    private let text: String
    private let font: Font
    private let color: Color
    private let start: Bool
    private let typingInterval: TimeInterval
    private let cursorBlinkInterval: TimeInterval
    private let initialDelay: TimeInterval
    private let showCursorWhenFinished: Bool
    private let cursorSymbol: String
    private let onFinish: (() -> Void)?

    @State private var visibleCount: Int = 0
    @State private var isCursorVisible: Bool = true
    @State private var typingTask: Task<Void, Never>?
    @State private var cursorTask: Task<Void, Never>?
    @State private var hasStarted: Bool = false

    private var characters: [Character] {
        Array(text)
    }

    private var hasFinishedTyping: Bool {
        visibleCount >= characters.count
    }

    private var displayText: String {
        guard hasStarted else { return "" }
        let visible = String(characters.prefix(visibleCount))
        let shouldShowCursor = isCursorVisible && (showCursorWhenFinished || !hasFinishedTyping)
        return shouldShowCursor ? visible + cursorSymbol : visible
    }

    public init(
        text: String,
        font: Font = .body,
        color: Color = .white,
        start: Bool = true,
        charactersPerSecond: Double = 18,
        initialDelay: TimeInterval = 0,
        cursorBlinkInterval: TimeInterval = 0.55,
        showCursorWhenFinished: Bool = false,
        cursorSymbol: String = "_",
        onFinish: (() -> Void)? = nil
    ) {
        self.text = text
        self.font = font
        self.color = color
        self.start = start
        self.typingInterval = 1.0 / max(charactersPerSecond, 1)
        self.cursorBlinkInterval = cursorBlinkInterval
        self.initialDelay = max(0, initialDelay)
        self.showCursorWhenFinished = showCursorWhenFinished
        self.cursorSymbol = cursorSymbol
        self.onFinish = onFinish
    }

    public var body: some View {
        Text(displayText)
            .font(font)
            .foregroundColor(color)
            .multilineTextAlignment(.leading)
            .onAppear(perform: tryStart)
            .onDisappear(perform: stopAnimations)
            .onChange(of: text) { _, _ in restartIfNeeded() }
            .onChange(of: start) { _, _ in handleStartChange() }
    }

    private func handleStartChange() {
        if start {
            restart()
        } else {
            stopAnimations()
            visibleCount = 0
            hasStarted = false
            isCursorVisible = false
        }
    }

    private func restartIfNeeded() {
        stopAnimations()
        visibleCount = 0
        hasStarted = false
        isCursorVisible = true
        tryStart()
    }

    private func restart() {
        stopAnimations()
        visibleCount = 0
        hasStarted = false
        isCursorVisible = true
        tryStart()
    }

    private func tryStart() {
        guard start, !hasStarted else { return }
        hasStarted = true
        startCursorBlink()

        typingTask = Task {
            if initialDelay > 0 {
                try? await Task.sleep(nanoseconds: UInt64(initialDelay * 1_000_000_000))
            }

            for idx in characters.indices {
                try? await Task.sleep(nanoseconds: UInt64(typingInterval * 1_000_000_000))

                await MainActor.run {
                    visibleCount = idx + 1
                }
            }

            if let onFinish {
                await MainActor.run {
                    onFinish()
                }
            }
        }
    }

    private func startCursorBlink() {
        cursorTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(cursorBlinkInterval * 1_000_000_000))

                await MainActor.run {
                    isCursorVisible.toggle()
                }
            }
        }
    }

    private func stopAnimations() {
        typingTask?.cancel()
        cursorTask?.cancel()
        typingTask = nil
        cursorTask = nil
    }
}
