import Foundation
import Combine

@MainActor
final class AuthSession: ObservableObject {
    static let shared = AuthSession()

    @Published var accessToken: String?

    private let authService: AuthService
    private var loginTask: Task<String, Error>?

    init() {
        self.authService = AuthService()
    }

    init(authService: AuthService) {
        self.authService = authService
    }

    func loginIfNeeded() async throws -> String {
        if let accessToken, !accessToken.isEmpty {
            return accessToken
        }

        if let loginTask {
            return try await loginTask.value
        }

        let task = Task<String, Error> {
            let response = try await authService.login(
                email: "admin@example.com",
                password: "123456"
            )
            return response.accessToken
        }

        loginTask = task

        do {
            let token = try await task.value
            accessToken = token
            loginTask = nil
            return token
        } catch {
            loginTask = nil
            throw error
        }
    }
}
