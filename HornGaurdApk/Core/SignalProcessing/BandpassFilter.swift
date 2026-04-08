import Foundation
import Accelerate

/// FFT-based bandpass filter (200 Hz – 1200 Hz by default).
/// Zeros frequency bins outside the band, then inverse-FFTs.
final class BandpassFilter {
    private let log2n: vDSP_Length
    private let n: Int
    private let fft: vDSP.FFT<DSPSplitComplex>
    private let sampleRate: Float
    private let lowHz: Float
    private let highHz: Float

    init(size: Int = 4096,
         sampleRate: Float = Float(AudioConstants.sampleRate),
         lowHz: Float = AudioConstants.minFrequency,
         highHz: Float = AudioConstants.maxFrequency) {
        // Round size up to next power of two.
        var pow2 = 1
        while pow2 < size { pow2 <<= 1 }
        self.n = pow2
        self.log2n = vDSP_Length(log2(Float(pow2)))
        self.fft = vDSP.FFT(log2n: log2n, radix: .radix2, ofType: DSPSplitComplex.self)!
        self.sampleRate = sampleRate
        self.lowHz = lowHz
        self.highHz = highHz
    }

    /// Returns a band-limited copy of `samples` (length matches input, padded with zeros internally).
    func apply(_ samples: [Float]) -> [Float] {
        var input = samples
        if input.count < n { input.append(contentsOf: [Float](repeating: 0, count: n - input.count)) }
        else if input.count > n { input = Array(input.prefix(n)) }

        var real = [Float](repeating: 0, count: n / 2)
        var imag = [Float](repeating: 0, count: n / 2)
        var output = [Float](repeating: 0, count: n)

        real.withUnsafeMutableBufferPointer { realPtr in
            imag.withUnsafeMutableBufferPointer { imagPtr in
                var split = DSPSplitComplex(realp: realPtr.baseAddress!, imagp: imagPtr.baseAddress!)

                input.withUnsafeBufferPointer { inPtr in
                    inPtr.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: n / 2) { cPtr in
                        vDSP_ctoz(cPtr, 2, &split, 1, vDSP_Length(n / 2))
                    }
                }

                fft.forward(input: split, output: &split)

                // Zero bins outside [lowHz, highHz].
                let binHz = sampleRate / Float(n)
                let lowBin = max(1, Int(lowHz / binHz))
                let highBin = min(n / 2 - 1, Int(highHz / binHz))
                for i in 0..<(n / 2) {
                    if i < lowBin || i > highBin {
                        realPtr[i] = 0
                        imagPtr[i] = 0
                    }
                }

                fft.inverse(input: split, output: &split)

                output.withUnsafeMutableBufferPointer { outPtr in
                    outPtr.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: n / 2) { cPtr in
                        vDSP_ztoc(&split, 1, cPtr, 2, vDSP_Length(n / 2))
                    }
                }
                // vDSP inverse FFT scaling: divide by 2*n.
                var scale: Float = 1.0 / Float(2 * n)
                vDSP_vsmul(output, 1, &scale, &output, 1, vDSP_Length(n))
            }
        }
        return Array(output.prefix(samples.count))
    }
}
