import Foundation
import Combine

/// Confirms a horn detection only after N consecutive frames exceed threshold,
/// and enforces a cooldown to avoid alert spam.
final class TemporalValidator {
    let confirmedSubject = PassthroughSubject<HornDetection, Never>()

    private var streak: Int = 0
    private var lastAlert: Date = .distantPast
    private let required: Int
    var cooldown: TimeInterval
    var threshold: Float

    init(required: Int = AudioConstants.consecutiveFramesRequired,
         cooldown: TimeInterval = AudioConstants.alertCooldownSeconds,
         threshold: Float = AudioConstants.confidenceThreshold) {
        self.required = required
        self.cooldown = cooldown
        self.threshold = threshold
    }

    func ingest(_ result: DetectionResult) {
        if result.confidence >= threshold {
            streak += 1
            if streak >= required {
                let now = Date()
                if now.timeIntervalSince(lastAlert) >= cooldown {
                    lastAlert = now
                    confirmedSubject.send(HornDetection(
                        timestamp: now,
                        confidence: result.confidence,
                        identifier: result.identifier
                    ))
                }
            }
        } else {
            streak = 0
        }
    }

    func reset() {
        streak = 0
        lastAlert = .distantPast
    }
}
