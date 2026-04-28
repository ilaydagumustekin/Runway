import SwiftUI
import CoreLocation
import AVFoundation

struct HomeView: View {
    @Binding var selectedTab: Tab
    @Binding var showSettings: Bool

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

    // MARK: - Mock Data

    private let neighborhoodName = "Modernevler"
    private let cityName = "Isparta"

    private let overallScore = 82
    private let overallStatus = "İyi"
    private let lastUpdateText = "Son güncelleme: 2 dk önce"

    private let airAQI = 42
    private let noiseDb = 63
    private let greenPct = 18

    private let airDetailValue = 78
    private let airDetailStatus = "İyi"
    private let noiseDetailValue = 63
    private let noiseDetailStatus = "Orta"
    private let weatherTempText = "18°C"
    private let weatherDesc = "Parçalı Bulutlu"

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
            }        }
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
                    Text(cityName)
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
            Image(systemName: system)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: 40, height: 40)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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
                miniMetric(icon: "wind", title: "Hava", value: "\(airAQI)", unit: "AQI")
                miniMetric(icon: "speaker.wave.2", title: "Gürültü", value: "\(noiseDb)", unit: "dB")
                miniMetric(icon: "leaf", title: "Yeşil", value: "\(greenPct)", unit: "%")
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

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                modernStatCard(
                    title: "Hava Kalitesi",
                    value: "\(airDetailValue)",
                    subtitle: airDetailStatus,
                    icon: "wind",
                    accent: statusColor(for: airDetailStatus)
                )

                modernStatCard(
                    title: "Gürültü",
                    value: "\(noiseDetailValue) dB",
                    subtitle: noiseDetailStatus,
                    icon: "speaker.wave.2",
                    accent: statusColor(for: noiseDetailStatus)
                )

                modernStatCard(
                    title: "Yeşil Alan",
                    value: "%\(greenPct)",
                    subtitle: "İyi",
                    icon: "leaf",
                    accent: .green
                )

                modernStatCard(
                    title: "Hava Durumu",
                    value: weatherTempText,
                    subtitle: weatherDesc,
                    icon: "cloud.sun.fill",
                    accent: .blue
                )
            }

            hourlyForecastPanel
        }
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
                    ForEach(hourly) { item in
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
                        Text("%\(suggestedScore)")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(.green)
                    }

                    HStack(spacing: 14) {
                        Label("\(suggestedEtaMin) dk", systemImage: "clock")
                        Label(String(format: "%.1f km", suggestedDistanceKm), systemImage: "location")
                    }
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)

                    Text(suggestedWarning)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.orange)
                }
                .padding(16)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            }
            .buttonStyle(.plain)
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
