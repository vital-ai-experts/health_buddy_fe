import SwiftUI
import ThemeKit
import FeatureAgendaApi
import LibraryChatUI

/// 显示副本简报的聊天消息视图
struct DigestReportMessageView: View {
    let message: DigestReportMessage
    let configuration: ChatConfiguration

    init(
        message: DigestReportMessage,
        configuration: ChatConfiguration = .default
    ) {
        self.message = message
        self.configuration = configuration
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                DigestReportView(reportData: message.reportData)

                if configuration.showTimestamp {
                    Text(timeString(from: message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer(minLength: 30)
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

/// 本地副本简报消息模型（供渲染使用）
struct DigestReportMessage: Hashable, Identifiable {
    let id: String
    let timestamp: Date
    let reportData: DigestReportData?
}

// MARK: - Preview

#Preview {
    DigestReportMessageView(
        message: DigestReportMessage(
            id: UUID().uuidString,
            timestamp: Date(),
            reportData: .mock
        )
    )
    .padding()
}
