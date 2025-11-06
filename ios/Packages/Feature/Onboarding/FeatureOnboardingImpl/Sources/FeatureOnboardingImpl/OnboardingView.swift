import SwiftUI
import LibraryServiceLoader
import DomainOnboarding
import UIKit

/// Onboarding view with conversational Q&A flow
struct OnboardingView: View {
    let onComplete: () -> Void
    
    @State private var sessionId: String?
    @State private var messages: [MessageItem] = []
    @State private var userInputText = ""
    @State private var isLoading = false
    @State private var pendingBotMessages: [BotMessage] = [] // 待显示的Bot消息
    @State private var showActionButton = false
    @State private var actionButtonText = ""
    @State private var actionButtonAction: BotMessageAction?
    
    @FocusState private var isInputFocused: Bool
    
    private let onboardingService: OnboardingService
    
    init(
        onComplete: @escaping () -> Void,
        onboardingService: OnboardingService = ServiceManager.shared.resolve(OnboardingService.self)
    ) {
        self.onComplete = onComplete
        self.onboardingService = onboardingService
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Chat area
            ScrollViewReader { proxy in
                ZStack(alignment: .top) {
                    ScrollView {
                        VStack(spacing: 12) {
                        // 显示所有消息
                        ForEach(Array(messages.enumerated()), id: \.element.id) { index, message in
                            if message.isBot {
                                // 检查是否需要显示头像（第一条消息或上一条不是Bot消息）
                                let showAvatar = index == 0 || !messages[index - 1].isBot
                                BotMessageBubble(message: message, showAvatar: showAvatar)
                                    .id(message.id)
                                    .transition(.opacity)
                            } else {
                                UserMessageBubble(message: message)
                                    .id(message.id)
                                    .transition(.opacity)
                            }
                        }
                        
                        // Loading indicator (AI is typing...) 或待显示的消息
                        if isLoading || !pendingBotMessages.isEmpty {
                            // 检查是否需要显示头像（列表为空或最后一条不是Bot消息）
                            let showAvatarInTyping = messages.isEmpty || !messages.last!.isBot
                            BotTypingBubble(
                                isLoading: isLoading,
                                pendingMessages: pendingBotMessages,
                                showAvatar: showAvatarInTyping
                            )
                            .id("typing-bubble")
                        }
                        
                        // 底部空白占位，确保消息可以滚动到顶部
                        Color.clear
                            .frame(height: UIScreen.main.bounds.height * 0.5)
                            .id("bottom-spacer")
                        }
                        .animation(.easeInOut(duration: 0.3), value: messages.count)
                        .padding(.top, 40)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                    
                    // 顶部渐变遮罩层
                    VStack(spacing: 0) {
                        LinearGradient(
                            colors: [
                                Color(uiColor: .systemBackground),
                                Color(uiColor: .systemBackground),
                                Color(uiColor: .systemBackground),
                                Color(uiColor: .systemBackground),
                                Color(uiColor: .systemBackground),
                                Color(uiColor: .systemBackground),
                                Color(uiColor: .systemBackground),
                                Color(uiColor: .systemBackground).opacity(0.97),
                                Color(uiColor: .systemBackground).opacity(0.5),
                                Color(uiColor: .systemBackground).opacity(0.2),
                                Color(uiColor: .systemBackground).opacity(0.1),
                                Color(uiColor: .systemBackground).opacity(0.05),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 100)
                        
                        Spacer()
                    }
                    .edgesIgnoringSafeArea(.top)
                    .allowsHitTesting(false) // 允许点击穿透
                }
                .onChange(of: isLoading) {
                    if isLoading {
                        // 当开始加载时，滚动到 typing bubble 位置
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo("typing-bubble", anchor: .top)
                            }
                        }
                    }
                }
                .onChange(of: pendingBotMessages.count) {
                    if !pendingBotMessages.isEmpty {
                        // 当有待显示消息时，确保它在顶部可见
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo("typing-bubble", anchor: .top)
                            }
                        }
                    }
                }
            }
            
            Spacer()
            
            Divider()
            
            // Input area or action button
            if showActionButton {
                // Action button (e.g., "Let's Start")
                ActionButtonView(
                    text: actionButtonText,
                    action: {
                        handleActionButton()
                    }
                )
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            } else {
                // Text input area
                InputAreaView(
                    text: $userInputText,
                    isInputFocused: $isInputFocused,
                    isLoading: isLoading,
                    onSubmit: {
                        sendUserMessage()
                    }
                )
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
        }
        .background(Color(uiColor: .systemBackground))
        .task {
            await initializeOnboarding()
        }
    }
    
    // MARK: - Private Methods
    
    /// 初始化 Onboarding
    private func initializeOnboarding() async {
        isLoading = true
        
        do {
            let response = try await onboardingService.sendMessage(
                sessionId: nil,
                userMessage: UserMessage(type: .initialize)
            )
            
            await MainActor.run {
                sessionId = response.sessionId
                isLoading = false
                pendingBotMessages = response.botMessages.filter { $0.type == .text }
                
                // 延迟显示新的 Bot 消息（从待显示列表中逐个添加）
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    processPendingMessages(response.botMessages)
                }
            }
        } catch {
            print("❌ 初始化失败: \(error)")
        }
    }
    
    /// 发送用户消息
    private func sendUserMessage() {
        guard !userInputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        let messageText = userInputText
        userInputText = ""
        
        // 1. 添加用户消息到列表
        let userMessage = MessageItem(isBot: false, text: messageText)
        withAnimation(.easeInOut(duration: 0.3)) {
            messages.append(userMessage)
        }
        
        // 2. 延迟0.5秒后显示加载动画并发起请求
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // 显示加载动画（...）
            withAnimation(.easeInOut(duration: 0.3)) {
                isLoading = true
            }
            
            // 发起网络请求
            Task {
                await loadBotResponse(userText: messageText)
            }
        }
    }
    
    /// 加载 Bot 响应
    private func loadBotResponse(userText: String) async {
        // isLoading 已经在 sendUserMessage 中设置为 true
        
        do {
            // 发起网络请求（Mock 会延迟1秒）
            let response = try await onboardingService.sendMessage(
                sessionId: sessionId,
                userMessage: UserMessage(type: .textReply, text: userText)
            )
            
            await MainActor.run {
                // 1. 关闭加载动画，设置待显示的消息
                isLoading = false
                pendingBotMessages = response.botMessages.filter { $0.type == .text }
                
                // 2. 延迟显示新的 Bot 消息
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    processPendingMessages(response.botMessages)
                }
            }
        } catch {
            print("❌ 加载响应失败: \(error)")
            await MainActor.run {
                isLoading = false
                pendingBotMessages = []
            }
        }
    }
    
    /// 处理待显示的消息（一次性添加所有消息）
    private func processPendingMessages(_ botMessages: [BotMessage]) {
        guard !pendingBotMessages.isEmpty else { return }
        
        // 一次性添加所有text类型的消息
        let newMessages = pendingBotMessages.map { botMessage in
            MessageItem(
                id: botMessage.id,
                isBot: true,
                text: botMessage.text ?? "",
                action: nil
            )
        }
        
        // 清空pending列表
        pendingBotMessages.removeAll()
        
        // 一次性添加所有消息（依赖 .transition(.opacity) 自动渐显）
        messages.append(contentsOf: newMessages)
        
        // 所有消息都已显示，检查是否有 action button
        if let buttonMessage = botMessages.first(where: { $0.type == .actionButton }) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    showActionButton = true
                    actionButtonText = buttonMessage.text ?? "Continue"
                    actionButtonAction = buttonMessage.action
                }
            }
        } else {
            // 没有 action button，聚焦输入框
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isInputFocused = true
            }
        }
    }
    
    /// 处理 Action Button 点击
    private func handleActionButton() {
        guard let action = actionButtonAction else { return }
        
        switch action {
        case .finishOnboarding:
            onComplete()
        case .notiPermit, .healthPermit:
            // 处理权限请求
            print("处理权限: \(action.rawValue)")
        }
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
