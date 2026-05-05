import Foundation
import Combine

@MainActor
final class NotificationsViewModel: ObservableObject {
    @Published var notifications: [NotificationItem] = []
    @Published var unreadCount: Int = 0
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service: NotificationsService
    private let authSession: AuthSession

    init(
        service: NotificationsService = NotificationsService(),
        authSession: AuthSession = .shared
    ) {
        self.service = service
        self.authSession = authSession
    }

    func loadNotifications() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        do {
            let token = try await authSession.loginIfNeeded()
            notifications = try await service.getNotifications(token: token)
            refreshUnreadCount()
        } catch {
            print("Notifications load error:", error)
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func markAsRead(notification: NotificationItem) async {
        guard !notification.isRead else { return }

        errorMessage = nil

        do {
            let token = try await authSession.loginIfNeeded()
            let updatedNotification = try await service.markAsRead(notificationId: notification.id, token: token)
            updateNotification(updatedNotification)
            refreshUnreadCount()
        } catch {
            print("Mark notification as read error:", error)
            errorMessage = error.localizedDescription
        }
    }

    func refreshUnreadCount() {
        unreadCount = notifications.filter { !$0.isRead }.count
    }

    private func updateNotification(_ updatedNotification: NotificationItem) {
        if let index = notifications.firstIndex(where: { $0.id == updatedNotification.id }) {
            notifications[index] = updatedNotification
        }
    }
}
