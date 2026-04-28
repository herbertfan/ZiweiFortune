import Foundation

// MARK: - ZiweiCalculator (Strictly Based on iztro)

final class ZiweiCalculator {
    static let shared = ZiweiCalculator()
    private init() {}

    // MARK: - Constants

    private let heavenlyStems = ["甲", "乙", "丙", "丁", "戊", "己", "庚", "辛", "壬", "癸"]
    private let earthlyBranches = ["子", "丑", "寅", "卯", "辰", "巳", "午", "未", "申", "酉", "戌", "亥"]
    private let palaceNames = ["命宫", "父母宫", "福德宫", "田宅宫", "官禄宫", "交友宫", "迁移宫", "疾厄宫", "财帛宫", "子女宫", "夫妻宫", "兄弟宫"]

    // 五虎遁
    private let tigerRule: [String: String] = [
        "甲": "丙", "乙": "戊", "丙": "庚", "丁": "壬", "戊": "甲",
        "己": "丙", "庚": "戊", "辛": "庚", "壬": "壬", "癸": "甲"
    ]

    // 五鼠遁
    private let ratRule: [String: String] = [
        "甲": "甲", "乙": "丙", "丙": "戊", "丁": "庚", "戊": "壬",
        "己": "甲", "庚": "丙", "辛": "戊", "壬": "庚", "癸": "壬"
    ]

    // 命主 lookup (by 命宫地支)
    private let soulStarMap: [String: String] = [
        "子": "贪狼", "丑": "巨门", "寅": "禄存", "卯": "文曲",
        "辰": "廉贞", "巳": "武曲", "午": "破军", "未": "武曲",
        "申": "廉贞", "酉": "文曲", "戌": "禄存", "亥": "巨门"
    ]

    // 身主 lookup (by 年支)
    private let bodyStarMap: [String: String] = [
        "子": "火星", "丑": "天相", "寅": "天梁", "卯": "天同",
        "辰": "文昌", "巳": "天机", "午": "火星", "未": "天相",
        "申": "天梁", "酉": "天同", "戌": "文昌", "亥": "天机"
    ]

    // MARK: - Brightness Tables (from iztro STARS_INFO, indexed from 寅=0)

    private let starBrightnessTable: [String: [StarBrightness]] = [
        "紫微": [.wang, .wang, .de, .wang, .miao, .miao, .wang, .wang, .de, .wang, .ping, .miao],
        "天机": [.de, .wang, .li, .ping, .miao, .xian, .de, .wang, .li, .ping, .miao, .xian],
        "太阳": [.wang, .miao, .wang, .wang, .wang, .de, .de, .xian, .bu, .xian, .xian, .bu],
        "武曲": [.de, .li, .miao, .ping, .wang, .miao, .de, .li, .miao, .ping, .wang, .miao],
        "天同": [.li, .ping, .ping, .miao, .xian, .bu, .wang, .ping, .ping, .miao, .wang, .bu],
        "廉贞": [.miao, .ping, .li, .xian, .ping, .li, .miao, .ping, .li, .xian, .ping, .li],
        "天府": [.miao, .de, .miao, .de, .wang, .miao, .de, .wang, .miao, .de, .miao, .miao],
        "太阴": [.wang, .xian, .xian, .xian, .bu, .bu, .li, .bu, .wang, .miao, .miao, .miao],
        "贪狼": [.ping, .li, .miao, .xian, .wang, .miao, .ping, .li, .miao, .xian, .wang, .miao],
        "巨门": [.miao, .miao, .xian, .wang, .wang, .bu, .miao, .miao, .xian, .wang, .wang, .bu],
        "天相": [.miao, .xian, .de, .de, .miao, .de, .miao, .xian, .de, .de, .miao, .miao],
        "天梁": [.miao, .miao, .miao, .xian, .miao, .wang, .xian, .de, .miao, .xian, .miao, .wang],
        "七杀": [.miao, .wang, .miao, .ping, .wang, .miao, .miao, .miao, .miao, .ping, .wang, .miao],
        "破军": [.de, .xian, .wang, .ping, .miao, .wang, .de, .xian, .wang, .ping, .miao, .wang],
        "文昌": [.xian, .li, .de, .miao, .xian, .li, .de, .miao, .xian, .li, .de, .miao],
        "文曲": [.ping, .wang, .de, .miao, .xian, .wang, .de, .miao, .xian, .wang, .de, .miao],
        "火星": [.miao, .li, .xian, .de, .miao, .li, .xian, .de, .miao, .li, .xian, .de],
        "铃星": [.miao, .li, .xian, .de, .miao, .li, .xian, .de, .miao, .li, .xian, .de],
        "擎羊": [.ping, .xian, .miao, .ping, .xian, .miao, .ping, .xian, .miao, .ping, .xian, .miao],
        "陀罗": [.xian, .ping, .miao, .xian, .ping, .miao, .xian, .ping, .miao, .xian, .ping, .miao],
    ]

    // MARK: - fixIndex helpers

    private func fixIndex(_ index: Int, max: Int = 12) -> Int {
        var idx = index
        while idx < 0 { idx += max }
        while idx >= max { idx -= max }
        return idx
    }

    private func fixEarthlyBranchIndex(_ branchName: String) -> Int {
        guard let idx = earthlyBranches.firstIndex(of: branchName) else { return 0 }
        return fixIndex(idx - 2)  // 寅 is index 2 in earthlyBranches
    }

    private func palaceBranchIndex(_ palaceIndex: Int) -> Int {
        return fixIndex(palaceIndex + 2)  // palace 0 = 寅 (index 2)
    }

    // MARK: - Main entry

    func calculateChart(
        birthYear: Int,
        birthMonth: Int,
        birthDay: Int,
        birthHour: Int,
        gender: Gender,
        isLeapMonth: Bool = false
    ) -> ZiweiChart {
        let solarDate = "\(birthYear)-\(birthMonth)-\(birthDay)"
        let timeIndex = birthHour  // 0~11, 子~亥

        // Lunar date
        let lunar = lunarFromSolar(year: birthYear, month: birthMonth, day: birthDay)
        let lunarMonth = lunar.month
        let lunarDay = lunar.day

        // Four pillars
        let fourPillars = calculateFourPillars(
            solarYear: birthYear, solarMonth: birthMonth, solarDay: birthDay,
            hour: birthHour, lunarMonth: lunarMonth
        )

        let yearStemName = heavenlyStems[fourPillars.year.heavenlyStem.rawValue]
        let yearBranchName = earthlyBranches[fourPillars.year.earthlyBranch.rawValue]

        // Soul and body
        let soulBody = getSoulAndBody(
            lunarMonth: lunarMonth, timeIndex: timeIndex, yearStemName: yearStemName
        )
        let mingGongIndex = soulBody.soulIndex
        let shenGongIndex = soulBody.bodyIndex
        let heavenlyStemOfSoul = soulBody.heavenlyStemOfSoul
        let earthlyBranchOfSoul = soulBody.earthlyBranchOfSoul

        // Five elements class
        let wuXingJu = getFiveElementsClass(
            heavenlyStem: heavenlyStemOfSoul, earthlyBranch: earthlyBranchOfSoul
        )

        // Arrange 12 palaces
        var palaces = arrangePalaces(
            mingGongIndex: mingGongIndex, shenGongIndex: shenGongIndex,
            yearStemName: yearStemName, heavenlyStemOfSoul: heavenlyStemOfSoul
        )

        // Place major stars
        let startIndex = getStartIndex(
            lunarDay: lunarDay, wuXingJu: wuXingJu
        )
        palaces = placeMajorStars(
            palaces: palaces, ziweiIndex: startIndex.ziweiIndex,
            tianfuIndex: startIndex.tianfuIndex, yearStemName: yearStemName
        )

        // Place minor stars
        palaces = placeMinorStars(
            palaces: palaces, yearStemName: yearStemName, yearBranchName: yearBranchName,
            timeIndex: timeIndex, lunarMonth: lunarMonth
        )

        // Place adjective stars
        palaces = placeAdjectiveStars(
            palaces: palaces, solarDate: solarDate, timeIndex: timeIndex,
            yearStemName: yearStemName, yearBranchName: yearBranchName,
            dayStemName: heavenlyStems[fourPillars.day.heavenlyStem.rawValue],
            mingGongIndex: mingGongIndex, gender: gender, fixLeap: true
        )

        // Place transformations (四化)
        palaces = placeTransformations(
            palaces: palaces, yearStemName: yearStemName
        )

        // Place changsheng12
        let changsheng12 = getChangSheng12(
            wuXingJu: wuXingJu, yearBranchName: yearBranchName, gender: gender
        )
        for i in 0..<12 {
            palaces[i].changsheng12 = changsheng12[i]
            palaces[i].changsheng12Name = changshengName(for: changsheng12[i])
        }

        // Place boshi12
        let boshi12 = getBoShi12(
            palaces: palaces, yearStemName: yearStemName, gender: gender
        )
        for i in 0..<12 {
            palaces[i].boshi12 = boshi12[i]
            palaces[i].boshi12Name = boshiName(for: boshi12[i])
        }

        // Ages (小限)
        let ages = calculateAges(yearBranchName: yearBranchName, gender: gender)
        for i in 0..<12 {
            palaces[i].ages = ages[i]
        }

        // Decadal ranges (大限)
        palaces = assignDecadalRanges(
            palaces: palaces, mingGongIndex: mingGongIndex,
            wuXingJu: wuXingJu, yearStemName: yearStemName, gender: gender
        )

        // Yearly12 (suiqian + jiangqian) for natal chart
        let yearly12 = getYearly12(yearBranchName: yearBranchName)
        for i in 0..<12 {
            palaces[i].suiqian12 = yearly12.suiqian[i]
            palaces[i].jiangqian12 = yearly12.jiangqian[i]
        }

        // Soul / Body
        let soulStar = soulStarMap[earthlyBranchOfSoul] ?? ""
        let bodyStar = bodyStarMap[yearBranchName] ?? ""

        // Horoscope
        let horoscope = calculateHoroscope(
            palaces: palaces, mingGongIndex: mingGongIndex,
            yearStemName: yearStemName, birthYear: birthYear, gender: gender
        )

        return ZiweiChart(
            solarDate: solarDate,
            lunarDate: formatLunarDate(year: lunar.year, month: lunar.month, day: lunar.day, isLeap: lunar.isLeap),
            fourPillars: fourPillars,
            wuXingJu: wuXingJu,
            mingGongIndex: mingGongIndex,
            shenGongIndex: shenGongIndex,
            palaces: palaces,
            horoscope: horoscope,
            gender: gender,
            birthHour: birthHour,
            soul: soulStar,
            body: bodyStar,
            lunarMonth: lunar.month,
            lunarDay: lunar.day,
            createdAt: Date()
        )
    }

    // MARK: - Lunar Date Conversion

    private struct LunarDate {
        var year: Int
        var month: Int
        var day: Int
        var isLeap: Bool
    }

    private func lunarFromSolar(year: Int, month: Int, day: Int) -> LunarDate {
        let gregorianCalendar = Calendar(identifier: .gregorian)
        let chineseCalendar = Calendar(identifier: .chinese)

        guard let solarDate = gregorianCalendar.date(from: DateComponents(year: year, month: month, day: day)) else {
            return LunarDate(year: year, month: month, day: day, isLeap: false)
        }

        let lunarComponents = chineseCalendar.dateComponents([.era, .year, .month, .day, .isLeapMonth], from: solarDate)
        let era = lunarComponents.era ?? 1
        let yearInCycle = lunarComponents.year ?? 1
        let lunarYear = 1984 + (era - 1) * 60 + (yearInCycle - 1)
        return LunarDate(
            year: lunarYear,
            month: lunarComponents.month ?? 1,
            day: lunarComponents.day ?? 1,
            isLeap: lunarComponents.isLeapMonth ?? false
        )
    }

    private func formatLunarDate(year: Int, month: Int, day: Int, isLeap: Bool) -> String {
        let chineseNumbers = ["", "一", "二", "三", "四", "五", "六", "七", "八", "九", "十", "十一", "十二"]
        let chineseDays = ["", "初一", "初二", "初三", "初四", "初五", "初六", "初七", "初八", "初九", "初十",
                           "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十",
                           "廿一", "廿二", "廿三", "廿四", "廿五", "廿六", "廿七", "廿八", "廿九", "三十"]
        let yearStem = heavenlyStems[((year - 4) % 10 + 10) % 10]
        let yearBranch = earthlyBranches[((year - 4) % 12 + 12) % 12]
        let leapPrefix = isLeap ? "闰" : ""
        return "\(yearStem)\(yearBranch)年 \(leapPrefix)\(chineseNumbers[month])月 \(chineseDays[day])"
    }

    // MARK: - Four Pillars

    private func isBeforeLiChun(month: Int, day: Int) -> Bool {
        if month < 2 { return true }
        if month == 2 && day < 4 { return true }
        return false
    }

    private func calculateFourPillars(solarYear: Int, solarMonth: Int, solarDay: Int, hour: Int, lunarMonth: Int) -> FourPillars {
        let effectiveYear = isBeforeLiChun(month: solarMonth, day: solarDay) ? solarYear - 1 : solarYear
        let yearStemIndex = ((effectiveYear - 4) % 10 + 10) % 10
        let yearBranchIndex = ((effectiveYear - 4) % 12 + 12) % 12
        let yearStem = HeavenlyStem(rawValue: yearStemIndex)!
        let yearBranch = EarthlyBranch(rawValue: yearBranchIndex)!

        // Month pillar: 五虎遁
        let tigerOffset = getTigerRuleOffset(for: yearStem)
        let monthStemIndex = (tigerOffset + lunarMonth - 1) % 10
        let monthStem = HeavenlyStem(rawValue: monthStemIndex)!
        let monthBranchIndex = (lunarMonth + 1) % 12
        let monthBranch = EarthlyBranch(rawValue: monthBranchIndex)!

        // Day pillar: Julian day from 1900-01-01 (甲戌日)
        let dayPair = getDayStemAndBranch(year: solarYear, month: solarMonth, day: solarDay)

        // Hour pillar: 五鼠遁
        let hourPair = getHourStemAndBranch(dayStem: dayPair.heavenlyStem, hour: hour)

        return FourPillars(
            year: StemBranch(heavenlyStem: yearStem, earthlyBranch: yearBranch),
            month: StemBranch(heavenlyStem: monthStem, earthlyBranch: monthBranch),
            day: dayPair,
            hour: hourPair
        )
    }

    private func getTigerRuleOffset(for yearStem: HeavenlyStem) -> Int {
        switch yearStem {
        case .jia, .ji: return 2   // 丙寅
        case .yi, .geng: return 4  // 戊寅
        case .bing, .xin: return 6 // 庚寅
        case .ding, .ren: return 8 // 壬寅
        case .wu, .gui: return 0   // 甲寅
        }
    }

    private func getDayStemAndBranch(year: Int, month: Int, day: Int) -> StemBranch {
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
        let hourIndex = hour % 12
        let ratRuleOffset: [HeavenlyStem: Int] = [
            .jia: 0, .yi: 2, .bing: 4, .ding: 6, .wu: 8,
            .ji: 0, .geng: 2, .xin: 4, .ren: 6, .gui: 8
        ]
        let stemIndex = (ratRuleOffset[dayStem]! + hourIndex) % 10
        let branchIndex = hourIndex
        return StemBranch(
            heavenlyStem: HeavenlyStem(rawValue: stemIndex)!,
            earthlyBranch: EarthlyBranch(rawValue: branchIndex)!
        )
    }

    // MARK: - Soul and Body

    private struct SoulAndBodyResult {
        let soulIndex: Int
        let bodyIndex: Int
        let heavenlyStemOfSoul: String
        let earthlyBranchOfSoul: String
    }

    private func getSoulAndBody(lunarMonth: Int, timeIndex: Int, yearStemName: String) -> SoulAndBodyResult {
        // fixLunarMonthIndex: 正月建寅
        let monthIndex = fixIndex(lunarMonth - 1)  // palace index of lunar month (寅=0)
        let timeBranchIndex = timeIndex % 12

        // 命宫 = 生月索引 - 时辰索引 (逆时针)
        let soulIndex = fixIndex(monthIndex - timeBranchIndex)
        // 身宫 = 生月索引 + 时辰索引 (顺时针)
        let bodyIndex = fixIndex(monthIndex + timeBranchIndex)

        // 五虎遁取寅宫天干
        let startStemName = tigerRule[yearStemName] ?? "丙"
        guard let startStemIdx = heavenlyStems.firstIndex(of: startStemName) else {
            return SoulAndBodyResult(soulIndex: 0, bodyIndex: 0, heavenlyStemOfSoul: "甲", earthlyBranchOfSoul: "寅")
        }

        // 命宫天干
        let heavenlyStemOfSoulIndex = fixIndex(startStemIdx + soulIndex, max: 10)
        let heavenlyStemOfSoul = heavenlyStems[heavenlyStemOfSoulIndex]

        // 命宫地支
        let earthlyBranchOfSoulIndex = fixIndex(soulIndex + 2)
        let earthlyBranchOfSoul = earthlyBranches[earthlyBranchOfSoulIndex]

        return SoulAndBodyResult(
            soulIndex: soulIndex,
            bodyIndex: bodyIndex,
            heavenlyStemOfSoul: heavenlyStemOfSoul,
            earthlyBranchOfSoul: earthlyBranchOfSoul
        )
    }

    // MARK: - Five Elements Class

    private func getFiveElementsClass(heavenlyStem: String, earthlyBranch: String) -> WuXingJu {
        let stemNumber: Int
        switch heavenlyStem {
        case "甲", "乙": stemNumber = 1
        case "丙", "丁": stemNumber = 2
        case "戊", "己": stemNumber = 3
        case "庚", "辛": stemNumber = 4
        case "壬", "癸": stemNumber = 5
        default: stemNumber = 1
        }

        let branchNumber: Int
        switch earthlyBranch {
        case "子", "午", "丑", "未": branchNumber = 1
        case "寅", "申", "卯", "酉": branchNumber = 2
        case "辰", "戌", "巳", "亥": branchNumber = 3
        default: branchNumber = 1
        }

        var index = stemNumber + branchNumber
        while index > 5 { index -= 5 }

        switch index {
        case 1: return .muSan
        case 2: return .jinSi
        case 3: return .shuiEr
        case 4: return .huoLiu
        case 5: return .tuWu
        default: return .tuWu
        }
    }

    // MARK: - Arrange 12 Palaces

    private func arrangePalaces(mingGongIndex: Int, shenGongIndex: Int, yearStemName: String, heavenlyStemOfSoul: String) -> [ZiweiPalace] {
        var palaces: [ZiweiPalace] = []

        let startStemName = tigerRule[yearStemName] ?? "丙"
        guard let startStemIdx = heavenlyStems.firstIndex(of: startStemName) else { return palaces }

        for i in 0..<12 {
            let palaceIndex = fixIndex(i - mingGongIndex)
            let stemIndex = fixIndex(startStemIdx + i, max: 10)
            let branchIndex = fixIndex(i + 2)

            let palaceName = palaceNames[palaceIndex]
            let heavenlyStem = HeavenlyStem(rawValue: stemIndex)!
            let earthlyBranch = EarthlyBranch(rawValue: branchIndex)!

            // 来因宫: 宫干 == 年干, 且地支不是子/丑
            let isOriginal = (stemIndex == heavenlyStems.firstIndex(of: yearStemName)) && (branchIndex != 0) && (branchIndex != 1)

            palaces.append(ZiweiPalace(
                name: palaceName,
                index: i,
                isOriginalPalace: isOriginal,
                isBodyPalace: i == shenGongIndex,
                heavenlyStem: heavenlyStem,
                earthlyBranch: earthlyBranch
            ))
        }

        return palaces
    }

    // MARK: - Start Index (紫微/天府定位)

    private struct StartIndex {
        let ziweiIndex: Int
        let tianfuIndex: Int
    }

    private func getStartIndex(lunarDay: Int, wuXingJu: WuXingJu) -> StartIndex {
        let fiveElementsValue = wuXingJu.value

        var offset = 0
        var divisor = lunarDay
        while divisor % fiveElementsValue != 0 {
            offset += 1
            divisor = lunarDay + offset
        }

        let quotient = (divisor / fiveElementsValue) % 12
        var ziweiIndex = quotient - 1

        if offset % 2 == 0 {
            ziweiIndex += offset
        } else {
            ziweiIndex -= offset
        }

        ziweiIndex = fixIndex(ziweiIndex)
        let tianfuIndex = fixIndex(12 - ziweiIndex)

        return StartIndex(ziweiIndex: ziweiIndex, tianfuIndex: tianfuIndex)
    }

    // MARK: - Place Major Stars

    private func placeMajorStars(palaces: [ZiweiPalace], ziweiIndex: Int, tianfuIndex: Int, yearStemName: String) -> [ZiweiPalace] {
        var result = palaces

        // 紫微星系 (逆时针)
        let ziweiGroup = [
            ("紫微", ziweiIndex),
            ("天机", fixIndex(ziweiIndex - 1)),
            ("", -1),
            ("太阳", fixIndex(ziweiIndex - 3)),
            ("武曲", fixIndex(ziweiIndex - 4)),
            ("天同", fixIndex(ziweiIndex - 5)),
            ("", -1),
            ("", -1),
            ("廉贞", fixIndex(ziweiIndex - 8))
        ]

        for (name, index) in ziweiGroup {
            if name.isEmpty || index < 0 { continue }
            let brightness = brightnessForStar(name, palaceIndex: index)
            let mutagen = mutagenForStar(name, yearStemName: yearStemName)
            result[index].majorStars.append(PlacedStar(
                name: name, type: "major", brightness: brightness,
                scope: "origin", transformation: mutagen
            ))
        }

        // 天府星系 (顺时针)
        let tianfuGroup = [
            ("天府", tianfuIndex),
            ("太阴", fixIndex(tianfuIndex + 1)),
            ("贪狼", fixIndex(tianfuIndex + 2)),
            ("巨门", fixIndex(tianfuIndex + 3)),
            ("天相", fixIndex(tianfuIndex + 4)),
            ("天梁", fixIndex(tianfuIndex + 5)),
            ("七杀", fixIndex(tianfuIndex + 6)),
            ("", -1),
            ("", -1),
            ("", -1),
            ("破军", fixIndex(tianfuIndex + 10))
        ]

        for (name, index) in tianfuGroup {
            if name.isEmpty || index < 0 { continue }
            let brightness = brightnessForStar(name, palaceIndex: index)
            let mutagen = mutagenForStar(name, yearStemName: yearStemName)
            result[index].majorStars.append(PlacedStar(
                name: name, type: "major", brightness: brightness,
                scope: "origin", transformation: mutagen
            ))
        }

        return result
    }

    // MARK: - Brightness & Mutagen Helpers

    private func brightnessForStar(_ starName: String, palaceIndex: Int) -> StarBrightness {
        guard let table = starBrightnessTable[starName] else { return .ping }
        return table[fixIndex(palaceIndex)]
    }

    private func simplifiedName(for star: TransformationStar) -> String {
        switch star {
        case .lian:   return "廉贞"
        case .po:     return "破军"
        case .wu:     return "武曲"
        case .yang:   return "太阳"
        case .ji:     return "天机"
        case .liang:  return "天梁"
        case .zi:     return "紫微"
        case .yin:    return "太阴"
        case .tong:   return "天同"
        case .chang:  return "文昌"
        case .ju:     return "巨门"
        case .tan:    return "贪狼"
        case .you:    return "右弼"
        case .qu:     return "文曲"
        case .zu:     return "左辅"
        }
    }

    private func mutagenForStar(_ starName: String, yearStemName: String) -> String? {
        guard let stemIdx = heavenlyStems.firstIndex(of: yearStemName),
              let stem = HeavenlyStem(rawValue: stemIdx) else { return nil }
        let transformations = stem.transformations
        let transTypes = ["禄", "权", "科", "忌"]
        for (i, transStar) in transformations.enumerated() {
            if simplifiedName(for: transStar) == starName {
                return transTypes[i]
            }
        }
        return nil
    }

    // MARK: - Place Minor Stars

    private func placeMinorStars(palaces: [ZiweiPalace], yearStemName: String, yearBranchName: String, timeIndex: Int, lunarMonth: Int) -> [ZiweiPalace] {
        var result = palaces

        // 禄存、擎羊、陀罗、天马
        let luYangTuoMa = getLuYangTuoMaIndex(yearStemName: yearStemName, yearBranchName: yearBranchName)
        result[luYangTuoMa.luIndex].minorStars.append(PlacedStar(
            name: "禄存", type: "lucun", brightness: brightnessForStar("禄存", palaceIndex: luYangTuoMa.luIndex)
        ))
        result[luYangTuoMa.yangIndex].minorStars.append(PlacedStar(
            name: "擎羊", type: "tough", brightness: brightnessForStar("擎羊", palaceIndex: luYangTuoMa.yangIndex)
        ))
        result[luYangTuoMa.tuoIndex].minorStars.append(PlacedStar(
            name: "陀罗", type: "tough", brightness: brightnessForStar("陀罗", palaceIndex: luYangTuoMa.tuoIndex)
        ))
        result[luYangTuoMa.maIndex].minorStars.append(PlacedStar(
            name: "天马", type: "tianma", brightness: .ping
        ))

        // 左辅、右弼
        let zuoYou = getZuoYouIndex(lunarMonth: lunarMonth)
        result[zuoYou.zuoIndex].minorStars.append(PlacedStar(name: "左辅", type: "soft", brightness: .ping))
        result[zuoYou.youIndex].minorStars.append(PlacedStar(name: "右弼", type: "soft", brightness: .ping))

        // 文昌、文曲
        let changQu = getChangQuIndex(timeIndex: timeIndex)
        result[changQu.changIndex].minorStars.append(PlacedStar(
            name: "文昌", type: "soft", brightness: brightnessForStar("文昌", palaceIndex: changQu.changIndex)
        ))
        result[changQu.quIndex].minorStars.append(PlacedStar(
            name: "文曲", type: "soft", brightness: brightnessForStar("文曲", palaceIndex: changQu.quIndex)
        ))

        // 天魁、天钺
        let kuiYue = getKuiYueIndex(yearStemName: yearStemName)
        result[kuiYue.kuiIndex].minorStars.append(PlacedStar(name: "天魁", type: "soft", brightness: .ping))
        result[kuiYue.yueIndex].minorStars.append(PlacedStar(name: "天钺", type: "soft", brightness: .ping))

        // 地空、地劫
        let kongJie = getKongJieIndex(timeIndex: timeIndex)
        result[kongJie.kongIndex].minorStars.append(PlacedStar(name: "地空", type: "tough", brightness: .xian))
        result[kongJie.jieIndex].minorStars.append(PlacedStar(name: "地劫", type: "tough", brightness: .xian))

        // 火星、铃星
        let huoLing = getHuoLingIndex(yearBranchName: yearBranchName, timeIndex: timeIndex)
        result[huoLing.huoIndex].minorStars.append(PlacedStar(
            name: "火星", type: "tough", brightness: brightnessForStar("火星", palaceIndex: huoLing.huoIndex)
        ))
        result[huoLing.lingIndex].minorStars.append(PlacedStar(
            name: "铃星", type: "tough", brightness: brightnessForStar("铃星", palaceIndex: huoLing.lingIndex)
        ))

        return result
    }

    // MARK: - Minor Star Location Functions

    private struct LuYangTuoMaIndex {
        let luIndex: Int
        let yangIndex: Int
        let tuoIndex: Int
        let maIndex: Int
    }

    private func getLuYangTuoMaIndex(yearStemName: String, yearBranchName: String) -> LuYangTuoMaIndex {
        // 天马 (按年支)
        let maIndex: Int
        switch yearBranchName {
        case "寅", "午", "戌": maIndex = fixEarthlyBranchIndex("申")
        case "申", "子", "辰": maIndex = fixEarthlyBranchIndex("寅")
        case "巳", "酉", "丑": maIndex = fixEarthlyBranchIndex("亥")
        case "亥", "卯", "未": maIndex = fixEarthlyBranchIndex("巳")
        default: maIndex = 0
        }

        // 禄存 (按年干)
        let luIndex: Int
        switch yearStemName {
        case "甲": luIndex = fixEarthlyBranchIndex("寅")
        case "乙": luIndex = fixEarthlyBranchIndex("卯")
        case "丙", "戊": luIndex = fixEarthlyBranchIndex("巳")
        case "丁", "己": luIndex = fixEarthlyBranchIndex("午")
        case "庚": luIndex = fixEarthlyBranchIndex("申")
        case "辛": luIndex = fixEarthlyBranchIndex("酉")
        case "壬": luIndex = fixEarthlyBranchIndex("亥")
        case "癸": luIndex = fixEarthlyBranchIndex("子")
        default: luIndex = 0
        }

        return LuYangTuoMaIndex(
            luIndex: luIndex,
            yangIndex: fixIndex(luIndex + 1),
            tuoIndex: fixIndex(luIndex - 1),
            maIndex: maIndex
        )
    }

    private struct ZuoYouIndex {
        let zuoIndex: Int
        let youIndex: Int
    }

    private func getZuoYouIndex(lunarMonth: Int) -> ZuoYouIndex {
        let chenIndex = fixEarthlyBranchIndex("辰")
        let xuIndex = fixEarthlyBranchIndex("戌")
        let zuoIndex = fixIndex(chenIndex + (lunarMonth - 1))
        let youIndex = fixIndex(xuIndex - (lunarMonth - 1))
        return ZuoYouIndex(zuoIndex: zuoIndex, youIndex: youIndex)
    }

    private struct ChangQuIndex {
        let changIndex: Int
        let quIndex: Int
    }

    private func getChangQuIndex(timeIndex: Int) -> ChangQuIndex {
        let chenIndex = fixEarthlyBranchIndex("辰")
        let xuIndex = fixEarthlyBranchIndex("戌")
        let quIndex = fixIndex(chenIndex + timeIndex)
        let changIndex = fixIndex(xuIndex - timeIndex)
        return ChangQuIndex(changIndex: changIndex, quIndex: quIndex)
    }

    private struct KuiYueIndex {
        let kuiIndex: Int
        let yueIndex: Int
    }

    private func getKuiYueIndex(yearStemName: String) -> KuiYueIndex {
        switch yearStemName {
        case "甲", "戊", "庚":
            return KuiYueIndex(kuiIndex: fixEarthlyBranchIndex("丑"), yueIndex: fixEarthlyBranchIndex("未"))
        case "乙", "己":
            return KuiYueIndex(kuiIndex: fixEarthlyBranchIndex("子"), yueIndex: fixEarthlyBranchIndex("申"))
        case "辛":
            return KuiYueIndex(kuiIndex: fixEarthlyBranchIndex("午"), yueIndex: fixEarthlyBranchIndex("寅"))
        case "丙", "丁":
            return KuiYueIndex(kuiIndex: fixEarthlyBranchIndex("亥"), yueIndex: fixEarthlyBranchIndex("酉"))
        case "壬", "癸":
            return KuiYueIndex(kuiIndex: fixEarthlyBranchIndex("卯"), yueIndex: fixEarthlyBranchIndex("巳"))
        default:
            return KuiYueIndex(kuiIndex: 0, yueIndex: 0)
        }
    }

    private struct KongJieIndex {
        let kongIndex: Int
        let jieIndex: Int
    }

    private func getKongJieIndex(timeIndex: Int) -> KongJieIndex {
        let haiIndex = fixEarthlyBranchIndex("亥")
        return KongJieIndex(
            kongIndex: fixIndex(haiIndex - timeIndex),
            jieIndex: fixIndex(haiIndex + timeIndex)
        )
    }

    private struct HuoLingIndex {
        let huoIndex: Int
        let lingIndex: Int
    }

    private func getHuoLingIndex(yearBranchName: String, timeIndex: Int) -> HuoLingIndex {
        switch yearBranchName {
        case "寅", "午", "戌":
            return HuoLingIndex(
                huoIndex: fixIndex(fixEarthlyBranchIndex("丑") + timeIndex),
                lingIndex: fixIndex(fixEarthlyBranchIndex("卯") + timeIndex)
            )
        case "申", "子", "辰":
            return HuoLingIndex(
                huoIndex: fixIndex(fixEarthlyBranchIndex("寅") + timeIndex),
                lingIndex: fixIndex(fixEarthlyBranchIndex("戌") + timeIndex)
            )
        case "巳", "酉", "丑":
            return HuoLingIndex(
                huoIndex: fixIndex(fixEarthlyBranchIndex("卯") + timeIndex),
                lingIndex: fixIndex(fixEarthlyBranchIndex("戌") + timeIndex)
            )
        case "亥", "卯", "未":
            return HuoLingIndex(
                huoIndex: fixIndex(fixEarthlyBranchIndex("酉") + timeIndex),
                lingIndex: fixIndex(fixEarthlyBranchIndex("戌") + timeIndex)
            )
        default:
            return HuoLingIndex(huoIndex: 0, lingIndex: 0)
        }
    }

    // MARK: - Place Adjective Stars

    private func placeAdjectiveStars(palaces: [ZiweiPalace], solarDate: String, timeIndex: Int, yearStemName: String, yearBranchName: String, dayStemName: String, mingGongIndex: Int, gender: Gender, fixLeap: Bool) -> [ZiweiPalace] {
        var result = palaces

        // Helper to find palace containing a star
        func findPalaceIndex(starName: String, in starLists: [[PlacedStar]]) -> Int? {
            for (i, list) in starLists.enumerated() {
                if list.contains(where: { $0.name == starName }) { return i }
            }
            return nil
        }
        let allMinorStars = result.map { $0.minorStars }

        // 年系星
        // 红鸾、天喜
        let hongluanIndex = fixIndex(fixEarthlyBranchIndex("卯") - earthlyBranches.firstIndex(of: yearBranchName)!)
        result[hongluanIndex].adjectiveStars.append(PlacedStar(name: "红鸾", type: "flower"))
        result[fixIndex(hongluanIndex + 6)].adjectiveStars.append(PlacedStar(name: "天喜", type: "flower"))

        // 龙池、凤阁
        let yearBranchIdx = earthlyBranches.firstIndex(of: yearBranchName) ?? 0
        result[fixIndex(fixEarthlyBranchIndex("辰") + yearBranchIdx)].adjectiveStars.append(PlacedStar(name: "龙池", type: "adjective"))
        result[fixIndex(fixEarthlyBranchIndex("戌") - yearBranchIdx)].adjectiveStars.append(PlacedStar(name: "凤阁", type: "adjective"))

        // 华盖、咸池
        let (huagaiBranchIdx, xianchiBranchIdx) = huagaiXianchiBranches(yearBranchName: yearBranchName)
        result[huagaiBranchIdx].adjectiveStars.append(PlacedStar(name: "华盖", type: "adjective"))
        result[xianchiBranchIdx].adjectiveStars.append(PlacedStar(name: "咸池", type: "adjective"))

        // 孤辰、寡宿
        let (guchenBranchIdx, guasuBranchIdx) = guchenGuasuBranches(yearBranchName: yearBranchName)
        result[guchenBranchIdx].adjectiveStars.append(PlacedStar(name: "孤辰", type: "adjective"))
        result[guasuBranchIdx].adjectiveStars.append(PlacedStar(name: "寡宿", type: "adjective"))

        // 天才、天寿
        result[fixIndex(mingGongIndex + yearBranchIdx)].adjectiveStars.append(PlacedStar(name: "天才", type: "adjective"))
        result[fixIndex(shenGongIndex(for: result) + yearBranchIdx)].adjectiveStars.append(PlacedStar(name: "天寿", type: "adjective"))

        // 天哭、天虚
        result[fixIndex(fixEarthlyBranchIndex("午") - yearBranchIdx)].adjectiveStars.append(PlacedStar(name: "天哭", type: "adjective"))
        result[fixIndex(fixEarthlyBranchIndex("午") + yearBranchIdx)].adjectiveStars.append(PlacedStar(name: "天虚", type: "adjective"))

        // 劫杀
        let jieshaOffsets: [String: Int] = [
            "申": 3, "子": 3, "辰": 3,
            "亥": 6, "卯": 6, "未": 6,
            "寅": 9, "午": 9, "戌": 9,
            "巳": 0, "酉": 0, "丑": 0
        ]
        if let jieshaOffset = jieshaOffsets[yearBranchName] {
            result[fixIndex(yearBranchIdx + jieshaOffset)].adjectiveStars.append(PlacedStar(name: "劫杀", type: "adjective"))
        }

        // 大耗
        let dahaoMapping: [String: String] = [
            "子": "未", "丑": "午", "寅": "酉", "卯": "申",
            "辰": "亥", "巳": "戌", "午": "丑", "未": "子",
            "申": "卯", "酉": "寅", "戌": "巳", "亥": "辰"
        ]
        if let dahaoBranch = dahaoMapping[yearBranchName] {
            result[fixEarthlyBranchIndex(dahaoBranch)].adjectiveStars.append(PlacedStar(name: "大耗", type: "adjective"))
        }

        // 天德、月德
        result[fixIndex(fixEarthlyBranchIndex("酉") + yearBranchIdx)].adjectiveStars.append(PlacedStar(name: "天德", type: "adjective"))
        result[fixIndex(fixEarthlyBranchIndex("巳") + yearBranchIdx)].adjectiveStars.append(PlacedStar(name: "月德", type: "adjective"))

        // 天空 (生年支顺数前一位)
        result[fixIndex(yearBranchIdx + 1)].adjectiveStars.append(PlacedStar(name: "天空", type: "adjective"))

        // 年解
        result[fixIndex(fixEarthlyBranchIndex("戌") - yearBranchIdx)].adjectiveStars.append(PlacedStar(name: "年解", type: "helper"))

        // 蜚蠊
        let feilianBranches = ["申", "酉", "戌", "巳", "午", "未", "寅", "卯", "辰", "亥", "子", "丑"]
        result[fixEarthlyBranchIndex(feilianBranches[yearBranchIdx])].adjectiveStars.append(PlacedStar(name: "蜚廉", type: "adjective"))

        // 破碎
        let posuiBranches = ["巳", "丑", "酉"]
        result[fixEarthlyBranchIndex(posuiBranches[yearBranchIdx % 3])].adjectiveStars.append(PlacedStar(name: "破碎", type: "adjective"))

        // 截路空亡 (按年干)
        let jieluBranches: [String: String] = [
            "甲": "申", "乙": "午", "丙": "辰", "丁": "寅", "戊": "子",
            "己": "申", "庚": "午", "辛": "辰", "壬": "寅", "癸": "子"
        ]
        let kongwangBranches: [String: String] = [
            "甲": "酉", "乙": "未", "丙": "巳", "丁": "卯", "戊": "丑",
            "己": "酉", "庚": "未", "辛": "巳", "壬": "卯", "癸": "丑"
        ]
        if let jl = jieluBranches[yearStemName], let kw = kongwangBranches[yearStemName] {
            result[fixEarthlyBranchIndex(jl)].adjectiveStars.append(PlacedStar(name: "截路", type: "adjective"))
            result[fixEarthlyBranchIndex(kw)].adjectiveStars.append(PlacedStar(name: "空亡", type: "adjective"))
        }

        // 天厨 (按年干)
        let tianchuMap: [String: String] = [
            "甲": "巳", "乙": "午", "丙": "子", "丁": "巳", "戊": "午",
            "己": "申", "庚": "寅", "辛": "午", "壬": "酉", "癸": "亥"
        ]
        if let tc = tianchuMap[yearStemName] {
            result[fixEarthlyBranchIndex(tc)].adjectiveStars.append(PlacedStar(name: "天厨", type: "adjective"))
        }

        // 天官 (按年干)
        let tianguanMap: [String: String] = [
            "甲": "未", "乙": "辰", "丙": "巳", "丁": "寅", "戊": "卯",
            "己": "酉", "庚": "亥", "辛": "酉", "壬": "戌", "癸": "午"
        ]
        if let tg = tianguanMap[yearStemName] {
            result[fixEarthlyBranchIndex(tg)].adjectiveStars.append(PlacedStar(name: "天官", type: "adjective"))
        }

        // 天福 (按年干)
        let tianfuMap: [String: String] = [
            "甲": "酉", "乙": "申", "丙": "子", "丁": "亥", "戊": "卯",
            "己": "寅", "庚": "午", "辛": "巳", "壬": "午", "癸": "巳"
        ]
        if let tf = tianfuMap[yearStemName] {
            result[fixEarthlyBranchIndex(tf)].adjectiveStars.append(PlacedStar(name: "天福", type: "adjective"))
        }

        // 旬空 (按年干年支)
        let stemIdx = heavenlyStems.firstIndex(of: yearStemName) ?? 0
        let xunkongBase = fixIndex(yearBranchIdx + 9 - stemIdx + 1)
        let xunkongIndex = (yearBranchIdx % 2) != (xunkongBase % 2) ? fixIndex(xunkongBase + 1) : xunkongBase
        result[xunkongIndex].adjectiveStars.append(PlacedStar(name: "旬空", type: "adjective"))

        // 天伤、天使 (按命宫/性别)
        let yearBranchYinYang = yearBranchIdx % 2 == 0  // 子寅辰午申戌 = 阳
        let isMale = gender == .male
        var tianshangIndex = fixIndex(mingGongIndex + 5)  // 交友宫
        var tianshiIndex = fixIndex(mingGongIndex + 7)    // 疾厄宫
        if yearBranchYinYang != isMale {
            (tianshangIndex, tianshiIndex) = (tianshiIndex, tianshangIndex)
        }
        result[tianshangIndex].adjectiveStars.append(PlacedStar(name: "天伤", type: "adjective"))
        result[tianshiIndex].adjectiveStars.append(PlacedStar(name: "天使", type: "adjective"))

        // 月系星
        let lunarMonth = lunarFromSolarDate(solarDate).month
        let monthIndex = lunarMonth - 1  // 0-based month index

        // 天姚 (从丑宫起正月)
        result[fixIndex(fixEarthlyBranchIndex("丑") + monthIndex)].adjectiveStars.append(PlacedStar(name: "天姚", type: "adjective"))

        // 天刑 (从酉宫起正月)
        result[fixIndex(fixEarthlyBranchIndex("酉") + monthIndex)].adjectiveStars.append(PlacedStar(name: "天刑", type: "adjective"))

        // 阴煞
        let yinshaBranches = ["寅", "子", "戌", "申", "午", "辰"]
        result[fixEarthlyBranchIndex(yinshaBranches[monthIndex % 6])].adjectiveStars.append(PlacedStar(name: "阴煞", type: "adjective"))

        // 天月
        let tianyueBranches = ["戌", "巳", "辰", "寅", "未", "卯", "亥", "未", "寅", "午", "戌", "寅"]
        result[fixEarthlyBranchIndex(tianyueBranches[monthIndex])].adjectiveStars.append(PlacedStar(name: "天月", type: "adjective"))

        // 天巫
        let tianwuBranches = ["巳", "申", "寅", "亥"]
        result[fixEarthlyBranchIndex(tianwuBranches[monthIndex % 4])].adjectiveStars.append(PlacedStar(name: "天巫", type: "adjective"))

        // 月解
        let yuejieBranches = ["申", "申", "戌", "戌", "子", "子", "寅", "寅", "辰", "辰", "午", "午"]
        result[fixEarthlyBranchIndex(yuejieBranches[monthIndex])].adjectiveStars.append(PlacedStar(name: "月解", type: "helper"))

        // 日系星 (三台、八座、恩光、天贵)
        let lunar = lunarFromSolarDate(solarDate)
        let lunarDay = lunar.day
        let dayIndex = lunarDay - 1  // 0-based day index

        if let zuoIndex = findPalaceIndex(starName: "左辅", in: allMinorStars) {
            result[fixIndex(zuoIndex + dayIndex)].adjectiveStars.append(PlacedStar(name: "三台", type: "adjective"))
        }
        if let youIndex = findPalaceIndex(starName: "右弼", in: allMinorStars) {
            result[fixIndex(youIndex - dayIndex)].adjectiveStars.append(PlacedStar(name: "八座", type: "adjective"))
        }
        if let changIndex = findPalaceIndex(starName: "文昌", in: allMinorStars) {
            result[fixIndex(changIndex + dayIndex - 1)].adjectiveStars.append(PlacedStar(name: "恩光", type: "adjective"))
        }
        if let quIndex = findPalaceIndex(starName: "文曲", in: allMinorStars) {
            result[fixIndex(quIndex + dayIndex - 1)].adjectiveStars.append(PlacedStar(name: "天贵", type: "adjective"))
        }

        // 时系星 (台辅、封诰)
        result[fixIndex(fixEarthlyBranchIndex("午") + timeIndex)].adjectiveStars.append(PlacedStar(name: "台辅", type: "adjective"))
        result[fixIndex(fixEarthlyBranchIndex("寅") + timeIndex)].adjectiveStars.append(PlacedStar(name: "封诰", type: "adjective"))

        return result
    }

    private func huagaiXianchiBranches(yearBranchName: String) -> (Int, Int) {
        switch yearBranchName {
        case "寅", "午", "戌": return (fixEarthlyBranchIndex("戌"), fixEarthlyBranchIndex("卯"))
        case "申", "子", "辰": return (fixEarthlyBranchIndex("辰"), fixEarthlyBranchIndex("酉"))
        case "巳", "酉", "丑": return (fixEarthlyBranchIndex("丑"), fixEarthlyBranchIndex("午"))
        case "亥", "卯", "未": return (fixEarthlyBranchIndex("未"), fixEarthlyBranchIndex("子"))
        default: return (0, 0)
        }
    }

    private func guchenGuasuBranches(yearBranchName: String) -> (Int, Int) {
        switch yearBranchName {
        case "寅", "卯", "辰": return (fixEarthlyBranchIndex("巳"), fixEarthlyBranchIndex("丑"))
        case "巳", "午", "未": return (fixEarthlyBranchIndex("申"), fixEarthlyBranchIndex("辰"))
        case "申", "酉", "戌": return (fixEarthlyBranchIndex("亥"), fixEarthlyBranchIndex("未"))
        case "亥", "子", "丑": return (fixEarthlyBranchIndex("寅"), fixEarthlyBranchIndex("戌"))
        default: return (0, 0)
        }
    }

    private func shenGongIndex(for palaces: [ZiweiPalace]) -> Int {
        return palaces.firstIndex(where: { $0.isBodyPalace }) ?? 0
    }

    private func lunarFromSolarDate(_ dateStr: String) -> (month: Int, day: Int) {
        let parts = dateStr.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return (1, 1) }
        let lunar = lunarFromSolar(year: parts[0], month: parts[1], day: parts[2])
        return (lunar.month, lunar.day)
    }

    // MARK: - Place Transformations

    private func placeTransformations(palaces: [ZiweiPalace], yearStemName: String) -> [ZiweiPalace] {
        var result = palaces
        guard let stemIdx = heavenlyStems.firstIndex(of: yearStemName),
              let stem = HeavenlyStem(rawValue: stemIdx) else { return result }

        let transformations = stem.transformations
        let transTypes = ["禄", "权", "科", "忌"]

        for (i, transStar) in transformations.enumerated() {
            let starName = simplifiedName(for: transStar)
            let transType = transTypes[i]
            for pIdx in 0..<12 {
                if let sIdx = result[pIdx].majorStars.firstIndex(where: { $0.name == starName }) {
                    result[pIdx].majorStars[sIdx].transformation = transType
                }
                if let sIdx = result[pIdx].minorStars.firstIndex(where: { $0.name == starName }) {
                    result[pIdx].minorStars[sIdx].transformation = transType
                }
            }
        }

        return result
    }

    // MARK: - ChangSheng12

    private func getChangSheng12(wuXingJu: WuXingJu, yearBranchName: String, gender: Gender) -> [Int] {
        // 长生十二神起始地支
        let startBranchName: String
        switch wuXingJu {
        case .shuiEr: startBranchName = "申"
        case .muSan: startBranchName = "亥"
        case .jinSi: startBranchName = "巳"
        case .tuWu: startBranchName = "申"
        case .huoLiu: startBranchName = "寅"
        }
        let startIndex = fixEarthlyBranchIndex(startBranchName)

        let yearBranchIdx = earthlyBranches.firstIndex(of: yearBranchName) ?? 0
        let isYangBranch = yearBranchIdx % 2 == 0
        let isMale = gender == .male
        let clockwise = isYangBranch == isMale  // 阳男阴女顺行

        var changsheng12 = Array(repeating: 0, count: 12)
        for i in 0..<12 {
            let idx = clockwise ? fixIndex(startIndex + i) : fixIndex(startIndex - i)
            changsheng12[idx] = i
        }
        return changsheng12
    }

    private func changshengName(for index: Int) -> String {
        let names = ["长生", "沐浴", "冠带", "临官", "帝旺", "衰", "病", "死", "墓", "绝", "胎", "养"]
        guard index >= 0 && index < 12 else { return "" }
        return names[index]
    }

    // MARK: - BoShi12

    private func getBoShi12(palaces: [ZiweiPalace], yearStemName: String, gender: Gender) -> [Int] {
        // 找禄存所在宫位
        var luCunIndex = 0
        for (i, palace) in palaces.enumerated() {
            if palace.minorStars.contains(where: { $0.name == "禄存" }) {
                luCunIndex = i
                break
            }
        }

        let luCunStem = palaces[luCunIndex].heavenlyStem ?? .jia
        let isYangStem = luCunStem.rawValue % 2 == 0
        let isMale = gender == .male
        let clockwise = isYangStem == isMale  // 阳男阴女顺行

        var boshi12 = Array(repeating: 0, count: 12)
        for i in 0..<12 {
            let idx = clockwise ? fixIndex(luCunIndex + i) : fixIndex(luCunIndex - i)
            boshi12[idx] = i
        }
        return boshi12
    }

    private func boshiName(for index: Int) -> String {
        let names = ["博士", "力士", "青龙", "小耗", "将军", "奏书", "飞廉", "喜神", "病符", "大耗", "伏兵", "官府"]
        guard index >= 0 && index < 12 else { return "" }
        return names[index]
    }

    // MARK: - Yearly12 (Suiqian + Jiangqian)

    private struct Yearly12Result {
        let suiqian: [String]
        let jiangqian: [String]
    }

    private func getYearly12(yearBranchName: String) -> Yearly12Result {
        let suiqianNames = ["岁建", "晦气", "丧门", "贯索", "官符", "小耗", "大耗", "龙德", "白虎", "天德", "吊客", "病符"]
        let jiangqianNames = ["将星", "攀鞍", "岁驿", "息神", "华盖", "劫煞", "灾煞", "天煞", "指背", "咸池", "月煞", "亡神"]

        let yearBranchIdx = earthlyBranches.firstIndex(of: yearBranchName) ?? 0

        // 岁前十二神: 从流年地支起，顺行
        var suiqian = Array(repeating: "", count: 12)
        for i in 0..<12 {
            let idx = fixIndex(yearBranchIdx + i)
            let palaceIdx = fixIndex(idx - 2)  // convert to palace index
            suiqian[palaceIdx] = suiqianNames[i]
        }

        // 将前十二神起始点
        let jiangqianStart: Int
        switch yearBranchName {
        case "寅", "午", "戌": jiangqianStart = 6   // 午
        case "申", "子", "辰": jiangqianStart = 0   // 子
        case "巳", "酉", "丑": jiangqianStart = 9   // 酉
        case "亥", "卯", "未": jiangqianStart = 3   // 卯
        default: jiangqianStart = 0
        }

        var jiangqian = Array(repeating: "", count: 12)
        for i in 0..<12 {
            let idx = fixIndex(jiangqianStart + i)
            let palaceIdx = fixIndex(idx - 2)
            jiangqian[palaceIdx] = jiangqianNames[i]
        }

        return Yearly12Result(suiqian: suiqian, jiangqian: jiangqian)
    }

    // MARK: - Decadal Ranges

    private func assignDecadalRanges(palaces: [ZiweiPalace], mingGongIndex: Int, wuXingJu: WuXingJu, yearStemName: String, gender: Gender) -> [ZiweiPalace] {
        var result = palaces
        let startAge = wuXingJu.value
        let yearStemIdx = heavenlyStems.firstIndex(of: yearStemName) ?? 0
        let isYangStem = yearStemIdx % 2 == 0
        let isMale = gender == .male
        let clockwise = (isYangStem && isMale) || (!isYangStem && !isMale)

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

    // MARK: - Ages (小限)

    private func calculateAges(yearBranchName: String, gender: Gender) -> [[Int]] {
        let startBranch: String
        switch yearBranchName {
        case "寅", "午", "戌": startBranch = "辰"
        case "申", "子", "辰": startBranch = "戌"
        case "巳", "酉", "丑": startBranch = "未"
        case "亥", "卯", "未": startBranch = "丑"
        default: startBranch = "辰"
        }

        let startPalace = fixEarthlyBranchIndex(startBranch)
        let yearBranchIdx = earthlyBranches.firstIndex(of: yearBranchName) ?? 0
        let isYangBranch = yearBranchIdx % 2 == 0
        let isMale = gender == .male
        let clockwise = isYangBranch == isMale  // 阳男阴女顺行
        var ages: [[Int]] = Array(repeating: [], count: 12)

        for palaceIndex in 0..<12 {
            var diff = clockwise ? palaceIndex - startPalace : startPalace - palaceIndex
            while diff < 0 { diff += 12 }
            let firstAge = diff + 1

            var age = firstAge
            while age <= 120 {
                ages[palaceIndex].append(age)
                age += 12
            }
        }

        return ages
    }

    // MARK: - Horoscope System

    private func calculateHoroscope(palaces: [ZiweiPalace], mingGongIndex: Int, yearStemName: String, birthYear: Int, gender: Gender) -> HoroscopeData {
        var horoscope = HoroscopeData()
        let currentYear = Calendar.current.component(.year, from: Date())
        let currentAge = currentYear - birthYear + 1  // nominal age

        // Decadal (大限)
        horoscope.decadal = calculateDecadalPeriod(
            palaces: palaces, mingGongIndex: mingGongIndex,
            currentAge: currentAge, birthYear: birthYear
        )

        // Yearly (流年)
        horoscope.yearly = calculateYearlyPeriod(
            palaces: palaces, mingGongIndex: mingGongIndex,
            currentYear: currentYear, birthYear: birthYear
        )

        // Monthly (流月)
        let currentMonth = Calendar.current.component(.month, from: Date())
        horoscope.monthly = calculateMonthlyPeriod(
            palaces: palaces, currentYear: currentYear, currentMonth: currentMonth
        )

        // Daily (流日)
        let currentDay = Calendar.current.component(.day, from: Date())
        horoscope.daily = calculateDailyPeriod(
            palaces: palaces, currentYear: currentYear, currentMonth: currentMonth, currentDay: currentDay
        )

        // Hourly (流时)
        let currentHour = Calendar.current.component(.hour, from: Date())
        horoscope.hourly = calculateHourlyPeriod(
            palaces: palaces, currentYear: currentYear, currentMonth: currentMonth,
            currentDay: currentDay, currentHour: currentHour
        )

        return horoscope
    }

    private func calculateDecadalPeriod(palaces: [ZiweiPalace], mingGongIndex: Int, currentAge: Int, birthYear: Int) -> PeriodData? {
        guard let activePalace = palaces.first(where: {
            guard let decadal = $0.decadal else { return false }
            return decadal.range.0 <= currentAge && currentAge <= decadal.range.1
        }) else { return nil }

        let decadal = activePalace.decadal!
        return PeriodData(
            index: activePalace.index,
            heavenlyStem: activePalace.heavenlyStem ?? .jia,
            earthlyBranch: activePalace.earthlyBranch ?? .zi,
            palaceNames: palaces.map { $0.name },
            mutagen: (activePalace.heavenlyStem ?? .jia).transformations,
            stars: [],
            flowStars: getFlowStars(
                stem: activePalace.heavenlyStem ?? .jia,
                branch: activePalace.earthlyBranch ?? .zi,
                scope: "decadal"
            ),
            suiqian12: [],
            jiangqian12: [],
            age: currentAge,
            startYear: birthYear + decadal.range.0,
            endYear: birthYear + decadal.range.1
        )
    }

    private func calculateYearlyPeriod(palaces: [ZiweiPalace], mingGongIndex: Int, currentYear: Int, birthYear: Int) -> PeriodData? {
        let yearStemIdx = (currentYear - 4) % 10
        let yearBranchIdx = (currentYear - 4) % 12
        let yearStem = HeavenlyStem(rawValue: yearStemIdx >= 0 ? yearStemIdx : yearStemIdx + 10)!
        let yearBranch = EarthlyBranch(rawValue: yearBranchIdx >= 0 ? yearBranchIdx : yearBranchIdx + 12)!

        // 流年命宫: 以流年地支为命宫
        let yearlyMingIndex = fixIndex(yearBranch.rawValue - 2)

        // 岁前/将前十二神
        let yearBranchName = earthlyBranches[yearBranch.rawValue]
        let yearly12 = getYearly12(yearBranchName: yearBranchName)

        // 流耀
        let flowStars = getFlowStars(stem: yearStem, branch: yearBranch, scope: "yearly")

        return PeriodData(
            index: yearlyMingIndex,
            heavenlyStem: yearStem,
            earthlyBranch: yearBranch,
            palaceNames: palaces.map { $0.name },
            mutagen: yearStem.transformations,
            stars: [],
            flowStars: flowStars,
            suiqian12: yearly12.suiqian,
            jiangqian12: yearly12.jiangqian,
            age: currentYear - birthYear + 1,
            startYear: currentYear,
            endYear: currentYear
        )
    }

    private func calculateMonthlyPeriod(palaces: [ZiweiPalace], currentYear: Int, currentMonth: Int) -> PeriodData? {
        let monthStemIdx = (currentYear - 4 + currentMonth - 1) % 10
        let monthBranchIdx = (currentMonth + 1) % 12
        let monthStem = HeavenlyStem(rawValue: monthStemIdx >= 0 ? monthStemIdx : monthStemIdx + 10)!
        let monthBranch = EarthlyBranch(rawValue: monthBranchIdx >= 0 ? monthBranchIdx : monthBranchIdx + 12)!

        return PeriodData(
            index: fixIndex(monthBranch.rawValue - 2),
            heavenlyStem: monthStem,
            earthlyBranch: monthBranch,
            palaceNames: palaces.map { $0.name },
            mutagen: monthStem.transformations,
            stars: [],
            flowStars: getFlowStars(stem: monthStem, branch: monthBranch, scope: "monthly"),
            suiqian12: [],
            jiangqian12: [],
            age: 0,
            startYear: currentYear,
            endYear: currentYear
        )
    }

    private func calculateDailyPeriod(palaces: [ZiweiPalace], currentYear: Int, currentMonth: Int, currentDay: Int) -> PeriodData? {
        let dayStemIdx = (currentYear - 4 + currentMonth - 1 + currentDay - 1) % 10
        let dayBranchIdx = (currentDay - 1) % 12
        let dayStem = HeavenlyStem(rawValue: dayStemIdx >= 0 ? dayStemIdx : dayStemIdx + 10)!
        let dayBranch = EarthlyBranch(rawValue: dayBranchIdx >= 0 ? dayBranchIdx : dayBranchIdx + 12)!

        return PeriodData(
            index: fixIndex(dayBranch.rawValue - 2),
            heavenlyStem: dayStem,
            earthlyBranch: dayBranch,
            palaceNames: palaces.map { $0.name },
            mutagen: dayStem.transformations,
            stars: [],
            flowStars: getFlowStars(stem: dayStem, branch: dayBranch, scope: "daily"),
            suiqian12: [],
            jiangqian12: [],
            age: 0,
            startYear: currentYear,
            endYear: currentYear
        )
    }

    private func calculateHourlyPeriod(palaces: [ZiweiPalace], currentYear: Int, currentMonth: Int, currentDay: Int, currentHour: Int) -> PeriodData? {
        let hourlyBranchIndex = ((currentHour + 1) / 2) % 12
        let dayStemIdx = (currentYear - 4 + currentMonth - 1 + currentDay - 1) % 10
        let dayStem = HeavenlyStem(rawValue: dayStemIdx >= 0 ? dayStemIdx : dayStemIdx + 10)!
        let ratOffset: [HeavenlyStem: Int] = [
            .jia: 0, .yi: 2, .bing: 4, .ding: 6, .wu: 8,
            .ji: 0, .geng: 2, .xin: 4, .ren: 6, .gui: 8
        ]
        let hourlyStemIdx = (ratOffset[dayStem]! + hourlyBranchIndex) % 10
        let hourlyStem = HeavenlyStem(rawValue: hourlyStemIdx)!
        let hourlyBranch = EarthlyBranch(rawValue: hourlyBranchIndex)!

        return PeriodData(
            index: fixIndex(hourlyBranch.rawValue - 2),
            heavenlyStem: hourlyStem,
            earthlyBranch: hourlyBranch,
            palaceNames: palaces.map { $0.name },
            mutagen: hourlyStem.transformations,
            stars: [],
            flowStars: getFlowStars(stem: hourlyStem, branch: hourlyBranch, scope: "hourly"),
            suiqian12: [],
            jiangqian12: [],
            age: 0,
            startYear: currentYear,
            endYear: currentYear
        )
    }

    // MARK: - Flow Stars (流耀)

    private func getFlowStars(stem: HeavenlyStem, branch: EarthlyBranch, scope: String) -> [[PlacedStar]] {
        var flowStars: [[PlacedStar]] = Array(repeating: [], count: 12)

        let stemName = heavenlyStems[stem.rawValue]
        let branchName = earthlyBranches[branch.rawValue]

        // 魁钺
        let kuiYue = getKuiYueIndex(yearStemName: stemName)
        flowStars[kuiYue.kuiIndex].append(PlacedStar(name: flowStarName(base: "魁", scope: scope), type: "flow"))
        flowStars[kuiYue.yueIndex].append(PlacedStar(name: flowStarName(base: "钺", scope: scope), type: "flow"))

        // 昌曲 (流昌流曲用年干起)
        let changQu = getChangQuIndexByHeavenlyStem(yearStemName: stemName)
        flowStars[changQu.changIndex].append(PlacedStar(name: flowStarName(base: "昌", scope: scope), type: "flow"))
        flowStars[changQu.quIndex].append(PlacedStar(name: flowStarName(base: "曲", scope: scope), type: "flow"))

        // 禄羊陀马
        let luYangTuoMa = getLuYangTuoMaIndex(yearStemName: stemName, yearBranchName: branchName)
        flowStars[luYangTuoMa.luIndex].append(PlacedStar(name: flowStarName(base: "禄", scope: scope), type: "flow"))
        flowStars[luYangTuoMa.yangIndex].append(PlacedStar(name: flowStarName(base: "羊", scope: scope), type: "flow"))
        flowStars[luYangTuoMa.tuoIndex].append(PlacedStar(name: flowStarName(base: "陀", scope: scope), type: "flow"))
        flowStars[luYangTuoMa.maIndex].append(PlacedStar(name: flowStarName(base: "马", scope: scope), type: "flow"))

        // 鸾喜
        let hongluanIndex = fixIndex(fixEarthlyBranchIndex("卯") - earthlyBranches.firstIndex(of: branchName)!)
        flowStars[hongluanIndex].append(PlacedStar(name: flowStarName(base: "鸾", scope: scope), type: "flow"))
        flowStars[fixIndex(hongluanIndex + 6)].append(PlacedStar(name: flowStarName(base: "喜", scope: scope), type: "flow"))

        // 年解 (仅流年)
        if scope == "yearly" {
            flowStars[fixIndex(fixEarthlyBranchIndex("戌") - earthlyBranches.firstIndex(of: branchName)!)].append(PlacedStar(name: "年解", type: "helper", scope: "yearly"))
        }

        return flowStars
    }

    private func flowStarName(base: String, scope: String) -> String {
        let prefix: String
        switch scope {
        case "decadal": prefix = "运"
        case "yearly": prefix = "流"
        case "monthly": prefix = "月"
        case "daily": prefix = "日"
        case "hourly": prefix = "时"
        default: prefix = ""
        }
        return "\(prefix)\(base)"
    }

    private func getChangQuIndexByHeavenlyStem(yearStemName: String) -> ChangQuIndex {
        switch yearStemName {
        case "甲":
            return ChangQuIndex(changIndex: fixEarthlyBranchIndex("巳"), quIndex: fixEarthlyBranchIndex("酉"))
        case "乙":
            return ChangQuIndex(changIndex: fixEarthlyBranchIndex("午"), quIndex: fixEarthlyBranchIndex("申"))
        case "丙", "戊":
            return ChangQuIndex(changIndex: fixEarthlyBranchIndex("申"), quIndex: fixEarthlyBranchIndex("午"))
        case "丁", "己":
            return ChangQuIndex(changIndex: fixEarthlyBranchIndex("酉"), quIndex: fixEarthlyBranchIndex("巳"))
        case "庚":
            return ChangQuIndex(changIndex: fixEarthlyBranchIndex("亥"), quIndex: fixEarthlyBranchIndex("卯"))
        case "辛":
            return ChangQuIndex(changIndex: fixEarthlyBranchIndex("子"), quIndex: fixEarthlyBranchIndex("寅"))
        case "壬":
            return ChangQuIndex(changIndex: fixEarthlyBranchIndex("寅"), quIndex: fixEarthlyBranchIndex("子"))
        case "癸":
            return ChangQuIndex(changIndex: fixEarthlyBranchIndex("卯"), quIndex: fixEarthlyBranchIndex("亥"))
        default:
            return ChangQuIndex(changIndex: 0, quIndex: 0)
        }
    }
}
