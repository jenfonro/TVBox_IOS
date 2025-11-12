import Foundation

struct MediaCatalog: Codable {
    var style: MediaStyle?
    var sites: [MediaSite]
}

struct MediaSite: Codable, Identifiable {
    let key: String
    let name: String
    let searchable: Int
    let changeable: Int
    let quickSearch: Int
    let indexs: Int
    let hide: Int
    let timeout: Int
    let header: [String: String]?
    let click: String?
    let style: MediaStyle?
    let categories: [MediaCategory]

    var id: String { key }

    enum CodingKeys: String, CodingKey {
        case key, name, searchable, changeable, indexs, hide, timeout, header, click, style, categories
        case quickSearch = "quickserch"
    }
}

struct MediaCategory: Codable, Identifiable {
    let id: String
    let name: String
    let filters: [MediaFilter]
    let items: [MediaItem]
}

struct MediaFilter: Codable, Identifiable {
    let id: String
    let name: String
    let options: [MediaFilterOption]
}

struct MediaFilterOption: Codable, Identifiable {
    let id: String
    let name: String

    enum CodingKeys: String, CodingKey {
        case id = "value"
        case name
    }
}

struct MediaItem: Codable, Identifiable {
    let id: String
    let name: String
    let remarks: String?
    let area: String?
    let director: String?
    let actor: String?
    let year: String?
    let poster: String?
    let style: MediaStyle?
    let playUrl: String?

    var posterURL: URL? { poster.flatMap(URL.init(string:)) }
    var streamURL: URL? { playUrl.flatMap(URL.init(string:)) }
}

struct PlayableItem: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let subtitle: String?
    let artworkURL: URL?
    let streamURL: URL
}
