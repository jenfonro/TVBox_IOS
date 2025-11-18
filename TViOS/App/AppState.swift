import Foundation

@MainActor
final class AppState: ObservableObject {
    let settings: SettingsStore
    let apiClient: APIClient
    lazy var catalogRepository = CatalogRepository(client: apiClient, settings: settings)
    lazy var catVodService = CatVodService(client: apiClient, settings: settings)
    let playbackController = PlaybackController()

    init() {
        let store = SettingsStore()
        self.settings = store
        self.apiClient = APIClient(proxyProvider: { store.proxy })
    }
}
