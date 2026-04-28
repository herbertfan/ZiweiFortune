import Foundation

// MARK: - Palace Name Localization

private let palaceNameMap: [String: String] = [
    "命宮": "palace_ming",
    "父母宮": "palace_parent",
    "福德宮": "palace_fortune",
    "田宅宮": "palace_property",
    "官祿宮": "palace_career",
    "交友宮": "palace_friend",
    "遷移宮": "palace_travel",
    "疾厄宮": "palace_health",
    "財帛宮": "palace_wealth",
    "子女宮": "palace_children",
    "夫妻宮": "palace_spouse",
    "兄弟宮": "palace_sibling",
]

func localizedPalaceName(_ name: String) -> String {
    guard let key = palaceNameMap[name] else { return name }
    return L(key)
}

// MARK: - Star Name Localization

private let starNameMap: [String: String] = [
    // 十四主星
    "紫微": "star_ziwei",
    "天機": "star_tianji",
    "太陽": "star_taiyang",
    "武曲": "star_wuqu",
    "天同": "star_tiantong",
    "廉貞": "star_lianzhen",
    "天府": "star_tianfu",
    "太陰": "star_taiyin",
    "貪狼": "star_tanlang",
    "巨門": "star_jumen",
    "天相": "star_tianxiang",
    "天梁": "star_tianliang",
    "七殺": "star_qisha",
    "破軍": "star_pojun",
    // 六吉星
    "左輔": "star_zuofu",
    "右弼": "star_youbi",
    "文昌": "star_wenchang",
    "文曲": "star_wenqu",
    "天魁": "star_tiankui",
    "天鉞": "star_tianyue",
    // 六煞星
    "祿存": "star_lucun",
    "擎羊": "star_qingyang",
    "陀羅": "star_tuoluo",
    "火星": "star_huoxing",
    "鈴星": "star_lingxing",
    "地劫": "star_dijie",
    "地空": "star_dikong",
    // 其他
    "天馬": "star_tianma",
    // 雜曜
    "紅鸞": "star_hongluan",
    "天喜": "star_tianxi",
    "龍池": "star_longchi",
    "鳳閣": "star_fengge",
    "華蓋": "star_huagai",
    "咸池": "star_xianchi",
    "孤辰": "star_guchen",
    "寡宿": "star_guasu",
    "天才": "star_tiancai",
    "天壽": "star_tianshou",
    "天哭": "star_tianku",
    "天虛": "star_tianxu",
    "劫殺": "star_jiesha",
    "大耗": "star_dahao",
    "天德": "star_tiande",
    "月德": "star_yuede",
    "天空": "star_tiankong",
    "年解": "star_nianjie",
    "蜚蠊": "star_feilian",
]

func localizedStarName(_ name: String) -> String {
    guard let key = starNameMap[name] else { return name }
    return L(key)
}

// MARK: - 長生十二神

private let changshengKeys = [
    "cs_changsheng", "cs_muyu", "cs_guandai", "cs_linguan",
    "cs_diwang", "cs_shuai", "cs_bing", "cs_si",
    "cs_mu", "cs_jue", "cs_tai", "cs_yang",
]

func localizedChangshengName(_ index: Int) -> String {
    guard index >= 0 && index < changshengKeys.count else { return "" }
    return L(changshengKeys[index])
}

// MARK: - 博士十二神

private let boshiNameMap: [String: String] = [
    "博士": "boshi_boshi",
    "力士": "boshi_lishi",
    "青龍": "boshi_qinglong",
    "小耗": "boshi_xiaohao",
    "將軍": "boshi_jiangjun",
    "奏書": "boshi_zoushu",
    "飛廉": "boshi_feilian",
    "喜神": "boshi_xishen",
    "病符": "boshi_bingfu",
    "大耗": "boshi_dahao",
    "伏兵": "boshi_fubing",
    "官府": "boshi_guanfu",
]

func localizedBoshiName(_ name: String) -> String {
    guard let key = boshiNameMap[name] else { return name }
    return L(key)
}

// MARK: - 歲前十二神

private let suiqianNameMap: [String: String] = [
    "歲建": "suiqian_suijian",
    "晦氣": "suiqian_huiqi",
    "喪門": "suiqian_sangmen",
    "貫索": "suiqian_guansuo",
    "官符": "suiqian_guanfu",
    "小耗": "suiqian_xiaohao",
    "大耗": "suiqian_dahao",
    "龍德": "suiqian_longde",
    "白虎": "suiqian_baihu",
    "天德": "suiqian_tiande",
    "吊客": "suiqian_diaoke",
    "病符": "suiqian_bingfu",
]

func localizedSuiqianName(_ name: String) -> String {
    guard let key = suiqianNameMap[name] else { return name }
    return L(key)
}

// MARK: - 將前十二神

private let jiangqianNameMap: [String: String] = [
    "將星": "jiangqian_jiangxing",
    "攀鞍": "jiangqian_panan",
    "歲馭": "jiangqian_suiyu",
    "息神": "jiangqian_xishen",
    "華蓋": "jiangqian_huagai",
    "劫煞": "jiangqian_jiesha",
    "災煞": "jiangqian_zhaisha",
    "天煞": "jiangqian_tiansha",
    "指背": "jiangqian_zhibei",
    "咸池": "jiangqian_xianchi",
    "月煞": "jiangqian_yuesha",
    "亡神": "jiangqian_wangshen",
]

func localizedJiangqianName(_ name: String) -> String {
    guard let key = jiangqianNameMap[name] else { return name }
    return L(key)
}

// MARK: - 四化

func localizedMutagen(_ trans: String) -> String {
    switch trans {
    case "祿": return L("mutagen_lu")
    case "權": return L("mutagen_quan")
    case "科": return L("mutagen_ke")
    case "忌": return L("mutagen_ji")
    default: return trans
    }
}

// MARK: - 格局名稱

private let patternNameMap: [String: String] = [
    "紫府同宫": "pattern_zifu_tonggong",
    "紫府朝垣": "pattern_zifu_chaoyuan",
    "日月并明": "pattern_riyue_bingming",
    "日月照命": "pattern_riyue_zhaoming",
    "七殺朝斗": "pattern_qisha_chaodou",
    "七殺仰斗": "pattern_qisha_yangdou",
    "機月同梁": "pattern_jiyuetongliang",
    "貪狼守命": "pattern_tanlang_shouming",
    "巨日同宮": "pattern_jumen_taiyang",
    "武貪同行": "pattern_wuqu_tanlang",
    "廉貞七殺": "pattern_lianzhen_qisha",
    "火貪/鈴貪": "pattern_huoling_tanlang2",
    "空宮借星": "pattern_konggong_jiexing",
    "輔弼夾命": "pattern_fubi_jiaming",
    "昌曲夾命": "pattern_changqu_jiaming",
    "權祿夾命": "pattern_quanlu_jiaming",
    "君臣慶會": "pattern_junchen_qinghui",
    "日月反背": "pattern_riyue_fanbei",
    "馬頭帶箭": "pattern_matou_daijian",
    "祿存守命": "pattern_lucun_shouming",
]

func localizedPatternName(_ name: String) -> String {
    guard let key = patternNameMap[name] else { return name }
    return L(key)
}

// MARK: - Convenience extensions

extension PlacedStar {
    var displayName: String { localizedStarName(name) }
}

extension ZiweiPalace {
    var displayName: String { localizedPalaceName(name) }
}

extension Pattern {
    var displayName: String { localizedPatternName(name) }
}
