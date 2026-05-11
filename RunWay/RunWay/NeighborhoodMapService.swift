import Foundation

struct NeighborhoodMapService {
    private let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    func fetchMarkersWithScores() async throws -> [NeighborhoodMarkerWithScore] {
        try await apiClient.get(
            path: "/map/neighborhood-markers/with-scores",
            queryItems: [],
            token: nil
        )
    }
}
