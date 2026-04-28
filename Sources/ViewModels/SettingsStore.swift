import Foundation
import Combine

final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()

    @Published var llmConfig: LLMConfig = .default {
        didSet { save() }
    }

    private let defaults = UserDefaults.standard
    private let configKey = "llmConfig"

    init() {
        load()
    }

    private func load() {
        if let data = defaults.data(forKey: configKey),
           let config = try? JSONDecoder().decode(LLMConfig.self, from: data) {
            llmConfig = config
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(llmConfig) {
            defaults.set(data, forKey: configKey)
        }
    }

    var isConfigured: Bool {
        !llmConfig.apiKey.isEmpty
    }
}
