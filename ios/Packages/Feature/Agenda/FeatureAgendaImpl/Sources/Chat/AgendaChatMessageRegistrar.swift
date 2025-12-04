import Foundation
import SwiftUI
import LibraryChatUI
import FeatureAgendaApi
import ThemeKit

enum AgendaChatMessageRegistrar {
    static let agendaTaskType = "agenda_task_card"
    static let digestReportType = "digest_report"
    static let inquiryCardType = "inquiry_card"

    static func registerRenderers() {
        ChatMessageRendererRegistry.shared.register(type: agendaTaskType, renderer: renderAgendaTask)
        ChatMessageRendererRegistry.shared.register(type: digestReportType, renderer: renderDigestReport)
        ChatMessageRendererRegistry.shared.register(type: inquiryCardType, renderer: renderInquiryCard)
    }

    // MARK: - Agenda Task

    private static func renderAgendaTask(
        message: CustomRenderedMessage,
        _: ChatSessionControlling?
    ) -> AnyView {
        let task = decodeTask(from: message.data) ?? AgendaTask.sampleTasks.first ?? fallbackTask

        return AnyView(
            AgendaCardView(task: task)
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
        )
    }

    private static func decodeTask(from data: String?) -> AgendaTask? {
        guard let data, let jsonData = data.data(using: .utf8) else { return nil }
        guard let payload = try? JSONDecoder().decode(AgendaTaskCardPayload.self, from: jsonData) else {
            return nil
        }
        return payload.toAgendaTask()
    }

    private static var fallbackTask: AgendaTask {
        AgendaTask(
            emoji: "⚡️",
            title: "糖分阻断",
            description: "喝完立刻去快走 15 分钟，激活大腿肌肉抢在胰岛素飙升前吸走血糖。",
            countdown: "窗口期：20 分钟内完成",
            tags: [],
            reward: "+10 快乐",
            rewardDescription: "+10 快乐",
            status: .inProgress,
            accent: .emerald,
            timeWindow: "窗口期：20 分钟内完成",
            progress: 0.5,
            actionType: .play("立刻行动")
        )
    }

    // MARK: - Digest Report

    private static func renderDigestReport(
        message: CustomRenderedMessage,
        _: ChatSessionControlling?
    ) -> AnyView {
        let data = DigestReportData.from(jsonString: message.data ?? "") ?? .mock
        let digestMessage = DigestReportMessage(
            id: message.id,
            timestamp: message.timestamp,
            reportData: data
        )

        return AnyView(
            DigestReportMessageView(message: digestMessage)
        )
    }

    // MARK: - Inquiry Card

    private static func renderInquiryCard(
        message: CustomRenderedMessage,
        _: ChatSessionControlling?
    ) -> AnyView {
        let card = decodeInquiryCard(from: message.data) ?? InquiryCard.sampleCards.first ?? fallbackInquiryCard

        return AnyView(
            InquiryCardView(card: card) { actionId in
                print("Inquiry option selected: \(actionId)")
                // TODO: 处理用户选择的选项，例如发送消息给AI
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        )
    }

    private static func decodeInquiryCard(from data: String?) -> InquiryCard? {
        guard let data, let jsonData = data.data(using: .utf8) else { return nil }
        guard let payload = try? JSONDecoder().decode(InquiryCardPayload.self, from: jsonData) else {
            return nil
        }
        return payload.toInquiryCard()
    }

    private static var fallbackInquiryCard: InquiryCard {
        InquiryCard(
            emoji: "👀",
            question: "正在为你计算今晚的最佳入睡时间，在我运行模型前，有没有什么干扰项需要我手动录入的？",
            options: [
                InquiryOption(emoji: "🥗", text: "我很健康", actionId: "healthy"),
                InquiryOption(emoji: "🍺", text: "喝了酒", actionId: "alcohol"),
                InquiryOption(emoji: "🍔", text: "吃了夜宵", actionId: "late_snack")
            ]
        )
    }
}

private struct AgendaTaskCardPayload: Decodable {
    let emoji: String
    let title: String
    let description: String
    let reward: String
    let timeWindow: String
    let progress: Double
    let actionType: String
    let actionLabel: String

    func toAgendaTask() -> AgendaTask {
        let action: AgendaTask.TaskActionType
        switch actionType.lowercased() {
        case "photo":
            action = .photo(actionLabel)
        case "sync":
            action = .sync(actionLabel)
        case "play":
            action = .play(actionLabel)
        case "walk", "exercise":
            action = .walk(actionLabel)
        default:
            action = .check(actionLabel)
        }

        return AgendaTask(
            emoji: emoji,
            title: title,
            description: description,
            countdown: timeWindow,
            tags: [],
            reward: reward,
            rewardDescription: reward,
            status: .inProgress,
            accent: .emerald,
            timeWindow: timeWindow,
            progress: progress,
            actionType: action
        )
    }
}
