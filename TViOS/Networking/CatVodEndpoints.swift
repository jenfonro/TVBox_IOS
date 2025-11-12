import Foundation

enum CatVodActionType: String, CaseIterable {
    case detail
    case player
    case live
    case subtitle
    case danmaku
}

enum CatVodCacheAction: String {
    case set
    case get
    case del
}

enum CatVodEndpoints {
    static func refresh(baseURL: URL, type: CatVodActionType) -> URL {
        var components = URLComponents(url: baseURL.appendingPathComponent("action"), resolvingAgainstBaseURL: false) ?? URLComponents()
        components.queryItems = [
            URLQueryItem(name: "do", value: "refresh"),
            URLQueryItem(name: "type", value: type.rawValue)
        ]
        return components.url ?? baseURL
    }

    static func subtitle(baseURL: URL, remotePath: URL) -> URL {
        var components = URLComponents(url: baseURL.appendingPathComponent("action"), resolvingAgainstBaseURL: false) ?? URLComponents()
        components.queryItems = [
            URLQueryItem(name: "do", value: "refresh"),
            URLQueryItem(name: "type", value: "subtitle"),
            URLQueryItem(name: "path", value: remotePath.absoluteString)
        ]
        return components.url ?? baseURL
    }

    static func cache(baseURL: URL, action: CatVodCacheAction, key: String, value: String? = nil) -> URL {
        var components = URLComponents(url: baseURL.appendingPathComponent("cache"), resolvingAgainstBaseURL: false) ?? URLComponents()
        var queryItems = [
            URLQueryItem(name: "do", value: action.rawValue),
            URLQueryItem(name: "key", value: key)
        ]
        if let value, action == .set {
            queryItems.append(URLQueryItem(name: "value", value: value))
        }
        components.queryItems = queryItems
        return components.url ?? baseURL
    }
}
