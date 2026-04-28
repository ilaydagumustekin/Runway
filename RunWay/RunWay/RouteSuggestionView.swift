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
        case .walk: return "walk"
        case .bike: return "bike"
        case .scooter: return "scooter"
        }
    }
}

struct RouteSuggestionView: View {
    @Environment(\.dismiss) private var dismiss

    let target: String
    @Binding var selectedTab: Tab

    @State private var mode: TravelMode = .walk
    @State private var routeSummary: RouteSuggestionResponse?
    @State private var isLoading = false
    @State private var errorMessage: String?

    // Backend başarısız olursa kullanılacak yedek değerler
    private let fallbackEtaMinutes: Int = 12
    private let fallbackDistanceKm: Double = 1.2
    private let fallbackRouteScore: Double = 78
    private let fallbackWarningText: String = "Uyarı: Gürültülü alan olabilir"

    private var etaText: String { "\(routeSummary?.etaMinutes ?? fallbackEtaMinutes) dk" }
    private var distanceText: String { String(format: "%.1f km", routeSummary?.distanceKm ?? fallbackDistanceKm) }
    private var scoreText: String { "%\(Int((routeSummary?.routeScore ?? fallbackRouteScore).rounded()))" }
    private var warningText: String { routeSummary?.warningText ?? fallbackWarningText }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {

                Text("Hedef: \(target)")
                    .font(.headline)

                // Mod seçimi: yürüyüş / bisiklet / scooter
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

                // Rota özeti
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

        do {
            routeSummary = try await RouteSuggestionAPI().fetchRouteSuggestion(target: target, mode: mode)
        } catch {
            errorMessage = "Rota bilgisi alınamadı."
        }

        isLoading = false
    }
}
