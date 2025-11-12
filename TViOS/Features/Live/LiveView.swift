import SwiftUI

@MainActor
final class LiveViewModel: ObservableObject {
    @Published var groups: [LiveGroup] = []
    @Published var selectedGroup: LiveGroup?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var nowPlaying: PlayableItem?

    private let repository: LiveRepository
    private let playbackController: PlaybackController

    init(repository: LiveRepository, playbackController: PlaybackController) {
        self.repository = repository
        self.playbackController = playbackController
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let playlist = try await repository.loadPlaylist()
            groups = playlist.groups
            selectedGroup = playlist.groups.first
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func select(group: LiveGroup) {
        selectedGroup = group
    }

    func play(_ channel: LiveChannel) {
        guard let streamURL = channel.streamURL else {
            errorMessage = "流媒體網址無效"
            return
        }
        let item = PlayableItem(
            title: channel.name,
            subtitle: channel.description,
            artworkURL: channel.logoURL,
            streamURL: streamURL
        )
        nowPlaying = item
        playbackController.play(item)
    }
}

@MainActor
struct LiveView: View {
    @StateObject private var viewModel: LiveViewModel

    init(viewModel: LiveViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        navigationContainer
            .task { await viewModel.load() }
            .sheet(item: $viewModel.nowPlaying) { PlayerScreen(item: $0) }
            .alert(item: Binding(
                get: { viewModel.errorMessage.map(IdentifiedError.init(message:)) },
                set: { _ in viewModel.errorMessage = nil }
            )) { identified in
                Alert(title: Text("錯誤"), message: Text(identified.message), dismissButton: .default(Text("好")))
            }
    }

    @ViewBuilder
    private var navigationContainer: some View {
        if #available(iOS 16.0, *) {
            NavigationStack { navigationContent }
        } else {
            NavigationView { navigationContent }
        }
    }

    private var navigationContent: some View {
        VStack(spacing: 12) {
            groupPicker
            channelList
        }
        .padding()
        .navigationTitle("直播")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { Task { await viewModel.load() } } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)
            }
        }
    }

    private var groupPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.groups) { group in
                    Button { viewModel.select(group: group) } label: {
                        Text(group.name)
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(group.id == viewModel.selectedGroup?.id ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private var channelList: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("正在讀取頻道…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if (viewModel.selectedGroup?.channels ?? []).isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tv")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("沒有可播放的頻道")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(viewModel.selectedGroup?.channels ?? []) { channel in
                    Button { viewModel.play(channel) } label: {
                        LiveRow(channel: channel)
                    }
                }
                .listStyle(.plain)
            }
        }
    }
}

private struct LiveRow: View {
    let channel: LiveChannel

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: channel.logoURL) { image in
                image.resizable().scaledToFit()
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay(Image(systemName: "bolt.horizontal.circle"))
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(channel.name)
                    .font(.headline)
                if let description = channel.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Image(systemName: "play.circle")
                .font(.title3)
                .foregroundColor(.accentColor)
        }
        .contentShape(Rectangle())
    }
}

private struct IdentifiedError: Identifiable {
    let id = UUID()
    let message: String
}
