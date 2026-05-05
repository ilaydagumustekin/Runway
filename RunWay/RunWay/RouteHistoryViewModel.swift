import Foundation

@MainActor
final class RouteHistoryViewModel: ObservableObject {
    enum Filter {
        case all
        case favorites
    }

    @Published var routes: [RouteHistoryItem] = []
    @Published var favoriteRoutes: [RouteHistoryItem] = []
    @Published var selectedTab: Filter = .all
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published private(set) var updatingRouteIDs: Set<Int> = []

    private let service: RouteHistoryService
    private let authSession: AuthSession
    private var hasLoadedRoutes = false
    private var hasLoadedFavorites = false

    init(
        service: RouteHistoryService = RouteHistoryService(),
        authSession: AuthSession = .shared
    ) {
        self.service = service
        self.authSession = authSession
    }

    func loadInitialDataIfNeeded() async {
        guard !hasLoadedRoutes else { return }
        await loadRoutes()
    }

    func loadRoutes(force: Bool = false) async {
        guard !isLoading || force else { return }

        isLoading = true
        errorMessage = nil

        do {
            let token = try await authSession.loginIfNeeded()
            routes = try await service.getRouteHistory(token: token)
            hasLoadedRoutes = true
            refreshFavoriteRoutesFromRoutes()
        } catch {
            print("Route history load error:", error)
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func loadFavoriteRoutes(force: Bool = false) async {
        guard !isLoading || force else { return }
        guard force || !hasLoadedFavorites else { return }

        isLoading = true
        errorMessage = nil

        do {
            let token = try await authSession.loginIfNeeded()
            favoriteRoutes = try await service.getFavoriteRouteHistory(token: token)
            hasLoadedFavorites = true
            mergeFavoritesIntoRoutes()
        } catch {
            print("Favorite route history load error:", error)
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func toggleFavorite(route: RouteHistoryItem) async {
        guard !updatingRouteIDs.contains(route.id) else { return }

        errorMessage = nil
        updatingRouteIDs.insert(route.id)

        let originalRoute = route
        let optimisticRoute = RouteHistoryItem(
            id: route.id,
            userId: route.userId,
            routeName: route.routeName,
            startLatitude: route.startLatitude,
            startLongitude: route.startLongitude,
            destinationLatitude: route.destinationLatitude,
            destinationLongitude: route.destinationLongitude,
            estimatedDurationMinutes: route.estimatedDurationMinutes,
            environmentalScore: route.environmentalScore,
            isFavorite: !route.isFavorite,
            createdAt: route.createdAt
        )

        updateRoute(optimisticRoute)

        do {
            let token = try await authSession.loginIfNeeded()
            let updatedRoute: RouteHistoryItem

            if route.isFavorite {
                updatedRoute = try await service.unfavoriteRoute(routeHistoryId: route.id, token: token)
            } else {
                updatedRoute = try await service.favoriteRoute(routeHistoryId: route.id, token: token)
            }

            updateRoute(updatedRoute)
            hasLoadedFavorites = false

            if selectedTab == .favorites {
                await loadFavoriteRoutes(force: true)
            }
        } catch {
            print("Toggle route favorite error:", error)
            updateRoute(originalRoute)
            errorMessage = error.localizedDescription
        }

        updatingRouteIDs.remove(route.id)
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

    private func refreshFavoriteRoutesFromRoutes() {
        favoriteRoutes = routes.filter(\.isFavorite)
    }

    private func mergeFavoritesIntoRoutes() {
        guard !routes.isEmpty else { return }
        let favoriteIDs = Set(favoriteRoutes.map(\.id))

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
                createdAt: route.createdAt
            )
        }
    }
}
