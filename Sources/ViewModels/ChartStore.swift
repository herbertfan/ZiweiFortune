import Foundation
import Combine

final class ChartStore: ObservableObject {
    @Published var currentChart: ZiweiChart?
    @Published var charts: [ZiweiChart] = []

    private let calculator = ZiweiCalculator.shared

    func calculateChart(for client: Client) -> ZiweiChart {
        let chart = calculator.calculateChart(
            birthYear: extractYear(from: client.birthDate),
            birthMonth: extractMonth(from: client.birthDate),
            birthDay: extractDay(from: client.birthDate),
            birthHour: client.birthTime.rawValue,
            gender: client.gender
        )
        currentChart = chart

        if let index = charts.firstIndex(where: { $0.clientId == client.id }) {
            charts[index] = chart
        } else {
            charts.append(chart)
        }

        return chart
    }

    func clearCurrentChart() {
        currentChart = nil
    }

    private func extractYear(from date: Date) -> Int {
        Calendar.current.component(.year, from: date)
    }

    private func extractMonth(from date: Date) -> Int {
        Calendar.current.component(.month, from: date)
    }

    private func extractDay(from date: Date) -> Int {
        Calendar.current.component(.day, from: date)
    }
}