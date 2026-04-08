import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = SettingsStore.shared

    var body: some View {
        NavigationStack {
            Form {
                Section("Sensitivity") {
                    Picker("Level", selection: $settings.sensitivity) {
                        ForEach(SensitivityLevel.allCases) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    Text("Confidence threshold: \(Int(settings.threshold * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Alerts") {
                    Toggle("Haptic feedback", isOn: $settings.hapticEnabled)
                    Toggle("Visual flash", isOn: $settings.visualEnabled)
                    Toggle("Duck music volume", isOn: $settings.audioDuckEnabled)
                }

                Section("Cooldown") {
                    VStack(alignment: .leading) {
                        Slider(value: $settings.cooldownSeconds, in: 1...5, step: 0.5)
                        Text("\(settings.cooldownSeconds, specifier: "%.1f")s between alerts")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("About") {
                    NavigationLink("How It Works") { HowItWorksView() }
                    Text("HornGuard listens for vehicle horns using on-device sound classification, signal-processing filters, and temporal validation to alert riders without any external hardware.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview { SettingsView() }
