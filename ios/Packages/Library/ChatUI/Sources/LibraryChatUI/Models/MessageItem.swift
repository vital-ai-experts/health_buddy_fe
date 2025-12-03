import Foundation

// MARK: - MessageItem Enum

/// Represents different types of messages in the chat
public enum MessageItem: Hashable, Identifiable {
    case user(UserMessage)
    case system(SystemMessage)
    case custom(CustomRenderedMessage)
    case loading(SystemLoading)
    case error(SystemError)
    case topicSeparator(TopicSeparator)

    public var id: String {
        switch self {
        case .user(let message):
            return "user_\(message.id)"
        case .system(let message):
            return "system_\(message.id)"
        case .custom(let message):
            return "custom_\(message.id)"
        case .loading(let loading):
            return "loading_\(loading.id)"
        case .error(let error):
            return "error_\(error.id)"
        case .topicSeparator(let separator):
            return "separator_\(separator.id)"
        }
    }
}

// MARK: - UserMessage

/// Represents a message from the user
public struct UserMessage: Hashable, Identifiable {
    public let id: String
    public let text: String
    public let timestamp: Date
    public let images: [MessageImage]?  // 图片附件
    public let goalTitle: String?

    public init(
        id: String = UUID().uuidString,
        text: String,
        timestamp: Date = Date(),
        images: [MessageImage]? = nil,
        goalTitle: String? = nil
    ) {
        self.id = id
        self.text = text
        self.timestamp = timestamp
        self.images = images
        self.goalTitle = goalTitle
    }
}

// MARK: - SystemMessage

/// Represents a message from the system/AI (both streaming and completed)
public struct SystemMessage: Hashable, Identifiable {
    public let id: String
    public let text: String
    public let timestamp: Date
    public let isStreaming: Bool
    public let thinkingContent: String?
    public let toolCalls: [ToolCallInfo]
    public let specialMessageType: SpecialMessageType?
    public let specialMessageData: String?
    public let goalTitle: String?

    public init(
        id: String = UUID().uuidString,
        text: String,
        timestamp: Date = Date(),
        isStreaming: Bool = false,
        thinkingContent: String? = nil,
        toolCalls: [ToolCallInfo] = [],
        specialMessageType: SpecialMessageType? = nil,
        specialMessageData: String? = nil,
        goalTitle: String? = nil
    ) {
        self.id = id
        self.text = text
        self.timestamp = timestamp
        self.isStreaming = isStreaming
        self.thinkingContent = thinkingContent
        self.toolCalls = toolCalls
        self.specialMessageType = specialMessageType
        self.specialMessageData = specialMessageData
        self.goalTitle = goalTitle
    }
}

// MARK: - SystemLoading

/// Represents a loading indicator when AI is thinking (before any content)
public struct SystemLoading: Hashable, Identifiable {
    public let id: String

    public init(id: String = UUID().uuidString) {
        self.id = id
    }
}

// MARK: - SystemError

/// Represents an error message with retry capability
public struct SystemError: Hashable, Identifiable {
    public let id: String
    public let errorMessage: String
    public let timestamp: Date
    public let failedMessageId: String?  // ID of the message that failed

    public init(
        id: String = UUID().uuidString,
        errorMessage: String,
        timestamp: Date = Date(),
        failedMessageId: String? = nil
    ) {
        self.id = id
        self.errorMessage = errorMessage
        self.timestamp = timestamp
        self.failedMessageId = failedMessageId
    }
}

// MARK: - TopicSeparator

/// Represents a topic/goal separator displayed between messages
public struct TopicSeparator: Hashable, Identifiable {
    public let id: String
    public let goalTitle: String

    public init(
        id: String = UUID().uuidString,
        goalTitle: String
    ) {
        self.id = id
        self.goalTitle = goalTitle
    }
}

// MARK: - Supporting Types

// Note: ToolCallInfo and SpecialMessageType are defined in ChatMessage.swift

// MARK: - Conversion from ChatMessage

extension MessageItem {
    /// Converts a ChatMessage to a MessageItem
    public static func from(chatMessage: ChatMessage) -> MessageItem {
        // 如果消息有错误，返回错误类型
        if chatMessage.hasError {
            return .error(SystemError(
                id: chatMessage.id,
                errorMessage: chatMessage.errorMessage ?? "Unknown error",
                timestamp: chatMessage.timestamp,
                failedMessageId: chatMessage.id
            ))
        }

        if chatMessage.isFromUser {
            return .user(UserMessage(
                id: chatMessage.id,
                text: chatMessage.text,
                timestamp: chatMessage.timestamp,
                images: chatMessage.images,
                goalTitle: chatMessage.goalTitle
            ))
        } else {
            // 自定义特殊消息，交给外部注册的渲染器
            if let rawType = chatMessage.specialMessageTypeRaw,
               ChatMessageRendererRegistry.shared.hasRenderer(for: rawType) {
                let customMessage = CustomRenderedMessage(
                    id: chatMessage.id,
                    type: rawType,
                    text: chatMessage.text,
                    timestamp: chatMessage.timestamp,
                    data: chatMessage.specialMessageData
                )
                return .custom(customMessage)
            }
            
            // Regular system message
            return .system(SystemMessage(
                id: chatMessage.id,
                text: chatMessage.text,
                timestamp: chatMessage.timestamp,
                isStreaming: chatMessage.isStreaming,
                thinkingContent: chatMessage.thinkingContent,
                toolCalls: chatMessage.toolCalls ?? [],
                specialMessageType: chatMessage.specialMessageType,
                specialMessageData: chatMessage.specialMessageData,
                goalTitle: chatMessage.goalTitle
            ))
        }
    }
}

// MARK: - Message Processing

extension MessageItem {
    /// Inserts topic separators into a message list based on goalTitle changes
    public static func withTopicSeparators(_ messages: [MessageItem]) -> [MessageItem] {
        var result: [MessageItem] = []
        var currentGoalTitle: String?

        for message in messages {
            // Extract goal title from current message
            let messageGoalTitle: String? = {
                switch message {
                case .user(let userMsg):
                    return userMsg.goalTitle
                case .system(let systemMsg):
                    return systemMsg.goalTitle
                default:
                    return nil
                }
            }()

            // Determine the effective goal title (inherit from previous if not specified)
            let effectiveGoalTitle = messageGoalTitle ?? currentGoalTitle

            // If goal title changed and is not nil, insert a separator
            if let goalTitle = effectiveGoalTitle,
               goalTitle != currentGoalTitle {
                let separator = TopicSeparator(
                    id: "separator_\(goalTitle)_\(result.count)",
                    goalTitle: goalTitle
                )
                result.append(.topicSeparator(separator))
                currentGoalTitle = goalTitle
            }

            result.append(message)
        }

        return result
    }
}
