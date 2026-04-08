import AVFoundation
import Combine

/// Captures microphone audio via AVAudioEngine and republishes PCM buffers
/// on a background queue for downstream feature extraction / classification.
final class AudioCaptureManager {
    private let engine = AVAudioEngine()
    private let processingQueue = DispatchQueue(label: "com.hornguard.audio", qos: .userInteractive)

    /// Published buffers (background thread). Subscribers must be thread-safe.
    let bufferSubject = PassthroughSubject<(AVAudioPCMBuffer, AVAudioTime), Never>()

    private(set) var isRunning = false

    func start() throws {
        guard !isRunning else { return }

        let input = engine.inputNode
        let hwFormat = input.inputFormat(forBus: 0)
        // Tap in the hardware format — SoundAnalysis can consume any standard format.
        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 4096, format: hwFormat) { [weak self] buffer, time in
            guard let self else { return }
            self.processingQueue.async {
                self.bufferSubject.send((buffer, time))
            }
        }

        engine.prepare()
        try engine.start()
        isRunning = true
    }

    func stop() {
        guard isRunning else { return }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        isRunning = false
    }

    var inputFormat: AVAudioFormat {
        engine.inputNode.inputFormat(forBus: 0)
    }
}
