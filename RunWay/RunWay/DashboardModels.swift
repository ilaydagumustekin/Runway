import Foundation

struct DashboardHomeResponse: Decodable {
    let location: DashboardLocation
    let environmentScore: EnvironmentScore
    let quickMetrics: QuickMetrics
    let currentEnvironment: [CurrentEnvironmentItem]
    let hourlyWeather: [HourlyWeatherItem]
    let notifications: DashboardNotifications
    let navigation: DashboardNavigation

    enum CodingKeys: String, CodingKey {
        case location
        case environmentScore = "environment_score"
        case quickMetrics = "quick_metrics"
        case currentEnvironment = "current_environment"
        case hourlyWeather = "hourly_weather"
        case notifications
        case navigation
    }
}

struct DashboardLocation: Decodable {
    let neighborhoodId: Int
    let neighborhoodName: String
    let city: String
    let district: String
    let latitude: Double
    let longitude: Double

    enum CodingKeys: String, CodingKey {
        case neighborhoodId = "neighborhood_id"
        case neighborhoodName = "neighborhood_name"
        case city
        case district
        case latitude
        case longitude
    }
}

struct EnvironmentScore: Decodable {
    let score: Double
    let category: String
    let categoryKey: String
    let lastUpdatedText: String
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case score
        case category
        case categoryKey = "category_key"
        case lastUpdatedText = "last_updated_text"
        case updatedAt = "updated_at"
    }
}

struct QuickMetrics: Decodable {
    let airQuality: MetricItem
    let noise: MetricItem
    let greenArea: MetricItem

    enum CodingKeys: String, CodingKey {
        case airQuality = "air_quality"
        case noise
        case greenArea = "green_area"
    }
}

struct MetricItem: Decodable {
    let label: String
    let value: Double
    let unit: String

    enum CodingKeys: String, CodingKey {
        case label
        case value
        case unit
    }

    init(label: String, value: Double, unit: String) {
        self.label = label
        self.value = value
        self.unit = unit
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        label = try container.decode(String.self, forKey: .label)
        value = try container.decodeFlexibleDouble(forKey: .value)
        unit = try container.decode(String.self, forKey: .unit)
    }
}

struct CurrentEnvironmentItem: Decodable, Identifiable {
    let key: String
    let title: String
    let value: Double
    let unit: String
    let status: String
    let statusKey: String

    var id: String { key }

    enum CodingKeys: String, CodingKey {
        case key
        case title
        case value
        case unit
        case status
        case statusKey = "status_key"
    }

    init(
        key: String,
        title: String,
        value: Double,
        unit: String,
        status: String,
        statusKey: String
    ) {
        self.key = key
        self.title = title
        self.value = value
        self.unit = unit
        self.status = status
        self.statusKey = statusKey
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        key = try container.decode(String.self, forKey: .key)
        title = try container.decode(String.self, forKey: .title)
        value = try container.decodeFlexibleDouble(forKey: .value)
        unit = try container.decode(String.self, forKey: .unit)
        status = try container.decode(String.self, forKey: .status)
        statusKey = try container.decode(String.self, forKey: .statusKey)
    }
}

struct HourlyWeatherItem: Decodable, Identifiable {
    let time: String
    let temperature: Double
    let condition: String

    var id: String { time }

    enum CodingKeys: String, CodingKey {
        case time
        case temperature
        case condition
    }

    init(time: String, temperature: Double, condition: String) {
        self.time = time
        self.temperature = temperature
        self.condition = condition
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        time = try container.decode(String.self, forKey: .time)
        temperature = try container.decodeFlexibleDouble(forKey: .temperature)
        condition = try container.decode(String.self, forKey: .condition)
    }
}

struct DashboardNotifications: Decodable {
    let unreadCount: Int

    enum CodingKeys: String, CodingKey {
        case unreadCount = "unread_count"
    }
}

struct DashboardNavigation: Decodable {
    let hasActiveRoute: Bool
    let activeRoute: ActiveRoute?

    enum CodingKeys: String, CodingKey {
        case hasActiveRoute = "has_active_route"
        case activeRoute = "active_route"
    }
}

struct ActiveRoute: Decodable {
    let navigationSessionId: Int
    let routeName: String
    let startLatitude: Double
    let startLongitude: Double
    let destinationLatitude: Double
    let destinationLongitude: Double
    let startedAt: String

    enum CodingKeys: String, CodingKey {
        case navigationSessionId = "navigation_session_id"
        case routeName = "route_name"
        case startLatitude = "start_latitude"
        case startLongitude = "start_longitude"
        case destinationLatitude = "destination_latitude"
        case destinationLongitude = "destination_longitude"
        case startedAt = "started_at"
    }
}

private extension KeyedDecodingContainer {
    func decodeFlexibleDouble(forKey key: Key) throws -> Double {
        if let doubleValue = try decodeIfPresent(Double.self, forKey: key) {
            return doubleValue
        }

        if let intValue = try decodeIfPresent(Int.self, forKey: key) {
            return Double(intValue)
        }

        if let stringValue = try decodeIfPresent(String.self, forKey: key),
           let doubleValue = Double(stringValue) {
            return doubleValue
        }

        throw DecodingError.typeMismatch(
            Double.self,
            DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "Expected Double-compatible value for '\(key.stringValue)'."
            )
        )
    }
}
