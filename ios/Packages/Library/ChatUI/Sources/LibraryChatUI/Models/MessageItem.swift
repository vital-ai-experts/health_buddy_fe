import Foundation

// MARK: - MessageItem Enum

/// Represents different types of messages in the chat
public enum MessageItem: Hashable, Identifiable {
    case user(UserMessage)
    case system(SystemMessage)
    case digestReport(DigestReportMessage)
    case loading(SystemLoading)
    case error(SystemError)

    public var id: String {
        switch self {
        case .user(let message):
            return "user_\(message.id)"
        case .system(let message):
            return "system_\(message.id)"
        case .digestReport(let message):
            return "digestReport_\(message.id)"
        case .loading(let loading):
            return "loading_\(loading.id)"
        case .error(let error):
            return "error_\(error.id)"
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

    public init(id: String = UUID().uuidString, text: String, timestamp: Date = Date(), images: [MessageImage]? = nil) {
        self.id = id
        self.text = text
        self.timestamp = timestamp
        self.images = images
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

// MARK: - DigestReportMessage

/// Represents a digest report card message
public struct DigestReportMessage: Hashable, Identifiable {
    public let id: String
    public let timestamp: Date
    public let reportData: DigestReportData?

    public init(
        id: String = UUID().uuidString,
        timestamp: Date = Date(),
        reportData: DigestReportData? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.reportData = reportData
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
                images: chatMessage.images
            ))
        } else {
            // Check if this is a digest report message
            if let specialType = chatMessage.specialMessageType,
               specialType == .digestReport {
                let reportData = chatMessage.specialMessageData.flatMap { 
                    DigestReportData.from(jsonString: $0) 
                }
                return .digestReport(DigestReportMessage(
                    id: chatMessage.id,
                    timestamp: chatMessage.timestamp,
                    reportData: reportData
                ))
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
                specialMessageData: chatMessage.specialMessageData
            ))
        }
    }
}
