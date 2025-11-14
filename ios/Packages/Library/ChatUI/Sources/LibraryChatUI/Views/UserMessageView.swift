import SwiftUI

/// SwiftUI view for displaying user messages
public struct UserMessageView: View {
    let message: UserMessage
    let configuration: ChatConfiguration

    public init(message: UserMessage, configuration: ChatConfiguration = .default) {
        self.message = message
        self.configuration = configuration
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Spacer(minLength: MessageViewConstants.MESSAGE_SPACING)

            VStack(alignment: .trailing, spacing: 4) {
                Text(message.text)
                    .font(configuration.messageFont)
                    .foregroundColor(configuration.userMessageTextColor)
                    .padding(12)
                    .background(configuration.userMessageBackgroundColor)
                    .cornerRadius(16)
                    .textSelection(.enabled)

                if configuration.showTimestamp {
                    Text(timeString(from: message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            if let avatarURL = configuration.userAvatarURL {
                AsyncImage(url: avatarURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.blue)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 14))
                        )
                }
                .frame(width: 32, height: 32)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 14))
                    )
            }
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

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        UserMessageView(
            message: UserMessage(
                text: "Hello, how are you?",
                timestamp: Date()
            )
        )

        UserMessageView(
            message: UserMessage(
                text: "This is a longer message to test how the view handles multiple lines of text. It should wrap properly and maintain good readability.",
                timestamp: Date()
            )
        )
    }
    .padding()
}
