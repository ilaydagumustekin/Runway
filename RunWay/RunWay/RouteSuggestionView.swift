import CoreLocation
import MapKit
import SwiftUI

// MARK: - TravelMode

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

    var speedKmh: Double {
        switch self {
        case .walk: return 5
        case .bike: return 15
        case .scooter: return 20
        }
    }
}

// MARK: - RouteSuggestionView

struct RouteSuggestionView: View {
    @Environment(\.dismiss) private var dismiss

    let target: String
    let destinationCoordinate: CLLocationCoordinate2D
    @Binding var selectedTab: Tab

    @ObservedObject private var locationManager = AppLocationManager.shared

    @State private var mode: TravelMode = .walk
    @State private var routeSummary: RouteRecommendAPIResponse?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var mapPosition: MapCameraPosition = .automatic

    // MARK: - Computed values

    private var durationText: String {
        guard let r = routeSummary else { return "—" }
        return "\(r.estimatedDurationMinutes) dk"
    }

    private var distanceText: String {
        guard let r = routeSummary, r.distanceKm > 0 else { return "—" }
        return String(format: "%.1f km", r.distanceKm)
    }

    private var arrivalText: String {
        guard let r = routeSummary else { return "—" }
        return Date()
            .addingTimeInterval(TimeInterval(r.estimatedDurationMinutes * 60))
            .formatted(date: .omitted, time: .shortened)
    }

    private var routeCoords: [CLLocationCoordinate2D] {
        routeSummary?.pathCoordinates ?? []
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            routeMap
                .ignoresSafeArea()

            topBar

            VStack(spacing: 0) {
                Spacer()
                bottomPanel
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .onAppear { fitMapToRoute() }
        .task(id: "\(target)-\(mode.backendValue)") {
            await loadRouteSuggestion()
        }
    }

    // MARK: - Map

    private var routeMap: some View {
        Map(position: $mapPosition) {
            UserAnnotation()

            Annotation(target, coordinate: destinationCoordinate) {
                ZStack {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 38, height: 38)
                        .shadow(radius: 4)
                    Image(systemName: "mappin.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                }
            }

            if routeCoords.count >= 2 {
                if let first = routeCoords.first {
                    Annotation("", coordinate: first) {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 14, height: 14)
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            .shadow(radius: 3)
                    }
                }
                MapPolyline(coordinates: routeCoords)
                    .stroke(
                        Color.green.opacity(0.9),
                        style: StrokeStyle(lineWidth: 7, lineCap: .round, lineJoin: .round)
                    )
            }
        }
        .mapStyle(.standard(elevation: .flat))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.primary)
                    .frame(width: 40, height: 40)
                    .background(.regularMaterial)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.12), radius: 6, y: 2)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 1) {
                Text("Yol Tarifi")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text(target)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .lineLimit(1)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: .black.opacity(0.08), radius: 6, y: 2)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    // MARK: - Bottom Panel

    private var bottomPanel: some View {
        VStack(spacing: 0) {
            // Mode picker
            HStack(spacing: 6) {
                ForEach(TravelMode.allCases) { m in
                    Button { mode = m } label: {
                        VStack(spacing: 4) {
                            Image(systemName: m.icon)
                                .font(.system(size: 18, weight: .semibold))
                            Text(m.rawValue)
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(mode == m ? .white : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(mode == m ? Color.black.opacity(0.80) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.horizontal, 20)
            .padding(.top, 22)

            // Stats row
            if isLoading {
                HStack(spacing: 8) {
                    ProgressView().scaleEffect(0.9)
                    Text("Rota hesaplanıyor...")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .frame(height: 72)
            } else {
                HStack(spacing: 0) {
                    statCell(value: durationText, label: "süre", icon: "clock.fill")
                    Divider().frame(height: 40)
                    statCell(value: distanceText, label: "mesafe", icon: mode.icon)
                    Divider().frame(height: 40)
                    statCell(value: arrivalText, label: "varış", icon: "flag.checkered")
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 4)
            }

            if let err = errorMessage {
                Text(err)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 4)
            }

            // Environmental score
            if let score = routeSummary?.environmentalScore, score > 0 {
                HStack {
                    Label("Çevre Skoru", systemImage: "leaf.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.green)
                    Spacer()
                    Text("%\(Int(score.rounded()))")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundStyle(.green)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }

            // Start button
            Button { startNavigation() } label: {
                HStack(spacing: 10) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 15, weight: .bold))
                    Text("Başla")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(isLoading ? Color.black.opacity(0.35) : Color.black.opacity(0.72))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: .black.opacity(0.28), radius: 10, y: 4)
            }
            .disabled(isLoading)
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 36)
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.14), radius: 24, x: 0, y: -4)
        .padding(.horizontal, 8)
    }

    private func statCell(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(value == "—" ? .secondary : .primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }

    // MARK: - Actions

    private func startNavigation() {
        RunWayDebugLog.routeHistory("start button tapped destination=\(target) mode=\(mode.backendValue)")
        let summary = routeSummary
        RouteOverlayStore.shared.setRoute(
            title: summary?.routeName ?? target,
            path: routeCoords,
            destinationName: target,
            destinationCoordinate: destinationCoordinate,
            distanceKm: summary?.distanceKm ?? 0,
            environmentalScore: summary?.environmentalScore ?? 0,
            transportMode: mode.backendValue
        )
        RunWayDebugLog.activeRoute("mode=navigating transport=\(mode.backendValue)")

        let startCoord = locationManager.lastLocation?.coordinate
            ?? CLLocationCoordinate2D(latitude: 37.7648, longitude: 30.5566)
        let destCoord = destinationCoordinate
        Task {
            do {
                let token = try await AuthSession.shared.loginIfNeeded()
                let displayTitle = "Konumunuz → \(target)"
                let payload = RouteHistoryCreateRequest(
                    routeName: displayTitle,
                    startLatitude: startCoord.latitude,
                    startLongitude: startCoord.longitude,
                    destinationLatitude: destCoord.latitude,
                    destinationLongitude: destCoord.longitude,
                    estimatedDurationMinutes: summary?.estimatedDurationMinutes ?? 0,
                    environmentalScore: summary?.environmentalScore ?? 0,
                    transportMode: mode.backendValue,
                    distanceKm: summary?.distanceKm,
                    originName: "Konumunuz",
                    destinationName: target
                )
                RunWayDebugLog.routeHistory(
                    "saving route title=\(payload.routeName)" +
                    " origin=\(payload.originName ?? "-") destination=\(payload.destinationName ?? "-")" +
                    " mode=\(payload.transportMode ?? "-") duration=\(payload.estimatedDurationMinutes)" +
                    " distance=\(payload.distanceKm.map { String(format: "%.2f", $0) } ?? "-")"
                )
                let saved = try await RouteHistoryService().createRoute(payload: payload, token: token)
                RunWayDebugLog.routeHistory(
                    "saved route id=\(saved.id) origin=\(saved.originName ?? "-")" +
                    " destination=\(saved.destinationName ?? "-") mode=\(saved.transportMode ?? "-")"
                )
            } catch {
                RunWayDebugLog.routeHistory("save failed: \(error)")
            }
        }

        selectedTab = .activeRoute
        dismiss()
    }

    private func fitMapToRoute() {
        if routeCoords.count >= 2 {
            var minLat = 90.0, maxLat = -90.0, minLon = 180.0, maxLon = -180.0
            for c in routeCoords {
                minLat = min(minLat, c.latitude); maxLat = max(maxLat, c.latitude)
                minLon = min(minLon, c.longitude); maxLon = max(maxLon, c.longitude)
            }
            withAnimation(.easeInOut(duration: 0.5)) {
                mapPosition = .region(MKCoordinateRegion(
                    center: CLLocationCoordinate2D(
                        latitude: (minLat + maxLat) / 2,
                        longitude: (minLon + maxLon) / 2
                    ),
                    span: MKCoordinateSpan(
                        latitudeDelta: max(0.012, (maxLat - minLat) * 1.8),
                        longitudeDelta: max(0.012, (maxLon - minLon) * 1.8)
                    )
                ))
            }
        } else if let user = locationManager.lastLocation?.coordinate {
            let dLat = max(0.025, abs(user.latitude - destinationCoordinate.latitude) * 1.8)
            let dLon = max(0.025, abs(user.longitude - destinationCoordinate.longitude) * 1.8)
            mapPosition = .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude: (user.latitude + destinationCoordinate.latitude) / 2,
                    longitude: (user.longitude + destinationCoordinate.longitude) / 2
                ),
                span: MKCoordinateSpan(latitudeDelta: dLat, longitudeDelta: dLon)
            ))
        } else {
            mapPosition = .region(MKCoordinateRegion(
                center: destinationCoordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
            ))
        }
    }

    @MainActor
    private func loadRouteSuggestion() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let start = locationManager.lastLocation?.coordinate
            ?? CLLocationCoordinate2D(latitude: 37.7648, longitude: 30.5566)

        RunWayDebugLog.route("selected transport mode=\(mode.backendValue)")
        RunWayDebugLog.activeRoute("mode=preview transport=\(mode.backendValue)")

        do {
            let response = try await RouteRecommendationService.fetchRecommendation(
                start: start,
                destination: destinationCoordinate,
                transportMode: mode.backendValue,
                token: nil
            )
            routeSummary = response
            fitMapToRoute()
        } catch {
            routeSummary = nil
            errorMessage = "Rota bilgisi alınamadı. Backend çalışıyor mu?"
        }
    }
}
