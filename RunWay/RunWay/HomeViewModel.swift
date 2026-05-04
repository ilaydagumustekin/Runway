import Foundation
import Combine

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

    func loadDashboard() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        do {
            let accessToken = try await authSession.loginIfNeeded()
            token = accessToken

            let homeResponse = try await dashboardService.fetchHome(
                neighborhoodId: 1,
                token: accessToken
            )

            dashboard = homeResponse
        } catch {
            print("Dashboard load error:", error)
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
