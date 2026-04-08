import SwiftUI

struct DemoModeView: View {
    @ObservedObject var engine: DetectionEngine
    @StateObject private var vm = DemoModeViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    header
                    liveStrip
                    SpectrogramView(matrix: engine.spectrogram)
                        .frame(height: 130)
                    ConfidenceGraph(values: engine.confidenceHistory,
                                    threshold: AudioConstants.confidenceThreshold)
                        .frame(height: 80)
                    sampleGrid
                    if !vm.missingFiles.isEmpty {
                        missingNotice
                    }
                }
                .padding()
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Demo Mode")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark)
            .onAppear {
                if !engine.isListening { Task { await engine.start() } }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text("Tap a sample to play it through the speaker.")
                .font(.callout)
                .foregroundStyle(.white.opacity(0.7))
            Text("HornGuard listens via the mic and reacts in real time.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
        }
        .multilineTextAlignment(.center)
    }

    private var liveStrip: some View {
        HStack(spacing: 12) {
            metric("Confidence", "\(Int((engine.lastResult?.confidence ?? 0) * 100))%")
            metric("Detections", "\(engine.detectionsToday)")
            metric("Status", engine.isListening ? "LIVE" : "OFF")
        }
    }

    private func metric(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.title3.weight(.bold)).foregroundStyle(.orange)
            Text(label).font(.caption2).foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var sampleGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(vm.samples) { s in
                Button { vm.play(s) } label: {
                    VStack(spacing: 8) {
                        Image(systemName: s.symbol)
                            .font(.system(size: 28))
                            .foregroundStyle(s.isHorn ? .orange : .blue)
                        Text(s.title)
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(.white)
                        Text(s.isHorn ? "Should detect" : "Should ignore")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(vm.nowPlaying == s ? Color.orange.opacity(0.25) : Color.white.opacity(0.06))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(vm.isAvailable(s) ? Color.clear : Color.red.opacity(0.4), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var missingNotice: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Missing audio files", systemImage: "exclamationmark.triangle.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(.yellow)
            Text("Add these to the app bundle (any of: wav/mp3/m4a):")
                .font(.caption2).foregroundStyle(.white.opacity(0.6))
            ForEach(vm.missingFiles, id: \.self) { f in
                Text("• \(f)").font(.caption2.monospaced()).foregroundStyle(.white.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.yellow.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
