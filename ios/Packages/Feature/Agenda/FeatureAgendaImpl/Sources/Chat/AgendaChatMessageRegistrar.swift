import Foundation
import SwiftUI
import LibraryChatUI

enum AgendaChatMessageRegistrar {
    static let agendaTaskType = "agenda_task_card"

    static func registerRenderers() {
        ChatMessageRendererRegistry.shared.register(type: agendaTaskType) { message in
            let task = decodeTask(from: message.data) ?? AgendaTask.sampleTasks.first ?? fallbackTask

            return AnyView(
                AgendaCardView(task: task)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)
            )
        }
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
