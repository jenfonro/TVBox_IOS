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
                var visited = Set<String>()
                let data = try await loadConfigData(from: endpoint, visited: &visited)
                return try decoder.decode(MediaCatalog.self, from: data)
            } catch {
                if forceRemote { throw error }
            }
        }
        return try loadLocalCatalog()
    }

    private func loadConfigData(from endpoint: String, visited: inout Set<String>) async throws -> Data {
        guard !visited.contains(endpoint) else {
            throw ConfigResolverError.invalidURL
        }
        visited.insert(endpoint)
        let resolver = ConfigResolver(client: client)
        let data = try await resolver.loadConfig(from: endpoint)
        if let next = try extractNextConfigURL(from: data) {
            return try await loadConfigData(from: next, visited: &visited)
        }
        return data
    }

    private func extractNextConfigURL(from data: Data) throws -> String? {
        let object = try JSONSerialization.jsonObject(with: data, options: [])
        guard let json = object as? [String: Any] else { return nil }
        if let urls = json["urls"] as? [[String: Any]] {
            for item in urls {
                if let urlString = item["url"] as? String, !urlString.isEmpty {
                    return urlString
                }
            }
        }
        return nil
    }

    private func loadLocalCatalog() throws -> MediaCatalog {
        guard let resourceURL = Bundle.main.url(forResource: "default_catalog", withExtension: "json") else {
            throw CatalogError.missingBundleResource
        }
        let data = try Data(contentsOf: resourceURL)
        return try decoder.decode(MediaCatalog.self, from: data)
    }
}
