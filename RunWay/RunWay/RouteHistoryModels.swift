import Foundation

struct RouteHistoryItem: Decodable, Identifiable, Equatable {
    let id: Int
    let userId: Int?
    let routeName: String
    let startLatitude: Double?
    let startLongitude: Double?
    let destinationLatitude: Double?
    let destinationLongitude: Double?
    let estimatedDurationMinutes: Int?
    let environmentalScore: Double?
    let isFavorite: Bool
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case routeName = "route_name"
        case startLatitude = "start_latitude"
        case startLongitude = "start_longitude"
        case destinationLatitude = "destination_latitude"
        case destinationLongitude = "destination_longitude"
        case estimatedDurationMinutes = "estimated_duration_minutes"
        case environmentalScore = "environmental_score"
        case isFavorite = "is_favorite"
        case createdAt = "created_at"
    }

    init(
        id: Int,
        userId: Int? = nil,
        routeName: String,
        startLatitude: Double? = nil,
        startLongitude: Double? = nil,
        destinationLatitude: Double? = nil,
        destinationLongitude: Double? = nil,
        estimatedDurationMinutes: Int? = nil,
        environmentalScore: Double? = nil,
        isFavorite: Bool,
        createdAt: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.routeName = routeName
        self.startLatitude = startLatitude
        self.startLongitude = startLongitude
        self.destinationLatitude = destinationLatitude
        self.destinationLongitude = destinationLongitude
        self.estimatedDurationMinutes = estimatedDurationMinutes
        self.environmentalScore = environmentalScore
        self.isFavorite = isFavorite
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(Int.self, forKey: .id)
        userId = RouteHistoryItem.decodeFlexibleIntIfPresent(container, forKey: .userId)
        routeName = (try? container.decode(String.self, forKey: .routeName)) ?? "Rota"
        startLatitude = try container.decodeFlexibleDoubleIfPresent(forKey: .startLatitude)
        startLongitude = try container.decodeFlexibleDoubleIfPresent(forKey: .startLongitude)
        destinationLatitude = try container.decodeFlexibleDoubleIfPresent(forKey: .destinationLatitude)
        destinationLongitude = try container.decodeFlexibleDoubleIfPresent(forKey: .destinationLongitude)
        estimatedDurationMinutes = RouteHistoryItem.decodeFlexibleIntIfPresent(container, forKey: .estimatedDurationMinutes)
        environmentalScore = try container.decodeFlexibleDoubleIfPresent(forKey: .environmentalScore)
        isFavorite = (try? container.decode(Bool.self, forKey: .isFavorite)) ?? false
        createdAt = try? container.decodeIfPresent(String.self, forKey: .createdAt)
    }

    private static func decodeFlexibleIntIfPresent(
        _ container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) -> Int? {
        if let intValue = try? container.decode(Int.self, forKey: key) {
            return intValue
        }

        if let doubleValue = try? container.decode(Double.self, forKey: key) {
            return Int(doubleValue.rounded())
        }

        if let stringValue = try? container.decode(String.self, forKey: key) {
            return Int(stringValue)
        }

        return nil
    }
}
