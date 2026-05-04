import SwiftUI
import CoreLocation
import AVFoundation
import Charts

struct HomeView: View {
    @Binding var selectedTab: Tab
    @Binding var showSettings: Bool
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var neighborhoodDetailViewModel = NeighborhoodDetailViewModel()

    struct TargetSelection: Identifiable {
        let id = UUID()
        let value: String
    }

    @State private var showTargetPicker = false
    @State private var showNotifications = false
    @State private var selectedTarget: TargetSelection? = nil

    @State private var showWeatherDetail = false
    @State private var showSuggestedRouteMap = false
    @State private var selectedSection: HomeSection = .neighborhood

    enum HomeSection: String, CaseIterable, Identifiable {
        case neighborhood = "Mahalle Detayı"
        case route = "Rota Öner"
        var id: String { rawValue }
    }

    // MARK: - Fallback Mock Data

    private let fallbackNeighborhoodName = "Modernevler"
    private let fallbackCityName = "Isparta"

    private let fallbackOverallScore = 82
    private let fallbackOverallStatus = "İyi"
    private let fallbackLastUpdateText = "Son güncelleme: 2 dk önce"

    private let airAQI = 42
    private let noiseDb = 63
    private let greenPct = 18

    private let airDetailValue = 78
    private let airDetailStatus = "İyi"
    private let noiseDetailValue = 63
    private let noiseDetailStatus = "Orta"
    private let fallbackWeatherTempText = "18°C"
    private let fallbackWeatherDescription = "Parçalı Bulutlu"

    private let hourly: [HourlyForecast] = [
        .init(hour: "Şimdi", temp: 9, icon: "cloud.sun.fill"),
        .init(hour: "18:00", temp: 8, icon: "cloud.fill"),
        .init(hour: "19:00", temp: 7, icon: "cloud.drizzle.fill"),
        .init(hour: "20:00", temp: 6, icon: "cloud.moon.fill"),
        .init(hour: "21:00", temp: 6, icon: "moon.stars.fill")
    ]

    private var dailyMock: [DailyForecast] {
        [
            .init(day: "Bugün", icon: "cloud.sun.fill", minTemp: 6, maxTemp: 18),
            .init(day: "Sal", icon: "cloud.rain.fill", minTemp: 5, maxTemp: 15),
            .init(day: "Çar", icon: "cloud.fill", minTemp: 4, maxTemp: 13),
            .init(day: "Per", icon: "sun.max.fill", minTemp: 6, maxTemp: 19),
            .init(day: "Cum", icon: "cloud.bolt.rain.fill", minTemp: 7, maxTemp: 16),
            .init(day: "Cmt", icon: "cloud.sun.fill", minTemp: 6, maxTemp: 18),
            .init(day: "Paz", icon: "cloud.snow.fill", minTemp: 0, maxTemp: 8),
            .init(day: "Pzt", icon: "cloud.fill", minTemp: 3, maxTemp: 12),
            .init(day: "Sal", icon: "cloud.rain.fill", minTemp: 4, maxTemp: 14),
            .init(day: "Çar", icon: "sun.max.fill", minTemp: 7, maxTemp: 20)
        ]
    }

    private let suggestedDistanceKm: Double = 1.2
    private let suggestedEtaMin: Int = 12
    private let suggestedScore: Int = 78
    private let suggestedWarning = "Uyarı: Gürültülü alan olabilir"

    private let suggestedDestinationName = "Merkez"
    private let suggestedDestinationCoord = CLLocationCoordinate2D(latitude: 37.7648, longitude: 30.5566)

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        header
                        if let errorMessage = activeErrorMessage {
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
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showTargetPicker) {
                TargetPickerView { target in
                    selectedTarget = TargetSelection(value: target)
                }
            }
            .sheet(item: $selectedTarget) { selection in
                RouteSuggestionView(target: selection.value, selectedTab: $selectedTab)
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
                    hourly: hourly,
                    daily: dailyMock
                )
            }
            .navigationDestination(isPresented: $showSuggestedRouteMap) {
                SuggestedRouteMapView(
                    destinationName: suggestedDestinationName,
                    destinationCoordinate: suggestedDestinationCoord
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
                await viewModel.loadDashboard()
                await neighborhoodDetailViewModel.loadDetails()
            }
        }
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
                        Text("\(overallScore)")
                            .font(.system(size: 42, weight: .heavy, design: .rounded))
                            .foregroundStyle(.primary)

                        Text(overallStatus)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(statusColor(for: overallStatus))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(statusColor(for: overallStatus).opacity(0.12))
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

            Text(lastUpdateText)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                miniMetric(icon: "wind", title: quickMetrics.airQuality.label, value: quickMetrics.airQuality.valueText, unit: quickMetrics.airQuality.unit)
                miniMetric(icon: "speaker.wave.2", title: quickMetrics.noise.label, value: quickMetrics.noise.valueText, unit: quickMetrics.noise.unit)
                miniMetric(icon: "leaf", title: quickMetrics.greenArea.label, value: quickMetrics.greenArea.valueText, unit: quickMetrics.greenArea.unit)
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
        switch status.lowercased() {
        case "iyi": return .green
        case "orta": return .orange
        default: return .red
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

            neighborhoodSummaryCard

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
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
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

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(hourlyForecast) { item in
                        HourlyCard(item: item)
                    }
                }
                .padding(.vertical, 2)
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

            Button {
                showSuggestedRouteMap = true
            } label: {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Bugün önerilen rota")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                        Spacer()
                        Text(activeRouteStatusText)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(activeRouteStatusColor)
                    }

                    HStack(spacing: 14) {
                        Label("\(suggestedEtaMin) dk", systemImage: "clock")
                        Label(String(format: "%.1f km", suggestedDistanceKm), systemImage: "location")
                    }
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)

                    Text(routeWarningText)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(routeWarningColor)
                }
                .padding(16)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            }
            .buttonStyle(.plain)
        }
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

    private var dashboard: DashboardHomeResponse? {
        viewModel.dashboard
    }

    private var neighborhoodDetail: NeighborhoodDetailResponse? {
        neighborhoodDetailViewModel.detail
    }

    private var activeErrorMessage: String? {
        neighborhoodDetailViewModel.errorMessage ?? viewModel.errorMessage
    }

    private var neighborhoodName: String {
        neighborhoodDetail?.neighborhood.name ?? dashboard?.location.neighborhoodName ?? fallbackNeighborhoodName
    }

    private var cityName: String {
        neighborhoodDetail?.neighborhood.city ?? dashboard?.location.city ?? fallbackCityName
    }

    private var districtName: String {
        neighborhoodDetail?.neighborhood.district ?? ""
    }

    private var cityDistrictText: String {
        if districtName.isEmpty {
            return cityName
        }

        return "\(cityName) · \(districtName)"
    }

    private var overallScore: Int {
        Int((dashboard?.environmentScore.score ?? Double(fallbackOverallScore)).rounded())
    }

    private var overallStatus: String {
        dashboard?.environmentScore.category ?? fallbackOverallStatus
    }

    private var lastUpdateText: String {
        dashboard?.environmentScore.lastUpdatedText ?? fallbackLastUpdateText
    }

    private var quickMetrics: QuickMetrics {
        dashboard?.quickMetrics ?? QuickMetrics(
            airQuality: MetricItem(label: "Hava", value: Double(airAQI), unit: "AQI"),
            noise: MetricItem(label: "Gürültü", value: Double(noiseDb), unit: "dB"),
            greenArea: MetricItem(label: "Yeşil", value: Double(greenPct), unit: "%")
        )
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
                CurrentEnvironmentItem(
                    key: "weather",
                    title: "Hava Durumu",
                    value: 18,
                    unit: "°C",
                    status: weatherDesc,
                    statusKey: nil
                )
            ]
        }

        if let items = dashboard?.currentEnvironment, !items.isEmpty {
            return items
        }

        return [
            CurrentEnvironmentItem(
                key: "air_quality",
                title: "Hava Kalitesi",
                value: Double(airDetailValue),
                unit: "AQI",
                status: airDetailStatus,
                statusKey: "good"
            ),
            CurrentEnvironmentItem(
                key: "noise",
                title: "Gürültü",
                value: Double(noiseDetailValue),
                unit: "dB",
                status: noiseDetailStatus,
                statusKey: "moderate"
            ),
            CurrentEnvironmentItem(
                key: "green_area",
                title: "Yeşil Alan",
                value: Double(greenPct),
                unit: "%",
                status: "İyi",
                statusKey: "good"
            ),
            CurrentEnvironmentItem(
                key: "weather",
                title: "Hava Durumu",
                value: 18,
                unit: "°C",
                status: fallbackWeatherDescription,
                statusKey: "cloudy"
            )
        ]
    }

    private var hourlyForecast: [HourlyForecast] {
        if let items = dashboard?.hourlyWeather, !items.isEmpty {
            return items.map {
                HourlyForecast(
                    hour: $0.time,
                    temp: Int($0.temperature.rounded()),
                    icon: weatherIcon(for: $0.condition ?? "")
                )
            }
        }

        return hourly
    }

    private var detailNeighborhoodName: String {
        neighborhoodDetail?.neighborhood.name ?? neighborhoodName
    }

    private var mykiScoreText: String {
        let score = neighborhoodDetail?.myki?.score ?? dashboard?.environmentScore.score ?? Double(fallbackOverallScore)
        return score.formattedMetricValue
    }

    private var mykiCategoryText: String {
        if let category = neighborhoodDetail?.myki?.category, !category.isEmpty {
            return localizedMykiCategory(category)
        }

        return overallStatus
    }

    private var mykiCategoryColor: Color {
        statusColor(for: mykiCategoryText)
    }

    private var detailUpdatedAtText: String {
        if let createdAt = neighborhoodDetail?.latestEnvironmentalData?.createdAt, !createdAt.isEmpty {
            return "Son veri: \(createdAt)"
        }

        return ""
    }

    private var neighborhoodChartSummary: ChartSummary {
        neighborhoodDetail?.chartSummary ?? ChartSummary()
    }

    private var neighborhoodDataSources: [DataSourceSummary] {
        neighborhoodDetail?.dataSources ?? []
    }

    private var unreadNotificationCount: Int {
        dashboard?.notifications.unreadCount ?? 0
    }

    private var hasActiveRoute: Bool {
        dashboard?.navigation.hasActiveRoute ?? false
    }

    private var weatherCard: CurrentEnvironmentItem? {
        currentEnvironmentItems.first(where: { $0.key == "weather" })
    }

    private var weatherTempText: String {
        if let weatherCard {
            return weatherCard.displayValue
        }

        return fallbackWeatherTempText
    }

    private var weatherDesc: String {
        weatherCard?.status ?? fallbackWeatherDescription
    }

    private var activeRouteStatusText: String {
        hasActiveRoute ? "Aktif" : "%\(suggestedScore)"
    }

    private var activeRouteStatusColor: Color {
        hasActiveRoute ? .blue : .green
    }

    private var routeWarningText: String {
        if hasActiveRoute {
            return dashboard?.navigation.activeRoute?.routeName ?? "Aktif rota devam ediyor"
        }

        return suggestedWarning
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
            return weatherIcon(for: item.status ?? "")
        default:
            return "circle.fill"
        }
    }

    private func accentColor(for item: CurrentEnvironmentItem) -> Color {
        switch item.key {
        case "weather":
            return .blue
        default:
            return statusColor(for: item.status ?? "")
        }
    }

    private func weatherIcon(for condition: String) -> String {
        let lowercased = condition.lowercased()

        if lowercased.contains("gunes") || lowercased.contains("sun") {
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
        switch category.lowercased() {
        case "high", "good", "iyi":
            return "İyi"
        case "medium", "orta":
            return "Orta"
        case "low", "poor", "dusuk", "kotu":
            return "Düşük"
        default:
            return category.capitalized
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
        status ?? ""
    }

    var displayValue: String {
        if unit == "%" {
            return "%\(value.formattedMetricValue)"
        }

        let unitText = unit ?? ""
        return "\(value.formattedMetricValue)\(unitText.isEmpty ? "" : " \(unitText)")"
    }
}

private extension Double {
    var formattedMetricValue: String {
        if truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(self))
        }

        return String(format: "%.1f", self)
    }
}
