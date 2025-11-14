import SwiftUI

/// SwiftUI view for displaying system loading indicator (before any content)
public struct SystemLoadingView: View {
    let loading: SystemLoading
    let configuration: ChatConfiguration

    public init(loading: SystemLoading, configuration: ChatConfiguration = .default) {
        self.loading = loading
        self.configuration = configuration
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar
            if let avatarURL = configuration.botAvatarURL {
                AsyncImage(url: avatarURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.green)
                        .overlay(
                            Image(systemName: "brain.head.profile")
                                .foregroundColor(.white)
                                .font(.system(size: 14))
                        )
                }
                .frame(width: 32, height: 32)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.green)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(.white)
                            .font(.system(size: 14))
                    )
            }

            // Typing indicator
            TypingIndicatorView()
                .padding(16)
                .background(configuration.botMessageBackgroundColor)
                .cornerRadius(16)

            Spacer(minLength: MessageViewConstants.MESSAGE_SPACING)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        SystemLoadingView(loading: SystemLoading())
    }
    .padding()
}
