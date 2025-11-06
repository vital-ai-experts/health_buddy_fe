import Foundation

/// Mock Onboarding 服务实现（用于 Demo）
public class MockOnboardingService: OnboardingService {
    private var currentStep = 0
    private let sessionId = UUID().uuidString
    
    public init() {}
    
    public func sendMessage(sessionId: String?, userMessage: UserMessage) async throws -> OnboardingResponseData {
        // 模拟网络延迟
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1秒
        
        // 根据消息类型和当前步骤返回不同的响应
        if userMessage.type == .initialize {
            // 第一次初始化 - 返回2条消息
            currentStep = 0
            return OnboardingResponseData(
                sessionId: self.sessionId,
                botMessages: [
                    BotMessage(
                        type: .text,
                        text: "你好！我是你的健康助手 HealthBuddy 🤖",
                        action: nil
                    ),
                    BotMessage(
                        type: .text,
                        text: "在开始之前，我想先了解一下你。请问怎么称呼你呢？",
                        action: nil
                    )
                ]
            )
        }
        
        // 用户回复后的响应
        currentStep += 1
        
        switch currentStep {
        case 1:
            // 第一个问题回答后 - 返回2条消息
            return OnboardingResponseData(
                sessionId: self.sessionId,
                botMessages: [
                    BotMessage(
                        type: .text,
                        text: "很高兴认识你！👋",
                        action: nil
                    ),
                    BotMessage(
                        type: .text,
                        text: "那么，你目前最关心的健康问题是什么呢？比如：运动、睡眠、饮食、心理健康等。",
                        action: nil
                    )
                ]
            )
            
        case 2:
            // 第二个问题回答后 - 返回2条消息
            return OnboardingResponseData(
                sessionId: self.sessionId,
                botMessages: [
                    BotMessage(
                        type: .text,
                        text: "了解了！我会特别关注这方面的建议。💪",
                        action: nil
                    ),
                    BotMessage(
                        type: .text,
                        text: "你平时有运动的习惯吗？每周大概运动几次呢？",
                        action: nil
                    )
                ]
            )
            
        case 3:
            // 第三个问题回答后 - 返回2条消息
            return OnboardingResponseData(
                sessionId: self.sessionId,
                botMessages: [
                    BotMessage(
                        type: .text,
                        text: "非常好！保持规律运动很重要。🏃",
                        action: nil
                    ),
                    BotMessage(
                        type: .text,
                        text: "最后一个问题：你希望通过 HealthBuddy 达成什么健康目标？",
                        action: nil
                    )
                ]
            )
            
        case 4:
            // 最后一个问题回答后 - 返回完成消息
            let userName = "朋友" // 实际应该从第一次回答中获取
            return OnboardingResponseData(
                sessionId: self.sessionId,
                botMessages: [
                    BotMessage(
                        type: .text,
                        text: "太棒了，\(userName)！✨\n\n我已经了解了你的基本情况。现在，让我们开始你的健康之旅吧！",
                        action: nil
                    ),
                    BotMessage(
                        type: .actionButton,
                        text: "Let's Start",
                        action: .finishOnboarding
                    )
                ]
            )
            
        default:
            // 意外情况
            return OnboardingResponseData(
                sessionId: self.sessionId,
                botMessages: [
                    BotMessage(
                        type: .text,
                        text: "感谢你的回答！",
                        action: nil
                    )
                ]
            )
        }
    }
}

