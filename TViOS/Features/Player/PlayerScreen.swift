import SwiftUI
import AVKit

struct PlayerScreen: View {
    @EnvironmentObject private var appState: AppState
    let item: PlayableItem

    var body: some View {
        VStack(spacing: 16) {
            VideoPlayer(player: appState.playbackController.player)
                .frame(height: 240)
                .onAppear { appState.playbackController.play(item) }
            VStack(alignment: .leading, spacing: 8) {
                Text(item.title)
                    .font(.title2.bold())
                if let subtitle = item.subtitle {
                    Text(subtitle)
                        .foregroundStyle(.secondary)
                }
                if let artwork = item.artworkURL {
                    AsyncImage(url: artwork) { image in
                        image.resizable().scaledToFit()
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                    }
                    .frame(maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            Spacer()
        }
        .padding()
    }
}
