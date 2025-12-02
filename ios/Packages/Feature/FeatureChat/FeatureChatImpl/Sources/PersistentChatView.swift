import SwiftUI
import SwiftData
import DomainChat
import LibraryServiceLoader
import LibraryChatUI
import LibraryBase
import ResourceKit
import FeatureAgendaApi
import ThemeKit

/// 单一长期对话视图，对话历史保存在本地
struct PersistentChatView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var router: RouteManager
    @StateObject private var viewModel: PersistentChatViewModel

    init(defaultSelectedGoalId: String? = nil) {
        let chatService = ServiceManager.shared.resolve(ChatService.self)
        _viewModel = StateObject(wrappedValue: PersistentChatViewModel(
            chatService: chatService,
            goalManager: ServiceManager.shared.resolveOptional(AgendaGoalManaging.self),
            defaultSelectedGoalId: defaultSelectedGoalId
        ))
    }

    var body: some View {
        SimpleChatView(
            messages: $viewModel.displayMessages,
            inputText: $viewModel.inputText,
            isLoading: viewModel.isSending,
            tags: viewModel.chatTags,
            selectedTagId: $viewModel.selectedGoalId,
            onSendMessage: { text in
                Task {
                    await viewModel.sendMessage(text)
                }
            },
            onLoadMoreHistory: {
                Task {
                    await viewModel.loadMoreMessages()
                }
            }
        )
        .alert("清除历史记录", isPresented: $viewModel.showClearHistoryAlert) {
            Button("取消", role: .cancel) {}
            Button("清除", role: .destructive) {
                Task {
                    await viewModel.clearHistory()
                }
            }
        } message: {
            Text("确定要清除所有对话历史吗？此操作不可撤销。")
        }
        .task {
            await viewModel.initialize(modelContext: modelContext)
        }
        .onAppear {
            Task {
                await viewModel.syncWithServer()
            }
            Task {
                await handlePendingChatMessageIfNeeded()
            }
        }
        .onChange(of: router.pendingChatMessage) { _, _ in
            Task {
                await handlePendingChatMessageIfNeeded()
            }
        }
    }

    @MainActor
    private func handlePendingChatMessageIfNeeded() async {
        guard let message = router.pendingChatMessage else { return }
        await viewModel.sendMessage(message)
        router.clearPendingChatMessage(message)
    }
}

@MainActor
final class PersistentChatViewModel: ObservableObject {
    @Published var displayMessages: [ChatMessage] = []
    @Published var isSending = false
    @Published var errorMessage: String?
    @Published var conversationId: String? // 长期持有的对话ID
    @Published var inputText = ""
    @Published var showClearHistoryAlert = false
    @Published var isLoadingMore = false  // 正在加载更多消息
    @Published var selectedGoalId: String? {
        didSet {
            goalManager?.defaultSelectedGoalId = selectedGoalId
        }
    }
    @Published var availableGoals: [AgendaGoal] = []

    private let chatService: ChatService
    private let goalManager: AgendaGoalManaging?
    private var storageService: ChatStorageService?
    private var hasInitialized = false
    private var lastDataId: String?  // 用于断线重连
    private var messageMap: [String: Int] = [:]  // msgId -> displayMessages index
    private var savedMessageIds: Set<String> = []  // 已保存到本地的消息ID
    private var oldestLoadedMessageDate: Date?  // 已加载的最旧消息的时间（用于游标分页）
    private var hasMoreMessagesToLoad = true  // 是否还有更多历史消息可以加载
    private var conversationUpdatedAt: Date?  // 对话的最后更新时间
    private var lastUserMessageText: String = ""  // 记录最近的用户消息文本（用于提取任务名称）

    private let initialLoadLimit = 10  // 初次加载消息数量
    private let loadMoreLimit = 20  // 每次加载更多的消息数量
    private let conversationTimeoutHours: TimeInterval = 4 * 3600  // 4小时超时

    init(
        chatService: ChatService,
        goalManager: AgendaGoalManaging? = nil,
        defaultSelectedGoalId: String? = nil
    ) {
        self.chatService = chatService
        self.goalManager = goalManager

        let initialGoalId = Self.resolveInitialGoalId(
            providedGoalId: defaultSelectedGoalId,
            manager: goalManager
        )
        self.availableGoals = goalManager?.goals ?? []
        self.selectedGoalId = initialGoalId

        if let initialGoalId {
            self.goalManager?.defaultSelectedGoalId = initialGoalId
        }
    }

    var hasMoreMessages: Bool {
        hasMoreMessagesToLoad
    }

    func initialize(modelContext: ModelContext) async {
        guard !hasInitialized else { return }
        hasInitialized = true

        storageService = ChatStorageService(modelContext: modelContext)

        // 从本地加载历史消息
        await loadLocalHistory()
        
        // 如果没有任何消息，插入一条 mock 的 digest report 卡片
        if displayMessages.isEmpty {
            await insertMockDigestIfNeeded()
        }

        // 检查是否需要恢复streaming
        // TODO 先不恢复
//        await checkAndResumeIfNeeded()
    }

    /// 从本地数据库加载历史消息（分页加载，初次只加载最近10条）
    private func loadLocalHistory() async {
        guard let storageService = storageService else { return }

        do {
            // 加载最近的10条消息（使用游标分页）
            let localMessages = try storageService.fetchRecentMessages(
                limit: initialLoadLimit,
                beforeDate: nil  // nil 表示从最新的消息开始
            )

            Log.i("📦 从数据库加载了 \(localMessages.count) 条消息", category: "Chat")
            for (index, msg) in localMessages.enumerated() {
                Log.i("  [\(index)] \(msg.isFromUser ? "用户" : "系统"): \(msg.content.prefix(20))... (id: \(msg.id.prefix(8))..., time: \(msg.createdAt))", category: "Chat")
            }

            displayMessages = localMessages.map { localMsg in
                ChatMessage(
                    id: localMsg.id,
                    text: localMsg.content,
                    isFromUser: localMsg.isFromUser,
                    timestamp: localMsg.createdAt,
                    isStreaming: false,
                    goalId: localMsg.goalId,
                    goalTitle: localMsg.goalTitle
                )
            }

            // 确保按时间正序排列（最新的在最后）
            displayMessages.sort { $0.timestamp < $1.timestamp }

            Log.i("📱 映射后显示 \(displayMessages.count) 条消息", category: "Chat")
            let userCount = displayMessages.filter { $0.isFromUser }.count
            let systemCount = displayMessages.filter { !$0.isFromUser }.count
            Log.i("   用户消息: \(userCount) 条, 系统消息: \(systemCount) 条", category: "Chat")

            // 记录最旧消息的时间作为下次加载的游标
            if let oldestMessage = localMessages.first {
                oldestLoadedMessageDate = oldestMessage.createdAt
            }

            // 如果加载的消息数量少于限制，说明没有更多了
            hasMoreMessagesToLoad = localMessages.count >= initialLoadLimit

            // 如果有消息，尝试恢复conversationId
            if let lastMsg = localMessages.last, let convId = lastMsg.conversationId {
                conversationId = convId
            }

            savedMessageIds = Set(localMessages.map { $0.id })
            rebuildMessageMap()

            Log.i("✅ 加载了 \(localMessages.count) 条本地消息", category: "Chat")
            if hasMoreMessages {
                Log.i("📚 还有更早的消息可以加载", category: "Chat")
            }
        } catch {
            Log.e("❌ 加载本地消息失败: \(error.localizedDescription)", category: "Chat")
            errorMessage = "加载历史消息失败"
        }
    }

    var chatTags: [ChatTag] {
        availableGoals.map { ChatTag(id: $0.id, title: $0.title) }
    }

    private static func resolveInitialGoalId(
        providedGoalId: String?,
        manager: AgendaGoalManaging?
    ) -> String? {
        let goals = manager?.goals ?? []

        if let providedGoalId, goals.contains(where: { $0.id == providedGoalId }) {
            return providedGoalId
        }

        if let defaultId = manager?.defaultSelectedGoalId,
           goals.contains(where: { $0.id == defaultId }) {
            return defaultId
        }

        return nil
    }

    /// 加载更多历史消息（用户往上滑动时调用）
    func loadMoreMessages() async {
        // TODO 先不加载更多
        hasMoreMessagesToLoad = false
        return

        guard !isLoadingMore else {
            Log.i("⏳ 正在加载中，跳过重复请求", category: "Chat")
            return
        }
        guard hasMoreMessages else {
            Log.i("📭 没有更多消息了", category: "Chat")
            return
        }
        guard let storageService = storageService else { return }
        guard let oldestDate = oldestLoadedMessageDate else {
            Log.i("📭 没有游标，无法加载更多", category: "Chat")
            return
        }

        isLoadingMore = true
        Log.i("📥 开始加载更多消息，游标时间: \(oldestDate)", category: "Chat")

        do {
            // 使用游标加载更旧的消息
            let olderMessages = try storageService.fetchRecentMessages(
                limit: loadMoreLimit,
                beforeDate: oldestDate
            )

            if olderMessages.isEmpty {
                Log.i("📭 没有更多消息了", category: "Chat")
                hasMoreMessagesToLoad = false
            } else {
                // 将更早的消息插入到列表前面
                let newChatMessages = olderMessages.map { localMsg in
                    ChatMessage(
                        id: localMsg.id,
                        text: localMsg.content,
                        isFromUser: localMsg.isFromUser,
                        timestamp: localMsg.createdAt,
                        isStreaming: false
                    )
                }

                displayMessages.insert(contentsOf: newChatMessages, at: 0)

                // 确保按时间正序排列（最新的在最后）
                displayMessages.sort { $0.timestamp < $1.timestamp }

                // 更新游标为新加载的最旧消息的时间
                if let newOldestMessage = olderMessages.first {
                    oldestLoadedMessageDate = newOldestMessage.createdAt
                }

                // 如果加载的消息数量少于限制，说明没有更多了
                if olderMessages.count < loadMoreLimit {
                    hasMoreMessagesToLoad = false
                }

                // 更新savedMessageIds
                savedMessageIds.formUnion(olderMessages.map { $0.id })

                // 重建messageMap（索引变了）
                rebuildMessageMap()

                Log.i("✅ 加载了 \(olderMessages.count) 条更早的消息", category: "Chat")
            }
        } catch {
            Log.e("❌ 加载更多消息失败: \(error.localizedDescription)", category: "Chat")
            errorMessage = "加载更多消息失败"
        }

        isLoadingMore = false
    }

    /// 从服务端同步消息
    func syncWithServer() async {
        // 1. 首先检查是否有最新的conversation
        do {
            let conversations = try await chatService.getConversations(limit: 1, offset: nil)
            // 按createdAt降序排列，确保获取最新的对话
            guard let latestConversation = conversations.sorted(by: { $0.createdAt > $1.createdAt }).first else {
                Log.i("📝 [PersistentChat] 服务端没有对话记录", category: "Chat")
                // 即使没有对话记录，也继续执行，可能会插入 mock digest
                await insertMockDigestIfNeeded()
                return
            }

            // 如果本地没有conversationId，直接使用服务端最新的
            if conversationId == nil {
                conversationId = latestConversation.id
                // 注意：conversationUpdatedAt 会在同步消息后，根据最新消息的时间来设置
                Log.i("📝 [PersistentChat] 使用最新的conversation: \(latestConversation.id)", category: "Chat")
            }
            // 如果本地有conversationId，保持使用本地的（除非明确需要切换）
            else {
                Log.i("📝 [PersistentChat] 保持本地对话: \(conversationId!)", category: "Chat")
            }
        } catch {
            Log.w("⚠️ [PersistentChat] 获取最新conversation失败: \(error)", category: "Chat")
            // 不阻塞，继续执行
        }

        // 2. 如果有conversationId，同步消息
        guard let conversationId = conversationId else {
            Log.i("📝 [PersistentChat] 没有conversationId，跳过同步", category: "Chat")
            // 即使没有同步，也尝试插入 mock digest
            await insertMockDigestIfNeeded()
            return
        }

        do {
            let allServerMessages = try await chatService.getConversationHistory(id: conversationId)

            Log.i("📡 服务端返回 \(allServerMessages.count) 条消息", category: "Chat")
            let serverUserCount = allServerMessages.filter { $0.role == .user }.count
            let serverAssistantCount = allServerMessages.filter { $0.role == .assistant }.count
            Log.i("   用户消息: \(serverUserCount) 条, 系统消息: \(serverAssistantCount) 条", category: "Chat")

            // 只保留系统消息(assistant messages)，过滤掉用户消息
            // 因为从服务端拉到的用户消息没有msg_id，所以我们不要了
            // 注意：保留有 specialMessageType 的消息，即使 content 为空（如 digest_report）
            let serverMessages = allServerMessages.filter { message in
                guard message.role == .assistant else { return false }
                // 保留有内容的消息，或者有特殊类型的消息（如 digest_report 卡片）
                return !message.content.isEmpty || message.specialMessageType != nil
            }

            Log.i("📥 过滤后保留 \(serverMessages.count) 条系统消息", category: "Chat")

            // 创建服务端消息ID->Message的映射
            let serverMessageMap = Dictionary(uniqueKeysWithValues: serverMessages.map { ($0.id, $0) })

            // 从displayMessages中移除与服务端重复的系统消息
            // 只有当服务端的content和本地的content不相同时，才移除本地消息(优先使用服务端消息)
            let removedCount = displayMessages.filter { message in
                guard !message.isFromUser, let serverMessage = serverMessageMap[message.id] else { return false }
                return message.text != serverMessage.content
            }.count

            displayMessages.removeAll { message in
                guard !message.isFromUser, let serverMessage = serverMessageMap[message.id] else { return false }
                return message.text != serverMessage.content
            }

            // 创建更新后的本地消息ID集合
            let localMessageIds = Set(displayMessages.map { $0.id })

            // 找出服务端有但本地没有的消息(包括刚才删除的重复消息)
            let missingMessages = serverMessages.filter { !localMessageIds.contains($0.id) }

            if !missingMessages.isEmpty || removedCount > 0 {
                if removedCount > 0 {
                    Log.i("📥 [PersistentChat] 删除本地重复的系统消息: \(removedCount)条", category: "Chat")
                }
                if !missingMessages.isEmpty {
                    Log.i("📥 [PersistentChat] 添加服务端缺失的系统消息: \(missingMessages.count)条", category: "Chat")
                }

                // 添加所有缺失的消息
                for message in missingMessages {
                    // 解析特殊消息类型
                    let specialType: SpecialMessageType? = {
                        guard let typeString = message.specialMessageType else { return nil }
                        return SpecialMessageType(rawValue: typeString)
                    }()

                    let chatMessage = ChatMessage(
                        id: message.id,
                        text: message.content,
                        isFromUser: false,  // 只有系统消息
                        timestamp: parseDate(message.createdAt),
                        isStreaming: false,
                        thinkingContent: message.thinkingContent,
                        toolCalls: message.toolCalls?.map { ToolCallInfo(
                            id: $0.toolCallId,
                            name: $0.toolCallName,
                            args: $0.toolCallArgs,
                            status: $0.toolCallStatus?.description,
                            result: $0.toolCallResult
                        )},
                        specialMessageType: specialType,
                        specialMessageData: message.specialMessageData,
                        specialMessageTypeRaw: message.specialMessageType
                    )

                    displayMessages.append(chatMessage)

                    // 保存到本地数据库
                    await saveMessageToLocal(
                        id: message.id,
                        content: message.content,
                        isFromUser: false,
                        createdAt: chatMessage.timestamp
                    )
                }

                // 按时间戳排序所有消息(时间正序，最新的在最后)
                displayMessages.sort { $0.timestamp < $1.timestamp }

                // 重建messageMap(因为索引变了)
                rebuildMessageMap()

                // 更新游标：取最旧消息的时间
                if let oldestMessage = displayMessages.first {
                    oldestLoadedMessageDate = oldestMessage.timestamp
                }

                let finalUserCount = displayMessages.filter { $0.isFromUser }.count
                let finalSystemCount = displayMessages.filter { !$0.isFromUser }.count
                Log.i("✅ [PersistentChat] 消息同步完成，当前显示: \(displayMessages.count)条", category: "Chat")
                Log.i("   用户消息: \(finalUserCount) 条, 系统消息: \(finalSystemCount) 条", category: "Chat")
            }
        } catch {
            Log.w("⚠️ [PersistentChat] 同步消息失败: \(error)", category: "Chat")
            // 不阻塞，继续执行
        }

        // 3. 同步完成后，更新 conversationUpdatedAt 为最新消息的时间
        if let latestMessage = displayMessages.last {
            conversationUpdatedAt = latestMessage.timestamp
            Log.i("📝 [PersistentChat] 更新对话时间为最新消息时间: \(latestMessage.timestamp)", category: "Chat")
        }
        
        // 4. 无论同步成功还是失败，都尝试插入 mock digest（如果还没有的话）
        await insertMockDigestIfNeeded()
    }

    /// 检查是否需要恢复streaming
    private func checkAndResumeIfNeeded() async {
        guard let conversationId = conversationId else { return }
        guard !displayMessages.isEmpty else { return }

        // 检查最后一条消息
        let lastMessage = displayMessages.last!

        // 情况1: 最后一条是用户消息，说明还没有收到assistant回复
        if lastMessage.isFromUser {
            Log.i("⏸️ [PersistentChat] 最后一条是用户消息，尝试恢复...", category: "Chat")
            await resumeConversation()
            return
        }

        // 情况2: 最后一条assistant消息可能未完成
        // 检查消息是否为空（可能被中断）
        if lastMessage.isStreaming {
            Log.w("⚠️ [PersistentChat] 最后一条assistant消息为空，尝试恢复...", category: "Chat")
            await resumeConversation()
            return
        }

        Log.i("✅ [PersistentChat] 消息完整，无需恢复", category: "Chat")
    }

    /// 恢复对话streaming
    private func resumeConversation() async {
        guard let conversationId = conversationId else { return }

        Log.i("🔄 [PersistentChat] 恢复对话: \(conversationId)", category: "Chat")
        isSending = true

        do {
            try await chatService.resumeConversation(
                conversationId: conversationId,
                lastDataId: lastDataId
            ) { [weak self] event in
                Task { @MainActor in
                    self?.handleStreamEvent(event)
                }
            }
        } catch {
            Log.e("❌ [PersistentChat] 恢复失败: \(error)", category: "Chat")
            // Resume失败不算严重错误
        }

        isSending = false
    }

    /// 将毫秒时间戳字符串转换为 Date
    /// - Parameter timestampString: 毫秒时间戳字符串，如 "1763302800241"
    /// - Returns: Date 对象
    private func parseDate(_ timestampString: String) -> Date {
        guard let timestampMs = Double(timestampString) else {
            Log.e("❌ 无法解析时间戳: \(timestampString)", category: "Chat")
            return Date()
        }
        // 毫秒转秒
        let timestampSec = timestampMs / 1000.0
        return Date(timeIntervalSince1970: timestampSec)
    }

    /// 发送消息
    func sendMessage(_ text: String) async {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        let displayText = ChatMocking.stripMockPrefix(from: trimmedText)
        guard !displayText.isEmpty else { return }

        // 记录最近的用户消息文本（用于提取任务名称）
        lastUserMessageText = displayText

        // 1. 检查对话是否超时（超过4小时）
        var effectiveConversationId = conversationId
        if let conversationId = conversationId, let updatedAt = conversationUpdatedAt {
            let timeSinceLastUpdate = Date().timeIntervalSince(updatedAt)
            if timeSinceLastUpdate > conversationTimeoutHours {
                Log.i("⏰ [PersistentChat] 对话超时 (\(Int(timeSinceLastUpdate/3600))小时)，开始新对话", category: "Chat")
                effectiveConversationId = nil
                self.conversationId = nil
                self.conversationUpdatedAt = nil
            } else {
                Log.i("✅ [PersistentChat] 使用现有对话: \(conversationId), 距上次更新: \(Int(timeSinceLastUpdate/60))分钟", category: "Chat")
            }
        }

        // 2. 创建用户消息
        let userMessageId = UUID().uuidString
        let goalTitle = goalTitle(for: selectedGoalId)
        let userMessage = ChatMessage(
            id: userMessageId,
            text: displayText,
            isFromUser: true,
            timestamp: Date(),
            isStreaming: false,
            goalId: selectedGoalId,
            goalTitle: goalTitle
        )
        displayMessages.append(userMessage)

        // 3. 保存用户消息到本地
        await saveMessageToLocal(
            id: userMessageId,
            content: displayText,
            isFromUser: true,
            createdAt: userMessage.timestamp,
            goalId: selectedGoalId,
            goalTitle: goalTitle
        )

        // 4. 发送到服务器
        isSending = true
        errorMessage = nil

        do {
            try await chatService.sendMessage(
                userInput: trimmedText,
                conversationId: effectiveConversationId
            ) { [weak self] event in
                Task { @MainActor in
                    self?.handleStreamEvent(event)
                }
            }
        } catch {
            errorMessage = "发送消息失败: \(error.localizedDescription)"
        }

        isSending = false
    }

    /// 处理流式响应事件
    private func handleStreamEvent(_ event: ConversationStreamEvent) {
        switch event {
        case .streamMessage(let streamMessage):
            Log.i("📩 [PersistentChat] Received stream message", category: "Chat")

            // 记录lastDataId用于断线重连
            lastDataId = streamMessage.id

            let data = streamMessage.data

            // 保存conversationId并更新时间戳
            if let cid = data.conversationId {
                if conversationId == nil || conversationId != cid {
                    conversationId = cid
                    conversationUpdatedAt = Date()
                    Log.i("✅ 对话ID: \(cid), 更新时间: \(Date())", category: "Chat")
                } else {
                    // 即使是同一个对话，也更新时间戳
                    conversationUpdatedAt = Date()
                }
            }

            // 根据dataType分派处理
            switch data.dataType {
            case .agentStatus:
                handleAgentStatus(data.agentStatus)

            case .agentMessage:
                handleAgentMessage(data)

            case .agentToolCall:
                handleToolCall(data)
            }

        case .error(let message):
            Log.e("❌ [PersistentChat] Stream error: \(message)", category: "Chat")
            errorMessage = message
            isSending = false
        }
    }

    /// 处理Agent状态
    private func handleAgentStatus(_ status: AgentStatus?) {
        guard let status = status else { return }

        switch status {
        case .generating:
            Log.i("🤖 Agent 生成中...", category: "Chat")

        case .finished:
            Log.i("✅ Agent 完成", category: "Chat")
            finalizeStreamingMessages(shouldPersist: true)
            isSending = false

            // 检查最后一条系统消息是否在请求上传图片
            checkAndAutoSendPhotoIfNeeded()

        case .error:
            Log.e("❌ Agent 错误", category: "Chat")
            markStreamingMessageAsError("Agent error")
            isSending = false

        case .stopped:
            Log.i("⏸️ Agent 停止", category: "Chat")
            finalizeStreamingMessages(shouldPersist: true)
            isSending = false
        }
    }

    /// 检查是否需要自动发送图片，如果需要则自动处理
    private func checkAndAutoSendPhotoIfNeeded() {
        // 获取最后一条系统消息
        guard let lastMessage = displayMessages.last, !lastMessage.isFromUser else { return }

        // 检查是否在请求上传图片
        guard ChatMocking.isRequestingPhotoUpload(in: lastMessage.text) else { return }

        Log.i("📷 检测到请求上传图片的消息，自动发送图片...", category: "Chat")

        // 从最近的用户消息中提取任务名称
        let taskName = ChatMocking.extractTaskNameFromRequest(lastMessage.text, userMessageText: lastUserMessageText)

        // 延迟一小段时间后自动发送图片
        Task { @MainActor in
            // 等待一小段时间，让用户看到请求消息
            try? await Task.sleep(nanoseconds: 800_000_000)  // 0.8秒

            await sendPhotoMessage(taskName: taskName)
        }
    }

    /// 发送带图片的消息
    private func sendPhotoMessage(taskName: String) async {
        // 1. 根据任务类型选择不同的模拟图片
        let mockImage = getMockImageForTask(taskName)

        // 2. 创建用户消息（带图片）
        let userMessageId = UUID().uuidString
        let userMessage = ChatMessage(
            id: userMessageId,
            text: "",  // 图片消息不需要文本
            isFromUser: true,
            timestamp: Date(),
            isStreaming: false,
            images: [mockImage],
            goalId: selectedGoalId,
            goalTitle: goalTitle(for: selectedGoalId)
        )
        displayMessages.append(userMessage)

        // 3. 保存用户消息到本地（图片消息用特殊标记）
        await saveMessageToLocal(
            id: userMessageId,
            content: "[图片]",
            isFromUser: true,
            createdAt: userMessage.timestamp,
            goalId: selectedGoalId,
            goalTitle: goalTitle(for: selectedGoalId)
        )

        // 4. 发送图片上传消息到服务器（mock）
        isSending = true
        errorMessage = nil

        let photoUploadMessage = ChatMocking.makePhotoUploadMessage(for: taskName)

        do {
            try await chatService.sendMessage(
                userInput: photoUploadMessage,
                conversationId: conversationId
            ) { [weak self] event in
                Task { @MainActor in
                    self?.handleStreamEvent(event)
                }
            }
        } catch {
            errorMessage = "发送图片失败: \(error.localizedDescription)"
        }

        isSending = false
    }

    /// 根据任务类型获取对应的模拟图片
    private func getMockImageForTask(_ taskName: String) -> MessageImage {
        // 所有任务统一使用本地资源图片
        return MessageImage(
            imageName: "MockPhoto",
            bundle: ResourceManager.bundle
        )
    }

    private func goalTitle(for goalId: String?) -> String? {
        guard let goalId else { return nil }

        if let goal = availableGoals.first(where: { $0.id == goalId }) {
            return goal.title
        }

        return goalManager?.goal(withId: goalId)?.title
    }

    /// 处理Agent消息
    private func handleAgentMessage(_ data: StreamMessageData) {
        let msgId = data.msgId

        Log.i("💭 [PersistentChat] handleAgentMessage", category: "Chat")
        Log.i("  msgId: \(msgId)", category: "Chat")
        Log.i("  messageType: \(String(describing: data.messageType))", category: "Chat")

        // 检查是否有内容
        let hasContent = data.content != nil && !data.content!.isEmpty
        let hasThinking = data.thinkingContent != nil && !data.thinkingContent!.isEmpty
        let hasToolCalls = data.toolCalls != nil && !data.toolCalls!.isEmpty
        let hasSpecial = data.specialMessageType != nil || data.specialMessageData != nil

        guard hasContent || hasThinking || hasToolCalls || hasSpecial else {
            return
        }

        let content = data.content ?? ""
        let specialType = data.specialMessageType.flatMap { SpecialMessageType(rawValue: $0) }

        // 转换工具调用
        let toolCallInfos: [ToolCallInfo]? = data.toolCalls?.map { toolCall in
            ToolCallInfo(
                id: toolCall.toolCallId,
                name: toolCall.toolCallName,
                args: toolCall.toolCallArgs,
                status: toolCall.toolCallStatus?.description,
                result: toolCall.toolCallResult
            )
        }

        // 查找或创建消息
        if let index = messageMap[msgId] {
            Log.i("  → Updating existing message at index \(index)", category: "Chat")
            let existingMessage = displayMessages[index]

            let message = ChatMessage(
                id: existingMessage.id,
                text: content,
                isFromUser: existingMessage.isFromUser,
                timestamp: existingMessage.timestamp,
                isStreaming: true,
                thinkingContent: data.thinkingContent ?? existingMessage.thinkingContent,
                toolCalls: toolCallInfos ?? existingMessage.toolCalls,
                specialMessageType: specialType ?? existingMessage.specialMessageType,
                specialMessageData: data.specialMessageData ?? existingMessage.specialMessageData,
                specialMessageTypeRaw: data.specialMessageType ?? existingMessage.specialMessageTypeRaw
            )
            displayMessages[index] = message

        } else {
            Log.i("  → Creating new message", category: "Chat")

            // 新消息到来时，将之前所有消息设为非streaming并保存
            finalizeStreamingMessages(shouldPersist: true)

            // 创建新消息
            let newMessage = ChatMessage(
                id: msgId,
                text: content,
                isFromUser: false,
                timestamp: Date(),
                isStreaming: true,
                thinkingContent: data.thinkingContent,
                toolCalls: toolCallInfos,
                specialMessageType: specialType,
                specialMessageData: data.specialMessageData,
                specialMessageTypeRaw: data.specialMessageType
            )
            displayMessages.append(newMessage)
            messageMap[msgId] = displayMessages.count - 1
        }
    }

    /// 处理工具调用
    private func handleToolCall(_ data: StreamMessageData) {
        Log.i("🔧 [PersistentChat] handleToolCall", category: "Chat")
        Log.i("  msgId: \(data.msgId)", category: "Chat")
        Log.i("  toolCalls: \(data.toolCalls?.count ?? 0)", category: "Chat")
    }

    private func finalizeStreamingMessages(shouldPersist: Bool) {
        for index in displayMessages.indices {
            guard displayMessages[index].isStreaming else { continue }

            let message = displayMessages[index]
            let finalMessage = ChatMessage(
                id: message.id,
                text: message.text,
                isFromUser: message.isFromUser,
                timestamp: message.timestamp,
                isStreaming: false,
                thinkingContent: message.thinkingContent,
                toolCalls: message.toolCalls,
                specialMessageType: message.specialMessageType,
                specialMessageData: message.specialMessageData,
                specialMessageTypeRaw: message.specialMessageTypeRaw
            )
            displayMessages[index] = finalMessage

            if shouldPersist {
                persistAssistantMessageIfNeeded(finalMessage)
            }
        }
    }

    private func markStreamingMessageAsError(_ message: String) {
        if let index = displayMessages.firstIndex(where: { $0.isStreaming }) {
            let failedMessage = displayMessages[index]
            displayMessages[index] = ChatMessage(
                id: failedMessage.id,
                text: failedMessage.text,
                isFromUser: false,
                timestamp: failedMessage.timestamp,
                isStreaming: false,
                specialMessageType: failedMessage.specialMessageType,
                specialMessageData: failedMessage.specialMessageData,
                specialMessageTypeRaw: failedMessage.specialMessageTypeRaw,
                hasError: true,
                errorMessage: message
            )
        }
    }

    private func persistAssistantMessageIfNeeded(_ message: ChatMessage) {
        guard !message.isFromUser else { return }
        guard !savedMessageIds.contains(message.id) else { return }
        savedMessageIds.insert(message.id)

        Task { @MainActor [weak self] in
            guard let self = self else { return }
            await self.saveMessageToLocal(
                id: message.id,
                content: message.text,
                isFromUser: false,
                createdAt: message.timestamp,
                conversationId: self.conversationId
            )
        }
    }

    /// 保存消息到本地数据库
    private func saveMessageToLocal(
        id: String,
        content: String,
        isFromUser: Bool,
        createdAt: Date,
        conversationId: String? = nil,
        goalId: String? = nil,
        goalTitle: String? = nil
    ) async {
        guard let storageService = storageService else { return }

        let localMessage = LocalChatMessage(
            id: id,
            content: content,
            isFromUser: isFromUser,
            createdAt: createdAt,
            conversationId: conversationId ?? self.conversationId,
            goalId: goalId,
            goalTitle: goalTitle
        )

        do {
            try storageService.saveMessage(localMessage)
            savedMessageIds.insert(id)
            Log.i("✅ 消息已保存到本地: \(content.prefix(20))...", category: "Chat")
        } catch {
            Log.e("❌ 保存消息失败: \(error.localizedDescription)", category: "Chat")
        }
    }

    /// 清除所有历史记录
    func clearHistory() async {
        guard let storageService = storageService else { return }

        do {
            try storageService.deleteAllMessages()
            displayMessages.removeAll()
            conversationId = nil
            conversationUpdatedAt = nil
            messageMap.removeAll()
            savedMessageIds.removeAll()
            oldestLoadedMessageDate = nil
            hasMoreMessagesToLoad = true
            Log.i("✅ 历史记录已清除", category: "Chat")
        } catch {
            Log.e("❌ 清除历史记录失败: \(error.localizedDescription)", category: "Chat")
            errorMessage = "清除历史记录失败"
        }
    }
    
    /// 插入一条 mock 的副本简报消息（用于演示），如果还没有的话
    private func insertMockDigestIfNeeded() async {
        // 检查是否已经有 digest_report 消息
        let hasDigestReport = displayMessages.contains { message in
            message.specialMessageType == .digestReport
        }
        
        if hasDigestReport {
            Log.i("ℹ️ 已存在 digest report，跳过插入", category: "Chat")
            return
        }
        
        // 使用统一的 mock 数据
        let jsonString = DigestReportData.mock.toJSONString() ?? ""
        
        let digestMessage = ChatMessage(
            id: UUID().uuidString,
            text: "",  // 副本简报卡片不需要文本内容
            isFromUser: false,
            timestamp: Date(),
            isStreaming: false,
            specialMessageType: .digestReport,
            specialMessageData: jsonString
        )
        
        displayMessages.append(digestMessage)
        Log.i("✨ 插入了 mock digest report 卡片", category: "Chat")
    }

    private func rebuildMessageMap() {
        messageMap = [:]
        for (index, message) in displayMessages.enumerated() where !message.isFromUser {
            messageMap[message.id] = index
        }
    }
}

#Preview {
    PersistentChatView()
        .modelContainer(for: [LocalChatMessage.self], inMemory: true)
}
