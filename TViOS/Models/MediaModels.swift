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
    let ext: [String: JSONValue]?
    let jar: String?
    let click: String?

    var id: String { key }

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
        return ext
            .map { ($0.key, $0.value.displayValue) }
            .sorted { $0.0 < $1.0 }
    }
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
