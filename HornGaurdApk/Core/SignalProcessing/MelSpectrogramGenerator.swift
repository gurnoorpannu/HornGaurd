import Foundation
import Accelerate

/// Streaming Mel spectrogram. Each `process(samples:)` call:
///   1. Runs STFT on the incoming chunk
///   2. Maps power spectrum into Mel bands (200–1200 Hz, 64 bands)
///   3. Appends the new column(s) to a rolling [melBands × spectrogramWidth] buffer
///   4. Returns a normalized 0…1 snapshot for visualization
final class MelSpectrogramGenerator {
    private let fftSize: Int
    private let hop: Int
    private let melBands: Int
    private let width: Int
    private let sampleRate: Float

    private let log2n: vDSP_Length
    private let fft: vDSP.FFT<DSPSplitComplex>
    private let window: [Float]
    private let melFilter: [[Float]] // [melBands][fftSize/2]

    /// Rolling buffer of log-Mel power columns. Newest = last.
    private var columns: [[Float]] = []
    private var carry: [Float] = []

    init(fftSize: Int = AudioConstants.fftSize,
         hop: Int = AudioConstants.fftSize / 2,
         melBands: Int = AudioConstants.melBands,
         width: Int = AudioConstants.spectrogramWidth,
         sampleRate: Float = Float(AudioConstants.sampleRate),
         minHz: Float = AudioConstants.minFrequency,
         maxHz: Float = AudioConstants.maxFrequency) {
        self.fftSize = fftSize
        self.hop = hop
        self.melBands = melBands
        self.width = width
        self.sampleRate = sampleRate
        self.log2n = vDSP_Length(log2(Float(fftSize)))
        self.fft = vDSP.FFT(log2n: log2n, radix: .radix2, ofType: DSPSplitComplex.self)!

        // Hann window
        var w = [Float](repeating: 0, count: fftSize)
        vDSP_hann_window(&w, vDSP_Length(fftSize), Int32(vDSP_HANN_NORM))
        self.window = w

        self.melFilter = Self.buildMelFilterbank(
            bands: melBands, fftSize: fftSize,
            sampleRate: sampleRate, minHz: minHz, maxHz: maxHz
        )
    }

    /// Append samples and emit a snapshot if any new STFT frames were produced.
    /// Returns a normalized [melBands][width] matrix (oldest → newest column).
    func process(samples: [Float]) -> [[Float]]? {
        carry.append(contentsOf: samples)
        var produced = false

        while carry.count >= fftSize {
            let frame = Array(carry.prefix(fftSize))
            carry.removeFirst(hop)

            let mel = computeMelColumn(frame: frame)
            columns.append(mel)
            if columns.count > width { columns.removeFirst(columns.count - width) }
            produced = true
        }
        return produced ? snapshot() : nil
    }

    func reset() {
        columns.removeAll()
        carry.removeAll()
    }

    /// Returns the current rolling spectrogram normalized to 0…1.
    /// Shape: [melBands][width]; if fewer than `width` columns exist, pads on the left with zeros.
    func snapshot() -> [[Float]] {
        var matrix = [[Float]](repeating: [Float](repeating: 0, count: width), count: melBands)
        let pad = width - columns.count
        for (i, col) in columns.enumerated() {
            let x = pad + i
            for b in 0..<melBands {
                matrix[b][x] = col[b]
            }
        }
        // Min/max normalize across the whole snapshot.
        var minV: Float = .greatestFiniteMagnitude
        var maxV: Float = -.greatestFiniteMagnitude
        for row in matrix {
            for v in row {
                if v < minV { minV = v }
                if v > maxV { maxV = v }
            }
        }
        let span = max(maxV - minV, 1e-6)
        for b in 0..<melBands {
            for x in 0..<width {
                matrix[b][x] = (matrix[b][x] - minV) / span
            }
        }
        return matrix
    }

    // MARK: - STFT → Mel column

    private func computeMelColumn(frame: [Float]) -> [Float] {
        var windowed = [Float](repeating: 0, count: fftSize)
        vDSP_vmul(frame, 1, window, 1, &windowed, 1, vDSP_Length(fftSize))

        let half = fftSize / 2
        var real = [Float](repeating: 0, count: half)
        var imag = [Float](repeating: 0, count: half)
        var power = [Float](repeating: 0, count: half)

        real.withUnsafeMutableBufferPointer { rp in
            imag.withUnsafeMutableBufferPointer { ip in
                var split = DSPSplitComplex(realp: rp.baseAddress!, imagp: ip.baseAddress!)
                windowed.withUnsafeBufferPointer { wp in
                    wp.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: half) { cPtr in
                        vDSP_ctoz(cPtr, 2, &split, 1, vDSP_Length(half))
                    }
                }
                fft.forward(input: split, output: &split)
                vDSP.squareMagnitudes(split, result: &power)
            }
        }

        // Apply mel filterbank.
        var mel = [Float](repeating: 0, count: melBands)
        for b in 0..<melBands {
            var sum: Float = 0
            let filt = melFilter[b]
            vDSP_dotpr(power, 1, filt, 1, &sum, vDSP_Length(half))
            mel[b] = log(sum + 1e-9)
        }
        return mel
    }

    // MARK: - Mel filterbank construction

    private static func hzToMel(_ hz: Float) -> Float { 2595 * log10(1 + hz / 700) }
    private static func melToHz(_ mel: Float) -> Float { 700 * (pow(10, mel / 2595) - 1) }

    private static func buildMelFilterbank(bands: Int, fftSize: Int,
                                           sampleRate: Float, minHz: Float, maxHz: Float) -> [[Float]] {
        let half = fftSize / 2
        let minMel = hzToMel(minHz)
        let maxMel = hzToMel(maxHz)
        // bands+2 points: bands triangles need (band-1, center, band+1)
        let melPoints = (0..<(bands + 2)).map { i -> Float in
            minMel + (maxMel - minMel) * Float(i) / Float(bands + 1)
        }
        let hzPoints = melPoints.map { melToHz($0) }
        let binPoints = hzPoints.map { hz -> Float in
            hz * Float(fftSize) / sampleRate
        }

        var filters = [[Float]](repeating: [Float](repeating: 0, count: half), count: bands)
        for b in 0..<bands {
            let left = binPoints[b]
            let center = binPoints[b + 1]
            let right = binPoints[b + 2]
            for k in 0..<half {
                let kf = Float(k)
                if kf >= left && kf <= center {
                    filters[b][k] = (kf - left) / max(center - left, 1e-6)
                } else if kf > center && kf <= right {
                    filters[b][k] = (right - kf) / max(right - center, 1e-6)
                }
            }
        }
        return filters
    }
}
