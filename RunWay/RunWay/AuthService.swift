import Foundation

struct AuthService {
    private let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    func login(email: String, password: String) async throws -> LoginResponse {
        let request = LoginRequest(email: email, password: password)
        return try await apiClient.post(path: "/auth/login-json", body: request, token: nil)
    }
}
