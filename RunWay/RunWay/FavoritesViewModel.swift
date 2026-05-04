import Foundation
import Combine

@MainActor
final class FavoritesViewModel: ObservableObject {
    @Published var favorites: [FavoriteNeighborhoodResponse] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isFavoriteCurrentNeighborhood = false

    private let service: FavoritesService

    init() {
        self.service = FavoritesService()
    }

    init(service: FavoritesService) {
        self.service = service
    }

    func loadFavorites(token: String) async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        do {
            favorites = try await service.getFavorites(token: token)
        } catch {
            print("Favorites load error:", error)
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func addFavorite(neighborhoodId: Int, token: String) async {
        errorMessage = nil

        do {
            let favorite = try await service.addFavorite(neighborhoodId: neighborhoodId, token: token)
            if !favorites.contains(where: { $0.neighborhoodId == neighborhoodId }) {
                favorites.insert(favorite, at: 0)
            }
            isFavoriteCurrentNeighborhood = true
        } catch let APIClientError.httpError(statusCode, _) where statusCode == 400 {
            isFavoriteCurrentNeighborhood = true
            if favorites.isEmpty || !favorites.contains(where: { $0.neighborhoodId == neighborhoodId }) {
                await loadFavorites(token: token)
            }
        } catch {
            print("Add favorite error:", error)
            errorMessage = error.localizedDescription
        }
    }

    func removeFavorite(neighborhoodId: Int, token: String) async {
        errorMessage = nil

        do {
            try await service.removeFavorite(neighborhoodId: neighborhoodId, token: token)
            favorites.removeAll { $0.neighborhoodId == neighborhoodId }
            isFavoriteCurrentNeighborhood = false
        } catch let APIClientError.httpError(statusCode, _) where statusCode == 404 {
            favorites.removeAll { $0.neighborhoodId == neighborhoodId }
            isFavoriteCurrentNeighborhood = false
        } catch {
            print("Remove favorite error:", error)
            errorMessage = error.localizedDescription
        }
    }

    func toggleFavorite(neighborhoodId: Int, token: String) async {
        if checkIsFavorite(neighborhoodId: neighborhoodId) {
            await removeFavorite(neighborhoodId: neighborhoodId, token: token)
        } else {
            await addFavorite(neighborhoodId: neighborhoodId, token: token)
        }
    }

    @discardableResult
    func checkIsFavorite(neighborhoodId: Int) -> Bool {
        let isFavorite = favorites.contains { $0.neighborhoodId == neighborhoodId }
        isFavoriteCurrentNeighborhood = isFavorite
        return isFavorite
    }
}
