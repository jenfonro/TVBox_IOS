import Foundation
import CommonCrypto

enum ConfigResolverError: Error, LocalizedError {
    case invalidURL
    case unsupportedScheme(String)
    case missingResource(String)
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "設定網址無效"
        case .unsupportedScheme(let scheme):
            return "不支援的協議：\(scheme)"
        case .missingResource(let name):
            return "找不到資源：\(name)"
        case .decodingFailed:
            return "設定內容解析失敗"
        }
    }
}

struct ConfigResolver {
    let client: APIClient

    func loadConfig(from rawString: String) async throws -> Data {
        let trimmed = rawString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed) else { throw ConfigResolverError.invalidURL }
        let data: Data
        switch url.scheme?.lowercased() {
        case "http", "https":
            data = try await client.data(from: url)
        case "assets":
            data = try loadAsset(from: url)
        case "file":
            data = try Data(contentsOf: url)
        case nil:
            throw ConfigResolverError.invalidURL
        default:
            throw ConfigResolverError.unsupportedScheme(url.scheme ?? "")
        }
        return try ConfigDecoder.decode(data: data, sourceURL: url)
    }

    private func loadAsset(from url: URL) throws -> Data {
        let resourcePath = url.absoluteString.replacingOccurrences(of: "assets://", with: "")
        let segments = resourcePath.split(separator: "/", omittingEmptySubsequences: false)
        guard let last = segments.last else { throw ConfigResolverError.missingResource(resourcePath) }
        let nameParts = last.split(separator: ".")
        let name = nameParts.first.map(String.init) ?? String(last)
        let ext = nameParts.dropFirst().joined(separator: ".")
        let folder = segments.dropLast().joined(separator: "/")
        let bundleURL: URL?
        if folder.isEmpty {
            bundleURL = Bundle.main.url(forResource: name, withExtension: ext)
        } else {
            bundleURL = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: folder)
        }
        guard let finalURL = bundleURL else { throw ConfigResolverError.missingResource(resourcePath) }
        return try Data(contentsOf: finalURL)
    }
}

private enum ConfigDecoder {
    private static let jsPattern = try! NSRegularExpression(pattern: "\"(\\.|\\.\\.)/(.?|.+?)\\.js\\?(.?|.+?)\"", options: [])

    static func decode(data: Data, sourceURL: URL) throws -> Data {
        guard var text = String(data: data, encoding: .utf8) else {
            throw ConfigResolverError.decodingFailed
        }
        if text.contains("**") { text = base64Decode(text) }
        if text.hasPrefix("2423") {
            text = try decryptCBC(text)
        }
        text = cleanJSON(text)
        text = fixPaths(text, baseURL: sourceURL)
        guard let fixedData = text.data(using: .utf8) else {
            throw ConfigResolverError.decodingFailed
        }
        return fixedData
    }

    private static func base64Decode(_ text: String) -> String {
        guard let extract = extractBase64(text) else { return text }
        guard let decoded = Data(base64Encoded: extract) else { return text }
        return String(data: decoded, encoding: .utf8) ?? text
    }

    private static func extractBase64(_ text: String) -> String? {
        let pattern = try! NSRegularExpression(pattern: "[A-Za-z0-9]{8}\\*\\*", options: [])
        guard let match = pattern.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else { return nil }
        let start = text.index(text.startIndex, offsetBy: match.range.location + match.range.length)
        return String(text[start...])
    }

    private static func decryptCBC(_ hexString: String) throws -> String {
        guard let decodedData = Data(hexString: hexString), let decodedString = String(data: decodedData, encoding: .utf8)?.lowercased() else {
            throw ConfigResolverError.decodingFailed
        }
        guard let keyStart = decodedString.range(of: "$#"), let keyEnd = decodedString.range(of: "#$", range: keyStart.upperBound..<decodedString.endIndex) else {
            throw ConfigResolverError.decodingFailed
        }
        let rawKey = String(decodedString[keyStart.upperBound..<keyEnd.lowerBound])
        let key = padEnd(rawKey)
        let rawIv = String(decodedString.suffix(13))
        let iv = padEnd(rawIv)
        guard let cipherRange = hexString.range(of: "2324") else { throw ConfigResolverError.decodingFailed }
        let cipherStart = cipherRange.upperBound
        let cipherEnd = hexString.index(hexString.endIndex, offsetBy: -26)
        guard cipherStart < cipherEnd else { throw ConfigResolverError.decodingFailed }
        let cipherHex = String(hexString[cipherStart..<cipherEnd])
        guard let cipherData = Data(hexString: cipherHex) else { throw ConfigResolverError.decodingFailed }
        guard let decrypted = aesCBC(data: cipherData, key: key, iv: iv) else {
            throw ConfigResolverError.decodingFailed
        }
        return decrypted
    }

    private static func aesCBC(data: Data, key: String, iv: String) -> String? {
        guard let keyData = key.data(using: .utf8), let ivData = iv.data(using: .utf8) else { return nil }
        var outLength: size_t = 0
        var outBytes = [UInt8](repeating: 0, count: data.count + kCCBlockSizeAES128)
        let status = data.withUnsafeBytes { dataPtr in
            keyData.withUnsafeBytes { keyPtr in
                ivData.withUnsafeBytes { ivPtr in
                    CCCrypt(CCOperation(kCCDecrypt), CCAlgorithm(kCCAlgorithmAES), CCOptions(kCCOptionPKCS7Padding), keyPtr.baseAddress, kCCKeySizeAES128, ivPtr.baseAddress, dataPtr.baseAddress, data.count, &outBytes, outBytes.count, &outLength)
                }
            }
        }
        guard status == kCCSuccess else { return nil }
        return String(bytes: outBytes.prefix(outLength), encoding: .utf8)
    }

    private static func padEnd(_ value: String) -> String {
        let padding = String(repeating: "0", count: max(0, 16 - value.count))
        return (value + padding).prefix(16).uppercased()
    }

    private static func cleanJSON(_ text: String) -> String {
        var cleaned = text.replacingOccurrences(of: "\u{FEFF}", with: "")
        if let regex = try? NSRegularExpression(pattern: "/\\*.*?\\*/", options: [.dotMatchesLineSeparators]) {
            cleaned = regex.stringByReplacingMatches(in: cleaned, range: NSRange(cleaned.startIndex..., in: cleaned), withTemplate: "")
        }
        let lines = cleaned.split(whereSeparator: { $0.isNewline })
        let filtered = lines.compactMap { line -> String? in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("//") || trimmed.hasPrefix("#") || trimmed.isEmpty {
                return nil
            }
            return String(line)
        }
        return filtered.joined(separator: "\n")
    }

    private static func fixPaths(_ text: String, baseURL: URL) -> String {
        var result = text
        let fullRange = NSRange(result.startIndex..., in: result)
        let matches = jsPattern.matches(in: result, range: fullRange).reversed()
        for match in matches {
            guard let range = Range(match.range, in: result) else { continue }
            let ext = String(result[range])
            let replaced = ext
                .replacingOccurrences(of: "\"./", with: "\"\(resolve(base: baseURL, reference: "./"))")
                .replacingOccurrences(of: "\"../", with: "\"\(resolve(base: baseURL, reference: "../"))")
                .replacingOccurrences(of: "./", with: "__JS1__")
                .replacingOccurrences(of: "../", with: "__JS2__")
            result.replaceSubrange(range, with: replaced)
        }
        if result.contains("../") {
            result = result.replacingOccurrences(of: "../", with: resolve(base: baseURL, reference: "../"))
        }
        if result.contains("./") {
            result = result.replacingOccurrences(of: "./", with: resolve(base: baseURL, reference: "./"))
        }
        result = result.replacingOccurrences(of: "__JS1__", with: "./")
        result = result.replacingOccurrences(of: "__JS2__", with: "../")
        return result
    }

    private static func resolve(base: URL, reference: String) -> String {
        guard let resolved = URL(string: reference, relativeTo: base)?.absoluteURL else { return reference }
        return resolved.absoluteString
    }
}

private extension Data {
    init?(hexString: String) {
        let len = hexString.count
        guard len % 2 == 0 else { return nil }
        var data = Data(capacity: len / 2)
        var index = hexString.startIndex
        while index < hexString.endIndex {
            let nextIndex = hexString.index(index, offsetBy: 2)
            let byteString = hexString[index..<nextIndex]
            guard let num = UInt8(byteString, radix: 16) else { return nil }
            data.append(num)
            index = nextIndex
        }
        self = data
    }
}
