import SwiftUI

/// Renders a [melBands][width] 0…1 matrix as a heat-map.
/// Y axis = mel bands (low → high frequency, bottom → top).
/// X axis = time (oldest → newest, left → right).
struct SpectrogramView: View {
    let matrix: [[Float]]

    var body: some View {
        Canvas { ctx, size in
            guard !matrix.isEmpty else { return }
            let bands = matrix.count
            let width = matrix[0].count
            let cellW = size.width / CGFloat(width)
            let cellH = size.height / CGFloat(bands)

            for b in 0..<bands {
                for x in 0..<width {
                    let v = matrix[b][x]
                    let rect = CGRect(
                        x: CGFloat(x) * cellW,
                        // Flip Y so low frequencies are at the bottom.
                        y: CGFloat(bands - 1 - b) * cellH,
                        width: cellW + 0.5,
                        height: cellH + 0.5
                    )
                    ctx.fill(Path(rect), with: .color(Self.color(for: v)))
                }
            }
        }
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
    }

    /// Viridis-ish colormap: dark blue → cyan → yellow → orange.
    private static func color(for v: Float) -> Color {
        let t = max(0, min(1, Double(v)))
        if t < 0.33 {
            let k = t / 0.33
            return Color(red: 0.05, green: 0.0 + k * 0.4, blue: 0.3 + k * 0.5)
        } else if t < 0.66 {
            let k = (t - 0.33) / 0.33
            return Color(red: 0.05 + k * 0.6, green: 0.4 + k * 0.5, blue: 0.8 - k * 0.6)
        } else {
            let k = (t - 0.66) / 0.34
            return Color(red: 0.65 + k * 0.35, green: 0.9 - k * 0.4, blue: 0.2 - k * 0.2)
        }
    }
}
