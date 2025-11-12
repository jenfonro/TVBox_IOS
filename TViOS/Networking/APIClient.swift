import Foundation

struct APIClient {
    enum APIError: Error, LocalizedError {
        case invalidResponse
        case unacceptableStatus(Int)

        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "無效的伺服器回應"
            case .unacceptableStatus(let code):
                return "HTTP 狀態碼：\(code)"
            }
        }
    }

    var proxyProvider: () -> ProxyConfig?

    init(proxyProvider: @escaping () -> ProxyConfig? = { nil }) {
        self.proxyProvider = proxyProvider
    }

    func get<T: Decodable>(_ type: T.Type, from url: URL, decoder: JSONDecoder = JSONDecoder()) async throws -> T {
        var request = URLRequest(url: url)
        request.setValue("iOSTV/1.0", forHTTPHeaderField: "User-Agent")
        let data = try await data(for: request)
        return try decoder.decode(T.self, from: data)
    }

    func data(from url: URL) async throws -> Data {
        try await data(for: URLRequest(url: url))
    }

    func data(for request: URLRequest) async throws -> Data {
        let (data, response) = try await session().data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw APIError.unacceptableStatus(httpResponse.statusCode)
        }
        return data
    }

    private func session() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 25
        configuration.timeoutIntervalForResource = 60
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        if let proxy = proxyProvider(), !proxy.connectionDictionary.isEmpty {
            configuration.connectionProxyDictionary = proxy.connectionDictionary
        }
        return URLSession(configuration: configuration)
    }
}
