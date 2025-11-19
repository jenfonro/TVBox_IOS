import Foundation
import CFNetwork

enum RequestMode: String, CaseIterable, Codable, Identifiable {
    case apple
    case android

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .apple: return "蘋果"
        case .android: return "安卓"
        }
    }

    var defaultHeaders: [String: String] {
        switch self {
        case .apple:
            return [
                "User-Agent": "TViOS/1.0",
                "Accept": "*/*"
            ]
        case .android:
            return [
                "User-Agent": "okhttp/3.12.13",
                "Accept": "*/*",
                "Accept-Encoding": "gzip",
                "Connection": "Keep-Alive"
            ]
        }
    }
}

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
            kCFProxyTypeKey: proxyType
        ]
        if proxyType == kCFProxyTypeSOCKS {
            dict[kCFProxyHostNameKey] = host
            if portValue > 0 {
                dict[kCFProxyPortNumberKey] = portValue
            }
        } else {
            dict[kCFNetworkProxiesHTTPEnable] = true
            dict[kCFNetworkProxiesHTTPProxy] = host
            if portValue > 0 {
                dict[kCFNetworkProxiesHTTPPort] = portValue
            }
            dict[kCFNetworkProxiesProxyAutoConfigEnable] = false
        }
        if !username.isEmpty { dict[kCFProxyUsernameKey] = username }
        if !password.isEmpty { dict[kCFProxyPasswordKey] = password }
        return dict
    }
}
