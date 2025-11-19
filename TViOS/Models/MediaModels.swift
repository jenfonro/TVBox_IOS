import Foundation

struct TVBoxConfig: Codable {
    var spider: String?
    var wallpaper: String?
    var sites: [TVBoxSite]
}

struct TVBoxSite: Codable, Identifiable {
    let key: String
    let name: String
    let type: Int?
    let api: String?
    let searchable: Int?
    let quickSearch: Int?
    let changeable: Int?
    let filterable: Int?
    let playerType: Int?
    let timeout: Int?
    let ext: TVBoxSiteExtra?
    let jar: String?
    let click: String?

    var id: String { key }

    var metadataDescription: String {
        var items: [String] = []
        if let type { items.append("type: \(type)") }
        if let api, !api.isEmpty { items.append("api: \(api)") }
        if let searchable { items.append("searchable: \(searchable)") }
        if let quickSearch { items.append("quickSearch: \(quickSearch)") }
        if let changeable { items.append("changeable: \(changeable)") }
        if let filterable { items.append("filterable: \(filterable)") }
        if let playerType { items.append("playerType: \(playerType)") }
        return items.joined(separator: " | ")
    }
}

struct TVBoxSiteExtra: Codable {
    let json: String?
    let requestHeaders: String?
    let other: [String: String]?

    enum CodingKeys: String, CodingKey {
        case json
        case requestHeaders = "请求头"
        case other
    }
}
