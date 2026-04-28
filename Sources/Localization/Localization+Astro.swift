import Foundation

// MARK: - Palace Name Localization

private let palaceNameMap: [String: String] = [
    "命宫": "palace_ming",
    "父母宫": "palace_parent",
    "福德宫": "palace_fortune",
    "田宅宫": "palace_property",
    "官禄宫": "palace_career",
    "交友宫": "palace_friend",
    "迁移宫": "palace_travel",
    "疾厄宫": "palace_health",
    "财帛宫": "palace_wealth",
    "子女宫": "palace_children",
    "夫妻宫": "palace_spouse",
    "兄弟宫": "palace_sibling",
]

func localizedPalaceName(_ name: String) -> String {
    guard let key = palaceNameMap[name] else { return name }
    return L(key)
}

// MARK: - Star Name Localization

private let starNameMap: [String: String] = [
    // 十四主星
    "紫微": "star_ziwei",
    "天机": "star_tianji",
    "太阳": "star_taiyang",
    "武曲": "star_wuqu",
    "天同": "star_tiantong",
    "廉贞": "star_lianzhen",
    "天府": "star_tianfu",
    "太阴": "star_taiyin",
    "贪狼": "star_tanlang",
    "巨门": "star_jumen",
    "天相": "star_tianxiang",
    "天梁": "star_tianliang",
    "七杀": "star_qisha",
    "破军": "star_pojun",
    // 六吉星
    "左辅": "star_zuofu",
    "右弼": "star_youbi",
    "文昌": "star_wenchang",
    "文曲": "star_wenqu",
    "天魁": "star_tiankui",
    "天钺": "star_tianyue",
    // 六煞星
    "禄存": "star_lucun",
    "擎羊": "star_qingyang",
    "陀罗": "star_tuoluo",
    "火星": "star_huoxing",
    "铃星": "star_lingxing",
    "地劫": "star_dijie",
    "地空": "star_dikong",
    // 其他
    "天马": "star_tianma",
    // 杂曜
    "红鸾": "star_hongluan",
    "天喜": "star_tianxi",
    "龙池": "star_longchi",
    "凤阁": "star_fengge",
    "华盖": "star_huagai",
    "咸池": "star_xianchi",
    "孤辰": "star_guchen",
    "寡宿": "star_guasu",
    "天才": "star_tiancai",
    "天寿": "star_tianshou",
    "天哭": "star_tianku",
    "天虚": "star_tianxu",
    "劫杀": "star_jiesha",
    "大耗": "star_dahao",
    "天德": "star_tiande",
    "月德": "star_yuede",
    "天空": "star_tiankong",
    "年解": "star_nianjie",
    "蜚廉": "star_feilian",
    "破碎": "star_posui",
    "截路": "star_jielu",
    "空亡": "star_kongwang",
    "天厨": "star_tianchu",
    "天官": "star_tianguan",
    "天福": "star_tianfu",
    "旬空": "star_xunkong",
    "天伤": "star_tianshang",
    "天使": "star_tianshi",
    "天姚": "star_tianyao",
    "天刑": "star_tianxing",
    "阴煞": "star_yinsha",
    "天月": "star_tianyue2",
    "天巫": "star_tianwu",
    "月解": "star_yuejie",
    "三台": "star_santai",
    "八座": "star_bazuo",
    "恩光": "star_engguang",
    "天贵": "star_tiangui",
    "台辅": "star_taifu",
    "封诰": "star_fenggao",
]

func localizedStarName(_ name: String) -> String {
    guard let key = starNameMap[name] else { return name }
    return L(key)
}

// MARK: - 长生十二神

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
    "青龙": "boshi_qinglong",
    "小耗": "boshi_xiaohao",
    "将军": "boshi_jiangjun",
    "奏书": "boshi_zoushu",
    "飞廉": "boshi_feilian",
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

// MARK: - 岁前十二神

private let suiqianNameMap: [String: String] = [
    "岁建": "suiqian_suijian",
    "晦气": "suiqian_huiqi",
    "丧门": "suiqian_sangmen",
    "贯索": "suiqian_guansuo",
    "官符": "suiqian_guanfu",
    "小耗": "suiqian_xiaohao",
    "大耗": "suiqian_dahao",
    "龙德": "suiqian_longde",
    "白虎": "suiqian_baihu",
    "天德": "suiqian_tiande",
    "吊客": "suiqian_diaoke",
    "病符": "suiqian_bingfu",
]

func localizedSuiqianName(_ name: String) -> String {
    guard let key = suiqianNameMap[name] else { return name }
    return L(key)
}

// MARK: - 将前十二神

private let jiangqianNameMap: [String: String] = [
    "将星": "jiangqian_jiangxing",
    "攀鞍": "jiangqian_panan",
    "岁驿": "jiangqian_suiyi",
    "息神": "jiangqian_xishen",
    "华盖": "jiangqian_huagai",
    "劫煞": "jiangqian_jiesha",
    "灾煞": "jiangqian_zhaisha",
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
    case "禄": return L("mutagen_lu")
    case "权": return L("mutagen_quan")
    case "科": return L("mutagen_ke")
    case "忌": return L("mutagen_ji")
    default: return trans
    }
}

// MARK: - 格局名称

private let patternNameMap: [String: String] = [
    "紫府同宫": "pattern_zifu_tonggong",
    "紫府朝垣": "pattern_zifu_chaoyuan",
    "日月并明": "pattern_riyue_bingming",
    "日月照命": "pattern_riyue_zhaoming",
    "七杀朝斗": "pattern_qisha_chaodou",
    "七杀仰斗": "pattern_qisha_yangdou",
    "机月同梁": "pattern_jiyuetongliang",
    "贪狼守命": "pattern_tanlang_shouming",
    "巨日同宫": "pattern_jumen_taiyang",
    "武贪同行": "pattern_wuqu_tanlang",
    "廉贞七杀": "pattern_lianzhen_qisha",
    "火贪/铃贪": "pattern_huoling_tanlang2",
    "空宫借星": "pattern_konggong_jiexing",
    "辅弼夹命": "pattern_fubi_jiaming",
    "昌曲夹命": "pattern_changqu_jiaming",
    "权禄夹命": "pattern_quanlu_jiaming",
    "君臣庆会": "pattern_junchen_qinghui",
    "日月反背": "pattern_riyue_fanbei",
    "马头带箭": "pattern_matou_daijian",
    "禄存守命": "pattern_lucun_shouming",
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
