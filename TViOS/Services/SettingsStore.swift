import Foundation

@MainActor
final class SettingsStore: ObservableObject {
    private enum Keys {
        static let server = "settings.server"
        static let catalog = "settings.catalog"
        static let live = "settings.live"
        static let style = "settings.style"
        static let proxy = "settings.proxy"
    }

    @Published var serverAddress: String
    @Published var catalogEndpoint: String
    @Published var liveEndpoint: String
    @Published var style: MediaStyle
    @Published var proxy: ProxyConfig?

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.serverAddress = defaults.string(forKey: Keys.server) ?? "http://127.0.0.1:9978"
        self.catalogEndpoint = defaults.string(forKey: Keys.catalog) ?? ""
        self.liveEndpoint = defaults.string(forKey: Keys.live) ?? ""
        if let data = defaults.data(forKey: Keys.style),
           let decoded = try? JSONDecoder().decode(MediaStyle.self, from: data) {
            self.style = decoded
        } else {
            self.style = MediaStyle()
        }
        if let data = defaults.data(forKey: Keys.proxy),
           let decoded = try? JSONDecoder().decode(ProxyConfig.self, from: data) {
            self.proxy = decoded
        }
    }

    var baseURL: URL? {
        guard !serverAddress.isEmpty else { return nil }
        if serverAddress.hasPrefix("http://") || serverAddress.hasPrefix("https://") {
            return URL(string: serverAddress)
        }
        return URL(string: "http://\(serverAddress)")
    }

    var catalogURL: URL? { URL(string: catalogEndpoint) }
    var liveURL: URL? { URL(string: liveEndpoint) }

    func persist() {
        defaults.set(serverAddress, forKey: Keys.server)
        defaults.set(catalogEndpoint, forKey: Keys.catalog)
        defaults.set(liveEndpoint, forKey: Keys.live)
        if let data = try? JSONEncoder().encode(style) {
            defaults.set(data, forKey: Keys.style)
        }
        if let proxy, let data = try? JSONEncoder().encode(proxy) {
            defaults.set(data, forKey: Keys.proxy)
        } else {
            defaults.removeObject(forKey: Keys.proxy)
        }
    }

    func reset() {
        serverAddress = "http://127.0.0.1:9978"
        catalogEndpoint = ""
        liveEndpoint = ""
        style = MediaStyle()
        proxy = nil
        persist()
    }

    func updateProxy(_ update: (inout ProxyConfig) -> Void) {
        var value = proxy ?? ProxyConfig()
        update(&value)
        proxy = value
    }
}
