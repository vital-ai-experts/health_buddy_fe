import Foundation

enum WeatherServiceError: Error {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case noData
}

actor WeatherService {
    static let shared = WeatherService()

    private let baseURL = "https://wttr.in/Shanghai?format=j1"
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 15
        config.waitsForConnectivity = false
        self.session = URLSession(configuration: config)
    }

    func fetchWeather() async throws -> WeatherData {
        guard let url = URL(string: baseURL) else {
            throw WeatherServiceError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw WeatherServiceError.noData
        }

        do {
            let weatherResponse = try JSONDecoder().decode(WeatherResponse.self, from: data)
            return parseWeatherData(from: weatherResponse)
        } catch {
            print("Weather decoding error: \(error)")
            throw WeatherServiceError.decodingError(error)
        }
    }

    private func parseWeatherData(from response: WeatherResponse) -> WeatherData {
        guard let current = response.currentCondition.first else {
            return WeatherData.placeholder
        }

        let location = response.nearestArea.first?.areaName.first?.value ?? "上海"

        return WeatherData(
            temperature: current.temp,
            feelsLike: current.feelsLike,
            weatherDescription: current.weatherDesc.first?.value ?? "未知",
            humidity: current.humidity,
            windSpeed: current.windspeedKmph,
            weatherCode: current.weatherCode,
            location: location,
            updateTime: Date()
        )
    }
}
