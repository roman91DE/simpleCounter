import Foundation
import Observation
import SimpleCounterCore

@Observable
final class CounterListViewModel {
    private(set) var counters: [Counter] = []
    private(set) var currentCounts: [UUID: Int] = [:]
    var errorMessage: String?

    let counterRepository: CounterRepository
    let entryRepository: CountEntryRepository
    private var observationTask: Task<Void, Never>?

    init(counterRepository: CounterRepository, entryRepository: CountEntryRepository) {
        self.counterRepository = counterRepository
        self.entryRepository = entryRepository
        startObserving()
    }

    deinit {
        observationTask?.cancel()
    }

    // MARK: - Public

    @MainActor
    func refresh() {
        reloadCounts(for: counters)
    }

    func delete(_ counter: Counter) {
        do {
            try counterRepository.delete(counter)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Private

    private func startObserving() {
        observationTask = Task { @MainActor in
            do {
                for try await updated in counterRepository.observeAll() {
                    counters = updated
                    reloadCounts(for: updated)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    @MainActor
    private func reloadCounts(for counters: [Counter]) {
        var counts: [UUID: Int] = [:]
        for counter in counters {
            let period = PeriodCalculator.currentPeriod(for: counter.resetInterval)
            counts[counter.id] = (try? entryRepository.sumDelta(for: counter.id, in: period)) ?? 0
        }
        currentCounts = counts
    }
}
