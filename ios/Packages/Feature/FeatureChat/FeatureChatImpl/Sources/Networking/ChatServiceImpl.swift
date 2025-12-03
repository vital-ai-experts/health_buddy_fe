import Foundation
import FeatureChatApi
import LibraryChatUI
import LibraryNetworking
import LibraryBase

/// 默认 ChatService 实现，直连后端
public final class ChatServiceImpl: ChatService {
    private let apiClient: APIClient

    public init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    public func sendMessage(
        userInput: String?,
        conversationId: String?,
        eventHandler: @escaping (ConversationStreamEvent) -> Void
    ) async throws {
        let request = SendConversationMessageRequest(
            conversationId: conversationId,
            userInput: userInput
        )

        let endpoint = APIEndpoint(
            path: "/conversations/message/send",
            method: .post,
            body: request,
            requiresAuth: true
        )

        try await apiClient.streamRequest(endpoint) { sseEvent in
            self.handleSSEEvent(sseEvent, eventHandler: eventHandler)
        }
    }

    public func resumeConversation(
        conversationId: String,
        lastDataId: String?,
        eventHandler: @escaping (ConversationStreamEvent) -> Void
    ) async throws {
        let request = ResumeConversationMessageRequest(
            conversationId: conversationId,
            lastDataId: lastDataId
        )

        let endpoint = APIEndpoint(
            path: "/conversations/message/resume",
            method: .post,
            body: request,
            requiresAuth: true
        )

        try await apiClient.streamRequest(endpoint) { sseEvent in
            self.handleSSEEvent(sseEvent, eventHandler: eventHandler)
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
            path: "/conversations/list",
            method: .get,
            queryItems: queryItems,
            requiresAuth: true
        )

        let response: ListConversationsResponse = try await apiClient.request(
            endpoint,
            responseType: ListConversationsResponse.self
        )
        return response.conversations.map { Conversation(from: $0) }
    }

    public func getConversationHistory(id: String, chatSession: ChatSessionControlling?) async throws -> [Message] {
        let endpoint = APIEndpoint(
            path: "/conversations/history",
            method: .get,
            queryItems: [URLQueryItem(name: "id", value: id)],
            requiresAuth: true
        )

        let response: GetConversationHistoryResponse = try await apiClient.request(
            endpoint,
            responseType: GetConversationHistoryResponse.self
        )

        return response.messages.map { Message(from: $0, conversationId: id) }
    }

    public func deleteConversation(id: String) async throws {
        let endpoint = APIEndpoint(
            path: "/conversations/\(id)",
            method: .delete,
            requiresAuth: true
        )

        struct DeleteResponse: Codable { let message: String }
        let _: DeleteResponse = try await apiClient.request(endpoint, responseType: DeleteResponse.self)
    }

    private func handleSSEEvent(
        _ sseEvent: ServerSentEvent,
        eventHandler: @escaping (ConversationStreamEvent) -> Void
    ) {
        guard let data = sseEvent.data.data(using: .utf8) else {
            eventHandler(.error("Invalid data encoding"))
            return
        }

        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let streamMessage = try decoder.decode(StreamMessage.self, from: data)
            Log.i("✅ [ChatService] Decoded StreamMessage", category: "Chat")
            eventHandler(.streamMessage(streamMessage))
        } catch {
            Log.e("❌ [ChatService] Failed to decode: \(error)", category: "Chat")
            eventHandler(.error("Failed to decode stream message: \(error.localizedDescription)"))
        }
    }
}
