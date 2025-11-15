import Foundation

// MARK: - Mock API Response Models (使用天气API作为测试数据)

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

// MARK: - Agenda Widget Display Model

struct AgendaData: Codable {
    // 使用天气数据字段作为mock数据
    // 未来替换成真实的健康任务数据
    let temperature: String      // Mock: 可改为任务数量
    let feelsLike: String        // Mock: 可改为紧急任务数量
    let weatherDescription: String // Mock: 可改为主要任务描述
    let humidity: String         // Mock: 可改为完成率
    let windSpeed: String        // Mock: 可改为待办数量
    let weatherCode: String      // Mock: 可改为任务类型代码
    let location: String         // Mock: 可改为用户名称
    let updateTime: Date

    var agendaEmoji: String {
        // 任务类型 emoji 映射（目前使用天气代码mock）
        // 未来可以改成真实的任务类型映射
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

    static var placeholder: AgendaData {
        AgendaData(
            temperature: "--",
            feelsLike: "--",
            weatherDescription: "加载中...",
            humidity: "--",
            windSpeed: "--",
            weatherCode: "113",
            location: "健康助手",
            updateTime: Date()
        )
    }
}
