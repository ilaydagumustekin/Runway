import Foundation

struct NeighborhoodDetailService {
    private let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    func fetchDetails(neighborhoodId: Int) async throws -> NeighborhoodDetailResponse {
        try await apiClient.get(
            path: "/neighborhoods/\(neighborhoodId)/details",
            queryItems: [],
            token: nil
        )
    }
}
