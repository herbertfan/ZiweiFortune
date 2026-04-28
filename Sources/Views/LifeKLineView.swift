import SwiftUI

struct LifeKLineView: View {
    let chart: ZiweiChart

    @State private var selectedAge: Int?
    @State private var hoverAge: Int?
    @State private var scrollOffset: CGFloat = 0

    private var klinePoints: [ZiweiAnalysis.KLinePoint] {
        ZiweiAnalysis.calculateLifeKLine(chart: chart)
    }

    private var minScore: Double { klinePoints.map { $0.score }.min() ?? 0 }
    private var maxScore: Double { klinePoints.map { $0.score }.max() ?? 100 }

    var body: some View {
        VStack(spacing: 0) {
            // 顶部信息
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L("life_fortune"))
                        .font(.system(size: 18, weight: .bold))
                    Text(L("kline_desc"))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                Spacer()
                if let age = hoverAge ?? selectedAge,
                   let point = klinePoints.first(where: { $0.age == age }) {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(age)\(L("age_unit"))")
                            .font(.system(size: 14, weight: .bold))
                        Text("\(String(format: "%.0f", point.score))\(L("score_unit"))")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(scoreColor(point.score))
                        Text(localizedPalaceName(point.palaceName))
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        if !point.note.isEmpty {
                            Text(point.note)
                                .font(.system(size: 11))
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            .padding()

            Divider()

            // 图表区域
            GeometryReader { geometry in
                let barWidth: CGFloat = 8
                let spacing: CGFloat = 2
                let totalWidth = CGFloat(klinePoints.count) * (barWidth + spacing)
                let chartHeight = geometry.size.height - 40

                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: true) {
                        ZStack(alignment: .bottomLeading) {
                            // 基准线
                            HStack(spacing: 0) {
                                ForEach(klinePoints) { point in
                                    VStack(spacing: 0) {
                                        Spacer()
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(barColor(point.score, isSelected: point.age == (hoverAge ?? selectedAge)))
                                            .frame(width: barWidth, height: barHeight(point.score, maxHeight: chartHeight))
                                    }
                                    .frame(width: barWidth + spacing)
                                    .contentShape(Rectangle())
                                    .onHover { hovering in
                                        if hovering {
                                            hoverAge = point.age
                                        } else if hoverAge == point.age {
                                            hoverAge = nil
                                        }
                                    }
                                    .onTapGesture {
                                        selectedAge = point.age
                                    }
                                    .id(point.age)
                                }
                            }
                            .frame(width: totalWidth, height: chartHeight)

                            // 50分参考线
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: totalWidth, height: 1)
                                .offset(y: chartHeight * 0.5)
                        }
                    }
                    .onAppear {
                        // 滚动到当前年龄附近（假设当前30岁）
                        let currentAge = 30
                        withAnimation {
                            proxy.scrollTo(currentAge, anchor: .center)
                        }
                    }
                }
            }
            .frame(height: 300)
            .padding(.horizontal)

            // 底部图例
            HStack(spacing: 20) {
                LegendItem(color: .green, label: L("good_fortune"))
                LegendItem(color: .blue, label: L("normal_fortune"))
                LegendItem(color: .red, label: L("low_fortune"))
                Spacer()
            }
            .padding()

            Divider()

            // 详细信息面板
            if let age = selectedAge,
               let point = klinePoints.first(where: { $0.age == age }) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        DetailRow(label: L("age_label"), value: "\(point.age)\(L("age_unit"))")
                        DetailRow(label: L("fortune_score"), value: "\(String(format: "%.1f", point.score))\(L("score_unit"))")
                        DetailRow(label: L("palace_label"), value: localizedPalaceName(point.palaceName))
                        DetailRow(label: L("major_stars_label"), value: point.majorStars.map { localizedStarName($0) }.joined(separator: "、") )
                        if !point.mutagens.isEmpty {
                            DetailRow(label: L("mutagen_label"), value: point.mutagens.map { localizedMutagen($0) }.joined(separator: "、"))
                        }
                        if !point.note.isEmpty {
                            DetailRow(label: L("note_label"), value: point.note)
                        }

                        // 大限信息
                        if let decadal = chart.palaces.first(where: { $0.ages.contains(age) })?.decadal {
                            DetailRow(label: L("decadal_label"), value: "\(decadal.displayName)（\(decadal.range.0)-\(decadal.range.1)\(L("age_unit"))）")
                        }
                    }
                    .padding()
                }
                .frame(maxHeight: 200)
                .background(Color(.textBackgroundColor))
            }
        }
    }

    private func barHeight(_ score: Double, maxHeight: CGFloat) -> CGFloat {
        CGFloat(score / 100.0) * maxHeight
    }

    private func barColor(_ score: Double, isSelected: Bool) -> Color {
        if isSelected { return .orange }
        if score >= 70 { return .green.opacity(0.7) }
        if score >= 40 { return .blue.opacity(0.6) }
        return .red.opacity(0.6)
    }

    private func scoreColor(_ score: Double) -> Color {
        if score >= 70 { return .green }
        if score >= 40 { return .blue }
        return .red
    }
}

struct LegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 12, height: 12)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .leading)
            Text(value)
                .font(.system(size: 13, weight: .medium))
            Spacer()
        }
    }
}
