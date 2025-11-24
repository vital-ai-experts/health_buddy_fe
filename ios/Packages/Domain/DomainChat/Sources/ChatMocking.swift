import Foundation

/// Mock 聊天相关的工具
public enum ChatMocking {
    /// 触发 mock 流程的前缀
    public static let prefix = "#mock#"

    /// 是否包含 mock 前缀（会先做首尾空白裁剪）
    public static func hasMockPrefix(in text: String) -> Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix(prefix)
    }

    /// 移除 mock 前缀后的纯文本（会移除首尾空白）
    public static func stripMockPrefix(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix(prefix) else { return trimmed }
        let dropped = trimmed.dropFirst(prefix.count)
        return dropped.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
