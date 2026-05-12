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

    init(
        location: DashboardLocation,
        environmentScore: EnvironmentScore,
        quickMetrics: QuickMetrics,
        currentEnvironment: [CurrentEnvironmentItem],
        hourlyWeather: [HourlyWeatherItem],
        notifications: DashboardNotifications,
        navigation: DashboardNavigation
    ) {
        self.location = location
        self.environmentScore = environmentScore
        self.quickMetrics = quickMetrics
        self.currentEnvironment = currentEnvironment
        self.hourlyWeather = hourlyWeather
        self.notifications = notifications
        self.navigation = navigation
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        location = try container.decodeIfPresent(DashboardLocation.self, forKey: .location) ?? DashboardLocation()
        environmentScore = try container.decodeIfPresent(EnvironmentScore.self, forKey: .environmentScore) ?? EnvironmentScore()
        quickMetrics = try container.decodeIfPresent(QuickMetrics.self, forKey: .quickMetrics) ?? QuickMetrics()
        currentEnvironment = try container.decodeIfPresent([CurrentEnvironmentItem].self, forKey: .currentEnvironment) ?? []
        hourlyWeather = try container.decodeIfPresent([HourlyWeatherItem].self, forKey: .hourlyWeather) ?? []
        notifications = try container.decodeIfPresent(DashboardNotifications.self, forKey: .notifications) ?? DashboardNotifications()
        navigation = try container.decodeIfPresent(DashboardNavigation.self, forKey: .navigation) ?? DashboardNavigation()
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

    init(
        neighborhoodId: Int = 0,
        neighborhoodName: String = "",
        city: String = "",
        district: String = "",
        latitude: Double = 0,
        longitude: Double = 0
    ) {
        self.neighborhoodId = neighborhoodId
        self.neighborhoodName = neighborhoodName
        self.city = city
        self.district = district
        self.latitude = latitude
        self.longitude = longitude
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        neighborhoodId = try container.decodeIfPresent(Int.self, forKey: .neighborhoodId) ?? 0
        neighborhoodName = try container.decodeIfPresent(String.self, forKey: .neighborhoodName) ?? ""
        city = try container.decodeIfPresent(String.self, forKey: .city) ?? ""
        district = try container.decodeIfPresent(String.self, forKey: .district) ?? ""
        latitude = try container.decodeFlexibleDoubleIfPresent(forKey: .latitude) ?? 0
        longitude = try container.decodeFlexibleDoubleIfPresent(forKey: .longitude) ?? 0
    }
}

struct EnvironmentScore: Decodable {
    let score: Double
    let category: String
    let categoryKey: String
    let lastUpdatedText: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case score
        case category
        case categoryKey = "category_key"
        case lastUpdatedText = "last_updated_text"
        case updatedAt = "updated_at"
    }

    init(
        score: Double = 0,
        category: String = "",
        categoryKey: String = "",
        lastUpdatedText: String = "",
        updatedAt: String = ""
    ) {
        self.score = score
        self.category = category
        self.categoryKey = categoryKey
        self.lastUpdatedText = lastUpdatedText
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        score = try container.decodeFlexibleDoubleIfPresent(forKey: .score) ?? 0
        category = try container.decodeIfPresent(String.self, forKey: .category) ?? ""
        categoryKey = try container.decodeIfPresent(String.self, forKey: .categoryKey) ?? ""
        lastUpdatedText = try container.decodeIfPresent(String.self, forKey: .lastUpdatedText) ?? ""
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt) ?? ""
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

    init(
        airQuality: MetricItem = MetricItem(),
        noise: MetricItem = MetricItem(),
        greenArea: MetricItem = MetricItem()
    ) {
        self.airQuality = airQuality
        self.noise = noise
        self.greenArea = greenArea
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        airQuality = try container.decodeIfPresent(MetricItem.self, forKey: .airQuality) ?? MetricItem()
        noise = try container.decodeIfPresent(MetricItem.self, forKey: .noise) ?? MetricItem()
        greenArea = try container.decodeIfPresent(MetricItem.self, forKey: .greenArea) ?? MetricItem()
    }
}

extension QuickMetrics {
    /// Dashboard henüz yokken mini metriklerde etiketleri göstermek için; değerler `HomeView` içinde `—` olarak gösterilir.
    static var waitingForDashboard: QuickMetrics {
        QuickMetrics(
            airQuality: MetricItem(label: "Hava", value: 0, unit: "AQI"),
            noise: MetricItem(label: "Gürültü", value: 0, unit: "dB"),
            greenArea: MetricItem(label: "Yeşil", value: 0, unit: "%")
        )
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

    init(label: String = "", value: Double = 0, unit: String = "") {
        self.label = label
        self.value = value
        self.unit = unit
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        label = try container.decodeIfPresent(String.self, forKey: .label) ?? ""
        value = try container.decodeFlexibleDoubleIfPresent(forKey: .value) ?? 0
        unit = try container.decodeIfPresent(String.self, forKey: .unit) ?? ""
    }
}

struct CurrentEnvironmentItem: Decodable, Identifiable {
    let key: String
    let title: String
    let value: Double
    let unit: String?
    let status: String?
    let statusKey: String?

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
        unit: String?,
        status: String?,
        statusKey: String?
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
        unit = try container.decodeIfPresent(String.self, forKey: .unit)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        statusKey = try container.decodeIfPresent(String.self, forKey: .statusKey)
    }
}

struct HourlyWeatherItem: Decodable, Identifiable {
    let time: String
    let temperature: Double
    let condition: String?

    var id: String { time }

    enum CodingKeys: String, CodingKey {
        case time
        case temperature
        case condition
    }

    init(time: String = "", temperature: Double = 0, condition: String? = nil) {
        self.time = time
        self.temperature = temperature
        self.condition = condition
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        time = try container.decode(String.self, forKey: .time)
        temperature = try container.decodeFlexibleDouble(forKey: .temperature)
        condition = try container.decodeIfPresent(String.self, forKey: .condition)
    }
}

struct DashboardNotifications: Decodable {
    let unreadCount: Int

    enum CodingKeys: String, CodingKey {
        case unreadCount = "unread_count"
    }

    init(unreadCount: Int = 0) {
        self.unreadCount = unreadCount
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        unreadCount = try container.decodeFlexibleIntIfPresent(forKey: .unreadCount) ?? 0
    }
}

struct DashboardNavigation: Decodable {
    let hasActiveRoute: Bool
    let activeRoute: ActiveRoute?

    enum CodingKeys: String, CodingKey {
        case hasActiveRoute = "has_active_route"
        case activeRoute = "active_route"
    }

    init(hasActiveRoute: Bool = false, activeRoute: ActiveRoute? = nil) {
        self.hasActiveRoute = hasActiveRoute
        self.activeRoute = activeRoute
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        hasActiveRoute = try container.decodeFlexibleBool(forKey: .hasActiveRoute, default: false)
        activeRoute = try container.decodeIfPresent(ActiveRoute.self, forKey: .activeRoute)
    }
}

struct ActiveRoute: Decodable {
    let navigationSessionId: Int?
    let routeName: String?
    let startLatitude: Double?
    let startLongitude: Double?
    let destinationLatitude: Double?
    let destinationLongitude: Double?
    let startedAt: String?

    enum CodingKeys: String, CodingKey {
        case navigationSessionId = "navigation_session_id"
        case routeName = "route_name"
        case startLatitude = "start_latitude"
        case startLongitude = "start_longitude"
        case destinationLatitude = "destination_latitude"
        case destinationLongitude = "destination_longitude"
        case startedAt = "started_at"
    }

    init(
        navigationSessionId: Int? = nil,
        routeName: String? = nil,
        startLatitude: Double? = nil,
        startLongitude: Double? = nil,
        destinationLatitude: Double? = nil,
        destinationLongitude: Double? = nil,
        startedAt: String? = nil
    ) {
        self.navigationSessionId = navigationSessionId
        self.routeName = routeName
        self.startLatitude = startLatitude
        self.startLongitude = startLongitude
        self.destinationLatitude = destinationLatitude
        self.destinationLongitude = destinationLongitude
        self.startedAt = startedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        navigationSessionId = try container.decodeIfPresent(Int.self, forKey: .navigationSessionId)
        routeName = try container.decodeIfPresent(String.self, forKey: .routeName)
        startLatitude = try container.decodeFlexibleDoubleIfPresent(forKey: .startLatitude)
        startLongitude = try container.decodeFlexibleDoubleIfPresent(forKey: .startLongitude)
        destinationLatitude = try container.decodeFlexibleDoubleIfPresent(forKey: .destinationLatitude)
        destinationLongitude = try container.decodeFlexibleDoubleIfPresent(forKey: .destinationLongitude)
        startedAt = try container.decodeIfPresent(String.self, forKey: .startedAt)
    }
}
