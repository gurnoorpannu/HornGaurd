import AVFoundation

extension AVAudioPCMBuffer {
    /// Returns a Float32 mono representation of the buffer (averages stereo channels).
    func monoSamples() -> [Float] {
        guard let channelData = floatChannelData else { return [] }
        let frames = Int(frameLength)
        let channels = Int(format.channelCount)
        if channels == 1 {
            return Array(UnsafeBufferPointer(start: channelData[0], count: frames))
        }
        var out = [Float](repeating: 0, count: frames)
        for c in 0..<channels {
            let ptr = UnsafeBufferPointer(start: channelData[c], count: frames)
            for i in 0..<frames { out[i] += ptr[i] }
        }
        let inv = 1.0 / Float(channels)
        for i in 0..<frames { out[i] *= inv }
        return out
    }

    /// RMS amplitude in 0…1 (linear).
    func rmsLevel() -> Float {
        let samples = monoSamples()
        if samples.isEmpty { return 0 }
        var sum: Float = 0
        for s in samples { sum += s * s }
        return sqrt(sum / Float(samples.count))
    }
}
