import Foundation
import CoreHaptics
import UIKit

final class HapticAlertManager {
    private var engine: CHHapticEngine?
    private let supportsHaptics: Bool

    init() {
        supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics
        prepare()
    }

    private func prepare() {
        guard supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            engine?.stoppedHandler = { _ in }
            engine?.resetHandler = { [weak self] in
                try? self?.engine?.start()
            }
            try engine?.start()
        } catch {
            print("[Haptics] engine error: \(error)")
        }
    }

    func fireHornAlert() {
        guard supportsHaptics, let engine else {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            return
        }
        do {
            let tap1 = CHHapticEvent(eventType: .hapticTransient, parameters: [
                .init(parameterID: .hapticIntensity, value: 1.0),
                .init(parameterID: .hapticSharpness, value: 1.0)
            ], relativeTime: 0)
            let tap2 = CHHapticEvent(eventType: .hapticTransient, parameters: [
                .init(parameterID: .hapticIntensity, value: 1.0),
                .init(parameterID: .hapticSharpness, value: 1.0)
            ], relativeTime: 0.12)
            let buzz = CHHapticEvent(eventType: .hapticContinuous, parameters: [
                .init(parameterID: .hapticIntensity, value: 0.9),
                .init(parameterID: .hapticSharpness, value: 0.6)
            ], relativeTime: 0.25, duration: 0.5)
            let pattern = try CHHapticPattern(events: [tap1, tap2, buzz], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        }
    }
}
