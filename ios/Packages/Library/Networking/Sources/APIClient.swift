import Foundation

/// Protocol for providing common query parameters that should be added to all API requests
public protocol CommonParamsProvider {
    /// Returns common query parameters to be appended to every API request
    /// - Returns: Array of URLQueryItem containing common parameters like region, language, device_id, etc.
    func getCommonQueryParams() -> [URLQueryItem]
}

/// API client for making HTTP requests
public final class APIClient {
    public static let shared = APIClient()

    private static let DEBUG_LOCAL_SERVER_URL = "http://192.168.31.190:8888/api/v1"
    private static let PROD_SERVER_URL = "https://vital.ninimu.com/api/v1"

    #if DEBUG
    private static let USE_DEBUG_LOCAL_SERVER = false
    #else
    private static let USE_DEBUG_LOCAL_SERVER = false
    #endif

    private let baseURL: URL = {
        if USE_DEBUG_LOCAL_SERVER {
            return URL(string: DEBUG_LOCAL_SERVER_URL)!
        } else {
            return URL(string: PROD_SERVER_URL)!
        }
    }()

    private let session: URLSession
    private var authToken: String?
    private var commonParamsProvider: CommonParamsProvider?

    public init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 300

        // 启用自动等待网络连接
        // 当网络暂时不可用时，URLSession会等待而不是立即失败
        configuration.waitsForConnectivity = true

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

    /// Set common parameters provider
    /// - Parameter provider: The provider that will supply common query parameters for all requests
    public func setCommonParamsProvider(_ provider: CommonParamsProvider?) {
        self.commonParamsProvider = provider
    }

    /// Health check - triggers network permission prompt
    public func healthCheck() async throws {
        let url = URL(string: "https://vital.ninimu.com/ping")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        
        print("🌐 [APIClient] Starting healthCheck")
        print("  URL: \(request.url?.absoluteString ?? "nil")")
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            throw APIError.httpError(statusCode: httpResponse.statusCode, message: "Health check failed")
        }
    }
    
    /// Make a network request
    public func request<T: Decodable>(
        _ endpoint: APIEndpoint,
        responseType: T.Type
    ) async throws -> T {
        let request = try buildRequest(endpoint)

        print("🌐 [APIClient] Starting request")
        print("  URL: \(request.url?.absoluteString ?? "nil")")

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as NSError {
            // 捕获网络层错误（超时、无连接等）
            print("❌ [APIClient] Network error: \(error.localizedDescription)")
            throw APIError.networkError(error)
        }

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

        print("🌐 [APIClient] Starting stream request")
        print("  URL: \(request.url?.absoluteString ?? "nil")")
        print("  Method: \(request.httpMethod ?? "nil")")
        print("  Headers: \(request.allHTTPHeaderFields ?? [:])")
        if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            print("  Body: \(bodyString)")
        }

        let (bytes, response): (URLSession.AsyncBytes, URLResponse)
        do {
            (bytes, response) = try await session.bytes(for: request)
        } catch let error as NSError {
            // 捕获网络层错误（超时、无连接等）
            print("❌ [APIClient] Network error during stream initialization: \(error.localizedDescription)")
            print("  Error code: \(error.code)")
            print("  Error domain: \(error.domain)")
            throw APIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ [APIClient] Invalid response type")
            throw APIError.invalidResponse
        }

        print("✅ [APIClient] Response received")
        print("  Status: \(httpResponse.statusCode)")
        print("  Headers: \(httpResponse.allHeaderFields)")

        guard 200...299 ~= httpResponse.statusCode else {
            print("❌ [APIClient] HTTP error: \(httpResponse.statusCode)")
            throw APIError.httpError(statusCode: httpResponse.statusCode, message: "Request failed")
        }

        print("📡 [APIClient] Starting to receive SSE stream...")
        var buffer = Data()
        var eventCount = 0

        do {
            for try await byte in bytes {
                buffer.append(byte)

                // 检查是否遇到 SSE 事件分隔符 "\n\n"
                if buffer.count >= 2 {
                    let lastTwoBytes = buffer.suffix(2)
                    if lastTwoBytes[lastTwoBytes.startIndex] == 0x0A &&
                       lastTwoBytes[lastTwoBytes.index(after: lastTwoBytes.startIndex)] == 0x0A {
                        // 找到 "\n\n"，处理这个事件
                        eventCount += 1

                        // 将 Data 转换为 UTF-8 字符串
                        if let eventString = String(data: buffer, encoding: .utf8) {
                            print("📨 [APIClient] Received SSE event #\(eventCount)")
                            print("  Raw: \(eventString.replacingOccurrences(of: "\n", with: "\\n"))")

                            let event = parseServerSentEvent(eventString)
                            if let event = event {
                                print("  ✅ Parsed successfully")
                                print("  Event type: \(event.event)")
                                print("  Data length: \(event.data.count) chars")
                                onEvent(event)
                            } else {
                                print("  ⚠️ Failed to parse SSE event")
                            }
                        } else {
                            print("  ❌ Failed to decode UTF-8 data")
                        }

                        buffer = Data()
                    }
                }
            }
        } catch let error as NSError {
            // 捕获流读取过程中的网络错误
            print("❌ [APIClient] Network error during stream reading: \(error.localizedDescription)")
            print("  Error code: \(error.code)")
            print("  Error domain: \(error.domain)")
            throw APIError.networkError(error)
        }

        print("🏁 [APIClient] Stream ended. Total events: \(eventCount)")
    }

    // MARK: - Private Methods

    private func buildRequest(_ endpoint: APIEndpoint) throws -> URLRequest {
        let url = baseURL.appendingPathComponent(endpoint.path)

        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!

        var allQueryItems: [URLQueryItem] = []

        if let provider = commonParamsProvider {
            allQueryItems.append(contentsOf: provider.getCommonQueryParams())
        }

        allQueryItems.append(contentsOf: endpoint.queryItems)

        if !allQueryItems.isEmpty {
            components.queryItems = allQueryItems
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

        // Add X-Vital-Secret header for vital.ninimu requests
        request.setValue("APTX-4869", forHTTPHeaderField: "X-Vital-Secret")

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

        // data字段是必须的
        guard let eventData = data else {
            return nil
        }
        
        // event字段是可选的，如果没有则使用"message"作为默认值
        let eventType = event ?? "message"

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
            let nsError = error as NSError
            // 处理常见的网络错误码
            switch nsError.code {
            case NSURLErrorTimedOut:
                return "Request timed out. Please check your connection and try again."
            case NSURLErrorNotConnectedToInternet:
                return "No internet connection. Please check your network settings."
            case NSURLErrorNetworkConnectionLost:
                return "Network connection lost. Please try again."
            case NSURLErrorCannotConnectToHost:
                return "Cannot connect to server. Please try again later."
            case NSURLErrorDNSLookupFailed:
                return "Cannot reach server. Please check your connection."
            default:
                return "Network error: \(error.localizedDescription)"
            }
        }
    }
}

struct ErrorResponse: Decodable {
    let detail: String
}
