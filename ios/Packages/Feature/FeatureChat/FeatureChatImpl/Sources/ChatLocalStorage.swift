import Foundation
import SwiftData

// MARK: - SwiftData Models for Local Chat History

@Model
public final class LocalChatMessage {
    public var id: String
    public var content: String
    public var isFromUser: Bool
    public var timestamp: Date
    public var conversationId: String?

    public init(
        id: String,
        content: String,
        isFromUser: Bool,
        timestamp: Date,
        conversationId: String? = nil
    ) {
        self.id = id
        self.content = content
        self.isFromUser = isFromUser
        self.timestamp = timestamp
        self.conversationId = conversationId
    }
}

// MARK: - Chat Storage Service

@MainActor
public final class ChatStorageService {
    private let modelContext: ModelContext

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// 保存消息到本地
    public func saveMessage(_ message: LocalChatMessage) throws {
        modelContext.insert(message)
        try modelContext.save()
    }

    /// 批量保存消息
    public func saveMessages(_ messages: [LocalChatMessage]) throws {
        for message in messages {
            modelContext.insert(message)
        }
        try modelContext.save()
    }

    /// 获取所有本地消息（按时间排序）
    public func fetchAllMessages() throws -> [LocalChatMessage] {
        let descriptor = FetchDescriptor<LocalChatMessage>(
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// 删除所有本地消息
    public func deleteAllMessages() throws {
        let messages = try fetchAllMessages()
        for message in messages {
            modelContext.delete(message)
        }
        try modelContext.save()
    }

    /// 删除指定ID的消息
    public func deleteMessage(id: String) throws {
        let descriptor = FetchDescriptor<LocalChatMessage>(
            predicate: #Predicate { $0.id == id }
        )
        let messages = try modelContext.fetch(descriptor)
        for message in messages {
            modelContext.delete(message)
        }
        try modelContext.save()
    }

    /// 获取消息数量
    public func getMessageCount() throws -> Int {
        let descriptor = FetchDescriptor<LocalChatMessage>()
        return try modelContext.fetchCount(descriptor)
    }
}
