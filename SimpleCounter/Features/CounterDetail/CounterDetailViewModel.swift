import Foundation
import Observation
import SimpleCounterCore
import WidgetKit

@Observable
final class CounterDetailViewModel {
    private(set) var counter: Counter
    private(set) var currentCount: Int = 0
    private(set) var history: [(DateInterval, Int)] = []
    var errorMessage: String?

    private let counterRepository: CounterRepository
    private let entryRepository: CountEntryRepository
    private var observationTask: Task<Void, Never>?

    init(
        counter: Counter,
        counterRepository: CounterRepository,
        entryRepository: CountEntryRepository
    ) {
        self.counter = counter
        self.counterRepository = counterRepository
        self.entryRepository = entryRepository
        reload()
        startObserving()
    }

    deinit {
        observationTask?.cancel()
    }

    // MARK: - Public

    func increment() {
        insertEntry(delta: 1)
    }

    func decrement() {
        insertEntry(delta: -1)
    }

    // MARK: - Private

    private func insertEntry(delta: Int) {
        do {
            let entry = CountEntry(counterID: counter.id, delta: delta)
            try entryRepository.insert(entry)
            reload()
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func reload() {
        do {
            let period = PeriodCalculator.currentPeriod(for: counter.resetInterval)
            currentCount = try entryRepository.sumDelta(for: counter.id, in: period)
            history = try entryRepository.historyByPeriod(for: counter.id, interval: counter.resetInterval, last: 7)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func startObserving() {
        observationTask = Task { @MainActor in
            do {
                for try await counters in counterRepository.observeAll() {
                    if let updated = counters.first(where: { $0.id == counter.id }) {
                        counter = updated
                    }
                    reload()
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
