import SwiftUI

struct NotificationsView: View {

    struct AppNotification: Identifiable {
        enum Kind {
            case warningOrange
            case airRed
            case successGreen
            case infoBlue

            var iconName: String {
                switch self {
                case .warningOrange: return "exclamationmark.triangle.fill"
                case .airRed: return "wind"
                case .successGreen: return "chart.line.uptrend.xyaxis"
                case .infoBlue: return "mappin.circle.fill"
                }
            }

            var iconBg: Color {
                switch self {
                case .warningOrange: return .orange
                case .airRed: return .red
                case .successGreen: return .green
                case .infoBlue: return .blue
                }
            }

            var cardBg: Color {
                switch self {
                case .warningOrange, .airRed:
                    return Color.blue.opacity(0.10) // üstteki mavi kutu hissi
                case .successGreen, .infoBlue:
                    return Color.white
                }
            }

            var cardBorder: Color {
                switch self {
                case .warningOrange, .airRed:
                    return Color.blue.opacity(0.25)
                case .successGreen, .infoBlue:
                    return Color.clear
                }
            }
        }

        let id = UUID()
        let kind: Kind
        let title: String
        let message: String
        let timeText: String
        var isUnread: Bool
        let section: SectionType

        enum SectionType: String, CaseIterable {
            case today = "BUGÜN"
            case earlier = "DAHA ÖNCE"
        }
    }

    @State private var items: [AppNotification] = [
        .init(kind: .warningOrange,
              title: "Gürültü Artışı",
              message: "Modernevler'de gürültü seviyesi 75 dB'e yükseldi. Alternatif rota öneriyoruz.",
              timeText: "5 dk önce",
              isUnread: true,
              section: .today),

        .init(kind: .airRed,
              title: "Hava Kalitesi Düşüşü",
              message: "Fatih Mahallesi'nde hava kalitesi 'Orta' seviyesine düştü.",
              timeText: "1 saat önce",
              isUnread: true,
              section: .today),

        .init(kind: .successGreen,
              title: "Yeni Rota Önerisi",
              message: "Daha temiz bir rota bulduk. %15 daha az gürültü, %20 daha iyi hava kalitesi.",
              timeText: "2 saat önce",
              isUnread: false,
              section: .earlier),

        .init(kind: .infoBlue,
              title: "Favori Rotada Risk",
              message: "BUNNA - Merkez rotanızda yüksek gürültü tespit edildi.",
              timeText: "Dün",
              isUnread: false,
              section: .earlier),
    ]

    private var unreadCount: Int { items.filter { $0.isUnread }.count }

    var body: some View {
        List {
            // BUGÜN
            sectionView(.today)

            // DAHA ÖNCE
            sectionView(.earlier)
        }
        .listStyle(.plain)
        .navigationTitle("Bildirimler")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Sağ üst: “Tümünü Okundu İşaretle”
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    markAllRead()
                } label: {
                    Text("Tümünü Okundu İşaretle")
                        .font(.system(size: 15, weight: .semibold))
                }
            }
        }
    }

    @ViewBuilder
    private func sectionView(_ type: AppNotification.SectionType) -> some View {
        let filtered = items.filter { $0.section == type }
        if !filtered.isEmpty {
            Section {
                ForEach(filtered) { n in
                    NotificationCard(
                        title: n.title,
                            message: n.message,
                            timeText: n.timeText,
                            iconSystemName: n.kind.iconName,
                            iconBackground: n.kind.iconBg,
                            isUnread: n.isUnread
                    )
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                    .onTapGesture {
                        // örnek: tıklanınca okundu yap
                        markRead(n.id)
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

    private func markAllRead() {
        for idx in items.indices {
            items[idx].isUnread = false
        }
    }

    private func markRead(_ id: UUID) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        items[idx].isUnread = false
    }
}

private struct NotificationCard: View {
    let title: String
    let message: String
    let timeText: String
    let iconSystemName: String
    let iconBackground: Color
    let isUnread: Bool

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
}
