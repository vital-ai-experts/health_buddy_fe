import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct AgendaEntry: TimelineEntry {
    let date: Date
    let agendaData: AgendaData
}

// MARK: - Timeline Provider

struct AgendaTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> AgendaEntry {
        AgendaEntry(date: Date(), agendaData: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (AgendaEntry) -> Void) {
        let entry = AgendaEntry(date: Date(), agendaData: .placeholder)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AgendaEntry>) -> Void) {
        Task {
            var entries: [AgendaEntry] = []
            let currentDate = Date()

            do {
                // Fetch agenda data (mock: 使用天气API)
                let agendaData = try await AgendaService.shared.fetchAgenda()

                // Create entry for current time
                let entry = AgendaEntry(date: currentDate, agendaData: agendaData)
                entries.append(entry)

                // Schedule next update in 5 minutes
                let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: currentDate)!
                let timeline = Timeline(entries: entries, policy: .after(nextUpdate))

                completion(timeline)
            } catch {
                print("Failed to fetch agenda: \(error)")

                // Use placeholder data on error
                let entry = AgendaEntry(date: currentDate, agendaData: .placeholder)
                entries.append(entry)

                // Retry in 5 minutes
                let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: currentDate)!
                let timeline = Timeline(entries: entries, policy: .after(nextUpdate))

                completion(timeline)
            }
        }
    }
}

// MARK: - Widget View

struct AgendaWidgetView: View {
    var entry: AgendaEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            CircularAgendaView(agendaData: entry.agendaData)
        case .accessoryRectangular:
            RectangularAgendaView(agendaData: entry.agendaData)
        case .accessoryInline:
            InlineAgendaView(agendaData: entry.agendaData)
        case .systemSmall:
            SystemAgendaView(agendaData: entry.agendaData)
        case .systemMedium:
            MediumAgendaView(agendaData: entry.agendaData)
        case .systemLarge:
            LargeAgendaView(agendaData: entry.agendaData)
        default:
            SystemAgendaView(agendaData: entry.agendaData)
        }
    }
}

// MARK: - Lock Screen Widget Views

struct CircularAgendaView: View {
    let agendaData: AgendaData

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 2) {
                Text(agendaData.agendaEmoji)
                    .font(.system(size: 24))
                Text("\(agendaData.temperature)°")
                    .font(.system(size: 16, weight: .semibold))
                    .minimumScaleFactor(0.8)
            }
        }
    }
}

struct RectangularAgendaView: View {
    let agendaData: AgendaData

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(agendaData.agendaEmoji)
                    .font(.system(size: 20))
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(agendaData.location) · \(agendaData.temperature)°C")
                        .font(.system(size: 14, weight: .semibold))
                    Text(agendaData.weatherDescription)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 12) {
                Label("\(agendaData.humidity)%", systemImage: "humidity.fill")
                    .font(.system(size: 10))
                Label("\(agendaData.windSpeed)km/h", systemImage: "wind")
                    .font(.system(size: 10))
                Spacer()
                Text(agendaData.formattedUpdateTime)
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct InlineAgendaView: View {
    let agendaData: AgendaData

    var body: some View {
        Text("\(agendaData.agendaEmoji) \(agendaData.location) \(agendaData.temperature)°C")
    }
}

// MARK: - System Widget Views (for home screen & StandBy)

// Small Widget (小组件)
struct SystemAgendaView: View {
    let agendaData: AgendaData

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.6), Color.blue.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 8) {
                HStack {
                    Text(agendaData.location)
                        .font(.headline)
                    Spacer()
                }

                HStack(alignment: .top, spacing: 12) {
                    Text(agendaData.agendaEmoji)
                        .font(.system(size: 60))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(agendaData.temperature)°C")
                            .font(.system(size: 40, weight: .bold))
                        Text("体感 \(agendaData.feelsLike)°C")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(agendaData.weatherDescription)
                        .font(.subheadline)

                    HStack(spacing: 20) {
                        Label("湿度 \(agendaData.humidity)%", systemImage: "humidity.fill")
                            .font(.caption)
                        Label("风速 \(agendaData.windSpeed)km/h", systemImage: "wind")
                            .font(.caption)
                    }

                    HStack {
                        Spacer()
                        Text("更新: \(agendaData.formattedUpdateTime)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }
            .padding()
        }
    }
}

// Medium Widget (中等组件 - 用于待机显示)
struct MediumAgendaView: View {
    let agendaData: AgendaData

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.6), Color.blue.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            HStack(spacing: 16) {
                // 左侧：大图标和温度
                VStack(spacing: 12) {
                    Text(agendaData.agendaEmoji)
                        .font(.system(size: 80))

                    Text("\(agendaData.temperature)°C")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .background(.white.opacity(0.3))

                // 右侧：详细信息
                VStack(alignment: .leading, spacing: 12) {
                    Text(agendaData.location)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(agendaData.weatherDescription)
                        .font(.title3)
                        .foregroundStyle(.secondary)

                    Spacer()

                    VStack(alignment: .leading, spacing: 8) {
                        Label("体感 \(agendaData.feelsLike)°C", systemImage: "thermometer")
                            .font(.body)
                        Label("湿度 \(agendaData.humidity)%", systemImage: "humidity.fill")
                            .font(.body)
                        Label("风速 \(agendaData.windSpeed)km/h", systemImage: "wind")
                            .font(.body)
                    }

                    HStack {
                        Spacer()
                        Text("更新: \(agendaData.formattedUpdateTime)")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
        }
    }
}

// Large Widget (大组件 - 全宽，用于待机显示)
struct LargeAgendaView: View {
    let agendaData: AgendaData

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.7),
                    Color.cyan.opacity(0.5),
                    Color.blue.opacity(0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 20) {
                // 顶部：位置和时间
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(agendaData.location)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("健康任务")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text(agendaData.formattedUpdateTime)
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }

                // 中间：大图标和主要数据
                HStack(alignment: .center, spacing: 24) {
                    Text(agendaData.agendaEmoji)
                        .font(.system(size: 120))
                        .shadow(radius: 10)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(agendaData.temperature)°C")
                            .font(.system(size: 72, weight: .bold))
                            .foregroundColor(.white)

                        Text("体感 \(agendaData.feelsLike)°C")
                            .font(.title)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }

                // 底部：详细信息卡片
                VStack(spacing: 16) {
                    Text(agendaData.weatherDescription)
                        .font(.title2)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 24) {
                        InfoCard(
                            icon: "thermometer",
                            title: "体感温度",
                            value: "\(agendaData.feelsLike)°C"
                        )

                        InfoCard(
                            icon: "humidity.fill",
                            title: "湿度",
                            value: "\(agendaData.humidity)%"
                        )

                        InfoCard(
                            icon: "wind",
                            title: "风速",
                            value: "\(agendaData.windSpeed) km/h"
                        )
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(16)

                Spacer()
            }
            .padding(24)
        }
    }
}

// 辅助组件：信息卡片
struct InfoCard: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Widget Configuration

struct AgendaWidget: Widget {
    let kind: String = "AgendaWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AgendaTimelineProvider()) { entry in
            AgendaWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("健康任务")
        .description("实时显示你的健康任务和待办事项，每5分钟自动更新")
        .supportedFamilies([
            // 锁屏卡片样式
            .accessoryCircular,      // 圆形卡片
            .accessoryRectangular,   // 矩形卡片
            .accessoryInline,        // 内联卡片
            // 主屏幕和待机显示样式
            .systemSmall,            // 小组件
            .systemMedium,           // 中等组件
            .systemLarge             // 大组件（全宽，用于待机显示）
        ])
    }
}

// MARK: - Widget Bundle

@main
struct AgendaWidgetBundle: WidgetBundle {
    var body: some Widget {
        AgendaWidget()
    }
}

// MARK: - Preview

#Preview(as: .accessoryRectangular) {
    AgendaWidget()
} timeline: {
    AgendaEntry(date: .now, agendaData: AgendaData(
        temperature: "17",
        feelsLike: "17",
        weatherDescription: "晴朗",
        humidity: "56",
        windSpeed: "10",
        weatherCode: "113",
        location: "健康助手",
        updateTime: Date()
    ))
}

#Preview(as: .accessoryCircular) {
    AgendaWidget()
} timeline: {
    AgendaEntry(date: .now, agendaData: AgendaData(
        temperature: "17",
        feelsLike: "17",
        weatherDescription: "晴朗",
        humidity: "56",
        windSpeed: "10",
        weatherCode: "113",
        location: "健康助手",
        updateTime: Date()
    ))
}

#Preview(as: .systemSmall) {
    AgendaWidget()
} timeline: {
    AgendaEntry(date: .now, agendaData: AgendaData(
        temperature: "17",
        feelsLike: "17",
        weatherDescription: "晴朗",
        humidity: "56",
        windSpeed: "10",
        weatherCode: "113",
        location: "健康助手",
        updateTime: Date()
    ))
}

#Preview(as: .systemMedium) {
    AgendaWidget()
} timeline: {
    AgendaEntry(date: .now, agendaData: AgendaData(
        temperature: "17",
        feelsLike: "17",
        weatherDescription: "晴朗",
        humidity: "56",
        windSpeed: "10",
        weatherCode: "113",
        location: "健康助手",
        updateTime: Date()
    ))
}

#Preview(as: .systemLarge) {
    AgendaWidget()
} timeline: {
    AgendaEntry(date: .now, agendaData: AgendaData(
        temperature: "17",
        feelsLike: "17",
        weatherDescription: "晴朗",
        humidity: "56",
        windSpeed: "10",
        weatherCode: "113",
        location: "健康助手",
        updateTime: Date()
    ))
}
