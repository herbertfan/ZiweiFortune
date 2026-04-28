import Foundation

// MARK: - 天干地支常數

enum HeavenlyStem: Int, CaseIterable, Codable {
    case jia = 0    // 甲
    case yi = 1     // 乙
    case bing = 2   // 丙
    case ding = 3   // 丁
    case wu = 4     // 戊
    case ji = 5     // 己
    case geng = 6   // 庚
    case xin = 7    // 辛
    case ren = 8    // 壬
    case gui = 9    // 癸

    var displayName: String {
        switch self {
        case .jia:  return L("stem_jia")
        case .yi:   return L("stem_yi")
        case .bing: return L("stem_bing")
        case .ding: return L("stem_ding")
        case .wu:   return L("stem_wu")
        case .ji:   return L("stem_ji")
        case .geng: return L("stem_geng")
        case .xin:  return L("stem_xin")
        case .ren:  return L("stem_ren")
        case .gui:  return L("stem_gui")
        }
    }

    var fiveElement: FiveElement {
        switch self {
        case .jia, .yi: return .wood
        case .bing, .ding: return .fire
        case .wu, .ji: return .earth
        case .geng, .xin: return .metal
        case .ren, .gui: return .water
        }
    }

    var isYang: Bool {
        rawValue % 2 == 0
    }

    // 四化星 (中州派)
    var transformations: [TransformationStar] {
        switch self {
        case .jia: return [.lian, .po, .wu, .yang]
        case .yi: return [.ji, .liang, .zi, .yin]
        case .bing: return [.tong, .ji, .chang, .lian]
        case .ding: return [.yin, .tong, .ji, .ju]
        case .wu: return [.tan, .yin, .you, .ji]
        case .ji: return [.wu, .tan, .liang, .qu]
        case .geng: return [.yang, .wu, .yin, .tong]
        case .xin: return [.ju, .yang, .qu, .chang]
        case .ren: return [.liang, .zi, .zu, .wu]
        case .gui: return [.po, .ju, .yin, .tan]
        }
    }
}

enum EarthlyBranch: Int, CaseIterable, Codable {
    case zi = 0     // 子
    case chou = 1   // 丑
    case yin = 2    // 寅
    case mao = 3    // 卯
    case chen = 4   // 辰
    case si = 5     // 巳
    case wu = 6     // 午
    case wei = 7    // 未
    case shen = 8   // 申
    case you = 9    // 酉
    case xu = 10    // 戌
    case hai = 11   // 亥

    var displayName: String {
        switch self {
        case .zi:   return L("branch_zi")
        case .chou: return L("branch_chou")
        case .yin:  return L("branch_yin")
        case .mao:  return L("branch_mao")
        case .chen: return L("branch_chen")
        case .si:   return L("branch_si")
        case .wu:   return L("branch_wu")
        case .wei:  return L("branch_wei")
        case .shen: return L("branch_shen")
        case .you:  return L("branch_you")
        case .xu:   return L("branch_xu")
        case .hai:  return L("branch_hai")
        }
    }

    var zodiac: String {
        switch self {
        case .zi:   return L("zodiac_rat")
        case .chou: return L("zodiac_ox")
        case .yin:  return L("zodiac_tiger")
        case .mao:  return L("zodiac_rabbit")
        case .chen: return L("zodiac_dragon")
        case .si:   return L("zodiac_snake")
        case .wu:   return L("zodiac_horse")
        case .wei:  return L("zodiac_goat")
        case .shen: return L("zodiac_monkey")
        case .you:  return L("zodiac_rooster")
        case .xu:   return L("zodiac_dog")
        case .hai:  return L("zodiac_pig")
        }
    }
}

enum FiveElement: String, Codable {
    case wood = "木"
    case fire = "火"
    case earth = "土"
    case metal = "金"
    case water = "水"

    var displayName: String {
        switch self {
        case .wood:  return L("element_wood")
        case .fire:  return L("element_fire")
        case .earth: return L("element_earth")
        case .metal: return L("element_metal")
        case .water: return L("element_water")
        }
    }
}

enum TransformationStar: String, Codable {
    case lian = "廉貞"
    case po = "破軍"
    case wu = "武曲"
    case yang = "太陽"
    case ji = "天機"
    case liang = "天梁"
    case zi = "紫微"
    case yin = "太陰"
    case tong = "天同"
    case chang = "文昌"
    case ju = "巨門"
    case tan = "貪狼"
    case you = "右弼"
    case qu = "文曲"
    case zu = "左輔"

    var displayName: String {
        switch self {
        case .lian:   return L("star_lianzhen")
        case .po:     return L("star_pojun")
        case .wu:     return L("star_wuqu")
        case .yang:   return L("star_taiyang")
        case .ji:     return L("star_tianji")
        case .liang:  return L("star_tianliang")
        case .zi:     return L("star_ziwei")
        case .yin:    return L("star_taiyin")
        case .tong:   return L("star_tiantong")
        case .chang:  return L("star_wenchang")
        case .ju:     return L("star_jumen")
        case .tan:    return L("star_tanlang")
        case .you:    return L("star_youbi")
        case .qu:     return L("star_wenqu")
        case .zu:     return L("star_zuofu")
        }
    }
}

enum StarType: String, Codable {
    case ziWei = "紫微"
    case tianJi = "天機"
    case taiYang = "太陽"
    case wuQu = "武曲"
    case tianTong = "天同"
    case lianZheng = "廉貞"
    case tianFu = "天府"
    case taiYin = "太陰"
    case cangLang = "蒼狼"
    case tianLiang = "天梁"
    case qiSha = "七殺"
    case poJun = "破軍"
    case wenQu = "文昌"
    case juMen = "巨門"
    case tianXing = "天刑"
    case yangRen = "羊刃"
    case tianMa = "天馬"
    case tianKong = "天空"
    case tianShi = "天喜"
    case hongLian = "紅鸞"
    case zuoFu = "左輔"
    case youBi = "右弼"
    case tianGuan = "天官"
    case tianFu2 = "天福"
    case luCun = "祿存"
    case qiNiao = "七鳥"
    case guanCao = "官府"
    case diJin = "地劫"
    case ban = "半殺"
    case xie = "斜視"
}

// MARK: - 五行局

enum WuXingJu: String, CaseIterable, Codable {
    case shuiEr = "水二局"
    case muSan = "木三局"
    case jinSi = "金四局"
    case tuWu = "土五局"
    case huoLiu = "火六局"

    var value: Int {
        switch self {
        case .shuiEr: return 2
        case .muSan: return 3
        case .jinSi: return 4
        case .tuWu: return 5
        case .huoLiu: return 6
        }
    }

    var displayName: String {
        switch self {
        case .shuiEr: return L("wuxing_shui2")
        case .muSan:  return L("wuxing_mu3")
        case .jinSi:  return L("wuxing_jin4")
        case .tuWu:   return L("wuxing_tu5")
        case .huoLiu: return L("wuxing_huo6")
        }
    }
}

// MARK: - 亮度

enum StarBrightness: String, Codable {
    case miao = "庙"
    case wang = "旺"
    case de = "得"
    case li = "利"
    case ping = "平"
    case bu = "不"
    case xian = "陷"

    var displayName: String {
        switch self {
        case .miao: return L("brightness_miao")
        case .wang: return L("brightness_wang")
        case .de:   return L("brightness_de")
        case .li:   return L("brightness_li")
        case .ping: return L("brightness_ping")
        case .bu:   return L("brightness_bu")
        case .xian: return L("brightness_xian")
        }
    }
}

// MARK: - 十二宮

enum PalaceName: String, CaseIterable, Codable {
    case mingGong = "命宮"
    case xiongDi = "兄弟"
    case fuQi = "夫妻"
    case ziNv = "子女"
    case caiBo = "財帛"
    case jiE = "疾厄"
    case qianYi = "遷移"
    case jiaoYou = "交友"
    case guanLu = "官祿"
    case tianZhai = "田宅"
    case fuDe = "福德"
    case fuMu = "父母"

    var index: Int {
        PalaceName.allCases.firstIndex(of: self)!
    }

    var displayName: String {
        switch self {
        case .mingGong: return L("palace_ming")
        case .xiongDi:  return L("palace_sibling")
        case .fuQi:     return L("palace_spouse")
        case .ziNv:     return L("palace_children")
        case .caiBo:    return L("palace_wealth")
        case .jiE:      return L("palace_health")
        case .qianYi:   return L("palace_travel")
        case .jiaoYou:  return L("palace_friend")
        case .guanLu:   return L("palace_career")
        case .tianZhai: return L("palace_property")
        case .fuDe:     return L("palace_fortune")
        case .fuMu:     return L("palace_parent")
        }
    }
}

// MARK: - 起寅口訣

enum YinMonthRule {
    static func getStartBranch(for stem: HeavenlyStem) -> EarthlyBranch {
        switch stem {
        case .jia, .ji: return .yin  // 甲己年起丙寅 -> 寅
        case .yi, .geng: return .chou  // 乙庚年起戊寅 -> 丑
        case .bing, .xin: return .mao  // 丙辛年起庚寅 -> 卯
        case .ding, .ren: return .si   // 丁壬年起壬寅 -> 巳
        case .wu, .gui: return .xu     // 戊癸年起甲寅 -> 戌
        }
    }

    static func getStartStemOffset(for stem: HeavenlyStem) -> Int {
        switch stem {
        case .jia, .ji: return 2   // 丙寅
        case .yi, .geng: return 4  // 戊寅
        case .bing, .xin: return 6  // 庚寅
        case .ding, .ren: return 8  // 壬寅
        case .wu, .gui: return 0    // 甲寅
        }
    }
}

// MARK: - PlacedStar

struct PlacedStar: Codable, Equatable {
    var name: String
    var type: String
    var brightness: StarBrightness
    var scope: String
    var transformation: String? = nil
    var fiveElement: String? = nil
    var yinYang: String? = nil

    init(name: String, type: String = "major", brightness: StarBrightness = .ping, scope: String = "origin", transformation: String? = nil, fiveElement: String? = nil, yinYang: String? = nil) {
        self.name = name
        self.type = type
        self.brightness = brightness
        self.scope = scope
        self.transformation = transformation
        self.fiveElement = fiveElement
        self.yinYang = yinYang
    }
}

// MARK: - ZiweiPalace

struct ZiweiPalace: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var index: Int
    var isOriginalPalace: Bool
    var isBodyPalace: Bool
    var heavenlyStem: HeavenlyStem?
    var earthlyBranch: EarthlyBranch?
    var majorStars: [PlacedStar]
    var minorStars: [PlacedStar]
    var adjectiveStars: [PlacedStar]
    var changsheng12: Int
    var boshi12: Int
    var changsheng12Name: String?
    var boshi12Name: String?
    var jiangqian12: String?
    var suiqian12: String?
    var decadal: Decadal?
    var ages: [Int]

    init(id: UUID = UUID(), name: String, index: Int, isOriginalPalace: Bool = false, isBodyPalace: Bool = false, heavenlyStem: HeavenlyStem? = nil, earthlyBranch: EarthlyBranch? = nil, majorStars: [PlacedStar] = [], minorStars: [PlacedStar] = [], adjectiveStars: [PlacedStar] = [], changsheng12: Int = 0, boshi12: Int = 0, changsheng12Name: String? = nil, boshi12Name: String? = nil, jiangqian12: String? = nil, suiqian12: String? = nil, decadal: Decadal? = nil, ages: [Int] = []) {
        self.id = id
        self.name = name
        self.index = index
        self.isOriginalPalace = isOriginalPalace
        self.isBodyPalace = isBodyPalace
        self.heavenlyStem = heavenlyStem
        self.earthlyBranch = earthlyBranch
        self.majorStars = majorStars
        self.minorStars = minorStars
        self.adjectiveStars = adjectiveStars
        self.changsheng12 = changsheng12
        self.boshi12 = boshi12
        self.changsheng12Name = changsheng12Name
        self.boshi12Name = boshi12Name
        self.jiangqian12 = jiangqian12
        self.suiqian12 = suiqian12
        self.decadal = decadal
        self.ages = ages
    }
}

// MARK: - FourPillars

struct FourPillars: Codable {
    var year: StemBranch
    var month: StemBranch
    var day: StemBranch
    var hour: StemBranch
}

struct StemBranch: Codable {
    var heavenlyStem: HeavenlyStem
    var earthlyBranch: EarthlyBranch

    var displayName: String {
        "\(heavenlyStem.displayName)\(earthlyBranch.displayName)"
    }
}

// MARK: - Decadal (大限)

struct Decadal: Codable, Equatable {
    var range: (Int, Int)
    var heavenlyStem: HeavenlyStem
    var earthlyBranch: EarthlyBranch
    var palaces: [String]

    var startAge: Int { range.0 }
    var endAge: Int { range.1 }
    var displayName: String { "\(heavenlyStem.displayName)\(earthlyBranch.displayName)" }

    init(range: (Int, Int) = (0, 0), heavenlyStem: HeavenlyStem = .jia, earthlyBranch: EarthlyBranch = .zi, palaces: [String] = []) {
        self.range = range
        self.heavenlyStem = heavenlyStem
        self.earthlyBranch = earthlyBranch
        self.palaces = palaces
    }

    static func == (lhs: Decadal, rhs: Decadal) -> Bool {
        lhs.range.0 == rhs.range.0 && lhs.range.1 == rhs.range.1 &&
        lhs.heavenlyStem == rhs.heavenlyStem && lhs.earthlyBranch == rhs.earthlyBranch
    }

    enum CodingKeys: String, CodingKey {
        case startAge, endAge, heavenlyStem, earthlyBranch, palaces
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let start = try container.decode(Int.self, forKey: .startAge)
        let end = try container.decode(Int.self, forKey: .endAge)
        self.range = (start, end)
        self.heavenlyStem = try container.decode(HeavenlyStem.self, forKey: .heavenlyStem)
        self.earthlyBranch = try container.decode(EarthlyBranch.self, forKey: .earthlyBranch)
        self.palaces = try container.decode([String].self, forKey: .palaces)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(range.0, forKey: .startAge)
        try container.encode(range.1, forKey: .endAge)
        try container.encode(heavenlyStem, forKey: .heavenlyStem)
        try container.encode(earthlyBranch, forKey: .earthlyBranch)
        try container.encode(palaces, forKey: .palaces)
    }
}

// MARK: - HoroscopeData

struct HoroscopeData: Codable {
    var decadal: PeriodData?
    var yearly: PeriodData?
    var monthly: PeriodData?
    var daily: PeriodData?
    var hourly: PeriodData?
}

struct PeriodData: Codable {
    var index: Int
    var heavenlyStem: HeavenlyStem
    var earthlyBranch: EarthlyBranch
    var palaceNames: [String]
    var mutagen: [TransformationStar]
    var stars: [PlacedStar]
    var flowStars: [[PlacedStar]]
    var suiqian12: [String]
    var jiangqian12: [String]
    var age: Int
    var startYear: Int
    var endYear: Int

    init(index: Int = 0, heavenlyStem: HeavenlyStem = .jia, earthlyBranch: EarthlyBranch = .zi, palaceNames: [String] = [], mutagen: [TransformationStar] = [], stars: [PlacedStar] = [], flowStars: [[PlacedStar]] = [], suiqian12: [String] = [], jiangqian12: [String] = [], age: Int = 0, startYear: Int = 0, endYear: Int = 0) {
        self.index = index
        self.heavenlyStem = heavenlyStem
        self.earthlyBranch = earthlyBranch
        self.palaceNames = palaceNames
        self.mutagen = mutagen
        self.stars = stars
        self.flowStars = flowStars
        self.suiqian12 = suiqian12
        self.jiangqian12 = jiangqian12
        self.age = age
        self.startYear = startYear
        self.endYear = endYear
    }
}