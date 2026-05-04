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

    init() {
        self.authService = AuthService()
        self.dashboardService = DashboardService()
    }

    init(
        authService: AuthService,
        dashboardService: DashboardService
    ) {
        self.authService = authService
        self.dashboardService = dashboardService
    }

    func loadDashboard() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        do {
            let loginResponse = try await authService.login(
                email: "admin@example.com",
                password: "123456"
            )
            token = loginResponse.accessToken

            let homeResponse = try await dashboardService.fetchHome(
                neighborhoodId: 1,
                token: loginResponse.accessToken
            )

            dashboard = homeResponse
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
