import SwiftUI

@MainActor
final class OnDemandViewModel: ObservableObject {
    @Published var config: TVBoxConfig?
    @Published var sites: [TVBoxSite] = []
    @Published var filteredSites: [TVBoxSite] = []
    @Published var searchText = "" { didSet { applyFilter() } }
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedSite: TVBoxSite?

    private let repository: CatalogRepository

    init(repository: CatalogRepository) {
        self.repository = repository
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let catalog = try await repository.loadCatalog()
            self.config = catalog
            sites = catalog.sites
            applyFilter()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func applyFilter() {
        if searchText.isEmpty {
            filteredSites = sites
        } else {
            let needle = searchText.lowercased()
            filteredSites = sites.filter { site in
                site.name.lowercased().contains(needle) || site.key.lowercased().contains(needle)
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
            header
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

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let spider = viewModel.config?.spider, !spider.isEmpty {
                Text("Spider: \(spider)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let wallpaper = viewModel.config?.wallpaper, !wallpaper.isEmpty {
                Text("Wallpaper: \(wallpaper)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var searchField: some View {
        TextField("搜尋站點名稱或 KEY", text: $viewModel.searchText)
            .textFieldStyle(.roundedBorder)
    }

    private var contentList: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("載入資料中…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.filteredSites.isEmpty {
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
                List(viewModel.filteredSites) { site in
                    Button { viewModel.selectedSite = site } label: {
                        SiteRow(site: site)
                    }
                }
                .listStyle(.plain)
            }
        }
        .sheet(item: $viewModel.selectedSite) { site in
            SiteDetailView(site: site)
        }
    }
}

private struct SiteRow: View {
    let site: TVBoxSite

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(site.name)
                .font(.headline)
            Text(site.metadataDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }
}

private struct SiteDetailView: View {
    let site: TVBoxSite

    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack { formContent }
        } else {
            NavigationView { formContent }
        }
    }

    private var formContent: some View {
        Form {
            Section(header: Text("基本資訊")) {
                InfoRow(title: "Key", value: site.key)
                if let api = site.api { InfoRow(title: "API", value: api) }
                if let jar = site.jar { InfoRow(title: "JAR", value: jar) }
                if let timeout = site.timeout { InfoRow(title: "Timeout", value: "\(timeout)s") }
            }
            if let ext = site.ext {
                Section(header: Text("EXT")) {
                    if let json = ext.json { InfoRow(title: "JSON", value: json) }
                    if let headers = ext.requestHeaders { InfoRow(title: "Headers", value: headers) }
                    if let other = ext.other, !other.isEmpty {
                        ForEach(other.keys.sorted(), id: \.self) { key in
                            InfoRow(title: key, value: other[key] ?? "")
                        }
                    }
                }
            }
        }
        .navigationTitle(site.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("關閉") { dismiss() }
            }
        }
    }

    @Environment(\.dismiss) private var dismiss
}

private struct InfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.footnote)
                .multilineTextAlignment(.trailing)
        }
    }
}

private struct IdentifiedError: Identifiable {
    let id = UUID()
    let message: String
}
