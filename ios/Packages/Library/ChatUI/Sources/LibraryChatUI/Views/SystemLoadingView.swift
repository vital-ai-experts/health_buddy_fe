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
