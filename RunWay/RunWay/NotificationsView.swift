import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject private var viewModel: NotificationsViewModel

    enum SectionType: String, CaseIterable {
        case unread = "OKUNMAMIŞ"
        case read = "OKUNDU"
    }

    var body: some View {
        List {
            if let errorMessage = viewModel.errorMessage {
                Section {
                    Text(errorMessage)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.red)
                }
            }

            if viewModel.notifications.isEmpty, !viewModel.isLoading {
                Section {
                    Text("Henüz bildirim yok.")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }

            sectionView(.unread)
            sectionView(.read)
        }
        .listStyle(.plain)
        .navigationTitle("Bildirimler")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel.notifications.isEmpty {
                await viewModel.loadNotifications()
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task {
                        await markAllRead()
                    }
                } label: {
                    Text("Tümünü Okundu İşaretle")
                        .font(.system(size: 15, weight: .semibold))
                }
                .disabled(viewModel.unreadCount == 0)
            }
        }
    }

    @ViewBuilder
    private func sectionView(_ type: SectionType) -> some View {
        let filtered = filteredItems(for: type)
        if !filtered.isEmpty {
            Section {
                ForEach(filtered) { n in
                    NotificationCard(
                        title: n.title,
                        message: n.message,
                        timeText: n.createdAtText,
                        iconSystemName: n.iconName,
                        iconBackground: n.iconBackground,
                        isUnread: !n.isRead,
                        severityText: n.severityDisplayText,
                        typeText: n.notificationTypeDisplayText
                    )
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                    .onTapGesture {
                        Task {
                            await viewModel.markAsRead(notification: n)
                        }
                    }
                }
            } header: {
                Text(type.rawValue)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.secondary)
                    .padding(.top, 6)
            }
        }
    }

    private func filteredItems(for type: SectionType) -> [NotificationItem] {
        switch type {
        case .unread:
            return viewModel.notifications.filter { !$0.isRead }
        case .read:
            return viewModel.notifications.filter { $0.isRead }
        }
    }

    private func markAllRead() async {
        let unreadItems = viewModel.notifications.filter { !$0.isRead }

        for item in unreadItems {
            await viewModel.markAsRead(notification: item)
        }
    }
}

private struct NotificationCard: View {
    let title: String
    let message: String
    let timeText: String
    let iconSystemName: String
    let iconBackground: Color
    let isUnread: Bool
    let severityText: String
    let typeText: String

    private var cardBackground: Color {
        isUnread ? Color.blue.opacity(0.10) : Color(.systemBackground)
    }

    private var borderColor: Color {
        isUnread ? Color.blue.opacity(0.25) : Color.clear
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(iconBackground)
                    .frame(width: 54, height: 54)

                Image(systemName: iconSystemName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                    Spacer()
                    Text(timeText)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                }

                Text(message)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    Text(severityText)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(Capsule())

                    Text(typeText)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(borderColor, lineWidth: borderColor == .clear ? 0 : 2)
                )
        )
    }
}

#Preview {
    NavigationStack {
        NotificationsView()
    }
    .environmentObject(NotificationsViewModel())
}

private extension NotificationItem {
    var createdAtText: String {
        guard let createdAt, !createdAt.isEmpty else { return "" }
        return createdAt
    }

    var severityDisplayText: String {
        severity.isEmpty ? "Bilgi" : severity.capitalized
    }

    var notificationTypeDisplayText: String {
        notificationType.isEmpty ? "info" : notificationType.replacingOccurrences(of: "_", with: " ").capitalized
    }

    var iconName: String {
        let lowercasedSeverity = severity.lowercased()
        let lowercasedType = notificationType.lowercased()

        if lowercasedType.contains("air") {
            return "wind"
        }

        if lowercasedType.contains("route") {
            return "map.fill"
        }

        if lowercasedSeverity.contains("high") || lowercasedSeverity.contains("critical") {
            return "exclamationmark.octagon.fill"
        }

        if lowercasedSeverity.contains("medium") || lowercasedSeverity.contains("warning") {
            return "exclamationmark.triangle.fill"
        }

        return "bell.fill"
    }

    var iconBackground: Color {
        let lowercasedSeverity = severity.lowercased()

        if lowercasedSeverity.contains("high") || lowercasedSeverity.contains("critical") {
            return .red
        }

        if lowercasedSeverity.contains("medium") || lowercasedSeverity.contains("warning") {
            return .orange
        }

        if lowercasedSeverity.contains("low") || lowercasedSeverity.contains("success") {
            return .green
        }

        return .blue
    }
}
