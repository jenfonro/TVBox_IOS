import SwiftUI

@MainActor
final class OnDemandViewModel: ObservableObject {
    @Published var sites: [MediaSite] = []
    @Published var selectedSite: MediaSite?
    @Published var selectedCategory: MediaCategory?
    @Published var filteredItems: [MediaItem] = []
    @Published var searchText = "" { didSet { applyFilter() } }
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var nowPlaying: PlayableItem?

    private let repository: CatalogRepository
    private let playbackController: PlaybackController

    init(repository: CatalogRepository, playbackController: PlaybackController) {
        self.repository = repository
        self.playbackController = playbackController
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let catalog = try await repository.loadCatalog()
            sites = catalog.sites
            selectedSite = catalog.sites.first
            selectedCategory = catalog.sites.first?.categories.first
            applyFilter()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func select(site: MediaSite) {
        selectedSite = site
        selectedCategory = site.categories.first
        applyFilter()
    }

    func select(category: MediaCategory) {
        selectedCategory = category
        applyFilter()
    }

    func play(_ item: MediaItem) {
        guard let streamURL = item.streamURL else {
            errorMessage = "此資源沒有可播放的鏈接"
            return
        }
        let playable = PlayableItem(
            title: item.name,
            subtitle: item.remarks,
            artworkURL: item.posterURL,
            streamURL: streamURL
        )
        nowPlaying = playable
        playbackController.play(playable)
    }

    private func applyFilter() {
        guard let category = selectedCategory else {
            filteredItems = []
            return
        }
        if searchText.isEmpty {
            filteredItems = category.items
        } else {
            let needle = searchText.lowercased()
            filteredItems = category.items.filter { item in
                item.name.lowercased().contains(needle) ||
                (item.remarks?.lowercased().contains(needle) ?? false)
            }
        }
    }
}

@MainActor
struct OnDemandView: View {
    @StateObject private var viewModel: OnDemandViewModel

    init(viewModel: OnDemandViewModel) {
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
            sitePicker
            categoryPicker
            searchField
            contentList
        }
        .padding()
        .navigationTitle("點播")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { Task { await viewModel.load() } } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)
            }
        }
    }

    private var sitePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.sites) { site in
                    Button { viewModel.select(site: site) } label: {
                        Text(site.name)
                            .font(.footnote.bold())
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(site.id == viewModel.selectedSite?.id ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.selectedSite?.categories ?? []) { category in
                    Button { viewModel.select(category: category) } label: {
                        Text(category.name)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(category.id == viewModel.selectedCategory?.id ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private var searchField: some View {
        TextField("搜尋片名或標籤", text: $viewModel.searchText)
            .textFieldStyle(.roundedBorder)
    }

    private var contentList: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("載入資料中…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.filteredItems.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "film")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("沒有節目")
                        .font(.headline)
                    Text("請調整搜尋條件或換個分類。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(viewModel.filteredItems) { item in
                    Button { viewModel.play(item) } label: {
                        MediaRow(item: item)
                    }
                }
                .listStyle(.plain)
            }
        }
    }
}

private struct MediaRow: View {
    let item: MediaItem

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: item.posterURL) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay(Image(systemName: "film"))
            }
            .frame(width: 80, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 6) {
                Text(item.name)
                    .font(.headline)
                if let remarks = item.remarks {
                    Text(remarks)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if let style = item.style {
                    Text(style.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Image(systemName: "play.circle.fill")
                .font(.title2)
                .foregroundColor(.accentColor)
        }
        .contentShape(Rectangle())
    }
}

private struct IdentifiedError: Identifiable {
    let id = UUID()
    let message: String
}
