import Foundation

enum LLMProvider: String, Codable, CaseIterable {
    case claude = "Claude"
    case deepseek = "DeepSeek"
    case openai = "OpenAI"
    case custom = "自定义"

    var defaultBaseURL: String {
        switch self {
        case .claude: return "https://api.anthropic.com/v1/messages"
        case .deepseek: return "https://api.deepseek.com/chat/completions"
        case .openai: return "https://api.openai.com/v1/chat/completions"
        case .custom: return ""
        }
    }

    var defaultModel: String {
        switch self {
        case .claude: return "claude-sonnet-4-6-20251101"
        case .deepseek: return "deepseek-chat"
        case .openai: return "gpt-4o"
        case .custom: return ""
        }
    }

    var apiKeyHeader: String {
        switch self {
        case .claude: return "x-api-key"
        case .deepseek, .openai, .custom: return "Authorization"
        }
    }

    var apiKeyPrefix: String {
        switch self {
        case .claude: return ""
        case .deepseek, .openai, .custom: return "Bearer "
        }
    }
}

struct LLMConfig: Codable {
    var provider: LLMProvider
    var apiKey: String
    var baseURL: String
    var model: String

    static let `default` = LLMConfig(
        provider: .claude,
        apiKey: "",
        baseURL: LLMProvider.claude.defaultBaseURL,
        model: LLMProvider.claude.defaultModel
    )
}

enum InterpretationScope: String, CaseIterable {
    case natal = "本命盘"
    case decadal = "大限运程"
    case yearly = "流年运势"
    case palace = "宫位详解"
}
