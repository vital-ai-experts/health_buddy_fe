import Foundation

// MARK: - Weather API Response Models

struct WeatherResponse: Codable {
    let currentCondition: [CurrentCondition]
    let weather: [WeatherDay]
    let nearestArea: [NearestArea]

    enum CodingKeys: String, CodingKey {
        case currentCondition = "current_condition"
        case weather
        case nearestArea = "nearest_area"
    }
}

struct CurrentCondition: Codable {
    let temp: String
    let feelsLike: String
    let weatherDesc: [WeatherDesc]
    let humidity: String
    let windspeedKmph: String
    let weatherCode: String
    let weatherIconUrl: [WeatherIcon]

    enum CodingKeys: String, CodingKey {
        case temp = "temp_C"
        case feelsLike = "FeelsLikeC"
        case weatherDesc
        case humidity
        case windspeedKmph
        case weatherCode
        case weatherIconUrl
    }
}

struct WeatherDesc: Codable {
    let value: String
}

struct WeatherIcon: Codable {
    let value: String
}

struct WeatherDay: Codable {
    let date: String
    let maxtempC: String
    let mintempC: String

    enum CodingKeys: String, CodingKey {
        case date
        case maxtempC
        case mintempC
    }
}

struct NearestArea: Codable {
    let areaName: [AreaName]
    let country: [Country]

    enum CodingKeys: String, CodingKey {
        case areaName
        case country
    }
}

struct AreaName: Codable {
    let value: String
}

struct Country: Codable {
    let value: String
}

// MARK: - Widget Display Model

struct WeatherData: Codable {
    let temperature: String
    let feelsLike: String
    let weatherDescription: String
    let humidity: String
    let windSpeed: String
    let weatherCode: String
    let location: String
    let updateTime: Date

    var weatherEmoji: String {
        // Weather code to emoji mapping
        // Reference: https://www.worldweatheronline.com/developer/api/docs/weather-icons.aspx
        switch weatherCode {
        case "113": return "☀️" // Sunny/Clear
        case "116": return "⛅️" // Partly cloudy
        case "119": return "☁️" // Cloudy
        case "122": return "☁️" // Overcast
        case "143", "248", "260": return "🌫" // Mist/Fog
        case "176", "263", "266": return "🌦" // Light rain
        case "179", "182", "185", "281", "284": return "🌨" // Light snow/sleet
        case "200": return "⛈" // Thundery outbreaks
        case "227", "230": return "🌨" // Blizzard
        case "293", "296": return "🌧" // Light rain
        case "299", "302", "305", "308", "311", "314", "317", "320", "323", "326", "329", "332", "335", "338": return "🌧" // Rain/Snow
        case "350", "353", "356", "359", "362", "365", "368", "371", "374", "377": return "🌨" // Heavy snow
        case "386", "389", "392", "395": return "⛈" // Thunder
        default: return "🌤" // Default
        }
    }

    var formattedUpdateTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: updateTime)
    }

    static var placeholder: WeatherData {
        WeatherData(
            temperature: "--",
            feelsLike: "--",
            weatherDescription: "加载中...",
            humidity: "--",
            windSpeed: "--",
            weatherCode: "113",
            location: "上海",
            updateTime: Date()
        )
    }
}
