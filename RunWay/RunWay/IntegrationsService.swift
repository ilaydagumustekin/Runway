import Foundation

struct IntegrationsService {
    private let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    func fetchAirQualityPrediction(neighborhoodId: Int, hours: Int) async throws -> AirQualityPredictionResponse {
        try await apiClient.get(
            path: "/integrations/air-quality-prediction/\(neighborhoodId)",
            queryItems: [URLQueryItem(name: "hours", value: String(hours))],
            token: nil
        )
    }

    func fetchGreenAreaAnalysis(neighborhoodId: Int, token: String? = nil) async throws -> GreenAreaAnalysisResponse {
        try await apiClient.get(
            path: "/integrations/green-area-analysis/\(neighborhoodId)",
            queryItems: [],
            token: token
        )
    }

    func fetchTuikValidation(neighborhoodId: Int) async throws -> TuikValidationResponse {
        try await apiClient.get(
            path: "/integrations/tuik-validation/\(neighborhoodId)",
            queryItems: [],
            token: nil
        )
    }
}
