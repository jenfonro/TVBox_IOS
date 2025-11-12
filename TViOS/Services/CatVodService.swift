import Foundation

@MainActor
final class CatVodService {
    enum ServiceError: Error, LocalizedError {
        case baseURLMissing

        var errorDescription: String? {
            switch self {
            case .baseURLMissing:
                return "請先設定 CatVod 主機"
            }
        }
    }

    private let client: APIClient
    private let settings: SettingsStore

    init(client: APIClient, settings: SettingsStore) {
        self.client = client
        self.settings = settings
    }

    func refresh(_ type: CatVodActionType) async throws -> String {
        guard let base = settings.baseURL else {
            throw ServiceError.baseURLMissing
        }
        let url = CatVodEndpoints.refresh(baseURL: base, type: type)
        let data = try await client.data(from: url)
        return String(data: data, encoding: .utf8) ?? "ok"
    }

    func setCache(key: String, value: String) async throws {
        guard let base = settings.baseURL else {
            throw ServiceError.baseURLMissing
        }
        let url = CatVodEndpoints.cache(baseURL: base, action: .set, key: key, value: value)
        _ = try await client.data(from: url)
    }

    func deleteCache(key: String) async throws {
        guard let base = settings.baseURL else {
            throw ServiceError.baseURLMissing
        }
        let url = CatVodEndpoints.cache(baseURL: base, action: .del, key: key)
        _ = try await client.data(from: url)
    }
}
