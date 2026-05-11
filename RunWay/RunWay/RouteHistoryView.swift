import SwiftUI

struct RouteHistoryView: View {
    @Binding var selectedTab: Tab
    @StateObject private var viewModel = RouteHistoryViewModel()
    @State private var filter: Filter = .all
    @State private var hasLoadedRoutes = false

    enum Filter {
        case all
        case favorites
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        header
                        filterTabs

                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(.red)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.red.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }

                        if filter == .favorites {
                            favoriteRouteList
                        } else {
                            routeList
                        }

                        Spacer().frame(height: 16)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 24)
                }
            }
            .navigationBarHidden(true)
            .task {
                guard !hasLoadedRoutes else { return }
                hasLoadedRoutes = true
                await viewModel.loadRoutes()
            }
            .onChange(of: filter) { _, newValue in
                Task {
                    switch newValue {
                    case .favorites:
                        await viewModel.loadFavoriteRoutes()
                    case .all:
                        await viewModel.reloadRoutes()
                    }
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
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
                Text(headerSubtitle)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    private var headerSubtitle: String {
        switch filter {
        case .all:
            return "\(viewModel.routes.count) rota"
        case .favorites:
            return "\(viewModel.favoriteRoutes.count) favori rota"
        }
    }

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
                title: "Favoriler (\(viewModel.favoriteRoutes.count))",
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

    private var routeList: some View {
        VStack(spacing: 14) {
            if viewModel.routes.isEmpty, !viewModel.isLoading {
                emptyState(text: "Henüz rota geçmişi yok.")
            } else {
                ForEach(viewModel.routes) { route in
                    RouteCard(
                        item: route,
                        onToggleFavorite: { await viewModel.toggleFavorite(route: route) },
                        onDelete: { await viewModel.deleteRoute(route) }
                    )
                }
            }
        }
    }

    private var favoriteRouteList: some View {
        VStack(spacing: 14) {
            if viewModel.favoriteRoutes.isEmpty, !viewModel.isLoading {
                emptyState(text: "Henüz favori rota yok.")
            } else {
                ForEach(viewModel.favoriteRoutes) { route in
                    RouteCard(
                        item: route,
                        onToggleFavorite: { await viewModel.toggleFavorite(route: route) },
                        onDelete: { await viewModel.deleteRoute(route) }
                    )
                }
            }
        }
    }

    private func emptyState(text: String) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
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

    struct RouteCard: View {
        let item: RouteHistoryItem
        let onToggleFavorite: () async -> Void
        let onDelete: () async -> Void

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.routeTitleText)
                            .font(.system(size: 17, weight: .heavy, design: .rounded))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)

                        Text(item.dateTimeDisplayText)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(.tertiary)
                    }

                    Spacer()

                    HStack(spacing: 2) {
                        Button {
                            Task { await onToggleFavorite() }
                        } label: {
                            Image(systemName: item.isFavorite ? "heart.fill" : "heart")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(item.isFavorite ? Color.red : Color.gray.opacity(0.45))
                                .padding(7)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        Button {
                            Task { await onDelete() }
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(Color.gray.opacity(0.45))
                                .padding(7)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }

                Text(item.metaSubtitle)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)

                HStack {
                    scoreBadge(score: item.scoreDisplayValue, style: item.scoreStyle)
                    Spacer()
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: Color.black.opacity(0.06), radius: 14, x: 0, y: 10)
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
    }
}

#Preview {
    RouteHistoryView(selectedTab: .constant(.home))
}

private extension RouteHistoryItem {
    var routeTitleText: String {
        let origin = originName?.isEmpty == false ? originName! : "Konumunuz"
        if let dest = destinationName, !dest.isEmpty {
            return "\(origin) → \(dest)"
        }
        return routeName.isEmpty ? "Rota" : routeName
    }

    var transportModeDisplayText: String {
        switch transportMode {
        case "walking": return "Yürüyüş"
        case "bicycle": return "Bisiklet"
        case "scooter": return "Scooter"
        default: return ""
        }
    }

    var metaSubtitle: String {
        var parts: [String] = []
        let modeText = transportModeDisplayText
        if !modeText.isEmpty { parts.append(modeText) }
        if let min = estimatedDurationMinutes { parts.append("\(min) dk") }
        let dist = resolvedDistanceText
        if dist != "--" { parts.append(dist) }
        return parts.joined(separator: " • ")
    }

    private var resolvedDistanceText: String {
        if let km = distanceKm, km > 0 {
            return String(format: "%.1f km", km)
        }
        guard
            let startLatitude, let startLongitude,
            let destinationLatitude, let destinationLongitude
        else { return "--" }
        let latDelta = destinationLatitude - startLatitude
        let lonDelta = destinationLongitude - startLongitude
        let approxKm = sqrt((latDelta * latDelta) + (lonDelta * lonDelta)) * 111
        guard approxKm > 0 else { return "--" }
        return String(format: "%.1f km", approxKm)
    }

    var dateTimeDisplayText: String {
        guard let createdAt, !createdAt.isEmpty else { return "Tarih yok" }
        let components = createdAt.split(separator: "T", maxSplits: 1).map(String.init)
        if components.count == 2 {
            let timeText = components[1].prefix(5)
            return "\(components[0])  •  \(timeText)"
        }
        return createdAt
    }

    var scoreDisplayValue: Int {
        Int((environmentalScore ?? 0).rounded())
    }

    var scoreStyle: RouteHistoryView.ScoreStyle {
        let score = environmentalScore ?? 0
        switch score {
        case 75...: return .good
        case 60..<75: return .mid
        default: return .bad
        }
    }
}
