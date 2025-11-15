import Foundation

/// API client for Agenda task completion notifications
actor AgendaAPIClient {
    static let shared = AgendaAPIClient()

    // TODO: Replace with your actual backend URL
    private let baseURL = "https://your-backend-api.com"
    private let timeoutInterval: TimeInterval = 10.0

    private init() {}

    /// Notify server that a task has been completed
    /// - Parameters:
    ///   - userId: User identifier
    ///   - taskId: Completed task identifier
    ///   - task: Task description
    /// - Returns: Success status
    func notifyTaskCompletion(userId: String, taskId: String, task: String) async throws -> Bool {
        let endpoint = "\(baseURL)/api/agenda/task/complete"

        guard let url = URL(string: endpoint) else {
            print("❌ Invalid API endpoint: \(endpoint)")
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = timeoutInterval

        let payload: [String: Any] = [
            "userId": userId,
            "taskId": taskId,
            "task": task,
            "completedAt": ISO8601DateFormatter().string(from: Date())
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            print("❌ Failed to serialize request payload: \(error)")
            throw APIError.serializationError
        }

        print("📤 Sending task completion to server...")
        print("   - URL: \(endpoint)")
        print("   - User ID: \(userId)")
        print("   - Task: \(task)")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            print("📥 Server response: \(httpResponse.statusCode)")

            guard (200...299).contains(httpResponse.statusCode) else {
                print("❌ Server returned error status: \(httpResponse.statusCode)")
                throw APIError.serverError(statusCode: httpResponse.statusCode)
            }

            // Log response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("   - Response body: \(responseString)")
            }

            print("✅ Task completion notification sent successfully")
            return true

        } catch let error as APIError {
            throw error
        } catch {
            print("❌ Network error: \(error)")
            // Don't throw network errors - we want to continue even if server is unreachable
            // The server update is best-effort
            print("⚠️ Continuing despite network error (best-effort)")
            return false
        }
    }
}

enum APIError: LocalizedError {
    case invalidURL
    case serializationError
    case invalidResponse
    case serverError(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .serializationError:
            return "Failed to serialize request data"
        case .invalidResponse:
            return "Invalid server response"
        case .serverError(let code):
            return "Server error: HTTP \(code)"
        }
    }
}
