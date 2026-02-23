import XCTest
@testable import SimpleCounterCore

final class CounterRepositoryTests: XCTestCase {
    func test_fetchAll_returnsEmptyWhenNoneInserted() throws {
        let db = try AppDatabase.makeInMemory()
        let repo = CounterRepository(db: db)

        let result = try repo.fetchAll()

        XCTAssertTrue(result.isEmpty)
    }

    func test_insert_counterAppearsInFetchAll() throws {
        let db = try AppDatabase.makeInMemory()
        let repo = CounterRepository(db: db)
        let counter = Counter(name: "Water", emoji: "💧", resetInterval: .daily)

        try repo.insert(counter)
        let result = try repo.fetchAll()

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].name, "Water")
    }

    func test_fetchAll_returnsCountersOrderedByCreationDate() throws {
        let db = try AppDatabase.makeInMemory()
        let repo = CounterRepository(db: db)
        let first = Counter(
            name: "A",
            emoji: "🅰️",
            resetInterval: .daily,
            createdAt: Date(timeIntervalSinceReferenceDate: 0)
        )
        let second = Counter(
            name: "B",
            emoji: "🅱️",
            resetInterval: .daily,
            createdAt: Date(timeIntervalSinceReferenceDate: 1)
        )

        try repo.insert(second)
        try repo.insert(first)
        let result = try repo.fetchAll()

        XCTAssertEqual(result[0].name, "A")
        XCTAssertEqual(result[1].name, "B")
    }

    func test_update_persistsChangedFields() throws {
        let db = try AppDatabase.makeInMemory()
        let repo = CounterRepository(db: db)
        var counter = Counter(name: "Gum", emoji: "🍬", resetInterval: .daily)
        try repo.insert(counter)

        counter.name = "Nicotine Gum"
        counter.goal = 10
        try repo.update(counter)
        let result = try repo.fetchAll()

        XCTAssertEqual(result[0].name, "Nicotine Gum")
        XCTAssertEqual(result[0].goal, 10)
    }

    func test_delete_removesCounterFromFetchAll() throws {
        let db = try AppDatabase.makeInMemory()
        let repo = CounterRepository(db: db)
        let counter = Counter(name: "Steps", emoji: "👟", resetInterval: .daily)
        try repo.insert(counter)

        try repo.delete(counter)
        let result = try repo.fetchAll()

        XCTAssertTrue(result.isEmpty)
    }

    func test_delete_cascadesCountEntries() throws {
        let db = try AppDatabase.makeInMemory()
        let counterRepo = CounterRepository(db: db)
        let entryRepo = CountEntryRepository(db: db)
        let counter = Counter(name: "Coffee", emoji: "☕️", resetInterval: .daily)
        try counterRepo.insert(counter)
        try entryRepo.insert(CountEntry(counterID: counter.id, delta: 1))

        try counterRepo.delete(counter)
        let period = PeriodCalculator.currentPeriod(for: .daily)
        let entries = try entryRepo.fetchEntries(for: counter.id, in: period)

        XCTAssertTrue(entries.isEmpty)
    }
}
