import Foundation
import SwiftUI

/// 问询卡片 - 用于主动向用户提问
public struct InquiryCard: Identifiable {
    public let id: String
    public let emoji: String  // 卡片的主表情图标
    public let question: String  // 问询问题
    public let options: [InquiryOption]  // 选项列表

    public init(
        id: String = UUID().uuidString,
        emoji: String,
        question: String,
        options: [InquiryOption]
    ) {
        self.id = id
        self.emoji = emoji
        self.question = question
        self.options = options
    }
}

/// 问询选项
public struct InquiryOption: Identifiable {
    public let id: String
    public let emoji: String  // 选项的表情图标
    public let text: String  // 选项文本
    public let actionId: String  // 用于识别用户选择的操作ID

    public init(
        id: String = UUID().uuidString,
        emoji: String,
        text: String,
        actionId: String
    ) {
        self.id = id
        self.emoji = emoji
        self.text = text
        self.actionId = actionId
    }
}

// MARK: - Decodable Support for JSON Payload

struct InquiryCardPayload: Decodable {
    let emoji: String
    let question: String
    let options: [InquiryOptionPayload]

    func toInquiryCard() -> InquiryCard {
        InquiryCard(
            emoji: emoji,
            question: question,
            options: options.map { $0.toInquiryOption() }
        )
    }
}

struct InquiryOptionPayload: Decodable {
    let emoji: String
    let text: String
    let actionId: String

    enum CodingKeys: String, CodingKey {
        case emoji
        case text
        case actionId = "action_id"
    }

    func toInquiryOption() -> InquiryOption {
        InquiryOption(emoji: emoji, text: text, actionId: actionId)
    }
}

// MARK: - Sample Data

extension InquiryCard {
    /// 示例问询卡片
    public static var sampleCards: [InquiryCard] {
        [
            // 卡片 1: 睡眠时间计算问询
            InquiryCard(
                emoji: "👀",
                question: "正在为你计算今晚的最佳入睡时间，在我运行模型前，有没有什么干扰项需要我手动录入的？",
                options: [
                    InquiryOption(emoji: "🥗", text: "我很健康", actionId: "healthy"),
                    InquiryOption(emoji: "🍺", text: "喝了酒", actionId: "alcohol"),
                    InquiryOption(emoji: "🍔", text: "吃了夜宵", actionId: "late_snack")
                ]
            ),

            // 卡片 2: 睡眠质量体感问询
            InquiryCard(
                emoji: "👀",
                question: "数据说你昨晚只睡了 6 小时，但我想知道你的真实体感。你现在感觉怎么样？",
                options: [
                    InquiryOption(emoji: "🚀", text: "满血复活", actionId: "energized"),
                    InquiryOption(emoji: "😑", text: "有点脑雾", actionId: "foggy"),
                    InquiryOption(emoji: "🧟‍♂️", text: "像卡车碾过", actionId: "exhausted")
                ]
            ),

            // 卡片 3: 心率异常问询
            InquiryCard(
                emoji: "👀",
                question: "虽然你坐着没动，但心率数据越来越高了，是遇到什么棘手的情况了吗？",
                options: [
                    InquiryOption(emoji: "😨", text: "突发焦虑", actionId: "anxiety"),
                    InquiryOption(emoji: "🤮", text: "开了个烂会", actionId: "bad_meeting"),
                    InquiryOption(emoji: "☕️", text: "咖啡因上头", actionId: "caffeine")
                ]
            ),

            // 卡片 4: HRV下降问询
            InquiryCard(
                emoji: "👀",
                question: "HRV 已经连跌 3 天了，深睡也一直在减少，最近是不是遇到了什么事情？",
                options: [
                    InquiryOption(emoji: "🤯", text: "工作太卷", actionId: "overwork"),
                    InquiryOption(emoji: "🦠", text: "感觉要病", actionId: "getting_sick"),
                    InquiryOption(emoji: "💔", text: "情绪烂事", actionId: "emotional_stress")
                ]
            ),

            // 卡片 5: 午餐拍照问询
            InquiryCard(
                emoji: "📷",
                question: "中午啦。别让自己饿着，吃的什么，随手拍一张给我看看？我来帮你记录今天的卡路里摄入。",
                options: [
                    InquiryOption(emoji: "📷", text: "随手拍", actionId: "take_photo")
                ]
            )
        ]
    }
}
