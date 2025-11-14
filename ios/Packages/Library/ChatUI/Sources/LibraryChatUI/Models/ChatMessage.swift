import Foundation
import SwiftUI

/// 特殊消息类型
public enum SpecialMessageType: String, Codable, Equatable, Hashable {
    case userHealthProfile = "user_health_profile"  // 用户健康档案确认
}

/// 聊天消息协议
public protocol ChatMessageProtocol: Identifiable {
    var id: String { get }
    var text: String { get }
    var isFromUser: Bool { get }
    var timestamp: Date { get }
    var isStreaming: Bool { get }
}

/// 工具调用信息（用于显示AI执行的操作）
public struct ToolCallInfo: Equatable, Codable, Hashable, Identifiable {
    public let id: String
    public let name: String
    public let args: String?
    public let status: String?
    public let result: String?

    public init(id: String = UUID().uuidString, name: String, args: String? = nil, status: String? = nil, result: String? = nil) {
        self.id = id
        self.name = name
        self.args = args
        self.status = status
        self.result = result
    }
}

/// 聊天消息实现
public struct ChatMessage: ChatMessageProtocol, Equatable {
    public let id: String
    public let text: String
    public let isFromUser: Bool
    public let timestamp: Date
    public let isStreaming: Bool

    // AI相关的额外信息
    public let thinkingContent: String?  // AI的思考过程
    public let toolCalls: [ToolCallInfo]? // AI执行的工具调用
    public let specialMessageType: SpecialMessageType?  // 特殊消息类型
    public let specialMessageData: String?  // 特殊消息的数据（例如：健康档案的JSON）

    // 错误相关
    public let hasError: Bool  // 消息是否有错误
    public let errorMessage: String?  // 错误信息

    public init(
        id: String = UUID().uuidString,
        text: String,
        isFromUser: Bool,
        timestamp: Date = Date(),
        isStreaming: Bool = false,
        thinkingContent: String? = nil,
        toolCalls: [ToolCallInfo]? = nil,
        specialMessageType: SpecialMessageType? = nil,
        specialMessageData: String? = nil,
        hasError: Bool = false,
        errorMessage: String? = nil
    ) {
        self.id = id
        self.text = text
        self.isFromUser = isFromUser
        self.timestamp = timestamp
        self.isStreaming = isStreaming
        self.thinkingContent = thinkingContent
        self.toolCalls = toolCalls
        self.specialMessageType = specialMessageType
        self.specialMessageData = specialMessageData
        self.hasError = hasError
        self.errorMessage = errorMessage
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
    /// 是否在用户发送消息后主动收起键盘
    public var dismissKeyboardAfterSend: Bool

    // Aliases for new view components
    public var userMessageBackgroundColor: Color { userMessageColor }
    public var botMessageBackgroundColor: Color { botMessageColor }
    public var userMessageTextColor: Color { userTextColor }
    public var botMessageTextColor: Color { botTextColor }

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
        autoFocusAfterBotMessage: Bool = false,
        dismissKeyboardAfterSend: Bool = true
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
        self.dismissKeyboardAfterSend = dismissKeyboardAfterSend
    }

    public static let `default` = ChatConfiguration()
}
