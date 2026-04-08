import SwiftUI

struct SoundLevelMeter: View {
    let level: Float // 0…1

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.white.opacity(0.08))
                RoundedRectangle(cornerRadius: 6)
                    .fill(LinearGradient(
                        colors: [.green, .yellow, .orange, .red],
                        startPoint: .leading, endPoint: .trailing
                    ))
                    .frame(width: geo.size.width * CGFloat(max(0, min(1, level))))
                    .animation(.linear(duration: 0.08), value: level)
            }
        }
        .frame(height: 12)
    }
}
