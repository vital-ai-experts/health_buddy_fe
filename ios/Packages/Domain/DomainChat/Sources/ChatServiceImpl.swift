import Foundation
import LibraryNetworking

/// Default implementation of ChatService
public final class ChatServiceImpl: ChatService {
    private let apiClient: APIClient

    public init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    public func sendMessage(
        message: String,
        conversationId: String?,
        onEvent: @escaping (ChatStreamEvent) -> Void
    ) async throws {
        let request = ChatMessageRequest(message: message, conversationId: conversationId)

        let endpoint = APIEndpoint(
            path: "/chat/send",
            method: .post,
            body: request,
            requiresAuth: true
        )

        try await apiClient.streamRequest(endpoint) { serverEvent in
            let chatEvent = self.parseChatEvent(serverEvent)
            onEvent(chatEvent)
        }
    }

    public func getConversations(limit: Int? = nil, offset: Int? = nil) async throws -> [Conversation] {
        var queryItems: [URLQueryItem] = []
        if let limit = limit {
            queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        }
        if let offset = offset {
            queryItems.append(URLQueryItem(name: "offset", value: String(offset)))
        }

        let endpoint = APIEndpoint(
            path: "/chat/conversations",
            method: .get,
            queryItems: queryItems,
            requiresAuth: true
        )

        let responses: [ConversationResponse] = try await apiClient.request(endpoint, responseType: [ConversationResponse].self)
        return responses.map { Conversation(from: $0) }
    }

    public func getConversation(id: String) async throws -> (Conversation, [Message]) {
        let endpoint = APIEndpoint(
            path: "/chat/conversations/\(id)",
            method: .get,
            requiresAuth: true
        )

        let response: ConversationWithMessagesResponse = try await apiClient.request(
            endpoint,
            responseType: ConversationWithMessagesResponse.self
        )

        let conversation = Conversation(
            id: response.id,
            userId: response.userId,
            title: response.title,
            createdAt: response.createdAt,
            updatedAt: response.updatedAt
        )
        let messages = response.messages.map { Message(from: $0) }

        return (conversation, messages)
    }

    public func deleteConversation(id: String) async throws {
        let endpoint = APIEndpoint(
            path: "/chat/conversations/\(id)",
            method: .delete,
            requiresAuth: true
        )

        struct DeleteResponse: Codable {
            let message: String
        }

        let _: DeleteResponse = try await apiClient.request(endpoint, responseType: DeleteResponse.self)
    }

    // MARK: - Private Methods

    private func parseChatEvent(_ serverEvent: ServerSentEvent) -> ChatStreamEvent {
        switch serverEvent.event {
        case "conversation_id":
            if let data = serverEvent.data.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let conversationId = json["conversation_id"] as? String {
                return .conversationStart(conversationId: conversationId)
            }
            return .error("Invalid conversation_id event")

        case "message":
            if let data = serverEvent.data.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let delta = json["delta"] as? String {
                return .contentDelta(content: delta)
            }
            return .error("Invalid message event")

        case "done":
            return .messageEnd

        case "error":
            if let data = serverEvent.data.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = json["error"] as? String {
                return .error(error)
            }
            return .error("Unknown error")

        default:
            // Ignore unknown events (like tool_use, tool_result)
            return .ignored
        }
    }
}
