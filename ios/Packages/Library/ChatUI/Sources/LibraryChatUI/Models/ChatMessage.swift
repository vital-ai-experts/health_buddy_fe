import Foundation
import SwiftUI

/// 聊天消息协议
public protocol ChatMessageProtocol: Identifiable {
    var id: String { get }
    var text: String { get }
    var isFromUser: Bool { get }
    var timestamp: Date { get }
    var isStreaming: Bool { get }
}

/// 聊天消息实现
public struct ChatMessage: ChatMessageProtocol, Equatable {
    public let id: String
    public let text: String
    public let isFromUser: Bool
    public let timestamp: Date
    public let isStreaming: Bool

    public init(
        id: String = UUID().uuidString,
        text: String,
        isFromUser: Bool,
        timestamp: Date = Date(),
        isStreaming: Bool = false
    ) {
        self.id = id
        self.text = text
        self.isFromUser = isFromUser
        self.timestamp = timestamp
        self.isStreaming = isStreaming
    }
}

/// 聊天配置
public struct ChatConfiguration {
    public var showAvatar: Bool
    public var showTimestamp: Bool
    public var userAvatarURL: URL?
    public var botAvatarURL: URL?
    public var messageFont: Font
    public var userMessageColor: Color
    public var botMessageColor: Color
    public var userTextColor: Color
    public var botTextColor: Color
    public var cornerRadius: CGFloat
    public var messagePadding: CGFloat
    /// 是否在 Bot 回复完成后自动聚焦输入框（弹起键盘）
    public var autoFocusAfterBotMessage: Bool

    public init(
        showAvatar: Bool = true,
        showTimestamp: Bool = true,
        userAvatarURL: URL? = nil,
        botAvatarURL: URL? = nil,
        messageFont: Font = .body,
        userMessageColor: Color = .blue,
        botMessageColor: Color = Color(.systemGray5),
        userTextColor: Color = .white,
        botTextColor: Color = .primary,
        cornerRadius: CGFloat = 16,
        messagePadding: CGFloat = 12,
        autoFocusAfterBotMessage: Bool = false
    ) {
        self.showAvatar = showAvatar
        self.showTimestamp = showTimestamp
        self.userAvatarURL = userAvatarURL
        self.botAvatarURL = botAvatarURL
        self.messageFont = messageFont
        self.userMessageColor = userMessageColor
        self.botMessageColor = botMessageColor
        self.userTextColor = userTextColor
        self.botTextColor = botTextColor
        self.cornerRadius = cornerRadius
        self.messagePadding = messagePadding
        self.autoFocusAfterBotMessage = autoFocusAfterBotMessage
    }

    public static let `default` = ChatConfiguration()
}
