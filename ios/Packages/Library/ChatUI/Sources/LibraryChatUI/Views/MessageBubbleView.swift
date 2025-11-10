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

            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 6) {
                // Thinking content (仅AI消息显示)
                if !message.isFromUser, let thinkingContent = message.thinkingContent, !thinkingContent.isEmpty {
                    thinkingDisclosureGroup(content: thinkingContent)
                }
                
                // 消息气泡
                if !message.text.isEmpty {
                    messageContentView
                        .padding(configuration.messagePadding)
                        .background(message.isFromUser ? configuration.userMessageColor : configuration.botMessageColor)
                        .cornerRadius(configuration.cornerRadius)
                }
                
                // Tool calls (仅AI消息显示)
                if !message.isFromUser, let toolCalls = message.toolCalls, !toolCalls.isEmpty {
                    toolCallsDisclosureGroup(toolCalls: toolCalls)
                }

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

    // Thinking content disclosure group
    @ViewBuilder
    private func thinkingDisclosureGroup(content: String) -> some View {
        DisclosureGroup {
            Text(content)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(6)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "brain")
                    .font(.caption)
                Text("思考过程")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(.purple)
        }
        .padding(8)
        .background(Color.purple.opacity(0.1))
        .cornerRadius(8)
    }
    
    // Tool calls disclosure group
    @ViewBuilder
    private func toolCallsDisclosureGroup(toolCalls: [ToolCallInfo]) -> some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(toolCalls.enumerated()), id: \.element.id) { index, toolCall in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("工具 \(index + 1): \(toolCall.name)")
                                .font(.caption)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            if let status = toolCall.status {
                                Text(status)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(statusColor(for: status))
                                    .cornerRadius(4)
                            }
                        }
                        
                        if let args = toolCall.args, !args.isEmpty {
                            Text("参数: \(args)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        if let result = toolCall.result, !result.isEmpty {
                            Text("结果: \(result)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(6)
                }
            }
            .padding(.top, 4)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "wrench.and.screwdriver")
                    .font(.caption)
                Text("工具调用 (\(toolCalls.count))")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(.blue)
        }
        .padding(8)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func statusColor(for status: String) -> Color {
        switch status {
        case "成功": return Color.green.opacity(0.2)
        case "失败": return Color.red.opacity(0.2)
        default: return Color.orange.opacity(0.2)
        }
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
