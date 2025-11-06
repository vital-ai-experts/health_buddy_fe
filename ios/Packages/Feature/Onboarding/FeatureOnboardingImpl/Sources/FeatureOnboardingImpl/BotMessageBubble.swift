import SwiftUI

/// Bot 消息气泡视图
struct BotMessageBubble: View {
    let message: MessageItem
    let showAvatar: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // AI Avatar (只在需要时显示)
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
            
            // Message bubble
            Text(message.text)
                .font(.body)
                .padding(16)
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(16)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

