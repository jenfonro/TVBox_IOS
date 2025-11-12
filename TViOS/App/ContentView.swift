import SwiftUI

@MainActor
struct ContentView: View {
    var body: some View {
        TabView {
            OnDemandContainerView()
                .tabItem { Label("點播", systemImage: "film") }
            LiveContainerView()
                .tabItem { Label("直播", systemImage: "tv") }
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
                repository: appState.catalogRepository,
                playbackController: appState.playbackController
            )
        )
    }
}

@MainActor
private struct LiveContainerView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        LiveView(
            viewModel: LiveViewModel(
                repository: appState.liveRepository,
                playbackController: appState.playbackController
            )
        )
    }
}

@MainActor
private struct SettingsContainerView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        SettingsView(
            settings: appState.settings,
            catVodService: appState.catVodService
        )
    }
}
