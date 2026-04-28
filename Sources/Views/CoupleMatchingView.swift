import SwiftUI

struct CoupleMatchingView: View {
    @EnvironmentObject var clientStore: ClientStore
    @EnvironmentObject var chartStore: ChartStore
    @State private var personA: Client?
    @State private var personB: Client?
    @State private var chartA: ZiweiChart?
    @State private var chartB: ZiweiChart?
    @State private var showingSelectorA = false
    @State private var showingSelectorB = false
    @State private var interpretationText = ""
    @State private var isLoading = false
    @State private var showingSettings = false

    var body: some View {
        VStack(spacing: 0) {
            // 顶部选择栏
            HStack(spacing: 20) {
                PersonSelector(label: L("person_a"), client: personA) {
                    showingSelectorA = true
                }

                Image(systemName: "heart.fill")
                    .foregroundColor(.pink)
                    .font(.title2)

                PersonSelector(label: L("person_b"), client: personB) {
                    showingSelectorB = true
                }

                Spacer()

                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.borderless)

                Button {
                    Task { await generateMatch() }
                } label: {
                    Image(systemName: "wand.and.stars")
                    Text(L("matching_analysis"))
                }
                .buttonStyle(.borderedProminent)
                .disabled(personA == nil || personB == nil || isLoading || !SettingsStore.shared.isConfigured)
            }
            .padding()

            Divider()

            if let a = chartA, let b = chartB {
                CoupleAnalysisView(chartA: a, chartB: b, interpretation: interpretationText, isLoading: isLoading)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "person.2")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    Text(L("select_two_clients"))
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.textBackgroundColor))
            }
        }
        .sheet(isPresented: $showingSelectorA) {
            ClientPickerSheet(clients: clientStore.clients, selectedClient: $personA)
        }
        .sheet(isPresented: $showingSelectorB) {
            ClientPickerSheet(clients: clientStore.clients, selectedClient: $personB)
        }
        .sheet(isPresented: $showingSettings) {
            LLMSettingsView()
        }
        .onChange(of: personA) { _, new in
            if let client = new {
                chartA = chartStore.calculateChart(for: client)
            } else {
                chartA = nil
            }
        }
        .onChange(of: personB) { _, new in
            if let client = new {
                chartB = chartStore.calculateChart(for: client)
            } else {
                chartB = nil
            }
        }
    }

    private func generateMatch() async {
        guard let a = chartA, let b = chartB, let ca = personA, let cb = personB else { return }
        guard SettingsStore.shared.isConfigured else { return }

        isLoading = true
        interpretationText = ""
        defer { isLoading = false }

        let prompt = buildMatchPrompt(chartA: a, chartB: b, clientA: ca, clientB: cb)
        let stream = await LLMService.shared.streamChat(
            config: SettingsStore.shared.llmConfig,
            prompt: prompt
        )

        do {
            for try await chunk in stream {
                await MainActor.run {
                    interpretationText += chunk
                }
            }
        } catch {
            await MainActor.run {
                interpretationText = "\(L("generation_failed")): \(error.localizedDescription)"
            }
        }
    }

    private func buildMatchPrompt(chartA: ZiweiChart, chartB: ZiweiChart, clientA: Client, clientB: Client) -> String {
        var prompt = "你是一位精通紫微斗数合盘分析的专家。请对以下两位命主进行合盘分析。\n\n"
        prompt += "【甲方：\(clientA.name)】\n"
        prompt += chartSummary(chart: chartA, client: clientA)
        prompt += "\n【乙方：\(clientB.name)】\n"
        prompt += chartSummary(chart: chartB, client: clientB)

        // 四化互飞分析
        prompt += "\n【四化互飞分析】\n"
        let aToB = analyzeMutagenFlight(from: chartA, to: chartB)
        let bToA = analyzeMutagenFlight(from: chartB, to: chartA)
        prompt += "甲方对乙方：\(aToB)\n"
        prompt += "乙方对甲方：\(bToA)\n"

        // 夫妻宫交叉
        prompt += "\n【夫妻宫交叉】\n"
        let aSpouse = chartA.palaces.first { $0.name == "夫妻宫" }
        let bSpouse = chartB.palaces.first { $0.name == "夫妻宫" }
        if let asp = aSpouse, let bsp = bSpouse {
            prompt += "甲方夫妻宫：\(asp.majorStars.map { $0.name }.joined(separator: "、"))\n"
            prompt += "乙方夫妻宫：\(bsp.majorStars.map { $0.name }.joined(separator: "、"))\n"
        }

        prompt += "\n【分析要求】\n"
        prompt += "1. 分析双方命格的互补性与冲突点\n"
        prompt += "2. 四化互飞对彼此的影响（生助 vs 刑克）\n"
        prompt += "3. 夫妻宫星曜的匹配度\n"
        prompt += "4. 感情发展的吉凶与注意事项\n"
        prompt += "5. 给出整体合盘评价与建议\n"

        return prompt
    }

    private func chartSummary(chart: ZiweiChart, client: Client) -> String {
        var s = ""
        s += "性别：\(client.gender.rawValue)\n"
        s += "五行局：\(chart.wuXingJu.rawValue)\n"
        s += "命宫：\(chart.mingGong.name) - \(chart.mingGong.majorStars.map { $0.name }.joined(separator: "、"))\n"
        s += "夫妻宫：\(chart.palaces.first { $0.name == "夫妻宫" }?.majorStars.map { $0.name }.joined(separator: "、") ?? "")\n"
        s += "四化：\(chart.mingGong.mutagens.map { "\($0.star)\($0.transformation)" }.joined(separator: " "))\n"
        return s
    }

    private func analyzeMutagenFlight(from: ZiweiChart, to: ZiweiChart) -> String {
        var results: [String] = []
        for fly in from.allFlyingStars {
            if let targetPalace = to.palaces.first(where: { $0.name == fly.toPalaceName }) {
                let meaning = flyMeaning(transformation: fly.transformation)
                results.append("\(fly.fromPalaceName)化\(fly.transformation)\(fly.starName)→入乙方\(fly.toPalaceName)：\(meaning)")
            }
        }
        return results.isEmpty ? "无明显四化影响" : results.joined(separator: "；")
    }

    private func flyMeaning(transformation: String) -> String {
        switch transformation {
        case "禄": return "生助、缘分"
        case "权": return "掌控、主导"
        case "科": return "文昌、和睦"
        case "忌": return "刑克、纠缠"
        default: return ""
        }
    }
}

struct PersonSelector: View {
    let label: String
    let client: Client?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(label)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if let c = client {
                        Text(c.name)
                            .font(.headline)
                        Text("\(c.gender.displayName) · \(c.birthDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text(L("select_client"))
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.down")
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(width: 200)
            .background(Color(.textBackgroundColor))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

struct ClientPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let clients: [Client]
    @Binding var selectedClient: Client?
    @State private var searchText = ""
    @State private var hoveredID: UUID? = nil

    var filtered: [Client] {
        if searchText.isEmpty { return clients }
        return clients.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(L("select_client"))
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button(L("close")) { dismiss() }
                    .keyboardShortcut(.escape)
            }
            .padding()

            Divider()

            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField(L("search"), text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(12)
            .background(Color(.textBackgroundColor))

            Divider()

            List {
                ForEach(filtered) { client in
                    Button {
                        selectedClient = client
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(client.name)
                                    .font(.headline)
                                Text("\(client.gender.displayName) · \(client.birthDate.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if selectedClient?.id == client.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                    .buttonStyle(PressableRowStyle())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        selectedClient?.id == client.id
                            ? Color.accentColor.opacity(0.12)
                            : (hoveredID == client.id ? Color.accentColor.opacity(0.06) : Color.clear)
                    )
                    .onHover { hovering in
                        withAnimation(.easeInOut(duration: 0.08)) {
                            hoveredID = hovering ? client.id : nil
                        }
                    }
                }
            }
            .listStyle(.plain)
        }
        .frame(width: 400, height: 500)
    }
}

struct CoupleAnalysisView: View {
    let chartA: ZiweiChart
    let chartB: ZiweiChart
    let interpretation: String
    let isLoading: Bool

    var body: some View {
        HSplitView {
            // 左侧：命盘对比
            VStack(spacing: 0) {
                Text(L("chart_comparison"))
                    .font(.headline)
                    .padding()

                Divider()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ComparisonSection(title: L("ming_gong_comparison")) {
                            ComparisonRow(label: L("person_a"), value: "\(chartA.mingGong.displayName): \(chartA.mingGong.majorStars.map { $0.displayName }.joined(separator: "、"))")
                            ComparisonRow(label: L("person_b"), value: "\(chartB.mingGong.displayName): \(chartB.mingGong.majorStars.map { $0.displayName }.joined(separator: "、"))")
                        }

                        ComparisonSection(title: L("spouse_comparison")) {
                            let aSpouse = chartA.palaces.first { $0.name == "夫妻宫" }
                            let bSpouse = chartB.palaces.first { $0.name == "夫妻宫" }
                            ComparisonRow(label: L("person_a"), value: "\(aSpouse?.displayName ?? ""): \(aSpouse?.majorStars.map { $0.displayName }.joined(separator: "、") ?? "")")
                            ComparisonRow(label: L("person_b"), value: "\(bSpouse?.displayName ?? ""): \(bSpouse?.majorStars.map { $0.displayName }.joined(separator: "、") ?? "")")
                        }

                        ComparisonSection(title: L("mutagen_comparison")) {
                            let aMutagens = chartA.palaces.flatMap { $0.mutagens }.map { "\(localizedStarName($0.star))\(localizedMutagen($0.transformation))" }.joined(separator: " ")
                            let bMutagens = chartB.palaces.flatMap { $0.mutagens }.map { "\(localizedStarName($0.star))\(localizedMutagen($0.transformation))" }.joined(separator: " ")
                            ComparisonRow(label: L("person_a"), value: aMutagens)
                            ComparisonRow(label: L("person_b"), value: bMutagens)
                        }

                        ComparisonSection(title: L("pattern_comparison")) {
                            ComparisonRow(label: L("person_a"), value: chartA.patterns.map { $0.displayName }.joined(separator: "、"))
                            ComparisonRow(label: L("person_b"), value: chartB.patterns.map { $0.displayName }.joined(separator: "、"))
                        }
                    }
                    .padding()
                }
            }
            .frame(minWidth: 300, maxWidth: 400)

            // 右侧：AI解读
            VStack(spacing: 0) {
                Text(L("matching_interpretation"))
                    .font(.headline)
                    .padding()

                Divider()

                if isLoading && interpretation.isEmpty {
                    VStack {
                        Spacer()
                        ProgressView(L("generating"))
                        Spacer()
                    }
                } else if interpretation.isEmpty {
                    VStack {
                        Spacer()
                        Text(L("click_matching_analysis"))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        Text(interpretation)
                            .font(.system(size: 14))
                            .lineSpacing(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                }
            }
            .frame(minWidth: 500)
            .background(Color(.textBackgroundColor))
        }
    }
}

struct ComparisonSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.primary)
            content
            Divider()
        }
    }
}

struct ComparisonRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .frame(width: 40, alignment: .leading)
            Text(value)
                .font(.system(size: 13))
            Spacer()
        }
    }
}
