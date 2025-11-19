import Foundation

@MainActor
final class CatalogRepository {
    struct ConfigPayload {
        let data: Data
        let source: String
    }

    enum CatalogError: Error, LocalizedError {
        case missingBundleResource
        case emptyData(String)
        case invalidFormat(String, String)

        var errorDescription: String? {
            switch self {
            case .missingBundleResource:
                return "找不到預設的點播資料"
            case .emptyData(let source):
                return "來源 \(source) 沒有任何內容"
            case .invalidFormat(let source, let preview):
                return "來源 \(source) 格式錯誤，預覽：\(preview)"
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

    func loadCatalog(forceRemote: Bool = false) async throws -> TVBoxConfig {
        if let endpoint = settings.catalogURL?.absoluteString, !endpoint.isEmpty {
            do {
                var visited = Set<String>()
                let payload = try await loadConfigPayload(from: endpoint, visited: &visited)
                guard !payload.data.isEmpty else { throw CatalogError.emptyData(payload.source) }
                do {
                    return try decoder.decode(TVBoxConfig.self, from: payload.data)
                } catch {
                    let preview = String(data: payload.data, encoding: .utf8)?
                        .prefix(200)
                        .replacingOccurrences(of: "\n", with: " ")
                        ?? "無法轉換為文字"
                    throw CatalogError.invalidFormat(payload.source, String(preview))
                }
            } catch {
                if forceRemote { throw error }
            }
        }
        return try loadLocalCatalog()
    }

    private func loadConfigPayload(from endpoint: String, visited: inout Set<String>) async throws -> ConfigPayload {
        guard !visited.contains(endpoint) else {
            throw ConfigResolverError.invalidURL
        }
        visited.insert(endpoint)
        let resolver = ConfigResolver(client: client)
        let data = try await resolver.loadConfig(from: endpoint)
        if let next = try extractNextConfigURL(from: data) {
            return try await loadConfigPayload(from: next, visited: &visited)
        }
        return ConfigPayload(data: data, source: endpoint)
    }

    private func extractNextConfigURL(from data: Data) -> String? {
        guard
            let object = try? JSONSerialization.jsonObject(with: data, options: []),
            let json = object as? [String: Any]
        else { return nil }
        if let urls = json["urls"] as? [[String: Any]] {
            for item in urls {
                if let urlString = item["url"] as? String, !urlString.isEmpty {
                    return urlString
                }
            }
        }
        return nil
    }

    private func loadLocalCatalog() throws -> TVBoxConfig {
        guard let resourceURL = Bundle.main.url(forResource: "default_catalog", withExtension: "json") else {
            throw CatalogError.missingBundleResource
        }
        let data = try Data(contentsOf: resourceURL)
        return try decoder.decode(TVBoxConfig.self, from: data)
    }
}
