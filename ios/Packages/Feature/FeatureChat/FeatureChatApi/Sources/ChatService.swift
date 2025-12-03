import Foundation

/// Chat service protocol
public protocol ChatService {
    func sendMessage(
        userInput: String?,
        conversationId: String?,
        eventHandler: @escaping (ConversationStreamEvent) -> Void
    ) async throws

    func resumeConversation(
        conversationId: String,
        lastDataId: String?,
        eventHandler: @escaping (ConversationStreamEvent) -> Void
    ) async throws

    func getConversations(limit: Int?, offset: Int?) async throws -> [Conversation]

    func getConversationHistory(id: String) async throws -> [Message]

    func deleteConversation(id: String) async throws
}
