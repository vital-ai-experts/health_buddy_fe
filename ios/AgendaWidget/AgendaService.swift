import Foundation

enum AgendaServiceError: Error {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case noData
}

actor AgendaService {
    static let shared = AgendaService()

    // Mock: 使用天气API作为测试数据
    // 未来替换成真实的健康任务API
    private let baseURL = "https://wttr.in/Shanghai?format=j1"
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 15
        config.waitsForConnectivity = false
        self.session = URLSession(configuration: config)
    }

    func fetchAgenda() async throws -> AgendaData {
        guard let url = URL(string: baseURL) else {
            throw AgendaServiceError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AgendaServiceError.noData
        }

        do {
            let weatherResponse = try JSONDecoder().decode(WeatherResponse.self, from: data)
            return parseAgendaData(from: weatherResponse)
        } catch {
            print("Agenda decoding error: \(error)")
            throw AgendaServiceError.decodingError(error)
        }
    }

    private func parseAgendaData(from response: WeatherResponse) -> AgendaData {
        guard let current = response.currentCondition.first else {
            return AgendaData.placeholder
        }

        let location = response.nearestArea.first?.areaName.first?.value ?? "健康助手"

        // Mock: 使用天气数据映射为健康任务数据
        return AgendaData(
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
