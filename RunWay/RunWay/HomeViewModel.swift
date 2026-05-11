import Foundation
import Combine
import CoreLocation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var dashboard: DashboardHomeResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var token: String?

    private let authService: AuthService
    private let dashboardService: DashboardService
    private let authSession: AuthSession

    init() {
        self.authService = AuthService()
        self.dashboardService = DashboardService()
        self.authSession = AuthSession.shared
    }

    init(
        authService: AuthService,
        dashboardService: DashboardService,
        authSession: AuthSession
    ) {
        self.authService = authService
        self.dashboardService = dashboardService
        self.authSession = authSession
    }

    /// `manualNeighborhoodId` doluysa sadece o mahalle kullanılır; aksi halde `latitude` / `longitude` ile en yakın mahalle seçilir.
    func loadDashboard(manualNeighborhoodId: Int?, latitude: Double?, longitude: Double?) async {
        guard !isLoading else {
            RunWayDebugLog.home("loadDashboard skipped (already loading)")
            return
        }

        isLoading = true
        errorMessage = nil

        guard let accessToken = authSession.accessToken, !accessToken.isEmpty else {
            errorMessage = "Oturum bulunamadı. Lütfen yeniden giriş yapın."
            isLoading = false
            return
        }

        token = accessToken

        do {
            let useManual = manualNeighborhoodId != nil
            RunWayDebugLog.home(
                "HomeViewModel.loadDashboard manualNeighborhoodId=\(manualNeighborhoodId.map(String.init) ?? "nil") "
                    + "requestLat=\(latitude.map { String($0) } ?? "nil") requestLon=\(longitude.map { String($0) } ?? "nil") "
                    + "omitCoordsForManual=\(useManual)"
            )
            let homeResponse = try await dashboardService.fetchHome(
                neighborhoodId: manualNeighborhoodId,
                latitude: useManual ? nil : latitude,
                longitude: useManual ? nil : longitude,
                token: accessToken
            )
            dashboard = homeResponse
            RunWayDebugLog.home("HomeViewModel: dashboard decoded (see DashboardService for full URL + response.location)")
        } catch {
            print("Dashboard load error:", error)
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func refreshDashboardWithCurrentLocation() async {
        let loc = await AppLocationManager.shared.waitForBestLocation(timeoutSeconds: 18, desiredAccuracy: 45)
        let coord = loc?.coordinate ?? AppLocationManager.shared.lastLocation?.coordinate
        await loadDashboard(manualNeighborhoodId: nil, latitude: coord?.latitude, longitude: coord?.longitude)
    }
}
