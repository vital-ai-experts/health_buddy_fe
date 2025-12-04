import Foundation
import FeatureChatApi
import LibraryBase
import LibraryChatUI

/// Mock Chat Service，必要时可回落到真实服务
public final class MockChatService: ChatService {
    private let realService: ChatService?

    public init(realService: ChatService? = nil) {
        self.realService = realService
    }

    public func sendMessage(
        userInput: String?,
        conversationId: String?,
        eventHandler: @escaping (ConversationStreamEvent) -> Void
    ) async throws {
        let rawText = userInput ?? ""
        let cleanText = ChatMocking.stripMockPrefix(from: rawText)
        let cid = conversationId ?? UUID().uuidString
        let msgId = UUID().uuidString

        // 奶茶彩蛋：返回任务卡片
        if cleanText.contains("奶茶") {
            try await respondWithMilkTea(
                conversationId: cid,
                statusMessageId: msgId,
                eventHandler: eventHandler
            )
            return
        }

        // 检查是否是图片上传消息
        if ChatMocking.isPhotoUploadMessage(cleanText) {
            let taskName = ChatMocking.extractTaskNameFromPhotoUpload(cleanText)
            let reply = generatePhotoVerificationReply(for: taskName)
            try await sendSimpleResponse(
                content: reply,
                conversationId: cid,
                msgId: msgId,
                eventHandler: eventHandler
            )
            return
        }

        // 检查是否需要请求图片验证
        if let requestMessage = checkPhotoVerificationRequired(for: cleanText) {
            try await sendSimpleResponse(
                content: requestMessage,
                conversationId: cid,
                msgId: msgId,
                eventHandler: eventHandler
            )
            return
        }

        // 普通消息处理，若无 mock 覆盖，则回退到真实服务
        if cleanText.isEmpty == false || ChatMocking.hasMockPrefix(in: rawText) {
            let reply = generateMockReply(for: cleanText)
            if !reply.isEmpty || ChatMocking.hasMockPrefix(in: rawText) {
                try await sendSimpleResponse(
                    content: reply.isEmpty ? (cleanText.isEmpty ? "收到" : "\(cleanText)收到") : reply,
                    conversationId: cid,
                    msgId: msgId,
                    eventHandler: eventHandler
                )
                return
            }
        }

        // 回退到真实服务
        if let realService {
            try await realService.sendMessage(
                userInput: userInput,
                conversationId: conversationId,
                eventHandler: eventHandler
            )
            return
        }

        // 没有真实服务就返回简单应答
        try await sendSimpleResponse(
            content: cleanText.isEmpty ? "收到" : "\(cleanText)收到",
            conversationId: cid,
            msgId: msgId,
            eventHandler: eventHandler
        )
    }

    public func resumeConversation(
        conversationId: String,
        lastDataId: String?,
        eventHandler: @escaping (ConversationStreamEvent) -> Void
    ) async throws {
        if let realService {
            try await realService.resumeConversation(
                conversationId: conversationId,
                lastDataId: lastDataId,
                eventHandler: eventHandler
            )
            return
        }

        eventHandler(.streamMessage(StreamMessage(
            id: UUID().uuidString,
            data: StreamMessageData(
                conversationId: conversationId,
                msgId: UUID().uuidString,
                dataType: .agentStatus,
                agentStatus: .finished
            )
        )))
    }

    public func getConversations(limit: Int?, offset: Int?) async throws -> [Conversation] {
        if let realService {
            return try await realService.getConversations(limit: limit, offset: offset)
        }
        return []
    }

    public func getConversationHistory(id: String, chatSession: ChatSessionControlling?) async throws -> [Message] {
        var messages: [Message] = []

        if let realService {
            messages = try await realService.getConversationHistory(id: id, chatSession: chatSession)
        }

        if await !hasDigest(in: messages, chatSession: chatSession) {
            messages.append(createMockDigestReportMessage(conversationId: id))
        }

        return messages
    }

    public func deleteConversation(id: String) async throws {
        if let realService {
            try await realService.deleteConversation(id: id)
        }
    }

    private func hasDigest(in messages: [Message], chatSession: ChatSessionControlling?) async -> Bool {
        if messages.contains(where: { $0.specialMessageType == "digest_report" }) {
            return true
        }

        let existing = await MainActor.run {
            chatSession?.currentMessages() ?? []
        }
        return existing.contains { $0.specialMessageTypeRaw == "digest_report" }
    }

    private func createMockDigestReportMessage(conversationId: String) -> Message {
        let reportData: [String: Any] = [
            "currentDay": 12,
            "totalDays": 30,
            "progressStatus": "超前",
            "targetValue": 65.0,
            "dataPoints": (1...12).map { day in
                [
                    "id": UUID().uuidString,
                    "day": day,
                    "value": Double(40 + day * 3)
                ]
            },
            "message": "得益于你连续 5 天完成了\"数字日落\"任务，你的入睡潜伏期缩短了 40%。"
        ]

        let jsonData = try? JSONSerialization.data(withJSONObject: reportData, options: [])
        let jsonString = jsonData.flatMap { String(data: $0, encoding: .utf8) } ?? ""
        let currentTimestamp = String(Int(Date().timeIntervalSince1970 * 1000))

        return Message(
            id: UUID().uuidString,
            conversationId: conversationId,
            role: .assistant,
            content: "",
            createdAt: currentTimestamp,
            thinkingContent: nil,
            toolCalls: nil,
            specialMessageType: "digest_report",
            specialMessageData: jsonString
        )
    }
}

// MARK: - Helpers

private extension MockChatService {
    func sendSimpleResponse(
        content: String,
        conversationId: String,
        msgId: String,
        eventHandler: @escaping (ConversationStreamEvent) -> Void
    ) async throws {
        // 开始生成
        eventHandler(.streamMessage(StreamMessage(
            id: UUID().uuidString,
            data: StreamMessageData(
                conversationId: conversationId,
                msgId: msgId,
                dataType: .agentStatus,
                agentStatus: .generating
            )
        )))

        let messageEvents = makeTextMessageEvents(
            conversationId: conversationId,
            msgId: msgId,
            content: content
        )
        messageEvents.forEach { event in
            eventHandler(.streamMessage(event))
        }

        eventHandler(.streamMessage(StreamMessage(
            id: UUID().uuidString,
            data: StreamMessageData(
                conversationId: conversationId,
                msgId: msgId,
                dataType: .agentStatus,
                agentStatus: .finished
            )
        )))
    }

    func makeTextMessageEvents(
        conversationId: String,
        msgId: String,
        content: String
    ) -> [StreamMessage] {
        guard !content.isEmpty else {
            return [
                StreamMessage(
                    id: UUID().uuidString,
                    data: StreamMessageData(
                        conversationId: conversationId,
                        msgId: msgId,
                        dataType: .agentMessage,
                        messageType: .whole,
                        content: content
                    )
                )
            ]
        }

        let chunkSize = 10
        let totalCount = content.count
        var boundaries: [Int] = []
        var current = chunkSize

        while current < totalCount {
            boundaries.append(current)
            current += chunkSize
        }
        boundaries.append(totalCount)

        return boundaries.enumerated().map { index, boundary in
            let messageType: MessageType = (index == boundaries.count - 1) ? .whole : .chunk
            let chunkContent = String(content.prefix(boundary))

            return StreamMessage(
                id: UUID().uuidString,
                data: StreamMessageData(
                    conversationId: conversationId,
                    msgId: msgId,
                    dataType: .agentMessage,
                    messageType: messageType,
                    content: chunkContent
                )
            )
        }
    }

    /// 需要图片验证的任务映射：任务关键词 -> (请求图片的消息, 验证后的回复)
    var photoVerificationTasks: [(key: String, request: String, reply: String)] {
        [
            ("采集光子", "请拍摄一张此时的天空或窗外景色，确认光照强度。", "✅ 光信号已确认！ (XP +20)\n你的视交叉上核已启动「日间模式」，皮质醇正在释放，预计 15 分钟后你会感觉清醒。"),
            ("彩虹协议", "请拍摄你的餐盘，确认蔬果的色彩种类。", "🎉 协议生效！色彩识别通过。\n【战利品】：💎 钻石经验 +600\n植物多酚正在清除自由基，你刚刚扑灭了一场细胞层面的微小火灾。"),
            ("晨曦猎人", "请拍摄一张晨光照片，证明你捕获了第一缕阳光。", "🎉 捕获晨曦！\n【战利品】：💎 钻石经验 +800 (早起奖励加倍)\n你完成了生物钟顶级校准，这道金色光线是顶级皮质醇唤醒剂。今晚 22:00 你会自然困倦。")
        ]
    }

    func checkPhotoVerificationRequired(for text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        for task in photoVerificationTasks {
            if trimmed.contains(task.key) {
                return task.request
            }
        }
        return nil
    }

    func generatePhotoVerificationReply(for taskName: String) -> String {
        for task in photoVerificationTasks {
            if taskName.contains(task.key) {
                return task.reply
            }
        }
        return "✅ 照片已确认！任务完成。 (XP +10)"
    }

    func generateMockReply(for text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }

        // 副本入口
        if trimmed.contains("加入副本") {
            return "太棒了，已开始副本挑战，现在去完成第一个任务吧。"
        }

        // 任务对应回复（不需要图片验证的任务）
        let mappings: [(key: String, reply: String)] = [
            ("填充冷却液", "🌊 注入完成。 (净水值 +10)\n血液粘稠度正在降低，氧气输送效率提升 15%。你的大脑引擎已预热。"),
            ("最后一杯", "🛡️ 明智的防守。 (睡眠护盾 +50)\n你避免了 6 小时后的腺苷受体堵塞。今晚你的深度睡眠将得到保护。"),
            ("燃烧葡萄糖", "✅ 同步完成：检测到 1200 步。 (能量 +30)\n漂亮的拦截！那碗碳水带来的昏睡感已被物理代谢掉，下午 2 点你可以保持清醒了。"),
            ("系统强制冷却", "❄️ 冷却成功。 (冷静值 +40)\n检测到心率已下降。你的前额叶皮层（理智脑）已重新接管控制权。"),
            ("全景扫描", "🦅 视觉锁定解除。 (鹰眼 Buff +1)\n这种「散焦」状态刚刚欺骗了你的杏仁核，让大脑认为你处于开阔地带，焦虑感已降低。"),
            ("模式切换", "🏠 后台进程已清理。 (家庭和谐度 +50)\n现在的你是「生活模式」。享受你的晚餐吧。"),
            ("调暗灯光", "✅ 环境合格。 (睡意值 +20)\n这种暖色调暗光是松果体的最爱。你的天然安眠药（褪黑素）正在开始批量生产。"),
            ("切断连接", "🏆 意志力胜利！ (意志力 +100)\n你刚刚战胜了算法推荐。作为奖励，我会为你播放一段助眠波，晚安。"),
            ("强制关机", "🛡️ 补救成功。\n虽然入睡晚，但昨晚的练习让你进入了高质量的浅睡。今天依然能保持战斗力。"),
            ("引擎重铸", "🎉 BOSS 击杀成功！\n【战利品】：💎 钻石经验 +500\n你迫使心脏泵血能力达到极限，细胞正在疯狂制造新的线粒体。今晚你会睡得像块石头。"),
            ("静默领域", "🎉 传奇胜利！\n【战利品】：💎 钻石经验 +800\n你的大脑完成了一次多巴胺排毒。你是自己大脑的主人。")
        ]

        for mapping in mappings {
            if trimmed.contains(mapping.key) {
                return mapping.reply
            }
        }

        // 特殊分支：咖啡窗口未喝
        if trimmed.contains("咖啡") && (trimmed.contains("没喝") || trimmed.contains("不喝") || trimmed.contains("跳过")) {
            return "🛡️ 明智的防守。 (睡眠护盾 +50)\n你避免了 6 小时后的腺苷受体堵塞。今晚你的深度睡眠将得到保护。"
        }

        return ""
    }

    // MARK: - 奶茶任务彩蛋

    func respondWithMilkTea(
        conversationId: String,
        statusMessageId: String,
        eventHandler: @escaping (ConversationStreamEvent) -> Void
    ) async throws {
        let taskMessageId = UUID().uuidString
        let cardMessageId = UUID().uuidString

        // 开始生成
        eventHandler(.streamMessage(StreamMessage(
            id: UUID().uuidString,
            data: StreamMessageData(
                conversationId: conversationId,
                msgId: statusMessageId,
                dataType: .agentStatus,
                agentStatus: .generating
            )
        )))

        try? await Task.sleep(nanoseconds: 500_000_000)

        let chunks: [String] = [
            "啊，我就知道。你的意志力这就“欠费”了？😉",
            """

不过，看在你今天被工作折磨得够惨的份上，这杯“毒药”我准了。在我的算法里，心情崩溃比发胖更危险。
""",
            """

我会给你增加一个任务，帮你把这杯奶茶的糖分快速代谢掉：
"""
        ]

        for (index, chunk) in chunks.enumerated() {
            try? await Task.sleep(nanoseconds: UInt64(700_000_000 + index * 200_000_000))

            let messageType: MessageType = (index == chunks.count - 1) ? .whole : .chunk

            eventHandler(.streamMessage(StreamMessage(
                id: UUID().uuidString,
                data: StreamMessageData(
                    conversationId: conversationId,
                    msgId: taskMessageId,
                    dataType: .agentMessage,
                    messageType: messageType,
                    content: chunks.prefix(index + 1).joined()
                )
            )))
        }

        try? await Task.sleep(nanoseconds: 600_000_000)

        eventHandler(.streamMessage(StreamMessage(
            id: UUID().uuidString,
            data: StreamMessageData(
                conversationId: conversationId,
                msgId: cardMessageId,
                dataType: .agentMessage,
                messageType: .whole,
                content: "",
                specialMessageType: "agenda_task_card",
                specialMessageData: makeMilkTeaTaskPayload()
            )
        )))

        try? await Task.sleep(nanoseconds: 400_000_000)
        eventHandler(.streamMessage(StreamMessage(
            id: UUID().uuidString,
            data: StreamMessageData(
                conversationId: conversationId,
                msgId: statusMessageId,
                dataType: .agentStatus,
                agentStatus: .finished
            )
        )))
    }

    func makeMilkTeaTaskPayload() -> String {
        struct AgendaTaskCardPayload: Codable {
            let emoji: String
            let title: String
            let description: String
            let reward: String
            let timeWindow: String
            let progress: Double
            let actionType: String
            let actionLabel: String
        }

        let payload = AgendaTaskCardPayload(
            emoji: "⚡️",
            title: "糖分阻断",
            description: "喝完立刻去快走 15 分钟。激活大腿肌肉作为海绵，赶在胰岛素飙升前，把血液里的游离糖分直接吃掉。",
            reward: "+10 快乐",
            timeWindow: "窗口期：血糖峰值到达前（剩余 20 分钟）",
            progress: 0.99,
            actionType: "walk",
            actionLabel: "压制胰岛素"
        )

        guard let data = try? JSONEncoder().encode(payload),
              let jsonString = String(data: data, encoding: .utf8) else {
            return ""
        }

        return jsonString
    }
}
