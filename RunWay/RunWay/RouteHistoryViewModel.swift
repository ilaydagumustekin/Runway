import Foundation
import Combine

@MainActor
final class RouteHistoryViewModel: ObservableObject {
    @Published var routes: [RouteHistoryItem] = []
    @Published var favoriteRoutes: [RouteHistoryItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service: RouteHistoryService
    private let authSession: AuthSession

    init() {
        self.service = RouteHistoryService()
        self.authSession = .shared
    }

    init(
        service: RouteHistoryService,
        authSession: AuthSession
    ) {
        self.service = service
        self.authSession = authSession
    }

    func loadRoutes() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        do {
            let token = try await authSession.loginIfNeeded()
            routes = try await service.getRouteHistory(token: token)
            favoriteRoutes = routes.filter(\.isFavorite)
            RunWayDebugLog.routeHistory("loaded \(routes.count) routes, \(favoriteRoutes.count) favorites")
        } catch {
            print("Route history load error:", error)
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func loadFavoriteRoutes() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        do {
            let token = try await authSession.loginIfNeeded()
            favoriteRoutes = try await service.getFavoriteRouteHistory(token: token)
            mergeFavoriteRoutesIntoRoutes()
        } catch {
            print("Favorite route history load error:", error)
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func deleteRoute(_ route: RouteHistoryItem) async {
        errorMessage = nil
        do {
            let token = try await authSession.loginIfNeeded()
            try await service.deleteRoute(routeHistoryId: route.id, token: token)
            routes.removeAll { $0.id == route.id }
            favoriteRoutes.removeAll { $0.id == route.id }
            RunWayDebugLog.routeHistory("deleted route id=\(route.id)")
        } catch {
            print("Delete route error:", error)
            errorMessage = error.localizedDescription
        }
    }

    func toggleFavorite(route: RouteHistoryItem) async {
        errorMessage = nil

        do {
            let token = try await authSession.loginIfNeeded()
            let updatedRoute: RouteHistoryItem

            if route.isFavorite {
                updatedRoute = try await service.unfavoriteRoute(routeHistoryId: route.id, token: token)
                RunWayDebugLog.routeHistory("remove from favorites only id=\(route.id) isFavorite=false")
                RunWayDebugLog.favorites("unfavorited route id=\(route.id) count=\(max(0, favoriteRoutes.count - 1))")
            } else {
                updatedRoute = try await service.favoriteRoute(routeHistoryId: route.id, token: token)
                RunWayDebugLog.routeHistory("toggle favorite id=\(route.id) isFavorite=true")
                RunWayDebugLog.favorites("favorited route id=\(route.id) count=\(favoriteRoutes.count + 1)")
            }

            updateRoute(updatedRoute)
        } catch {
            print("Toggle route favorite error:", error)
            errorMessage = error.localizedDescription
        }
    }

    private func updateRoute(_ updatedRoute: RouteHistoryItem) {
        if let routeIndex = routes.firstIndex(where: { $0.id == updatedRoute.id }) {
            routes[routeIndex] = updatedRoute
        }

        if updatedRoute.isFavorite {
            if let favoriteIndex = favoriteRoutes.firstIndex(where: { $0.id == updatedRoute.id }) {
                favoriteRoutes[favoriteIndex] = updatedRoute
            } else {
                favoriteRoutes.insert(updatedRoute, at: 0)
            }
        } else {
            favoriteRoutes.removeAll { $0.id == updatedRoute.id }
        }
    }

    func reloadRoutes() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let token = try await authSession.loginIfNeeded()
            routes = try await service.getRouteHistory(token: token)
            favoriteRoutes = routes.filter(\.isFavorite)
            RunWayDebugLog.routeHistory("reloaded \(routes.count) routes, \(favoriteRoutes.count) favorites")
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func mergeFavoriteRoutesIntoRoutes() {
        guard !routes.isEmpty else { return }
        let favoriteIDs = Set(favoriteRoutes.map { $0.id })

        routes = routes.map { route in
            RouteHistoryItem(
                id: route.id,
                userId: route.userId,
                routeName: route.routeName,
                startLatitude: route.startLatitude,
                startLongitude: route.startLongitude,
                destinationLatitude: route.destinationLatitude,
                destinationLongitude: route.destinationLongitude,
                estimatedDurationMinutes: route.estimatedDurationMinutes,
                environmentalScore: route.environmentalScore,
                isFavorite: favoriteIDs.contains(route.id),
                createdAt: route.createdAt,
                transportMode: route.transportMode,
                distanceKm: route.distanceKm,
                originName: route.originName,
                destinationName: route.destinationName
            )
        }
    }
}
