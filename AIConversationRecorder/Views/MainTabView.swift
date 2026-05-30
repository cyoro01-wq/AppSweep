import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var homeViewModel = HomeViewModel()

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            NavigationStack {
                HomeView()
            }
            .tabItem { Label("ホーム", systemImage: "house.fill") }
            .tag(0)

            NavigationStack {
                RecordingView()
            }
            .tabItem { Label("録音", systemImage: "mic.fill") }
            .tag(1)

            NavigationStack {
                RecordsListView()
            }
            .tabItem { Label("記録", systemImage: "list.bullet") }
            .tag(2)

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label("設定", systemImage: "gearshape.fill") }
            .tag(3)
        }
        .environmentObject(homeViewModel)
    }
}
