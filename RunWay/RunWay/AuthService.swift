import Foundation

struct AuthService {
    private let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    func register(fullName: String, email: String, password: String) async throws -> UserProfileResponse {
        let request = RegisterRequest(fullName: fullName, email: email, password: password)
        return try await apiClient.post(path: "/auth/register", body: request, token: nil)
    }

    func login(email: String, password: String) async throws -> LoginResponse {
        let request = LoginRequest(email: email, password: password)
        return try await apiClient.post(path: "/auth/login-json", body: request, token: nil)
    }

    func getCurrentUser(token: String) async throws -> UserProfileResponse {
        try await apiClient.get(path: "/users/me", queryItems: [], token: token)
    }

    func logout(token: String?) async throws -> EmptyAPIResponse {
        try await apiClient.post(path: "/auth/logout", token: token)
    }
}
