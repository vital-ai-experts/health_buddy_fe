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
        default:
            // For system small/medium/large widgets
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

// MARK: - System Widget View (for home screen)

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
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
            .systemSmall,
            .systemMedium
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
