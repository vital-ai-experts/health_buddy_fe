import Foundation

/// 在正式 ChatService 外包一层，用于处理 mock 消息
public final class ChatServiceWithMock: ChatService {
    private let realService: ChatService
    private let mockService: ChatService

    public init(
        realService: ChatService = ChatServiceImpl(),
        mockService: ChatService = MockChatService()
    ) {
        self.realService = realService
        self.mockService = mockService
    }

    public func sendMessage(
        userInput: String?,
        conversationId: String?,
        eventHandler: @escaping (ConversationStreamEvent) -> Void
    ) async throws {
        if let userInput, ChatMocking.hasMockPrefix(in: userInput) {
            try await mockService.sendMessage(
                userInput: userInput,
                conversationId: conversationId,
                eventHandler: eventHandler
            )
            return
        }

        try await realService.sendMessage(
            userInput: userInput,
            conversationId: conversationId,
            eventHandler: eventHandler
        )
    }

    public func resumeConversation(
        conversationId: String,
        lastDataId: String?,
        eventHandler: @escaping (ConversationStreamEvent) -> Void
    ) async throws {
        try await realService.resumeConversation(
            conversationId: conversationId,
            lastDataId: lastDataId,
            eventHandler: eventHandler
        )
    }

    public func getConversations(limit: Int?, offset: Int?) async throws -> [Conversation] {
        try await realService.getConversations(limit: limit, offset: offset)
    }

    public func getConversationHistory(id: String) async throws -> [Message] {
        try await realService.getConversationHistory(id: id)
    }

    public func deleteConversation(id: String) async throws {
        try await realService.deleteConversation(id: id)
    }
}

/// 处理 mock 消息的简单实现
public final class MockChatService: ChatService {
    public init() {}

    public func sendMessage(
        userInput: String?,
        conversationId: String?,
        eventHandler: @escaping (ConversationStreamEvent) -> Void
    ) async throws {
        let rawText = userInput ?? ""
        let cleanText = ChatMocking.stripMockPrefix(from: rawText)
        let cid = conversationId ?? UUID().uuidString
        let msgId = UUID().uuidString

        // 开始生成
        eventHandler(.streamMessage(StreamMessage(
            id: UUID().uuidString,
            data: StreamMessageData(
                conversationId: cid,
                msgId: msgId,
                dataType: .agentStatus,
                agentStatus: .generating
            )
        )))

        // 返回 mock 内容：原文 + “收到”
        let content = cleanText.isEmpty ? "收到" : "\(cleanText)收到"
        eventHandler(.streamMessage(StreamMessage(
            id: UUID().uuidString,
            data: StreamMessageData(
                conversationId: cid,
                msgId: msgId,
                dataType: .agentMessage,
                messageType: .whole,
                content: content
            )
        )))

        // 结束
        eventHandler(.streamMessage(StreamMessage(
            id: UUID().uuidString,
            data: StreamMessageData(
                conversationId: cid,
                msgId: msgId,
                dataType: .agentStatus,
                agentStatus: .finished
            )
        )))
    }

    public func resumeConversation(
        conversationId: String,
        lastDataId: String?,
        eventHandler: @escaping (ConversationStreamEvent) -> Void
    ) async throws {
        // demo mock 不支持恢复，直接返回完成状态
        eventHandler(.streamMessage(StreamMessage(
            id: UUID().uuidString,
            data: StreamMessageData(
                conversationId: conversationId,
                msgId: UUID().uuidString,
                dataType: .agentStatus,
                agentStatus: .finished
            )
        )))
    }

    public func getConversations(limit: Int?, offset: Int?) async throws -> [Conversation] {
        []
    }

    public func getConversationHistory(id: String) async throws -> [Message] {
        []
    }

    public func deleteConversation(id: String) async throws {}
}
