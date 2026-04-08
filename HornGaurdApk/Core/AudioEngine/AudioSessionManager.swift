import AVFoundation

final class AudioSessionManager {
    static let shared = AudioSessionManager()
    private init() {}

    func configure() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(
            .playAndRecord,
            mode: .measurement,
            options: [.defaultToSpeaker, .allowBluetoothHFP, .duckOthers, .mixWithOthers]
        )
        try session.setPreferredSampleRate(AudioConstants.sampleRate)
        try session.setPreferredIOBufferDuration(0.05)
        try session.setActive(true, options: [])
        try? enableStereoInputIfPossible(session: session)
    }

    /// iPhones since iOS 14 expose front+back mics as a stereo data source.
    /// This lets us estimate horn direction by comparing L/R levels.
    private func enableStereoInputIfPossible(session: AVAudioSession) throws {
        guard let input = session.availableInputs?.first,
              let dataSources = input.dataSources else { return }
        // Pick a data source that supports stereo polar patterns.
        for source in dataSources {
            if let patterns = source.supportedPolarPatterns,
               patterns.contains(.stereo) {
                try source.setPreferredPolarPattern(.stereo)
                try input.setPreferredDataSource(source)
                try session.setPreferredInputOrientation(.portrait)
                break
            }
        }
    }

    func requestMicPermission() async -> Bool {
        await withCheckedContinuation { cont in
            AVAudioApplication.requestRecordPermission { granted in
                cont.resume(returning: granted)
            }
        }
    }

    func deactivate() {
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }
}
