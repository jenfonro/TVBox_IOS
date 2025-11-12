import Foundation

struct LivePlaylist: Codable {
    let groups: [LiveGroup]
}

struct LiveGroup: Codable, Identifiable {
    let id: String
    let name: String
    let channels: [LiveChannel]
}

struct LiveChannel: Codable, Identifiable {
    let id: String
    let name: String
    let logo: String?
    let epg: String?
    let url: String
    let ua: String?
    let referer: String?
    let origin: String?
    let timeout: Int?
    let description: String?

    var logoURL: URL? { logo.flatMap(URL.init(string:)) }
    var streamURL: URL? { URL(string: url) }
}
