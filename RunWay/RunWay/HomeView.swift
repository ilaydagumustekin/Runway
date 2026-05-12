import SwiftUI
import Combine
import CoreLocation
import AVFoundation
import Charts

struct HomeView: View {
    @Binding var selectedTab: Tab
    @Binding var showSettings: Bool
    @EnvironmentObject private var appSession: AppSession
    @EnvironmentObject private var authSession: AuthSession
    @EnvironmentObject private var favoritesViewModel: FavoritesViewModel
    @EnvironmentObject private var notificationsViewModel: NotificationsViewModel
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var neighborhoodDetailViewModel = NeighborhoodDetailViewModel()

    struct TargetSelection: Identifiable {
        let id = UUID()
        let name: String
        let coordinate: CLLocationCoordinate2D
    }

    @State private var showTargetPicker = false
    @State private var showNotifications = false
    @State private var selectedTarget: TargetSelection? = nil

    @State private var showWeatherDetail = false
    @State private var selectedSection: HomeSection = .neighborhood
    @State private var hasLoadedInitialData = false
    /// Son dashboard isteğinde kullanılan GPS (otomatik yenileme için).
    @State private var lastDashboardGPS: CLLocation?
    @State private var lastDashboardAutoReloadAt: Date = .distantPast

    enum HomeSection: String, CaseIterable, Identifiable {
        case neighborhood = "Mahalle Detayı"
        case route = "Rota Öner"
        var id: String { rawValue }
    }

    /// `navigation.active_route` ile harita hedefi (mock koordinat yok).
    private struct ActiveRouteMapTarget: Identifiable, Hashable {
        let id: String
        let name: String
        let latitude: Double
        let longitude: Double

        var coordinate: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    }

    @State private var activeRouteMapTarget: ActiveRouteMapTarget?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        header
                        if appSession.manualNeighborhoodId != nil,
                           let manualName = appSession.manualNeighborhoodName {
                            manualSelectionBanner(name: manualName)
                        }
                        if let errorMessage = primaryHomeErrorMessage {
                            errorBanner(message: errorMessage)
                        }
                        heroScoreCard
                        homeSegment
                        homeSectionContent
                        Spacer().frame(height: 18)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
                .refreshable {
                    await refreshHomeData()
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showTargetPicker) {
                TargetPickerView { target in
                    selectedTarget = TargetSelection(name: target.name, coordinate: target.coordinate)
                }
            }
            .sheet(item: $selectedTarget) { selection in
                RouteSuggestionView(
                    target: selection.name,
                    destinationCoordinate: selection.coordinate,
                    selectedTab: $selectedTab
                )
            }
            .navigationDestination(isPresented: $showNotifications) {
                NotificationsView()
            }
            .navigationDestination(isPresented: $showWeatherDetail) {
                HourlyWeatherDetailView(
                    cityName: cityName,
                    neighborhoodName: neighborhoodName,
                    currentTempText: weatherTempText,
                    currentDesc: weatherDesc,
                    hourly: hourlyForecast,
                    daily: []
                )
            }
            .navigationDestination(item: $activeRouteMapTarget) { target in
                SuggestedRouteMapView(
                    destinationName: target.name,
                    destinationCoordinate: target.coordinate
                )
            }
            .onAppear {
                AppLocationManager.shared.requestPermission()
                AppLocationManager.shared.startUpdating()

                if #available(iOS 17.0, *) {
                    AVAudioApplication.requestRecordPermission { _ in }
                } else {
                    AVAudioSession.sharedInstance().requestRecordPermission { _ in }
                }
            }
            .task {
                guard !hasLoadedInitialData else { return }
                hasLoadedInitialData = true
                await loadHomeDashboard()
                await loadFavoritesIfPossible()
                await notificationsViewModel.loadNotifications()
            }
            .onChange(of: appSession.manualNeighborhoodId) { _, _ in
                Task { await loadHomeDashboard() }
            }
            .onReceive(AppLocationManager.shared.$lastLocation.compactMap { $0 }) { loc in
                Task { await considerReloadDashboardIfLocationImproved(loc) }
            }
        }
    }

    private func manualSelectionBanner(name: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "map.circle.fill")
                .font(.title2)
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("Haritadan seçilen mahalle")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                Text(name)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
            }

            Spacer()

            Button("Konumuma dön") {
                appSession.clearManualSelection()
            }
            .font(.system(size: 14, weight: .bold, design: .rounded))
        }
        .padding(14)
        .background(Color.orange.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func loadHomeDashboard() async {
        if appSession.manualNeighborhoodId != nil {
            lastDashboardGPS = nil
        }

        if let manualId = appSession.manualNeighborhoodId {
            RunWayDebugLog.home("loading home data for neighborhoodId=\(manualId) (manual map selection, no lat/lon on /home)")
            await viewModel.loadDashboard(manualNeighborhoodId: manualId, latitude: nil, longitude: nil)
        } else {
            let loc = await AppLocationManager.shared.waitForBestLocation(timeoutSeconds: 18, desiredAccuracy: 45)
            let coord = loc?.coordinate ?? AppLocationManager.shared.lastLocation?.coordinate
            lastDashboardGPS = loc
            if let c = coord {
                RunWayDebugLog.location(
                    "home load GPS chosen: lat=\(c.latitude), lon=\(c.longitude), hAcc_m=\(loc?.horizontalAccuracy ?? -1) "
                        + "(same coordinate used for GET /dashboard/home latitude & longitude)"
                )
                #if DEBUG
                RunWayLocationDebugGeocoder.logReverseGeocode(coordinate: c)
                #endif
            } else {
                RunWayDebugLog.location("home load GPS chosen: nil (no coordinate)")
            }
            await viewModel.loadDashboard(
                manualNeighborhoodId: nil,
                latitude: coord?.latitude,
                longitude: coord?.longitude
            )
        }

        if let d = viewModel.dashboard, d.location.neighborhoodId > 0 {
            let greenPercent = viewModel.integrationGreenAreaPercent ?? d.quickMetrics.greenArea.value
            appSession.setDashboardQuickMetricsHint(
                neighborhoodId: d.location.neighborhoodId,
                airQualityAqi: d.quickMetrics.airQuality.value,
                greenAreaPercent: greenPercent
            )
        } else {
            appSession.clearDashboardQuickMetricsHint()
        }

        if let nid = viewModel.dashboard?.location.neighborhoodId, nid > 0 {
            RunWayDebugLog.home("scheduling neighborhood detail fetch for neighborhoodId=\(nid)")
            appSession.updateAnalysisNeighborhood(id: nid)
            await neighborhoodDetailViewModel.loadDetails(neighborhoodId: nid)
        }
    }

    private func considerReloadDashboardIfLocationImproved(_ loc: CLLocation) async {
        guard appSession.manualNeighborhoodId == nil else { return }
        guard hasLoadedInitialData else { return }
        guard loc.horizontalAccuracy > 0, loc.horizontalAccuracy <= 42 else { return }
        guard let baseline = lastDashboardGPS else { return }

        let moved = baseline.distance(from: loc)
        guard moved > 200 else { return }

        let now = Date()
        guard now.timeIntervalSince(lastDashboardAutoReloadAt) > 28 else { return }

        lastDashboardAutoReloadAt = now
        lastDashboardGPS = loc
        RunWayDebugLog.home(
            "auto reload dashboard: moved_m=\(Int(moved)) newLat=\(loc.coordinate.latitude) newLon=\(loc.coordinate.longitude)"
        )
        await loadHomeDashboard()
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(neighborhoodName)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                HStack(spacing: 6) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Text(cityDistrictText)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            HStack(spacing: 10) {
                iconButton(system: "bell") { showNotifications = true }
                iconButton(system: "gearshape") { showSettings = true }
            }
        }
        .padding(.top, 6)
    }

    private func iconButton(system: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: system)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                if system == "bell", unreadNotificationCount > 0 {
                    Text("\(min(unreadNotificationCount, 99))")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.red)
                        .clipShape(Capsule())
                        .offset(x: 6, y: -6)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Hero Card

    private var heroScoreCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Genel Çevre Skoru")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)

                    HStack(alignment: .lastTextBaseline, spacing: 10) {
                        Text(heroScoreText)
                            .font(.system(size: 42, weight: .heavy, design: .rounded))
                            .foregroundStyle(.primary)

                        Text(heroCategoryText)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(statusColor(for: heroCategoryText))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(statusColor(for: heroCategoryText).opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }

                Spacer()

                Image(systemName: "aqi.low")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.primary)
                    .padding(12)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            if !lastUpdateText.isEmpty {
                Text(lastUpdateText)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                miniMetric(icon: "wind", title: quickMetrics.airQuality.label, value: metricValueDisplay(quickMetrics.airQuality), unit: quickMetrics.airQuality.unit)
                miniMetric(icon: "speaker.wave.2", title: quickMetrics.noise.label, value: metricValueDisplay(quickMetrics.noise), unit: quickMetrics.noise.unit)
                miniMetric(icon: "leaf", title: quickMetrics.greenArea.label, value: greenAreaHeroValueText, unit: quickMetrics.greenArea.unit)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(Color.black.opacity(0.04), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.06), radius: 14, x: 0, y: 10)
    }

    private func miniMetric(icon: String, title: String, value: String, unit: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)

                HStack(spacing: 4) {
                    Text(value)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text(unit)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func statusColor(for status: String) -> Color {
        let trimmed = status.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed == "—" {
            return .secondary
        }
        let k = trimmed.lowercased(with: Locale(identifier: "tr_TR"))
        switch k {
        case "iyi", "çok iyi", "mükemmel":
            return .green
        case "orta":
            return .orange
        case "düşük", "çok düşük", "sağlıksız", "tehlikeli":
            return .red
        default:
            return .red
        }
    }

    // MARK: - Segment

    private var homeSegment: some View {
        HStack(spacing: 0) {
            ForEach(HomeSection.allCases) { section in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
                        selectedSection = section
                    }
                } label: {
                    Text(section.rawValue)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundStyle(selectedSection == section ? .white : .secondary)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(selectedSection == section ? Color(.label) : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var homeSectionContent: some View {
        Group {
            switch selectedSection {
            case .neighborhood:
                neighborhoodDetailPanel
            case .route:
                routePanel
            }
        }
    }

    // MARK: - Neighborhood

    private var neighborhoodDetailPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Anlık Çevre Durumu")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .padding(.top, 4)

            if let detailErr = neighborhoodDetailLoadError {
                neighborhoodDetailWarningBanner(message: detailErr)
            }

            neighborhoodSummaryCard

            if currentEnvironmentItems.isEmpty {
                Text("Anlık çevre verisi için dashboard veya mahalle detayı bekleniyor.")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(currentEnvironmentItems) { item in
                        modernStatCard(
                            title: item.title,
                            value: item.displayValue,
                            subtitle: item.statusText,
                            icon: iconName(for: item),
                            accent: accentColor(for: item)
                        )
                    }
                }
            }

            hourlyForecastPanel
            chartSummaryPanel
            dataSourcesPanel
        }
    }

    private var neighborhoodSummaryCard: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(detailNeighborhoodName)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                Text(cityDistrictText)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)

                if !detailUpdatedAtText.isEmpty {
                    Text(detailUpdatedAtText)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Text(currentLocationText)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                Button {
                    Task {
                        await toggleFavorite()
                    }
                } label: {
                    Image(systemName: favoritesViewModel.isFavoriteCurrentNeighborhood ? "heart.fill" : "heart")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(favoritesViewModel.isFavoriteCurrentNeighborhood ? Color.red : .secondary)
                        .frame(width: 36, height: 36)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)

                Text("MYKI")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)

                Text(mykiScoreText)
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(.primary)

                Text(mykiCategoryText)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(mykiCategoryColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(mykiCategoryColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func modernStatCard(title: String, value: String, subtitle: String, icon: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                WeatherSymbol(name: icon)
                    .font(.system(size: 18, weight: .bold))

                Spacer()

                Text(subtitle)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(accent.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(.primary)

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 6)
    }

    private var hourlyForecastPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Saatlik Hava")
                    .font(.system(size: 18, weight: .bold, design: .rounded))

                Spacer()

                Button {
                    showWeatherDetail = true
                } label: {
                    Text("Tümü ›")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            if hourlyForecast.isEmpty {
                Text("Saatlik hava verisi API’de yok veya henüz yüklenmedi.")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(hourlyForecast) { item in
                            HourlyCard(item: item)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var chartSummaryPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Grafik Özeti")
                .font(.system(size: 18, weight: .bold, design: .rounded))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                MiniChartCard(title: "AQI", values: neighborhoodChartSummary.aqi, color: .blue)
                MiniChartCard(title: "Gürültü", values: neighborhoodChartSummary.noiseLevelDba, color: .orange)
                MiniChartCard(title: "Yeşil Alan", values: neighborhoodChartSummary.greenAreaRatio, color: .green)
                MiniChartCard(title: "MYKI", values: neighborhoodChartSummary.mykiScore, color: .purple)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var dataSourcesPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Veri Kaynakları")
                .font(.system(size: 18, weight: .bold, design: .rounded))

            if neighborhoodDataSources.isEmpty {
                Text("Henüz veri kaynağı bilgisi yok.")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(neighborhoodDataSources) { source in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(source.name)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(.primary)

                            Text(source.typeDisplayText)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(.secondary)

                            Text(source.statusDisplayText)
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(.primary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color(.systemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    // MARK: - Route

    private var routePanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Rota Önerileri")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .padding(.top, 4)

            Button {
                showTargetPicker = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "location.magnifyingglass")
                        .font(.system(size: 16, weight: .bold))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Hedef seç")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                        Text("En sağlıklı rotayı bulalım")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.secondary)
                }
                .foregroundStyle(.primary)
                .padding(14)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 6)
            }
            .buttonStyle(.plain)

            activeRouteCard
        }
    }

    private var activeRouteCard: some View {
        Group {
            if let target = activeRouteMapTargetFromDashboard() {
                Button {
                    activeRouteMapTarget = target
                } label: {
                    activeRouteCardContent(
                        title: "Aktif rota",
                        subtitle: dashboard?.navigation.activeRoute?.routeName ?? "Rota devam ediyor",
                        detail: "Haritada rotayı göster",
                        status: "Aktif",
                        statusColor: .blue,
                        footnote: routeWarningText
                    )
                }
                .buttonStyle(.plain)
            } else if hasActiveRoute {
                activeRouteCardContent(
                    title: "Aktif rota",
                    subtitle: dashboard?.navigation.activeRoute?.routeName ?? "Rota",
                    detail: "Hedef koordinatları API yanıtında yok; harita açılamıyor.",
                    status: "Aktif",
                    statusColor: .blue,
                    footnote: routeWarningText
                )
            } else {
                activeRouteCardContent(
                    title: "Aktif rota",
                    subtitle: "Şu an devam eden bir rota yok.",
                    detail: "Hedef seçerek yeni rota oluşturabilirsiniz.",
                    status: "Yok",
                    statusColor: .secondary,
                    footnote: routeWarningText
                )
            }
        }
    }

    private func activeRouteMapTargetFromDashboard() -> ActiveRouteMapTarget? {
        guard let route = dashboard?.navigation.activeRoute,
              let lat = route.destinationLatitude,
              let lon = route.destinationLongitude
        else { return nil }
        let id = String(route.navigationSessionId ?? 0)
        let name = route.routeName ?? "Hedef"
        return ActiveRouteMapTarget(id: id, name: name, latitude: lat, longitude: lon)
    }

    private func activeRouteCardContent(
        title: String,
        subtitle: String,
        detail: String,
        status: String,
        statusColor: Color,
        footnote: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                Spacer()
                Text(status)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(statusColor)
            }

            Text(subtitle)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)

            Text(detail)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)

            Text(footnote)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(routeWarningColor)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func errorBanner(message: String) -> some View {
        Text(message)
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(.red)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.red.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    /// Mahalle detayı (`/neighborhood/...`) hatası: dashboard çalışsa bile üstte kırmızı banner göstermeyiz; kullanıcıyı yanıltıyor.
    private func neighborhoodDetailWarningBanner(message: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text(message)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
            }
            Button {
                Task {
                    let id = currentNeighborhoodId
                    guard id > 0 else { return }
                    await neighborhoodDetailViewModel.loadDetails(neighborhoodId: id)
                }
            } label: {
                Text("Tekrar dene")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.orange.opacity(0.18))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)

            Text("Özet ve anlık kartlar `/dashboard/home` verisinden gelmeye devam eder.")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var dashboard: DashboardHomeResponse? {
        viewModel.dashboard
    }

    private var neighborhoodDetail: NeighborhoodDetailResponse? {
        neighborhoodDetailViewModel.detail
    }

    /// Dashboard, favoriler ve bildirim hataları. Mahalle detayı 500 olsa bile burada gösterilmez (aşağıda ayrı uyarı).
    private var primaryHomeErrorMessage: String? {
        viewModel.errorMessage
            ?? favoritesViewModel.errorMessage
            ?? notificationsViewModel.errorMessage
    }

    private var neighborhoodDetailLoadError: String? {
        neighborhoodDetailViewModel.errorMessage
    }

    private var neighborhoodName: String {
        if let name = neighborhoodDetail?.neighborhood.name, !name.isEmpty { return name }
        if let name = dashboard?.location.neighborhoodName, !name.isEmpty { return name }
        return viewModel.isLoading ? "Yükleniyor…" : "—"
    }

    private var cityName: String {
        if let c = neighborhoodDetail?.neighborhood.city, !c.isEmpty { return c }
        if let c = dashboard?.location.city, !c.isEmpty { return c }
        return "—"
    }

    private var districtName: String {
        if let d = neighborhoodDetail?.neighborhood.district, !d.isEmpty { return d }
        if let d = dashboard?.location.district, !d.isEmpty { return d }
        return ""
    }

    private var cityDistrictText: String {
        if dashboard == nil && neighborhoodDetail == nil {
            return viewModel.isLoading ? "Dashboard yükleniyor…" : "Konum veya mahalle bilgisi yok"
        }
        if districtName.isEmpty {
            return cityName
        }

        return "\(cityName) · \(districtName)"
    }

    private var currentLocationText: String {
        guard let coordinate = AppLocationManager.shared.lastLocation?.coordinate else {
            return "Canlı konum alınıyor..."
        }
        let lat = String(format: "%.5f", coordinate.latitude)
        let lon = String(format: "%.5f", coordinate.longitude)
        return "Konum: \(lat), \(lon)"
    }

    private var heroScoreText: String {
        // Alt karttaki MYKİ ile birebir aynı değeri göster: önce mahalle detayı `myki.score`,
        // yoksa dashboard `environment_score.score`. Yuvarlama yok; ondalık korunur (73.8 → "73.8").
        if let score = neighborhoodDetail?.myki?.score {
            return score.formattedMetricValue
        }
        if let dashboard {
            return dashboard.environmentScore.score.formattedMetricValue
        }
        return viewModel.isLoading ? "…" : "—"
    }

    private var heroCategoryText: String {
        guard let dashboard else {
            return viewModel.isLoading ? "" : "—"
        }
        // Dashboard `environment_score.category` ile mahalle `myki.category` bazen aynı skorda çelişiyor;
        // skorlar hizalıysa tek kaynak olarak detay MYKİ etiketini kullan (alt kartla aynı).
        if let myki = neighborhoodDetail?.myki {
            let mykiCat = myki.category.trimmingCharacters(in: .whitespacesAndNewlines)
            if !mykiCat.isEmpty, heroAndMykiScoresAligned(dashboard: dashboard, myki: myki) {
                return localizedMykiCategory(myki.category)
            }
        }
        let rawCat = dashboard.environmentScore.category.trimmingCharacters(in: .whitespacesAndNewlines)
        let rawKey = dashboard.environmentScore.categoryKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let raw = rawCat.isEmpty ? rawKey : rawCat
        return raw.isEmpty ? "—" : localizedMykiCategory(raw)
    }

    private func heroAndMykiScoresAligned(dashboard: DashboardHomeResponse, myki: MykiInfo) -> Bool {
        abs(myki.score - dashboard.environmentScore.score) <= 1.0
    }

    private var lastUpdateText: String {
        guard let text = dashboard?.environmentScore.lastUpdatedText,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return dashboard == nil ? (viewModel.isLoading ? "…" : "") : "—"
        }
        return text
    }

    private var quickMetrics: QuickMetrics {
        dashboard?.quickMetrics ?? .waitingForDashboard
    }

    /// Anasayfa yeşil mini metriği: önce `/integrations/green-area-analysis` → `analysis.green_percentage`, yoksa `quick_metrics.green_area`.
    private var displayGreenAreaPercent: Double {
        viewModel.integrationGreenAreaPercent ?? quickMetrics.greenArea.value
    }

    private var greenAreaHeroValueText: String {
        guard dashboard != nil else {
            return viewModel.isLoading ? "…" : "—"
        }
        return displayGreenAreaPercent.formattedMetricValue
    }

    private func metricValueDisplay(_ item: MetricItem) -> String {
        guard dashboard != nil else {
            return viewModel.isLoading ? "…" : "—"
        }
        return item.valueText
    }

    private var currentEnvironmentItems: [CurrentEnvironmentItem] {
        if let latestData = neighborhoodDetail?.latestEnvironmentalData {
            return [
                CurrentEnvironmentItem(
                    key: "air_quality",
                    title: "Hava Kalitesi",
                    value: latestData.aqi,
                    unit: "AQI",
                    status: airStatus(for: latestData.aqi),
                    statusKey: nil
                ),
                CurrentEnvironmentItem(
                    key: "pm25",
                    title: "PM2.5",
                    value: latestData.pm25,
                    unit: "ug/m3",
                    status: airStatus(for: latestData.pm25),
                    statusKey: nil
                ),
                CurrentEnvironmentItem(
                    key: "pm10",
                    title: "PM10",
                    value: latestData.pm10,
                    unit: "ug/m3",
                    status: airStatus(for: latestData.pm10),
                    statusKey: nil
                ),
                CurrentEnvironmentItem(
                    key: "noise",
                    title: "Gürültü",
                    value: latestData.noiseLevelDba,
                    unit: "dB",
                    status: noiseStatus(for: latestData.noiseLevelDba),
                    statusKey: nil
                ),
                CurrentEnvironmentItem(
                    key: "green_area",
                    title: "Yeşil Alan",
                    value: latestData.greenAreaRatio,
                    unit: "%",
                    status: greenAreaStatus(for: latestData.greenAreaRatio),
                    statusKey: nil
                ),
                weatherEnvironmentItem()
            ]
        }

        if let items = dashboard?.currentEnvironment, !items.isEmpty {
            return items
        }

        return []
    }

    private var hourlyForecast: [HourlyForecast] {
        if let items = dashboard?.hourlyWeather, !items.isEmpty {
            return items.map {
                HourlyForecast(
                    hour: $0.time,
                    temp: Int($0.temperature.rounded()),
                    icon: weatherSymbolForConditionKey($0.condition)
                )
            }
        }

        return []
    }

    private func weatherEnvironmentItem() -> CurrentEnvironmentItem {
        if let w = dashboard?.currentEnvironment.first(where: { $0.key == "weather" }) {
            return CurrentEnvironmentItem(
                key: w.key,
                title: w.title,
                value: w.value,
                unit: w.unit,
                status: w.status,
                statusKey: w.statusKey
            )
        }
        return CurrentEnvironmentItem(
            key: "weather",
            title: "Hava Durumu",
            value: 0,
            unit: "°C",
            status: nil,
            statusKey: nil
        )
    }

    private func weatherSymbolForConditionKey(_ key: String?) -> String {
        guard let key, !key.isEmpty else { return "cloud.sun.fill" }
        switch key.lowercased() {
        case "clear":
            return "sun.max.fill"
        case "mostly_clear":
            return "sun.haze.fill"
        case "sunny":
            return "sun.max.fill"
        case "partly_cloudy":
            return "cloud.sun.fill"
        case "cloudy":
            return "cloud.sun.fill"
        case "fog":
            return "cloud.fog.fill"
        case "drizzle":
            return "cloud.drizzle.fill"
        case "rain":
            return "cloud.rain.fill"
        case "snow":
            return "cloud.snow.fill"
        case "thunderstorm":
            return "cloud.bolt.rain.fill"
        case "variable":
            return "cloud.sun.fill"
        default:
            return weatherIcon(for: key)
        }
    }

    private var detailNeighborhoodName: String {
        neighborhoodDetail?.neighborhood.name ?? neighborhoodName
    }

    private var mykiScoreText: String {
        if let score = neighborhoodDetail?.myki?.score {
            return score.formattedMetricValue
        }
        if let dashboard {
            return dashboard.environmentScore.score.formattedMetricValue
        }
        return viewModel.isLoading ? "…" : "—"
    }

    private var mykiCategoryText: String {
        if let category = neighborhoodDetail?.myki?.category, !category.isEmpty {
            return localizedMykiCategory(category)
        }
        let cat = dashboard?.environmentScore.category.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let key = dashboard?.environmentScore.categoryKey.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let fromDashboard = cat.isEmpty ? key : cat
        if !fromDashboard.isEmpty {
            return localizedMykiCategory(fromDashboard)
        }
        return heroCategoryText
    }

    private var mykiCategoryColor: Color {
        statusColor(for: mykiCategoryText)
    }

    private var detailUpdatedAtText: String {
        if let createdAt = neighborhoodDetail?.latestEnvironmentalData?.createdAt, !createdAt.isEmpty {
            let formatted = RunWayAPIInstantFormatting.turkishDisplayString(from: createdAt) ?? createdAt
            return "Son veri: \(formatted)"
        }

        return ""
    }

    private var neighborhoodChartSummary: ChartSummary {
        neighborhoodDetail?.chartSummary ?? ChartSummary()
    }

    private var neighborhoodDataSources: [DataSourceSummary] {
        neighborhoodDetail?.dataSources ?? []
    }

    private var currentNeighborhoodId: Int {
        neighborhoodDetail?.neighborhood.id ?? dashboard?.location.neighborhoodId ?? 1
    }

    private var unreadNotificationCount: Int {
        if !notificationsViewModel.notifications.isEmpty {
            return notificationsViewModel.unreadCount
        }

        return dashboard?.notifications.unreadCount ?? 0
    }

    private var hasActiveRoute: Bool {
        dashboard?.navigation.hasActiveRoute ?? false
    }

    private var dashboardWeatherItem: CurrentEnvironmentItem? {
        dashboard?.currentEnvironment.first(where: { $0.key == "weather" })
    }

    private var weatherTempText: String {
        if let dashboardWeatherItem {
            return dashboardWeatherItem.displayValue
        }

        return viewModel.isLoading ? "…" : "—"
    }

    private var currentWeatherDescription: String {
        if let s = dashboardWeatherItem?.status, !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return s
        }
        return dashboard == nil && viewModel.isLoading ? "…" : "—"
    }

    private var weatherDesc: String {
        currentWeatherDescription
    }

    private var routeWarningText: String {
        if hasActiveRoute {
            return dashboard?.navigation.activeRoute?.routeName ?? "Aktif rota devam ediyor"
        }

        return "Aktif rota yok. Hedef seçerek yeni rota oluşturabilirsiniz."
    }

    private var routeWarningColor: Color {
        hasActiveRoute ? .blue : .orange
    }

    private func iconName(for item: CurrentEnvironmentItem) -> String {
        switch item.key {
        case "air_quality":
            return "wind"
        case "pm25", "pm10":
            return "aqi.medium"
        case "noise":
            return "speaker.wave.2"
        case "green_area":
            return "leaf"
        case "weather":
            return weatherSymbolForConditionKey(item.statusKey ?? item.status)
        default:
            return "circle.fill"
        }
    }

    private func accentColor(for item: CurrentEnvironmentItem) -> Color {
        switch item.key {
        case "weather":
            return .blue
        default:
            let s = (item.status ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if s.isEmpty {
                return .secondary
            }
            return statusColor(for: s)
        }
    }

    private func weatherIcon(for condition: String) -> String {
        let lowercased = condition.lowercased()

        if lowercased == "clear" || lowercased == "mostly_clear" {
            return lowercased == "clear" ? "sun.max.fill" : "sun.haze.fill"
        }

        if lowercased.contains("gunes") || lowercased.contains("sun") || lowercased.contains("açık") {
            return "sun.max.fill"
        }

        if lowercased.contains("yagmur") || lowercased.contains("rain") || lowercased.contains("drizzle") {
            return "cloud.rain.fill"
        }

        if lowercased.contains("firtina") || lowercased.contains("storm") || lowercased.contains("thunder") {
            return "cloud.bolt.rain.fill"
        }

        if lowercased.contains("kar") || lowercased.contains("snow") {
            return "cloud.snow.fill"
        }

        if lowercased.contains("bulut") || lowercased.contains("cloud") {
            return "cloud.sun.fill"
        }

        return "cloud.sun.fill"
    }

    private func localizedMykiCategory(_ category: String) -> String {
        let key = category
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "_", with: " ")
            .lowercased(with: Locale(identifier: "tr_TR"))

        switch key {
        case "very high", "veryhigh", "excellent", "mükemmel", "mukemmel":
            return "Çok iyi"
        case "high", "good", "iyi":
            return "İyi"
        case "medium", "orta", "moderate", "fair":
            return "Orta"
        case "low", "poor", "bad", "dusuk", "düşük", "kotu", "kötü":
            return "Düşük"
        case "very low", "verylow":
            return "Çok düşük"
        case "unhealthy", "sağlıksız":
            return "Sağlıksız"
        case "hazardous", "tehlikeli":
            return "Tehlikeli"
        default:
            let spaced = category.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "_", with: " ")
            return spaced.capitalized(with: Locale(identifier: "tr_TR"))
        }
    }

    private func airStatus(for value: Double) -> String {
        switch value {
        case ..<50:
            return "İyi"
        case ..<100:
            return "Orta"
        default:
            return "Düşük"
        }
    }

    private func noiseStatus(for value: Double) -> String {
        switch value {
        case ..<55:
            return "İyi"
        case ..<70:
            return "Orta"
        default:
            return "Düşük"
        }
    }

    private func greenAreaStatus(for value: Double) -> String {
        switch value {
        case 30...:
            return "İyi"
        case 15...:
            return "Orta"
        default:
            return "Düşük"
        }
    }

    private func loadFavoritesIfPossible() async {
        do {
            let token = try await authSession.loginIfNeeded()
            await favoritesViewModel.loadFavorites(token: token)
            favoritesViewModel.checkIsFavorite(neighborhoodId: currentNeighborhoodId)
        } catch {
            print("Favorites bootstrap error:", error)
        }
    }

    private func toggleFavorite() async {
        do {
            let token = try await authSession.loginIfNeeded()
            await favoritesViewModel.toggleFavorite(
                neighborhoodId: currentNeighborhoodId,
                token: token
            )
            favoritesViewModel.checkIsFavorite(neighborhoodId: currentNeighborhoodId)
        } catch {
            print("Toggle favorite error:", error)
        }
    }

    private func refreshHomeData() async {
        AppLocationManager.shared.requestPermission()
        AppLocationManager.shared.startUpdating()
        await loadHomeDashboard()
    }
}

struct HourlyCard: View {
    let item: HourlyForecast

    var body: some View {
        VStack(spacing: 10) {
            Text(item.hour)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)

            WeatherSymbol(name: item.icon)
                .font(.system(size: 22, weight: .semibold))

            Text("\(item.temp)°")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
        }
        .frame(width: 74, height: 92)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 6)
    }
}

private struct MiniChartCard: View {
    let title: String
    let values: [Double]
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                Spacer()
                Text(latestValueText)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Chart(Array(values.enumerated()), id: \.offset) { index, value in
                LineMark(
                    x: .value("Index", index),
                    y: .value("Value", value)
                )
                .foregroundStyle(color)
                .interpolationMethod(.catmullRom)

                AreaMark(
                    x: .value("Index", index),
                    y: .value("Value", value)
                )
                .foregroundStyle(
                    .linearGradient(
                        colors: [color.opacity(0.22), color.opacity(0.04)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: 90)
        }
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var latestValueText: String {
        guard let last = values.last else { return "Veri yok" }
        return last.formattedMetricValue
    }
}

private extension MetricItem {
    var valueText: String {
        value.formattedMetricValue
    }
}

private extension DataSourceSummary {
    var typeDisplayText: String {
        type
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }

    var statusDisplayText: String {
        status
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }
}

private extension CurrentEnvironmentItem {
    var statusText: String {
        let t = (status ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? "—" : t
    }

    var displayValue: String {
        if unit == "%" {
            return "%\(value.formattedMetricValue)"
        }

        let unitText = unit ?? ""
        return "\(value.formattedMetricValue)\(unitText.isEmpty ? "" : " \(unitText)")"
    }
}
