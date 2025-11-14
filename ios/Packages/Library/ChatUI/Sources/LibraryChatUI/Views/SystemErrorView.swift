import SwiftUI

/// SwiftUI view for displaying system error with retry button
public struct SystemErrorView: View {
    let error: SystemError
    let configuration: ChatConfiguration
    let onRetry: () -> Void

    public init(
        error: SystemError,
        configuration: ChatConfiguration = .default,
        onRetry: @escaping () -> Void
    ) {
        self.error = error
        self.configuration = configuration
        self.onRetry = onRetry
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
                        .fill(Color.red.opacity(0.2))
                        .overlay(
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                                .font(.system(size: 14))
                        )
                }
                .frame(width: 32, height: 32)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.red.opacity(0.2))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 14))
                    )
            }

            // Error content
            VStack(alignment: .leading, spacing: 12) {
                Text("Oops network fails")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)

                if !error.errorMessage.isEmpty {
                    Text(error.errorMessage)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                // Retry button
                Button(action: onRetry) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 13, weight: .medium))
                        Text("Retry")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .cornerRadius(8)
                }
            }
            .padding(12)
            .background(Color.red.opacity(0.1))
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
        SystemErrorView(
            error: SystemError(
                errorMessage: "Failed to connect to server"
            ),
            onRetry: {
                print("Retry tapped")
            }
        )

        SystemErrorView(
            error: SystemError(
                errorMessage: ""
            ),
            onRetry: {
                print("Retry tapped")
            }
        )
    }
    .padding()
}
