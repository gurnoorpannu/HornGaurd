import Foundation

struct HornDetection: Identifiable, Equatable {
    let id = UUID()
    let timestamp: Date
    let confidence: Float
    let identifier: String
    var direction: HornDirection = .unknown
    var latitude: Double? = nil
    var longitude: Double? = nil
}

struct DetectionResult: Equatable {
    let timestamp: Date
    let identifier: String
    let confidence: Float
    var isHorn: Bool { confidence >= AudioConstants.confidenceThreshold }
}
