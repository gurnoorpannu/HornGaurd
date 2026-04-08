import SwiftUI

/// Scrolling line chart of horn classification confidence (0…1).
struct ConfidenceGraph: View {
    let values: [Float]
    let threshold: Float

    var body: some View {
        Canvas { ctx, size in
            // Background grid
            let gridColor = GraphicsContext.Shading.color(.white.opacity(0.08))
            for i in 1..<4 {
                let y = size.height * CGFloat(i) / 4
                var p = Path()
                p.move(to: CGPoint(x: 0, y: y))
                p.addLine(to: CGPoint(x: size.width, y: y))
                ctx.stroke(p, with: gridColor, lineWidth: 1)
            }

            // Threshold line
            let ty = size.height * (1 - CGFloat(threshold))
            var tp = Path()
            tp.move(to: CGPoint(x: 0, y: ty))
            tp.addLine(to: CGPoint(x: size.width, y: ty))
            ctx.stroke(tp, with: .color(.orange.opacity(0.7)),
                       style: StrokeStyle(lineWidth: 1, dash: [4, 4]))

            guard values.count > 1 else { return }
            let stepX = size.width / CGFloat(max(values.count - 1, 1))

            var line = Path()
            for (i, v) in values.enumerated() {
                let x = CGFloat(i) * stepX
                let y = size.height * (1 - CGFloat(max(0, min(1, v))))
                if i == 0 { line.move(to: CGPoint(x: x, y: y)) }
                else { line.addLine(to: CGPoint(x: x, y: y)) }
            }
            ctx.stroke(line, with: .color(.green), lineWidth: 2)
        }
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
    }
}
