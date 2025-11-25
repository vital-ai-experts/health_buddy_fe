import Foundation

/// 在正式 ChatService 外包一层，用于处理 mock 消息
public final class ChatServiceWithMock: ChatService {
    private let realService: ChatService
    private let mockService: ChatService

    public init(
        realService: ChatService = ChatServiceImpl(),
        mockService: ChatService = MockChatService()
    ) {
        self.realService = realService
        self.mockService = mockService
    }

    public func sendMessage(
        userInput: String?,
        conversationId: String?,
        eventHandler: @escaping (ConversationStreamEvent) -> Void
    ) async throws {
        if let userInput, ChatMocking.hasMockPrefix(in: userInput) {
            try await mockService.sendMessage(
                userInput: userInput,
                conversationId: conversationId,
                eventHandler: eventHandler
            )
            return
        }

        try await realService.sendMessage(
            userInput: userInput,
            conversationId: conversationId,
            eventHandler: eventHandler
        )
    }

    public func resumeConversation(
        conversationId: String,
        lastDataId: String?,
        eventHandler: @escaping (ConversationStreamEvent) -> Void
    ) async throws {
        try await realService.resumeConversation(
            conversationId: conversationId,
            lastDataId: lastDataId,
            eventHandler: eventHandler
        )
    }

    public func getConversations(limit: Int?, offset: Int?) async throws -> [Conversation] {
        try await realService.getConversations(limit: limit, offset: offset)
    }

    public func getConversationHistory(id: String) async throws -> [Message] {
        try await realService.getConversationHistory(id: id)
    }

    public func deleteConversation(id: String) async throws {
        try await realService.deleteConversation(id: id)
    }
}

/// 处理 mock 消息的简单实现
public final class MockChatService: ChatService {
    public init() {}

    public func sendMessage(
        userInput: String?,
        conversationId: String?,
        eventHandler: @escaping (ConversationStreamEvent) -> Void
    ) async throws {
        let rawText = userInput ?? ""
        let cleanText = ChatMocking.stripMockPrefix(from: rawText)
        let cid = conversationId ?? UUID().uuidString
        let msgId = UUID().uuidString

        // 检查是否是图片上传消息
        if ChatMocking.isPhotoUploadMessage(cleanText) {
            // 返回任务完成消息
            let taskName = ChatMocking.extractTaskNameFromPhotoUpload(cleanText)
            let reply = generatePhotoVerificationReply(for: taskName)

            // 开始生成
            eventHandler(.streamMessage(StreamMessage(
                id: UUID().uuidString,
                data: StreamMessageData(
                    conversationId: cid,
                    msgId: msgId,
                    dataType: .agentStatus,
                    agentStatus: .generating
                )
            )))

            // 返回完成内容
            eventHandler(.streamMessage(StreamMessage(
                id: UUID().uuidString,
                data: StreamMessageData(
                    conversationId: cid,
                    msgId: msgId,
                    dataType: .agentMessage,
                    messageType: .whole,
                    content: reply
                )
            )))

            // 结束
            eventHandler(.streamMessage(StreamMessage(
                id: UUID().uuidString,
                data: StreamMessageData(
                    conversationId: cid,
                    msgId: msgId,
                    dataType: .agentStatus,
                    agentStatus: .finished
                )
            )))
            return
        }

        // 检查是否需要请求图片验证
        let photoRequest = checkPhotoVerificationRequired(for: cleanText)

        if let requestMessage = photoRequest {
            // 需要图片验证：先发送请求图片的消息
            eventHandler(.streamMessage(StreamMessage(
                id: UUID().uuidString,
                data: StreamMessageData(
                    conversationId: cid,
                    msgId: msgId,
                    dataType: .agentStatus,
                    agentStatus: .generating
                )
            )))

            eventHandler(.streamMessage(StreamMessage(
                id: UUID().uuidString,
                data: StreamMessageData(
                    conversationId: cid,
                    msgId: msgId,
                    dataType: .agentMessage,
                    messageType: .whole,
                    content: requestMessage
                )
            )))

            eventHandler(.streamMessage(StreamMessage(
                id: UUID().uuidString,
                data: StreamMessageData(
                    conversationId: cid,
                    msgId: msgId,
                    dataType: .agentStatus,
                    agentStatus: .finished
                )
            )))
            return
        }

        // 普通消息处理
        let reply = generateMockReply(for: cleanText)

        // 开始生成
        eventHandler(.streamMessage(StreamMessage(
            id: UUID().uuidString,
            data: StreamMessageData(
                conversationId: cid,
                msgId: msgId,
                dataType: .agentStatus,
                agentStatus: .generating
            )
        )))

        // 返回 mock 内容
        let content = reply.isEmpty ? (cleanText.isEmpty ? "收到" : "\(cleanText)收到") : reply
        eventHandler(.streamMessage(StreamMessage(
            id: UUID().uuidString,
            data: StreamMessageData(
                conversationId: cid,
                msgId: msgId,
                dataType: .agentMessage,
                messageType: .whole,
                content: content
            )
        )))

        // 结束
        eventHandler(.streamMessage(StreamMessage(
            id: UUID().uuidString,
            data: StreamMessageData(
                conversationId: cid,
                msgId: msgId,
                dataType: .agentStatus,
                agentStatus: .finished
            )
        )))
    }

    public func resumeConversation(
        conversationId: String,
        lastDataId: String?,
        eventHandler: @escaping (ConversationStreamEvent) -> Void
    ) async throws {
        // demo mock 不支持恢复，直接返回完成状态
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
        []
    }

    public func getConversationHistory(id: String) async throws -> [Message] {
        []
    }

    public func deleteConversation(id: String) async throws {}

    // MARK: - Photo Verification

    /// 需要图片验证的任务映射：任务关键词 -> (请求图片的消息, 验证后的回复)
    private let photoVerificationTasks: [(key: String, request: String, reply: String)] = [
        ("采集光子", "请拍摄一张此时的天空或窗外景色，确认光照强度。", "✅ 光信号已确认！ (XP +20)\n你的视交叉上核已启动「日间模式」，皮质醇正在释放，预计 15 分钟后你会感觉清醒。"),
        ("彩虹协议", "请拍摄你的餐盘，确认蔬果的色彩种类。", "🎉 协议生效！色彩识别通过。\n【战利品】：💎 钻石经验 +600\n植物多酚正在清除自由基，你刚刚扑灭了一场细胞层面的微小火灾。"),
        ("晨曦猎人", "请拍摄一张晨光照片，证明你捕获了第一缕阳光。", "🎉 捕获晨曦！\n【战利品】：💎 钻石经验 +800 (早起奖励加倍)\n你完成了生物钟顶级校准，这道金色光线是顶级皮质醇唤醒剂。今晚 22:00 你会自然困倦。")
    ]

    /// 检查任务是否需要图片验证
    private func checkPhotoVerificationRequired(for text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        for task in photoVerificationTasks {
            if trimmed.contains(task.key) {
                return task.request
            }
        }
        return nil
    }

    /// 获取图片验证后的回复
    private func generatePhotoVerificationReply(for taskName: String) -> String {
        for task in photoVerificationTasks {
            if taskName.contains(task.key) {
                return task.reply
            }
        }
        // 默认回复
        return "✅ 照片已确认！任务完成。 (XP +10)"
    }

    // MARK: - Reply Templates

    private func generateMockReply(for text: String) -> String {
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
}
