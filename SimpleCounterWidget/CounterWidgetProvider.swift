import SimpleCounterCore
import SwiftUI
import WidgetKit

struct CounterWidgetProvider: TimelineProvider {
    func placeholder(in _: Context) -> CounterWidgetEntry {
        CounterWidgetEntry(date: .now, counter: .preview, currentCount: 7)
    }

    func getSnapshot(in _: Context, completion: @escaping (CounterWidgetEntry) -> Void) {
        let entry = makeEntry() ?? CounterWidgetEntry(date: .now, counter: .preview, currentCount: 7)
        completion(entry)
    }

    func getTimeline(in _: Context, completion: @escaping (Timeline<CounterWidgetEntry>) -> Void) {
        let entry = makeEntry() ?? CounterWidgetEntry(date: .now, counter: nil, currentCount: 0)
        // Refresh every 15 minutes so counts stay reasonably fresh
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 15, to: .now)
            ?? Date(timeIntervalSinceNow: 900)
        let timeline = Timeline(entries: [entry], policy: .after(nextRefresh))
        completion(timeline)
    }

    // MARK: - Private

    private func makeEntry() -> CounterWidgetEntry? {
        guard let db = try? AppDatabase.makeLive() else { return nil }
        let counterRepo = CounterRepository(db: db)
        let entryRepo = CountEntryRepository(db: db)

        guard let counter = try? counterRepo.fetchAll().first else { return nil }
        let period = PeriodCalculator.currentPeriod(for: counter.resetInterval)
        let count = (try? entryRepo.sumDelta(for: counter.id, in: period)) ?? 0
        return CounterWidgetEntry(date: .now, counter: counter, currentCount: count)
    }
}
