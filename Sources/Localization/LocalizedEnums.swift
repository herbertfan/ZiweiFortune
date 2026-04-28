import Foundation

extension Gender {
    var localizedName: String {
        switch self {
        case .male: return L(StringKey.male)
        case .female: return L(StringKey.female)
        }
    }
}

extension InterpretationScope {
    var localizedName: String {
        switch self {
        case .natal: return L(StringKey.aiScopeNatal)
        case .decadal: return L(StringKey.aiScopeDecadal)
        case .yearly: return L(StringKey.aiScopeYearly)
        case .palace: return L(StringKey.aiScopePalace)
        }
    }
}

extension Pattern.PatternLevel {
    var localizedName: String {
        switch self {
        case .supreme: return L(StringKey.patternSupreme)
        case .high: return L(StringKey.patternHigh)
        case .medium: return L(StringKey.patternMedium)
        case .special: return L(StringKey.patternSpecial)
        }
    }
}

extension LLMProvider {
    var localizedName: String {
        switch self {
        case .claude: return "Claude"
        case .deepseek: return "DeepSeek"
        case .openai: return "OpenAI"
        case .custom: return L(StringKey.provider)
        }
    }
}
