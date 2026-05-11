import Foundation
import Combine

@MainActor
final class AuthSession: ObservableObject {
    static let shared = AuthSession()

    @Published var accessToken: String?
    @Published var currentUser: UserProfileResponse?
    @Published var authErrorMessage: String?
    @Published var isLoading = false

    private let authService: AuthService

    init() {
        self.authService = AuthService()
    }

    init(authService: AuthService) {
        self.authService = authService
    }

    var isAuthenticated: Bool {
        if let accessToken, !accessToken.isEmpty {
            return true
        }
        return false
    }

    func register(fullName: String, email: String, password: String) async -> Bool {
        isLoading = true
        authErrorMessage = nil
        defer { isLoading = false }

        do {
            _ = try await authService.register(fullName: fullName, email: email, password: password)
            let loginResponse = try await authService.login(email: email, password: password)
            accessToken = loginResponse.accessToken
            currentUser = try await authService.getCurrentUser(token: loginResponse.accessToken)
            return true
        } catch {
            authErrorMessage = error.localizedDescription
            return false
        }
    }

    func login(email: String, password: String) async -> Bool {
        isLoading = true
        authErrorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await authService.login(email: email, password: password)
            accessToken = response.accessToken
            currentUser = try await authService.getCurrentUser(token: response.accessToken)
            return true
        } catch {
            authErrorMessage = error.localizedDescription
            return false
        }
    }

    func loadCurrentUserIfNeeded() async {
        guard currentUser == nil, let accessToken, !accessToken.isEmpty else { return }
        do {
            currentUser = try await authService.getCurrentUser(token: accessToken)
        } catch {
            authErrorMessage = error.localizedDescription
        }
    }

    func logout() async {
        do {
            _ = try await authService.logout(token: accessToken)
        } catch {
            // Keep local logout behavior even if remote logout fails.
        }
        accessToken = nil
        currentUser = nil
        authErrorMessage = nil
    }

    func loginIfNeeded() async throws -> String {
        if let accessToken, !accessToken.isEmpty {
            return accessToken
        }
        throw APIClientError.httpError(statusCode: 401, message: "Giriş yapmanız gerekiyor.")
    }
}
