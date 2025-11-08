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
        GeometryReader { geometry in
            ZStack {
                SimpleChatView(
                    messages: $viewModel.displayMessages,
                    inputText: $viewModel.inputText,
                    isLoading: viewModel.isLoading,
                    configuration: ChatConfiguration(autoFocusAfterBotMessage: true),
                    bottomPadding: 200,  // Onboarding 需要底部空间让消息滚动到舒适位置
                    onSendMessage: { text in
                        viewModel.sendMessage(text)
                    }
                )

                // 顶部渐变遮罩 - 让滚动到顶部的内容完全遮挡
                VStack(spacing: 0) {
                    let statusBarHeight = geometry.safeAreaInsets.top
                    let gradientHeight = statusBarHeight + 20  // 状态栏高度 + 20pt 渐变区域

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
                    .frame(height: gradientHeight)
                    .allowsHitTesting(false)
                    .ignoresSafeArea(edges: .top) // 延伸到状态栏区域

                    Spacer()
                }

                // Action button overlay (when needed)
                VStack {
                    Spacer()

                    if viewModel.showActionButton {
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
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(uiColor: .systemBackground).opacity(0),
                                    Color(uiColor: .systemBackground)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 100)
                            .offset(y: -60)
                        )
                    }
                }
            }
            .background(Color(uiColor: .systemBackground))
        }
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

    private var sessionId: String?
    private var actionButtonAction: BotMessageAction?
    private let onboardingService: OnboardingService
    private let onComplete: () -> Void

    init(onboardingService: OnboardingService, onComplete: @escaping () -> Void) {
        self.onboardingService = onboardingService
        self.onComplete = onComplete
    }

    func initializeOnboarding() async {
        isLoading = true

        do {
            try await onboardingService.sendMessage(
                sessionId: nil,
                userMessage: UserMessage(type: .initialize),
                eventHandler: { [weak self] event in
                    self?.handleStreamEvent(event)
                }
            )

            isLoading = false
        } catch {
            print("❌ 初始化失败: \(error)")
            isLoading = false
        }
    }

    func sendMessage(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
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

        // 2. 清空输入框
        inputText = ""

        // 3. 延迟显示 loading，让用户消息先渲染
        Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3秒
            self.isLoading = true

            do {
                try await onboardingService.sendMessage(
                    sessionId: sessionId,
                    userMessage: UserMessage(type: .textReply, text: text),
                    eventHandler: { [weak self] event in
                        self?.handleStreamEvent(event)
                    }
                )

                self.isLoading = false
            } catch {
                print("❌ 发送消息失败: \(error)")
                self.isLoading = false
            }
        }
    }

    private var currentStreamingMessageId: String?

    private func handleStreamEvent(_ event: OnboardingStreamEvent) {
        Task { @MainActor in
            switch event {
            case .sessionStart(let sessionId):
                self.sessionId = sessionId

            case .messageStart(let messageId):
                // 创建一个新的流式消息占位符
                currentStreamingMessageId = messageId
                let streamingMessage = ChatMessage(
                    id: messageId,
                    text: "",
                    isFromUser: false,
                    timestamp: Date(),
                    isStreaming: true
                )
                displayMessages.append(streamingMessage)

            case .contentDelta(let content):
                // 更新流式消息的内容
                guard let messageId = currentStreamingMessageId,
                      let index = displayMessages.firstIndex(where: { $0.id == messageId }) else {
                    return
                }

                var updatedMessage = displayMessages[index]
                updatedMessage = ChatMessage(
                    id: updatedMessage.id,
                    text: updatedMessage.text + content,
                    isFromUser: updatedMessage.isFromUser,
                    timestamp: updatedMessage.timestamp,
                    isStreaming: true
                )
                displayMessages[index] = updatedMessage

            case .messageEnd(let action):
                // 标记消息为完成状态
                guard let messageId = currentStreamingMessageId,
                      let index = displayMessages.firstIndex(where: { $0.id == messageId }) else {
                    return
                }

                var finalMessage = displayMessages[index]
                finalMessage = ChatMessage(
                    id: finalMessage.id,
                    text: finalMessage.text,
                    isFromUser: finalMessage.isFromUser,
                    timestamp: finalMessage.timestamp,
                    isStreaming: false
                )
                displayMessages[index] = finalMessage
                currentStreamingMessageId = nil

                // 如果消息携带 action，显示 action button
                if let actionInfo = action {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation {
                            self.showActionButton = true
                            self.actionButtonText = actionInfo.title
                            self.actionButtonAction = actionInfo.type
                        }
                    }
                }

            case .error(let message):
                print("❌ Stream error: \(message)")
            }
        }
    }

    func handleActionButton() {
        guard let action = actionButtonAction else { return }

        switch action {
        case .finishOnboarding:
            onComplete()
        case .notiPermit, .healthPermit:
            // Handle permission requests
            print("处理权限: \(action.rawValue)")
            // For now, just hide the button and continue
            showActionButton = false
        }
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
