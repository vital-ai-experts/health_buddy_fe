import Foundation

/// 聊天输入框上方用于筛选的话题标签
public struct ChatTopic: Identifiable, Equatable, Hashable {
    public let id: String
    public let title: String

    public init(id: String, title: String) {
        self.id = id
        self.title = title
    }
}
