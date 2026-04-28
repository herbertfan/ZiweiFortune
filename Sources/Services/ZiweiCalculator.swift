import Foundation

// MARK: - ZiweiCalculator (中州派 Algorithm - Based on iztro)

final class ZiweiCalculator {
    static let shared = ZiweiCalculator()
    private init() {}

    // MARK: - Constants from iztro

    private let HEAVENLY_STEMS = ["jia", "yi", "bing", "ding", "wu", "ji", "geng", "xin", "ren", "gui"]
    private let EARTHLY_BRANCHES = ["zi", "chou", "yin", "mao", "chen", "si", "wu", "wei", "shen", "you", "xu", "hai"]

    // 五虎遁 - Tiger Rule for month stem
    private let TIGER_RULE: [String: String] = [
        "jia": "bing", "yi": "wu", "bing": "geng", "ding": "ren", "wu": "jia",
        "ji": "bing", "geng": "wu", "xin": "geng", "ren": "ren", "gui": "jia"
    ]

    // 五鼠遁 - Rat Rule for hour stem
    private let RAT_RULE: [String: String] = [
        "jia": "jia", "yi": "bing", "bing": "wu", "ding": "geng", "wu": "ren",
        "ji": "jia", "geng": "bing", "xin": "wu", "ren": "geng", "gui": "ren"
    ]

    // 命主 lookup (by 命宮地支)
    private let SOUL_STAR_MAP: [String: String] = [
        "zi": "貪狼", "chou": "巨門", "yin": "祿存", "mao": "文曲",
        "chen": "廉貞", "si": "武曲", "wu": "破軍", "wei": "武曲",
        "shen": "廉貞", "you": "文曲", "xu": "祿存", "hai": "巨門"
    ]

    // 身主 lookup (by 年支)
    private let BODY_STAR_MAP: [String: String] = [
        "zi": "火星", "chou": "天相", "yin": "天梁", "mao": "天同",
        "chen": "文昌", "si": "天機", "wu": "火星", "wei": "天相",
        "shen": "天梁", "you": "天同", "xu": "文昌", "hai": "天機"
    ]

    // MARK: - fixIndex - circular index wrapping (0 ~ max-1)

    private func fixIndex(_ index: Int, max: Int = 12) -> Int {
        var idx = index
        while idx < 0 { idx += max }
        while idx >= max { idx -= max }
        return idx
    }

    // MARK: - Main entry: Generate Ziwei Chart

    func calculateChart(
        birthYear: Int,
        birthMonth: Int,
        birthDay: Int,
        birthHour: Int,
        gender: Gender,
        isLeapMonth: Bool = false
    ) -> ZiweiChart {
        // Get lunar date
        let lunar = lunarFromSolar(year: birthYear, month: birthMonth, day: birthDay)
        let lunarMonth = lunar.month
        let lunarDay = lunar.day

        // Time index (0-12)
        let timeIndex = timeToIndex(hour: birthHour)

        // Calculate 4 pillars (using lunar month for month pillar)
        let fourPillars = calculateFourPillars(
            solarYear: birthYear, solarMonth: birthMonth, solarDay: birthDay,
            hour: birthHour, lunarMonth: lunarMonth
        )

        // Get 命宫 and 身宫
        let soulAndBody = getSoulAndBody(
            lunarMonth: lunarMonth,
            timeIndex: timeIndex, yearlyStem: fourPillars.year.heavenlyStem.rawValue
        )

        let mingGongIndex = soulAndBody.soulIndex
        let shenGongIndex = soulAndBody.bodyIndex

        // Get 五行局
        let wuXingJu = getFiveElementsClass(
            heavenlyStem: soulAndBody.heavenlyStemOfSoul,
            earthlyBranch: soulAndBody.earthlyBranchOfSoul
        )

        // Arrange 12 palaces
        var palaces = arrangePalaces(mingGongIndex: mingGongIndex, shenGongIndex: shenGongIndex, yearlyStem: fourPillars.year.heavenlyStem.rawValue)

        // Place 紫微 and 天府
        let startIndex = getStartIndex(
            lunarDay: lunarDay, timeIndex: timeIndex,
            wuXingJu: wuXingJu
        )

        // Place major stars
        palaces = placeMajorStars(palaces: palaces, ziweiIndex: startIndex.ziweiIndex, tianfuIndex: startIndex.tianfuIndex)

        // Place minor stars (六吉、六煞)
        palaces = placeMinorStars(
            palaces: palaces,
            yearlyStem: fourPillars.year.heavenlyStem.rawValue,
            yearlyBranch: fourPillars.year.earthlyBranch.rawValue,
            timeIndex: timeIndex,
            lunarMonth: lunarMonth
        )

        // Place adjective stars (杂耀)
        palaces = placeAdjectiveStars(
            palaces: palaces,
            solarDate: "\(birthYear)-\(birthMonth)-\(birthDay)",
            timeIndex: timeIndex,
            yearlyStem: fourPillars.year.heavenlyStem.rawValue,
            yearlyBranch: fourPillars.year.earthlyBranch.rawValue,
            dayStem: fourPillars.day.heavenlyStem.rawValue,
            mingGongIndex: mingGongIndex,
            gender: gender,
            fixLeap: true
        )

        // Place transformations (四化星)
        palaces = placeTransformations(
            palaces: palaces,
            yearlyStem: fourPillars.year.heavenlyStem.rawValue
        )

        // Place 长生十二星
        palaces = placeChangSheng12(palaces: palaces, wuXingJu: wuXingJu, yearlyStem: fourPillars.year.heavenlyStem.rawValue, gender: gender)

        // Place 博士十二神
        palaces = placeBoShi12(palaces: palaces, yearlyStem: fourPillars.year.heavenlyStem.rawValue, gender: gender)

        // 小限年齡
        palaces = calculateAges(palaces: palaces, yearlyBranch: fourPillars.year.earthlyBranch.rawValue, gender: gender)

        // 大限年齡範圍
        palaces = assignDecadalRanges(palaces: palaces, mingGongIndex: mingGongIndex, wuXingJu: wuXingJu, yearlyStem: fourPillars.year.heavenlyStem.rawValue, gender: gender)

        // 命主/身主
        let mingBranchKey = EARTHLY_BRANCHES[palaces[mingGongIndex].earthlyBranch?.rawValue ?? 0]
        let yearBranchKey = EARTHLY_BRANCHES[fourPillars.year.earthlyBranch.rawValue]
        let soulStar = SOUL_STAR_MAP[mingBranchKey] ?? ""
        let bodyStar = BODY_STAR_MAP[yearBranchKey] ?? ""

        return ZiweiChart(
            solarDate: "\(birthYear)-\(birthMonth)-\(birthDay)",
            lunarDate: formatLunarDate(year: lunar.year, month: lunar.month, day: lunar.day, isLeap: lunar.isLeap),
            fourPillars: fourPillars,
            wuXingJu: wuXingJu,
            mingGongIndex: mingGongIndex,
            shenGongIndex: shenGongIndex,
            palaces: palaces,
            horoscope: calculateHoroscope(
                palaces: palaces,
                mingGongIndex: mingGongIndex,
                yearlyStem: fourPillars.year.heavenlyStem.rawValue,
                birthYear: birthYear,
                gender: gender
            ),
            gender: gender,
            birthHour: birthHour,
            soul: soulStar,
            body: bodyStar,
            lunarMonth: lunar.month,
            lunarDay: lunar.day,
            createdAt: Date()
        )
    }

    // MARK: - Time Index Conversion

    private func timeToIndex(hour: Int) -> Int {
        // hour is earthly branch index (0=子 ~ 11=亥) from BirthTime.rawValue
        return hour % 12
    }

    // MARK: - Four Pillars (四柱)

    /// 檢查是否在立春（約2月4日）之前，若在立春前則年柱應使用前一年
    private func isBeforeLiChun(month: Int, day: Int) -> Bool {
        if month < 2 { return true }
        if month == 2 && day < 4 { return true }
        return false
    }

    private func calculateFourPillars(solarYear: Int, solarMonth: Int, solarDay: Int, hour: Int, lunarMonth: Int) -> FourPillars {
        // 立春前年柱屬於前一年
        let effectiveYear = isBeforeLiChun(month: solarMonth, day: solarDay) ? solarYear - 1 : solarYear
        let yearStemIndex = (effectiveYear - 4) % 10
        let yearBranchIndex = (effectiveYear - 4) % 12
        let yearStem = HeavenlyStem(rawValue: yearStemIndex >= 0 ? yearStemIndex : yearStemIndex + 10)!
        let yearBranch = EarthlyBranch(rawValue: yearBranchIndex >= 0 ? yearBranchIndex : yearBranchIndex + 12)!

        // Month stem/branch using 五虎遁 with lunar month
        // 正月=寅(index 2), 所以 monthBranchIndex = (lunarMonth + 1) % 12
        let tigerOffset = getTigerRuleOffset(for: yearStem)
        let monthStemIndex = (tigerOffset + lunarMonth - 1) % 10
        let monthStem = HeavenlyStem(rawValue: monthStemIndex)!
        let monthBranchIndex = (lunarMonth + 1) % 12
        let monthBranch = EarthlyBranch(rawValue: monthBranchIndex)!

        // Day stem and branch
        let dayPair = getDayStemAndBranch(year: solarYear, month: solarMonth, day: solarDay)

        // Hour stem and branch using 五鼠遁
        let hourPair = getHourStemAndBranch(dayStem: dayPair.heavenlyStem, hour: hour)

        return FourPillars(
            year: StemBranch(heavenlyStem: yearStem, earthlyBranch: yearBranch),
            month: StemBranch(heavenlyStem: monthStem, earthlyBranch: monthBranch),
            day: dayPair,
            hour: hourPair
        )
    }

    /// 五虎遁：年干 → 寅月(正月)天干索引
    private func getTigerRuleOffset(for yearStem: HeavenlyStem) -> Int {
        switch yearStem {
        case .jia, .ji: return 2   // 丙
        case .yi, .geng: return 4  // 戊
        case .bing, .xin: return 6 // 庚
        case .ding, .ren: return 8 // 壬
        case .wu, .gui: return 0   // 甲
        }
    }

    private func getDayStemAndBranch(year: Int, month: Int, day: Int) -> StemBranch {
        // 使用西曆的 Julian day 計算日干支
        // 參考點：1900年1月1日（西曆）= 甲戌日（天干甲=0, 地支戌=10）
        let gregorianCalendar = Calendar(identifier: .gregorian)

        guard let base = gregorianCalendar.date(from: DateComponents(year: 1900, month: 1, day: 1)),
              let target = gregorianCalendar.date(from: DateComponents(year: year, month: month, day: day)) else {
            return StemBranch(heavenlyStem: .jia, earthlyBranch: .zi)
        }

        let days = gregorianCalendar.dateComponents([.day], from: base, to: target).day ?? 0
        let stemIndex = ((days % 10) + 10) % 10
        let branchIndex = ((days + 10) % 12 + 12) % 12

        return StemBranch(
            heavenlyStem: HeavenlyStem(rawValue: stemIndex)!,
            earthlyBranch: EarthlyBranch(rawValue: branchIndex)!
        )
    }

    private func getHourStemAndBranch(dayStem: HeavenlyStem, hour: Int) -> StemBranch {
        let hourIndex = timeToIndex(hour: hour)
        let ratRule: [HeavenlyStem: Int] = [
            .jia: 0, .yi: 2, .bing: 4, .ding: 6, .wu: 8,
            .ji: 0, .geng: 2, .xin: 4, .ren: 6, .gui: 8
        ]
        let stemIndex = (ratRule[dayStem]! + hourIndex) % 10
        let branchIndex = hourIndex % 12

        return StemBranch(
            heavenlyStem: HeavenlyStem(rawValue: stemIndex)!,
            earthlyBranch: EarthlyBranch(rawValue: branchIndex)!
        )
    }

    // MARK: - Soul and Body (命宫身宫)

    private struct SoulAndBodyResult {
        let soulIndex: Int
        let bodyIndex: Int
        let heavenlyStemOfSoul: String
        let earthlyBranchOfSoul: String
    }

    private func getSoulAndBody(lunarMonth: Int, timeIndex: Int, yearlyStem: Int) -> SoulAndBodyResult {
        // 寅宫作为起点 (index 0)
        let yinIndex = 2  // 地支寅的索引

        // 命宫：寅起正月，顺数至生月，逆数生时
        // 身宫：寅起正月，顺数至生月，顺数生时
        let monthIndex = (lunarMonth + 1 - yinIndex) % 12  // 生月地支索引 - 寅的索引

        // 时辰地支索引
        let timeBranchIndex = timeIndex % 12

        // 命宫 = 生月索引 - 时辰索引 (逆时针)
        let soulIndex = fixIndex(monthIndex - timeBranchIndex)

        // 身宫 = 生月索引 + 时辰索引 (顺时针)
        let bodyIndex = fixIndex(monthIndex + timeBranchIndex)

        // 用五虎遁获取寅宫的天干
        let stemKey = HEAVENLY_STEMS[yearlyStem]
        let startStemKey = TIGER_RULE[stemKey] ?? "bing"
        let startStemIndex = HEAVENLY_STEMS.firstIndex(of: startStemKey) ?? 2

        // 命宫天干
        let heavenlyStemOfSoulIndex = fixIndex(startStemIndex + soulIndex, max: 10)
        let heavenlyStemOfSoul = HEAVENLY_STEMS[heavenlyStemOfSoulIndex]

        // 命宫地支 (命宫索引 + 寅的索引)
        let earthlyBranchOfSoulIndex = fixIndex(soulIndex + yinIndex)
        let earthlyBranchOfSoul = EARTHLY_BRANCHES[earthlyBranchOfSoulIndex]

        return SoulAndBodyResult(
            soulIndex: soulIndex,
            bodyIndex: bodyIndex,
            heavenlyStemOfSoul: heavenlyStemOfSoul,
            earthlyBranchOfSoul: earthlyBranchOfSoul
        )
    }

    // MARK: - Five Elements Class (五行局)

    private func getFiveElementsClass(heavenlyStem: String, earthlyBranch: String) -> WuXingJu {
        // 纳音五行计算
        // 天干取数：甲乙=1, 丙丁=2, 戊己=3, 庚辛=4, 壬癸=5
        let stemNumber: Int
        switch heavenlyStem {
        case "jia", "yi": stemNumber = 1
        case "bing", "ding": stemNumber = 2
        case "wu", "ji": stemNumber = 3
        case "geng", "xin": stemNumber = 4
        case "ren", "gui": stemNumber = 5
        default: stemNumber = 1
        }

        // 地支取数：子午丑未=1, 寅申卯酉=2, 辰戌巳亥=3
        let branchNumber: Int
        switch earthlyBranch {
        case "zi", "wu", "chou", "wei": branchNumber = 1
        case "yin", "shen", "mao", "you": branchNumber = 2
        case "chen", "xu", "si", "hai": branchNumber = 3
        default: branchNumber = 1
        }

        var index = stemNumber + branchNumber
        while index > 5 { index -= 5 }

        switch index {
        case 1: return .muSan    // 木三局
        case 2: return .jinSi    // 金四局
        case 3: return .shuiEr   // 水二局
        case 4: return .huoLiu   // 火六局
        case 5: return .tuWu    // 土五局
        default: return .tuWu
        }
    }

    // MARK: - Get Start Index for 紫微 and 天府

    private struct StartIndex {
        let ziweiIndex: Int
        let tianfuIndex: Int
    }

    private func getStartIndex(lunarDay: Int, timeIndex: Int, wuXingJu: WuXingJu) -> StartIndex {
        let fiveElementsValue = wuXingJu.value
        let maxDays = 30

        // Find the offset where (lunarDay + offset) is divisible by fiveElementsValue
        var offset = 0
        var divisor = lunarDay
        while divisor % fiveElementsValue != 0 && offset < maxDays {
            offset += 1
            divisor = lunarDay + offset
        }

        let quotient = divisor / fiveElementsValue
        var ziweiIndex = quotient % 12

        if offset % 2 == 0 {
            ziweiIndex = fixIndex(ziweiIndex - 1 + offset)
        } else {
            ziweiIndex = fixIndex(ziweiIndex - 1 - offset)
        }

        ziweiIndex = fixIndex(ziweiIndex)

        // 天府与紫微相对
        let tianfuIndex = fixIndex(12 - ziweiIndex)

        return StartIndex(ziweiIndex: ziweiIndex, tianfuIndex: tianfuIndex)
    }

    // MARK: - Arrange 12 Palaces

    private func arrangePalaces(mingGongIndex: Int, shenGongIndex: Int, yearlyStem: Int) -> [ZiweiPalace] {
        var palaces: [ZiweiPalace] = []

        // 使用五虎遁來計算寅宮天干
        let stemKey = HEAVENLY_STEMS[yearlyStem]
        let startStemKey = TIGER_RULE[stemKey] ?? "bing"
        let startStemIndex = HEAVENLY_STEMS.firstIndex(of: startStemKey) ?? 2

        for i in 0..<12 {
            let palaceIndex = fixIndex(i - mingGongIndex)
            let stemIndex = fixIndex(startStemIndex + i, max: 10)
            let branchIndex = fixIndex(i + 2)  // 從寅開始

            // iztro 標準順序（從命宮逆時針）：
            // 命宮→父母→福德→田宅→官祿→交友→遷移→疾厄→財帛→子女→夫妻→兄弟
            let palaceName: String
            switch palaceIndex {
            case 0: palaceName = "命宮"
            case 1: palaceName = "父母宮"
            case 2: palaceName = "福德宮"
            case 3: palaceName = "田宅宮"
            case 4: palaceName = "官祿宮"
            case 5: palaceName = "交友宮"
            case 6: palaceName = "遷移宮"
            case 7: palaceName = "疾厄宮"
            case 8: palaceName = "財帛宮"
            case 9: palaceName = "子女宮"
            case 10: palaceName = "夫妻宮"
            case 11: palaceName = "兄弟宮"
            default: palaceName = "命宮"
            }

            palaces.append(ZiweiPalace(
                name: palaceName,
                index: i,
                isOriginalPalace: (stemIndex == yearlyStem) && (branchIndex != 0) && (branchIndex != 1),
                isBodyPalace: i == shenGongIndex,
                heavenlyStem: HeavenlyStem(rawValue: stemIndex),
                earthlyBranch: EarthlyBranch(rawValue: branchIndex)
            ))
        }

        return palaces
    }

    // MARK: - Place Major Stars

    private func placeMajorStars(palaces: [ZiweiPalace], ziweiIndex: Int, tianfuIndex: Int) -> [ZiweiPalace] {
        var result = palaces

        // 紫微星系 — 逆時針從紫微開始放置
        // iztro: fixIndex(ziweiIndex - i), 陣列: [紫微, 天機, -, 太陽, 武曲, 天同, -, -, 廉貞]
        let ziweiGroup = [
            ("紫微", ziweiIndex),                     // i=0, offset 0
            ("天機", fixIndex(ziweiIndex - 1)),        // i=1, offset -1
            ("", -1),                                  // i=2, 空一格
            ("太陽", fixIndex(ziweiIndex - 3)),        // i=3, offset -3
            ("武曲", fixIndex(ziweiIndex - 4)),        // i=4, offset -4
            ("天同", fixIndex(ziweiIndex - 5)),        // i=5, offset -5
            ("", -1),                                  // i=6, 空二格
            ("", -1),                                  // i=7, 空二格
            ("廉貞", fixIndex(ziweiIndex - 8))         // i=8, offset -8
        ]

        for (name, index) in ziweiGroup {
            if name.isEmpty || index < 0 { continue }
            let brightness = majorStarBrightness(name: name, palaceIndex: index)
            result[index].majorStars.append(PlacedStar(name: name, type: "major", brightness: brightness))
        }

        // 天府星系 (顺行)
        let tianfuGroup = [
            ("天府", tianfuIndex),
            ("太陰", fixIndex(tianfuIndex + 1)),
            ("貪狼", fixIndex(tianfuIndex + 2)),
            ("巨門", fixIndex(tianfuIndex + 3)),
            ("天相", fixIndex(tianfuIndex + 4)),
            ("天梁", fixIndex(tianfuIndex + 5)),
            ("七殺", fixIndex(tianfuIndex + 6)),
            ("", -1),
            ("", -1),
            ("", -1),
            ("破軍", fixIndex(tianfuIndex + 10))
        ]

        for (name, index) in tianfuGroup {
            if name.isEmpty || index < 0 { continue }
            let brightness = majorStarBrightness(name: name, palaceIndex: index)
            result[index].majorStars.append(PlacedStar(name: name, type: "major", brightness: brightness))
        }

        return result
    }

    // MARK: - Star Brightness (亮度)

    private func majorStarBrightness(name: String, palaceIndex: Int) -> StarBrightness {
        let branch = fixIndex(palaceIndex + 2) // 換算為地支索引
        switch name {
        case "紫微":
            return (branch == 6 || branch == 7) ? .wang : (branch == 0 ? .xian : .ping)
        case "天機":
            return (branch == 4 || branch == 7 || branch == 10) ? .wang : (branch == 3 || branch == 9 ? .xian : .ping)
        case "太陽":
            return (branch == 3 || branch == 4 || branch == 6) ? .wang : (branch == 0 || branch == 11 ? .xian : .ping)
        case "武曲":
            return (branch == 4 || branch == 7 || branch == 10 || branch == 1) ? .wang : (branch == 5 || branch == 11 ? .xian : .ping)
        case "天同":
            return (branch == 5 || branch == 11 || branch == 0 || branch == 2 || branch == 8) ? .wang : (branch == 3 || branch == 9 ? .xian : .ping)
        case "廉貞":
            return (branch == 2 || branch == 8 || branch == 4 || branch == 10) ? .wang : (branch == 5 || branch == 11 ? .xian : .ping)
        case "天府":
            return (branch == 4 || branch == 10 || branch == 0 || branch == 6) ? .wang : (branch == 5 || branch == 11 ? .xian : .ping)
        case "太陰":
            return (branch == 9 || branch == 10 || branch == 11) ? .wang : (branch == 5 || branch == 6 || branch == 7 ? .xian : .ping)
        case "貪狼":
            return (branch == 4 || branch == 10 || branch == 2 || branch == 8) ? .wang : (branch == 5 || branch == 11 ? .xian : .ping)
        case "巨門":
            return (branch == 4 || branch == 10 || branch == 2 || branch == 8) ? .wang : (branch == 5 || branch == 11 ? .xian : .ping)
        case "天相":
            return (branch == 3 || branch == 9 || branch == 2 || branch == 8 || branch == 5 || branch == 11) ? .wang : (branch == 0 || branch == 6 ? .xian : .ping)
        case "天梁":
            return (branch == 1 || branch == 4 || branch == 7 || branch == 10) ? .wang : (branch == 5 || branch == 11 ? .xian : .ping)
        case "七殺":
            return (branch == 2 || branch == 8 || branch == 0 || branch == 6 || branch == 4 || branch == 10) ? .wang : (branch == 5 || branch == 11 ? .xian : .ping)
        case "破軍":
            return (branch == 0 || branch == 6 || branch == 1 || branch == 7) ? .wang : (branch == 3 || branch == 9 ? .xian : .ping)
        default:
            return .ping
        }
    }

    // MARK: - Minor Star Brightness Lookup

    private let MINOR_STAR_BRIGHTNESS: [String: [StarBrightness]] = [
        "文昌": [.xian, .li, .de, .miao, .xian, .li, .de, .miao, .xian, .li, .de, .miao],
        "文曲": [.ping, .wang, .de, .miao, .xian, .wang, .de, .miao, .xian, .wang, .de, .miao],
        "火星": [.miao, .li, .xian, .de, .miao, .li, .xian, .de, .miao, .li, .xian, .de],
        "鈴星": [.miao, .li, .xian, .de, .miao, .li, .xian, .de, .miao, .li, .xian, .de],
        "擎羊": [.ping, .xian, .miao, .ping, .xian, .miao, .ping, .xian, .miao, .ping, .xian, .miao],
        "陀罗": [.xian, .ping, .miao, .xian, .ping, .miao, .xian, .ping, .miao, .xian, .ping, .miao]
    ]

    private func minorStarBrightness(name: String, palaceBranch: Int) -> StarBrightness {
        guard let table = MINOR_STAR_BRIGHTNESS[name] else { return .ping }
        let idx = fixIndex(palaceBranch - 2)
        return table[idx]
    }

    // MARK: - Place Minor Stars (六吉、六煞)

    private func placeMinorStars(palaces: [ZiweiPalace], yearlyStem: Int, yearlyBranch: Int, timeIndex: Int, lunarMonth: Int) -> [ZiweiPalace] {
        var result = palaces

        // 禄存、擎羊、陀罗、天马 (按年干年支)
        let luYangTuoMa = getLuYangTuoMaIndex(yearlyStem: yearlyStem, yearlyBranch: yearlyBranch)
        result[luYangTuoMa.luIndex].minorStars.append(PlacedStar(name: "祿存", type: "lucun", brightness: .wang))
        let yangBranch = result[luYangTuoMa.yangIndex].earthlyBranch?.rawValue ?? 0
        let tuoBranch = result[luYangTuoMa.tuoIndex].earthlyBranch?.rawValue ?? 0
        result[luYangTuoMa.yangIndex].minorStars.append(PlacedStar(name: "擎羊", type: "tough", brightness: minorStarBrightness(name: "擎羊", palaceBranch: yangBranch)))
        result[luYangTuoMa.tuoIndex].minorStars.append(PlacedStar(name: "陀罗", type: "tough", brightness: minorStarBrightness(name: "陀罗", palaceBranch: tuoBranch)))
        result[luYangTuoMa.maIndex].minorStars.append(PlacedStar(name: "天馬", type: "tianma", brightness: .ping))

        // 左辅、右弼 (按月)
        let zuoYou = getZuoYouIndex(lunarMonth: lunarMonth)
        result[zuoYou.zuoIndex].minorStars.append(PlacedStar(name: "左輔", type: "soft", brightness: .ping))
        result[zuoYou.youIndex].minorStars.append(PlacedStar(name: "右弼", type: "soft", brightness: .ping))

        // 文昌、文曲 (按时)
        let changQu = getChangQuIndex(timeIndex: timeIndex)
        let changBranch = result[changQu.changIndex].earthlyBranch?.rawValue ?? 0
        let quBranch = result[changQu.quIndex].earthlyBranch?.rawValue ?? 0
        result[changQu.changIndex].minorStars.append(PlacedStar(name: "文昌", type: "soft", brightness: minorStarBrightness(name: "文昌", palaceBranch: changBranch)))
        result[changQu.quIndex].minorStars.append(PlacedStar(name: "文曲", type: "soft", brightness: minorStarBrightness(name: "文曲", palaceBranch: quBranch)))

        // 天魁、天钺 (按年干)
        let kuiYue = getKuiYueIndex(yearlyStem: yearlyStem)
        result[kuiYue.kuiIndex].minorStars.append(PlacedStar(name: "天魁", type: "soft", brightness: .ping))
        result[kuiYue.yueIndex].minorStars.append(PlacedStar(name: "天钺", type: "soft", brightness: .ping))

        // 地空、地劫 (按时)
        let kongJie = getKongJieIndex(timeIndex: timeIndex)
        result[kongJie.kongIndex].minorStars.append(PlacedStar(name: "地空", type: "tough", brightness: .xian))
        result[kongJie.jieIndex].minorStars.append(PlacedStar(name: "地劫", type: "tough", brightness: .xian))

        // 火星、铃星 (按年支、时支)
        let huoLing = getHuoLingIndex(yearlyBranch: yearlyBranch, timeIndex: timeIndex)
        let huoBranch = result[huoLing.huoIndex].earthlyBranch?.rawValue ?? 0
        let lingBranch = result[huoLing.lingIndex].earthlyBranch?.rawValue ?? 0
        result[huoLing.huoIndex].minorStars.append(PlacedStar(name: "火星", type: "tough", brightness: minorStarBrightness(name: "火星", palaceBranch: huoBranch)))
        result[huoLing.lingIndex].minorStars.append(PlacedStar(name: "鈴星", type: "tough", brightness: minorStarBrightness(name: "鈴星", palaceBranch: lingBranch)))

        return result
    }

    // MARK: - Location Functions

    private struct LuYangTuoMaIndex {
        let luIndex: Int
        let yangIndex: Int
        let tuoIndex: Int
        let maIndex: Int
    }

    private func getLuYangTuoMaIndex(yearlyStem: Int, yearlyBranch: Int) -> LuYangTuoMaIndex {
        // 天马 (按年支) - 四马地
        let maIndex: Int
        switch yearlyBranch {
        case 2, 6, 10: maIndex = fixIndex(8 - 2)   // 寅午戌 -> 申
        case 8, 0, 4: maIndex = fixIndex(2 - 2)    // 申子辰 -> 寅
        case 5, 9, 1: maIndex = fixIndex(11 - 2)   // 巳酉丑 -> 亥
        case 11, 3, 7: maIndex = fixIndex(5 - 2)  // 亥卯未 -> 巳
        default: maIndex = 0
        }

        // 禄存 (按年干)
        let luIndex: Int
        switch yearlyStem {
        case 0: luIndex = fixIndex(2 - 2)   // 甲禄寅
        case 1: luIndex = fixIndex(3 - 2)   // 乙禄卯
        case 2, 4: luIndex = fixIndex(5 - 2)  // 丙戊禄巳
        case 3, 5: luIndex = fixIndex(6 - 2)  // 丁己禄午
        case 6: luIndex = fixIndex(8 - 2)    // 庚禄申
        case 7: luIndex = fixIndex(9 - 2)    // 辛禄酉
        case 8: luIndex = fixIndex(11 - 2)  // 壬禄亥
        case 9: luIndex = fixIndex(0 - 2)   // 癸禄子
        default: luIndex = 0
        }

        let yangIndex = fixIndex(luIndex + 1)
        let tuoIndex = fixIndex(luIndex - 1)

        return LuYangTuoMaIndex(luIndex: luIndex, yangIndex: yangIndex, tuoIndex: tuoIndex, maIndex: maIndex)
    }

    private struct ZuoYouIndex {
        let zuoIndex: Int
        let youIndex: Int
    }

    private func getZuoYouIndex(lunarMonth: Int) -> ZuoYouIndex {
        // 辰上顺正寻左辅, 戌上逆正右弼当
        let chenIndex = fixIndex(4 - 2)  // 辰 = index 4, relative to yin = 2
        let xuIndex = fixIndex(10 - 2)   // 戌 = index 10

        let zuoIndex = fixIndex(chenIndex + (lunarMonth - 1))
        let youIndex = fixIndex(xuIndex - (lunarMonth - 1))

        return ZuoYouIndex(zuoIndex: zuoIndex, youIndex: youIndex)
    }

    private struct ChangQuIndex {
        let changIndex: Int
        let quIndex: Int
    }

    private func getChangQuIndex(timeIndex: Int) -> ChangQuIndex {
        // 辰上顺时文曲位, 戌上逆时觅文昌
        let chenIndex = fixIndex(4 - 2)
        let xuIndex = fixIndex(10 - 2)

        let quIndex = fixIndex(chenIndex + timeIndex)
        let changIndex = fixIndex(xuIndex - timeIndex)

        return ChangQuIndex(changIndex: changIndex, quIndex: quIndex)
    }

    private struct KuiYueIndex {
        let kuiIndex: Int
        let yueIndex: Int
    }

    private func getKuiYueIndex(yearlyStem: Int) -> KuiYueIndex {
        // 甲戊庚之年丑未, 乙己之年子申, 辛年午寅, 壬癸之年卯巳, 丙丁之年亥酉
        switch yearlyStem {
        case 0, 4, 6: return KuiYueIndex(kuiIndex: fixIndex(1 - 2), yueIndex: fixIndex(7 - 2))  // 丑未
        case 1, 5: return KuiYueIndex(kuiIndex: fixIndex(0 - 2), yueIndex: fixIndex(8 - 2))    // 子申
        case 7: return KuiYueIndex(kuiIndex: fixIndex(6 - 2), yueIndex: fixIndex(2 - 2))       // 午寅
        case 8, 9: return KuiYueIndex(kuiIndex: fixIndex(3 - 2), yueIndex: fixIndex(5 - 2))     // 卯巳
        case 2, 3: return KuiYueIndex(kuiIndex: fixIndex(11 - 2), yueIndex: fixIndex(9 - 2))   // 亥酉
        default: return KuiYueIndex(kuiIndex: 0, yueIndex: 0)
        }
    }

    private struct KongJieIndex {
        let kongIndex: Int
        let jieIndex: Int
    }

    private func getKongJieIndex(timeIndex: Int) -> KongJieIndex {
        // 亥上子时顺安劫, 逆回便是地空亡
        let haiIndex = fixIndex(11 - 2)

        let jieIndex = fixIndex(haiIndex + timeIndex)
        let kongIndex = fixIndex(haiIndex - timeIndex)

        return KongJieIndex(kongIndex: kongIndex, jieIndex: jieIndex)
    }

    private struct HuoLingIndex {
        let huoIndex: Int
        let lingIndex: Int
    }

    private func getHuoLingIndex(yearlyBranch: Int, timeIndex: Int) -> HuoLingIndex {
        // 申子辰人寅戌扬, 寅午戌人丑卯方, 巳酉丑人卯戌位, 亥卯未人酉戌房
        switch yearlyBranch {
        case 2, 6, 10: return HuoLingIndex(huoIndex: fixIndex(1 - 2 + timeIndex), lingIndex: fixIndex(3 - 2 + timeIndex))   // 寅午戌: 火星丑, 鈴星卯
        case 8, 0, 4: return HuoLingIndex(huoIndex: fixIndex(2 - 2 + timeIndex), lingIndex: fixIndex(10 - 2 + timeIndex))   // 申子辰
        case 5, 9, 1: return HuoLingIndex(huoIndex: fixIndex(3 - 2 + timeIndex), lingIndex: fixIndex(10 - 2 + timeIndex))  // 巳酉丑
        case 11, 3, 7: return HuoLingIndex(huoIndex: fixIndex(9 - 2 + timeIndex), lingIndex: fixIndex(10 - 2 + timeIndex)) // 亥卯未
        default: return HuoLingIndex(huoIndex: 0, lingIndex: 0)
        }
    }

    // MARK: - Place Adjective Stars (杂耀)

    private func placeAdjectiveStars(palaces: [ZiweiPalace], solarDate: String, timeIndex: Int, yearlyStem: Int, yearlyBranch: Int, dayStem: Int, mingGongIndex: Int, gender: Gender, fixLeap: Bool) -> [ZiweiPalace] {
        var result = palaces

        // Helper: find palace index containing a star name
        func findPalaceIndex(starName: String, in stars: [[PlacedStar]]) -> Int? {
            for (i, starList) in stars.enumerated() {
                if starList.contains(where: { $0.name == starName }) { return i }
            }
            return nil
        }
        let allMinorStars = result.map { $0.minorStars }

        // ——— 年系星 ———
        // 红鸾、天喜 (按年支)
        let hongluanIndex = fixIndex(3 - 2 - yearlyBranch) // 卯上起子逆數
        result[hongluanIndex].adjectiveStars.append(PlacedStar(name: "紅鸞", type: "flower"))
        result[fixIndex(hongluanIndex + 6)].adjectiveStars.append(PlacedStar(name: "天喜", type: "flower"))

        // 龍池、鳳閣 (按年支)
        result[fixIndex(4 - 2 + yearlyBranch)].adjectiveStars.append(PlacedStar(name: "龍池", type: "adjective"))
        result[fixIndex(10 - 2 - yearlyBranch)].adjectiveStars.append(PlacedStar(name: "鳳閣", type: "adjective"))

        // 華蓋、咸池 (按年支)
        let (huagaiBranch, xianchiBranch) = huagaiXianchiBranches(yearlyBranch: yearlyBranch)
        result[fixIndex(huagaiBranch - 2)].adjectiveStars.append(PlacedStar(name: "華蓋", type: "adjective"))
        result[fixIndex(xianchiBranch - 2)].adjectiveStars.append(PlacedStar(name: "咸池", type: "adjective"))

        // 孤辰、寡宿 (按年支)
        let (guchenBranch, guasuBranch) = guchenGuasuBranches(yearlyBranch: yearlyBranch)
        result[fixIndex(guchenBranch - 2)].adjectiveStars.append(PlacedStar(name: "孤辰", type: "adjective"))
        result[fixIndex(guasuBranch - 2)].adjectiveStars.append(PlacedStar(name: "寡宿", type: "adjective"))

        // 天才、天壽 (by year branch, from 命宮/身宮)
        // Simplified: from 辰/戌
        result[fixIndex(4 - 2 + yearlyBranch)].adjectiveStars.append(PlacedStar(name: "天才", type: "adjective"))
        result[fixIndex(10 - 2 + yearlyBranch)].adjectiveStars.append(PlacedStar(name: "天壽", type: "adjective"))

        // 天哭、天虛 (from 午)
        result[fixIndex(6 - 2 - yearlyBranch)].adjectiveStars.append(PlacedStar(name: "天哭", type: "adjective"))
        result[fixIndex(6 - 2 + yearlyBranch)].adjectiveStars.append(PlacedStar(name: "天虛", type: "adjective"))

        // 劫殺
        let jieShaOffset = [3, 6, 9, 0][(yearlyBranch % 12) / 3]
        let jieShaIndex = fixIndex(yearlyBranch + jieShaOffset - 2)
        result[jieShaIndex].adjectiveStars.append(PlacedStar(name: "劫殺", type: "adjective"))

        // 大耗
        let baseIndex = fixIndex(yearlyBranch + 6)
        let daHaoOffset = yearlyBranch % 2 == 0 ? 1 : -1
        let daHaoIndex = fixIndex(baseIndex + daHaoOffset - 2)
        result[daHaoIndex].adjectiveStars.append(PlacedStar(name: "大耗", type: "adjective"))

        // 天德、月德
        result[fixIndex(9 - 2 + yearlyBranch)].adjectiveStars.append(PlacedStar(name: "天德", type: "adjective"))
        result[fixIndex(5 - 2 + yearlyBranch)].adjectiveStars.append(PlacedStar(name: "月德", type: "adjective"))

        // 天空 (生年支順數的前一位)
        result[fixIndex(yearlyBranch - 1)].adjectiveStars.append(PlacedStar(name: "天空", type: "adjective"))

        // 年解
        result[fixIndex(10 - 2 - yearlyBranch)].adjectiveStars.append(PlacedStar(name: "年解", type: "adjective"))

        // 蜚蠊
        let feilianBranches = [8, 9, 10, 5, 6, 7, 2, 3, 4, 11, 0, 1]
        result[fixIndex(feilianBranches[yearlyBranch % 12] - 2)].adjectiveStars.append(PlacedStar(name: "蜚蠊", type: "adjective"))

        // 破碎
        let posuiBranches = [5, 1, 9][(yearlyBranch % 12) % 3]
        result[fixIndex(posuiBranches - 2)].adjectiveStars.append(PlacedStar(name: "破碎", type: "adjective"))

        // 截路空亡 (by year stem)
        let (jieluBranch, kongwangBranch) = jieluKongwangBranches(yearlyStem: yearlyStem)
        result[fixIndex(jieluBranch - 2)].adjectiveStars.append(PlacedStar(name: "截路", type: "adjective"))
        result[fixIndex(kongwangBranch - 2)].adjectiveStars.append(PlacedStar(name: "空亡", type: "adjective"))

        // 天廚 (by year stem)
        let tianchuBranches = [5, 6, 0, 5, 6, 8, 2, 6, 9, 11]
        result[fixIndex(tianchuBranches[yearlyStem] - 2)].adjectiveStars.append(PlacedStar(name: "天廚", type: "adjective"))

        // 天官 (by year stem)
        let tianguanBranches = [7, 4, 5, 2, 3, 9, 11, 9, 10, 6]
        result[fixIndex(tianguanBranches[yearlyStem] - 2)].adjectiveStars.append(PlacedStar(name: "天官", type: "adjective"))

        // 天福 (by year stem)
        let tianfuBranches = [9, 8, 0, 11, 3, 2, 6, 5, 6, 5]
        result[fixIndex(tianfuBranches[yearlyStem] - 2)].adjectiveStars.append(PlacedStar(name: "天福", type: "adjective"))

        // 旬空 (by year stem & branch)
        let xunkongBase = fixIndex(yearlyBranch + 9 - yearlyStem + 1)
        let xunkongIndex = (yearlyBranch % 2) != (xunkongBase % 2) ? fixIndex(xunkongBase + 1) : xunkongBase
        result[xunkongIndex].adjectiveStars.append(PlacedStar(name: "旬空", type: "adjective"))

        // 天傷 / 天使 (by mingGongIndex & gender)
        var tianshangIndex = fixIndex(mingGongIndex + 5) // 交友宮
        var tianshiIndex = fixIndex(mingGongIndex + 7)   // 疾厄宮
        let isYangBranch = yearlyBranch % 2 == 0
        let isMale = gender == .male
        // 中州派：陰男陽女則交換
        if isYangBranch != isMale {
            (tianshangIndex, tianshiIndex) = (tianshiIndex, tianshangIndex)
        }
        result[tianshangIndex].adjectiveStars.append(PlacedStar(name: "天傷", type: "adjective"))
        result[tianshiIndex].adjectiveStars.append(PlacedStar(name: "天使", type: "adjective"))

        // ——— 月系星 ———
        let lunar = lunarFromSolarDate(solarDate)
        let lunarMonth = lunar.month
        let monthIndex = fixIndex(lunarMonth - 1) // 0-based

        // 左輔、右弼已放在 minorStars

        // 天姚 (from 丑宫)
        result[fixIndex(1 - 2 + monthIndex)].adjectiveStars.append(PlacedStar(name: "天姚", type: "adjective"))

        // 天刑 (from 酉宫)
        result[fixIndex(9 - 2 + monthIndex)].adjectiveStars.append(PlacedStar(name: "天刑", type: "adjective"))

        // 陰煞 (repeating every 6 months)
        let yinshaBranches = [2, 0, 10, 8, 6, 4]
        result[fixIndex(yinshaBranches[(lunarMonth - 1) % 6] - 2)].adjectiveStars.append(PlacedStar(name: "陰煞", type: "adjective"))

        // 天月
        let tianyueBranches = [10, 5, 4, 2, 7, 3, 11, 7, 2, 6, 10, 2]
        result[fixIndex(tianyueBranches[(lunarMonth - 1) % 12] - 2)].adjectiveStars.append(PlacedStar(name: "天月", type: "adjective"))

        // 天巫 (repeating every 4 months)
        let tianwuBranches = [5, 8, 2, 11]
        result[fixIndex(tianwuBranches[(lunarMonth - 1) % 4] - 2)].adjectiveStars.append(PlacedStar(name: "天巫", type: "adjective"))

        // 月解
        let yuejieBranches = [8, 8, 10, 10, 0, 0, 2, 2, 4, 4, 6, 6]
        result[fixIndex(yuejieBranches[(lunarMonth - 1) % 12] - 2)].adjectiveStars.append(PlacedStar(name: "月解", type: "adjective"))

        // ——— 日系星 ———
        // 三台 (from 左輔, +日干)
        if let zuoIndex = findPalaceIndex(starName: "左輔", in: allMinorStars) {
            result[fixIndex(zuoIndex + dayStem)].adjectiveStars.append(PlacedStar(name: "三台", type: "adjective"))
        }
        // 八座 (from 右弼, -日干)
        if let youIndex = findPalaceIndex(starName: "右弼", in: allMinorStars) {
            result[fixIndex(youIndex - dayStem)].adjectiveStars.append(PlacedStar(name: "八座", type: "adjective"))
        }
        // 恩光 (from 文昌, +日干-1)
        if let changIndex = findPalaceIndex(starName: "文昌", in: allMinorStars) {
            result[fixIndex(changIndex + dayStem - 1)].adjectiveStars.append(PlacedStar(name: "恩光", type: "adjective"))
        }
        // 天貴 (from 文曲, +日干-1)
        if let quIndex = findPalaceIndex(starName: "文曲", in: allMinorStars) {
            result[fixIndex(quIndex + dayStem - 1)].adjectiveStars.append(PlacedStar(name: "天貴", type: "adjective"))
        }

        // ——— 時系星 ———
        // 台輔 (from 午, +時支)
        result[fixIndex(6 + timeIndex)].adjectiveStars.append(PlacedStar(name: "台輔", type: "adjective"))
        // 封誥 (from 寅, +時支)
        result[fixIndex(2 + timeIndex)].adjectiveStars.append(PlacedStar(name: "封誥", type: "adjective"))

        return result
    }

    private func lunarFromSolarDate(_ dateStr: String) -> (month: Int, day: Int) {
        let parts = dateStr.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return (1, 1) }
        let lunar = lunarFromSolar(year: parts[0], month: parts[1], day: parts[2])
        return (lunar.month, lunar.day)
    }

    private func huagaiXianchiBranches(yearlyBranch: Int) -> (Int, Int) {
        switch yearlyBranch {
        case 2, 6, 10: return (10, 3)  // 寅午戌 → 戌卯
        case 8, 0, 4: return (4, 9)    // 申子辰 → 辰酉
        case 5, 9, 1: return (1, 6)    // 巳酉丑 → 丑午
        case 11, 3, 7: return (7, 0)   // 亥卯未 → 未子
        default: return (0, 0)
        }
    }

    private func guchenGuasuBranches(yearlyBranch: Int) -> (Int, Int) {
        switch yearlyBranch {
        case 2, 3, 4: return (5, 1)    // 寅卯辰 → 巳丑
        case 5, 6, 7: return (8, 4)    // 巳午未 → 申辰
        case 8, 9, 10: return (11, 7)  // 申酉戌 → 亥未
        case 11, 0, 1: return (2, 10)  // 亥子丑 → 寅戌
        default: return (0, 0)
        }
    }

    private func jieluKongwangBranches(yearlyStem: Int) -> (Int, Int) {
        switch yearlyStem {
        case 0, 5: return (8, 9)   // 甲己 → 申酉
        case 1, 6: return (6, 7)   // 乙庚 → 午未
        case 2, 7: return (4, 5)   // 丙辛 → 辰巳
        case 3, 8: return (2, 3)   // 丁壬 → 寅卯
        case 4, 9: return (0, 1)   // 戊癸 → 子丑
        default: return (0, 0)
        }
    }

    // MARK: - Place Transformations (四化星)

    private func placeTransformations(palaces: [ZiweiPalace], yearlyStem: Int) -> [ZiweiPalace] {
        var result = palaces

        let transformations = getTransformations(yearlyStem: yearlyStem)

        for (starName, transType) in transformations {
            for i in 0..<12 {
                // 在主星中尋找並標記
                if let idx = result[i].majorStars.firstIndex(where: { $0.name == starName }) {
                    result[i].majorStars[idx].transformation = transType
                }
                // 在輔星中尋找並標記
                if let idx = result[i].minorStars.firstIndex(where: { $0.name == starName }) {
                    result[i].minorStars[idx].transformation = transType
                }
            }
        }

        return result
    }

    private func getTransformations(yearlyStem: Int) -> [(String, String)] {
        guard let stem = HeavenlyStem(rawValue: yearlyStem) else { return [] }
        let transTypes = ["祿", "權", "科", "忌"]
        return stem.transformations.enumerated().map { (i, star) in
            (star.displayName, transTypes[i])
        }
    }

    // MARK: - Place ChangSheng12 (长生十二星)

    /// 长生十二神 placement per iztro
    /// 起始宮位由五行局決定，方向由年干陰陽與性別決定
    private func placeChangSheng12(palaces: [ZiweiPalace], wuXingJu: WuXingJu, yearlyStem: Int, gender: Gender) -> [ZiweiPalace] {
        var result = palaces

        // 五行局 → 長生起始地支
        let startBranch: Int
        switch wuXingJu {
        case .shuiEr: startBranch = 8   // 水二局 → 申
        case .muSan: startBranch = 11   // 木三局 → 亥
        case .jinSi: startBranch = 5    // 金四局 → 巳
        case .tuWu: startBranch = 8     // 土五局 → 申
        case .huoLiu: startBranch = 2   // 火六局 → 寅
        }

        let startPalaceIndex = fixIndex(startBranch - 2) // 轉為 palace index
        let isYangStem = yearlyStem % 2 == 0  // 甲丙戊庚壬=陽
        let isYangGender = gender == .male
        // 陽男陰女順行, 陰男陽女逆行
        let clockwise = isYangStem == isYangGender

        for i in 0..<12 {
            let idx = clockwise
                ? fixIndex(startPalaceIndex + i)
                : fixIndex(startPalaceIndex - i)
            result[idx].changsheng12 = i
        }

        return result
    }

    // MARK: - Place 博士十二神

    private func placeBoShi12(palaces: [ZiweiPalace], yearlyStem: Int, gender: Gender) -> [ZiweiPalace] {
        var result = palaces
        let names = ["博士", "力士", "青龍", "小耗", "將軍", "奏書", "飛廉", "喜神", "病符", "大耗", "伏兵", "官府"]

        // 找祿存所在宮位
        var luCunIndex = 0
        for (i, palace) in result.enumerated() {
            if palace.minorStars.contains(where: { $0.name == "祿存" }) {
                luCunIndex = i
                break
            }
        }

        let isYangStem = yearlyStem % 2 == 0
        let isYangGender = gender == .male
        let clockwise = isYangStem == isYangGender // 陽男陰女順行

        for i in 0..<12 {
            let idx = clockwise
                ? fixIndex(luCunIndex + i)
                : fixIndex(luCunIndex - i)
            result[idx].boshi12 = i
            result[idx].boshi12Name = names[i]
        }

        return result
    }

    // MARK: - Assign Decadal Ranges (大限)

    private func assignDecadalRanges(palaces: [ZiweiPalace], mingGongIndex: Int, wuXingJu: WuXingJu, yearlyStem: Int, gender: Gender) -> [ZiweiPalace] {
        var result = palaces
        let startAge = wuXingJu.value
        let isYangStem = yearlyStem % 2 == 0
        let isMale = gender == .male
        let clockwise = (isYangStem && isMale) || (!isYangStem && !isMale) // 陽男陰女順行

        for i in 0..<12 {
            let palaceIndex = clockwise ? fixIndex(mingGongIndex + i) : fixIndex(mingGongIndex - i)
            let fromAge = startAge + i * 10
            let toAge = fromAge + 9
            let palace = result[palaceIndex]
            result[palaceIndex].decadal = Decadal(
                range: (fromAge, toAge),
                heavenlyStem: palace.heavenlyStem ?? .jia,
                earthlyBranch: palace.earthlyBranch ?? .zi,
                palaces: result.map { $0.name }
            )
        }
        return result
    }

    // MARK: - Calculate Ages (小限)

    private func calculateAges(palaces: [ZiweiPalace], yearlyBranch: Int, gender: Gender) -> [ZiweiPalace] {
        var result = palaces

        // 年支決定起點：寅午戌→辰(4), 申子辰→戌(10), 巳酉丑→未(7), 亥卯未→丑(1)
        let startBranch: Int
        switch yearlyBranch {
        case 2, 6, 10: startBranch = 4   // 寅午戌 → 辰
        case 8, 0, 4:  startBranch = 10  // 申子辰 → 戌
        case 5, 9, 1:  startBranch = 7   // 巳酉丑 → 未
        case 11, 3, 7: startBranch = 1   // 亥卯未 → 丑
        default: startBranch = 4
        }

        let startPalace = fixIndex(startBranch - 2) // 轉為 palace index (寅=0)
        let isMale = gender == .male
        let maxAge = 120

        for palaceIndex in 0..<12 {
            var ages: [Int] = []
            // 計算第一個落在本宮的年齡
            var diff: Int
            if isMale {
                diff = palaceIndex - startPalace
            } else {
                diff = startPalace - palaceIndex
            }
            while diff < 0 { diff += 12 }
            let firstAge = diff + 1

            var age = firstAge
            while age <= maxAge {
                ages.append(age)
                age += 12
            }
            result[palaceIndex].ages = ages
        }

        return result
    }

    // MARK: - Horoscope (大限/流年)

    private func calculateHoroscope(palaces: [ZiweiPalace], mingGongIndex: Int, yearlyStem: Int, birthYear: Int, gender: Gender) -> HoroscopeData {
        var horoscope = HoroscopeData()
        let currentYear = Calendar.current.component(.year, from: Date())
        let currentMonth = Calendar.current.component(.month, from: Date())
        let currentDay = Calendar.current.component(.day, from: Date())
        let currentHour = Calendar.current.component(.hour, from: Date())

        // 大限
        let decadal = calculateDecadal(mingGongIndex: mingGongIndex, yearlyStem: yearlyStem, birthYear: birthYear, currentYear: currentYear, gender: gender, palaces: palaces)
        horoscope.decadal = decadal

        // 流年
        let yearly = calculateYearly(mingGongIndex: mingGongIndex, yearlyStem: yearlyStem, currentYear: currentYear, birthYear: birthYear, gender: gender, palaces: palaces)
        horoscope.yearly = yearly

        // 流月 (簡化：以當前西曆月推算)
        let monthlyStem = HeavenlyStem(rawValue: (currentYear - 4 + currentMonth - 1) % 10)!
        let monthlyBranch = EarthlyBranch(rawValue: (currentMonth + 1) % 12)!
        horoscope.monthly = PeriodData(
            index: fixIndex(monthlyBranch.rawValue - 2),
            heavenlyStem: monthlyStem,
            earthlyBranch: monthlyBranch,
            palaceNames: palaces.map { $0.name },
            mutagen: monthlyStem.transformations,
            stars: [],
            age: currentYear - birthYear,
            startYear: currentYear,
            endYear: currentYear
        )

        // 流日 (簡化)
        let dailyStem = HeavenlyStem(rawValue: (currentYear - 4 + currentMonth - 1 + currentDay - 1) % 10)!
        let dailyBranch = EarthlyBranch(rawValue: (currentDay - 1) % 12)!
        horoscope.daily = PeriodData(
            index: fixIndex(dailyBranch.rawValue - 2),
            heavenlyStem: dailyStem,
            earthlyBranch: dailyBranch,
            palaceNames: palaces.map { $0.name },
            mutagen: dailyStem.transformations,
            stars: [],
            age: currentYear - birthYear,
            startYear: currentYear,
            endYear: currentYear
        )

        // 流時 (簡化)
        let hourlyBranchIndex = (currentHour + 1) / 2 % 12
        let hourlyStem = HeavenlyStem(rawValue: (dailyStem.rawValue * 2 + hourlyBranchIndex) % 10)!
        let hourlyBranch = EarthlyBranch(rawValue: hourlyBranchIndex)!
        horoscope.hourly = PeriodData(
            index: fixIndex(hourlyBranch.rawValue - 2),
            heavenlyStem: hourlyStem,
            earthlyBranch: hourlyBranch,
            palaceNames: palaces.map { $0.name },
            mutagen: hourlyStem.transformations,
            stars: [],
            age: currentYear - birthYear,
            startYear: currentYear,
            endYear: currentYear
        )

        return horoscope
    }

    private func calculateDecadal(mingGongIndex: Int, yearlyStem: Int, birthYear: Int, currentYear: Int, gender: Gender, palaces: [ZiweiPalace]) -> PeriodData {
        let currentAge = currentYear - birthYear
        guard let activePalace = palaces.first(where: {
            guard let decadal = $0.decadal else { return false }
            return decadal.range.0 <= currentAge && currentAge <= decadal.range.1
        }) else {
            // Fallback to first decadal
            return PeriodData(
                index: mingGongIndex,
                heavenlyStem: HeavenlyStem(rawValue: yearlyStem)!,
                earthlyBranch: EarthlyBranch(rawValue: fixIndex(mingGongIndex + 2))!,
                palaceNames: palaces.map { $0.name },
                mutagen: HeavenlyStem(rawValue: yearlyStem)!.transformations,
                stars: [],
                age: currentAge,
                startYear: birthYear,
                endYear: birthYear + 9
            )
        }

        return PeriodData(
            index: activePalace.index,
            heavenlyStem: activePalace.heavenlyStem ?? .jia,
            earthlyBranch: activePalace.earthlyBranch ?? .zi,
            palaceNames: palaces.map { $0.name },
            mutagen: (activePalace.heavenlyStem ?? .jia).transformations,
            stars: [],
            age: currentAge,
            startYear: birthYear + (activePalace.decadal?.range.0 ?? 0),
            endYear: birthYear + (activePalace.decadal?.range.1 ?? 0)
        )
    }

    private func calculateYearly(mingGongIndex: Int, yearlyStem: Int, currentYear: Int, birthYear: Int, gender: Gender, palaces: [ZiweiPalace]) -> PeriodData {
        let yearStem = HeavenlyStem(rawValue: (currentYear - 4) % 10)!
        let yearBranch = EarthlyBranch(rawValue: (currentYear - 4) % 12)!

        // 流年命宮：以流年地支為命宮所在
        let yearlyMingIndex = fixIndex(yearBranch.rawValue - 2)

        // 歲前/將前十二神
        let gods = calculateYearlyGods(yearBranch: yearBranch.rawValue)

        // 流耀
        let flowStars = getYearlyFlowStars(yearStem: yearStem.rawValue, yearBranch: yearBranch.rawValue)

        return PeriodData(
            index: yearlyMingIndex,
            heavenlyStem: yearStem,
            earthlyBranch: yearBranch,
            palaceNames: palaces.map { $0.name },
            mutagen: yearStem.transformations,
            stars: [],
            flowStars: flowStars,
            suiqian12: gods.suiqian,
            jiangqian12: gods.jiangqian,
            age: currentYear - birthYear,
            startYear: currentYear,
            endYear: currentYear
        )
    }

    // MARK: - 歲前十二神 & 將前十二神

    private func calculateYearlyGods(yearBranch: Int) -> (suiqian: [String], jiangqian: [String]) {
        let suiqianNames = ["歲建", "晦氣", "喪門", "貫索", "官符", "小耗", "大耗", "龍德", "白虎", "天德", "吊客", "病符"]
        let jiangqianNames = ["將星", "攀鞍", "歲驛", "息神", "華蓋", "劫煞", "災煞", "天煞", "指背", "咸池", "月煞", "亡神"]

        // 歲前十二神：從流年地支起，順行
        var suiqian = Array(repeating: "", count: 12)
        let suiqianStart = yearBranch
        for i in 0..<12 {
            let idx = fixIndex(suiqianStart + i)
            // 轉為 palace index (branch - 2)
            let palaceIdx = fixIndex(idx - 2)
            suiqian[palaceIdx] = suiqianNames[i]
        }

        // 將前十二神起始點
        let jiangqianStart: Int
        switch yearBranch {
        case 2, 6, 10: jiangqianStart = 6   // 寅午戌 → 午
        case 8, 0, 4:  jiangqianStart = 0   // 申子辰 → 子
        case 5, 9, 1:  jiangqianStart = 9   // 巳酉丑 → 酉
        case 11, 3, 7: jiangqianStart = 3   // 亥卯未 → 卯
        default: jiangqianStart = 0
        }
        var jiangqian = Array(repeating: "", count: 12)
        for i in 0..<12 {
            let idx = fixIndex(jiangqianStart + i)
            let palaceIdx = fixIndex(idx - 2)
            jiangqian[palaceIdx] = jiangqianNames[i]
        }

        return (suiqian, jiangqian)
    }

    // MARK: - Yearly Flow Stars (流耀)

    private func getYearlyFlowStars(yearStem: Int, yearBranch: Int) -> [[PlacedStar]] {
        var flowStars: [[PlacedStar]] = Array(repeating: [], count: 12)

        // 流魁/流钺 (按年干)
        let kuiYue = getKuiYueIndex(yearlyStem: yearStem)
        flowStars[kuiYue.kuiIndex].append(PlacedStar(name: "流魁", type: "flow"))
        flowStars[kuiYue.yueIndex].append(PlacedStar(name: "流钺", type: "flow"))

        // 流昌/流曲 (按时) — 流年以立春后的时支？简化：用年干起文昌文曲
        // 文昌文曲的年干公式：庚年文昌在亥，其他按年干顺/逆
        // 简化处理：使用 getChangQuIndex 以年支为基准
        let changQu = getChangQuIndex(timeIndex: yearBranch % 12)
        flowStars[changQu.changIndex].append(PlacedStar(name: "流昌", type: "flow"))
        flowStars[changQu.quIndex].append(PlacedStar(name: "流曲", type: "flow"))

        // 流禄/流羊/流陀/流马 (按年干年支)
        let luYangTuoMa = getLuYangTuoMaIndex(yearlyStem: yearStem, yearlyBranch: yearBranch)
        flowStars[luYangTuoMa.luIndex].append(PlacedStar(name: "流祿", type: "flow"))
        flowStars[luYangTuoMa.yangIndex].append(PlacedStar(name: "流羊", type: "flow"))
        flowStars[luYangTuoMa.tuoIndex].append(PlacedStar(name: "流陀", type: "flow"))
        flowStars[luYangTuoMa.maIndex].append(PlacedStar(name: "流馬", type: "flow"))

        // 流鸾/流喜 (按年支)
        let hongluanIndex = fixIndex(3 - 2 - yearBranch)
        flowStars[hongluanIndex].append(PlacedStar(name: "流鸞", type: "flow"))
        flowStars[fixIndex(hongluanIndex + 6)].append(PlacedStar(name: "流喜", type: "flow"))

        return flowStars
    }

    // MARK: - Lunar Date Conversion (simplified)

    private struct LunarDate {
        var year: Int
        var month: Int
        var day: Int
        var isLeap: Bool
    }

    private func lunarFromSolar(year: Int, month: Int, day: Int) -> LunarDate {
        // 西曆 → 農曆轉換
        // 用西曆 calendar 建立西曆日期, 再用農曆 calendar 讀取農曆成分
        let gregorianCalendar = Calendar(identifier: .gregorian)
        let chineseCalendar = Calendar(identifier: .chinese)

        guard let solarDate = gregorianCalendar.date(from: DateComponents(year: year, month: month, day: day)) else {
            return LunarDate(year: year, month: month, day: day, isLeap: false)
        }

        let lunarComponents = chineseCalendar.dateComponents([.era, .year, .month, .day, .isLeapMonth], from: solarDate)
        let era = lunarComponents.era ?? 1
        let yearInCycle = lunarComponents.year ?? 1
        // Apple's Chinese calendar: each era is a 60-year cycle, era 1 year 1 = 甲子年 = 1984
        let lunarYear = 1984 + (era - 1) * 60 + (yearInCycle - 1)
        return LunarDate(
            year: lunarYear,
            month: lunarComponents.month ?? 1,
            day: lunarComponents.day ?? 1,
            isLeap: lunarComponents.isLeapMonth ?? false
        )
    }

    private func formatLunarDate(year: Int, month: Int, day: Int, isLeap: Bool) -> String {
        let chineseNumbers = ["", "一", "二", "三", "四", "五", "六", "七", "八", "九", "十",
                              "十一", "十二"]
        let chineseDays = ["", "初一", "初二", "初三", "初四", "初五", "初六", "初七", "初八", "初九", "初十",
                           "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十",
                           "廿一", "廿二", "廿三", "廿四", "廿五", "廿六", "廿七", "廿八", "廿九", "三十"]

        // 年：天干地支
        let yearStem = HeavenlyStem(rawValue: ((year - 4) % 10 + 10) % 10)!
        let yearBranch = EarthlyBranch(rawValue: ((year - 4) % 12 + 12) % 12)!
        let yearStr = "\(yearStem.displayName)\(yearBranch.displayName)"

        // 月
        let leapPrefix = isLeap ? "閏" : ""
        let monthStr = "\(leapPrefix)\(chineseNumbers[month])月"

        // 日
        let dayStr = chineseDays[day]

        return "\(yearStr) \(monthStr) \(dayStr)"
    }
}
