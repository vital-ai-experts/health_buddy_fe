import SwiftUI
import LibraryServiceLoader
import DomainOnboarding
import LibraryChatUI

/// Onboarding view with conversational Q&A flow
struct OnboardingView: View {
    let onComplete: () -> Void

    @StateObject private var viewModel: OnboardingViewModel

    init(
        onComplete: @escaping () -> Void,
        onboardingService: OnboardingService = ServiceManager.shared.resolve(OnboardingService.self)
    ) {
        self.onComplete = onComplete
        _viewModel = StateObject(wrappedValue: OnboardingViewModel(
            onboardingService: onboardingService,
            onComplete: onComplete
        ))
    }

    var body: some View {
        ZStack {
            SimpleChatView(
                messages: $viewModel.displayMessages,
                inputText: $viewModel.inputText,
                isLoading: viewModel.isLoading,
                configuration: ChatConfiguration(
                    autoFocusAfterBotMessage: false,
                    dismissKeyboardAfterSend: true
                ),
                bottomPadding: 200,  // Onboarding 需要底部空间让消息滚动到舒适位置
                onSendMessage: { text in
                    viewModel.sendMessage(text)
                }
            )

            // 顶部渐变遮罩 - 使用固定高度避免布局循环
            VStack(spacing: 0) {
                LinearGradient(
                    stops: [
                        .init(color: Color(uiColor: .systemBackground), location: 0.0),   // 顶部完全不透明
                        .init(color: Color(uiColor: .systemBackground), location: 0.6),   // 保持不透明到60%
                        .init(color: Color(uiColor: .systemBackground).opacity(0.5), location: 0.8),  // 快速渐变
                        .init(color: Color(uiColor: .systemBackground).opacity(0), location: 1.0)     // 底部完全透明
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 70)  // 使用固定高度（状态栏 ~47pt + 渐变区域 23pt）
                .allowsHitTesting(false)
                .ignoresSafeArea(edges: .top) // 延伸到状态栏区域

                Spacer()
            }

            // Action button overlay (when needed)
            VStack {
                Spacer()

                if viewModel.showActionButton {
                    VStack(spacing: 0) {
                        // 渐变背景
                        LinearGradient(
                            colors: [
                                Color(uiColor: .systemBackground).opacity(0),
                                Color(uiColor: .systemBackground)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 40)
                        
                        // 按钮区域
                        Button(action: {
                            viewModel.handleActionButton()
                        }) {
                            Text(viewModel.actionButtonText)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                        .background(Color(uiColor: .systemBackground))
                    }
                }
            }
        }
        .background(Color(uiColor: .systemBackground))
        .task {
            await viewModel.initializeOnboarding()
        }
    }
}

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var displayMessages: [ChatMessage] = []
    @Published var inputText = ""
    @Published var isLoading = false
    @Published var showActionButton = false
    @Published var actionButtonText = ""

    private var onboardingId: String?
    private var lastDataId: String?  // 记录最新的data id，用于断线重连
    private var actionButtonAction: BotMessageAction?
    private let onboardingService: OnboardingService
    private let onComplete: () -> Void
    
    // 消息ID到ChatMessage的映射，用于处理流式更新
    private var messageMap: [String: Int] = [:]  // msgId -> displayMessages index
    
    // 需要用户交互的工具名称集合
    private let interactiveToolNames: Set<String> = ["authorize_health_data", "noti_permit", "finish_onboarding"]

    init(onboardingService: OnboardingService, onComplete: @escaping () -> Void) {
        self.onboardingService = onboardingService
        self.onComplete = onComplete
    }

    func initializeOnboarding() async {
        print("🎬 [OnboardingViewModel] initializeOnboarding started")
        isLoading = true

        do {
            try await onboardingService.startOnboarding(
                eventHandler: { [weak self] event in
                    self?.handleStreamEvent(event)
                }
            )

            isLoading = false
            print("✅ [OnboardingViewModel] initializeOnboarding completed")
        } catch {
            print("❌ [OnboardingViewModel] 初始化失败: \(error)")
            isLoading = false
        }
    }

    func sendMessage(_ text: String) {
        print("💬 [OnboardingViewModel] sendMessage called: \(text.prefix(50))...")
        
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("⚠️ [OnboardingViewModel] Empty message, skipping")
            return
        }
        
        guard let onboardingId = onboardingId else {
            print("❌ [OnboardingViewModel] onboardingId 为空，无法发送消息")
            return
        }

        // 1. 立即添加用户消息到 UI
        let userMsg = ChatMessage(
            id: UUID().uuidString,
            text: text,
            isFromUser: true,
            timestamp: Date(),
            isStreaming: false
        )
        displayMessages.append(userMsg)
        print("✅ [OnboardingViewModel] User message added to UI")

        // 2. 清空输入框
        inputText = ""

        // 3. 延迟显示 loading，让用户消息先渲染
        Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3秒
            self.isLoading = true

            do {
                print("📤 [OnboardingViewModel] Calling continueOnboarding...")
                try await onboardingService.continueOnboarding(
                    onboardingId: onboardingId,
                    userInput: text,
                    healthData: nil,
                    eventHandler: { [weak self] event in
                        self?.handleStreamEvent(event)
                    }
                )

                self.isLoading = false
                print("✅ [OnboardingViewModel] continueOnboarding completed")
            } catch {
                print("❌ [OnboardingViewModel] 发送消息失败: \(error)")
                self.isLoading = false
                
                // TODO: 可以在这里尝试调用 resumeOnboarding
            }
        }
    }

    private func handleStreamEvent(_ event: OnboardingStreamEvent) {
        Task { @MainActor in
            switch event {
            case .streamMessage(let streamMessage):
                print("📩 [OnboardingViewModel] Received stream message")
                print("  id: \(streamMessage.id)")
                print("  dataType: \(streamMessage.data.dataType)")
                
                // 记录最新的data id
                lastDataId = streamMessage.id
                
                let data = streamMessage.data
                
                // 保存onboardingId
                if let oid = data.onboardingId {
                    if onboardingId == nil {
                        print("✅ [OnboardingViewModel] Got onboardingId: \(oid)")
                    }
                    onboardingId = oid
                }
                
                switch data.dataType {
                case .agentStatus:
                    print("  → Processing agentStatus")
                    // 处理Agent状态
                    handleAgentStatus(data.agentStatus)
                    
                case .agentMessage:
                    print("  → Processing agentMessage")
                    print("    msgId: \(data.msgId)")
                    print("    messageType: \(String(describing: data.messageType))")
                    print("    content length: \(data.content?.count ?? 0)")
                    // 处理Agent消息（chunk或whole）
                    handleAgentMessage(data)
                    
                case .agentToolCall:
                    print("  → Processing agentToolCall")
                    // 处理工具调用
                    handleToolCall(data)
                }

            case .error(let message):
                print("❌ [OnboardingViewModel] Stream error: \(message)")
                isLoading = false
            }
        }
    }
    
    private func handleAgentStatus(_ status: AgentStatus?) {
        guard let status = status else { return }
        
        switch status {
        case .generating:
            print("🤖 Agent 生成中...")
            
        case .finished:
            print("✅ Agent 完成")
            // 将所有仍在 streaming 状态的消息更新为非 streaming
            for (index, message) in displayMessages.enumerated() {
                if message.isStreaming {
                    var updatedMessage = message
                    updatedMessage = ChatMessage(
                        id: updatedMessage.id,
                        text: updatedMessage.text,
                        isFromUser: updatedMessage.isFromUser,
                        timestamp: updatedMessage.timestamp,
                        isStreaming: false,
                        thinkingContent: updatedMessage.thinkingContent,
                        toolCalls: updatedMessage.toolCalls
                    )
                    displayMessages[index] = updatedMessage
                    print("  → Message at index \(index) set to non-streaming")
                }
            }
            isLoading = false
            
        case .error:
            print("❌ Agent 错误")
            // 错误时也将所有消息设为非 streaming
            for (index, message) in displayMessages.enumerated() {
                if message.isStreaming {
                    var updatedMessage = message
                    updatedMessage = ChatMessage(
                        id: updatedMessage.id,
                        text: updatedMessage.text,
                        isFromUser: updatedMessage.isFromUser,
                        timestamp: updatedMessage.timestamp,
                        isStreaming: false,
                        thinkingContent: updatedMessage.thinkingContent,
                        toolCalls: updatedMessage.toolCalls
                    )
                    displayMessages[index] = updatedMessage
                }
            }
            isLoading = false
            
        case .stopped:
            print("⏸️ Agent 停止")
            // 停止时也将所有消息设为非 streaming
            for (index, message) in displayMessages.enumerated() {
                if message.isStreaming {
                    var updatedMessage = message
                    updatedMessage = ChatMessage(
                        id: updatedMessage.id,
                        text: updatedMessage.text,
                        isFromUser: updatedMessage.isFromUser,
                        timestamp: updatedMessage.timestamp,
                        isStreaming: false,
                        thinkingContent: updatedMessage.thinkingContent,
                        toolCalls: updatedMessage.toolCalls
                    )
                    displayMessages[index] = updatedMessage
                }
            }
            isLoading = false
        }
    }
    
    private func handleAgentMessage(_ data: StreamMessageData) {
        let msgId = data.msgId
        
        print("💭 [OnboardingViewModel] handleAgentMessage")
        print("  msgId: \(msgId)")
        print("  content: \(data.content ?? "nil")")
        print("  thinking_content: \(data.thinkingContent ?? "nil")")
        print("  messageType: \(String(describing: data.messageType))")
        print("  toolCalls count: \(data.toolCalls?.count ?? 0)")
        
        // 检查是否有任何内容需要显示
        let hasContent = data.content != nil && !data.content!.isEmpty
        let hasThinking = data.thinkingContent != nil && !data.thinkingContent!.isEmpty
        let hasToolCalls = data.toolCalls != nil && !data.toolCalls!.isEmpty
        
        // 如果content、thinking和toolCalls都为空，才跳过
        guard hasContent || hasThinking || hasToolCalls else {
            print("  → No content, thinking or tool calls, skipping UI update")
            return
        }
        
        // 使用content，如果为空则使用空字符串（但仍然可以显示thinking和toolCalls）
        let content = data.content ?? ""
        
        // 将需要用户交互的工具调用过滤掉（不在消息中显示，通过actionButton显示）
        // 不需要用户交互的工具调用仍然在消息中显示
        let toolCallInfos: [ToolCallInfo]? = data.toolCalls?.compactMap { toolCall in
            // 如果是需要用户交互的工具，返回 nil（过滤掉）
            guard !interactiveToolNames.contains(toolCall.toolCallName) else {
                return nil
            }
            // 否则返回 ToolCallInfo（显示在消息中）
            return ToolCallInfo(
                id: toolCall.toolCallId,
                name: toolCall.toolCallName,
                args: toolCall.toolCallArgs,
                status: toolCall.toolCallStatus?.description,
                result: toolCall.toolCallResult
            )
        }
        
        // 查找或创建消息
        if let index = messageMap[msgId] {
            print("  → Updating existing message at index \(index)")
            // 更新现有消息（每次收到的content都是完整的，不是delta）
            var message = displayMessages[index]
            message = ChatMessage(
                id: message.id,
                text: content,
                isFromUser: message.isFromUser,
                timestamp: message.timestamp,
                isStreaming: true,  // 当前正在处理的消息保持 streaming 状态
                thinkingContent: data.thinkingContent,
                toolCalls: toolCallInfos
            )
            displayMessages[index] = message
            
        } else {
            print("  → Creating new message")
            
            // 新消息到来时，将之前所有的消息设置为非 streaming 状态
            for (idx, msg) in displayMessages.enumerated() {
                if msg.isStreaming {
                    var updatedMsg = msg
                    updatedMsg = ChatMessage(
                        id: updatedMsg.id,
                        text: updatedMsg.text,
                        isFromUser: updatedMsg.isFromUser,
                        timestamp: updatedMsg.timestamp,
                        isStreaming: false,
                        thinkingContent: updatedMsg.thinkingContent,
                        toolCalls: updatedMsg.toolCalls
                    )
                    displayMessages[idx] = updatedMsg
                    print("  ✅ Previous message at index \(idx) set to non-streaming")
                }
            }
            
            // 创建新消息，保持 streaming 状态
            let newMessage = ChatMessage(
                id: msgId,
                text: content,
                isFromUser: false,
                timestamp: Date(),
                isStreaming: true,  // 新消息以 streaming 状态创建
                thinkingContent: data.thinkingContent,
                toolCalls: toolCallInfos
            )
            displayMessages.append(newMessage)
            messageMap[msgId] = displayMessages.count - 1
            print("  ✅ Message added at index \(displayMessages.count - 1)")
        }
        
        // 如果是完整消息，检查是否有工具调用需要处理
        if data.messageType == .whole {
            print("  → Message is complete (WHOLE)")
            
            // 根据 toolCalls 决定是否需要显示action button
            if let toolCalls = data.toolCalls, !toolCalls.isEmpty {
                print("  → Has \(toolCalls.count) tool calls")
                for toolCall in toolCalls {
                    handleToolCallForUI(toolCall)
                }
            }
        }
    }
    
    private func handleToolCall(_ data: StreamMessageData) {
        // 处理工具调用状态
        guard let toolCalls = data.toolCalls else { return }
        
        for toolCall in toolCalls {
            print("🔧 Tool call: \(toolCall.toolCallName), status: \(String(describing: toolCall.toolCallStatus))")
            
            // 根据工具调用状态更新UI
            if let status = toolCall.toolCallStatus {
                switch status {
                case .started:
                    print("  ▶️ 开始执行")
                case .success:
                    print("  ✅ 执行成功")
                case .failed:
                    print("  ❌ 执行失败")
                }
            }
        }
    }
    
    private func handleToolCallForUI(_ toolCall: ToolCall) {
        // 根据工具调用类型显示相应的UI操作
        switch toolCall.toolCallName {
        case "authorize_health_data":
            // 显示健康数据授权按钮
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    self.showActionButton = true
                    self.actionButtonText = "授权健康数据"
                    self.actionButtonAction = .healthPermit
                }
            }
            
        case "noti_permit":
            // 显示通知权限授权按钮
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    self.showActionButton = true
                    self.actionButtonText = "开启通知"
                    self.actionButtonAction = .notiPermit
                }
            }
            
        case "finish_onboarding":
            // 显示完成引导按钮
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    self.showActionButton = true
                    self.actionButtonText = "开始使用"
                    self.actionButtonAction = .finishOnboarding
                }
            }
            
        default:
            break
        }
    }

    func handleActionButton() {
        guard let action = actionButtonAction else { return }

        switch action {
        case .finishOnboarding:
            onComplete()
            
        case .notiPermit:
            // TODO: 请求通知权限
            print("处理通知权限")
            showActionButton = false
            
        case .healthPermit:
            // TODO: 请求健康数据权限，然后调用continueOnboarding传入healthData
            print("处理健康数据权限")
            showActionButton = false
            
            // 示例：授权后继续
            Task {
                guard let onboardingId = onboardingId else { return }
                
                // TODO: 实际获取健康数据
                let healthData = "{\"authorized\": true}"
                
                isLoading = true
                do {
                    try await onboardingService.continueOnboarding(
                        onboardingId: onboardingId,
                        userInput: nil,
                        healthData: healthData,
                        eventHandler: { [weak self] event in
                            self?.handleStreamEvent(event)
                        }
                    )
                    isLoading = false
                } catch {
                    print("❌ 继续onboarding失败: \(error)")
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
