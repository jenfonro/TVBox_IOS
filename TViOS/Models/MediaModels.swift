import Foundation

struct TVBoxConfig: Codable {
    var spider: String?
    var wallpaper: String?
    var logo: String?
    var notice: String?
    var sites: [TVBoxSite]
    var lives: [TVBoxLive]
    var parses: [TVBoxParse]
    var rules: [TVBoxRule]
    var headers: [TVBoxHeaderRule]
    var hosts: [String]
    var flags: [String]
    var ads: [String]
    var proxy: [TVBoxProxyRule]
    var doh: [TVBoxDoH]
    var urls: [TVBoxDepot]

    private enum CodingKeys: String, CodingKey {
        case spider, wallpaper, logo, notice, sites, lives, parses, rules, headers, hosts, flags, ads, proxy, doh, urls
    }

    init(
        spider: String? = nil,
        wallpaper: String? = nil,
        logo: String? = nil,
        notice: String? = nil,
        sites: [TVBoxSite] = [],
        lives: [TVBoxLive] = [],
        parses: [TVBoxParse] = [],
        rules: [TVBoxRule] = [],
        headers: [TVBoxHeaderRule] = [],
        hosts: [String] = [],
        flags: [String] = [],
        ads: [String] = [],
        proxy: [TVBoxProxyRule] = [],
        doh: [TVBoxDoH] = [],
        urls: [TVBoxDepot] = []
    ) {
        self.spider = spider
        self.wallpaper = wallpaper
        self.logo = logo
        self.notice = notice
        self.sites = sites
        self.lives = lives
        self.parses = parses
        self.rules = rules
        self.headers = headers
        self.hosts = hosts
        self.flags = flags
        self.ads = ads
        self.proxy = proxy
        self.doh = doh
        self.urls = urls
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.spider = try container.decodeIfPresent(String.self, forKey: .spider)
        self.wallpaper = try container.decodeIfPresent(String.self, forKey: .wallpaper)
        self.logo = try container.decodeIfPresent(String.self, forKey: .logo)
        self.notice = try container.decodeIfPresent(String.self, forKey: .notice)
        self.sites = try container.decodeIfPresent([TVBoxSite].self, forKey: .sites) ?? []
        self.lives = try container.decodeIfPresent([TVBoxLive].self, forKey: .lives) ?? []
        self.parses = try container.decodeIfPresent([TVBoxParse].self, forKey: .parses) ?? []
        self.rules = try container.decodeIfPresent([TVBoxRule].self, forKey: .rules) ?? []
        self.headers = try container.decodeIfPresent([TVBoxHeaderRule].self, forKey: .headers) ?? []
        self.hosts = try container.decodeIfPresent([String].self, forKey: .hosts) ?? []
        self.flags = try container.decodeIfPresent([String].self, forKey: .flags) ?? []
        self.ads = try container.decodeIfPresent([String].self, forKey: .ads) ?? []
        self.proxy = try container.decodeIfPresent([TVBoxProxyRule].self, forKey: .proxy) ?? []
        self.doh = try container.decodeIfPresent([TVBoxDoH].self, forKey: .doh) ?? []
        self.urls = try container.decodeIfPresent([TVBoxDepot].self, forKey: .urls) ?? []
    }
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
    let ext: JSONValue?
    let jar: String?
    let click: String?
    let playUrl: String?
    let categories: [String]?
    let header: JSONValue?
    let style: TVBoxCardStyle?
    let hide: Int?
    let indexs: Int?

    var id: String { key }
    var isSearchable: Bool { (searchable ?? 1) == 1 }
    var isQuickSearch: Bool { (quickSearch ?? 1) == 1 }
    var isChangeable: Bool { (changeable ?? 1) == 1 }

    var metadataDescription: String {
        var items: [String] = []
        if let type { items.append("type: \(type)") }
        if let api, !api.isEmpty { items.append("api: \(api)") }
        if let searchable { items.append("search: \(searchable)") }
        if let quickSearch { items.append("quick: \(quickSearch)") }
        if let changeable { items.append("change: \(changeable)") }
        if let filterable { items.append("filter: \(filterable)") }
        if let playerType { items.append("player: \(playerType)") }
        return items.joined(separator: " | ")
    }

    var extPairs: [(String, String)] {
        guard let ext else { return [] }
        switch ext {
        case .object(let dict):
            return dict
                .map { ($0.key, $0.value.displayValue) }
                .sorted { $0.0 < $1.0 }
        default:
            return [("value", ext.displayValue)]
        }
    }
    private enum CodingKeys: String, CodingKey {
        case key, name, type, api, searchable, quickSearch, changeable, filterable, playerType, timeout, ext, jar, click, playUrl, categories, header, style, hide, indexs
    }

    init(
        key: String,
        name: String,
        type: Int? = nil,
        api: String? = nil,
        searchable: Int? = nil,
        quickSearch: Int? = nil,
        changeable: Int? = nil,
        filterable: Int? = nil,
        playerType: Int? = nil,
        timeout: Int? = nil,
        ext: JSONValue? = nil,
        jar: String? = nil,
        click: String? = nil,
        playUrl: String? = nil,
        categories: [String]? = nil,
        header: JSONValue? = nil,
        style: TVBoxCardStyle? = nil,
        hide: Int? = nil,
        indexs: Int? = nil
    ) {
        self.key = key
        self.name = name
        self.type = type
        self.api = api
        self.searchable = searchable
        self.quickSearch = quickSearch
        self.changeable = changeable
        self.filterable = filterable
        self.playerType = playerType
        self.timeout = timeout
        self.ext = ext
        self.jar = jar
        self.click = click
        self.playUrl = playUrl
        self.categories = categories
        self.header = header
        self.style = style
        self.hide = hide
        self.indexs = indexs
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.key = try container.decode(String.self, forKey: .key)
        self.name = try container.decode(String.self, forKey: .name)
        self.type = container.decodeFlexibleInt(forKey: .type)
        self.api = try container.decodeIfPresent(String.self, forKey: .api)
        self.searchable = container.decodeFlexibleInt(forKey: .searchable)
        self.quickSearch = container.decodeFlexibleInt(forKey: .quickSearch)
        self.changeable = container.decodeFlexibleInt(forKey: .changeable)
        self.filterable = container.decodeFlexibleInt(forKey: .filterable)
        self.playerType = container.decodeFlexibleInt(forKey: .playerType)
        self.timeout = container.decodeFlexibleInt(forKey: .timeout)
        self.ext = try container.decodeIfPresent(JSONValue.self, forKey: .ext)
        self.jar = try container.decodeIfPresent(String.self, forKey: .jar)
        self.click = try container.decodeIfPresent(String.self, forKey: .click)
        self.playUrl = try container.decodeIfPresent(String.self, forKey: .playUrl)
        self.categories = try container.decodeIfPresent([String].self, forKey: .categories)
        self.header = try container.decodeIfPresent(JSONValue.self, forKey: .header)
        self.style = try container.decodeIfPresent(TVBoxCardStyle.self, forKey: .style)
        self.hide = container.decodeFlexibleInt(forKey: .hide)
        self.indexs = container.decodeFlexibleInt(forKey: .indexs)
    }
}

struct TVBoxCardStyle: Codable {
    let type: String?
    let ratio: Double?

    var resolvedType: String { type ?? "rect" }
    var resolvedRatio: Double {
        guard let ratio, ratio > 0 else { return resolvedType == "oval" ? 1.0 : 0.75 }
        return min(4, ratio)
    }
}

struct TVBoxLive: Codable, Identifiable {
    var id: String { name }
    let name: String
    let type: Int?
    let url: String
    let epg: String?
    let logo: String?

    private enum CodingKeys: String, CodingKey { case name, type, url, epg, logo }

    init(name: String, type: Int? = nil, url: String, epg: String? = nil, logo: String? = nil) {
        self.name = name
        self.type = type
        self.url = url
        self.epg = epg
        self.logo = logo
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.type = container.decodeFlexibleInt(forKey: .type)
        self.url = try container.decode(String.self, forKey: .url)
        self.epg = try container.decodeIfPresent(String.self, forKey: .epg)
        self.logo = try container.decodeIfPresent(String.self, forKey: .logo)
    }
}

struct TVBoxParse: Codable, Identifiable {
    var id: String { name }
    let name: String
    let type: Int?
    let url: String?
    let ext: TVBoxParseExt?

    private enum CodingKeys: String, CodingKey { case name, type, url, ext }

    init(name: String, type: Int? = nil, url: String? = nil, ext: TVBoxParseExt? = nil) {
        self.name = name
        self.type = type
        self.url = url
        self.ext = ext
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.type = container.decodeFlexibleInt(forKey: .type)
        self.url = try container.decodeIfPresent(String.self, forKey: .url)
        self.ext = try container.decodeIfPresent(TVBoxParseExt.self, forKey: .ext)
    }
}

struct TVBoxParseExt: Codable {
    let flag: [String]?
    let header: [String: String]?
}

struct TVBoxRule: Codable, Identifiable {
    var id: String { name ?? UUID().uuidString }
    let name: String?
    let hosts: [String]?
    let regex: [String]?
    let script: [String]?
    let exclude: [String]?
}

struct TVBoxHeaderRule: Codable, Identifiable {
    var id: String { host ?? UUID().uuidString }
    let host: String?
    let header: [String: String]
}

struct TVBoxProxyRule: Codable, Identifiable {
    var id: String { name ?? UUID().uuidString }
    let name: String?
    let hosts: [String]?
    let urls: [String]?
}

struct TVBoxDoH: Codable, Identifiable {
    var id: String { name ?? (url ?? UUID().uuidString) }
    let name: String?
    let url: String?
    let ips: [String]?
}

struct TVBoxDepot: Codable, Identifiable {
    var id: String { url }
    let url: String
    let name: String?
}

enum JSONValue: Codable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let str = try? container.decode(String.self) {
            self = .string(str)
        } else if let num = try? container.decode(Double.self) {
            self = .number(num)
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let dict = try? container.decode([String: JSONValue].self) {
            self = .object(dict)
        } else if let array = try? container.decode([JSONValue].self) {
            self = .array(array)
        } else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Unsupported JSON value"))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let str): try container.encode(str)
        case .number(let num): try container.encode(num)
        case .bool(let bool): try container.encode(bool)
        case .object(let dict): try container.encode(dict)
        case .array(let array): try container.encode(array)
        case .null: try container.encodeNil()
        }
    }

    var displayValue: String {
        switch self {
        case .string(let str):
            return str
        case .number(let num):
            return num.description
        case .bool(let bool):
            return bool ? "true" : "false"
        case .null:
            return "null"
        case .object, .array:
            if let data = try? JSONEncoder().encode(self),
               let string = String(data: data, encoding: .utf8) {
                return string
            }
            return "(object)"
        }
    }
}

private extension KeyedDecodingContainer {
    func decodeFlexibleInt(forKey key: Key) -> Int? {
        if let value = try? decodeIfPresent(Int.self, forKey: key) {
            return value
        }
        if let string = try? decodeIfPresent(String.self, forKey: key) {
            return Int(string)
        }
        return nil
    }
}
