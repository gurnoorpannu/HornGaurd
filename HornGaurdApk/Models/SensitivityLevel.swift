import Foundation

enum SensitivityLevel: String, CaseIterable, Identifiable, Codable {
    case low, medium, high
    var id: String { rawValue }

    var threshold: Float {
        switch self {
        case .low: return 0.90
        case .medium: return 0.85
        case .high: return 0.75
        }
    }

    var label: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }
}
