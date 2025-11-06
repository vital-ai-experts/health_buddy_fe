import SwiftUI
import DomainOnboarding

/// Bot 输入中气泡视图（加载中或显示第一条待显示消息）
struct BotTypingBubble: View {
    let isLoading: Bool
    let pendingMessages: [BotMessage]
    let showAvatar: Bool
    
    @State private var animationPhase = 0
    @State private var timer: Timer?
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // AI Avatar (根据需要显示或隐藏)
            if showAvatar {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(.white)
                            .font(.system(size: 20))
                    }
            } else {
                // 占位空间，保持对齐
                Color.clear
                    .frame(width: 40, height: 40)
            }
            
            // 内容区域（根据状态显示加载动画或第一条消息）
            Group {
                if isLoading {
                    // Loading dots
                    HStack(spacing: 8) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(Color.gray)
                                .frame(width: 8, height: 8)
                                .opacity(animationPhase == index ? 1.0 : 0.3)
                        }
                    }
                    .transition(.opacity)
                } else if let firstMessage = pendingMessages.first {
                    // 第一条待显示的消息
                    Text(firstMessage.text ?? "")
                        .font(.body)
                        .transition(.opacity)
                } else {
                    // 没有内容（不应该出现）
                    EmptyView()
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(uiColor: .secondarySystemBackground))
            .cornerRadius(16)
            .animation(.easeInOut(duration: 0.3), value: isLoading)
            .animation(.easeInOut(duration: 0.3), value: pendingMessages.count)
            
            Spacer()
        }
        .onAppear {
            startAnimation()
        }
        .onDisappear {
            stopAnimation()
        }
    }
    
    private func startAnimation() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
            if isLoading {
                animationPhase = (animationPhase + 1) % 3
            }
        }
        RunLoop.current.add(timer!, forMode: .common)
    }
    
    private func stopAnimation() {
        timer?.invalidate()
        timer = nil
    }
}

