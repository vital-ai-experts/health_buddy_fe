import Foundation
import LibraryNetworking
import DomainChat  // 导入StreamMessage
import LibraryBase

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
        Log.i("🚀 [OnboardingService] startOnboarding called", category: "Onboarding")
        
        let request = StartOnboardingRequest()
        
        let endpoint = APIEndpoint(
            path: "/onboarding/start",
            method: .post,
            body: request,
            requiresAuth: true
        )
        
        Log.i("📤 [OnboardingService] Calling API...", category: "Onboarding")
        do {
            try await apiClient.streamRequest(endpoint) { sseEvent in
                self.handleSSEEvent(sseEvent, eventHandler: eventHandler)
            }
            Log.i("✅ [OnboardingService] startOnboarding completed", category: "Onboarding")
        } catch {
            Log.e("❌ [OnboardingService] startOnboarding failed: \(error)", category: "Onboarding")
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
        Log.i("🚀 [OnboardingService] continueOnboarding called", category: "Onboarding")
        Log.i("  onboardingId: \(onboardingId)", category: "Onboarding")
        Log.i("  userInput: \(userInput ?? "nil")", category: "Onboarding")
        Log.i("  healthData: \(healthData ?? "nil")", category: "Onboarding")
        
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
        
        Log.i("📤 [OnboardingService] Calling API...", category: "Onboarding")
        do {
            try await apiClient.streamRequest(endpoint) { sseEvent in
                self.handleSSEEvent(sseEvent, eventHandler: eventHandler)
            }
            Log.i("✅ [OnboardingService] continueOnboarding completed", category: "Onboarding")
        } catch {
            Log.e("❌ [OnboardingService] continueOnboarding failed: \(error)", category: "Onboarding")
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
        Log.i("🔄 [OnboardingService] handleSSEEvent", category: "Onboarding")
        Log.i("  Event type: \(sseEvent.event)", category: "Onboarding")
        Log.i("  Data: \(sseEvent.data.prefix(200))...", category: "Onboarding")  // 只打印前200字符
        
        // SSE事件格式：data: { "id": "1", "data": {...} }
        // 只有一个data字段，对应的JSON反序列化后的StreamMessage
        
        guard let data = sseEvent.data.data(using: .utf8) else {
            Log.e("❌ [OnboardingService] Invalid data encoding", category: "Onboarding")
            eventHandler(.error("Invalid data encoding"))
            return
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let streamMessage = try decoder.decode(StreamMessage.self, from: data)
            
            Log.i("✅ [OnboardingService] Decoded StreamMessage", category: "Onboarding")
            Log.i("  id: \(streamMessage.id)", category: "Onboarding")
            Log.i("  msgId: \(streamMessage.data.msgId)", category: "Onboarding")
            Log.i("  dataType: \(streamMessage.data.dataType)", category: "Onboarding")
            Log.i("  messageType: \(String(describing: streamMessage.data.messageType))", category: "Onboarding")
            Log.i("  onboardingId: \(String(describing: streamMessage.data.onboardingId))", category: "Onboarding")
            Log.i("  content length: \(streamMessage.data.content?.count ?? 0)", category: "Onboarding")
            
            eventHandler(.streamMessage(streamMessage))
        } catch {
            Log.e("❌ [OnboardingService] Failed to decode: \(error)", category: "Onboarding")
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    Log.i("  Missing key: \(key.stringValue)", category: "Onboarding")
                    Log.i("  Context: \(context.debugDescription)", category: "Onboarding")
                case .typeMismatch(let type, let context):
                    Log.i("  Type mismatch: expected \(type)", category: "Onboarding")
                    Log.i("  Context: \(context.debugDescription)", category: "Onboarding")
                case .valueNotFound(let type, let context):
                    Log.i("  Value not found: \(type)", category: "Onboarding")
                    Log.i("  Context: \(context.debugDescription)", category: "Onboarding")
                case .dataCorrupted(let context):
                    Log.i("  Data corrupted: \(context.debugDescription)", category: "Onboarding")
                @unknown default:
                    Log.i("  Unknown decoding error", category: "Onboarding")
                }
            }
            eventHandler(.error("Failed to decode stream message: \(error.localizedDescription)"))
        }
    }
}

