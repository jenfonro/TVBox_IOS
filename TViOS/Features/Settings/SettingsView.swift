import SwiftUI

@MainActor
struct SettingsView: View {
    @ObservedObject var settings: SettingsStore
    @State private var statusMessage: String?
    @State private var isWorking = false
    @State private var debugLog: [String] = []

    @EnvironmentObject private var appState: AppState

    var body: some View {
        navigationContainer
    }

    @ViewBuilder
    private var navigationContainer: some View {
        if #available(iOS 16.0, *) {
            NavigationStack { formContent }
        } else {
            NavigationView { formContent }
        }
    }

    private var formContent: some View {
        Form {
            Section(header: Text("點播")) {
                TextField("點播 JSON", text: $settings.catalogEndpoint)
                    .keyboardType(.URL)
                Picker("請求方式", selection: $settings.requestMode) {
                    ForEach(RequestMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section(header: Text("代理")) {
                Toggle("啟用代理", isOn: Binding(
                    get: { settings.proxy != nil },
                    set: { enabled in
                        if !enabled {
                            settings.proxy = nil
                        } else if settings.proxy == nil {
                            settings.proxy = ProxyConfig()
                        }
                    }
                ))
                if settings.proxy != nil {
                    TextField("代理協議 (http / https / socks5)", text: Binding(
                        get: { settings.proxy?.scheme ?? "" },
                        set: { newValue in settings.updateProxy { $0.scheme = newValue } }
                    ))
                    TextField("主機", text: Binding(
                        get: { settings.proxy?.host ?? "" },
                        set: { newValue in settings.updateProxy { $0.host = newValue } }
                    ))
                    TextField("埠", text: Binding(
                        get: { settings.proxy?.portString ?? "" },
                        set: { newValue in settings.updateProxy { $0.portString = newValue } }
                    ))
                    TextField("使用者", text: Binding(
                        get: { settings.proxy?.username ?? "" },
                        set: { newValue in settings.updateProxy { $0.username = newValue } }
                    ))
                    SecureField("密碼", text: Binding(
                        get: { settings.proxy?.password ?? "" },
                        set: { newValue in settings.updateProxy { $0.password = newValue } }
                    ))
                }
            }

            Section(header: Text("樣式")) {
                Picker("卡片樣式", selection: $settings.style.type) {
                    ForEach(MediaStyle.StyleType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                Stepper(value: $settings.style.ratio, in: 0.5...2, step: 0.05) {
                    Text("比例：\(String(format: "%.2f", settings.style.ratio))")
                }
            }

            if let status = statusMessage {
                Section(header: Text("Debug")) {
                    Text(status)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    if !debugLog.isEmpty {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(debugLog.indices, id: \.self) { index in
                                    Text(debugLog[index])
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .frame(height: 120)
                    }
                }
            }

            Section {
                Button("儲存設定") {
                    settings.persist()
                    statusMessage = "設定已儲存"
                }
                Button("恢復預設", role: .destructive) {
                    settings.reset()
                }
                Button("刷新點播") {
                    Task { await refreshCatalog() }
                }
            }
        }
        .navigationTitle("設定")
        .disabled(isWorking)
        .toolbar {
            if isWorking {
                ProgressView()
            }
        }
    }

    private func refreshCatalog() async {
        guard !isWorking else { return }
        isWorking = true
        statusMessage = "正在刷新..."
        appendLog("開始刷新配置：\(settings.catalogEndpoint)")
        do {
            let catalog = try await appState.catalogRepository.loadCatalog(forceRemote: true)
            statusMessage = "刷新完成，共 \(catalog.sites.count) 個站點"
            appendLog("刷新成功")
        } catch {
            statusMessage = "刷新失敗：\(error.localizedDescription)"
            appendLog("錯誤詳情：\(String(describing: error))")
        }
        isWorking = false
    }

    private func appendLog(_ message: String) {
        debugLog.append("[\(Date().description)] \(message)")
        if debugLog.count > 20 {
            debugLog.removeFirst(debugLog.count - 20)
        }
    }
}
