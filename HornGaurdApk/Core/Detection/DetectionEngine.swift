import Foundation
import AVFoundation
import CoreLocation
import Combine

/// Wires AudioCapture → (BandpassFilter + MelSpectrogram) + HornClassifier → TemporalValidator
/// and exposes observable state to the UI layer.
@MainActor
final class DetectionEngine: ObservableObject {
    @Published var isListening: Bool = false
    @Published var lastResult: DetectionResult?
    @Published var lastConfirmed: HornDetection?
    @Published var detectionsToday: Int = 0
    @Published var history: [HornDetection] = []
    @Published var errorMessage: String?

    // Phase 2 visualization state
    @Published var spectrogram: [[Float]] = []     // [melBands][width], 0…1
    @Published var audioLevel: Float = 0           // 0…1 RMS
    @Published var confidenceHistory: [Float] = [] // rolling, newest last
    @Published var currentDirection: HornDirection = .unknown

    let location = LocationTracker()

    private let capture = AudioCaptureManager()
    private let classifier = HornClassifier()
    private var validator = TemporalValidator()
    private let alerts = AlertCoordinator()
    private let settings = SettingsStore.shared

    private var bandpass: BandpassFilter?
    private var melGen: MelSpectrogramGenerator?
    private let direction = StereoDirectionEstimator()
    private let confidenceHistoryLimit = 120

    private var cancellables = Set<AnyCancellable>()

    init() { bind() }

    private func bind() {
        capture.bufferSubject
            .sink { [weak self] buffer, time in
                guard let self else { return }
                // 1. Forward raw buffer to SoundAnalysis classifier.
                self.classifier.analyze(buffer: buffer, at: time)
                // 2. Run signal processing for visualization + direction.
                self.processForVisualization(buffer: buffer)
                self.direction.ingest(buffer: buffer)
            }
            .store(in: &cancellables)

        classifier.resultSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                guard let self else { return }
                self.lastResult = result
                self.appendConfidence(result.confidence)
                self.validator.ingest(result)
            }
            .store(in: &cancellables)

        validator.confirmedSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] detection in
                guard let self else { return }
                var enriched = detection
                let dir = self.direction.currentDirection()
                enriched.direction = dir
                if let loc = self.location.currentLocation {
                    enriched.latitude = loc.coordinate.latitude
                    enriched.longitude = loc.coordinate.longitude
                }
                self.currentDirection = dir
                self.lastConfirmed = enriched
                self.detectionsToday += 1
                self.history.insert(enriched, at: 0)
                self.alerts.fire(for: enriched)
            }
            .store(in: &cancellables)
    }

    // MARK: - Lifecycle

    func start() async {
        let granted = await AudioSessionManager.shared.requestMicPermission()
        guard granted else {
            errorMessage = "Microphone permission denied. Enable it in Settings."
            return
        }
        do {
            try AudioSessionManager.shared.configure()
            try classifier.prepare(format: capture.inputFormat)
            validator.threshold = settings.threshold
            validator.cooldown = settings.cooldownSeconds

            let sr = Float(capture.inputFormat.sampleRate)
            bandpass = BandpassFilter(size: 4096, sampleRate: sr)
            melGen = MelSpectrogramGenerator(sampleRate: sr)

            try capture.start()
            location.start()
            isListening = true
            errorMessage = nil
        } catch {
            errorMessage = "Failed to start: \(error.localizedDescription)"
            isListening = false
        }
    }

    func stop() {
        capture.stop()
        location.stop()
        direction.reset()
        classifier.reset()
        validator.reset()
        bandpass = nil
        melGen?.reset()
        melGen = nil
        AudioSessionManager.shared.deactivate()
        isListening = false
    }

    // MARK: - Visualization pipeline

    private func processForVisualization(buffer: AVAudioPCMBuffer) {
        let mono = buffer.monoSamples()
        let level = buffer.rmsLevel()

        let filtered = bandpass?.apply(mono) ?? mono
        let snapshot = melGen?.process(samples: filtered)

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.audioLevel = min(1, level * 4) // small gain so meter is visible
            if let snap = snapshot {
                self.spectrogram = snap
            }
        }
    }

    private func appendConfidence(_ c: Float) {
        confidenceHistory.append(c)
        if confidenceHistory.count > confidenceHistoryLimit {
            confidenceHistory.removeFirst(confidenceHistory.count - confidenceHistoryLimit)
        }
    }
}
