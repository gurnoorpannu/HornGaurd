import Foundation

enum AudioConstants {
    static let sampleRate: Double = 16000
    static let frameLength: Int = 3200          // 200 ms @ 16 kHz
    static let hopLength: Int = 1600            // 100 ms
    static let fftSize: Int = 512
    static let melBands: Int = 64
    static let minFrequency: Float = 200
    static let maxFrequency: Float = 1200
    static let spectrogramWidth: Int = 32
    static let spectrogramHeight: Int = 64
    static let confidenceThreshold: Float = 0.85
    static let consecutiveFramesRequired: Int = 3
    static let alertCooldownSeconds: Double = 2.0

    /// Substrings we treat as "horn" inside SoundAnalysis classifier identifiers.
    static let hornIdentifiers: [String] = [
        "car_horn", "vehicle_horn", "truck_horn", "honk", "honking",
        "bicycle_bell", "air_horn"
    ]
}
