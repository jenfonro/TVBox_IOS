import Foundation

struct MediaStyle: Codable, Equatable {
    enum StyleType: String, CaseIterable, Codable, Identifiable {
        case rect
        case oval
        case list

        var id: String { rawValue }
    }

    var type: StyleType
    var ratio: Double

    init(type: StyleType = .rect, ratio: Double = 0.75) {
        self.type = type
        self.ratio = ratio
    }

    var description: String {
        switch type {
        case .rect:
            if ratio == 1 { return "正方" }
            return ratio > 1 ? "橫式" : "直式"
        case .oval:
            return "圓形"
        case .list:
            return "列表"
        }
    }
}
