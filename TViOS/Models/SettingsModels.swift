import Foundation
import CFNetwork

struct ProxyConfig: Codable, Equatable {
    var scheme: String = "http"
    var host: String = ""
    private var portValue: Int = 0
    var username: String = ""
    var password: String = ""

    var port: Int {
        get { portValue }
        set { portValue = max(0, newValue) }
    }

    var portString: String {
        get { portValue == 0 ? "" : String(portValue) }
        set { portValue = Int(newValue) ?? 0 }
    }

    var urlString: String {
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.port = portValue == 0 ? nil : portValue
        if !username.isEmpty { components.user = username }
        if !password.isEmpty { components.password = password }
        return components.string ?? ""
    }

    var connectionDictionary: [AnyHashable: Any] {
        guard !host.isEmpty else { return [:] }
        let proxyType: CFString
        switch scheme.lowercased() {
        case "socks", "socks5": proxyType = kCFProxyTypeSOCKS
        default: proxyType = kCFProxyTypeHTTP
        }
        var dict: [AnyHashable: Any] = [
            kCFProxyTypeKey: proxyType,
            kCFNetworkProxiesHTTPEnable: true,
            kCFNetworkProxiesHTTPProxy: host,
            kCFNetworkProxiesHTTPPort: portValue,
            kCFNetworkProxiesProxyAutoConfigEnable: false,
            kCFNetworkProxiesSOCKSEnable: proxyType == kCFProxyTypeSOCKS
        ]
        if !username.isEmpty { dict[kCFProxyUsernameKey] = username }
        if !password.isEmpty { dict[kCFProxyPasswordKey] = password }
        return dict
    }
}
