import SwiftUI

/// 简单的 Markdown 文本渲染器
struct MarkdownText: View {
    let text: String
    let font: Font
    let textColor: Color

    var body: some View {
        Text(parseMarkdown(text))
            .font(font)
            .foregroundColor(textColor)
    }

    private func parseMarkdown(_ text: String) -> AttributedString {
        var attributedString = AttributedString(text)

        // 1. 处理 **粗体**
        if let boldRegex = try? NSRegularExpression(pattern: #"\*\*(.+?)\*\*"#, options: []) {
            let nsString = text as NSString
            let matches = boldRegex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))

            for match in matches.reversed() {
                if let range = Range(match.range, in: text) {
                    let content = String(text[range]).replacingOccurrences(of: "**", with: "")
                    if let attrRange = Range(match.range, in: attributedString) {
                        attributedString.replaceSubrange(attrRange, with: AttributedString(content))
                        if let contentRange = attributedString.range(of: content) {
                            attributedString[contentRange].font = font.bold()
                        }
                    }
                }
            }
        }

        // 2. 处理 *斜体*
        if let italicRegex = try? NSRegularExpression(pattern: #"(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)"#, options: []) {
            let nsString = attributedString.description as NSString
            let matches = italicRegex.matches(in: attributedString.description, options: [], range: NSRange(location: 0, length: nsString.length))

            for match in matches.reversed() {
                if let range = Range(match.range, in: attributedString.description),
                   let attrRange = attributedString.range(of: String(attributedString.description[range])) {
                    let content = String(attributedString.description[range]).replacingOccurrences(of: "*", with: "")
                    attributedString.replaceSubrange(attrRange, with: AttributedString(content))
                    if let contentRange = attributedString.range(of: content) {
                        attributedString[contentRange].font = font.italic()
                    }
                }
            }
        }

        // 3. 处理 `代码`
        if let codeRegex = try? NSRegularExpression(pattern: #"`(.+?)`"#, options: []) {
            let nsString = attributedString.description as NSString
            let matches = codeRegex.matches(in: attributedString.description, options: [], range: NSRange(location: 0, length: nsString.length))

            for match in matches.reversed() {
                if let range = Range(match.range, in: attributedString.description),
                   let attrRange = attributedString.range(of: String(attributedString.description[range])) {
                    let content = String(attributedString.description[range]).replacingOccurrences(of: "`", with: "")
                    attributedString.replaceSubrange(attrRange, with: AttributedString(content))
                    if let contentRange = attributedString.range(of: content) {
                        attributedString[contentRange].font = .system(.body, design: .monospaced)
                        attributedString[contentRange].backgroundColor = .gray.opacity(0.2)
                    }
                }
            }
        }

        return attributedString
    }
}

/// 带有内联光标的流式文本视图（纯文本）
struct StreamingTextWithCursor: View {
    let text: String
    let font: Font
    let textColor: Color

    var body: some View {
        // 光标使用实心圆点，保持固定颜色，不闪烁
        (Text(text) + Text(" ●"))
            .font(font)
            .foregroundColor(textColor)
    }
}

/// 带有内联光标的 Markdown 文本视图
struct MarkdownTextWithCursor: View {
    let text: String
    let font: Font
    let textColor: Color

    var body: some View {
        // 解析 Markdown 并添加光标
        Text(parseMarkdown(text)) + Text(" ●")
            .foregroundColor(textColor)
    }

    private func parseMarkdown(_ text: String) -> AttributedString {
        var attributedString = AttributedString(text)

        // 1. 处理 **粗体**
        if let boldRegex = try? NSRegularExpression(pattern: #"\*\*(.+?)\*\*"#, options: []) {
            let nsString = text as NSString
            let matches = boldRegex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))

            for match in matches.reversed() {
                if let range = Range(match.range, in: text) {
                    let content = String(text[range]).replacingOccurrences(of: "**", with: "")
                    if let attrRange = Range(match.range, in: attributedString) {
                        attributedString.replaceSubrange(attrRange, with: AttributedString(content))
                        if let contentRange = attributedString.range(of: content) {
                            attributedString[contentRange].font = font.bold()
                        }
                    }
                }
            }
        }

        // 2. 处理 *斜体*
        if let italicRegex = try? NSRegularExpression(pattern: #"(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)"#, options: []) {
            let nsString = attributedString.description as NSString
            let matches = italicRegex.matches(in: attributedString.description, options: [], range: NSRange(location: 0, length: nsString.length))

            for match in matches.reversed() {
                if let range = Range(match.range, in: attributedString.description),
                   let attrRange = attributedString.range(of: String(attributedString.description[range])) {
                    let content = String(attributedString.description[range]).replacingOccurrences(of: "*", with: "")
                    attributedString.replaceSubrange(attrRange, with: AttributedString(content))
                    if let contentRange = attributedString.range(of: content) {
                        attributedString[contentRange].font = font.italic()
                    }
                }
            }
        }

        // 3. 处理 `代码`
        if let codeRegex = try? NSRegularExpression(pattern: #"`(.+?)`"#, options: []) {
            let nsString = attributedString.description as NSString
            let matches = codeRegex.matches(in: attributedString.description, options: [], range: NSRange(location: 0, length: nsString.length))

            for match in matches.reversed() {
                if let range = Range(match.range, in: attributedString.description),
                   let attrRange = attributedString.range(of: String(attributedString.description[range])) {
                    let content = String(attributedString.description[range]).replacingOccurrences(of: "`", with: "")
                    attributedString.replaceSubrange(attrRange, with: AttributedString(content))
                    if let contentRange = attributedString.range(of: content) {
                        attributedString[contentRange].font = .system(.body, design: .monospaced)
                        attributedString[contentRange].backgroundColor = .gray.opacity(0.2)
                    }
                }
            }
        }

        return attributedString
    }
}
