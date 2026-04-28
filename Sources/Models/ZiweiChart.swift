import Foundation

struct ZiweiChart: Identifiable, Codable {
    var id: UUID
    var clientId: UUID
    var name: String
    var solarDate: String
    var lunarDate: String?
    var fourPillars: FourPillars
    var wuXingJu: WuXingJu
    var mingGongIndex: Int
    var shenGongIndex: Int
    var palaces: [ZiweiPalace]
    var horoscope: HoroscopeData
    var gender: Gender
    var birthHour: Int
    var soul: String
    var body: String
    var lunarMonth: Int
    var lunarDay: Int
    var createdAt: Date

    init(
        id: UUID = UUID(),
        clientId: UUID = UUID(),
        name: String = "",
        solarDate: String = "",
        lunarDate: String? = nil,
        fourPillars: FourPillars = FourPillars(
            year: StemBranch(heavenlyStem: .jia, earthlyBranch: .zi),
            month: StemBranch(heavenlyStem: .jia, earthlyBranch: .yin),
            day: StemBranch(heavenlyStem: .jia, earthlyBranch: .zi),
            hour: StemBranch(heavenlyStem: .jia, earthlyBranch: .zi)
        ),
        wuXingJu: WuXingJu = .tuWu,
        mingGongIndex: Int = 0,
        shenGongIndex: Int = 0,
        palaces: [ZiweiPalace] = [],
        horoscope: HoroscopeData = HoroscopeData(),
        gender: Gender = .male,
        birthHour: Int = 0,
        soul: String = "",
        body: String = "",
        lunarMonth: Int = 1,
        lunarDay: Int = 1,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.clientId = clientId
        self.name = name
        self.solarDate = solarDate
        self.lunarDate = lunarDate
        self.fourPillars = fourPillars
        self.wuXingJu = wuXingJu
        self.mingGongIndex = mingGongIndex
        self.shenGongIndex = shenGongIndex
        self.palaces = palaces
        self.horoscope = horoscope
        self.gender = gender
        self.birthHour = birthHour
        self.soul = soul
        self.body = body
        self.lunarMonth = lunarMonth
        self.lunarDay = lunarDay
        self.createdAt = createdAt
    }

    var mingGong: ZiweiPalace {
        palaces[mingGongIndex]
    }

    var shenGong: ZiweiPalace {
        palaces[shenGongIndex]
    }

    static func == (lhs: ZiweiChart, rhs: ZiweiChart) -> Bool {
        lhs.id == rhs.id
    }
}