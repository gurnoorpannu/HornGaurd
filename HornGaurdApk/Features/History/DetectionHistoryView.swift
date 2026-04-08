import SwiftUI

struct DetectionHistoryView: View {
    @ObservedObject var engine: DetectionEngine
    @State private var showShare = false
    @State private var csvURL: URL?

    var body: some View {
        NavigationStack {
            Group {
                if engine.history.isEmpty {
                    ContentUnavailableView(
                        "No detections yet",
                        systemImage: "shield",
                        description: Text("Confirmed horn detections will appear here.")
                    )
                } else {
                    List(engine.history) { item in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.identifier.replacingOccurrences(of: "_", with: " "))
                                    .font(.headline)
                                Text(item.timestamp, style: .time)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(Int(item.confidence * 100))%")
                                .font(.callout.monospaced())
                                .foregroundStyle(.orange)
                        }
                    }
                }
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if let url = exportCSV() {
                            csvURL = url
                            showShare = true
                        }
                    } label: { Image(systemName: "square.and.arrow.up") }
                    .disabled(engine.history.isEmpty)
                }
            }
            .sheet(isPresented: $showShare) {
                if let csvURL { ShareSheet(items: [csvURL]) }
            }
        }
    }

    private func exportCSV() -> URL? {
        var csv = "timestamp,identifier,confidence\n"
        let fmt = ISO8601DateFormatter()
        for d in engine.history {
            csv += "\(fmt.string(from: d.timestamp)),\(d.identifier),\(d.confidence)\n"
        }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("hornguard_history.csv")
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch { return nil }
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
