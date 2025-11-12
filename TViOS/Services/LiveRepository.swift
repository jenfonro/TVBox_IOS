import Foundation

@MainActor
final class LiveRepository {
    enum LiveError: Error, LocalizedError {
        case missingBundleResource

        var errorDescription: String? {
            switch self {
            case .missingBundleResource:
                return "找不到預設的直播資料"
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

    func loadPlaylist(forceRemote: Bool = false) async throws -> LivePlaylist {
        if let url = settings.liveURL {
            do {
                return try await client.get(LivePlaylist.self, from: url, decoder: decoder)
            } catch {
                if forceRemote { throw error }
            }
        }
        return try loadLocalPlaylist()
    }

    private func loadLocalPlaylist() throws -> LivePlaylist {
        guard let resourceURL = Bundle.main.url(forResource: "default_live", withExtension: "json") else {
            throw LiveError.missingBundleResource
        }
        let data = try Data(contentsOf: resourceURL)
        return try decoder.decode(LivePlaylist.self, from: data)
    }
}
