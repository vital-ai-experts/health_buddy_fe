import Foundation
import FeatureChatApi
import FeatureOnboardingApi
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
        var state = states[cid] ?? OnboardingConversationState(stateManager: stateManager)

        let responses = await handleMessage(
            cleanText,
            conversationId: cid,
            state: &state
        )
        states[cid] = state
        if !responses.isEmpty {
            stateManager.saveOnboardingID(cid)
        }

        let streamingResponses = responses.flatMap { expandTextMessageIfNeeded($0) }
        try? await Task.sleep(nanoseconds: 500_000_000)
        for (index, event) in streamingResponses.enumerated() {
            eventHandler(.streamMessage(event))
            if index < streamingResponses.count - 1 {
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
        case start
        case healthConnect
        case survey
        case profileInfo
        case issues
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
        var stage: Stage = .start
        var hasGreeted = false
        var hasConnectedHealth = false
        var selectedGender: String?
        var hasBookedCall = false
        var hasPushedDungeonCard = false

        init(stateManager: OnboardingStateManager = OnboardingStateManager.shared) {
            selectedIssueId = issues.first?.id ?? "fatigue"
            hasConnectedHealth = stateManager.hasAuthorizedHealth
            selectedGender = stateManager.selectedGender
            hasBookedCall = stateManager.hasCompletedCall

            if hasBookedCall {
                stage = .dungeon
            } else if selectedGender != nil {
                stage = .call
            } else if hasConnectedHealth {
                stage = .survey
            }
        }
    }

    enum IncomingCommand {
        case start
        case clear
        case skip
        case healthAuthorized
        case confirmProfile
        case selectIssue(String)
        case selectGender(String)
        case updateProfile(ProfileUpdate)
        case bookCall(String)
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
            return respondStartDungeon(conversationId: conversationId, state: &state)

        case .healthAuthorized:
            return respondHealthAuthorized(conversationId: conversationId, state: &state)

        case .confirmProfile:
            return respondConfirmProfile(conversationId: conversationId, state: &state)

        case .selectIssue(let issueId):
            return respondSelectIssue(issueId, conversationId: conversationId, state: &state)

        case .selectGender(let genderId):
            return respondSelectGender(genderId, conversationId: conversationId, state: &state)

        case .updateProfile(let update):
            return respondUpdateProfile(update, conversationId: conversationId, state: &state)

        case .bookCall(let phone):
            return await respondBookCall(phone, conversationId: conversationId, state: &state)

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
        if normalized == "onboarding_health_authorized" || text == OnboardingChatMocking.Command.healthAuthorized {
            return .healthAuthorized
        }
        if normalized == "onboarding_confirm_profile" || text == OnboardingChatMocking.Command.confirmProfile {
            return .confirmProfile
        }
        if normalized == "onboarding_start_dungeon" || text == OnboardingChatMocking.Command.startDungeon {
            return .startDungeon
        }

        if normalized.hasPrefix("onboarding_select_gender:") || text.hasPrefix(OnboardingChatMocking.Command.selectGenderPrefix) {
            let id = normalized.hasPrefix("onboarding_select_gender:")
            ? String(normalized.dropFirst("onboarding_select_gender:".count))
            : String(text.dropFirst(OnboardingChatMocking.Command.selectGenderPrefix.count))
            return .selectGender(id)
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

        return .plainText(normalized)
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
        state.stage = .healthConnect
        state.hasGreeted = true

        let statusId = UUID().uuidString
        let messageId1 = UUID().uuidString
        let messageId2 = UUID().uuidString
        let cardId = UUID().uuidString

        return [
            makeStatusEvent(conversationId: conversationId, msgId: statusId, status: .generating),
            makeMessageEvent(
                conversationId: conversationId,
                msgId: messageId1,
                content: "很有价值的目标。👊为了帮你搞定它，我需要连接你的 Apple Health，读取你的运动、睡眠和心率等基础数据，这能让我实时看到你的进展。"
            ),
            makeMessageEvent(
                conversationId: conversationId,
                msgId: messageId2,
                content: "至于隐私？把心放肚子里。端到端加密和 GDPR 标准是我的底线。我痛恨垃圾邮件和数据泄露，就像你痛恨高体脂率一样。"
            ),
            makeMessageEvent(
                conversationId: conversationId,
                msgId: cardId,
                content: "",
                specialType: "onboarding_health_connect_card",
                specialData: encodeHealthConnectPayload(from: state)
            ),
            makeStatusEvent(conversationId: conversationId, msgId: statusId, status: .finished)
        ]
    }

    func respondClear(
        conversationId: String,
        state: inout OnboardingConversationState
    ) -> [StreamMessage] {
        // 重置本地状态
        state = OnboardingConversationState(stateManager: stateManager)

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

    func respondHealthAuthorized(
        conversationId: String,
        state: inout OnboardingConversationState
    ) -> [StreamMessage] {
        state.stage = .survey
        state.hasConnectedHealth = true
        stateManager.hasAuthorizedHealth = true

        let statusId = UUID().uuidString
        let msg1 = UUID().uuidString
        let msg2 = UUID().uuidString
        let msg3 = UUID().uuidString
        let msg4 = UUID().uuidString
        let msg5 = UUID().uuidString
        let cardId = UUID().uuidString

        return [
            makeStatusEvent(conversationId: conversationId, msgId: statusId, status: .generating),
            makeMessageEvent(
                conversationId: conversationId,
                msgId: msg1,
                content: "给我一分钟，正在同步你的体征数据..."
            ),
            makeMessageEvent(
                conversationId: conversationId,
                msgId: msg2,
                content: "嗯... 基础底子不错。看到你的静息心率（RHR）长期稳定在 65 左右，心肺功能是达标的，这很好。"
            ),
            makeMessageEvent(
                conversationId: conversationId,
                msgId: msg3,
                content: "但是... 这里的波动有点问题。你每晚的深睡比例平均只有 8%，远低于 15% 的及格线。而且入睡潜伏期很不稳定。"
            ),
            makeMessageEvent(
                conversationId: conversationId,
                msgId: msg4,
                content: "难怪你会觉得累。你的身体其实每晚都在‘假睡’，根本没有完成物理层面的修复。"
            ),
            makeMessageEvent(
                conversationId: conversationId,
                msgId: msg5,
                content: "行了，我心里有数了。要想方案真的落地，我还有一些关键问题要问你。"
            ),
            makeMessageEvent(
                conversationId: conversationId,
                msgId: cardId,
                content: "",
                specialType: "onboarding_single_choice_card",
                specialData: encodeGenderPayload(from: state)
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

        let title = currentIssue(state)?.title ?? "关键问题"
        state.stage = .call

        return [
            makeStatusEvent(conversationId: conversationId, msgId: statusId, status: .generating),
            makeMessageEvent(
                conversationId: conversationId,
                msgId: msgId,
                content: "好的，我们优先解决「\(title)」，我会据此更新任务节奏。"
            ),
            makeMessageEvent(
                conversationId: conversationId,
                msgId: UUID().uuidString,
                content: "",
                specialType: "onboarding_call_card",
                specialData: encodeCallPayload(from: state)
            ),
            makeStatusEvent(conversationId: conversationId, msgId: statusId, status: .finished)
        ]
    }

    func respondSelectGender(
        _ genderId: String,
        conversationId: String,
        state: inout OnboardingConversationState
    ) -> [StreamMessage] {
        state.profile.gender = mapGender(from: genderId)
        state.selectedGender = genderId
        state.stage = .call
        stateManager.selectedGender = genderId

        let statusId = UUID().uuidString
        let msgId = UUID().uuidString
        let cardId = UUID().uuidString

        return [
            makeStatusEvent(conversationId: conversationId, msgId: statusId, status: .generating),
            makeMessageEvent(
                conversationId: conversationId,
                msgId: msgId,
                content: "光有这些数据可不够，咱俩得打个电话。"
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

    func respondUpdateProfile(
        _ update: ProfileUpdate,
        conversationId: String,
        state: inout OnboardingConversationState
    ) -> [StreamMessage] {
        applyProfileUpdate(update, to: &state)
        // 不返回提示消息，等待用户点击确认后统一发送锁定文案
        return []
    }

    func respondConfirmProfile(
        conversationId: String,
        state: inout OnboardingConversationState
    ) -> [StreamMessage] {
        state.stage = .issues

        let statusId = UUID().uuidString
        let msgId = UUID().uuidString
        let cardId = UUID().uuidString

        return [
            makeStatusEvent(conversationId: conversationId, msgId: statusId, status: .generating),
            makeMessageEvent(
                conversationId: conversationId,
                msgId: msgId,
                content: "收到，档案已锁定。再确认一个你最想解决的关键问题："
            ),
            makeMessageEvent(
                conversationId: conversationId,
                msgId: cardId,
                content: "",
                specialType: "onboarding_issue_card",
                specialData: encodeProfilePayload(from: state)
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
        stateManager.hasCompletedCall = true

        let statusId = UUID().uuidString
        let msg1 = UUID().uuidString
        let msg2 = UUID().uuidString
        let msg3 = UUID().uuidString
        let msg4 = UUID().uuidString
        let msg5 = UUID().uuidString
        let dungeonCardId = UUID().uuidString

        var responses: [StreamMessage] = []
        responses.append(makeStatusEvent(conversationId: conversationId, msgId: statusId, status: .generating))
        responses.append(makeMessageEvent(
            conversationId: conversationId,
            msgId: msg1,
            content: "电话挂了。情况我摸透了。"
        ))
        responses.append(makeMessageEvent(
            conversationId: conversationId,
            msgId: msg2,
            content: "根据你的情况，我为你定制了这份「生物钟重置协议」。"
        ))
        responses.append(makeMessageEvent(
            conversationId: conversationId,
            msgId: msg3,
            content: "底层的逻辑很硬核，我融合了 Huberman Lab 的神经调控理论和斯坦福的 CBT-I 疗法(失眠认知行为疗法)。而你要做的很简单，把我推送到你手机锁屏上的微任务完成了就行。"
        ))
        responses.append(makeMessageEvent(
            conversationId: conversationId,
            msgId: msg4,
            content: "🌌 闭上眼，想象一下 21 天后的那个早晨：闹钟还没响，你的皮质醇已经自然唤醒了大脑。没有起床气，不需要靠第一杯咖啡续命，那种久违的、大脑瞬间开机的清澈感和掌控感，很想要吧？"
        ))
        responses.append(makeMessageEvent(
            conversationId: conversationId,
            msgId: msg5,
            content: "以我的经验，像你这样的用户，坚持 21 天，改善率可达 85%，睡眠变好就像打 RPG 游戏一样简单。"
        ))

        responses.append(makeMessageEvent(
            conversationId: conversationId,
            msgId: dungeonCardId,
            content: "",
            specialType: "onboarding_dungeon_card",
            specialData: encodeDungeonPayload(
                from: state,
                title: "🧬 已生成副本：21天深度睡眠修护",
                primaryAction: "🔥 激活副本",
                secondaryAction: "查看详情"
            )
        ))
        responses.append(makeStatusEvent(conversationId: conversationId, msgId: statusId, status: .finished))

        state.hasPushedDungeonCard = true
        return responses
    }

    func respondStartDungeon(
        conversationId: String,
        state: inout OnboardingConversationState
    ) -> [StreamMessage] {
        state.stage = .dungeon

        let statusId = UUID().uuidString
        let cardId = UUID().uuidString

        return [
            makeStatusEvent(conversationId: conversationId, msgId: statusId, status: .generating),
            makeMessageEvent(
                conversationId: conversationId,
                msgId: cardId,
                content: "",
                specialType: "onboarding_finish_card",
                specialData: nil
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
        case.start:
            return []
        case .healthConnect:
            let statusId = UUID().uuidString
            let msgId = UUID().uuidString

            return [
                makeStatusEvent(conversationId: conversationId, msgId: statusId, status: .generating),
                makeMessageEvent(
                    conversationId: conversationId,
                    msgId: msgId,
                    content: "先点一下上面的「连接 Apple Health」按钮，授权后我才能分析你的数据。"
                ),
                makeStatusEvent(conversationId: conversationId, msgId: statusId, status: .finished)
            ]

        case .survey:
            if text.contains("男") {
                return respondSelectGender("male", conversationId: conversationId, state: &state)
            }
            if text.contains("女") {
                return respondSelectGender("female", conversationId: conversationId, state: &state)
            }
            if text.contains("保密") {
                return respondSelectGender("secret", conversationId: conversationId, state: &state)
            }

            let statusId = UUID().uuidString
            let msgId = UUID().uuidString

            return [
                makeStatusEvent(conversationId: conversationId, msgId: statusId, status: .generating),
                makeMessageEvent(
                    conversationId: conversationId,
                    msgId: msgId,
                    content: "点选卡片上的选项会更快，帮我确定你的节律特征。"
                ),
                makeStatusEvent(conversationId: conversationId, msgId: statusId, status: .finished)
            ]

        case .profileInfo:
            var update = parseProfileUpdate(from: text.replacingOccurrences(of: "，", with: ";"))
            update = merge(update, with: parseLooseProfileUpdate(from: text))
            return respondUpdateProfile(update, conversationId: conversationId, state: &state)

        case .issues:
            let update = parseLooseProfileUpdate(from: text)
            let issueId = update.selectedIssueId ?? state.selectedIssueId
            return respondSelectIssue(issueId, conversationId: conversationId, state: &state)

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

    func mapGender(from id: String) -> String {
        switch id.lowercased() {
        case "male":
            return "男"
        case "female":
            return "女"
        default:
            return "保密"
        }
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
            gender: state.profile.gender,
            age: state.profile.age,
            height: state.profile.height,
            weight: state.profile.weight,
            issues: issues,
            selectedIssueId: state.selectedIssueId
            )
        return encodeToString(payload)
    }

    func encodeHealthConnectPayload(from state: OnboardingConversationState) -> String {
        let payload = HealthConnectCardPayload(
            title: "连接 Apple Health",
            description: "我需要访问你的运动、睡眠和心率等基础数据，用于实时调整方案。",
            connectButtonTitle: "🔗 连接 Apple Health",
            loadingTitle: "正在分析...",
            analyzingHint: "Pascal 正在分析数据...",
            isFinished: state.hasConnectedHealth || stateManager.hasAuthorizedHealth
        )
        return encodeToString(payload)
    }

    func encodeGenderPayload(from state: OnboardingConversationState) -> String {
        let selectedId = state.selectedGender ?? stateManager.selectedGender
        let payload = SingleChoiceCardPayload(
            title: "你的性别",
            description: "这能帮我做出更准确的节律判断。",
            options: [
                .init(id: "male", title: "男", subtitle: nil),
                .init(id: "female", title: "女", subtitle: nil),
                .init(id: "secret", title: "保密", subtitle: nil)
            ],
            ctaTitle: nil,
            selectedId: selectedId
        )
        return encodeToString(payload)
    }

    func encodeCallPayload(from state: OnboardingConversationState) -> String {
        let payload = CallCardPayload(
            phoneNumber: state.phoneNumber,
            headline: "给我 10 分钟，聊聊你的压力和想法",
            note: "有些具体的细节，我得亲耳听你说，才能判断你到底是卡在哪一步了。",
            ctaTitle: "📞 接听 Pascal 的来电",
            requiresPhoneNumber: true,
            loadingTitle: "通话中...",
            hasFinished: state.hasBookedCall || stateManager.hasCompletedCall
        )
        return encodeToString(payload)
    }

    func encodeDungeonPayload(
        from state: OnboardingConversationState,
        title: String,
        primaryAction: String,
        secondaryAction: String
    ) -> String {
        let payload = DungeonCardPayload(
            title: title,
            subtitle: "当前等级：Lv.1 睡眠新手 ➔ 目标：Lv.10 满电玩家",
            detail: "🔴 现状：深度睡眠 8% (易疲劳、脑雾、情绪像过山车)\n🟢 21天后：深度睡眠 15% (精力无限、反应敏捷、皮肤光泽度 +20%)",
            primaryAction: primaryAction,
            secondaryAction: secondaryAction
        )
        return encodeToString(payload)
    }

    func encodeToString<T: Encodable>(_ value: T) -> String {
        guard let data = try? JSONEncoder().encode(value) else { return "" }
        return String(data: data, encoding: .utf8) ?? ""
    }

    func makeTextMessageEvents(
        conversationId: String,
        msgId: String,
        content: String
    ) -> [StreamMessage] {
        guard !content.isEmpty else {
            return [makeMessageEvent(conversationId: conversationId, msgId: msgId, content: content)]
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

    func expandTextMessageIfNeeded(_ message: StreamMessage) -> [StreamMessage] {
        let data = message.data
        let hasSpecialMessage = data.specialMessageType != nil || data.specialMessageData != nil

        guard data.dataType == .agentMessage,
              data.messageType != .chunk,
              !hasSpecialMessage,
              let conversationId = data.conversationId ?? data.onboardingId,
              let content = data.content,
              !content.isEmpty else {
            return [message]
        }

        return makeTextMessageEvents(conversationId: conversationId, msgId: data.msgId, content: content)
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
