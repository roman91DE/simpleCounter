import XCTest
@testable import SimpleCounterCore

final class CountEntryRepositoryTests: XCTestCase {
    func test_sumDelta_returnsZeroWhenNoEntries() throws {
        let db = try AppDatabase.makeInMemory()
        let repo = CountEntryRepository(db: db)
        let counterID = UUID()
        let period = PeriodCalculator.currentPeriod(for: .daily)

        let total = try repo.sumDelta(for: counterID, in: period)

        XCTAssertEqual(total, 0)
    }

    func test_sumDelta_sumsPositiveDeltas() throws {
        let db = try AppDatabase.makeInMemory()
        let counterRepo = CounterRepository(db: db)
        let entryRepo = CountEntryRepository(db: db)
        let counter = Counter(name: "Test", emoji: "🔢", resetInterval: .daily)
        try counterRepo.insert(counter)
        let period = PeriodCalculator.currentPeriod(for: .daily)

        try entryRepo.insert(CountEntry(counterID: counter.id, delta: 1, timestamp: period.start + 1))
        try entryRepo.insert(CountEntry(counterID: counter.id, delta: 1, timestamp: period.start + 2))
        try entryRepo.insert(CountEntry(counterID: counter.id, delta: 1, timestamp: period.start + 3))
        let total = try entryRepo.sumDelta(for: counter.id, in: period)

        XCTAssertEqual(total, 3)
    }

    func test_sumDelta_handlesDecrements() throws {
        let db = try AppDatabase.makeInMemory()
        let counterRepo = CounterRepository(db: db)
        let entryRepo = CountEntryRepository(db: db)
        let counter = Counter(name: "Test", emoji: "🔢", resetInterval: .daily)
        try counterRepo.insert(counter)
        let period = PeriodCalculator.currentPeriod(for: .daily)

        try entryRepo.insert(CountEntry(counterID: counter.id, delta: 1, timestamp: period.start + 1))
        try entryRepo.insert(CountEntry(counterID: counter.id, delta: 1, timestamp: period.start + 2))
        try entryRepo.insert(CountEntry(counterID: counter.id, delta: -1, timestamp: period.start + 3))
        let total = try entryRepo.sumDelta(for: counter.id, in: period)

        XCTAssertEqual(total, 1)
    }

    func test_sumDelta_excludesEntriesOutsidePeriod() throws {
        let db = try AppDatabase.makeInMemory()
        let counterRepo = CounterRepository(db: db)
        let entryRepo = CountEntryRepository(db: db)
        let counter = Counter(name: "Test", emoji: "🔢", resetInterval: .daily)
        try counterRepo.insert(counter)
        let period = PeriodCalculator.currentPeriod(for: .daily)

        // Inside period
        try entryRepo.insert(CountEntry(counterID: counter.id, delta: 5, timestamp: period.start + 1))
        // Before period start
        try entryRepo.insert(CountEntry(counterID: counter.id, delta: 100, timestamp: period.start - 1))
        // At period end (exclusive)
        try entryRepo.insert(CountEntry(counterID: counter.id, delta: 100, timestamp: period.end))
        let total = try entryRepo.sumDelta(for: counter.id, in: period)

        XCTAssertEqual(total, 5)
    }

    func test_sumDelta_doesNotIncludeOtherCounters() throws {
        let db = try AppDatabase.makeInMemory()
        let counterRepo = CounterRepository(db: db)
        let entryRepo = CountEntryRepository(db: db)
        let counterA = Counter(name: "A", emoji: "🅰️", resetInterval: .daily)
        let counterB = Counter(name: "B", emoji: "🅱️", resetInterval: .daily)
        try counterRepo.insert(counterA)
        try counterRepo.insert(counterB)
        let period = PeriodCalculator.currentPeriod(for: .daily)

        try entryRepo.insert(CountEntry(counterID: counterA.id, delta: 3, timestamp: period.start + 1))
        try entryRepo.insert(CountEntry(counterID: counterB.id, delta: 99, timestamp: period.start + 2))
        let total = try entryRepo.sumDelta(for: counterA.id, in: period)

        XCTAssertEqual(total, 3)
    }

    func test_fetchEntries_returnsOnlyEntriesInPeriod() throws {
        let db = try AppDatabase.makeInMemory()
        let counterRepo = CounterRepository(db: db)
        let entryRepo = CountEntryRepository(db: db)
        let counter = Counter(name: "Test", emoji: "🔢", resetInterval: .daily)
        try counterRepo.insert(counter)
        let period = PeriodCalculator.currentPeriod(for: .daily)

        let inside = CountEntry(counterID: counter.id, delta: 1, timestamp: period.start + 1)
        let outside = CountEntry(counterID: counter.id, delta: 1, timestamp: period.start - 1)
        try entryRepo.insert(inside)
        try entryRepo.insert(outside)
        let result = try entryRepo.fetchEntries(for: counter.id, in: period)

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].id, inside.id)
    }

    func test_historyByPeriod_returnsCorrectNumberOfPeriods() throws {
        let db = try AppDatabase.makeInMemory()
        let counterRepo = CounterRepository(db: db)
        let entryRepo = CountEntryRepository(db: db)
        let counter = Counter(name: "Test", emoji: "🔢", resetInterval: .daily)
        try counterRepo.insert(counter)

        let history = try entryRepo.historyByPeriod(for: counter.id, interval: .daily, last: 7)

        XCTAssertEqual(history.count, 7)
    }
}
