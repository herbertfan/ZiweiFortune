import SwiftUI

// MARK: - 運限選擇列

struct HoroscopeSelectorView: View {
    let chart: ZiweiChart

    @Binding var selectedDecadal: Int
    @Binding var selectedYear: Int
    @Binding var selectedMonth: Int
    @Binding var selectedDay: Int
    @Binding var selectedHour: Int

    private let heavenlyStems = ["甲", "乙", "丙", "丁", "戊", "己", "庚", "辛", "壬", "癸"]
    private let earthlyBranches = ["子", "丑", "寅", "卯", "辰", "巳", "午", "未", "申", "酉", "戌", "亥"]

    // 大限選項
    private var decadalOptions: [(index: Int, label: String)] {
        chart.palaces.enumerated().compactMap { i, palace in
            guard let decadal = palace.decadal else { return nil }
            let label = "\(decadal.range.0)~\(decadal.range.1) \(decadal.displayName)\(L("decadal_label"))"
            return (i, label)
        }
    }

    // 出生年份
    private var birthYear: Int {
        let components = chart.solarDate.split(separator: "-").compactMap { Int($0) }
        return components.first ?? 2000
    }

    // 流年選項（出生年前後各30年）
    private var yearlyOptions: [(index: Int, label: String)] {
        Array((birthYear - 30)...(birthYear + 30)).map { year in
            let stemIdx = (year - 4) % 10
            let branchIdx = (year - 4) % 12
            let stem = heavenlyStems[stemIdx >= 0 ? stemIdx : stemIdx + 10]
            let branch = earthlyBranches[branchIdx >= 0 ? branchIdx : branchIdx + 12]
            let age = year - birthYear + 1
            let label = "\(year)\(L("year_unit")) \(stem)\(branch)\(age)\(L("age_unit"))"
            return (year, label)
        }
    }

    // 流月選項
    private var monthlyOptions: [(index: Int, label: String)] {
        let baseYear = selectedYear > 0 ? selectedYear : birthYear
        return (1...12).map { month in
            let monthStemIdx = (baseYear - 4 + month - 1) % 10
            let monthBranchIdx = (month + 1) % 12
            let stem = heavenlyStems[monthStemIdx >= 0 ? monthStemIdx : monthStemIdx + 10]
            let branch = earthlyBranches[monthBranchIdx >= 0 ? monthBranchIdx : monthBranchIdx + 12]
            let label = "\(L("month_\(month)"))\(stem)\(branch)"
            return (month, label)
        }
    }

    // 流日選項
    private var dailyOptions: [(index: Int, label: String)] {
        let baseYear = selectedYear > 0 ? selectedYear : birthYear
        let baseMonth = selectedMonth > 0 ? selectedMonth : 1
        return (1...30).map { day in
            let dayStemIdx = (baseYear - 4 + baseMonth - 1 + day - 1) % 10
            let dayBranchIdx = (day - 1) % 12
            let stem = heavenlyStems[dayStemIdx >= 0 ? dayStemIdx : dayStemIdx + 10]
            let branch = earthlyBranches[dayBranchIdx >= 0 ? dayBranchIdx : dayBranchIdx + 12]
            let label = "\(day)\(L("label_day"))\(stem)\(branch)"
            return (day, label)
        }
    }

    // 流時選項
    private var hourlyOptions: [(index: Int, label: String)] {
        (0...11).map { hour in
            let label = EarthlyBranch(rawValue: hour)?.displayName ?? "\(hour)"
            return (hour, label)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            VStack(spacing: 4) {
                selectorRow(title: L("tab_decadal"), options: decadalOptions.map { ($0.index, $0.label) }, selection: $selectedDecadal)
                selectorRow(title: L("tab_yearly"), options: yearlyOptions, selection: $selectedYear)
                selectorRow(title: L("tab_monthly"), options: monthlyOptions, selection: $selectedMonth)
                selectorRow(title: L("tab_daily"), options: dailyOptions, selection: $selectedDay)
                selectorRow(title: L("tab_hourly"), options: hourlyOptions, selection: $selectedHour)
            }
            .padding(.vertical, 6)
            .background(Color(.textBackgroundColor))
        }
    }

    private func selectorRow(title: String, options: [(index: Int, label: String)], selection: Binding<Int>) -> some View {
        HStack(spacing: 0) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.primary)
                .frame(width: 36, alignment: .leading)
                .padding(.leading, 12)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(options, id: \.index) { option in
                        Text(option.label)
                            .font(.system(size: 10))
                            .foregroundColor(selection.wrappedValue == option.index ? .blue : .secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .overlay(
                                Rectangle()
                                    .fill(selection.wrappedValue == option.index ? Color.blue : Color.clear)
                                    .frame(height: 2)
                                    .padding(.horizontal, 2)
                                , alignment: .bottom
                            )
                            .onTapGesture {
                                withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                                    if selection.wrappedValue == option.index {
                                        selection.wrappedValue = -1
                                    } else {
                                        selection.wrappedValue = option.index
                                    }
                                }
                            }
                    }
                }
                .padding(.horizontal, 8)
            }
        }
        .frame(height: 28)
    }
}
