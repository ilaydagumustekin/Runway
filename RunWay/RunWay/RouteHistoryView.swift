import SwiftUI

struct RouteHistoryView: View {

    @Binding var selectedTab: Tab

    enum Filter: CaseIterable, Identifiable {
        case all
        case favorites

        var id: String { key }

        private var key: String {
            switch self {
            case .all: return "all"
            case .favorites: return "favorites"
            }
        }
    }

    @State private var filter: Filter = .all

    private var favoritesCount: Int {
        routes.filter { $0.isFavorite }.count
    }


    @State private var routes: [RouteItem] = [
        .init(
            from: "Zafer Mahallesi",
            to: "Fatih Mahallesi",
            dateText: "22 Şubat 2026",
            timeText: "14:30",
            durationText: "12 dk",
            distanceText: "1.2 km",
            score: 78,
            scoreStyle: .good,
            tags: [],
            isFavorite: true
        ),
        .init(
            from: "Modernevler",
            to: "Merkez",
            dateText: "21 Şubat 2026",
            timeText: "09:15",
            durationText: "18 dk",
            distanceText: "2.1 km",
            score: 65,
            scoreStyle: .mid,
            tags: [.init(text: "Yüksek gürültü", style: .warn)],
            isFavorite: false
        ),
        .init(
            from: "Zafer Mahallesi",
            to: "Bahçelievler",
            dateText: "20 Şubat 2026",
            timeText: "16:45",
            durationText: "15 dk",
            distanceText: "1.8 km",
            score: 82,
            scoreStyle: .good,
            tags: [],
            isFavorite: true
        ),
        .init(
            from: "Fatih Mahallesi",
            to: "Çünür",
            dateText: "19 Şubat 2026",
            timeText: "11:20",
            durationText: "22 dk",
            distanceText: "2.8 km",
            score: 58,
            scoreStyle: .bad,
            tags: [
                .init(text: "Düşük hava kalitesi", style: .warn),
                .init(text: "Yoğun trafik", style: .danger)
            ],
            isFavorite: false
        )
    ]

    private var filteredRoutesIndices: [Int] {
        switch filter {
        case .all:
            return Array(routes.indices)
        case .favorites:
            return routes.indices.filter { routes[$0].isFavorite }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {

                        header

                        filterTabs

                        VStack(spacing: 14) {
                            ForEach(filteredRoutesIndices, id: \.self) { idx in
                                RouteCard(item: $routes[idx])
                            }
                        }

                        Spacer().frame(height: 16)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 24)
                }
            }
            .navigationBarHidden(true)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {

            // Geri = Ana sayfa tab’ına dön
            Button {
                selectedTab = .home
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.primary)
                    .frame(width: 40, height: 40)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text("Rota Geçmişi")
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                Text("\(routes.count) rota")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    // MARK: - Tabs

    private var filterTabs: some View {
        HStack(spacing: 12) {
            tabButton(
                icon: "clock",
                title: "Tüm Rotalar",
                isSelected: filter == .all
            ) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    filter = .all
                }
            }

            tabButton(
                icon: "star",
                title: "Favoriler (\(favoritesCount))",
                isSelected: filter == .favorites
            ) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    filter = .favorites
                }
            }
        }
    }

    private func tabButton(
        icon: String,
        title: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                Text(title)
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
            }
            .foregroundStyle(isSelected ? .white : .primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color(.label) : Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Models

    struct RouteItem: Identifiable {
        let id = UUID()

        let from: String
        let to: String
        let dateText: String
        let timeText: String

        let durationText: String
        let distanceText: String

        let score: Int
        let scoreStyle: ScoreStyle

        let tags: [RouteTag]
        var isFavorite: Bool
    }

    enum ScoreStyle {
        case good, mid, bad

        var bg: Color {
            switch self {
            case .good: return Color.green.opacity(0.15)
            case .mid: return Color.yellow.opacity(0.18)
            case .bad: return Color.red.opacity(0.14)
            }
        }

        var fg: Color {
            switch self {
            case .good: return Color.green
            case .mid: return Color.orange
            case .bad: return Color.red
            }
        }

        var icon: String {
            switch self {
            case .good: return "arrow.up.right"
            case .mid: return "arrow.up.right"
            case .bad: return "arrow.down.right"
            }
        }
    }

    struct RouteTag: Identifiable {
        let id = UUID()
        let text: String
        let style: RouteTagStyle
    }

    enum RouteTagStyle {
        case warn, danger

        var bg: Color {
            switch self {
            case .warn: return Color.orange.opacity(0.14)
            case .danger: return Color.red.opacity(0.12)
            }
        }

        var fg: Color {
            switch self {
            case .warn: return Color.orange
            case .danger: return Color.red
            }
        }

        var icon: String {
            switch self {
            case .warn: return "exclamationmark.triangle.fill"
            case .danger: return "exclamationmark.octagon.fill"
            }
        }
    }

    // MARK: - Card

    struct RouteCard: View {
        @Binding var item: RouteItem

        var body: some View {
            VStack(alignment: .leading, spacing: 12) {

                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.secondary)

                            Text("\(item.from) → \(item.to)")
                                .font(.system(size: 18, weight: .heavy, design: .rounded))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                        }

                        Text("\(item.dateText)  •  \(item.timeText)")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            item.isFavorite.toggle()
                        }
                    } label: {
                        Image(systemName: item.isFavorite ? "heart.fill" : "heart")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(item.isFavorite ? Color.red : Color.gray.opacity(0.55))
                            .padding(6)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }

                HStack(spacing: 14) {
                    metaPill(icon: "clock", text: item.durationText)
                    metaPill(icon: "point.topleft.down.curvedto.point.bottomright.up", text: item.distanceText)

                    Spacer()

                    scoreBadge(score: item.score, style: item.scoreStyle)
                }

                if !item.tags.isEmpty {
                    HStack(spacing: 10) {
                        ForEach(item.tags) { t in
                            tagChip(t)
                        }
                    }
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: Color.black.opacity(0.06), radius: 14, x: 0, y: 10)
        }

        private func metaPill(icon: String, text: String) -> some View {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.secondary)
                Text(text)
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(.primary)
            }
        }

        private func scoreBadge(score: Int, style: ScoreStyle) -> some View {
            HStack(spacing: 8) {
                Image(systemName: style.icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(style.fg)
                Text("\(score)%")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(style.fg)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(style.bg)
            .clipShape(Capsule())
        }

        private func tagChip(_ tag: RouteTag) -> some View {
            HStack(spacing: 8) {
                Image(systemName: tag.style.icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(tag.style.fg)
                Text(tag.text)
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(tag.style.fg)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(tag.style.bg)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}

#Preview {
    RouteHistoryView(selectedTab: .constant(.home))
}
