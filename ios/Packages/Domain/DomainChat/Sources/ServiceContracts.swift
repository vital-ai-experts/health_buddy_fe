import Foundation

/// Chat service protocol
public protocol ChatService {
    /// Send a conversation message and receive streaming response (IDL: SendConversationMessage)
    func sendMessage(
        userInput: String?,
        conversationId: String?,
        eventHandler: @escaping (ConversationStreamEvent) -> Void
    ) async throws

    /// Resume a conversation after disconnection (IDL: ResumeConversationMessage)
    func resumeConversation(
        conversationId: String,
        lastDataId: String?,
        eventHandler: @escaping (ConversationStreamEvent) -> Void
    ) async throws

    /// Get list of conversations (IDL: ListConversations)
    func getConversations(limit: Int?, offset: Int?) async throws -> [Conversation]

    /// Get conversation history (IDL: GetConversationHistory)
    func getConversationHistory(id: String) async throws -> [Message]

    /// Delete a conversation
    func deleteConversation(id: String) async throws
}
