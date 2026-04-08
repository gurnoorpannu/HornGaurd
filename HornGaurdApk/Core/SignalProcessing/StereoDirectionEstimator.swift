import AVFoundation

/// Estimates horn direction by comparing left/right channel RMS levels in
/// the band-limited signal. Maintains a small smoothing window so brief
/// asymmetries don't flip the result.
final class StereoDirectionEstimator {
    private var leftHistory: [Float] = []
    private var rightHistory: [Float] = []
    private let window = 5
    private let centerThreshold: Float = 0.12 // |Δ|/sum below this = center

    func ingest(buffer: AVAudioPCMBuffer) {
        guard let data = buffer.floatChannelData,
              buffer.format.channelCount >= 2 else {
            return
        }
        let frames = Int(buffer.frameLength)
        let l = UnsafeBufferPointer(start: data[0], count: frames)
        let r = UnsafeBufferPointer(start: data[1], count: frames)
        var lSum: Float = 0, rSum: Float = 0
        for i in 0..<frames {
            lSum += l[i] * l[i]
            rSum += r[i] * r[i]
        }
        let lRMS = sqrt(lSum / Float(max(frames, 1)))
        let rRMS = sqrt(rSum / Float(max(frames, 1)))
        leftHistory.append(lRMS)
        rightHistory.append(rRMS)
        if leftHistory.count > window {
            leftHistory.removeFirst(leftHistory.count - window)
            rightHistory.removeFirst(rightHistory.count - window)
        }
    }

    func currentDirection() -> HornDirection {
        guard !leftHistory.isEmpty else { return .unknown }
        let l = leftHistory.reduce(0, +) / Float(leftHistory.count)
        let r = rightHistory.reduce(0, +) / Float(rightHistory.count)
        let sum = l + r
        guard sum > 1e-5 else { return .unknown }
        let delta = (r - l) / sum
        if abs(delta) < centerThreshold { return .center }
        return delta > 0 ? .right : .left
    }

    func reset() {
        leftHistory.removeAll()
        rightHistory.removeAll()
    }
}
