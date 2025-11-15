import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct WeatherEntry: TimelineEntry {
    let date: Date
    let weatherData: WeatherData
}

// MARK: - Timeline Provider

struct WeatherTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> WeatherEntry {
        WeatherEntry(date: Date(), weatherData: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (WeatherEntry) -> Void) {
        let entry = WeatherEntry(date: Date(), weatherData: .placeholder)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WeatherEntry>) -> Void) {
        Task {
            var entries: [WeatherEntry] = []
            let currentDate = Date()

            do {
                // Fetch weather data
                let weatherData = try await WeatherService.shared.fetchWeather()

                // Create entry for current time
                let entry = WeatherEntry(date: currentDate, weatherData: weatherData)
                entries.append(entry)

                // Schedule next update in 5 minutes
                let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: currentDate)!
                let timeline = Timeline(entries: entries, policy: .after(nextUpdate))

                completion(timeline)
            } catch {
                print("Failed to fetch weather: \(error)")

                // Use placeholder data on error
                let entry = WeatherEntry(date: currentDate, weatherData: .placeholder)
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

struct WeatherWidgetView: View {
    var entry: WeatherEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            CircularWidgetView(weatherData: entry.weatherData)
        case .accessoryRectangular:
            RectangularWidgetView(weatherData: entry.weatherData)
        case .accessoryInline:
            InlineWidgetView(weatherData: entry.weatherData)
        default:
            // For system small/medium/large widgets
            SystemWidgetView(weatherData: entry.weatherData)
        }
    }
}

// MARK: - Lock Screen Widget Views

struct CircularWidgetView: View {
    let weatherData: WeatherData

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 2) {
                Text(weatherData.weatherEmoji)
                    .font(.system(size: 24))
                Text("\(weatherData.temperature)°")
                    .font(.system(size: 16, weight: .semibold))
                    .minimumScaleFactor(0.8)
            }
        }
    }
}

struct RectangularWidgetView: View {
    let weatherData: WeatherData

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(weatherData.weatherEmoji)
                    .font(.system(size: 20))
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(weatherData.location) · \(weatherData.temperature)°C")
                        .font(.system(size: 14, weight: .semibold))
                    Text(weatherData.weatherDescription)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 12) {
                Label("\(weatherData.humidity)%", systemImage: "humidity.fill")
                    .font(.system(size: 10))
                Label("\(weatherData.windSpeed)km/h", systemImage: "wind")
                    .font(.system(size: 10))
                Spacer()
                Text(weatherData.formattedUpdateTime)
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct InlineWidgetView: View {
    let weatherData: WeatherData

    var body: some View {
        Text("\(weatherData.weatherEmoji) \(weatherData.location) \(weatherData.temperature)°C")
    }
}

// MARK: - System Widget View (for home screen)

struct SystemWidgetView: View {
    let weatherData: WeatherData

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.6), Color.blue.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 8) {
                HStack {
                    Text(weatherData.location)
                        .font(.headline)
                    Spacer()
                }

                HStack(alignment: .top, spacing: 12) {
                    Text(weatherData.weatherEmoji)
                        .font(.system(size: 60))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(weatherData.temperature)°C")
                            .font(.system(size: 40, weight: .bold))
                        Text("体感 \(weatherData.feelsLike)°C")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(weatherData.weatherDescription)
                        .font(.subheadline)

                    HStack(spacing: 20) {
                        Label("湿度 \(weatherData.humidity)%", systemImage: "humidity.fill")
                            .font(.caption)
                        Label("风速 \(weatherData.windSpeed)km/h", systemImage: "wind")
                            .font(.caption)
                    }

                    HStack {
                        Spacer()
                        Text("更新: \(weatherData.formattedUpdateTime)")
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

struct WeatherWidget: Widget {
    let kind: String = "WeatherWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WeatherTimelineProvider()) { entry in
            WeatherWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("上海天气")
        .description("实时显示上海的天气信息，每5分钟自动更新")
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
struct WeatherWidgetBundle: WidgetBundle {
    var body: some Widget {
        WeatherWidget()
    }
}

// MARK: - Preview

#Preview(as: .accessoryRectangular) {
    WeatherWidget()
} timeline: {
    WeatherEntry(date: .now, weatherData: WeatherData(
        temperature: "17",
        feelsLike: "17",
        weatherDescription: "晴朗",
        humidity: "56",
        windSpeed: "10",
        weatherCode: "113",
        location: "上海",
        updateTime: Date()
    ))
}

#Preview(as: .accessoryCircular) {
    WeatherWidget()
} timeline: {
    WeatherEntry(date: .now, weatherData: WeatherData(
        temperature: "17",
        feelsLike: "17",
        weatherDescription: "晴朗",
        humidity: "56",
        windSpeed: "10",
        weatherCode: "113",
        location: "上海",
        updateTime: Date()
    ))
}

#Preview(as: .systemSmall) {
    WeatherWidget()
} timeline: {
    WeatherEntry(date: .now, weatherData: WeatherData(
        temperature: "17",
        feelsLike: "17",
        weatherDescription: "晴朗",
        humidity: "56",
        windSpeed: "10",
        weatherCode: "113",
        location: "上海",
        updateTime: Date()
    ))
}
