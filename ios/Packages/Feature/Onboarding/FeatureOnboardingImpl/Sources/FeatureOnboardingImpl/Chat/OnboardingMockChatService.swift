import Foundation
import FeatureChatApi
import LibraryChatUI

/// Onboarding 阶段专用的 Mock Chat Service，完全在本地生成对话流与卡片
public final class OnboardingMockChatService: ChatService {
    private var states: [String: OnboardingConversationState] = [:]
    private let stateManager = OnboardingStateManager.shared

    public init() {}

    public func sendMessage(
        userInput: String?,
        conversationId: String?,
        eventHandler: @escaping (ConversationStreamEvent) -> Void
    ) async throws {
        let rawText = userInput ?? ""
        let cleanText = ChatMocking.stripMockPrefix(from: rawText)
        let cid = resolveConversationId(from: conversationId)
        var state = states[cid] ?? OnboardingConversationState()

        let responses = await handleMessage(
            cleanText,
            conversationId: cid,
            state: &state
        )
        states[cid] = state
        if !responses.isEmpty {
            stateManager.saveOnboardingID(cid)
        }

        for (index, event) in responses.enumerated() {
            try? await Task.sleep(nanoseconds: 500_000_000)
            eventHandler(.streamMessage(event))
            if index < responses.count - 1 {
                try? await Task.sleep(nanoseconds: 200_000_000)
            }
        }
    }

    public func resumeConversation(
        conversationId: String,
        lastDataId: String?,
        eventHandler: @escaping (ConversationStreamEvent) -> Void
    ) async throws {
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
        let cid = stateManager.getOnboardingID() ?? OnboardingChatMocking.makeConversationId()
        return [
            Conversation(
                id: cid,
                createdAt: currentTimestamp()
            )
        ]
    }

    public func getConversationHistory(id: String, chatSession: ChatSessionControlling?) async throws -> [Message] {
        []
    }

    public func deleteConversation(id: String) async throws {
        states[id] = nil
    }
}

// MARK: - Private helpers

private extension OnboardingMockChatService {
    enum Stage {
        case profile
        case call
        case dungeon
    }

    struct Profile {
        var name: String
        var gender: String
        var age: Int
        var height: Int
        var weight: Int
    }

    struct Issue: Codable {
        let id: String
        let title: String
        let detail: String
    }

    struct OnboardingConversationState {
        var profile = Profile(name: "凌安", gender: "男", age: 30, height: 178, weight: 75)
        var issues: [Issue] = OnboardingMockChatService.defaultIssues
        var selectedIssueId: String
        var phoneNumber: String = "13800000000"
        var stage: Stage = .profile
        var hasGreeted = false
        var hasBookedCall = false
        var hasPushedDungeonCard = false

        init() {
            selectedIssueId = issues.first?.id ?? "fatigue"
        }
    }

    enum IncomingCommand {
        case start
        case clear
        case skip
        case confirmProfile
        case selectIssue(String)
        case updateProfile(ProfileUpdate)
        case bookCall(String)
        case viewDungeon
        case startDungeon
        case plainText(String)
    }

    struct ProfileUpdate {
        var name: String?
        var age: Int?
        var height: Int?
        var weight: Int?
        var gender: String?
        var selectedIssueId: String?

        var hasChanges: Bool {
            name != nil || age != nil || height != nil || weight != nil || gender != nil || selectedIssueId != nil
        }
    }

    static let defaultIssues: [Issue] = [
        Issue(
            id: "fatigue",
            title: "虽然睡够了 7 小时，但醒来依然像没睡一样累",
            detail: "深睡占比 < 10%"
        ),
        Issue(
            id: "focus",
            title: "下午 3 点后注意力很难集中，必须靠咖啡续命",
            detail: "久坐 + HRV 偏低"
        ),
        Issue(
            id: "bloat",
            title: "体重正常，但经常感觉身体“沉重”或水肿",
            detail: "步数与卡路里消耗不匹配"
        )
    ]

    func handleMessage(
        _ text: String,
        conversationId: String,
        state: inout OnboardingConversationState
    ) async -> [StreamMessage] {
        let command = parseCommand(from: text)

        switch command {
        case .start:
            return respondProfileIntro(conversationId: conversationId, state: &state)

        case .clear:
            return respondClear(conversationId: conversationId, state: &state)

        case .skip:
            return respondSkip(conversationId: conversationId)

        case .confirmProfile:
            return respondConfirmProfile(conversationId: conversationId, state: &state)

        case .selectIssue(let issueId):
            return respondSelectIssue(issueId, conversationId: conversationId, state: &state)

        case .updateProfile(let update):
            return respondUpdateProfile(update, conversationId: conversationId, state: &state)

        case .bookCall(let phone):
            return await respondBookCall(phone, conversationId: conversationId, state: &state)

        case .viewDungeon:
            return respondViewDungeon(conversationId: conversationId)

        case .startDungeon:
            return respondStartDungeon(conversationId: conversationId, state: &state)

        case .plainText(let text):
            return await respondFreeText(text, conversationId: conversationId, state: &state)
        }
    }

    func parseCommand(from text: String) -> IncomingCommand {
        if text.isEmpty {
            return .start
        }

        let normalized = text.replacingOccurrences(of: "#mock#", with: "")
        let lowercased = normalized.lowercased()
        if lowercased == "clear" {
            return .clear
        }
        if lowercased == "skip" {
            return .skip
        }

        if normalized == "onboarding_start" || text == OnboardingChatMocking.Command.start {
            return .start
        }
        if normalized == "onboarding_confirm_profile" || text == OnboardingChatMocking.Command.confirmProfile {
            return .confirmProfile
        }
        if normalized == "onboarding_view_dungeon" || text == OnboardingChatMocking.Command.viewDungeon {
            return .viewDungeon
        }
        if normalized == "onboarding_start_dungeon" || text == OnboardingChatMocking.Command.startDungeon {
            return .startDungeon
        }

        if normalized.hasPrefix("onboarding_select_issue:") || text.hasPrefix(OnboardingChatMocking.Command.selectIssuePrefix) {
            let id = normalized.hasPrefix("onboarding_select_issue:")
            ? String(normalized.dropFirst("onboarding_select_issue:".count))
            : String(text.dropFirst(OnboardingChatMocking.Command.selectIssuePrefix.count))
            return .selectIssue(id)
        }

        if normalized.hasPrefix("onboarding_update_profile:") || text.hasPrefix(OnboardingChatMocking.Command.updateProfilePrefix) {
            let content = normalized.hasPrefix("onboarding_update_profile:")
            ? String(normalized.dropFirst("onboarding_update_profile:".count))
            : String(text.dropFirst(OnboardingChatMocking.Command.updateProfilePrefix.count))
            let update = parseProfileUpdate(from: content)
            return .updateProfile(update)
        }

        if normalized.hasPrefix("onboarding_book_call:") || text.hasPrefix(OnboardingChatMocking.Command.bookCallPrefix) {
            let phone = normalized.hasPrefix("onboarding_book_call:")
            ? String(normalized.dropFirst("onboarding_book_call:".count))
            : String(text.dropFirst(OnboardingChatMocking.Command.bookCallPrefix.count))
            return .bookCall(phone)
        }

        return .plainText(text)
    }

    func parseProfileUpdate(from text: String) -> ProfileUpdate {
        var update = ProfileUpdate()
        let pairs = text.split(separator: ";")
        for pair in pairs {
            let keyValue = pair.split(separator: "=")
            guard keyValue.count == 2 else { continue }
            let key = keyValue[0].trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let value = keyValue[1].trimmingCharacters(in: .whitespacesAndNewlines)

            switch key {
            case "name":
                update.name = value
            case "age":
                update.age = Int(value)
            case "height":
                update.height = Int(value)
            case "weight":
                update.weight = Int(value)
            case "gender":
                update.gender = value
            case "issue":
                update.selectedIssueId = value
            default:
                break
            }
        }
        return update
    }

    func respondProfileIntro(
        conversationId: String,
        state: inout OnboardingConversationState
    ) -> [StreamMessage] {
        state.stage = .profile
        state.hasGreeted = true

        let statusId = UUID().uuidString
        let messageId = UUID().uuidString
        let cardId = UUID().uuidString

        return [
            makeStatusEvent(conversationId: conversationId, msgId: statusId, status: .generating),
            makeMessageEvent(
                conversationId: conversationId,
                msgId: messageId,
                content: "我已经读取完你的身体数据，先帮你生成了一版健康档案草稿，确认后我会为你安排顾问电话。"
            ),
            makeMessageEvent(
                conversationId: conversationId,
                msgId: cardId,
                content: "",
                specialType: "onboarding_profile_card",
                specialData: encodeProfilePayload(from: state)
            ),
            makeStatusEvent(conversationId: conversationId, msgId: statusId, status: .finished)
        ]
    }

    func respondClear(
        conversationId: String,
        state: inout OnboardingConversationState
    ) -> [StreamMessage] {
        // 重置本地状态
        state = OnboardingConversationState()

        let resetMsgId = UUID().uuidString
        var events: [StreamMessage] = [
            makeSpecialEvent(
                conversationId: conversationId,
                msgId: resetMsgId,
                specialType: "reset_conversation",
                specialData: nil
            )
        ]

        events.append(contentsOf: respondProfileIntro(conversationId: conversationId, state: &state))
        return events
    }

    func respondSkip(conversationId: String) -> [StreamMessage] {
        stateManager.saveOnboardingID(conversationId)
        stateManager.markOnboardingAsCompleted()

        let statusId = UUID().uuidString
        let msgId = UUID().uuidString

        return [
            makeStatusEvent(conversationId: conversationId, msgId: statusId, status: .generating),
            makeMessageEvent(
                conversationId: conversationId,
                msgId: msgId,
                content: "好的，已为你跳过引导，直接进入首页。",
                specialType: "onboarding_skip",
                specialData: nil
            ),
            makeStatusEvent(conversationId: conversationId, msgId: statusId, status: .finished)
        ]
    }

    func respondSelectIssue(
        _ issueId: String,
        conversationId: String,
        state: inout OnboardingConversationState
    ) -> [StreamMessage] {
        if state.issues.contains(where: { $0.id == issueId }) {
            state.selectedIssueId = issueId
        }

        let statusId = UUID().uuidString
        let msgId = UUID().uuidString
        let cardId = UUID().uuidString

        let title = currentIssue(state)?.title ?? "关键问题"

        return [
            makeStatusEvent(conversationId: conversationId, msgId: statusId, status: .generating),
            makeMessageEvent(
                conversationId: conversationId,
                msgId: msgId,
                content: "好的，我们优先解决「\(title)」，我会据此更新任务节奏。"
            ),
            makeMessageEvent(
                conversationId: conversationId,
                msgId: cardId,
                content: "",
                specialType: "onboarding_profile_card",
                specialData: encodeProfilePayload(from: state)
            ),
            makeStatusEvent(conversationId: conversationId, msgId: statusId, status: .finished)
        ]
    }

    func respondUpdateProfile(
        _ update: ProfileUpdate,
        conversationId: String,
        state: inout OnboardingConversationState
    ) -> [StreamMessage] {
        applyProfileUpdate(update, to: &state)

        let statusId = UUID().uuidString
        let msgId = UUID().uuidString
        let cardId = UUID().uuidString

        let summary = profileSummary(from: update, state: state)

        return [
            makeStatusEvent(conversationId: conversationId, msgId: statusId, status: .generating),
            makeMessageEvent(
                conversationId: conversationId,
                msgId: msgId,
                content: summary
            ),
            makeMessageEvent(
                conversationId: conversationId,
                msgId: cardId,
                content: "",
                specialType: "onboarding_profile_card",
                specialData: encodeProfilePayload(from: state)
            ),
            makeStatusEvent(conversationId: conversationId, msgId: statusId, status: .finished)
        ]
    }

    func respondConfirmProfile(
        conversationId: String,
        state: inout OnboardingConversationState
    ) -> [StreamMessage] {
        state.stage = .call

        let statusId = UUID().uuidString
        let msgId = UUID().uuidString
        let cardId = UUID().uuidString

        let issueTitle = currentIssue(state)?.title ?? "你的目标"

        return [
            makeStatusEvent(conversationId: conversationId, msgId: statusId, status: .generating),
            makeMessageEvent(
                conversationId: conversationId,
                msgId: msgId,
                content: "收到，档案已锁定。「\(issueTitle)」将作为你的主线任务，先留一个手机号，我们 10 秒内安排顾问来电确认。"
            ),
            makeMessageEvent(
                conversationId: conversationId,
                msgId: cardId,
                content: "",
                specialType: "onboarding_call_card",
                specialData: encodeCallPayload(from: state)
            ),
            makeStatusEvent(conversationId: conversationId, msgId: statusId, status: .finished)
        ]
    }

    func respondBookCall(
        _ phone: String,
        conversationId: String,
        state: inout OnboardingConversationState
    ) async -> [StreamMessage] {
        state.phoneNumber = phone
        state.stage = .dungeon
        state.hasBookedCall = true

        let statusId = UUID().uuidString
        let waitingMsgId = UUID().uuidString
        let finishMsgId = UUID().uuidString
        let dungeonCardId = UUID().uuidString

        var responses: [StreamMessage] = []
        responses.append(makeStatusEvent(conversationId: conversationId, msgId: statusId, status: .generating))
        responses.append(makeMessageEvent(
            conversationId: conversationId,
            msgId: waitingMsgId,
            content: "好的，将在 10 秒内给 \(phone) 拨出顾问电话，请保持畅通。"
        ))

        try? await Task.sleep(nanoseconds: 900_000_000)
        responses.append(makeMessageEvent(
            conversationId: conversationId,
            msgId: finishMsgId,
            content: "通话完成，我已为你解锁专属副本，先看一眼今日任务吧。"
        ))

        responses.append(makeMessageEvent(
            conversationId: conversationId,
            msgId: dungeonCardId,
            content: "",
            specialType: "onboarding_dungeon_card",
            specialData: encodeDungeonPayload(from: state)
        ))
        responses.append(makeStatusEvent(conversationId: conversationId, msgId: statusId, status: .finished))

        state.hasPushedDungeonCard = true
        return responses
    }

    func respondViewDungeon(conversationId: String) -> [StreamMessage] {
        let statusId = UUID().uuidString
        let msgId = UUID().uuidString

        return [
            makeStatusEvent(conversationId: conversationId, msgId: statusId, status: .generating),
            makeMessageEvent(
                conversationId: conversationId,
                msgId: msgId,
                content: "好的，我会为你打开副本详情，随时可以从卡片进入。"
            ),
            makeStatusEvent(conversationId: conversationId, msgId: statusId, status: .finished)
        ]
    }

    func respondStartDungeon(
        conversationId: String,
        state: inout OnboardingConversationState
    ) -> [StreamMessage] {
        state.stage = .dungeon

        let statusId = UUID().uuidString
        let msgId = UUID().uuidString

        let issueTitle = currentIssue(state)?.title ?? "副本"

        return [
            makeStatusEvent(conversationId: conversationId, msgId: statusId, status: .generating),
            makeMessageEvent(
                conversationId: conversationId,
                msgId: msgId,
                content: "副本「\(issueTitle)」已开启，我会把任务同步到今日清单，随时可以回来问我。"
            ),
            makeStatusEvent(conversationId: conversationId, msgId: statusId, status: .finished)
        ]
    }

    func respondFreeText(
        _ text: String,
        conversationId: String,
        state: inout OnboardingConversationState
    ) async -> [StreamMessage] {
        switch state.stage {
        case .profile:
            var update = parseProfileUpdate(from: text.replacingOccurrences(of: "，", with: ";"))
            update = merge(update, with: parseLooseProfileUpdate(from: text))
            return respondUpdateProfile(update, conversationId: conversationId, state: &state)

        case .call:
            let phone = extractPhone(from: text) ?? state.phoneNumber
            return await respondBookCall(phone, conversationId: conversationId, state: &state)

        case .dungeon:
            let statusId = UUID().uuidString
            let msgId = UUID().uuidString

            return [
                makeStatusEvent(conversationId: conversationId, msgId: statusId, status: .generating),
                makeMessageEvent(
                    conversationId: conversationId,
                    msgId: msgId,
                    content: "收到，任务已锁定。随时可以在卡片底部开启副本，或者告诉我新的需求。"
                ),
                makeStatusEvent(conversationId: conversationId, msgId: statusId, status: .finished)
            ]
        }
    }

    func applyProfileUpdate(_ update: ProfileUpdate, to state: inout OnboardingConversationState) {
        if let name = update.name { state.profile.name = name }
        if let age = update.age { state.profile.age = age }
        if let height = update.height { state.profile.height = height }
        if let weight = update.weight { state.profile.weight = weight }
        if let gender = update.gender { state.profile.gender = gender }
        if let issue = update.selectedIssueId { state.selectedIssueId = issue }
    }

    func merge(_ lhs: ProfileUpdate, with rhs: ProfileUpdate) -> ProfileUpdate {
        ProfileUpdate(
            name: lhs.name ?? rhs.name,
            age: lhs.age ?? rhs.age,
            height: lhs.height ?? rhs.height,
            weight: lhs.weight ?? rhs.weight,
            gender: lhs.gender ?? rhs.gender,
            selectedIssueId: lhs.selectedIssueId ?? rhs.selectedIssueId
        )
    }

    func parseLooseProfileUpdate(from text: String) -> ProfileUpdate {
        var update = ProfileUpdate()
        let lowercased = text.lowercased()

        if lowercased.contains("男") { update.gender = "男" }
        if lowercased.contains("女") { update.gender = "女" }

        let digits = text.compactMap { $0.isNumber ? $0 : nil }
        if !digits.isEmpty {
            let numberString = String(digits)
            if numberString.count >= 9 {
                update.selectedIssueId = nil
            } else if numberString.count >= 3 {
                if let value = Int(numberString.suffix(3)) {
                    if lowercased.contains("cm") || lowercased.contains("身高") {
                        update.height = value
                    } else if lowercased.contains("kg") || lowercased.contains("体重") {
                        update.weight = value
                    }
                }
            }
        }

        if let age = extractNumber(in: text, keyword: "岁") {
            update.age = age
        }

        for issue in OnboardingMockChatService.defaultIssues {
            if text.contains(issue.title) {
                update.selectedIssueId = issue.id
            }
        }

        return update
    }

    func extractPhone(from text: String) -> String? {
        let digits = text.filter { $0.isNumber }
        guard digits.count >= 6 else { return nil }
        return digits
    }

    func extractNumber(in text: String, keyword: String) -> Int? {
        guard let range = text.range(of: keyword) else { return nil }
        let prefix = text[..<range.lowerBound]
        let digits = prefix.reversed().prefix { $0.isNumber }.reversed()
        return Int(String(digits))
    }

    func profileSummary(from update: ProfileUpdate, state: OnboardingConversationState) -> String {
        if !update.hasChanges {
            return "好的，我会按当前档案生成战术，随时可以继续补充信息。"
        }

        var parts: [String] = []
        if let name = update.name { parts.append("姓名更新为 \(name)") }
        if let age = update.age { parts.append("年龄改为 \(age) 岁") }
        if let height = update.height { parts.append("身高改为 \(height) cm") }
        if let weight = update.weight { parts.append("体重改为 \(weight) kg") }
        if let gender = update.gender { parts.append("性别更新为 \(gender)") }
        if let issue = update.selectedIssueId, let issueTitle = state.issues.first(where: { $0.id == issue })?.title {
            parts.append("优先问题改为「\(issueTitle)」")
        }

        return parts.joined(separator: "，") + "。"
    }

    func currentIssue(_ state: OnboardingConversationState) -> Issue? {
        state.issues.first { $0.id == state.selectedIssueId }
    }

    func encodeProfilePayload(from state: OnboardingConversationState) -> String {
        let issues = state.issues.map { issue in
            ProfileCardPayload.Issue(id: issue.id, title: issue.title, detail: issue.detail)
        }
        let payload = ProfileCardPayload(
            name: state.profile.name,
            gender: state.profile.gender,
            age: state.profile.age,
            height: state.profile.height,
            weight: state.profile.weight,
            issues: issues,
            selectedIssueId: state.selectedIssueId
        )
        return encodeToString(payload)
    }

    func encodeCallPayload(from state: OnboardingConversationState) -> String {
        let payload = CallCardPayload(
            phoneNumber: state.phoneNumber,
            headline: "顾问将在 10 秒内来电",
            note: "确认后会拨打你提供的手机号，讨论你的目标与日程。"
        )
        return encodeToString(payload)
    }

    func encodeDungeonPayload(from state: OnboardingConversationState) -> String {
        let issueTitle = currentIssue(state)?.title ?? "你的专属副本"
        let payload = DungeonCardPayload(
            title: "已加入副本，查看今日任务吧！",
            subtitle: issueTitle,
            detail: "我们已为你生成今日的优先任务。点击查看详情或直接开启副本，任务会同步到首页。",
            primaryAction: "开启副本",
            secondaryAction: "查看详情"
        )
        return encodeToString(payload)
    }

    func encodeToString<T: Encodable>(_ value: T) -> String {
        guard let data = try? JSONEncoder().encode(value) else { return "" }
        return String(data: data, encoding: .utf8) ?? ""
    }

    func makeStatusEvent(
        conversationId: String,
        msgId: String,
        status: AgentStatus
    ) -> StreamMessage {
        StreamMessage(
            id: UUID().uuidString,
            data: StreamMessageData(
                conversationId: conversationId,
                msgId: msgId,
                dataType: .agentStatus,
                agentStatus: status
            )
        )
    }

    func makeMessageEvent(
        conversationId: String,
        msgId: String,
        content: String,
        specialType: String? = nil,
        specialData: String? = nil
    ) -> StreamMessage {
        StreamMessage(
            id: UUID().uuidString,
            data: StreamMessageData(
                conversationId: conversationId,
                msgId: msgId,
                dataType: .agentMessage,
                messageType: .whole,
                content: content,
                specialMessageType: specialType,
                specialMessageData: specialData
            )
        )
    }

    func makeSpecialEvent(
        conversationId: String,
        msgId: String,
        specialType: String,
        specialData: String?
    ) -> StreamMessage {
        StreamMessage(
            id: UUID().uuidString,
            data: StreamMessageData(
                conversationId: conversationId,
                msgId: msgId,
                dataType: .agentMessage,
                messageType: .whole,
                specialMessageType: specialType,
                specialMessageData: specialData
            )
        )
    }

    func currentTimestamp() -> String {
        String(Int(Date().timeIntervalSince1970 * 1000))
    }

    func resolveConversationId(from incoming: String?) -> String {
        if let incoming {
            return incoming
        }
        if let saved = stateManager.getOnboardingID(),
           saved.hasPrefix(OnboardingChatMocking.onboardingConversationPrefix) {
            return saved
        }
        return OnboardingChatMocking.makeConversationId()
    }
}
