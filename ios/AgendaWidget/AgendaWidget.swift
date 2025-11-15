import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Activity Attributes

struct AgendaAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // 动态数据（可以通过推送更新）
        var temperature: String      // Mock: 任务数量
        var feelsLike: String        // Mock: 紧急任务数
        var weatherDescription: String // Mock: 主要任务描述
        var humidity: String         // Mock: 完成率
        var windSpeed: String        // Mock: 待办数量
        var weatherCode: String      // Mock: 任务类型代码
        var updateTime: Date

        var agendaEmoji: String {
            // 任务类型 emoji 映射
            switch weatherCode {
            case "113": return "✅" // 正常状态
            case "116": return "📋" // 有待办
            case "119": return "⏰" // 有提醒
            case "122": return "🔔" // 有通知
            case "143", "248", "260": return "⚠️" // 有警告
            case "176", "263", "266": return "📝" // 记录任务
            case "179", "182", "185", "281", "284": return "💊" // 用药提醒
            case "200": return "🏃" // 运动任务
            case "227", "230": return "🩺" // 健康检查
            case "293", "296": return "💧" // 饮水提醒
            case "299", "302", "305", "308", "311", "314", "317", "320", "323", "326", "329", "332", "335", "338": return "🍎" // 饮食记录
            case "350", "353", "356", "359", "362", "365", "368", "371", "374", "377": return "😴" // 睡眠提醒
            case "386", "389", "392", "395": return "🚨" // 紧急任务
            default: return "📌" // 默认任务
            }
        }

        var formattedUpdateTime: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            formatter.locale = Locale(identifier: "zh_CN")
            return formatter.string(from: updateTime)
        }
    }

    // 静态数据（Live Activity 生命周期内不变）
    var userName: String
}

// MARK: - Live Activity Widget

struct AgendaLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AgendaAttributes.self) { context in
            // 锁屏/横幅视图
            LockScreenLiveActivityView(context: context)
        } dynamicIsland: { context in
            // 灵动岛视图
            DynamicIsland {
                // Expanded - 灵动岛展开状态
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        Text(context.state.agendaEmoji)
                            .font(.system(size: 32))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("健康任务")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(context.state.weatherDescription)
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(context.state.temperature)°")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(context.state.formattedUpdateTime)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 16) {
                        Label("\(context.state.humidity)%", systemImage: "humidity.fill")
                            .font(.caption)
                        Label("\(context.state.windSpeed)km/h", systemImage: "wind")
                            .font(.caption)
                        Spacer()
                        Text("体感 \(context.state.feelsLike)°")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                }
            } compactLeading: {
                // 灵动岛紧凑状态 - 左侧
                Text(context.state.agendaEmoji)
            } compactTrailing: {
                // 灵动岛紧凑状态 - 右侧
                Text("\(context.state.temperature)°")
                    .font(.caption)
                    .fontWeight(.semibold)
            } minimal: {
                // 灵动岛最小化状态
                Text(context.state.agendaEmoji)
            }
        }
    }
}

// MARK: - Lock Screen Live Activity View

struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<AgendaAttributes>

    var body: some View {
        VStack(spacing: 0) {
            // 顶部主要信息
            HStack(spacing: 12) {
                // 左侧：大图标
                Text(context.state.agendaEmoji)
                    .font(.system(size: 56))

                // 中间：任务信息
                VStack(alignment: .leading, spacing: 4) {
                    Text(context.attributes.userName)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(context.state.weatherDescription)
                        .font(.title3)
                        .fontWeight(.bold)

                    Text("体感 \(context.state.feelsLike)°C")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // 右侧：温度显示
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(context.state.temperature)°")
                        .font(.system(size: 44, weight: .bold))
                    Text("更新: \(context.state.formattedUpdateTime)")
                        .font(.caption2)
                        .foregroundColor(.tertiary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            // 底部详细信息卡片
            HStack(spacing: 24) {
                InfoPill(
                    icon: "humidity.fill",
                    label: "湿度",
                    value: "\(context.state.humidity)%"
                )

                InfoPill(
                    icon: "wind",
                    label: "风速",
                    value: "\(context.state.windSpeed)km/h"
                )

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.secondary.opacity(0.1))
        }
        .activityBackgroundTint(Color.cyan.opacity(0.25))
        .activitySystemActionForegroundColor(Color.cyan)
    }
}

// MARK: - Supporting Views

struct InfoPill: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
            VStack(alignment: .leading, spacing: 0) {
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
        }
    }
}

// MARK: - Widget Bundle

@main
struct AgendaWidgetBundle: WidgetBundle {
    var body: some Widget {
        AgendaLiveActivity()
    }
}

// MARK: - Preview

#Preview("Live Activity", as: .content, using: AgendaAttributes(userName: "健康助手")) {
    AgendaLiveActivity()
} contentStates: {
    AgendaAttributes.ContentState(
        temperature: "17",
        feelsLike: "17",
        weatherDescription: "晴朗",
        humidity: "56",
        windSpeed: "10",
        weatherCode: "113",
        updateTime: Date()
    )

    AgendaAttributes.ContentState(
        temperature: "8",
        feelsLike: "5",
        weatherDescription: "紧急任务",
        humidity: "25",
        windSpeed: "3",
        weatherCode: "395",
        updateTime: Date()
    )
}
