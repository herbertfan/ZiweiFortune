import Foundation

final class KnowledgeBase {
    static let shared = KnowledgeBase()
    private init() {}

    func enhance(chart: ZiweiChart, scope: InterpretationScope) -> String {
        var parts: [String] = []

        // 命宫主星
        let mingGong = chart.mingGong
        let majorStarNames = mingGong.majorStars.map { $0.name }
        for name in majorStarNames {
            if let desc = majorStarDescriptions[name] {
                parts.append("\(name)：\(desc)")
            }
        }

        // 命宫格局提示
        if let pattern = detectPattern(palace: mingGong) {
            parts.append("格局提示：\(pattern)")
        }

        return parts.joined(separator: "\n")
    }

    // MARK: - Major Star Descriptions

    private let majorStarDescriptions: [String: String] = [
        "紫微": "帝王之星，主尊贵、领导力。坐命则格局较高，有统御能力，但需辅星扶持。",
        "天機": "智慧之星，主谋略、变动。坐命聪明机敏，善策划，但易多虑。",
        "太陽": "光明之星，主声名、热力。坐命热情开朗，重名誉，但易辛劳。",
        "武曲": "財帛之星，主果断、財富。坐命坚毅果决，善理财，但性情刚直。",
        "天同": "福星，主享乐、温和。坐命性格随和，有福分，但易懒散。",
        "廉貞": "次桃花，主欲望、才艺。坐命重感情，有才艺，但情绪起伏大。",
        "天府": "南斗主星，主稳重、守成。坐命宽厚保守，善守财，但缺乏开创力。",
        "太陰": "母性之星，主温柔、財富。坐命细腻敏感，善理财，但易情绪化。",
        "貪狼": "桃花之星，主欲望、才艺。坐命多才多艺，交际广，但欲望强。",
        "巨門": "暗曜，主口才、是非。坐命口才好，善分析，但易招是非。",
        "天相": "印星，主正直、服务。坐命稳重公正，善协调，但依赖性强。",
        "天梁": "蔭星，主化解、长寿。坐命成熟稳重，善助人，但易老气横秋。",
        "七殺": "将星，主开创、冲动。坐命果敢有魄力，善开创，但性情急躁。",
        "破軍": "先锋之星，主开创、破坏。坐命勇于创新，不畏变革，但稳定性差。"
    ]

    // MARK: - Simple Pattern Detection

    private func detectPattern(palace: ZiweiPalace) -> String? {
        let stars = palace.majorStars.map { $0.name }
        let allNames = palace.allStars.map { $0.name }

        // 紫府同宫
        if stars.contains("紫微") && stars.contains("天府") {
            return "紫府同宫格：主富贵双全，但需防性格保守、缺乏开创。"
        }
        // 日月并明
        if stars.contains("太陽") && stars.contains("太陰") {
            return "日月并明：主光明磊落，阴阳调和，事业顺利。"
        }
        // 七杀朝斗
        if stars.contains("七殺") {
            let sanFang = ZiweiAnalysis.sanFang(index: palace.index)
            // simplified check
            return "七杀坐命：主开创力强，宜武职、创业，需防急躁。"
        }
        // 机月同梁
        if stars.contains("天機") && stars.contains("太陰") && stars.contains("天同") && stars.contains("天梁") {
            return "机月同梁格：主文职、幕僚，宜公职、策划。"
        }
        // 贪狼守命
        if stars.contains("貪狼") {
            return "贪狼守命：主多才多艺，交际广阔，需防欲望过强。"
        }
        // 空宫借星
        if palace.majorStars.isEmpty || palace.majorStars.allSatisfy({ $0.type == "borrowed" }) {
            return "空宫借对宫：命格受对宫影响较大，需结合对宫主星一起看。"
        }

        return nil
    }
}
