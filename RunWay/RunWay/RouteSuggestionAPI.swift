import Foundation

struct RouteSuggestionResponse: Decodable {
    let target: String
    let travelMode: String
    let etaMinutes: Int
    let distanceKm: Double
    let routeScore: Double
    let warningText: String

    enum CodingKeys: String, CodingKey {
        case target
        case travelMode = "travel_mode"
        case etaMinutes = "eta_minutes"
        case distanceKm = "distance_km"
        case routeScore = "route_score"
        case warningText = "warning_text"
    }
}

struct RouteSuggestionAPI {
    private let baseURL = URL(string: "http://127.0.0.1:8000")!

    func fetchRouteSuggestion(target: String, mode: TravelMode) async throws -> RouteSuggestionResponse {
        var components = URLComponents(url: baseURL.appendingPathComponent("route-suggestion"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "target", value: target),
            URLQueryItem(name: "mode", value: mode.backendValue)
        ]

        guard let url = components?.url else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(RouteSuggestionResponse.self, from: data)
    }
}
