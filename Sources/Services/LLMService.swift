import Foundation
import Combine

actor LLMService {
    static let shared = LLMService()
    private init() {}

    func streamInterpretation(
        config: LLMConfig,
        chart: ZiweiChart,
        client: Client,
        scope: InterpretationScope,
        focusPalace: String? = nil
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let prompt = buildPrompt(chart: chart, client: client, scope: scope, focusPalace: focusPalace)
                    let request = try buildRequest(config: config, prompt: prompt)

                    let (data, response) = try await URLSession.shared.bytes(for: request)
                    guard let httpResponse = response as? HTTPURLResponse,
                          (200...299).contains(httpResponse.statusCode) else {
                        continuation.finish(throwing: LLMError.invalidResponse)
                        return
                    }

                    for try await line in data.lines {
                        if line.isEmpty { continue }
                        if let chunk = parseChunk(line: line, provider: config.provider) {
                            continuation.yield(chunk)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    func streamChat(config: LLMConfig, prompt: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let request = try buildRequest(config: config, prompt: prompt)
                    let (data, response) = try await URLSession.shared.bytes(for: request)
                    guard let httpResponse = response as? HTTPURLResponse,
                          (200...299).contains(httpResponse.statusCode) else {
                        continuation.finish(throwing: LLMError.invalidResponse)
                        return
                    }
                    for try await line in data.lines {
                        if line.isEmpty { continue }
                        if let chunk = parseChunk(line: line, provider: config.provider) {
                            continuation.yield(chunk)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - Request Builder

    private func buildRequest(config: LLMConfig, prompt: String) throws -> URLRequest {
        guard let url = URL(string: config.baseURL) else {
            throw LLMError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(config.provider.apiKeyPrefix + config.apiKey, forHTTPHeaderField: config.provider.apiKeyHeader)

        if config.provider == .claude {
            request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
            request.setValue("true", forHTTPHeaderField: "anthropic-dangerous-direct-browser-unfiltered-access")
        }

        let body: [String: Any]
        switch config.provider {
        case .claude:
            body = [
                "model": config.model,
                "max_tokens": 4096,
                "messages": [["role": "user", "content": prompt]],
                "stream": true
            ]
        case .deepseek, .openai, .custom:
            body = [
                "model": config.model,
                "messages": [
                    ["role": "system", "content": systemPrompt],
                    ["role": "user", "content": prompt]
                ],
                "stream": true
            ]
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    // MARK: - Chunk Parser

    private func parseChunk(line: String, provider: LLMProvider) -> String? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("data: ") else { return nil }
        let dataStr = String(trimmed.dropFirst(6))
        if dataStr == "[DONE]" { return nil }

        guard let data = dataStr.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        switch provider {
        case .claude:
            if let contentBlock = json["content_block"] as? [String: Any],
               let text = contentBlock["text"] as? String {
                return text
            }
            if let delta = json["delta"] as? [String: Any],
               let text = delta["text"] as? String {
                return text
            }
        case .deepseek, .openai, .custom:
            if let choices = json["choices"] as? [[String: Any]],
               let first = choices.first,
               let delta = first["delta"] as? [String: Any],
               let content = delta["content"] as? String {
                return content
            }
        }
        return nil
    }

    // MARK: - Prompt Builder

    private let systemPrompt = """
    你是一位精通紫微斗数的中州派命理师，拥有数十年实盘经验。你的解盘风格严谨而温暖，遵循传统紫微斗数理论，以中州派安星法和四化飞星为核心分析手段。

    解盘原则：
    1. 先看命宫格局，再论三方四正
    2. 四化飞星是动态分析的核心，必须详细说明
    3. 主星组合决定格局高低，辅星煞星影响吉凶程度
    4. 运限分析要结合本命盘一起看
    5. 用语要专业但易懂，避免过于晦涩
    """

    private func buildPrompt(chart: ZiweiChart, client: Client, scope: InterpretationScope, focusPalace: String?) -> String {
        var prompt = ""

        // 基本信息
        prompt += "【命主资料】\n"
        prompt += "姓名：\(client.name)\n"
        prompt += "性别：\(client.gender.rawValue)\n"
        prompt += "阳历：\(chart.solarDate)\n"
        if let lunar = chart.lunarDate {
            prompt += "农历：\(lunar)\n"
        }
        prompt += "五行局：\(chart.wuXingJu.rawValue)\n"
        prompt += "生肖：\(chart.fourPillars.year.earthlyBranch.zodiac)\n"
        prompt += "命主星：\(chart.soul)\n"
        prompt += "身主星：\(chart.body)\n\n"

        // 四柱
        prompt += "【四柱八字】\n"
        prompt += "年柱：\(chart.fourPillars.year.displayName)\n"
        prompt += "月柱：\(chart.fourPillars.month.displayName)\n"
        prompt += "日柱：\(chart.fourPillars.day.displayName)\n"
        prompt += "时柱：\(chart.fourPillars.hour.displayName)\n\n"

        // 十二宫主星
        prompt += "【十二宫主星】\n"
        for palace in chart.palaces {
            let stars = palace.majorStars.map { star in
                var name = star.name
                if let t = star.transformation { name += "(\(t))" }
                name += "[\(star.brightness)]"
                return name
            }.joined(separator: "、")
            let minor = palace.minorStars.map { $0.name }.joined(separator: ", ")
            let adj = palace.adjectiveStars.map { $0.name }.joined(separator: ", ")
            var line = "\(palace.name)(\(palace.heavenlyStem?.displayName ?? "")\(palace.earthlyBranch?.displayName ?? ""))：\(stars.isEmpty ? "借对宫" : stars)"
            if !minor.isEmpty { line += " | 六吉六煞：\(minor)" }
            if !adj.isEmpty { line += " | 杂曜：\(adj)" }
            prompt += line + "\n"
        }
        prompt += "\n"

        // 四化飞星
        let flies = chart.allFlyingStars
        if !flies.isEmpty {
            prompt += "【四化飞星】\n"
            for fly in flies {
                prompt += "\(fly.fromPalaceName) 化\(fly.transformation) \(fly.starName) → 入\(fly.toPalaceName)\n"
            }
            prompt += "\n"
        }

        // 来因宫
        if let laiYin = chart.palaces.first(where: { $0.isOriginalPalace }) {
            prompt += "【来因宫】\(laiYin.name)\n\n"
        }

        // 大限
        if let decadal = chart.palaces.compactMap({ $0.decadal }).min(by: { (a: Decadal, b: Decadal) -> Bool in a.range.0 < b.range.0 }) {
            prompt += "【当前大限】\(decadal.displayName)（\(decadal.range.0)-\(decadal.range.1)岁）\n\n"
        }

        // 解读请求
        prompt += "【解读要求】\n"
        switch scope {
        case .natal:
            prompt += "请对以上命盘进行本命盘全面解读。重点分析：\n"
            prompt += "1. 命宫格局与性格特质\n"
            prompt += "2. 三方四正的星曜组合与格局判断\n"
            prompt += "3. 四化飞星的动态影响\n"
            prompt += "4. 事业、财运、感情、健康各宫位的吉凶\n"
            prompt += "5. 人生整体运势走向建议\n"
        case .decadal:
            prompt += "请重点分析当前大限运程。说明：\n"
            prompt += "1. 当前大限所在宫位的星曜组合\n"
            prompt += "2. 大限四化对整体运势的影响\n"
            prompt += "3. 这十年内的吉凶起伏\n"
            prompt += "4. 事业、感情、健康方面的注意事项\n"
        case .yearly:
            prompt += "请分析今年流年运势。说明：\n"
            prompt += "1. 流年命宫所在位置及星曜\n"
            prompt += "2. 流年四化与流耀的影响\n"
            prompt += "3. 今年各方面的吉凶与注意事项\n"
        case .palace:
            if let palaceName = focusPalace {
                prompt += "请详细解读\(palaceName)的星曜组合与含义。说明：\n"
                prompt += "1. 该宫位的主星组合及格局\n"
                prompt += "2. 三方四正的影响\n"
                prompt += "3. 四化飞星对该宫的影响\n"
            } else {
                prompt += "请详细解读命宫的星曜组合与含义。\n"
            }
        }

        // 知识增强
        let knowledge = KnowledgeBase.shared.enhance(chart: chart, scope: scope)
        if !knowledge.isEmpty {
            prompt += "\n【参考知识】\n\(knowledge)\n"
        }

        return prompt
    }
}

enum LLMError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case noAPIKey

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "无效的 API 地址"
        case .invalidResponse: return "API 响应异常"
        case .noAPIKey: return "未设置 API Key"
        }
    }
}
