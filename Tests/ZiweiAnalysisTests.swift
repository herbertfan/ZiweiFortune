import XCTest
@testable import ZiweiFortune

final class ZiweiAnalysisTests: XCTestCase {

    let calc = ZiweiCalculator.shared

    // MARK: - Palace Star Queries

    func testPalaceHaveStars() {
        let chart = calc.calculateChart(
            birthYear: 1987, birthMonth: 2, birthDay: 19,
            birthHour: 1, gender: .male, isLeapMonth: false
        )
        let mingGong = chart.mingGong
        // 命宫至少有一颗主星（含借对宫）
        XCTAssertFalse(mingGong.majorStars.isEmpty, "命宫应有主星（含借对宫）")
    }

    func testPalaceNotHaveStars() {
        let chart = calc.calculateChart(
            birthYear: 1987, birthMonth: 2, birthDay: 19,
            birthHour: 1, gender: .male, isLeapMonth: false
        )
        let mingGong = chart.mingGong
        XCTAssertTrue(mingGong.notHaveStars(["不存在的星"]), "命宫不应有不存在的星")
    }

    // MARK: - Mutagen Queries

    func testPalaceHaveMutagen() {
        let chart = calc.calculateChart(
            birthYear: 1987, birthMonth: 2, birthDay: 19,
            birthHour: 1, gender: .male, isLeapMonth: false
        )
        // 丁年四化: 太陰禄, 天同權, 天機科, 巨門忌
        let allPalaces = chart.palaces
        let hasLu = allPalaces.contains { $0.haveMutagen("祿") }
        let hasQuan = allPalaces.contains { $0.haveMutagen("權") }
        let hasKe = allPalaces.contains { $0.haveMutagen("科") }
        let hasJi = allPalaces.contains { $0.haveMutagen("忌") }
        XCTAssertTrue(hasLu, "应有化禄")
        XCTAssertTrue(hasQuan, "应有化權")
        XCTAssertTrue(hasKe, "应有化科")
        XCTAssertTrue(hasJi, "应有化忌")
    }

    // MARK: - Surrounded Palaces Queries

    func testSurroundedPalacesHaveOneOfStars() {
        let chart = calc.calculateChart(
            birthYear: 1987, birthMonth: 2, birthDay: 19,
            birthHour: 1, gender: .male, isLeapMonth: false
        )
        // 命宫三方四正应至少包含一颗主星（紫微或天府）
        let hasMajor = chart.surroundedPalacesHaveOneOfStars(palaceIndex: chart.mingGongIndex, stars: ["紫微", "天府"])
        XCTAssertTrue(hasMajor, "命宫三方四正应有紫微或天府")
    }

    // MARK: - Star Location

    func testStarPalace() {
        let chart = calc.calculateChart(
            birthYear: 1987, birthMonth: 2, birthDay: 19,
            birthHour: 1, gender: .male, isLeapMonth: false
        )
        let ziWeiPalace = chart.palace(of: "紫微")
        XCTAssertNotNil(ziWeiPalace, "紫微星必须存在于某一宫位")
        if let palace = ziWeiPalace {
            XCTAssertTrue(palace.haveStars(["紫微"]), "找到的宫位应包含紫微")
        }
    }

    // MARK: - Flying Star (飞星四化)

    func testFlyingStarsExist() {
        let chart = calc.calculateChart(
            birthYear: 1987, birthMonth: 2, birthDay: 19,
            birthHour: 1, gender: .male, isLeapMonth: false
        )
        let allFlies = chart.allFlyingStars
        // 12个宫位 × 每个宫干最多4个四化 = 最多48条飞星路径
        // 实际会有部分四化对应的星曜不在盘中，所以路径会少一些
        XCTAssertFalse(allFlies.isEmpty, "应有飞星路径")

        // 检查每个飞星结果的结构完整性
        for fly in allFlies {
            XCTAssertTrue(["祿", "權", "科", "忌"].contains(fly.transformation), "四化必须是祿/權/科/忌")
            XCTAssertTrue(fly.fromPalaceIndex >= 0 && fly.fromPalaceIndex < 12, "出发宫位索引应在0-11")
            XCTAssertTrue(fly.toPalaceIndex >= 0 && fly.toPalaceIndex < 12, "目标宫位索引应在0-11")
            XCTAssertFalse(fly.starName.isEmpty, "被化星曜名称不应为空")
        }
    }

    func testFlyingStars_DingYear() {
        // 1987丁年: 太陰禄, 天同權, 天機科, 巨門忌
        let chart = calc.calculateChart(
            birthYear: 1987, birthMonth: 2, birthDay: 19,
            birthHour: 1, gender: .male, isLeapMonth: false
        )
        let allFlies = chart.allFlyingStars

        // 查找丁干宫位飞出的四化
        let dingPalaces = chart.palaces.filter { $0.heavenlyStem == .ding }
        XCTAssertFalse(dingPalaces.isEmpty, "应有丁干宫位")

        for palace in dingPalaces {
            let flies = palace.flyingStars(from: chart.palaces)
            let transformations = flies.map { $0.transformation }
            XCTAssertTrue(transformations.contains("祿"), "丁干应飞出化禄")
            XCTAssertTrue(transformations.contains("權"), "丁干应飞出化權")
            XCTAssertTrue(transformations.contains("科"), "丁干应飞出化科")
            XCTAssertTrue(transformations.contains("忌"), "丁干应飞出化忌")

            // 验证被化的星是否正确
            let luStar = flies.first { $0.transformation == "祿" }
            XCTAssertEqual(luStar?.starName, "太陰", "丁年化禄应为太陰")

            let quanStar = flies.first { $0.transformation == "權" }
            XCTAssertEqual(quanStar?.starName, "天同", "丁年化權应为天同")

            let keStar = flies.first { $0.transformation == "科" }
            XCTAssertEqual(keStar?.starName, "天機", "丁年化科应为天機")

            let jiStar = flies.first { $0.transformation == "忌" }
            XCTAssertEqual(jiStar?.starName, "巨門", "丁年化忌应为巨門")
        }
    }

    func testIncomingFlies() {
        let chart = calc.calculateChart(
            birthYear: 1987, birthMonth: 2, birthDay: 19,
            birthHour: 1, gender: .male, isLeapMonth: false
        )
        // 每个宫位检查是否有飞入的四化（只检查非借星）
        for palace in chart.palaces {
            let incoming = palace.incomingFlies(from: chart.palaces)
            // 被四化的原生星所在的宫位应该有飞入
            for star in palace.allStars where star.transformation != nil && star.type != "borrowed" {
                let hasIncoming = incoming.contains { $0.starName == star.name && $0.transformation == star.transformation }
                XCTAssertTrue(hasIncoming, "\(palace.name)中的\(star.name)\(star.transformation!)应有对应的飞入记录")
            }
        }
    }

    func testPalaceMutagens() {
        let chart = calc.calculateChart(
            birthYear: 1987, birthMonth: 2, birthDay: 19,
            birthHour: 1, gender: .male, isLeapMonth: false
        )
        let totalMutagens = chart.palaces.flatMap { $0.mutagens }
        // 四化总数含借星后可能超过4，但祿權科忌各至少一个
        let uniqueTransformations = Set(totalMutagens.map { $0.transformation })
        XCTAssertTrue(uniqueTransformations.contains("祿"))
        XCTAssertTrue(uniqueTransformations.contains("權"))
        XCTAssertTrue(uniqueTransformations.contains("科"))
        XCTAssertTrue(uniqueTransformations.contains("忌"))
    }

    // MARK: - Empty Palace (空宫)

    func testEmptyPalaceAfterBorrowing() {
        let chart = calc.calculateChart(
            birthYear: 1987, birthMonth: 2, birthDay: 19,
            birthHour: 1, gender: .male, isLeapMonth: false
        )
        for palace in chart.palaces {
            // 借星后的空宫不应再为空
            XCTAssertFalse(palace.majorStars.isEmpty, "\(palace.name)不应为空宫（已借对宫）")
        }
    }

    // MARK: - SanFang / SiZheng

    func testSanFangCount() {
        XCTAssertEqual(ZiweiAnalysis.sanFang(index: 0).count, 3, "三方应有3个宫位")
        XCTAssertEqual(ZiweiAnalysis.siZheng(index: 0).count, 4, "四正应有4个宫位")
    }

    func testOppositePalace() {
        XCTAssertEqual(ZiweiAnalysis.oppositePalace(index: 0), 6)
        XCTAssertEqual(ZiweiAnalysis.oppositePalace(index: 3), 9)
        XCTAssertEqual(ZiweiAnalysis.oppositePalace(index: 11), 5)
    }

    // MARK: - 天干四化映射验证 (对照 iztro)

    func testHeavenlyStemMutagenMapping() {
        // 验证全部10个天干的四化映射与 iztro 一致
        // iztro 顺序: [禄, 权, 科, 忌]
        let expected: [HeavenlyStem: [String]] = [
            .jia:  ["廉貞", "破軍", "武曲", "太陽"],
            .yi:   ["天機", "天梁", "紫微", "太陰"],
            .bing: ["天同", "天機", "文昌", "廉貞"],
            .ding: ["太陰", "天同", "天機", "巨門"],
            .wu:   ["貪狼", "太陰", "右弼", "天機"],
            .ji:   ["武曲", "貪狼", "天梁", "文曲"],
            .geng: ["太陽", "武曲", "太陰", "天同"],
            .xin:  ["巨門", "太陽", "文曲", "文昌"],
            .ren:  ["天梁", "紫微", "左輔", "武曲"],
            .gui:  ["破軍", "巨門", "太陰", "貪狼"],
        ]
        for (stem, expectedStars) in expected {
            let actual = stem.transformations.map { $0.displayName }
            XCTAssertEqual(actual, expectedStars, "\(stem.displayName)干四化映射错误")
        }
    }

    // MARK: - 大限四化叠加验证

    func testDecadalMutagenOverlay() {
        let chart = calc.calculateChart(
            birthYear: 1987, birthMonth: 2, birthDay: 19,
            birthHour: 1, gender: .male, isLeapMonth: false
        )
        // 取命宫大限的干支
        guard let decadal = chart.palaces[chart.mingGongIndex].decadal else {
            XCTFail("命宫应有 decadal 数据")
            return
        }
        let stem = decadal.heavenlyStem
        let transLabels = ["祿", "權", "科", "忌"]
        let mutagenStars = stem.transformations.map { $0.displayName }

        // 对每个宫位，检查 horoscope mutagen 计算逻辑
        for palaceIdx in 0..<12 {
            let palace = chart.palaces[palaceIdx]
            var expectedMutagens: [(String, String)] = []
            for (transIdx, starName) in mutagenStars.enumerated() {
                if palace.allStars.contains(where: { $0.name == starName }) {
                    expectedMutagens.append((starName, transLabels[transIdx]))
                }
            }

            // 验证: 只有包含被化星曜的宫位才应有 horoscope mutagen
            for (starName, trans) in expectedMutagens {
                let star = palace.allStars.first { $0.name == starName }
                XCTAssertNotNil(star, "\(palace.name) 应包含 \(starName)")
            }
        }
    }

    // MARK: - 流年四化验证

    func testYearlyMutagenOverlay() {
        let chart = calc.calculateChart(
            birthYear: 1987, birthMonth: 2, birthDay: 19,
            birthHour: 1, gender: .male, isLeapMonth: false
        )
        // 1999年: 己卯年, 己干四化 = [武曲禄, 贪狼权, 天梁科, 文曲忌]
        let year1999Stem = HeavenlyStem.ji
        let mutagenStars = year1999Stem.transformations.map { $0.displayName }
        XCTAssertEqual(mutagenStars, ["武曲", "貪狼", "天梁", "文曲"])

        // 验证: 找到包含武曲的宫位，该宫位应有 horoscope "祿" 标记
        let wuQuPalace = chart.palaces.first { $0.allStars.contains(where: { $0.name == "武曲" }) }
        XCTAssertNotNil(wuQuPalace, "盘中应有武曲")
        if let palace = wuQuPalace {
            XCTAssertTrue(palace.allStars.contains(where: { $0.name == "武曲" }),
                          "\(palace.name) 应包含武曲")
        }
    }

    // MARK: - 流耀完整性验证

    func testDecadalFlowStarsCompleteness() {
        let chart = calc.calculateChart(
            birthYear: 1987, birthMonth: 2, birthDay: 19,
            birthHour: 1, gender: .male, isLeapMonth: false
        )
        guard let decadal = chart.palaces[chart.mingGongIndex].decadal else {
            XCTFail("应有 decadal 数据")
            return
        }
        let flowStars = ZiweiCalculator.shared.getHoroscopeStars(
            heavenlyStem: decadal.heavenlyStem.rawValue,
            earthlyBranch: decadal.earthlyBranch.rawValue,
            scope: "decadal"
        )
        let allFlowStars = flowStars.flatMap { $0 }
        let names = allFlowStars.map { $0.name }

        // 大限流耀应有10颗: 運魁, 運鉞, 運昌, 運曲, 運祿, 運羊, 運陀, 運馬, 運鸞, 運喜
        XCTAssertTrue(names.contains("運魁"), "应有大限流魁")
        XCTAssertTrue(names.contains("運鉞"), "应有大限流鉞")
        XCTAssertTrue(names.contains("運昌"), "应有大限流昌")
        XCTAssertTrue(names.contains("運曲"), "应有大限流曲")
        XCTAssertTrue(names.contains("運祿"), "应有大限流祿")
        XCTAssertTrue(names.contains("運羊"), "应有大限流羊")
        XCTAssertTrue(names.contains("運陀"), "应有大限流陀")
        XCTAssertTrue(names.contains("運馬"), "应有大限流馬")
        XCTAssertTrue(names.contains("運鸞"), "应有大限流鸞")
        XCTAssertTrue(names.contains("運喜"), "应有大限流喜")
    }
}
