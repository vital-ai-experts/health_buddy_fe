import Foundation

/// API client for making HTTP requests
public final class APIClient {
    public static let shared = APIClient()

    private let baseURL: URL
    private let session: URLSession
    private var authToken: String?

    public init(baseURL: String = "https://vital.ninimu.com/api/v1") {
        self.baseURL = URL(string: baseURL)!

        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: configuration)
    }

    /// Set authentication token
    public func setAuthToken(_ token: String?) {
        self.authToken = token
    }

    /// Get current authentication token
    public func getAuthToken() -> String? {
        return authToken
    }

    /// Make a network request
    public func request<T: Decodable>(
        _ endpoint: APIEndpoint,
        responseType: T.Type
    ) async throws -> T {
        let request = try buildRequest(endpoint)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard 200...299 ~= httpResponse.statusCode else {
            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            throw APIError.httpError(
                statusCode: httpResponse.statusCode,
                message: errorResponse?.detail ?? "Unknown error"
            )
        }

        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    /// Make a streaming request (for chat)
    public func streamRequest(
        _ endpoint: APIEndpoint,
        onEvent: @escaping (ServerSentEvent) -> Void
    ) async throws {
        let request = try buildRequest(endpoint)

        let (bytes, response) = try await session.bytes(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard 200...299 ~= httpResponse.statusCode else {
            throw APIError.httpError(statusCode: httpResponse.statusCode, message: "Request failed")
        }

        var buffer = ""
        for try await byte in bytes {
            let character = String(UnicodeScalar(byte))
            buffer.append(character)

            if buffer.hasSuffix("\n\n") {
                let event = parseServerSentEvent(buffer)
                if let event = event {
                    onEvent(event)
                }
                buffer = ""
            }
        }
    }

    // MARK: - Private Methods

    private func buildRequest(_ endpoint: APIEndpoint) throws -> URLRequest {
        let url = baseURL.appendingPathComponent(endpoint.path)

        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        if !endpoint.queryItems.isEmpty {
            components.queryItems = endpoint.queryItems
        }

        guard let finalURL = components.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: finalURL)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Add authentication token if available and required
        if endpoint.requiresAuth, let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Add request body
        if let body = endpoint.body {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            request.httpBody = try encoder.encode(body)
        }

        return request
    }

    private func parseServerSentEvent(_ text: String) -> ServerSentEvent? {
        let lines = text.split(separator: "\n")
        var event: String?
        var data: String?

        for line in lines {
            if line.hasPrefix("event:") {
                event = String(line.dropFirst(6).trimmingCharacters(in: .whitespaces))
            } else if line.hasPrefix("data:") {
                data = String(line.dropFirst(5).trimmingCharacters(in: .whitespaces))
            }
        }

        guard let eventType = event, let eventData = data else {
            return nil
        }

        return ServerSentEvent(event: eventType, data: eventData)
    }
}

// MARK: - Supporting Types

public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

public struct APIEndpoint {
    public let path: String
    public let method: HTTPMethod
    public let queryItems: [URLQueryItem]
    public let body: Encodable?
    public let requiresAuth: Bool

    public init(
        path: String,
        method: HTTPMethod,
        queryItems: [URLQueryItem] = [],
        body: Encodable? = nil,
        requiresAuth: Bool = false
    ) {
        self.path = path
        self.method = method
        self.queryItems = queryItems
        self.body = body
        self.requiresAuth = requiresAuth
    }
}

public struct ServerSentEvent {
    public let event: String
    public let data: String

    public init(event: String, data: String) {
        self.event = event
        self.data = data
    }
}

public enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, message: String)
    case decodingError(Error)
    case encodingError(Error)
    case networkError(Error)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode, let message):
            return "HTTP \(statusCode): \(message)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Failed to encode request: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

struct ErrorResponse: Decodable {
    let detail: String
}
