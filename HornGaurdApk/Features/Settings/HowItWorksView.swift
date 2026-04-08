import SwiftUI

struct HowItWorksView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                section(
                    title: "1. Microphone capture",
                    body: "AVAudioEngine taps the mic at the device's hardware sample rate, streaming PCM buffers on a background queue. The audio session uses .playAndRecord with .duckOthers so music can play simultaneously."
                )
                section(
                    title: "2. Bandpass filter (200–1200 Hz)",
                    body: "An FFT-based filter zeros frequency bins outside the horn band. Indian car horns are 300–500 Hz, truck air horns 200–400 Hz, two-wheeler horns 400–800 Hz. This kills wind noise (<200 Hz) and irrelevant high frequencies."
                )
                section(
                    title: "3. Mel spectrogram",
                    body: "STFT (FFT 512, 50% overlap) → power spectrum → 64 triangular Mel filters → log compression. The Mel scale m = 2595·log₁₀(1 + f/700) maps frequencies the way human hearing perceives them."
                )
                section(
                    title: "4. Sound classification",
                    body: "Apple's SoundAnalysis framework runs an on-device classifier (Version 1) over each audio window, returning per-class confidences. We watch for car_horn / vehicle_horn / honking / air_horn identifiers."
                )
                section(
                    title: "5. Temporal validation",
                    body: "A horn is confirmed only when 3 consecutive frames exceed the confidence threshold. This filters out impulse noise (door slams, firecrackers) that last <200 ms and can't sustain a streak."
                )
                section(
                    title: "6. Latency budget",
                    body: "200 ms frame + ~20 ms inference + 3-frame confirmation ≈ 620 ms total. At 40 km/h a vehicle covers ~7 m in that time — still well within rider reaction range."
                )
                section(
                    title: "7. Multi-modal alert",
                    body: "On confirmation: CoreHaptics fires a sharp buzz pattern, the screen border flashes orange, music ducks via AVAudioSession, and VoiceOver announces 'Horn detected nearby'."
                )
            }
            .padding()
        }
        .navigationTitle("How It Works")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func section(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.headline)
            Text(body).font(.callout).foregroundStyle(.secondary)
        }
    }
}

#Preview { NavigationStack { HowItWorksView() } }
