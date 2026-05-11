import CoreLocation
import SwiftUI

enum TravelMode: String, CaseIterable, Identifiable {
    case walk = "Yürüyüş"
    case bike = "Bisiklet"
    case scooter = "Scooter"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .walk: return "figure.walk"
        case .bike: return "bicycle"
        case .scooter: return "scooter"
        }
    }

    var backendValue: String {
        switch self {
        case .walk: return "walking"
        case .bike: return "bicycle"
        case .scooter: return "scooter"
        }
    }
}

struct RouteSuggestionView: View {
    @Environment(\.dismiss) private var dismiss

    let target: String
    let destinationCoordinate: CLLocationCoordinate2D
    @Binding var selectedTab: Tab

    @State private var mode: TravelMode = .walk
    @State private var routeSummary: RouteRecommendAPIResponse?
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let fallbackEtaMinutes: Int = 12
    private let fallbackDistanceKm: Double = 1.2
    private let fallbackRouteScore: Double = 78
    private let fallbackWarningText: String = "Çevre skoruna göre önerilen yürüyüş rotası (mock)."

    private var etaText: String { "\(routeSummary?.estimatedDurationMinutes ?? fallbackEtaMinutes) dk" }

    private var distanceText: String {
        if let routeSummary, routeSummary.distanceKm > 0 {
            return String(format: "%.1f km", routeSummary.distanceKm)
        }
        return String(format: "%.1f km", fallbackDistanceKm)
    }

    private var scoreText: String {
        let raw = routeSummary?.environmentalScore ?? fallbackRouteScore
        return "%\(Int(raw.rounded()))"
    }

    private var warningText: String {
        if let name = routeSummary?.routeName, !name.isEmpty {
            return "\(name). \(fallbackWarningText)"
        }
        return fallbackWarningText
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {

                Text("Hedef: \(target)")
                    .font(.headline)

                HStack(spacing: 10) {
                    ForEach(TravelMode.allCases) { m in
                        Button {
                            mode = m
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: m.icon)
                                Text(m.rawValue)
                            }
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(
                                mode == m
                                ? Color.green.opacity(0.20)
                                : Color(.secondarySystemBackground)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Rota Özeti")
                        .font(.headline)

                    if isLoading {
                        HStack {
                            ProgressView()
                            Text("Rota hesaplanıyor...")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        HStack {
                            Label(etaText, systemImage: "clock")
                            Spacer()
                            Label(distanceText, systemImage: "location")
                            Spacer()
                            Text(scoreText)
                                .fontWeight(.bold)
                                .foregroundStyle(.green)
                        }
                        .font(.subheadline)
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    Text(warningText)
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                Spacer()

                Button {
                    if let coords = routeSummary?.pathCoordinates, !coords.isEmpty {
                        RouteOverlayStore.shared.setRoute(
                            title: routeSummary?.routeName ?? "Rota",
                            path: coords,
                            destinationName: target,
                            destinationCoordinate: destinationCoordinate,
                            distanceKm: routeSummary?.distanceKm ?? 0,
                            environmentalScore: routeSummary?.environmentalScore ?? 0
                        )
                    }
                    selectedTab = .activeRoute
                    dismiss()
                } label: {
                    Text("Rotayı Başlat")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
            .padding()
            .navigationTitle("Rota Önerisi")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Geri") { dismiss() }
                }
            }
            .task(id: "\(target)-\(mode.backendValue)") {
                await loadRouteSuggestion()
            }
        }
    }

    @MainActor
    private func loadRouteSuggestion() async {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        let start = AppLocationManager.shared.lastLocation?.coordinate
            ?? CLLocationCoordinate2D(latitude: 37.7648, longitude: 30.5566)

        RunWayDebugLog.route("selected transport mode=\(mode.backendValue)")

        do {
            let response = try await RouteRecommendationService.fetchRecommendation(
                start: start,
                destination: destinationCoordinate,
                transportMode: mode.backendValue,
                token: nil
            )
            routeSummary = response
            RouteOverlayStore.shared.setRoute(
                title: response.routeName,
                path: response.pathCoordinates,
                destinationName: target,
                destinationCoordinate: destinationCoordinate,
                distanceKm: response.distanceKm,
                environmentalScore: response.environmentalScore
            )
        } catch {
            routeSummary = nil
            errorMessage = "Rota bilgisi alınamadı. Backend çalışıyor mu?"
        }
    }
}
