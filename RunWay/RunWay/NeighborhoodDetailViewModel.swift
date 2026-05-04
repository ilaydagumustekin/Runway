import Foundation
import Combine

@MainActor
final class NeighborhoodDetailViewModel: ObservableObject {
    @Published var detail: NeighborhoodDetailResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service: NeighborhoodDetailService

    init() {
        self.service = NeighborhoodDetailService()
    }

    init(service: NeighborhoodDetailService) {
        self.service = service
    }

    func loadDetails(neighborhoodId: Int = 1) async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        do {
            detail = try await service.fetchDetails(neighborhoodId: neighborhoodId)
        } catch {
            print("Neighborhood detail load error:", error)
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
