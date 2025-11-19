import Foundation

@MainActor
final class CatalogRepository {
    enum CatalogError: Error, LocalizedError {
        case missingBundleResource

        var errorDescription: String? {
            switch self {
            case .missingBundleResource:
                return "找不到預設的點播資料"
            }
        }
    }

    private let client: APIClient
    private let settings: SettingsStore
    private let decoder = JSONDecoder()

    init(client: APIClient, settings: SettingsStore) {
        self.client = client
        self.settings = settings
    }

    func loadCatalog(forceRemote: Bool = false) async throws -> MediaCatalog {
        if let endpoint = settings.catalogURL?.absoluteString, !endpoint.isEmpty {
            do {
                let resolver = ConfigResolver(client: client)
                let data = try await resolver.loadConfig(from: endpoint)
                return try decoder.decode(MediaCatalog.self, from: data)
            } catch {
                if forceRemote { throw error }
            }
        }
        return try loadLocalCatalog()
    }

    private func loadLocalCatalog() throws -> MediaCatalog {
        guard let resourceURL = Bundle.main.url(forResource: "default_catalog", withExtension: "json") else {
            throw CatalogError.missingBundleResource
        }
        let data = try Data(contentsOf: resourceURL)
        return try decoder.decode(MediaCatalog.self, from: data)
    }
}
