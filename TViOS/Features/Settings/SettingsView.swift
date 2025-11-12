import SwiftUI

@MainActor
struct SettingsView: View {
    @ObservedObject var settings: SettingsStore
    let catVodService: CatVodService
    @State private var statusMessage: String?
    @State private var isWorking = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("伺服器")) {
                    TextField("CatVod 主機 (含埠)", text: $settings.serverAddress)
                        .keyboardType(.URL)
                    TextField("點播 JSON", text: $settings.catalogEndpoint)
                        .keyboardType(.URL)
                    TextField("直播 JSON", text: $settings.liveEndpoint)
                        .keyboardType(.URL)
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

                Section(header: Text("CatVod API")) {
                    Button("刷新詳情") { trigger(.detail) }
                    Button("刷新播放") { trigger(.player) }
                    Button("刷新直播") { trigger(.live) }
                }

                if let status = statusMessage {
                    Section {
                        Text(status)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
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
    }

    private func trigger(_ type: CatVodActionType) {
        guard !isWorking else { return }
        isWorking = true
        statusMessage = nil
        Task {
            defer { isWorking = false }
            do {
                let response = try await catVodService.refresh(type)
                statusMessage = "完成：\(response)"
            } catch {
                statusMessage = "失敗：\(error.localizedDescription)"
            }
        }
    }
}
