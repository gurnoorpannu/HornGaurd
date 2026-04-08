import Foundation
import UIKit

/// Decides which alert modalities (haptic / visual / audio-duck) fire on
/// a confirmed horn detection, based on the user's settings.
final class AlertCoordinator {
    private let haptics = HapticAlertManager()
    private let ducking = MusicDuckingManager()
    private let settings: SettingsStore

    init(settings: SettingsStore = .shared) {
        self.settings = settings
    }

    /// Called from main thread on a confirmed detection.
    func fire(for detection: HornDetection) {
        if settings.hapticEnabled {
            haptics.fireHornAlert()
        }
        if settings.audioDuckEnabled {
            ducking.duck(for: 2.0)
        }
        // Visual alert is driven by the UI observing `lastConfirmed`.
        // Accessibility announcement
        UIAccessibility.post(notification: .announcement, argument: "Horn detected nearby")
    }
}
