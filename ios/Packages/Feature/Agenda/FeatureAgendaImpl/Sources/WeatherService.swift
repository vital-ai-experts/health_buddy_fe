import Foundation

/// Service for fetching weather data
actor WeatherService {
    private let baseURL = "https://wttr.in"

    /// Fetch weather for Shanghai
    /// - Returns: Weather description string
    func fetchShanghaiWeather() async throws -> String {
        let urlString = "\(baseURL)/Shanghai?format=%C+%t"
        guard let url = URL(string: urlString) else {
            throw WeatherError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw WeatherError.networkError
        }

        guard let weatherText = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            throw WeatherError.invalidData
        }

        return weatherText
    }

    /// Fetch weather with fallback to mock data
    func fetchWeatherSafely() async -> String {
        do {
            return try await fetchShanghaiWeather()
        } catch {
            print("⚠️ Failed to fetch weather: \(error), using mock data")
            return mockWeather()
        }
    }

    /// Generate mock weather data
    private func mockWeather() -> String {
        let conditions = ["Sunny ☀️", "Cloudy ☁️", "Rainy 🌧️", "Partly cloudy ⛅️"]
        let temperatures = ["22°C", "18°C", "25°C", "20°C", "16°C"]

        let condition = conditions.randomElement() ?? "Sunny ☀️"
        let temp = temperatures.randomElement() ?? "20°C"

        return "\(condition) \(temp)"
    }
}

enum WeatherError: LocalizedError {
    case invalidURL
    case networkError
    case invalidData

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid weather API URL"
        case .networkError:
            return "Network request failed"
        case .invalidData:
            return "Invalid weather data received"
        }
    }
}
