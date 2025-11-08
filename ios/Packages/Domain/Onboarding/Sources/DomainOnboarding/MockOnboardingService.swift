import Foundation

/// Mock Onboarding 服务实现（用于测试和开发） - SSE 流式版本
public class MockOnboardingService: OnboardingService {
    private var currentStep = 0
    private let sessionId = UUID().uuidString
    
    public init() {}
    
    public func sendMessage(
        sessionId: String?,
        userMessage: UserMessage,
        eventHandler: @escaping (OnboardingStreamEvent) -> Void
    ) async throws {
        // 如果是初始化，发送sessionStart事件
        if userMessage.type == .initialize {
            currentStep = 0
            eventHandler(.sessionStart(sessionId: self.sessionId))
        }
        
        // 模拟网络延迟
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
        
        // 根据消息类型和当前步骤返回不同的响应
        if userMessage.type == .initialize {
            // 第一次初始化 - 流式输出2条消息
            await streamMessage(
                id: UUID().uuidString,
                text: "你好！我是你的健康助手 HealthBuddy 🤖",
                eventHandler: eventHandler
            )
            
            try await Task.sleep(nanoseconds: 300_000_000) // 0.3秒间隔
            
            await streamMessage(
                id: UUID().uuidString,
                text: "在开始之前，我想先了解一下你。请问怎么称呼你呢？",
                eventHandler: eventHandler
            )
            return
        }
        
        // 用户回复后的响应
        currentStep += 1
        
        switch currentStep {
        case 1:
            await streamMessage(
                id: UUID().uuidString,
                text: "很高兴认识你！👋",
                eventHandler: eventHandler
            )
            
            try await Task.sleep(nanoseconds: 300_000_000)
            
            await streamMessage(
                id: UUID().uuidString,
                text: "那么，你目前最关心的健康问题是什么呢？比如：运动、睡眠、饮食、心理健康等。",
                eventHandler: eventHandler
            )
            
        case 2:
            await streamMessage(
                id: UUID().uuidString,
                text: "了解了！我会特别关注这方面的建议。💪",
                eventHandler: eventHandler
            )
            
            try await Task.sleep(nanoseconds: 300_000_000)
            
            await streamMessage(
                id: UUID().uuidString,
                text: "你平时有运动的习惯吗？每周大概运动几次呢？",
                eventHandler: eventHandler
            )
            
        case 3:
            await streamMessage(
                id: UUID().uuidString,
                text: "非常好！保持规律运动很重要。🏃",
                eventHandler: eventHandler
            )
            
            try await Task.sleep(nanoseconds: 300_000_000)
            
            await streamMessage(
                id: UUID().uuidString,
                text: "最后一个问题：你希望通过 HealthBuddy 达成什么健康目标？",
                eventHandler: eventHandler
            )
            
        case 4:
            let userName = "朋友"
            await streamMessage(
                id: UUID().uuidString,
                text: "太棒了，\(userName)！✨\n\n我已经了解了你的基本情况。现在，让我们开始你的健康之旅吧！",
                action: BotMessageActionInfo(type: .finishOnboarding, title: "Let's Start"),
                eventHandler: eventHandler
            )
            
        default:
            await streamMessage(
                id: UUID().uuidString,
                text: "感谢你的回答！",
                eventHandler: eventHandler
            )
        }
    }
    
    /// 模拟流式输出单条消息 - 按字符逐个输出
    private func streamMessage(
        id: String,
        text: String,
        action: BotMessageActionInfo? = nil,
        eventHandler: @escaping (OnboardingStreamEvent) -> Void
    ) async {
        // 发送消息开始事件
        eventHandler(.messageStart(messageId: id))

        // 将消息按字符逐个流式输出
        for char in text {
            eventHandler(.contentDelta(content: String(char)))

            // 模拟打字速度 - 每个字符之间延迟
            // 英文字符和符号: 60ms
            // 中文字符和emoji: 80ms (稍慢一点)
            let delay: UInt64 = {
                // 检查是否是中文字符或emoji
                if char.unicodeScalars.first?.value ?? 0 > 0x4E00 {
                    return 80_000_000  // 80ms
                } else {
                    return 60_000_000  // 60ms
                }
            }()

            try? await Task.sleep(nanoseconds: delay)
        }

        // 发送消息结束事件，携带可选的 action 信息
        eventHandler(.messageEnd(action: action))
    }
}
