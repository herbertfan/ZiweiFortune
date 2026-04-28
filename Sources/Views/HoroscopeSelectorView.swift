import SwiftUI

// MARK: - 運限選擇列

struct HoroscopeSelectorView: View {
    let chart: ZiweiChart

    @State private var selectedDecadal: Int = 0
    @State private var selectedYear: Int = 0
    @State private var selectedMonth: Int = 0
    @State private var selectedDay: Int = 0
    @State private var selectedHour: Int = 0

    // 大限選項
    private var decadalOptions: [(index: Int, label: String)] {
        chart.palaces.enumerated().compactMap { i, palace in
            guard let decadal = palace.decadal else { return nil }
            let label = "\(decadal.range.0)~\(decadal.range.1)"
            return (i, label)
        }
    }

    // 流年選項（出生年前後各30年）
    private var birthYear: Int {
        // 嘗試從 solarDate 解析年份，否則從四柱年干推算近似的
        let components = chart.solarDate.split(separator: "-").compactMap { Int($0) }
        if let year = components.first {
            return year
        }
        // fallback: 從 createdAt 或 default
        return 2000
    }

    private var yearlyOptions: [Int] {
        Array((birthYear - 30)...(birthYear + 30))
    }

    // 流月選項
    private var monthlyOptions: [(index: Int, label: String)] {
        (1...12).map { ($0, L("month_\($0)")) }
    }

    // 流日選項
    private var dailyOptions: [(index: Int, label: String)] {
        (1...30).map { ($0, "\($0)\(L("label_day"))") }
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
                selectorRow(title: L("tab_yearly"), options: yearlyOptions.map { ($0, "\($0)\(L("year_unit"))") }, selection: $selectedYear)
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
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(selection.wrappedValue == option.index ? Color.blue.opacity(0.1) : Color.clear)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(selection.wrappedValue == option.index ? Color.blue.opacity(0.4) : Color.clear, lineWidth: 1)
                            )
                            .onTapGesture {
                                withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                                    selection.wrappedValue = option.index
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
