import Foundation

@MainActor
final class SettingsStore: ObservableObject {
    private enum Keys {
        static let catalog = "settings.catalog"
        static let style = "settings.style"
        static let proxy = "settings.proxy"
        static let requestMode = "settings.requestMode"
    }

    @Published var catalogEndpoint: String
    @Published var style: MediaStyle
    @Published var proxy: ProxyConfig?
    @Published var requestMode: RequestMode

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.catalogEndpoint = defaults.string(forKey: Keys.catalog) ?? "http://tv.nxog.top/m/t"
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
        if let stored = defaults.string(forKey: Keys.requestMode),
           let mode = RequestMode(rawValue: stored) {
            self.requestMode = mode
        } else {
            self.requestMode = .apple
        }
    }

    var catalogURL: URL? { URL(string: catalogEndpoint) }
    func persist() {
        defaults.set(catalogEndpoint, forKey: Keys.catalog)
        if let data = try? JSONEncoder().encode(style) {
            defaults.set(data, forKey: Keys.style)
        }
        if let proxy, let data = try? JSONEncoder().encode(proxy) {
            defaults.set(data, forKey: Keys.proxy)
        } else {
            defaults.removeObject(forKey: Keys.proxy)
        }
        defaults.set(requestMode.rawValue, forKey: Keys.requestMode)
    }

    func reset() {
        catalogEndpoint = "http://tv.nxog.top/m/t"
        style = MediaStyle()
        proxy = nil
        requestMode = .apple
        persist()
    }

    func updateProxy(_ update: (inout ProxyConfig) -> Void) {
        var value = proxy ?? ProxyConfig()
        update(&value)
        proxy = value
    }
}
