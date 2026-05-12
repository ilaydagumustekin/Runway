import Foundation

struct FavoritesService {
    private let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    func getFavorites(token: String) async throws -> [FavoriteNeighborhoodResponse] {
        try await apiClient.getArray(path: "/favorites", queryItems: [], token: token)
    }

    func addFavorite(neighborhoodId: Int, token: String) async throws -> FavoriteNeighborhoodResponse {
        try await apiClient.post(path: "/favorites/\(neighborhoodId)", token: token)
    }

    func removeFavorite(neighborhoodId: Int, token: String) async throws {
        _ = try await apiClient.delete(path: "/favorites/\(neighborhoodId)", token: token) as EmptyAPIResponse
    }
}
