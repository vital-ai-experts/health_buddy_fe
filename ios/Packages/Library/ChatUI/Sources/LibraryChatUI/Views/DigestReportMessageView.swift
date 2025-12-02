import SwiftUI
import ThemeKit

/// SwiftUI view for displaying digest report messages
public struct DigestReportMessageView: View {
    let message: DigestReportMessage
    let configuration: ChatConfiguration

    public init(
        message: DigestReportMessage,
        configuration: ChatConfiguration = .default
    ) {
        self.message = message
        self.configuration = configuration
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Content
            VStack(alignment: .leading, spacing: 8) {
                // Digest Report Card
                DigestReportView(reportData: message.reportData)

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

// MARK: - Preview

#Preview {
    DigestReportMessageView(
        message: DigestReportMessage(
            timestamp: Date(),
            reportData: .mock
        )
    )
    .padding()
}
