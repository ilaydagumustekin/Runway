import Foundation

struct RouteHistoryService {
    private let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    func getRouteHistory(token: String) async throws -> [RouteHistoryItem] {
        try await apiClient.get(path: "/route-history", token: token)
    }

    func getFavoriteRouteHistory(token: String) async throws -> [RouteHistoryItem] {
        try await apiClient.get(path: "/route-history/favorites", token: token)
    }

    func favoriteRoute(routeHistoryId: Int, token: String) async throws -> RouteHistoryItem {
        try await apiClient.patch(
            path: "/route-history/\(routeHistoryId)/favorite",
            token: token
        )
    }

    func unfavoriteRoute(routeHistoryId: Int, token: String) async throws -> RouteHistoryItem {
        try await apiClient.patch(
            path: "/route-history/\(routeHistoryId)/unfavorite",
            token: token
        )
    }
}
