import Foundation

enum HornDirection: String {
    case left, center, right, unknown

    var arrowSymbol: String {
        switch self {
        case .left: return "arrow.left"
        case .right: return "arrow.right"
        case .center: return "arrow.up"
        case .unknown: return "questionmark"
        }
    }

    var label: String {
        switch self {
        case .left: return "LEFT"
        case .right: return "RIGHT"
        case .center: return "AHEAD"
        case .unknown: return "—"
        }
    }
}
