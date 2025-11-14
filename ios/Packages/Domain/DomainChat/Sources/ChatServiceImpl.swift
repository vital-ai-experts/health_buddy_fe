import Foundation
import LibraryNetworking

/// Default implementation of ChatService
public final class ChatServiceImpl: ChatService {
    private let apiClient: APIClient

    public init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    // MARK: - ChatService Implementation

    /// 发送对话消息（IDL: /conversations/message/send）
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

    /// 恢复对话（IDL: /conversations/message/resume）
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

    /// 获取对话列表（IDL: /conversations/list）
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

    /// 获取对话历史（IDL: /conversations/history）
    public func getConversationHistory(id: String) async throws -> [Message] {
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

    /// 删除对话
    public func deleteConversation(id: String) async throws {
        let endpoint = APIEndpoint(
            path: "/conversations/\(id)",
            method: .delete,
            requiresAuth: true
        )

        struct DeleteResponse: Codable {
            let message: String
        }

        let _: DeleteResponse = try await apiClient.request(endpoint, responseType: DeleteResponse.self)
    }

    // MARK: - Private Methods

    /// SSE事件处理（参考OnboardingServiceImpl的实现）
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

            print("✅ [ChatService] Decoded StreamMessage")
            print("  id: \(streamMessage.id)")
            print("  msgId: \(streamMessage.data.msgId)")
            print("  dataType: \(streamMessage.data.dataType)")
            print("  conversationId: \(streamMessage.data.conversationId ?? "nil")")
            print("  content length: \(streamMessage.data.content?.count ?? 0)")

            eventHandler(.streamMessage(streamMessage))
        } catch {
            print("❌ [ChatService] Failed to decode: \(error)")
            eventHandler(.error("Failed to decode stream message: \(error.localizedDescription)"))
        }
    }
}
