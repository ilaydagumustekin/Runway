import SwiftUI
import AVFoundation

enum Tab: Hashable {
    case home
    case map
    case activeRoute
    case routes
    case integrations
}

struct ContentView: View {
    @AppStorage("RunWay.hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var selectedTab: Tab = .home
    @State private var showSettings = false
    @StateObject private var appSession = AppSession()
    @StateObject private var authSession = AuthSession.shared
    @StateObject private var favoritesViewModel = FavoritesViewModel()
    @StateObject private var notificationsViewModel = NotificationsViewModel()

    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                OnboardingView()
            } else if authSession.isAuthenticated {
                TabView(selection: $selectedTab) {
                    HomeView(selectedTab: $selectedTab, showSettings: $showSettings)
                        .tabItem { Label("Ana Sayfa", systemImage: "house") }
                        .tag(Tab.home)

                    NeighborhoodMapExplorerView(
                        onPick: { id, name in
                            appSession.setManualNeighborhood(id: id, name: name)
                            selectedTab = .home
                        },
                        showDismiss: false
                    )
                    .tabItem { Label("Harita", systemImage: "map") }
                    .tag(Tab.map)

                    ActiveRouteView(selectedTab: $selectedTab)
                        .tabItem { Label("Aktif Rota", systemImage: "location.north.line") }
                        .tag(Tab.activeRoute)

                    RouteHistoryView(selectedTab: $selectedTab)
                        .tabItem { Label("Rotalarım", systemImage: "clock") }
                        .tag(Tab.routes)

                    IntegrationsHubView()
                        .tabItem { Label("Analiz", systemImage: "waveform.path.ecg") }
                        .tag(Tab.integrations)
                }
            } else {
                AuthGateView()
            }
        }
        .environmentObject(appSession)
        .environmentObject(authSession)
        .environmentObject(favoritesViewModel)
        .environmentObject(notificationsViewModel)
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(authSession)
        }
        .onChange(of: authSession.isAuthenticated) { _, authenticated in
            guard authenticated else { return }
            // Ana ekran auth sonrası yüklendiğinde izin pencerelerinin kesin tetiklenmesi
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                AppLocationManager.shared.requestPermission()
                AppLocationManager.shared.startUpdating()

                if #available(iOS 17.0, *) {
                    AVAudioApplication.requestRecordPermission { _ in }
                } else {
                    AVAudioSession.sharedInstance().requestRecordPermission { _ in }
                }
            }
        }
    }
}
