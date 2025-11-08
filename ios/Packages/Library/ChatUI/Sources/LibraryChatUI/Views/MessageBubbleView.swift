import SwiftUI

/// 带有内联光标的流式文本视图
struct StreamingTextWithCursor: View {
    let text: String
    let font: Font
    let textColor: Color

    var body: some View {
        // 光标使用实心圆点，保持固定颜色，不闪烁
        (Text(text) + Text(" ●"))
            .font(font)
            .foregroundColor(textColor)
    }
}

/// 消息气泡视图
struct MessageBubbleView: View {
    let message: ChatMessage
    let configuration: ChatConfiguration
    let showAvatar: Bool // 是否显示头像

    init(message: ChatMessage, configuration: ChatConfiguration, showAvatar: Bool = true) {
        self.message = message
        self.configuration = configuration
        self.showAvatar = showAvatar
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.isFromUser {
                Spacer(minLength: 60)
            } else if configuration.showAvatar {
                if showAvatar {
                    avatarView
                } else {
                    // 占位空间，保持对齐
                    Color.clear
                        .frame(width: 32, height: 32)
                        .padding(.top, 6)
                }
            }

            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 4) {
                // 消息气泡
                messageContentView
                    .padding(configuration.messagePadding)
                    .background(message.isFromUser ? configuration.userMessageColor : configuration.botMessageColor)
                    .cornerRadius(configuration.cornerRadius)

                // 时间戳
                if configuration.showTimestamp && !message.isStreaming {
                    Text(formatTime(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: 280, alignment: message.isFromUser ? .trailing : .leading)

            if !message.isFromUser {
                Spacer(minLength: 60)
            } else if configuration.showAvatar {
                if showAvatar {
                    avatarView
                } else {
                    // 占位空间，保持对齐
                    Color.clear
                        .frame(width: 32, height: 32)
                        .padding(.top, 6)
                }
            }
        }
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private var messageContentView: some View {
        if message.isStreaming {
            // 流式消息：使用 ZStack + GeometryReader 来定位光标
            StreamingTextWithCursor(
                text: message.text,
                font: configuration.messageFont,
                textColor: message.isFromUser ? configuration.userTextColor : configuration.botTextColor
            )
        } else {
            // 普通消息
            Text(message.text)
                .font(configuration.messageFont)
                .foregroundColor(message.isFromUser ? configuration.userTextColor : configuration.botTextColor)
        }
    }

    @ViewBuilder
    private var avatarView: some View {
        if let avatarURL = message.isFromUser ? configuration.userAvatarURL : configuration.botAvatarURL {
            AsyncImage(url: avatarURL) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                defaultAvatarPlaceholder
            }
            .frame(width: 32, height: 32)
            .clipShape(Circle())
            .padding(.top, 6)
        } else {
            defaultAvatarPlaceholder
                .padding(.top, 6)
        }
    }

    private var defaultAvatarPlaceholder: some View {
        ZStack {
            Circle()
                .fill(Color(.systemGray4))
            Image(systemName: message.isFromUser ? "person.fill" : "brain.head.profile")
                .font(.system(size: 16))
                .foregroundColor(.white)
        }
        .frame(width: 32, height: 32)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    VStack(spacing: 12) {
        MessageBubbleView(
            message: ChatMessage(text: "Hello! How can I help you?", isFromUser: false),
            configuration: .default,
            showAvatar: true
        )

        MessageBubbleView(
            message: ChatMessage(text: "Sure, let me explain...", isFromUser: false),
            configuration: .default,
            showAvatar: false  // 连续消息，隐藏头像
        )

        MessageBubbleView(
            message: ChatMessage(text: "I need help with something", isFromUser: true),
            configuration: .default,
            showAvatar: true
        )

        MessageBubbleView(
            message: ChatMessage(text: "Typing...", isFromUser: false, isStreaming: true),
            configuration: .default,
            showAvatar: true
        )
    }
    .padding()
}
