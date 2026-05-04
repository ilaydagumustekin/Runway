import Foundation

struct DashboardService {
    private let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    func fetchHome(neighborhoodId: Int, token: String) async throws -> DashboardHomeResponse {
        try await apiClient.get(
            path: "/dashboard/home",
            queryItems: [URLQueryItem(name: "neighborhood_id", value: String(neighborhoodId))],
            token: token
        )
    }
}
