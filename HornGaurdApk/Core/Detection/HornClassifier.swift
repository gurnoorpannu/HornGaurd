import Foundation
import AVFoundation
import SoundAnalysis
import Combine

/// Wraps Apple's built-in SoundAnalysis classifier and emits DetectionResults.
final class HornClassifier: NSObject {
    let resultSubject = PassthroughSubject<DetectionResult, Never>()

    private var analyzer: SNAudioStreamAnalyzer?
    private let analysisQueue = DispatchQueue(label: "com.hornguard.classifier", qos: .userInteractive)
    private var observer: ResultsObserver?

    func prepare(format: AVAudioFormat) throws {
        let analyzer = SNAudioStreamAnalyzer(format: format)
        let request = try SNClassifySoundRequest(classifierIdentifier: .version1)
        request.windowDuration = CMTime(seconds: 0.5, preferredTimescale: 1000)
        request.overlapFactor = 0.5

        let observer = ResultsObserver { [weak self] result in
            self?.resultSubject.send(result)
        }
        try analyzer.add(request, withObserver: observer)
        self.analyzer = analyzer
        self.observer = observer
    }

    func analyze(buffer: AVAudioPCMBuffer, at time: AVAudioTime) {
        analysisQueue.async { [weak self] in
            self?.analyzer?.analyze(buffer, atAudioFramePosition: time.sampleTime)
        }
    }

    func reset() {
        analyzer?.removeAllRequests()
        analyzer = nil
        observer = nil
    }
}

private final class ResultsObserver: NSObject, SNResultsObserving {
    private let onResult: (DetectionResult) -> Void
    init(onResult: @escaping (DetectionResult) -> Void) { self.onResult = onResult }

    func request(_ request: SNRequest, didProduce result: SNResult) {
        guard let cls = result as? SNClassificationResult else { return }
        // Find the best horn-like classification in this window.
        let best = cls.classifications
            .filter { c in
                let id = c.identifier.lowercased()
                return AudioConstants.hornIdentifiers.contains { id.contains($0) }
            }
            .max(by: { $0.confidence < $1.confidence })

        if let best {
            onResult(DetectionResult(
                timestamp: Date(),
                identifier: best.identifier,
                confidence: Float(best.confidence)
            ))
        } else if let top = cls.classifications.first {
            // Emit a non-horn result so the validator can reset its streak.
            onResult(DetectionResult(
                timestamp: Date(),
                identifier: top.identifier,
                confidence: 0
            ))
        }
    }

    func request(_ request: SNRequest, didFailWithError error: Error) {
        print("[HornClassifier] failed: \(error)")
    }

    func requestDidComplete(_ request: SNRequest) {}
}
