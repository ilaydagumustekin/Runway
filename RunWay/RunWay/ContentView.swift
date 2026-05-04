import SwiftUI

enum Tab: Hashable {
    case home
    case activeRoute
    case routes
}

struct ContentView: View {
    @State private var selectedTab: Tab = .home
    @State private var showSettings = false
    @StateObject private var authSession = AuthSession.shared
    @StateObject private var favoritesViewModel = FavoritesViewModel()

    var body: some View {
        TabView(selection: $selectedTab) {

            HomeView(selectedTab: $selectedTab, showSettings: $showSettings)
                .tabItem { Label("Ana Sayfa", systemImage: "house") }
                .tag(Tab.home)

            ActiveRouteView(selectedTab: $selectedTab)
                .tabItem { Label("Aktif Rota", systemImage: "location.north.line") }
                .tag(Tab.activeRoute)

            
            RouteHistoryView(selectedTab: $selectedTab)
                .tabItem { Label("Rotalarım", systemImage: "clock") }
                .tag(Tab.routes)
        }
        .environmentObject(authSession)
        .environmentObject(favoritesViewModel)
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}
