import Foundation
import AVFoundation

final class PlaybackController: ObservableObject {
    @Published private(set) var nowPlaying: PlayableItem?
    let player = AVPlayer()

    func play(_ item: PlayableItem) {
        nowPlaying = item
        let playerItem = AVPlayerItem(url: item.streamURL)
        player.replaceCurrentItem(with: playerItem)
        player.play()
    }
}
