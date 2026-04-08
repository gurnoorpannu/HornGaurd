import AVFoundation

/// Briefly lowers other apps' audio (music) by toggling AVAudioSession's
/// `.duckOthers` option around a horn alert.
final class MusicDuckingManager {
    private var isDucking = false

    func duck(for seconds: TimeInterval) {
        guard !isDucking else { return }
        isDucking = true
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(
                .playAndRecord,
                mode: .measurement,
                options: [.defaultToSpeaker, .allowBluetoothHFP, .duckOthers, .mixWithOthers]
            )
            try session.setActive(true, options: [])
        } catch {
            print("[Ducking] failed: \(error)")
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { [weak self] in
            self?.isDucking = false
            // Re-set without duckOthers to release ducking.
            do {
                try session.setCategory(
                    .playAndRecord,
                    mode: .measurement,
                    options: [.defaultToSpeaker, .allowBluetoothHFP, .mixWithOthers]
                )
                try session.setActive(true, options: [])
            } catch {
                print("[Ducking] release failed: \(error)")
            }
        }
    }
}
