import Foundation

// MARK: - FlyResult (飞星结果)

struct FlyResult: Equatable, Hashable {
    let fromPalaceIndex: Int
    let fromPalaceName: String
    let transformation: String  // 祿/權/科/忌
    let starName: String        // 被化的星
    let toPalaceIndex: Int
    let toPalaceName: String
}

// MARK: - Pattern (格局)

struct Pattern: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let description: String
    let level: PatternLevel

    enum PatternLevel: String, CaseIterable {
        case supreme = "上格"
        case high = "中上"
        case medium = "中格"
        case special = "特殊"
    }
}

// MARK: - ZiweiAnalysis (分析工具)

enum ZiweiAnalysis {

    /// Get the three-direction (三方) palace indices for a given palace
    static func sanFang(index: Int) -> [Int] {
        [index, fixIndex(index + 4), fixIndex(index - 4)]
    }

    /// Get the four-direction (四正) palace indices (三方 + 對宮)
    static func siZheng(index: Int) -> [Int] {
        [index, fixIndex(index + 4), fixIndex(index - 4), fixIndex(index + 6)]
    }

    /// Get the opposite palace (對宮)
    static func oppositePalace(index: Int) -> Int {
        fixIndex(index + 6)
    }

    // MARK: - Palace Star Queries

    /// 宫位是否包含全部指定星曜
    static func palaceHaveStars(_ palace: ZiweiPalace, stars: [String]) -> Bool {
        let names = palace.allStars.map { $0.name }
        return stars.allSatisfy { names.contains($0) }
    }

    /// 宫位是否包含任一指定星曜
    static func palaceHaveOneOfStars(_ palace: ZiweiPalace, stars: [String]) -> Bool {
        let names = palace.allStars.map { $0.name }
        return stars.contains { names.contains($0) }
    }

    /// 宫位是否不包含全部指定星曜
    static func palaceNotHaveStars(_ palace: ZiweiPalace, stars: [String]) -> Bool {
        let names = palace.allStars.map { $0.name }
        return stars.allSatisfy { !names.contains($0) }
    }

    /// 宫位是否有指定四化
    static func palaceHaveMutagen(_ palace: ZiweiPalace, mutagen: String) -> Bool {
        palace.allStars.contains { $0.transformation == mutagen }
    }

    /// 宫位是否有任一指定四化
    static func palaceHaveOneOfMutagens(_ palace: ZiweiPalace, mutagens: [String]) -> Bool {
        palace.allStars.contains { star in
            guard let t = star.transformation else { return false }
            return mutagens.contains(t)
        }
    }

    // MARK: - Surrounded Palaces (三方四正) Queries

    /// 三方四正是否包含全部指定星曜
    static func surroundedPalacesHaveStars(palaceIndex: Int, stars: [String], palaces: [ZiweiPalace]) -> Bool {
        let all = siZheng(index: palaceIndex).flatMap { palaces[$0].allStars }
        let names = all.map { $0.name }
        return stars.allSatisfy { names.contains($0) }
    }

    /// 三方四正是否包含任一指定星曜
    static func surroundedPalacesHaveOneOfStars(palaceIndex: Int, stars: [String], palaces: [ZiweiPalace]) -> Bool {
        let all = siZheng(index: palaceIndex).flatMap { palaces[$0].allStars }
        let names = Set(all.map { $0.name })
        return stars.contains { names.contains($0) }
    }

    /// 三方四正是否不包含全部指定星曜
    static func surroundedPalacesNotHaveStars(palaceIndex: Int, stars: [String], palaces: [ZiweiPalace]) -> Bool {
        let all = siZheng(index: palaceIndex).flatMap { palaces[$0].allStars }
        let names = Set(all.map { $0.name })
        return stars.allSatisfy { !names.contains($0) }
    }

    /// 三方四正是否有指定四化
    static func surroundedPalacesHaveMutagen(palaceIndex: Int, mutagen: String, palaces: [ZiweiPalace]) -> Bool {
        let all = siZheng(index: palaceIndex).flatMap { palaces[$0].allStars }
        return all.contains { $0.transformation == mutagen }
    }

    /// 三方四正是否没有指定四化
    static func surroundedPalacesNotHaveMutagen(palaceIndex: Int, mutagen: String, palaces: [ZiweiPalace]) -> Bool {
        !surroundedPalacesHaveMutagen(palaceIndex: palaceIndex, mutagen: mutagen, palaces: palaces)
    }

    // MARK: - Star Location Queries

    /// 查找指定星曜所在的宫位索引
    static func starPalaces(starName: String, palaces: [ZiweiPalace]) -> [Int] {
        palaces.filter { $0.allStars.contains { $0.name == starName } }.map { $0.index }
    }

    /// 查找指定星曜所在宫位，优先返回原生星（非借星）
    static func starPalace(starName: String, palaces: [ZiweiPalace]) -> ZiweiPalace? {
        // 先找原生星
        if let original = palaces.first(where: {
            $0.allStars.contains { $0.name == starName && $0.type != "borrowed" }
        }) { return original }
        // 再找借星
        return palaces.first { $0.allStars.contains { $0.name == starName } }
    }

    // MARK: - Flying Star (飞星四化) Analysis

    /// 计算从指定宫位飞出的四化路径
    static func flyingStars(fromPalaceIndex: Int, palaces: [ZiweiPalace]) -> [FlyResult] {
        guard let fromPalace = palaces.first(where: { $0.index == fromPalaceIndex }),
              let heavenlyStem = fromPalace.heavenlyStem else { return [] }

        // 获取该宫干对应的四化映射
        let mutagenMap = getMutagenMap(stem: heavenlyStem)
        var results: [FlyResult] = []

        for (transformation, starName) in mutagenMap {
            // 找到被化的星曜在哪个宫位
            if let targetPalace = starPalace(starName: starName, palaces: palaces) {
                results.append(FlyResult(
                    fromPalaceIndex: fromPalaceIndex,
                    fromPalaceName: fromPalace.name,
                    transformation: transformation,
                    starName: starName,
                    toPalaceIndex: targetPalace.index,
                    toPalaceName: targetPalace.name
                ))
            }
        }
        return results
    }

    /// 计算所有宫位的飞星（本命盘全盘飞星）
    static func allFlyingStars(palaces: [ZiweiPalace]) -> [FlyResult] {
        (0..<12).flatMap { flyingStars(fromPalaceIndex: $0, palaces: palaces) }
    }

    /// 获取指定宫位的四化信息（此宫位内哪些星被化了）
    static func palaceMutagens(_ palace: ZiweiPalace) -> [(star: String, transformation: String)] {
        palace.allStars.compactMap { star in
            guard let t = star.transformation else { return nil }
            return (star: star.name, transformation: t)
        }
    }

    /// 获取哪些宫位的四化飞入此宫位
    static func incomingFlies(toPalaceIndex: Int, palaces: [ZiweiPalace]) -> [FlyResult] {
        allFlyingStars(palaces: palaces).filter { $0.toPalaceIndex == toPalaceIndex }
    }

    // MARK: - Life K-Line Scoring (人生K线评分)

    struct KLinePoint: Identifiable {
        let id = UUID()
        let age: Int
        let score: Double // 0-100
        let palaceName: String
        let majorStars: [String]
        let mutagens: [String]
        let note: String
    }

    /// Calculate fortune score for each age (1-100)
    static func calculateLifeKLine(chart: ZiweiChart) -> [KLinePoint] {
        var points: [KLinePoint] = []
        for age in 1...100 {
            // Find the palace that contains this age
            guard let palace = chart.palaces.first(where: { $0.ages.contains(age) }) else { continue }

            var score: Double = 50 // Base score
            var notes: [String] = []

            // Major stars influence
            for star in palace.majorStars {
                switch star.brightness {
                case .miao: score += 8; notes.append("\(star.name)庙旺")
                case .wang: score += 6; notes.append("\(star.name)旺")
                case .de:  score += 4
                case .li:  score += 2
                case .ping: score += 0
                case .bu:  score -= 3
                case .xian: score -= 5; notes.append("\(star.name)陷")
                }
            }

            // Auspicious minor stars
            let auspicious = ["左輔", "右弼", "天魁", "天鉞", "文昌", "文曲", "祿存", "天馬"]
            let auspiciousCount = palace.minorStars.filter { auspicious.contains($0.name) }.count
            score += Double(auspiciousCount) * 3

            // Malefic minor stars
            let malefic = ["擎羊", "陀羅", "火星", "鈴星", "地空", "地劫"]
            let maleficCount = palace.minorStars.filter { malefic.contains($0.name) }.count
            score -= Double(maleficCount) * 4

            // Mutagen influence
            for star in palace.allStars {
                if let t = star.transformation {
                    switch t {
                    case "祿": score += 5; notes.append("化祿")
                    case "權": score += 4; notes.append("化權")
                    case "科": score += 3; notes.append("化科")
                    case "忌": score -= 6; notes.append("化忌")
                    default: break
                    }
                }
            }

            // Decadal transition bonus/penalty
            if let decadal = palace.decadal {
                if age == decadal.range.0 {
                    score += 3; notes.append("大限起运")
                } else if age == decadal.range.1 {
                    score -= 2; notes.append("大限将终")
                }
            }

            // Clamp score
            score = max(0, min(100, score))

            points.append(KLinePoint(
                age: age,
                score: score,
                palaceName: palace.name,
                majorStars: palace.majorStars.map { $0.name },
                mutagens: palace.allStars.compactMap { $0.transformation },
                note: notes.joined(separator: "、")
            ))
        }
        return points
    }

    // MARK: - Pattern Detection (格局判断)

    static func detectPatterns(chart: ZiweiChart) -> [Pattern] {
        var patterns: [Pattern] = []
        let palaces = chart.palaces
        let mingGong = chart.mingGong
        let mingStars = mingGong.majorStars.map { $0.name }
        let mingAll = mingGong.allStars.map { $0.name }
        let mingSanFang = mingGong.sanFangStars(from: palaces).map { $0.name }
        let mingSiZheng = mingGong.siZhengStars(from: palaces).map { $0.name }

        // 1. 紫府同宫
        if mingStars.contains("紫微") && mingStars.contains("天府") {
            patterns.append(Pattern(name: "紫府同宫", description: "紫微天府同坐命宫，主富贵双全，性格稳重有领导力。", level: .supreme))
        }

        // 2. 紫府朝垣
        if mingSanFang.contains("紫微") && mingSanFang.contains("天府") {
            patterns.append(Pattern(name: "紫府朝垣", description: "紫微天府在三方四正会照命宫，主贵气非凡，得人助。", level: .supreme))
        }

        // 3. 日月并明
        if mingStars.contains("太陽") && mingStars.contains("太陰") {
            patterns.append(Pattern(name: "日月并明", description: "太阳太阴同宫，主阴阳调和，光明磊落，事业有成。", level: .supreme))
        }
        if mingSiZheng.contains("太陽") && mingSiZheng.contains("太陰") {
            patterns.append(Pattern(name: "日月照命", description: "太阳太阴在三方四正会照，主名声显达。", level: .high))
        }

        // 4. 七杀朝斗/仰斗
        if mingStars.contains("七殺") {
            if [0, 4, 8].contains(mingGong.index) { // 寅申巳亥
                patterns.append(Pattern(name: "七殺朝斗", description: "七杀坐命于四生之地，主开创力强，宜武职创业。", level: .high))
            } else if [2, 6, 10].contains(mingGong.index) { // 子午卯酉
                patterns.append(Pattern(name: "七殺仰斗", description: "七杀坐命于四正之地，主威权显赫，但需防孤克。", level: .high))
            }
        }

        // 5. 机月同梁
        let jiYueTongLiang = ["天機", "太陰", "天同", "天梁"]
        if jiYueTongLiang.allSatisfy({ mingAll.contains($0) || mingSiZheng.contains($0) }) {
            patterns.append(Pattern(name: "機月同梁", description: "天机太阴天同天梁会照，主宜文职幕僚，善策划协调。", level: .medium))
        }

        // 6. 贪狼守命
        if mingStars.contains("貪狼") {
            patterns.append(Pattern(name: "貪狼守命", description: "贪狼坐命，主多才多艺，交际广阔，欲望强烈。", level: .medium))
        }

        // 7. 巨日同宫
        if mingStars.contains("巨門") && mingStars.contains("太陽") {
            patterns.append(Pattern(name: "巨日同宮", description: "巨门太阳同宫，主口才出众，宜文教传播，防是非。", level: .medium))
        }

        // 8. 武贪同行
        if mingStars.contains("武曲") && mingStars.contains("貪狼") {
            patterns.append(Pattern(name: "武貪同行", description: "武曲贪狼同宫，主财权双美，宜经商创业，晚发。", level: .high))
        }

        // 9. 廉贞七杀
        if mingStars.contains("廉貞") && mingStars.contains("七殺") {
            patterns.append(Pattern(name: "廉貞七殺", description: "廉贞七杀同宫，主积富之人，宜经商，但性格刚烈。", level: .medium))
        }

        // 10. 火贪/铃贪
        if mingStars.contains("貪狼") && (mingAll.contains("火星") || mingAll.contains("鈴星")) {
            patterns.append(Pattern(name: "火貪/鈴貪", description: "贪狼遇火铃，主突发之财，横发暴富，但起伏大。", level: .special))
        }

        // 11. 空宫借星
        if mingGong.majorStars.allSatisfy({ $0.type == "borrowed" }) {
            patterns.append(Pattern(name: "空宮借星", description: "命宫无主星，借对宫星曜，命格受对宫影响较大。", level: .special))
        }

        // 12. 辅弼夹命
        let leftIdx = fixIndex(mingGong.index - 1)
        let rightIdx = fixIndex(mingGong.index + 1)
        let leftStarNames = palaces[leftIdx].allStars.map { $0.name }
        let rightStarNames = palaces[rightIdx].allStars.map { $0.name }
        let leftAllStars = palaces[leftIdx].allStars
        let rightAllStars = palaces[rightIdx].allStars
        if leftStarNames.contains("左輔") && rightStarNames.contains("右弼") {
            patterns.append(Pattern(name: "輔弼夾命", description: "左辅右弼夹命宫，主左右逢源，得力助手多。", level: .high))
        }

        // 13. 昌曲夹命
        if leftStarNames.contains("文昌") && rightStarNames.contains("文曲") {
            patterns.append(Pattern(name: "昌曲夾命", description: "文昌文曲夹命宫，主聪明才智，学业功名佳。", level: .high))
        }

        // 14. 权禄夹命
        if leftAllStars.contains(where: { $0.transformation == "祿" }) && rightAllStars.contains(where: { $0.transformation == "權" }) {
            patterns.append(Pattern(name: "權祿夾命", description: "化禄化权夹命宫，主富贵双全，事业有成。", level: .supreme))
        }

        // 15. 君臣庆会
        if mingStars.contains("紫微") && mingSiZheng.contains("天府") || (mingStars.contains("天府") && mingSiZheng.contains("紫微")) {
            patterns.append(Pattern(name: "君臣慶會", description: "紫微天府在三方四正相会，主君臣和睦，事业昌隆。", level: .supreme))
        }

        // 16. 日月反背
        if mingStars.contains("太陽") && [5, 11].contains(mingGong.index) { // 太阳在巳亥为落陷
            patterns.append(Pattern(name: "日月反背", description: "太阳落陷坐命，主辛劳奔波，需靠后天努力。", level: .special))
        }

        // 17. 马头带箭
        if mingStars.contains("天馬") && mingStars.contains("七殺") {
            patterns.append(Pattern(name: "馬頭帶箭", description: "天马七杀同宫，主奔波开创，宜外地发展。", level: .medium))
        }

        // 18. 禄存守命
        if mingStars.contains("祿存") {
            patterns.append(Pattern(name: "祿存守命", description: "禄存坐命，主财运亨通，一生不缺钱财。", level: .high))
        }

        return patterns
    }

    // MARK: - Helpers

    /// 天干四化映射（中州派）
    private static func getMutagenMap(stem: HeavenlyStem) -> [(String, String)] {
        switch stem {
        case .jia: return [("祿", "廉貞"), ("權", "破軍"), ("科", "武曲"), ("忌", "太陽")]
        case .yi:  return [("祿", "天機"), ("權", "天梁"), ("科", "紫微"), ("忌", "太陰")]
        case .bing: return [("祿", "天同"), ("權", "天機"), ("科", "文昌"), ("忌", "廉貞")]
        case .ding: return [("祿", "太陰"), ("權", "天同"), ("科", "天機"), ("忌", "巨門")]
        case .wu:   return [("祿", "貪狼"), ("權", "太陰"), ("科", "右弼"), ("忌", "天機")]
        case .ji:   return [("祿", "武曲"), ("權", "貪狼"), ("科", "天梁"), ("忌", "文曲")]
        case .geng: return [("祿", "太陽"), ("權", "武曲"), ("科", "太陰"), ("忌", "天同")]
        case .xin:  return [("祿", "巨門"), ("權", "太陽"), ("科", "文曲"), ("忌", "文昌")]
        case .ren:  return [("祿", "天梁"), ("權", "紫微"), ("科", "左輔"), ("忌", "武曲")]
        case .gui:  return [("祿", "破軍"), ("權", "巨門"), ("科", "太陰"), ("忌", "貪狼")]
        }
    }

    private static func fixIndex(_ index: Int, max: Int = 12) -> Int {
        var idx = index
        while idx < 0 { idx += max }
        while idx >= max { idx -= max }
        return idx
    }
}

// MARK: - Palace Convenience Extensions

extension ZiweiPalace {
    /// Whether the palace has no major stars (空宮)
    var isEmpty: Bool {
        majorStars.isEmpty
    }

    /// All placed stars (major + minor + adjective)
    var allStars: [PlacedStar] {
        majorStars + minorStars + adjectiveStars
    }

    /// Stars in 三方 palaces including this palace
    func sanFangStars(from palaces: [ZiweiPalace]) -> [PlacedStar] {
        ZiweiAnalysis.sanFang(index: index).flatMap { palaces[$0].allStars }
    }

    /// Stars in 四正 palaces including this palace
    func siZhengStars(from palaces: [ZiweiPalace]) -> [PlacedStar] {
        ZiweiAnalysis.siZheng(index: index).flatMap { palaces[$0].allStars }
    }

    /// 此宫位是否包含全部指定星曜
    func haveStars(_ stars: [String]) -> Bool {
        ZiweiAnalysis.palaceHaveStars(self, stars: stars)
    }

    /// 此宫位是否包含任一指定星曜
    func haveOneOfStars(_ stars: [String]) -> Bool {
        ZiweiAnalysis.palaceHaveOneOfStars(self, stars: stars)
    }

    /// 此宫位是否不包含全部指定星曜
    func notHaveStars(_ stars: [String]) -> Bool {
        ZiweiAnalysis.palaceNotHaveStars(self, stars: stars)
    }

    /// 此宫位是否有指定四化
    func haveMutagen(_ mutagen: String) -> Bool {
        ZiweiAnalysis.palaceHaveMutagen(self, mutagen: mutagen)
    }

    /// 此宫位的四化信息
    var mutagens: [(star: String, transformation: String)] {
        ZiweiAnalysis.palaceMutagens(self)
    }

    /// 此宫位的飞星（从此宫位飞出的四化路径）
    func flyingStars(from palaces: [ZiweiPalace]) -> [FlyResult] {
        ZiweiAnalysis.flyingStars(fromPalaceIndex: index, palaces: palaces)
    }

    /// 哪些飞星飞入此宫位
    func incomingFlies(from palaces: [ZiweiPalace]) -> [FlyResult] {
        ZiweiAnalysis.incomingFlies(toPalaceIndex: index, palaces: palaces)
    }
}

// MARK: - ZiweiChart Convenience Extensions

extension ZiweiChart {
    /// 查找指定星曜所在的宫位
    func palace(of starName: String) -> ZiweiPalace? {
        ZiweiAnalysis.starPalace(starName: starName, palaces: palaces)
    }

    /// 指定宫位的三方四正是否包含全部星曜
    func surroundedPalacesHaveStars(palaceIndex: Int, stars: [String]) -> Bool {
        ZiweiAnalysis.surroundedPalacesHaveStars(palaceIndex: palaceIndex, stars: stars, palaces: palaces)
    }

    /// 指定宫位的三方四正是否包含任一星曜
    func surroundedPalacesHaveOneOfStars(palaceIndex: Int, stars: [String]) -> Bool {
        ZiweiAnalysis.surroundedPalacesHaveOneOfStars(palaceIndex: palaceIndex, stars: stars, palaces: palaces)
    }

    /// 指定宫位的三方四正是否有指定四化
    func surroundedPalacesHaveMutagen(palaceIndex: Int, mutagen: String) -> Bool {
        ZiweiAnalysis.surroundedPalacesHaveMutagen(palaceIndex: palaceIndex, mutagen: mutagen, palaces: palaces)
    }

    /// 全盘飞星
    var allFlyingStars: [FlyResult] {
        ZiweiAnalysis.allFlyingStars(palaces: palaces)
    }

    /// 命盘格局
    var patterns: [Pattern] {
        ZiweiAnalysis.detectPatterns(chart: self)
    }
}
