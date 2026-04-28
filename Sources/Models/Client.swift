import Foundation

struct Client: Identifiable, Equatable, Hashable, Codable {
    var id: UUID
    var name: String
    var gender: Gender
    var birthDate: Date
    var birthTime: BirthTime
    var birthPlace: String
    var phone: String
    var email: String
    var notes: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String = "",
        gender: Gender = .male,
        birthDate: Date = Date(),
        birthTime: BirthTime = .zi,
        birthPlace: String = "",
        phone: String = "",
        email: String = "",
        notes: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.gender = gender
        self.birthDate = birthDate
        self.birthTime = birthTime
        self.birthPlace = birthPlace
        self.phone = phone
        self.email = email
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

enum Gender: String, Codable, CaseIterable {
    case male = "男"
    case female = "女"

    var displayName: String {
        switch self {
        case .male: return L("male")
        case .female: return L("female")
        }
    }
}

enum BirthTime: Int, Codable, CaseIterable {
    case zi = 0    // 子時 23:00-00:59
    case chou = 1  // 丑時 01:00-02:59
    case yin = 2   // 寅時 03:00-04:59
    case mao = 3   // 卯時 05:00-06:59
    case chen = 4  // 辰時 07:00-08:59
    case si = 5    // 巳時 09:00-10:59
    case wu = 6    // 午時 11:00-12:59
    case wei = 7   // 未時 13:00-14:59
    case shen = 8  // 申時 15:00-16:59
    case you = 9   // 酉時 17:00-18:59
    case xu = 10   // 戌時 19:00-20:59
    case hai = 11  // 亥時 21:00-22:59

    var displayName: String {
        let key: String
        switch self {
        case .zi:   key = "hour_zi"
        case .chou: key = "hour_chou"
        case .yin:  key = "hour_yin"
        case .mao:  key = "hour_mao"
        case .chen: key = "hour_chen"
        case .si:   key = "hour_si"
        case .wu:   key = "hour_wu"
        case .wei:  key = "hour_wei"
        case .shen: key = "hour_shen"
        case .you:  key = "hour_you"
        case .xu:   key = "hour_xu"
        case .hai:  key = "hour_hai"
        }
        let end = (startHour + 1) % 24
        return "\(L(key)) (\(String(format: "%02d:00-%02d:59", startHour, end)))"
    }

    var startHour: Int {
        switch self {
        case .zi: return 23
        default: return self.rawValue * 2 - 1
        }
    }
}