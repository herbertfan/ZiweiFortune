import XCTest
@testable import ZiweiFortune

final class ZiweiCalculatorTests: XCTestCase {

    let calc = ZiweiCalculator.shared

    // MARK: - 四柱验证

    func testFourPillars_1987_02_19_chou() {
        let result = calc.calculateChart(
            birthYear: 1987, birthMonth: 2, birthDay: 19,
            birthHour: 1, gender: .male, isLeapMonth: false
        )
        let fp = result.fourPillars
        XCTAssertEqual(fp.year.displayName, "丁卯", "年柱应为丁卯")
        XCTAssertEqual(fp.month.displayName, "壬寅", "月柱应为壬寅")
        XCTAssertEqual(fp.day.displayName, "己亥", "日柱应为己亥")
        XCTAssertEqual(fp.hour.displayName, "乙丑", "时柱应为乙丑")
    }

    func testFourPillars_1990_08_15_zi() {
        let result = calc.calculateChart(
            birthYear: 1990, birthMonth: 8, birthDay: 15,
            birthHour: 23, gender: .female, isLeapMonth: false
        )
        let fp = result.fourPillars
        XCTAssertEqual(fp.year.displayName, "庚午")
        XCTAssertEqual(fp.month.displayName, "癸未")
        XCTAssertEqual(fp.day.displayName, "壬子")
        XCTAssertEqual(fp.hour.displayName, "辛亥")
    }

    // MARK: - 命宫/身宫位置验证

    func testMingGongIndex_1987_02_19_chou() {
        let result = calc.calculateChart(
            birthYear: 1987, birthMonth: 2, birthDay: 19,
            birthHour: 1, gender: .male, isLeapMonth: false
        )
        XCTAssertTrue(result.mingGongIndex >= 0 && result.mingGongIndex < 12, "命宫索引应在 0-11 范围内")
    }

    // MARK: - 五行局验证

    func testWuXingJu_1987_02_19() {
        let result = calc.calculateChart(
            birthYear: 1987, birthMonth: 2, birthDay: 19,
            birthHour: 1, gender: .male, isLeapMonth: false
        )
        XCTAssertTrue([WuXingJu.shuiEr, .muSan, .jinSi, .tuWu, .huoLiu].contains(result.wuXingJu), "五行局应为有效值")
    }

    // MARK: - 空宫借对宫验证

    func testEmptyPalaceBorrowing() {
        let result = calc.calculateChart(
            birthYear: 1987, birthMonth: 2, birthDay: 19,
            birthHour: 1, gender: .male, isLeapMonth: false
        )
        for palace in result.palaces {
            if palace.isEmpty {
                let opposite = result.palaces[ZiweiAnalysis.oppositePalace(index: palace.index)]
                XCTAssertFalse(opposite.majorStars.isEmpty, "对宫必须至少有一颗主星")
                let borrowed = palace.majorStars
                XCTAssertFalse(borrowed.isEmpty, "空宫 \(palace.name) 应借对宫 \(opposite.name) 主星")
            }
        }
    }

    // MARK: - 大限验证

    func testDecadal_1987_02_19() {
        let result = calc.calculateChart(
            birthYear: 1987, birthMonth: 2, birthDay: 19,
            birthHour: 1, gender: .male, isLeapMonth: false
        )
        let decadalPalaces = result.palaces.compactMap { $0.decadal }
        XCTAssertFalse(decadalPalaces.isEmpty, "必须有至少一个大限宫位")
    }

    // MARK: - 小限验证

    func testAges_1987_02_19() {
        let result = calc.calculateChart(
            birthYear: 1987, birthMonth: 2, birthDay: 19,
            birthHour: 1, gender: .male, isLeapMonth: false
        )
        let allAges = result.palaces.flatMap { $0.ages }
        for age in 1...100 {
            XCTAssertTrue(allAges.contains(age), "年龄 \(age) 应存在于某宫位")
        }
    }

    // MARK: - 四化验证

    func testMutagen_1987_02_19() {
        let result = calc.calculateChart(
            birthYear: 1987, birthMonth: 2, birthDay: 19,
            birthHour: 1, gender: .male, isLeapMonth: false
        )
        let allStars = result.palaces.flatMap { $0.allStars }
        let taiYin = allStars.first { $0.name == "太陰" }
        let tianJi = allStars.first { $0.name == "天機" }
        let tianTong = allStars.first { $0.name == "天同" }
        let juMen = allStars.first { $0.name == "巨門" }

        XCTAssertEqual(taiYin?.transformation, "祿", "太陰应化禄")
        XCTAssertEqual(tianJi?.transformation, "科", "天機应化科")
        XCTAssertEqual(tianTong?.transformation, "權", "天同应化權")
        XCTAssertEqual(juMen?.transformation, "忌", "巨門应化忌")
    }

    // MARK: - 流耀验证

    func testYearlyFlowStars() {
        let stars = ZiweiCalculator.shared.getHoroscopeStars(
            heavenlyStem: 4, earthlyBranch: 3, scope: "yearly"
        )
        XCTAssertEqual(stars.count, 12, "应有12宫流耀")
        let allFlowStars = stars.flatMap { $0 }
        let names = allFlowStars.map { $0.name }
        XCTAssertTrue(names.contains("流魁"))
        XCTAssertTrue(names.contains("流鉞"))
        XCTAssertTrue(names.contains("流昌"))
        XCTAssertTrue(names.contains("流曲"))
        XCTAssertTrue(names.contains("流祿"))
        XCTAssertTrue(names.contains("流羊"))
        XCTAssertTrue(names.contains("流陀"))
        XCTAssertTrue(names.contains("流馬"))
        XCTAssertTrue(names.contains("流鸞"))
        XCTAssertTrue(names.contains("流喜"))
    }

    // MARK: - 来因宫验证

    func testLaiYinPalace() {
        let result = calc.calculateChart(
            birthYear: 1987, birthMonth: 2, birthDay: 19,
            birthHour: 1, gender: .male, isLeapMonth: false
        )
        let laiYinPalaces = result.palaces.filter { $0.isOriginalPalace }
        XCTAssertFalse(laiYinPalaces.isEmpty, "应存在至少一个来因宫")
    }

    // MARK: - 星曜亮度验证

    func testStarBrightnessFilled() {
        let result = calc.calculateChart(
            birthYear: 1987, birthMonth: 2, birthDay: 19,
            birthHour: 1, gender: .male, isLeapMonth: false
        )
        for palace in result.palaces {
            for star in palace.majorStars {
                XCTAssertNotEqual(star.brightness, .ping, "主星 \(star.name) 亮度不应仅为默认值")
            }
        }
    }

    // MARK: - 大限四化动态变化验证

    func testDecadalMutagenChangesWithSelection() {
        let result = calc.calculateChart(
            birthYear: 1987, birthMonth: 2, birthDay: 19,
            birthHour: 1, gender: .male, isLeapMonth: false
        )
        let decadalPalaces = result.palaces.enumerated()
            .compactMap { i, p in p.decadal.map { (i, $0) } }
            .sorted { $0.decadal.startAge < $1.decadal.startAge }

        XCTAssertGreaterThan(decadalPalaces.count, 1, "应有多于一个大限")

        // 验证不同大限的四化不同（至少某些大限不同）
        var uniqueMutagenSets = Set<String>()
        for (_, decadal) in decadalPalaces {
            let mutagenKey = decadal.heavenlyStem.transformations.map { $0.displayName }.joined(separator: ",")
            uniqueMutagenSets.insert(mutagenKey)
        }
        XCTAssertGreaterThan(uniqueMutagenSets.count, 1, "不同大限应有不同四化")
    }

    // MARK: - 宫位名称旋转验证

    func testRotatePalaceNames() {
        let names = ZiweiCalculator.shared.rotatePalaceNames(fromIndex: 0)
        XCTAssertEqual(names[0], "命宮", "命宫索引应为命宫")
        XCTAssertEqual(names[1], "父母宮", "顺行第二应为父母宫")
        XCTAssertEqual(names[6], "遷移宮", "顺行第七应为迁移宫")

        let names2 = ZiweiCalculator.shared.rotatePalaceNames(fromIndex: 3)
        XCTAssertEqual(names2[3], "命宮", "从索引3旋转后，索引3应为命宫")
    }

    // MARK: - 運限資料驗證

    func testHoroscopeData_Yearly() {
        let result = calc.calculateChart(
            birthYear: 1987, birthMonth: 2, birthDay: 19,
            birthHour: 1, gender: .male, isLeapMonth: false
        )
        XCTAssertNotNil(result.horoscope.yearly, "應有流年資料")
        if let yearly = result.horoscope.yearly {
            XCTAssertGreaterThan(yearly.heavenlyStem.rawValue, -1, "流年天干應有效")
            XCTAssertGreaterThan(yearly.earthlyBranch.rawValue, -1, "流年地支應有效")
            XCTAssertEqual(yearly.palaceNames.count, 12, "流年應有12宮名稱")
        }
    }

    func testHoroscopeData_Monthly() {
        let result = calc.calculateChart(
            birthYear: 1987, birthMonth: 2, birthDay: 19,
            birthHour: 1, gender: .male, isLeapMonth: false
        )
        XCTAssertNotNil(result.horoscope.monthly, "應有流月資料")
        if let monthly = result.horoscope.monthly {
            XCTAssertEqual(monthly.palaceNames.count, 12, "流月應有12宮名稱")
            XCTAssertGreaterThan(monthly.mutagen.count, 0, "流月應有四化")
        }
    }

    func testHoroscopeData_Daily() {
        let result = calc.calculateChart(
            birthYear: 1987, birthMonth: 2, birthDay: 19,
            birthHour: 1, gender: .male, isLeapMonth: false
        )
        XCTAssertNotNil(result.horoscope.daily, "應有流日資料")
        if let daily = result.horoscope.daily {
            XCTAssertEqual(daily.palaceNames.count, 12, "流日應有12宮名稱")
        }
    }

    func testHoroscopeData_Hourly() {
        let result = calc.calculateChart(
            birthYear: 1987, birthMonth: 2, birthDay: 19,
            birthHour: 1, gender: .male, isLeapMonth: false
        )
        XCTAssertNotNil(result.horoscope.hourly, "應有流時資料")
        if let hourly = result.horoscope.hourly {
            XCTAssertEqual(hourly.palaceNames.count, 12, "流時應有12宮名稱")
        }
    }

    func testYearlyPalaceLabels() {
        let chart = calc.calculateChart(
            birthYear: 1987, birthMonth: 2, birthDay: 19,
            birthHour: 1, gender: .male, isLeapMonth: false
        )
        guard let yearly = chart.horoscope.yearly else {
            XCTFail("應有流年資料")
            return
        }
        let mingIndex = yearly.index
        let labels = ["年命", "年兄", "年夫", "年子", "年财", "年疾", "年迁", "年友", "年官", "年田", "年福", "年父"]
        for i in 0..<12 {
            let palaceIndex = (mingIndex + i) % 12
            let expectedLabel = labels[i]
            XCTAssertEqual(chart.palaces[palaceIndex].name, yearly.palaceNames[palaceIndex], "宮位名稱應一致")
        }
    }

    func testDecadalPeriodHasValidRange() {
        let chart = calc.calculateChart(
            birthYear: 1987, birthMonth: 2, birthDay: 19,
            birthHour: 1, gender: .male, isLeapMonth: false
        )
        let decadalPalaces = chart.palaces.compactMap { $0.decadal }
        XCTAssertFalse(decadalPalaces.isEmpty, "應有大限資料")
        for decadal in decadalPalaces {
            XCTAssertLessThan(decadal.range.0, decadal.range.1, "大限起始歲數應小於結束歲數")
            XCTAssertGreaterThanOrEqual(decadal.range.0, 0, "大限起始歲數應大於等於0")
        }
    }
}
