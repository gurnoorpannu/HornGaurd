import Foundation
import Combine
import AVFoundation

@MainActor
final class DemoModeViewModel: ObservableObject {
    struct Sample: Identifiable, Hashable {
        let id = UUID()
        let title: String
        let fileName: String  // without extension
        let isHorn: Bool
        let symbol: String
    }

    /// User must drop matching .wav files into the project bundle.
    /// File names here are matched against bundled resources.
    let samples: [Sample] = [
        .init(title: "Car horn",      fileName: "car_horn_1",    isHorn: true,  symbol: "car.fill"),
        .init(title: "Truck horn",    fileName: "truck_horn",    isHorn: true,  symbol: "truck.box.fill"),
        .init(title: "Truck horn 2",  fileName: "truck_horn_1",  isHorn: true,  symbol: "truck.box.fill"),
        .init(title: "Dog barking",   fileName: "dog_barking",   isHorn: false, symbol: "pawprint.fill"),
        .init(title: "Human shout",   fileName: "human_shouting", isHorn: false, symbol: "person.wave.2.fill")
    ]

    @Published var nowPlaying: Sample?
    @Published var missingFiles: [String] = []

    private var player: AVAudioPlayer?

    func play(_ sample: Sample) {
        stop()
        guard let url = url(for: sample) else {
            if !missingFiles.contains(sample.fileName) {
                missingFiles.append(sample.fileName)
            }
            return
        }
        do {
            let p = try AVAudioPlayer(contentsOf: url)
            p.prepareToPlay()
            p.play()
            player = p
            nowPlaying = sample
        } catch {
            print("[Demo] play failed: \(error)")
        }
    }

    func stop() {
        player?.stop()
        player = nil
        nowPlaying = nil
    }

    func isAvailable(_ sample: Sample) -> Bool { url(for: sample) != nil }

    private func url(for sample: Sample) -> URL? {
        for ext in ["wav", "mp3", "m4a", "aiff", "caf"] {
            if let u = Bundle.main.url(forResource: sample.fileName, withExtension: ext) {
                return u
            }
        }
        return nil
    }
}
