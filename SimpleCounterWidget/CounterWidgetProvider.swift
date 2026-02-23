import AppIntents
import SimpleCounterCore
import SwiftUI
import WidgetKit

struct CounterWidgetProvider: AppIntentTimelineProvider {
    func placeholder(in _: Context) -> CounterWidgetEntry {
        CounterWidgetEntry(date: .now, counter: .preview, currentCount: 7)
    }

    func snapshot(for configuration: CounterConfigurationIntent, in _: Context) async -> CounterWidgetEntry {
        makeEntry(for: configuration) ?? CounterWidgetEntry(date: .now, counter: .preview, currentCount: 7)
    }

    func timeline(for configuration: CounterConfigurationIntent, in _: Context) async -> Timeline<CounterWidgetEntry> {
        let entry = makeEntry(for: configuration) ?? CounterWidgetEntry(date: .now, counter: nil, currentCount: 0)
        // Refresh every 15 minutes so counts stay reasonably fresh
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 15, to: .now)
            ?? Date(timeIntervalSinceNow: 900)
        return Timeline(entries: [entry], policy: .after(nextRefresh))
    }

    // MARK: - Private

    private func makeEntry(for configuration: CounterConfigurationIntent) -> CounterWidgetEntry? {
        guard let db = try? AppDatabase.makeLive() else { return nil }
        let counterRepo = CounterRepository(db: db)
        let entryRepo = CountEntryRepository(db: db)

        guard let allCounters = try? counterRepo.fetchAll(), !allCounters.isEmpty else { return nil }

        let counter: Counter
        if let selectedIDString = configuration.counter?.id,
           let found = allCounters.first(where: { $0.id.uuidString == selectedIDString }) {
            counter = found
        } else {
            guard let first = allCounters.first else { return nil }
            counter = first
        }

        let period = PeriodCalculator.currentPeriod(for: counter.resetInterval)
        let count = (try? entryRepo.sumDelta(for: counter.id, in: period)) ?? 0
        return CounterWidgetEntry(date: .now, counter: counter, currentCount: count)
    }
}
