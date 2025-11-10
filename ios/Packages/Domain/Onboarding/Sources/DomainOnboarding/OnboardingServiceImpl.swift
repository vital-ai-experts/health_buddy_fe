import Foundation
import LibraryNetworking

/// Onboarding服务实现
public final class OnboardingServiceImpl: OnboardingService {
    private let apiClient: APIClient
    
    public init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }
    
    /// 开始Onboarding
    public func startOnboarding(
        eventHandler: @escaping (OnboardingStreamEvent) -> Void
    ) async throws {
        print("🚀 [OnboardingService] startOnboarding called")
        
        let request = StartOnboardingRequest()
        
        let endpoint = APIEndpoint(
            path: "/onboarding/start",
            method: .post,
            body: request,
            requiresAuth: true
        )
        
        print("📤 [OnboardingService] Calling API...")
        do {
            try await apiClient.streamRequest(endpoint) { sseEvent in
                self.handleSSEEvent(sseEvent, eventHandler: eventHandler)
            }
            print("✅ [OnboardingService] startOnboarding completed")
        } catch {
            print("❌ [OnboardingService] startOnboarding failed: \(error)")
            throw error
        }
    }
    
    /// 继续Onboarding
    public func continueOnboarding(
        onboardingId: String,
        userInput: String?,
        healthData: String?,
        eventHandler: @escaping (OnboardingStreamEvent) -> Void
    ) async throws {
        print("🚀 [OnboardingService] continueOnboarding called")
        print("  onboardingId: \(onboardingId)")
        print("  userInput: \(userInput ?? "nil")")
        print("  healthData: \(healthData ?? "nil")")
        
        let request = ContinueOnboardingRequest(
            onboardingId: onboardingId,
            userInput: userInput,
            healthData: healthData
        )
        
        let endpoint = APIEndpoint(
            path: "/onboarding/continue",
            method: .post,
            body: request,
            requiresAuth: true
        )
        
        print("📤 [OnboardingService] Calling API...")
        do {
            try await apiClient.streamRequest(endpoint) { sseEvent in
                self.handleSSEEvent(sseEvent, eventHandler: eventHandler)
            }
            print("✅ [OnboardingService] continueOnboarding completed")
        } catch {
            print("❌ [OnboardingService] continueOnboarding failed: \(error)")
            throw error
        }
    }
    
    /// 恢复Onboarding
    public func resumeOnboarding(
        onboardingId: String,
        lastDataId: String?,
        eventHandler: @escaping (OnboardingStreamEvent) -> Void
    ) async throws {
        let request = ResumeOnboardingRequest(
            onboardingId: onboardingId,
            lastDataId: lastDataId
        )
        
        let endpoint = APIEndpoint(
            path: "/onboarding/resume",
            method: .post,
            body: request,
            requiresAuth: true
        )
        
        try await apiClient.streamRequest(endpoint) { sseEvent in
            self.handleSSEEvent(sseEvent, eventHandler: eventHandler)
        }
    }
    
    // MARK: - Private Methods
    
    /// 处理SSE事件
    private func handleSSEEvent(
        _ sseEvent: ServerSentEvent,
        eventHandler: @escaping (OnboardingStreamEvent) -> Void
    ) {
        print("🔄 [OnboardingService] handleSSEEvent")
        print("  Event type: \(sseEvent.event)")
        print("  Data: \(sseEvent.data.prefix(200))...")  // 只打印前200字符
        
        // SSE事件格式：data: { "id": "1", "data": {...} }
        // 只有一个data字段，对应的JSON反序列化后的StreamMessage
        
        guard let data = sseEvent.data.data(using: .utf8) else {
            print("❌ [OnboardingService] Invalid data encoding")
            eventHandler(.error("Invalid data encoding"))
            return
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let streamMessage = try decoder.decode(StreamMessage.self, from: data)
            
            print("✅ [OnboardingService] Decoded StreamMessage")
            print("  id: \(streamMessage.id)")
            print("  msgId: \(streamMessage.data.msgId)")
            print("  dataType: \(streamMessage.data.dataType)")
            print("  messageType: \(String(describing: streamMessage.data.messageType))")
            print("  onboardingId: \(String(describing: streamMessage.data.onboardingId))")
            print("  content length: \(streamMessage.data.content?.count ?? 0)")
            
            eventHandler(.streamMessage(streamMessage))
        } catch {
            print("❌ [OnboardingService] Failed to decode: \(error)")
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("  Missing key: \(key.stringValue)")
                    print("  Context: \(context.debugDescription)")
                case .typeMismatch(let type, let context):
                    print("  Type mismatch: expected \(type)")
                    print("  Context: \(context.debugDescription)")
                case .valueNotFound(let type, let context):
                    print("  Value not found: \(type)")
                    print("  Context: \(context.debugDescription)")
                case .dataCorrupted(let context):
                    print("  Data corrupted: \(context.debugDescription)")
                @unknown default:
                    print("  Unknown decoding error")
                }
            }
            eventHandler(.error("Failed to decode stream message: \(error.localizedDescription)"))
        }
    }
}

