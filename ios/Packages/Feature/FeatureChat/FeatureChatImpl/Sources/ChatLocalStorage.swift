import Foundation
import SwiftData

// MARK: - SwiftData Models for Local Chat History

@Model
public final class LocalChatMessage {
    public var id: String
    public var content: String
    public var isFromUser: Bool
    public var createdAt: Date
    public var conversationId: String?

    public init(
        id: String,
        content: String,
        isFromUser: Bool,
        createdAt: Date,
        conversationId: String? = nil
    ) {
        self.id = id
        self.content = content
        self.isFromUser = isFromUser
        self.createdAt = createdAt
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
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// 基于游标的分页获取最近的消息（使用 createdAt 作为游标）
    /// - Parameters:
    ///   - limit: 每页消息数量
    ///   - beforeDate: 游标，获取此时间之前的消息。nil 表示获取最新的消息
    /// - Returns: 消息列表，按时间正序排列（旧的在前，新的在后）
    public func fetchRecentMessages(limit: Int, beforeDate: Date? = nil) throws -> [LocalChatMessage] {
        var descriptor: FetchDescriptor<LocalChatMessage>

        if let beforeDate = beforeDate {
            // 获取指定时间之前的消息，按时间倒序
            descriptor = FetchDescriptor<LocalChatMessage>(
                predicate: #Predicate { $0.createdAt < beforeDate },
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
        } else {
            // 获取最新的消息，按时间倒序
            descriptor = FetchDescriptor<LocalChatMessage>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
        }

        descriptor.fetchLimit = limit
        let messages = try modelContext.fetch(descriptor)

        // 反转成时间正序（旧的在前，新的在后）
        return messages.reversed()
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
