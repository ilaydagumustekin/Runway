import SwiftUI

/// ML tahmini, yeşil alan (placeholder) ve TÜİK doğrulama uçlarını tek ekranda gösterir.
struct IntegrationsHubView: View {
    @EnvironmentObject private var appSession: AppSession

    @State private var hours: Int = 24
    @State private var air: AirQualityPredictionResponse?
    @State private var greenArea: GreenAreaAnalysisResponse?
    @State private var tuik: TuikValidationResponse?
    @State private var isLoading = false
    @State private var errorText: String?

    private let service = IntegrationsService()

    private var neighborhoodId: Int? {
        appSession.currentAnalysisNeighborhoodId
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if neighborhoodId == nil {
                        Text("Ana sayfada veri yüklendikten veya haritadan mahalle seçtikten sonra bu bölüm aktif olur.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
                    }

                    Picker("Tahmin ufku", selection: $hours) {
                        Text("24 saat").tag(24)
                        Text("48 saat").tag(48)
                        Text("72 saat").tag(72)
                    }
                    .pickerStyle(.segmented)
                    .disabled(neighborhoodId == nil)

                    if let errorText {
                        Text(errorText)
                            .font(.subheadline)
                            .foregroundStyle(.red)
                    }

                    integrationCard(title: "Hava kalitesi tahmini", systemImage: "chart.line.uptrend.xyaxis") {
                        if let air {
                            Text("Kaynak: \(air.source)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(air.forecast.count) zaman noktası (her ~6 saat)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let first = air.forecast.first, let last = air.forecast.last {
                                Text("AQI: \(first.predictedAqi.formattedMetricValue) → \(last.predictedAqi.formattedMetricValue)")
                                    .font(.subheadline.weight(.semibold))
                            }
                        } else {
                            placeholderLine
                        }
                    }

                    integrationCard(title: "Yeşil alan analizi", systemImage: "leaf.circle") {
                        if let greenArea {
                            Text(greenArea.message)
                                .font(.subheadline)
                            if let providers = greenArea.supportedFutureProviders, !providers.isEmpty {
                                Text(providers.joined(separator: " · "))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            placeholderLine
                        }
                    }

                    integrationCard(title: "TÜİK doğrulama", systemImage: "checkmark.shield") {
                        if let tuik {
                            Text(tuik.source)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(tuik.message)
                                .font(.subheadline)
                        } else {
                            placeholderLine
                        }
                    }
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Gelişmiş analiz")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await loadAll() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(neighborhoodId == nil || isLoading)
                }
            }
            .task(id: "\(neighborhoodId.map(String.init) ?? "")-\(hours)") {
                await loadAll()
            }
            .overlay {
                if isLoading {
                    ProgressView()
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
        }
    }

    private var placeholderLine: some View {
        Text("Veri yok")
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }

    private func integrationCard<Content: View>(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: systemImage)
                .font(.headline)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func loadAll() async {
        errorText = nil
        guard let nid = neighborhoodId else {
            air = nil
            greenArea = nil
            tuik = nil
            return
        }

        RunWayDebugLog.analysis("loading analysis for neighborhoodId=\(nid)")

        isLoading = true
        defer { isLoading = false }

        async let a = try? service.fetchAirQualityPrediction(neighborhoodId: nid, hours: hours)
        async let g = try? service.fetchGreenAreaAnalysis(neighborhoodId: nid)
        async let t = try? service.fetchTuikValidation(neighborhoodId: nid)

        let results = await (a, g, t)
        air = results.0
        greenArea = results.1
        tuik = results.2

        if results.0 == nil, results.1 == nil, results.2 == nil {
            errorText = "Entegrasyon uçlarına ulaşılamadı. API adresini ve sunucuyu kontrol edin."
        }
    }
}

#Preview {
    IntegrationsHubView()
        .environmentObject(AppSession())
}
