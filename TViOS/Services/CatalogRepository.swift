import Foundation

@MainActor
final class CatalogRepository {
    struct ConfigPayload {
        let data: Data
        let source: String
    }

    enum CatalogError: Error, LocalizedError {
        case emptyData(String)
        case missingEndpoint
        case invalidFormat(String, String)

        var errorDescription: String? {
            switch self {
            case .emptyData(let source):
                return "來源 \(source) 沒有任何內容"
            case .missingEndpoint:
                return "請先在設定中填寫有效的點播位址"
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
        guard let endpoint = settings.catalogURL?.absoluteString,
              !endpoint.isEmpty else {
            throw CatalogError.missingEndpoint
        }
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
}
