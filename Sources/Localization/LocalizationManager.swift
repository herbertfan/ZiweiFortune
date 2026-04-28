import Foundation
import SwiftUI
import Combine

final class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    @AppStorage("appLanguage") var storedLanguage: String = "system" {
        didSet {
            objectWillChange.send()
        }
    }

    var language: AppLanguage {
        if storedLanguage == "system" {
            return AppLanguage.effectiveLanguage
        }
        return AppLanguage(rawValue: storedLanguage) ?? .traditionalChinese
    }

    func setLanguage(_ lang: AppLanguage) {
        storedLanguage = lang.rawValue
    }
}

/// Global convenience function for localized strings
func L(_ key: String) -> String {
    Strings.shared.string(key, language: LocalizationManager.shared.language)
}

/// Type-safe string keys
struct StringKey {
    static let appTitle                = "app_title"
    static let chartTitle              = "chart_title"
    static let tabNatal                = "tab_natal"
    static let tabDecadal              = "tab_decadal"
    static let tabYearly               = "tab_yearly"
    static let tabMonthly              = "tab_monthly"
    static let tabDaily                = "tab_daily"
    static let tabHourly               = "tab_hourly"
    static let tabPatterns             = "tab_patterns"
    static let tabKLine                = "tab_kline"
    static let tabAI                   = "tab_ai"
    static let tabClients              = "tab_clients"
    static let tabMatching             = "tab_matching"

    static let settings                = "settings"
    static let language                = "language"
    static let exportPNG               = "export_png"
    static let share                   = "share"
    static let save                    = "save"
    static let cancel                  = "cancel"
    static let close                   = "close"
    static let delete                  = "delete"
    static let edit                    = "edit"
    static let add                     = "add"
    static let search                  = "search"
    static let confirm                 = "confirm"

    static let name                    = "name"
    static let gender                  = "gender"
    static let male                    = "male"
    static let female                  = "female"
    static let birthDate               = "birth_date"
    static let birthTime               = "birth_time"
    static let birthPlace              = "birth_place"
    static let birthInfo               = "birth_info"
    static let contactInfo             = "contact_info"
    static let phone                   = "phone"
    static let email                   = "email"
    static let notes                   = "notes"
    static let solarDate               = "solar_date"
    static let lunarDate               = "lunar_date"
    static let fourPillars             = "four_pillars"
    static let yearPillar              = "year_pillar"
    static let monthPillar             = "month_pillar"
    static let dayPillar               = "day_pillar"
    static let hourPillar              = "hour_pillar"
    static let wuXingJu                = "wuxing_ju"
    static let zodiac                  = "zodiac"
    static let soul                    = "soul"
    static let body                    = "body"
    static let nominalAge              = "nominal_age"
    static let age                     = "age"

    static let mingGong                = "ming_gong"
    static let shenGong                = "shen_gong"
    static let laiYin                  = "lai_yin"
    static let xiaoXian                = "xiao_xian"
    static let decadalRange            = "decadal_range"
    static let currentDecadal          = "current_decadal"
    static let currentYearly           = "current_yearly"
    static let selectYear              = "select_year"
    static let selectMonth             = "select_month"
    static let selectDay               = "select_day"
    static let selectHour              = "select_hour"

    static let palaceNames             = "palace_names"
    static let starBrightness          = "star_brightness"
    static let mutagen                 = "mutagen"
    static let flowStars               = "flow_stars"
    static let suiQian12               = "suiqian_12"
    static let jiangQian12             = "jiangqian_12"
    static let changSheng12            = "changsheng_12"
    static let boShi12                 = "boshi_12"

    static let patterns                = "patterns"
    static let noPatterns              = "no_patterns"
    static let patternSupreme          = "pattern_supreme"
    static let patternHigh             = "pattern_high"
    static let patternMedium           = "pattern_medium"
    static let patternSpecial          = "pattern_special"

    static let lifeFortune             = "life_fortune"
    static let fortuneScore            = "fortune_score"
    static let goodFortune             = "good_fortune"
    static let normalFortune           = "normal_fortune"
    static let lowFortune              = "low_fortune"

    static let aiInterpretation        = "ai_interpretation"
    static let aiScopeNatal            = "ai_scope_natal"
    static let aiScopeDecadal          = "ai_scope_decadal"
    static let aiScopeYearly           = "ai_scope_yearly"
    static let aiScopePalace           = "ai_scope_palace"
    static let aiGenerating            = "ai_generating"
    static let aiPromptPlaceholder     = "ai_prompt_placeholder"
    static let aiSend                  = "ai_send"

    static let clients                 = "clients"
    static let clientList              = "client_list"
    static let newClient               = "new_client"
    static let editClient              = "edit_client"
    static let importClients           = "import_clients"
    static let exportClients           = "export_clients"
    static let doubleClickHint         = "double_click_hint"

    static let coupleMatching          = "couple_matching"
    static let personA                 = "person_a"
    static let personB                 = "person_b"
    static let selectPerson            = "select_person"
    static let compare                 = "compare"

    static let tabCharting             = "tab_charting"
    static let searchClients           = "search_clients"
    static let noClients               = "no_clients"
    static let addClientHint           = "add_client_hint"
    static let chart                   = "chart"
    static let importResult            = "import_result"
    static let addedX                  = "added_x"
    static let skippedX                = "skipped_x"
    static let renamedX                = "renamed_x"
    static let noClientsImported       = "no_clients_imported"

    static let interpretationScope     = "interpretation_scope"
    static let aiSettings              = "ai_settings"
    static let modelProvider           = "model_provider"
    static let provider                = "provider"
    static let apiConfig               = "api_config"
    static let apiKeyLocal             = "api_key_local"
    static let pleaseSetAPIKey         = "please_set_api_key"
    static let openSettings            = "open_settings"
    static let clickAIInterpret        = "click_ai_interpret"
    static let aiTheoryDesc            = "ai_theory_desc"
    static let error                   = "error"
    static let unknownError            = "unknown_error"
    static let pleaseConfigAPIKey      = "please_config_api_key"

    static let klineDesc               = "kline_desc"
    static let ageUnit                 = "age_unit"
    static let scoreUnit               = "score_unit"
    static let ageLabel                = "age_label"
    static let palaceLabel             = "palace_label"
    static let palace                  = "palace"
    static let modelName               = "model_name"
    static let generationFailed        = "generation_failed"
    static let majorStarsLabel         = "major_stars_label"
    static let mutagenLabel            = "mutagen_label"
    static let noteLabel               = "note_label"
    static let decadalLabel            = "decadal_label"

    static let noPatternsDesc          = "no_patterns_desc"

    static let matchingAnalysis        = "matching_analysis"
    static let selectTwoClients        = "select_two_clients"
    static let selectClient            = "select_client"
    static let chartComparison         = "chart_comparison"
    static let mingGongComparison      = "ming_gong_comparison"
    static let spouseComparison        = "spouse_comparison"
    static let mutagenComparison       = "mutagen_comparison"
    static let patternComparison       = "pattern_comparison"
    static let matchingInterpretation  = "matching_interpretation"
    static let generating              = "generating"
    static let clickMatchingAnalysis   = "click_matching_analysis"

    static let langSystem              = "lang_system"
    static let shareSheetTitle         = "share_sheet_title"
    static let exportSuccess           = "export_success"
    static let exportFailed            = "export_failed"
}

final class Strings {
    static let shared = Strings()

    private var data: [AppLanguage: [String: String]] = [:]

    init() {
        loadJSON()
    }

    private func loadJSON() {
        let mapping: [(AppLanguage, String)] = [
            (.traditionalChinese, "zh-Hant"),
            (.simplifiedChinese,  "zh-Hans"),
            (.japanese,           "ja"),
        ]
        for (lang, fileName) in mapping {
            if let url = Bundle.main.url(forResource: fileName, withExtension: "json"),
               let raw = try? Data(contentsOf: url),
               let dict = try? JSONDecoder().decode([String: String].self, from: raw) {
                data[lang] = dict
            }
        }
    }

    func string(_ key: String, language: AppLanguage) -> String {
        data[language]?[key] ?? key
    }
}
