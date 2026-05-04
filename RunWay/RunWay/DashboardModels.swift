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
    let updatedAt: Date?

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
}

struct HourlyWeatherItem: Decodable, Identifiable {
    let time: String
    let temperature: Int
    let condition: String

    var id: String { time }
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
    let startedAt: Date

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
