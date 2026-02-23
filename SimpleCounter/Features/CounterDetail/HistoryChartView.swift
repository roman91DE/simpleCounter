import Charts
import SimpleCounterCore
import SwiftUI

struct HistoryChartView: View {
    let history: [(DateInterval, Int)]
    let interval: ResetInterval

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("History")
                .font(.headline)

            Chart(chartData, id: \.label) { item in
                BarMark(
                    x: .value("Period", item.label),
                    y: .value("Count", item.count)
                )
                .foregroundStyle(.blue.gradient)
                .cornerRadius(4)
            }
            .frame(height: 160)
        }
        .accessibilityLabel("History chart showing last \(history.count) \(interval.displayName) periods")
    }

    // MARK: - Private

    private var chartData: [ChartItem] {
        history.map { period, count in
            ChartItem(label: label(for: period.start), count: count)
        }
    }

    private func label(for date: Date) -> String {
        let formatter = DateFormatter()
        switch interval {
        case .daily:
            formatter.dateFormat = "E"
        case .weekly:
            formatter.dateFormat = "MMM d"
        case .monthly:
            formatter.dateFormat = "MMM"
        case .yearly:
            formatter.dateFormat = "yyyy"
        }
        return formatter.string(from: date)
    }
}

private struct ChartItem {
    let label: String
    let count: Int
}

#Preview {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: .now)
    let history: [(DateInterval, Int)] = (0 ..< 7).reversed().compactMap { offset in
        guard
            let start = calendar.date(byAdding: .day, value: -offset, to: today),
            let end = calendar.date(byAdding: .day, value: 1, to: start)
        else { return nil }
        return (DateInterval(start: start, end: end), Int.random(in: 0 ... 12))
    }
    HistoryChartView(history: history, interval: .daily)
        .padding()
}
