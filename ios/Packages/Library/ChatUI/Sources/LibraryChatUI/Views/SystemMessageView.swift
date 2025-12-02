import SwiftUI
import ThemeKit

/// SwiftUI view for displaying completed system/AI messages
public struct SystemMessageView: View {
    let message: SystemMessage
    let configuration: ChatConfiguration
    let onHealthProfileConfirm: (() -> Void)?
    let onHealthProfileReject: (() -> Void)?

    public init(
        message: SystemMessage,
        configuration: ChatConfiguration = .default,
        onHealthProfileConfirm: (() -> Void)? = nil,
        onHealthProfileReject: (() -> Void)? = nil
    ) {
        self.message = message
        self.configuration = configuration
        self.onHealthProfileConfirm = onHealthProfileConfirm
        self.onHealthProfileReject = onHealthProfileReject
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Content
            VStack(alignment: .leading, spacing: 8) {
                // Thinking content
                if let thinking = message.thinkingContent, !thinking.isEmpty {
                    ThinkingContentView(thinking: thinking)
                }

                // Tool calls
                if !message.toolCalls.isEmpty {
                    ToolCallsView(toolCalls: message.toolCalls)
                }

                // Main message content
                if !message.text.isEmpty {
                    MessageContentView(
                        text: message.text,
                        isStreaming: message.isStreaming,
                        configuration: configuration
                    )
                }

                // Special message (Health Profile)
                if message.specialMessageType == .userHealthProfile {
                    HealthProfileView(
                        profileData: message.specialMessageData,
                        isStreaming: message.isStreaming,
                        onConfirm: onHealthProfileConfirm,
                        onReject: onHealthProfileReject
                    )
                }

                // Timestamp
                if configuration.showTimestamp {
                    Text(timeString(from: message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer(minLength: MessageViewConstants.MESSAGE_SPACING)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Subviews

/// Bot avatar view
private struct BotAvatarView: View {
    let configuration: ChatConfiguration

    var body: some View {
        if let avatarURL = configuration.botAvatarURL {
            AsyncImage(url: avatarURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                defaultAvatar
            }
            .frame(width: 32, height: 32)
            .clipShape(Circle())
        } else {
            defaultAvatar
        }
    }

    private var defaultAvatar: some View {
        Circle()
            .fill(Color.green)
            .frame(width: 32, height: 32)
            .overlay(
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.white)
                    .font(.system(size: 14))
            )
    }
}

/// Thinking content disclosure group
private struct ThinkingContentView: View {
    let thinking: String

    var body: some View {
        DisclosureGroup {
            Text(thinking)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
        } label: {
            Label("Think", systemImage: "brain")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.bottom, 4)
    }
}

/// Tool calls list view
private struct ToolCallsView: View {
    let toolCalls: [ToolCallInfo]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(toolCalls) { toolCall in
                ToolCallItemView(toolCall: toolCall)
            }
        }
    }
}

/// Single tool call item
private struct ToolCallItemView: View {
    let toolCall: ToolCallInfo

    var body: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 8) {
                // Parameters
                if let args = toolCall.args, !args.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Parameters:")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .fontWeight(.semibold)
                        Text(args)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Result
                if let result = toolCall.result, !result.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Result:")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .fontWeight(.semibold)
                        Text(result)
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(6)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "wrench.and.screwdriver")
                    .font(.caption2)
                Text(toolCall.name)
                    .font(.caption)
                    .fontWeight(.medium)
                ToolCallStatusBadge(status: toolCall.status)
                Spacer()
            }
        }
    }
}

/// Tool call status badge
private struct ToolCallStatusBadge: View {
    let status: String?

    var body: some View {
        let (text, color) = statusInfo

        Text(text)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(4)
    }

    private var statusInfo: (String, Color) {
        switch status?.lowercased() {
        case "success":
            return ("成功", .green)
        case "failure", "error":
            return ("失败", .red)
        case "pending", "running":
            return ("进行中", .orange)
        default:
            return ("未知", .gray)
        }
    }
}

/// Main message content view
private struct MessageContentView: View {
    let text: String
    let isStreaming: Bool
    let configuration: ChatConfiguration

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if isStreaming {
                MarkdownTextWithCursor(
                    text: text,
                    font: configuration.messageFont,
                    textColor: configuration.botMessageTextColor
                )
                .textSelection(.enabled)
            } else {
                MarkdownText(
                    text: text,
                    font: configuration.messageFont,
                    textColor: configuration.botMessageTextColor
                )
                .textSelection(.enabled)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(configuration.botMessageBackgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.Palette.surfaceElevatedBorder, lineWidth: 1)
        )
        .shadow(color: Color.Palette.textPrimary.opacity(0.08), radius: 4, x: 0, y: 2)
    }
}

/// Health profile special message view
private struct HealthProfileView: View {
    let profileData: String?
    let isStreaming: Bool
    let onConfirm: (() -> Void)?
    let onReject: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Profile data content
            if let profileData = profileData, !profileData.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    if isStreaming {
                        MarkdownTextWithCursor(
                            text: profileData,
                            font: .body,
                            textColor: Color.orange.opacity(0.9)
                        )
                    } else {
                        MarkdownText(
                            text: profileData,
                            font: .body,
                            textColor: Color.orange.opacity(0.9)
                        )
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
            }

            // Confirmation buttons
            if !isStreaming {
                HStack(spacing: 12) {
                    Button {
                        onConfirm?()
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Good")
                        }
                        .font(.subheadline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }

                    Button {
                        onReject?()
                    } label: {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                            Text("Modify")
                        }
                        .font(.subheadline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        SystemMessageView(
            message: SystemMessage(
                text: "Hello! How can I help you today?",
                timestamp: Date(),
                thinkingContent: "First, I need to check the user's recent activity data. Then, I'll compare it with their historical patterns to identify any significant changes.",
            )
        )

        SystemMessageView(
            message: SystemMessage(
                text: "I've analyzed your health data and found some interesting patterns.",
                timestamp: Date(),
                thinkingContent: "First, I need to check the user's recent activity data. Then, I'll compare it with their historical patterns to identify any significant changes.",
                toolCalls: [
                    ToolCallInfo(name: "fetch_health_data", status: "success"),
                    ToolCallInfo(name: "analyze_patterns", status: "success")
                ]
            )
        )

        SystemMessageView(
            message: SystemMessage(
                text: "Please confirm your health profile information.",
                timestamp: Date(),
                thinkingContent: "First, I need to check the user's recent activity data. Then, I'll compare it with their historical patterns to identify any significant changes.",
                toolCalls: [
                    ToolCallInfo(name: "analyze_patterns", status: "success")
                ],
                specialMessageType: .userHealthProfile,
                specialMessageData: "# 报告"
            ),
            onHealthProfileConfirm: { print("Confirmed") },
            onHealthProfileReject: { print("Rejected") }
        )
    }
    .padding()
}
