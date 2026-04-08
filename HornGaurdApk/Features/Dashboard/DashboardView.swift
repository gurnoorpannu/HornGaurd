import SwiftUI

struct DashboardView: View {
    @ObservedObject var engine: DetectionEngine
    @State private var alertFlash = false

    private var isAlerting: Bool {
        guard let last = engine.lastConfirmed else { return false }
        return Date().timeIntervalSince(last.timestamp) < 2.0
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 20) {
                statusBar
                centralIndicator
                visualizations
                statsRow
                controlButton
            }
            .padding()

            if alertFlash && SettingsStore.shared.visualEnabled {
                Rectangle()
                    .stroke(Color.orange, lineWidth: 16)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: engine.lastConfirmed) { _, _ in
            withAnimation(.easeInOut(duration: 0.15)) { alertFlash = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeOut(duration: 0.4)) { alertFlash = false }
            }
        }
        .alert("Error", isPresented: .constant(engine.errorMessage != nil), actions: {
            Button("OK") { engine.errorMessage = nil }
        }, message: { Text(engine.errorMessage ?? "") })
    }

    private var statusBar: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isAlerting ? .red : (engine.isListening ? .green : .gray))
                .frame(width: 12, height: 12)
            Text(isAlerting ? "HORN DETECTED" : (engine.isListening ? "LISTENING" : "PAUSED"))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.85))
            Spacer()
        }
    }

    private var centralIndicator: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(isAlerting ? Color.orange : Color.green.opacity(0.5), lineWidth: 4)
                    .frame(width: 240, height: 240)
                    .scaleEffect(engine.isListening ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                               value: engine.isListening)
                Image(systemName: isAlerting ? "exclamationmark.triangle.fill" : "shield.lefthalf.filled")
                    .font(.system(size: 100, weight: .bold))
                    .foregroundStyle(isAlerting ? .orange : .green)
            }
            Text(isAlerting ? "HORN!" : (engine.isListening ? "All clear" : "Tap Start"))
                .font(.system(size: 36, weight: .heavy))
                .foregroundStyle(.white)
            if isAlerting, let dir = engine.lastConfirmed?.direction, dir != .unknown {
                HStack(spacing: 8) {
                    Image(systemName: dir.arrowSymbol)
                        .font(.title2.weight(.bold))
                    Text(dir.label).font(.title3.weight(.bold))
                }
                .foregroundStyle(.orange)
            }
            if let r = engine.lastResult {
                Text("\(r.identifier)  ·  \(Int(r.confidence * 100))%")
                    .font(.caption.monospaced())
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
    }

    private var visualizations: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "waveform")
                    .foregroundStyle(.white.opacity(0.5))
                SoundLevelMeter(level: engine.audioLevel)
            }
            SpectrogramView(matrix: engine.spectrogram)
                .frame(height: 110)
            ConfidenceGraph(values: engine.confidenceHistory,
                            threshold: AudioConstants.confidenceThreshold)
                .frame(height: 70)
        }
    }

    private var statsRow: some View {
        HStack {
            stat("Today", "\(engine.detectionsToday)")
            Spacer()
            stat("Last", lastAgo)
            Spacer()
            stat("Status", engine.isListening ? "ON" : "OFF")
        }
        .padding(.horizontal)
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.title3.weight(.bold)).foregroundStyle(.white)
            Text(label).font(.caption2).foregroundStyle(.white.opacity(0.5))
        }
    }

    private var lastAgo: String {
        guard let t = engine.lastConfirmed?.timestamp else { return "—" }
        let s = Int(Date().timeIntervalSince(t))
        return "\(s)s"
    }

    private var controlButton: some View {
        Button {
            if engine.isListening { engine.stop() }
            else { Task { await engine.start() } }
        } label: {
            Text(engine.isListening ? "STOP" : "START")
                .font(.title2.weight(.bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(engine.isListening ? Color.red : Color.green)
                .foregroundStyle(.black)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

#Preview { DashboardView(engine: DetectionEngine()) }
