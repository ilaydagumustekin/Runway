import Foundation

struct NotificationsService {
    private let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    func getNotifications(token: String) async throws -> [NotificationItem] {
        try await apiClient.get(path: "/notifications", token: token)
    }

    func markAsRead(notificationId: Int, token: String) async throws -> NotificationItem {
        try await apiClient.patch(path: "/notifications/\(notificationId)/read", token: token)
    }
}
