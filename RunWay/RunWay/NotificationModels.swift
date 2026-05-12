import Foundation

struct NotificationItem: Decodable, Identifiable, Equatable {
    let id: Int
    let userId: Int?
    let neighborhoodId: Int?
    let title: String
    let message: String
    let notificationType: String
    let severity: String
    let isRead: Bool
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case neighborhoodId = "neighborhood_id"
        case title
        case message
        case notificationType = "notification_type"
        case severity
        case isRead = "is_read"
        case createdAt = "created_at"
    }

    init(
        id: Int,
        userId: Int? = nil,
        neighborhoodId: Int? = nil,
        title: String,
        message: String,
        notificationType: String,
        severity: String,
        isRead: Bool,
        createdAt: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.neighborhoodId = neighborhoodId
        self.title = title
        self.message = message
        self.notificationType = notificationType
        self.severity = severity
        self.isRead = isRead
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeFlexibleIntIfPresent(forKey: .id) ?? 0
        userId = try container.decodeFlexibleIntIfPresent(forKey: .userId)
        neighborhoodId = try container.decodeFlexibleIntIfPresent(forKey: .neighborhoodId)
        title = (try? container.decode(String.self, forKey: .title)) ?? "Bildirim"
        message = (try? container.decode(String.self, forKey: .message)) ?? ""
        notificationType = (try? container.decode(String.self, forKey: .notificationType)) ?? "info"
        severity = (try? container.decode(String.self, forKey: .severity)) ?? "info"
        isRead = try container.decodeFlexibleBool(forKey: .isRead, default: false)
        createdAt = try? container.decodeIfPresent(String.self, forKey: .createdAt)
    }
}
