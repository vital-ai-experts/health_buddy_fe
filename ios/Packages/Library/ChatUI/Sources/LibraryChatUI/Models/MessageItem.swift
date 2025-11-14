import Foundation

// MARK: - MessageItem Enum

/// Represents different types of messages in the chat
public enum MessageItem: Hashable, Identifiable {
    case user(UserMessage)
    case system(SystemMessage)
    case loading(SystemLoading)

    public var id: String {
        switch self {
        case .user(let message):
            return "user_\(message.id)"
        case .system(let message):
            return "system_\(message.id)"
        case .loading(let loading):
            return "loading_\(loading.id)"
        }
    }
}

// MARK: - UserMessage

/// Represents a message from the user
public struct UserMessage: Hashable, Identifiable {
    public let id: String
    public let text: String
    public let timestamp: Date

    public init(id: String = UUID().uuidString, text: String, timestamp: Date = Date()) {
        self.id = id
        self.text = text
        self.timestamp = timestamp
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

    public init(
        id: String = UUID().uuidString,
        text: String,
        timestamp: Date = Date(),
        isStreaming: Bool = false,
        thinkingContent: String? = nil,
        toolCalls: [ToolCallInfo] = [],
        specialMessageType: SpecialMessageType? = nil,
        specialMessageData: String? = nil
    ) {
        self.id = id
        self.text = text
        self.timestamp = timestamp
        self.isStreaming = isStreaming
        self.thinkingContent = thinkingContent
        self.toolCalls = toolCalls
        self.specialMessageType = specialMessageType
        self.specialMessageData = specialMessageData
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

// MARK: - Supporting Types

// Note: ToolCallInfo and SpecialMessageType are defined in ChatMessage.swift

// MARK: - Conversion from ChatMessage

extension MessageItem {
    /// Converts a ChatMessage to a MessageItem
    public static func from(chatMessage: ChatMessage) -> MessageItem {
        if chatMessage.isFromUser {
            return .user(UserMessage(
                id: chatMessage.id,
                text: chatMessage.text,
                timestamp: chatMessage.timestamp
            ))
        } else {
            return .system(SystemMessage(
                id: chatMessage.id,
                text: chatMessage.text,
                timestamp: chatMessage.timestamp,
                isStreaming: chatMessage.isStreaming,
                thinkingContent: chatMessage.thinkingContent,
                toolCalls: chatMessage.toolCalls ?? [],
                specialMessageType: chatMessage.specialMessageType,
                specialMessageData: chatMessage.specialMessageData
            ))
        }
    }
}
