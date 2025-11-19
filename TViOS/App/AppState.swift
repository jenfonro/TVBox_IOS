import Foundation

@MainActor
final class AppState: ObservableObject {
    let settings: SettingsStore
    let apiClient: APIClient
    lazy var catalogRepository = CatalogRepository(client: apiClient, settings: settings)

    init() {
        let store = SettingsStore()
        self.settings = store
        self.apiClient = APIClient(
            proxyProvider: { store.proxy },
            headersProvider: { store.requestMode.defaultHeaders }
        )
    }
}
