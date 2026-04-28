import SwiftUI

// MARK: - 親盤交叉命盤

struct ZiweiChartGridView: View {
    let chart: ZiweiChart
    let client: Client
    let showFlyingStars: Bool
    let selectedDecadalPalaceIndex: Int?
    let selectedYear: Int?
    @State private var selectedPalaceIndex: Int? = nil

    private var genderYinyang: String {
        let stem = chart.fourPillars.year.heavenlyStem
        let isYang = stem.rawValue % 2 == 0
        switch (isYang, client.gender) {
        case (true, .male): return L("label_yang_male")
        case (false, .male): return L("label_yin_male")
        case (true, .female): return L("label_yang_female")
        case (false, .female): return L("label_yin_female")
        }
    }

    private func isHighlighted(index: Int) -> Bool {
        guard let selected = selectedPalaceIndex else { return false }
        let triad = [selected, (selected + 4) % 12, (selected + 6) % 12, (selected + 8) % 12]
        return triad.contains(index)
    }

    private func borrowedStars(for index: Int) -> [PlacedStar] {
        let oppositeIndex = (index + 6) % 12
        return chart.palaces[oppositeIndex].majorStars
    }

    /// 流年十二宮標籤（年命、年父、年夫...）
    private var yearlyPalaceLabels: [Int: String] {
        guard let year = selectedYear else { return [:] }
        let yearBranchIdx = (year - 4) % 12
        let yearlyMingIndex = ((yearBranchIdx >= 0 ? yearBranchIdx : yearBranchIdx + 12) + 10) % 12
        let labels = ["年命", "年兄", "年夫", "年子", "年财", "年疾", "年迁", "年友", "年官", "年田", "年福", "年父"]
        var result: [Int: String] = [:]
        for i in 0..<12 {
            let palaceIndex = (yearlyMingIndex + i) % 12
            result[palaceIndex] = labels[i]
        }
        return result
    }

    /// 每宮的流年歲數列表（所有會落入此宮的流年虛歲）
    private func yearlyAges(for palaceIndex: Int) -> [Int] {
        guard let birthYear = Int(chart.solarDate.prefix(4)) else { return [] }
        var ages: [Int] = []
        for year in (birthYear...birthYear + 120) {
            let yearBranchIdx = (year - 4) % 12
            let yb = yearBranchIdx >= 0 ? yearBranchIdx : yearBranchIdx + 12
            let yearlyMingIndex = (yb + 10) % 12
            let offset = (palaceIndex - yearlyMingIndex + 12) % 12
            if offset == 0 {
                ages.append(year - birthYear + 1)
            }
        }
        return ages
    }

    private func palaceCell(at index: Int) -> some View {
        let flies = showFlyingStars
            ? ZiweiAnalysis.flyingStars(fromPalaceIndex: index, palaces: chart.palaces)
            : []
        let isSelectedDecadal = selectedDecadalPalaceIndex == index
        let yearlyLabel = yearlyPalaceLabels[index]
        return PalaceCell(
            palace: chart.palaces[index],
            isMingGong: chart.mingGongIndex == index,
            isShenGong: chart.shenGongIndex == index,
            isHighlighted: isHighlighted(index: index),
            borrowedMajorStars: borrowedStars(for: index),
            flyingStars: flies,
            horoscope: nil,
            isSelectedDecadal: isSelectedDecadal,
            yearlyLabel: yearlyLabel,
            yearlyAges: yearlyAges(for: index),
            selectedYear: selectedYear
        )
        .onTapGesture {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                if selectedPalaceIndex == index {
                    selectedPalaceIndex = nil
                } else {
                    selectedPalaceIndex = index
                }
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 交叉命盤 — 地支定位：巳午未申(上排), 辰卯(左), 酉戌(右), 寅丑子亥(下排)
            VStack(spacing: 2) {
                // 第一行：巳(3) 午(4) 未(5) 申(6)
                HStack(spacing: 2) {
                    palaceCell(at: 3)
                    palaceCell(at: 4)
                    palaceCell(at: 5)
                    palaceCell(at: 6)
                }

                // 第二、三行：辰(2)/卯(1) 左 + 中央資訊 + 酉(7)/戌(8) 右
                HStack(spacing: 2) {
                    // 左側兩宮（上下堆疊）
                    VStack(spacing: 2) {
                        palaceCell(at: 2)
                        palaceCell(at: 1)
                    }

                    // 中央資訊卡（合併2x2）
                    PalaceCellCenter(chart: chart, client: client, selectedYear: selectedYear)

                    // 右側兩宮（上下堆疊）
                    VStack(spacing: 2) {
                        palaceCell(at: 7)
                        palaceCell(at: 8)
                    }
                }

                // 第四行：寅(0) 丑(11) 子(10) 亥(9)
                HStack(spacing: 2) {
                    palaceCell(at: 0)
                    palaceCell(at: 11)
                    palaceCell(at: 10)
                    palaceCell(at: 9)
                }
            }
            .padding(12)
        }
    }
}

struct FourPillarsItem: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 1) {
            Text(title)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 13, weight: .medium))
        }
    }
}

// MARK: - 中央資訊卡

struct PalaceCellCenter: View {
    let chart: ZiweiChart
    let client: Client
    let selectedYear: Int?

    private let heavenlyStems = ["甲", "乙", "丙", "丁", "戊", "己", "庚", "辛", "壬", "癸"]
    private let earthlyBranches = ["子", "丑", "寅", "卯", "辰", "巳", "午", "未", "申", "酉", "戌", "亥"]

    private func hourDisplay(_ hour: Int) -> String {
        guard let branch = EarthlyBranch(rawValue: hour) else {
            return "\(hour)\(L("label_hour"))"
        }
        return branch.displayName
    }

    private var genderYinyang: String {
        let stem = chart.fourPillars.year.heavenlyStem
        let isYang = stem.rawValue % 2 == 0
        switch (isYang, client.gender) {
        case (true, .male): return L("label_yang_male")
        case (false, .male): return L("label_yin_male")
        case (true, .female): return L("label_yang_female")
        case (false, .female): return L("label_yin_female")
        }
    }

    private var nominalAge: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: client.birthDate, to: Date())
        return max(1, (components.year ?? 0) + 1)
    }

    private var zodiacText: String {
        chart.fourPillars.year.earthlyBranch.zodiac
    }

    private var selectedYearlyInfo: String? {
        guard let year = selectedYear,
              let birthYear = Int(chart.solarDate.prefix(4)) else { return nil }
        let stemIdx = (year - 4) % 10
        let branchIdx = (year - 4) % 12
        let stem = heavenlyStems[stemIdx >= 0 ? stemIdx : stemIdx + 10]
        let branch = earthlyBranches[branchIdx >= 0 ? branchIdx : branchIdx + 12]
        let age = year - birthYear + 1
        return "\(year)/\(stem)\(branch)\(L("year_unit"))/\(L("nominal_age"))\(age)\(L("age_unit"))"
    }

    var body: some View {
        VStack(spacing: 5) {
            // 姓名
            Text(client.name)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)

            // 陰陽 + 虛歲 + 五行局 + 生肖
            HStack(spacing: 6) {
                Text(genderYinyang)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Text("\(nominalAge)\(L("age_unit"))")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Text(chart.wuXingJu.displayName)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Text("\(L("zodiac"))：\(zodiacText)")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            // 選中流年資訊
            if let info = selectedYearlyInfo {
                Text("[\(L("tab_yearly"))：\(info)]")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.blue)
            }

            Divider()
                .padding(.horizontal, 20)

            // 西元出生
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(L("solar_date"))
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                Text(chart.solarDate)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.primary)
                Text(hourDisplay(chart.birthHour))
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }

            // 農曆出生
            if let lunar = chart.lunarDate, !lunar.isEmpty {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(lunar)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.primary)
                }
            }

            // 命主 / 身主
            HStack(spacing: 8) {
                Text("\(L("soul"))：\(localizedStarName(chart.soul))")
                Text("\(L("body"))：\(localizedStarName(chart.body))")
            }
            .font(.system(size: 10))
            .foregroundColor(.secondary)

            Divider()
                .padding(.horizontal, 20)

            // 四柱八字（緊湊顯示）
            HStack(spacing: 12) {
                Text(chart.fourPillars.year.displayName).font(.system(size: 12, weight: .medium))
                Text(chart.fourPillars.month.displayName).font(.system(size: 12, weight: .medium))
                Text(chart.fourPillars.day.displayName).font(.system(size: 12, weight: .medium))
                Text(chart.fourPillars.hour.displayName).font(.system(size: 12, weight: .medium))
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.textBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.15), lineWidth: 0.5)
        )
        .padding(4)
    }
}

// MARK: - 單格宮位

struct PalaceCell: View {
    let palace: ZiweiPalace
    let isMingGong: Bool
    let isShenGong: Bool
    let isHighlighted: Bool
    let borrowedMajorStars: [PlacedStar]
    let flyingStars: [FlyResult]
    let horoscope: HoroscopeData?
    let isSelectedDecadal: Bool
    let yearlyLabel: String?
    let yearlyAges: [Int]
    let selectedYear: Int?

    private var palaceColor: Color {
        if isMingGong { return Color(hex: "#1A73E8") }
        switch palace.name {
        case "命宫":   return Color(hex: "#1A73E8")
        case "父母宫": return Color(hex: "#7986CB")
        case "福德宫": return Color(hex: "#FFB74D")
        case "田宅宫": return Color(hex: "#66BB6A")
        case "官禄宫": return Color(hex: "#EF5350")
        case "交友宫": return Color(hex: "#BA68C8")
        case "迁移宫": return Color(hex: "#4DB6AC")
        case "疾厄宫": return Color(hex: "#E57373")
        case "财帛宫": return Color(hex: "#FF8F00")
        case "子女宫": return Color(hex: "#4FC3F7")
        case "夫妻宫": return Color(hex: "#F06292")
        case "兄弟宫": return Color(hex: "#5C6BC0")
        default: return .gray
        }
    }

    private var changshengName: String {
        localizedChangshengName(palace.changsheng12)
    }

    private var starTransformations: [(star: String, trans: String)] {
        let majors = palace.isEmpty && !borrowedMajorStars.isEmpty ? borrowedMajorStars : palace.majorStars
        let all = majors + palace.minorStars + palace.adjectiveStars
        return all.compactMap { star in
            guard let trans = star.transformation, !trans.isEmpty else { return nil }
            return (star.displayName, trans)
        }
    }

    /// 四化顏色綁定主星
    private func starColor(_ star: PlacedStar) -> Color {
        guard let trans = star.transformation, !trans.isEmpty else { return .primary }
        switch trans {
        case "禄": return Color(hex: "#2E7D32")
        case "权": return Color(hex: "#7B1FA2")
        case "科": return Color(hex: "#1565C0")
        case "忌": return Color(hex: "#C62828")
        default: return .primary
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header: 宮名 + 年齡 + 徽章
            HStack(spacing: 4) {
                Text(palace.displayName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)

                if let decadal = palace.decadal {
                    Text("\(decadal.range.0)~\(decadal.range.1)")
                        .font(.system(size: 9))
                        .foregroundColor(isSelectedDecadal ? .yellow : .white.opacity(0.85))
                }

                Spacer()

                HStack(spacing: 2) {
                    if isMingGong { badge(L("badge_ming")) }
                    if isShenGong { badge(L("badge_shen")) }
                    if palace.isOriginalPalace { badge(L("badge_yin")) }
                    if palace.isEmpty { badge(L("badge_empty")) }
                    if isSelectedDecadal { badge("限") }
                    if let yl = yearlyLabel, !yl.isEmpty { yearlyBadge(yl) }
                }
            }
            .padding(.horizontal, 5)
            .padding(.vertical, 3)
            .background(palaceColor)

            // Stars area (compact horizontal)
            VStack(alignment: .leading, spacing: 1) {
                if palace.isEmpty && !borrowedMajorStars.isEmpty {
                    // 空宮借對宮主星（淡化顯示）
                    HStack(spacing: 3) {
                        ForEach(borrowedMajorStars.prefix(6), id: \.name) { star in
                            Text(star.displayName)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.secondary)
                                .fixedSize()
                        }
                    }
                    .opacity(0.7)
                    HStack(spacing: 3) {
                        ForEach(borrowedMajorStars.prefix(6), id: \.name) { star in
                            Text(star.brightness.displayName)
                                .font(.system(size: 7))
                                .foregroundColor(.secondary)
                                .fixedSize()
                        }
                    }
                    .opacity(0.7)
                    Text(L("label_borrowed"))
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                        .padding(.top, 1)
                } else {
                    // 主星（四化顏色綁定）
                    if !palace.majorStars.isEmpty {
                        HStack(spacing: 3) {
                            ForEach(palace.majorStars.prefix(6), id: \.name) { star in
                                Text(star.displayName)
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(starColor(star))
                                    .fixedSize()
                            }
                        }
                        HStack(spacing: 3) {
                            ForEach(palace.majorStars.prefix(6), id: \.name) { star in
                                Text(star.brightness.displayName)
                                    .font(.system(size: 7))
                                    .foregroundColor(.secondary)
                                    .fixedSize()
                            }
                        }
                    }
                }

                // 輔星（四化顏色綁定）
                if !palace.minorStars.isEmpty {
                    HStack(spacing: 3) {
                        ForEach(palace.minorStars.prefix(8), id: \.name) { star in
                            Text(star.displayName)
                                .font(.system(size: 9))
                                .foregroundColor(starColor(star))
                                .fixedSize()
                        }
                    }
                    HStack(spacing: 3) {
                        ForEach(palace.minorStars.prefix(8), id: \.name) { star in
                            Text(star.brightness.displayName)
                                .font(.system(size: 7))
                                .foregroundColor(.secondary)
                                .fixedSize()
                        }
                    }
                }

                // 雜曜
                if !palace.adjectiveStars.isEmpty {
                    HStack(spacing: 3) {
                        ForEach(palace.adjectiveStars.prefix(10), id: \.name) { star in
                            Text(star.displayName)
                                .font(.system(size: 9))
                                .foregroundColor(.purple)
                                .fixedSize()
                        }
                    }
                }

                // 四化 badges（保留獨立顯示作為備援）
                if !starTransformations.isEmpty {
                    HStack(spacing: 3) {
                        ForEach(starTransformations.prefix(4), id: \.star) { item in
                            Text(localizedMutagen(item.trans))
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 3)
                                .padding(.vertical, 1)
                                .background(transformationColor(item.trans))
                                .cornerRadius(2)
                        }
                    }
                }

                // 飛星四化（簡要顯示）
                if !flyingStars.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(flyingStars.prefix(3), id: \.self) { fly in
                            Text("\(localizedMutagen(fly.transformation))→\(localizedPalaceName(fly.toPalaceName))")
                                .font(.system(size: 7))
                                .foregroundColor(.secondary)
                                .fixedSize()
                        }
                    }
                    .padding(.top, 1)
                }

                Spacer(minLength: 0)

                // 小限與流年歲數
                if !palace.ages.isEmpty || !yearlyAges.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        if !palace.ages.isEmpty {
                            let ageStr = palace.ages.map { String($0) }.joined(separator: ",")
                            Text("\(L("xiao_xian")): \(ageStr)")
                                .font(.system(size: 8))
                                .foregroundColor(.secondary)
                        }
                        if !yearlyAges.isEmpty {
                            let yAgeStr = yearlyAges.map { String($0) }.joined(separator: ",")
                            Text("\(L("yearly_age")): \(yAgeStr)")
                                .font(.system(size: 8))
                                .foregroundColor(Color(hex: "#1565C0"))
                        }
                    }
                }
            }
            .padding(.horizontal, 5)
            .padding(.vertical, 3)
            .frame(maxWidth: .infinity, minHeight: 40, alignment: .topLeading)
            .background(Color(.textBackgroundColor))

            // Footer: 長生/博士/將前/歲前 + 宮干地支
            HStack(spacing: 0) {
                HStack(spacing: 3) {
                    if !changshengName.isEmpty {
                        Text(changshengName)
                            .font(.system(size: 8))
                            .foregroundColor(Color(hex: "#8D6E63"))
                    }
                    if let boshi = palace.boshi12Name, !boshi.isEmpty {
                        Text(localizedBoshiName(boshi))
                            .font(.system(size: 8))
                            .foregroundColor(Color(hex: "#8D6E63"))
                    }
                    if let jiang = palace.jiangqian12, !jiang.isEmpty {
                        Text(localizedJiangqianName(jiang))
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                    }
                    if let sui = palace.suiqian12, !sui.isEmpty {
                        Text(localizedSuiqianName(sui))
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                HStack(spacing: 2) {
                    if let decadal = palace.decadal, isSelectedDecadal {
                        Text(decadal.displayName)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.red)
                    }
                    if let stem = palace.heavenlyStem {
                        Text(stem.displayName)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    if let branch = palace.earthlyBranch {
                        Text(branch.displayName)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.primary)
                    }
                }
            }
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(Color(.windowBackgroundColor).opacity(0.5))
        }
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(borderColor, lineWidth: borderWidth)
        )
    }

    private var borderColor: Color {
        if isMingGong { return Color(hex: "#1A73E8").opacity(0.7) }
        if isHighlighted { return Color(hex: "#FF9800").opacity(0.9) }
        if isSelectedDecadal { return Color(hex: "#F44336").opacity(0.6) }
        return Color.gray.opacity(0.12)
    }

    private var borderWidth: CGFloat {
        if isMingGong || isHighlighted || isSelectedDecadal { return 2 }
        return 0.5
    }

    private func badge(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 8, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 12, height: 12)
            .background(Color.white.opacity(0.25))
            .cornerRadius(2)
    }

    private func yearlyBadge(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 8, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 3)
            .padding(.vertical, 1)
            .background(Color(hex: "#2196F3").opacity(0.9))
            .cornerRadius(2)
    }
            .cornerRadius(2)
    }

    private func transformationColor(_ trans: String) -> Color {
        switch trans {
        case "禄": return Color(hex: "#4CAF50")
        case "权": return Color(hex: "#9C27B0")
        case "科": return Color(hex: "#2196F3")
        case "忌": return Color(hex: "#F44336")
        default: return .gray
        }
    }
}

struct StarsLineCell: View {
    let stars: [PlacedStar]
    let color: Color
    let size: CGFloat
    var weight: Font.Weight = .regular

    var body: some View {
        Text(stars.map { $0.displayName }.joined(separator: ""))
            .font(.system(size: size, weight: weight))
            .foregroundColor(color)
            .lineLimit(1)
            .truncationMode(.tail)
    }
}

// MARK: - 主視圖

struct ChartDisplayView: View {
    let chart: ZiweiChart
    let client: Client
    @State private var selectedTab: ChartTab = .main
    @State private var showFlyingStars: Bool = false

    // Horoscope selection states (shared across main chart and selectors)
    @State private var selectedDecadal: Int = 0
    @State private var selectedYear: Int = 0
    @State private var selectedMonth: Int = 0
    @State private var selectedDay: Int = 0
    @State private var selectedHour: Int = 0

    enum ChartTab: String, CaseIterable {
        case main = "本命"
        case decadal = "大限"
        case yearly = "流年"

        var localizedName: String {
            switch self {
            case .main: return L("tab_natal")
            case .decadal: return L("tab_decadal")
            case .yearly: return L("tab_yearly")
            }
        }
    }

    /// Currently selected decadal palace index (nil if none)
    private var selectedDecadalPalaceIndex: Int? {
        guard selectedDecadal >= 0 else { return nil }
        return selectedDecadal
    }

    /// Currently selected year (nil if none selected / default)
    private var selectedYearValue: Int? {
        guard selectedYear > 0 else { return nil }
        return selectedYear
    }

    var body: some View {
        VStack(spacing: 0) {
            // 頂部工具列
            HStack {
                Text(L("app_title"))
                    .font(.system(size: 18, weight: .semibold))

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                        showFlyingStars.toggle()
                    }
                } label: {
                    Image(systemName: showFlyingStars ? "arrowshape.turn.up.right.fill" : "arrowshape.turn.up.right")
                        .foregroundColor(showFlyingStars ? .blue : .secondary)
                }
                .help(L("help_flying_stars"))

                Picker("", selection: $selectedTab) {
                    ForEach(ChartTab.allCases, id: \.self) { tab in
                        Text(tab.localizedName).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 240)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)

            Divider()

            switch selectedTab {
            case .main:
                VStack(spacing: 0) {
                    ZiweiChartGridView(
                        chart: chart,
                        client: client,
                        showFlyingStars: showFlyingStars,
                        selectedDecadalPalaceIndex: selectedDecadalPalaceIndex,
                        selectedYear: selectedYearValue
                    )
                    HoroscopeSelectorView(
                        chart: chart,
                        selectedDecadal: $selectedDecadal,
                        selectedYear: $selectedYear,
                        selectedMonth: $selectedMonth,
                        selectedDay: $selectedDay,
                        selectedHour: $selectedHour
                    )
                }
            case .decadal:
                DecadalView(chart: chart)
            case .yearly:
                YearlyView(chart: chart)
            }
        }
    }
}

struct DecadalView: View {
    let chart: ZiweiChart

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(0..<12, id: \.self) { index in
                    let palace = chart.palaces[index]
                    decadalRow(palace: palace, index: index)
                }
            }
            .padding()
        }
    }

    private func decadalRow(palace: ZiweiPalace, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("第\(index + 1)\(L("decadal_label")) · \(palace.displayName)")
                    .font(.system(size: 14, weight: .semibold))

                Spacer()

                if let decadal = palace.decadal {
                    Text("\(decadal.range.0)~\(decadal.range.1)\(L("age_unit"))")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text(decadal.displayName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                }
            }

            // 大限主星
            if !palace.majorStars.isEmpty {
                HStack(spacing: 6) {
                    ForEach(palace.majorStars, id: \.name) { star in
                        HStack(spacing: 2) {
                            Text(star.displayName)
                                .font(.system(size: 12, weight: .medium))
                            if let trans = star.transformation, !trans.isEmpty {
                                Text(localizedMutagen(trans))
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 3)
                                    .padding(.vertical, 1)
                                    .background(transColor(trans))
                                    .cornerRadius(2)
                            }
                        }
                    }
                }
            }

            // 大限輔星
            if !palace.minorStars.isEmpty {
                Text(palace.minorStars.map { $0.displayName }.joined(separator: " "))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.textBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.12), lineWidth: 0.5)
        )
    }

    private func transColor(_ trans: String) -> Color {
        switch trans {
        case "禄": return Color(hex: "#4CAF50")
        case "权": return Color(hex: "#9C27B0")
        case "科": return Color(hex: "#2196F3")
        case "忌": return Color(hex: "#F44336")
        default: return .gray
        }
    }
}

struct YearlyView: View {
    let chart: ZiweiChart
    @State private var selectedYearOffset: Int = 0

    private var birthYear: Int {
        let components = chart.solarDate.split(separator: "-").compactMap { Int($0) }
        return components.first ?? 2000
    }

    private var currentYearly: PeriodData? {
        chart.horoscope.yearly
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // 年份選擇器
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(-5..<6, id: \.self) { offset in
                            let year = birthYear + offset
                            Button {
                                withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                                    selectedYearOffset = offset
                                }
                            } label: {
                                Text("\(year)\(L("year_unit"))")
                                    .font(.system(size: 12, weight: selectedYearOffset == offset ? .semibold : .regular))
                                    .foregroundColor(selectedYearOffset == offset ? .white : .primary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(selectedYearOffset == offset ? Color.blue : Color(.textBackgroundColor))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }

                if let yearly = currentYearly {
                    // 流年干支
                    HStack {
                        Text("\(L("current_yearly"))：\(yearly.heavenlyStem.displayName)\(yearly.earthlyBranch.displayName)")
                            .font(.system(size: 14, weight: .semibold))
                        Spacer()
                    }
                    .padding()
                    .background(Color(.textBackgroundColor))
                    .cornerRadius(8)

                    // 流年四化
                    if !yearly.mutagen.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(L("yearly_mutagen"))
                                .font(.system(size: 13, weight: .semibold))
                            HStack(spacing: 8) {
                                ForEach(yearly.mutagen.indices, id: \.self) { i in
                                    let transKeys = ["mutagen_lu", "mutagen_quan", "mutagen_ke", "mutagen_ji"]
                                    let transRaw = ["禄", "权", "科", "忌"][i]
                                    let star = yearly.mutagen[i].displayName
                                    HStack(spacing: 2) {
                                        Text(L(transKeys[i]))
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 2)
                                            .background(transColor(transRaw))
                                            .cornerRadius(2)
                                        Text(star)
                                            .font(.system(size: 12))
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color(.textBackgroundColor))
                        .cornerRadius(8)
                    }

                    // 流耀
                    if !yearly.stars.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(L("yearly_flow_stars"))
                                .font(.system(size: 13, weight: .semibold))
                            Text(yearly.stars.map { $0.displayName }.joined(separator: " "))
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.textBackgroundColor))
                        .cornerRadius(8)
                    }

                    // 歲前十二神
                    if !yearly.suiqian12.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(L("suiqian_12_title"))
                                .font(.system(size: 13, weight: .semibold))
                            Text(yearly.suiqian12.map { localizedSuiqianName($0) }.joined(separator: " "))
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.textBackgroundColor))
                        .cornerRadius(8)
                    }

                    // 將前十二神
                    if !yearly.jiangqian12.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(L("jiangqian_12_title"))
                                .font(.system(size: 13, weight: .semibold))
                            Text(yearly.jiangqian12.map { localizedJiangqianName($0) }.joined(separator: " "))
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.textBackgroundColor))
                        .cornerRadius(8)
                    }
                } else {
                    Text(L("no_yearly_data"))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
            }
            .padding()
        }
    }

    private func transColor(_ trans: String) -> Color {
        switch trans {
        case "禄": return Color(hex: "#4CAF50")
        case "权": return Color(hex: "#9C27B0")
        case "科": return Color(hex: "#2196F3")
        case "忌": return Color(hex: "#F44336")
        default: return .gray
        }
    }
}

#Preview {
    let client = Client(name: "測試", gender: .male, birthDate: Date(), birthTime: .zi)
    let chart = ZiweiCalculator.shared.calculateChart(
        birthYear: 2000,
        birthMonth: 8,
        birthDay: 16,
        birthHour: 2,
        gender: .male
    )
    return ChartDisplayView(chart: chart, client: client)
}
