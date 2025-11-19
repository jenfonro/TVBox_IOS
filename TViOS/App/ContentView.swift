import SwiftUI

@MainActor
struct ContentView: View {
    var body: some View {
        TabView {
            OnDemandContainerView()
                .tabItem { Label("點播", systemImage: "film") }
            SettingsContainerView()
                .tabItem { Label("設定", systemImage: "gearshape") }
        }
    }
}

@MainActor
private struct OnDemandContainerView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        OnDemandView(
            viewModel: OnDemandViewModel(
                repository: appState.catalogRepository
            )
        )
    }
}

@MainActor
private struct SettingsContainerView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        SettingsView(settings: appState.settings)
            .environmentObject(appState)
    }
}
