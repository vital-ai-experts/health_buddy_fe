import Foundation

/// 聊天气泡上方用于筛选的标签
public struct ChatTag: Identifiable, Equatable, Hashable {
    public let id: String
    public let title: String

    public init(id: String, title: String) {
        self.id = id
        self.title = title
    }
}
