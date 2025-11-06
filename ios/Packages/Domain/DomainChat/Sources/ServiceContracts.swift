import Foundation

/// Chat service protocol
public protocol ChatService {
    /// Send a message and receive streaming response
    func sendMessage(
        message: String,
        conversationId: String?,
        onEvent: @escaping (ChatStreamEvent) -> Void
    ) async throws

    /// Get list of conversations
    func getConversations(limit: Int?, offset: Int?) async throws -> [Conversation]

    /// Get a specific conversation with messages
    func getConversation(id: String) async throws -> (Conversation, [Message])

    /// Delete a conversation
    func deleteConversation(id: String) async throws
}
