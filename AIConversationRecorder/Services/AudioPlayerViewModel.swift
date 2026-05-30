import Foundation
import AVFoundation

class AudioPlayerViewModel: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var isPlaying = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var playbackRate: Float = 1.0

    private var player: AVAudioPlayer?
    private var timer: Timer?

    var progress: Double { duration > 0 ? currentTime / duration : 0 }

    func load(url: URL) {
        player = try? AVAudioPlayer(contentsOf: url)
        player?.delegate = self
        player?.prepareToPlay()
        duration = player?.duration ?? 0
    }

    func togglePlay() {
        if isPlaying {
            player?.pause()
            timer?.invalidate()
        } else {
            player?.enableRate = true
            player?.rate = playbackRate
            player?.play()
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                self?.currentTime = self?.player?.currentTime ?? 0
            }
        }
        isPlaying.toggle()
    }

    func seek(to ratio: Double) {
        let t = max(0, min(1, ratio)) * duration
        player?.currentTime = t
        currentTime = t
    }

    func cycleRate() {
        let rates: [Float] = [1.0, 1.5, 2.0, 0.75]
        let idx = rates.firstIndex(of: playbackRate) ?? 0
        playbackRate = rates[(idx + 1) % rates.count]
        player?.enableRate = true
        player?.rate = playbackRate
    }

    func audioPlayerDidFinishPlaying(_: AVAudioPlayer, successfully _: Bool) {
        isPlaying = false
        currentTime = 0
        timer?.invalidate()
    }
}
