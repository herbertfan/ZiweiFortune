import SwiftUI

struct AIInterpretationView: View {
    let chart: ZiweiChart
    let client: Client

    @StateObject private var settings = SettingsStore.shared
    @State private var scope: InterpretationScope = .natal
    @State private var selectedPalace: String?
    @State private var interpretationText = ""
    @State private var isLoading = false
    @State private var showingSettings = false
    @State private var errorMessage: String?
    @State private var showingError = false

    private var palaceNames: [String] {
        chart.palaces.map { $0.name }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 顶部控制栏
            HStack(spacing: 16) {
                Picker(L("interpretation_scope"), selection: $scope) {
                    ForEach(InterpretationScope.allCases, id: \.self) { s in
                        Text(s.localizedName).tag(s)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 300)

                if scope == .palace {
                    Picker(L("palace"), selection: $selectedPalace) {
                        ForEach(palaceNames, id: \.self) { name in
                            Text(localizedPalaceName(name)).tag(name as String?)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 120)
                }

                Spacer()

                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                }

                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.borderless)

                Button {
                    Task { await generateInterpretation() }
                } label: {
                    Image(systemName: "wand.and.stars")
                    Text(L("ai_interpretation"))
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading || !settings.isConfigured)
            }
            .padding()

            Divider()

            if !settings.isConfigured {
                VStack(spacing: 16) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text(L("please_set_api_key"))
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Button(L("open_settings")) {
                        showingSettings = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.textBackgroundColor))
            } else if interpretationText.isEmpty && !isLoading {
                VStack(spacing: 16) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    Text(L("click_ai_interpret"))
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text(L("ai_theory_desc"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.textBackgroundColor))
            } else {
                ScrollView {
                    Text(interpretationText)
                        .font(.system(size: 14))
                        .lineSpacing(6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                .background(Color(.textBackgroundColor))
            }
        }
        .sheet(isPresented: $showingSettings) {
            LLMSettingsView()
        }
        .alert(L("error"), isPresented: $showingError) {
            Button(L("confirm"), role: .cancel) {}
        } message: {
            Text(errorMessage ?? L("unknown_error"))
        }
    }

    private func generateInterpretation() async {
        guard settings.isConfigured else {
            errorMessage = L("please_config_api_key")
            showingError = true
            return
        }

        isLoading = true
        interpretationText = ""
        defer { isLoading = false }

        let focus = scope == .palace ? selectedPalace : nil
        let stream = await LLMService.shared.streamInterpretation(
            config: settings.llmConfig,
            chart: chart,
            client: client,
            scope: scope,
            focusPalace: focus
        )

        do {
            for try await chunk in stream {
                await MainActor.run {
                    interpretationText += chunk
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
}

// MARK: - LLM Settings View

struct LLMSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var settings = SettingsStore.shared

    @State private var provider: LLMProvider = .claude
    @State private var apiKey = ""
    @State private var baseURL = ""
    @State private var model = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(L("ai_settings"))
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button(L("close")) {
                    dismiss()
                }
                .keyboardShortcut(.escape)
            }
            .padding()

            Divider()

            Form {
                Section(L("model_provider")) {
                    Picker(L("provider"), selection: $provider) {
                        ForEach(LLMProvider.allCases, id: \.self) { p in
                            Text(p.localizedName).tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: provider) { _, new in
                        baseURL = new.defaultBaseURL
                        model = new.defaultModel
                    }
                }

                Section(L("api_config")) {
                    TextField("API Key", text: $apiKey)
                        .textFieldStyle(.roundedBorder)
                    if provider == .custom {
                        TextField("Base URL", text: $baseURL)
                            .textFieldStyle(.roundedBorder)
                    }
                    TextField(L("model_name"), text: $model)
                        .textFieldStyle(.roundedBorder)
                }

                Section {
                    Text(L("api_key_local"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .formStyle(.grouped)
            .padding()

            Divider()

            HStack {
                Spacer()
                Button(L("save")) {
                    settings.llmConfig = LLMConfig(
                        provider: provider,
                        apiKey: apiKey,
                        baseURL: baseURL,
                        model: model
                    )
                    dismiss()
                }
                .keyboardShortcut(.return)
                .disabled(apiKey.isEmpty || model.isEmpty)
            }
            .padding()
        }
        .frame(width: 500, height: 400)
        .onAppear {
            provider = settings.llmConfig.provider
            apiKey = settings.llmConfig.apiKey
            baseURL = settings.llmConfig.baseURL
            model = settings.llmConfig.model
        }
    }
}
