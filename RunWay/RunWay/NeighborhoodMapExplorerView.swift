import CoreLocation
import MapKit
import SwiftUI

/// Mahalle işaretleri MYKİ skoruna göre renklendirilir; dokununca analiz için seçilebilir.
struct NeighborhoodMapExplorerView: View {
    var onPick: (Int, String) -> Void
    var showDismiss: Bool = false

    @Environment(\.dismiss) private var dismiss

    @State private var markers: [NeighborhoodMarkerWithScore] = []
    @State private var selected: NeighborhoodMarkerWithScore?
    @State private var camera: MapCameraPosition = .automatic
    @State private var errorText: String?
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Map(position: $camera) {
                    UserAnnotation()

                    ForEach(markers) { marker in
                        Annotation(marker.displayTitle, coordinate: marker.coordinate) {
                            Button {
                                selected = marker
                            } label: {
                                Circle()
                                    .fill(color(for: marker.mykiScore))
                                    .frame(width: 18, height: 18)
                                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                    .shadow(radius: 2)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                    MapScaleView()
                }

                if let selected {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(selected.displayTitle)
                            .font(.system(size: 17, weight: .heavy, design: .rounded))
                        if let score = selected.mykiScore {
                            Text("MYKİ: \(Int(score.rounded()))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        HStack(spacing: 12) {
                            Button("Bu mahalleyi analiz et") {
                                RunWayDebugLog.state(
                                    "map pin chosen for analysis: id=\(selected.id) name=\(selected.name) "
                                        + "pinLat=\(selected.latitude) pinLon=\(selected.longitude)"
                                )
                                onPick(selected.id, selected.name)
                                if showDismiss { dismiss() }
                            }
                            .buttonStyle(.borderedProminent)

                            Button("Kapat") {
                                self.selected = nil
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .padding()
                }

                if isLoading {
                    ProgressView("Harita yükleniyor…")
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .navigationTitle("Mahalle Haritası")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if showDismiss {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Kapat") { dismiss() }
                    }
                }
            }
            .task {
                try? await Task.sleep(nanoseconds: 500_000_000)
                if let l = AppLocationManager.shared.lastLocation {
                    RunWayDebugLog.location(
                        "map selected location (UserAnnotation / shared lastLocation): lat=\(l.coordinate.latitude), lon=\(l.coordinate.longitude), hAcc_m=\(l.horizontalAccuracy)"
                    )
                } else {
                    RunWayDebugLog.location("map screen: lastLocation nil (user dot may still appear when GPS arrives)")
                }
                await loadMarkers()
            }
            .alert("Hata", isPresented: .constant(errorText != nil)) {
                Button("Tamam") { errorText = nil }
            } message: {
                Text(errorText ?? "")
            }
        }
    }

    private func color(for score: Double?) -> Color {
        guard let score else { return .gray }
        switch score {
        case 70...: return .green
        case 40..<70: return .yellow
        default: return .orange
        }
    }

    private func loadMarkers() async {
        isLoading = true
        defer { isLoading = false }
        do {
            markers = try await NeighborhoodMapService().fetchMarkersWithScores()
            fitCamera()
        } catch {
            errorText = "Mahalle işaretleri alınamadı. Backend adresini kontrol edin."
        }
    }

    private func fitCamera() {
        guard !markers.isEmpty else { return }
        var minLat = 90.0, maxLat = -90.0, minLon = 180.0, maxLon = -180.0
        for marker in markers {
            minLat = min(minLat, marker.latitude)
            maxLat = max(maxLat, marker.latitude)
            minLon = min(minLon, marker.longitude)
            maxLon = max(maxLon, marker.longitude)
        }
        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2)
        let span = MKCoordinateSpan(
            latitudeDelta: max(0.02, (maxLat - minLat) * 1.6),
            longitudeDelta: max(0.02, (maxLon - minLon) * 1.6)
        )
        camera = .region(MKCoordinateRegion(center: center, span: span))
    }
}

#Preview {
    NeighborhoodMapExplorerView(onPick: { _, _ in }, showDismiss: true)
}
