import Foundation
import Combine

/// Global, persisted user preferences. Single source of truth shared by
/// DetectionEngine, AlertCoordinator, and the Settings UI.
final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()

    @Published var sensitivity: SensitivityLevel {
        didSet { defaults.set(sensitivity.rawValue, forKey: Keys.sensitivity) }
    }
    @Published var hapticEnabled: Bool {
        didSet { defaults.set(hapticEnabled, forKey: Keys.haptic) }
    }
    @Published var visualEnabled: Bool {
        didSet { defaults.set(visualEnabled, forKey: Keys.visual) }
    }
    @Published var audioDuckEnabled: Bool {
        didSet { defaults.set(audioDuckEnabled, forKey: Keys.duck) }
    }
    @Published var cooldownSeconds: Double {
        didSet { defaults.set(cooldownSeconds, forKey: Keys.cooldown) }
    }

    var threshold: Float { sensitivity.threshold }

    private let defaults = UserDefaults.standard
    private enum Keys {
        static let sensitivity = "settings.sensitivity"
        static let haptic = "settings.haptic"
        static let visual = "settings.visual"
        static let duck = "settings.duck"
        static let cooldown = "settings.cooldown"
    }

    private init() {
        sensitivity = SensitivityLevel(rawValue: defaults.string(forKey: Keys.sensitivity) ?? "")
            ?? .medium
        hapticEnabled = defaults.object(forKey: Keys.haptic) as? Bool ?? true
        visualEnabled = defaults.object(forKey: Keys.visual) as? Bool ?? true
        audioDuckEnabled = defaults.object(forKey: Keys.duck) as? Bool ?? true
        cooldownSeconds = defaults.object(forKey: Keys.cooldown) as? Double
            ?? AudioConstants.alertCooldownSeconds
    }
}
