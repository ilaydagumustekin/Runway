import Foundation

struct RouteHistoryItem: Decodable, Identifiable {
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
}
