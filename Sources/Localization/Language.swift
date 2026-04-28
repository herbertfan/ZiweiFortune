import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case system = "system"
    case traditionalChinese = "zh-Hant"
    case simplifiedChinese = "zh-Hans"
    case japanese = "ja"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system:           return L("lang_system")
        case .traditionalChinese: return "繁體中文"
        case .simplifiedChinese: return "简体中文"
        case .japanese:         return "日本語"
        }
    }

    static var effectiveLanguage: AppLanguage {
        let stored = UserDefaults.standard.string(forKey: "appLanguage") ?? "system"
        if stored == "system" {
            return detectSystemLanguage()
        }
        return AppLanguage(rawValue: stored) ?? .traditionalChinese
    }

    private static func detectSystemLanguage() -> AppLanguage {
        let preferred = Locale.preferredLanguages.first ?? "zh-Hant"
        let locale = Locale(identifier: preferred)

        if let languageCode = locale.language.languageCode?.identifier {
            switch languageCode {
            case "ja":
                return .japanese
            case "zh":
                let script = locale.language.script?.identifier ?? "Hant"
                return script == "Hans" ? .simplifiedChinese : .traditionalChinese
            default:
                break
            }
        }

        // Fallback: check if simplified by region
        if preferred.contains("Hans") || preferred.contains("CN") {
            return .simplifiedChinese
        }
        return .traditionalChinese
    }
}
