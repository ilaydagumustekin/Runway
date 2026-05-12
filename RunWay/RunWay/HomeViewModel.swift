import Foundation
import Combine
import CoreLocation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var dashboard: DashboardHomeResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var token: String?
    /// `/integrations/green-area-analysis/{id}` → `analysis.green_percentage`; anasayfa yeşil mini metriği bunu öncelikli kullanır.
    @Published private(set) var integrationGreenAreaPercent: Double?

    private let authService: AuthService
    private let dashboardService: DashboardService
    private let integrationsService: IntegrationsService
    private let authSession: AuthSession

    init() {
        self.authService = AuthService()
        self.dashboardService = DashboardService()
        self.integrationsService = IntegrationsService()
        self.authSession = AuthSession.shared
    }

    init(
        authService: AuthService,
        dashboardService: DashboardService,
        integrationsService: IntegrationsService = IntegrationsService(),
        authSession: AuthSession
    ) {
        self.authService = authService
        self.dashboardService = dashboardService
        self.integrationsService = integrationsService
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
        integrationGreenAreaPercent = nil

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

            let nid = homeResponse.location.neighborhoodId
            if nid > 0 {
                do {
                    let greenResp = try await integrationsService.fetchGreenAreaAnalysis(neighborhoodId: nid, token: accessToken)
                    integrationGreenAreaPercent = greenResp.analysis?.greenPercentage
                    if integrationGreenAreaPercent == nil {
                        RunWayDebugLog.home("green-area-analysis: no analysis.green_percentage for neighborhoodId=\(nid)")
                    }
                } catch {
                    integrationGreenAreaPercent = nil
                    RunWayDebugLog.home("green-area-analysis fetch failed for neighborhoodId=\(nid): \(error.localizedDescription)")
                }
            } else {
                integrationGreenAreaPercent = nil
            }
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
