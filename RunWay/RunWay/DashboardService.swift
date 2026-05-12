import Foundation

struct DashboardService {
    private let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    /// `latitude` + `longitude` gönderildiğinde backend en yakın mahalleyi seçer.
    /// `neighborhoodId` verilirse doğrudan o mahalle kullanılır (konum gönderilmemeli).
    func fetchHome(
        neighborhoodId: Int? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        token: String
    ) async throws -> DashboardHomeResponse {
        var items: [URLQueryItem] = []
        if let neighborhoodId {
            items.append(URLQueryItem(name: "neighborhood_id", value: String(neighborhoodId)))
        }
        if let latitude {
            items.append(URLQueryItem(name: "latitude", value: String(latitude)))
        }
        if let longitude {
            items.append(URLQueryItem(name: "longitude", value: String(longitude)))
        }

        let path = "/dashboard/home"
        if var components = URLComponents(string: APIConfig.baseURL + path) {
            if !items.isEmpty {
                components.queryItems = items
            }
            RunWayDebugLog.neighborhood("/dashboard/home full request URL: \(components.url?.absoluteString ?? "(invalid)")")
        }

        let paramSummary: String
        let hasExplicitNeighborhoodId: Bool
        if let neighborhoodId {
            paramSummary = "neighborhood_id=\(neighborhoodId) (lat/lon omitted by client when manual)"
            hasExplicitNeighborhoodId = true
        } else {
            let latStr = latitude.map { String(describing: $0) } ?? "nil"
            let lonStr = longitude.map { String(describing: $0) } ?? "nil"
            paramSummary =
                "latitude=\(latStr) longitude=\(lonStr) neighborhood_id=<absent>"
            hasExplicitNeighborhoodId = false
        }
        RunWayDebugLog.neighborhood("/dashboard/home query params: \(paramSummary)")
        if !hasExplicitNeighborhoodId && (latitude == nil || longitude == nil) {
            RunWayDebugLog.neighborhood(
                "WARNING both lat/lon not sent → backend falls back to first/preferred neighborhood (often id=1)"
            )
        }

        let decoded: DashboardHomeResponse = try await apiClient.get(path: path, queryItems: items, token: token)
        let loc = decoded.location
        print(decoded)
        RunWayDebugLog.neighborhood(
            "/dashboard/home response.location: neighborhood_id=\(loc.neighborhoodId) name=\(loc.neighborhoodName) "
                + "city=\(loc.city) district=\(loc.district) lat=\(loc.latitude) lon=\(loc.longitude)"
        )
        return decoded
    }
}
