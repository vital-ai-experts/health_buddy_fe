import ActivityKit
import Foundation
import SwiftUI
import WidgetKit
import LibraryNotification
import LibraryBase
import AppIntents
import ThemeKit

/// Live Activity Widget for Inquiry (主动问询卡片)
@available(iOS 16.1, *)
struct InquiryLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: InquiryActivityAttributes.self) { context in
            // Lock screen UI
            InquiryLiveActivityView(context: context)
                .activityBackgroundTint(Color.Palette.bgMuted)
                .activitySystemActionForegroundColor(Color.Palette.textPrimary)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded region
                DynamicIslandExpandedRegion(.leading) {
                    Text("👀")
                        .font(.system(size: 24))
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Image(systemName: "questionmark.circle.fill")
                        .foregroundStyle(Color.Palette.infoBgSoft)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(context.state.question)
                            .font(.caption)
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                    }
                    .padding(.horizontal)
                }
            } compactLeading: {
                Text("👀")
                    .font(.caption2)
            } compactTrailing: {
                Image(systemName: "questionmark.circle")
                    .foregroundStyle(Color.Palette.infoMain)
            } minimal: {
                Image(systemName: "questionmark.circle.fill")
                    .foregroundStyle(Color.Palette.infoMain)
            }
        }
    }
}

/// Main view for the Inquiry Live Activity on lock screen
@available(iOS 16.1, *)
struct InquiryLiveActivityView: View {
    let context: ActivityViewContext<InquiryActivityAttributes>

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color.Palette.bgBase,
                    Color.Palette.bgMuted
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(0.98)

            VStack(alignment: .leading, spacing: 12) {
                // Question section
                HStack(alignment: .top, spacing: 8) {
                    Text("👀")
                        .font(.system(size: 20))

                    Text(context.state.question)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.Palette.textPrimary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 0)
                }

                // Options grid
                let columns = [
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8)
                ]

                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(context.state.options, id: \.id) { option in
                        Link(destination: buildOptionURL(for: option)) {
                            HStack(spacing: 6) {
                                Text(option.emoji)
                                    .font(.system(size: 16))

                                Text(option.text)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color.Palette.textPrimary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)

                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.Palette.bgMuted.opacity(0.9))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .strokeBorder(
                                                Color.Palette.borderSubtle.opacity(0.5),
                                                lineWidth: 1
                                            )
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
        }
        .widgetURL(deepLinkURL)
    }

    /// Build deep link for option selection
    private func buildOptionURL(for option: InquiryActivityAttributes.ContentState.InquiryOption) -> URL {
        let message = "#inquiry#\(option.text)"
        var components = URLComponents()
        components.scheme = "thrivebody"
        components.host = "main"
        components.queryItems = [
            URLQueryItem(name: "tab", value: "chat"),
            URLQueryItem(name: "sendmsg", value: message),
            URLQueryItem(name: "inquiry", value: "1"),
            URLQueryItem(name: "complete", value: "1")
        ]
        return components.url ?? URL(string: "thrivebody://main")!
    }

    /// Build deep link to open app and send message
    private var deepLinkURL: URL? {
        var components = URLComponents()
        components.scheme = "thrivebody"
        components.host = "main"
        components.queryItems = [
            URLQueryItem(name: "tab", value: "chat"),
            URLQueryItem(name: "inquiry", value: "1")
        ]
        return components.url
    }
}

// MARK: - Preview

@available(iOS 16.1, *)
#Preview("Inquiry Live Activity", as: .content, using: InquiryActivityAttributes(userId: "preview")) {
    InquiryLiveActivity()
} contentStates: {
    // Preview state 1: 入睡时间问询
    InquiryActivityAttributes.ContentState(
        question: "正在为你计算今晚的最佳入睡时间，在我运行模型前，有没有什么干扰项需要我手动录入的？",
        options: [
            .init(emoji: "🥗", text: "我很健康", id: "healthy"),
            .init(emoji: "🍺", text: "喝了酒", id: "alcohol"),
            .init(emoji: "🍔", text: "吃了夜宵", id: "late_snack")
        ]
    )

    // Preview state 2: 睡眠体感问询
    InquiryActivityAttributes.ContentState(
        question: "数据说你昨晚只睡了 6 小时，但我想知道你的真实体感。你现在感觉怎么样？",
        options: [
            .init(emoji: "🚀", text: "满血复活", id: "energized"),
            .init(emoji: "😑", text: "有点脑雾", id: "foggy"),
            .init(emoji: "🧟‍♂️", text: "像卡车碾过", id: "exhausted")
        ]
    )

    // Preview state 3: 心率升高问询
    InquiryActivityAttributes.ContentState(
        question: "虽然你坐着没动，但心率数据越来越高了，是遇到什么棘手的情况了吗？",
        options: [
            .init(emoji: "😨", text: "突发焦虑", id: "anxiety"),
            .init(emoji: "🤮", text: "开了个烂会", id: "bad_meeting"),
            .init(emoji: "☕️", text: "咖啡因上头", id: "caffeine")
        ]
    )

    // Preview state 4: HRV下降问询
    InquiryActivityAttributes.ContentState(
        question: "HRV 已经连跌 3 天了，深睡也一直在减少，最近是不是遇到了什么事情？",
        options: [
            .init(emoji: "🤯", text: "工作太卷", id: "overwork"),
            .init(emoji: "🦠", text: "感觉要病", id: "getting_sick"),
            .init(emoji: "💔", text: "情绪烂事", id: "emotional")
        ]
    )

    // Preview state 5: 午餐拍照
    InquiryActivityAttributes.ContentState(
        question: "中午啦。别让自己饿着，吃的什么，随手拍一张给我看看？我来帮你记录今天的卡路里摄入。",
        options: [
            .init(emoji: "📷", text: "随手拍", id: "take_photo")
        ]
    )
}
