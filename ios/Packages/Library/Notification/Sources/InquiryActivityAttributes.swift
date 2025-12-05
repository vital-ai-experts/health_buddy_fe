import ActivityKit
import Foundation

/// Activity Attributes for Inquiry Live Activity (主动问询卡片)
@available(iOS 16.1, *)
public struct InquiryActivityAttributes: ActivityAttributes {
    /// Content State for Inquiry Live Activity
    public struct ContentState: Codable, Hashable {
        /// 问询选项
        public struct InquiryOption: Codable, Hashable {
            /// 选项的 emoji 图标
            public var emoji: String
            /// 选项的文本
            public var text: String
            /// 选项的标识符（用于回传）
            public var id: String

            public init(emoji: String, text: String, id: String) {
                self.emoji = emoji
                self.text = text
                self.id = id
            }
        }

        /// 问题文本（👀 开头）
        public var question: String
        /// 选项列表
        public var options: [InquiryOption]
        /// 卡片创建时间
        public var createdAt: Date

        public init(question: String, options: [InquiryOption], createdAt: Date = Date()) {
            self.question = question
            self.options = options
            self.createdAt = createdAt
        }
    }

    /// User identifier (static during activity lifetime)
    public var userId: String

    public init(userId: String) {
        self.userId = userId
    }
}
