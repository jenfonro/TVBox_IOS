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
    var defaultHeaders: [String: String]

    init(proxyProvider: @escaping () -> ProxyConfig? = { nil }) {
        self.proxyProvider = proxyProvider
        self.defaultHeaders = [
            "User-Agent": "Mozilla/5.0 (Linux; Android 11; TVBOX Build/RP1A.200720.011; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/94.0.4606.61 Mobile Safari/537.36",
            "Accept": "application/json,text/plain,*/*",
            "Accept-Language": "zh-CN,zh;q=0.9,en;q=0.8",
            "Accept-Encoding": "gzip, deflate"
        ]
    }

    func get<T: Decodable>(_ type: T.Type, from url: URL, decoder: JSONDecoder = JSONDecoder()) async throws -> T {
        var request = URLRequest(url: url)
        applyDefaultHeaders(to: &request)
        let data = try await data(for: request)
        return try decoder.decode(T.self, from: data)
    }

    func data(from url: URL) async throws -> Data {
        try await data(for: URLRequest(url: url))
    }

    func data(for request: URLRequest) async throws -> Data {
        var request = request
        applyDefaultHeaders(to: &request)
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

    private func applyDefaultHeaders(to request: inout URLRequest) {
        for (key, value) in defaultHeaders where request.value(forHTTPHeaderField: key) == nil {
            request.setValue(value, forHTTPHeaderField: key)
        }
    }
}
