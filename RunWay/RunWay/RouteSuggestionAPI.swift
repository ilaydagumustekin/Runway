import CoreLocation
import Foundation

/// Backend `POST /routes/recommend` yanıtı (snake_case).
struct RouteRecommendAPIResponse: Decodable {
    let routeName: String
    let estimatedDurationMinutes: Int
    let environmentalScore: Double
    let path: [CoordinatePoint]
    let distanceKm: Double
    let transportMode: String
    let speedKmh: Double

    enum CodingKeys: String, CodingKey {
        case routeName = "route_name"
        case estimatedDurationMinutes = "estimated_duration_minutes"
        case environmentalScore = "environmental_score"
        case path
        case distanceKm = "distance_km"
        case transportMode = "transport_mode"
        case speedKmh = "speed_kmh"
    }

    struct CoordinatePoint: Decodable {
        let latitude: Double
        let longitude: Double
    }

    var pathCoordinates: [CLLocationCoordinate2D] {
        path.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
    }
}

enum RouteRecommendationService {
    private static let apiClient = APIClient.shared

    static func fetchRecommendation(
        start: CLLocationCoordinate2D,
        destination: CLLocationCoordinate2D,
        transportMode: String = "walking",
        token: String? = nil
    ) async throws -> RouteRecommendAPIResponse {
        struct Body: Encodable {
            let start: Coord
            let destination: Coord
            let transport_mode: String

            struct Coord: Encodable {
                let latitude: Double
                let longitude: Double
            }
        }

        RunWayDebugLog.route("route request transport_mode=\(transportMode)")

        let body = Body(
            start: .init(latitude: start.latitude, longitude: start.longitude),
            destination: .init(latitude: destination.latitude, longitude: destination.longitude),
            transport_mode: transportMode
        )

        let response: RouteRecommendAPIResponse = try await apiClient.post(
            path: "/routes/recommend",
            body: body,
            token: token
        )

        RunWayDebugLog.route(
            "route response distance_km=\(response.distanceKm)" +
            " duration_minutes=\(response.estimatedDurationMinutes)"
        )

        return response
    }
}
