import Foundation
import GRDB

/// Defines the read/write API for `CountEntry` records.
public protocol CountEntryRepositoryProtocol {
    /// Inserts a new count entry.
    func insert(_ entry: CountEntry) throws

    /// Returns all entries for `counterID` whose timestamp falls within `period`.
    func fetchEntries(for counterID: UUID, in period: DateInterval) throws -> [CountEntry]

    /// Returns the sum of `delta` values for `counterID` within `period`.
    /// Returns `0` if there are no matching entries.
    func sumDelta(for counterID: UUID, in period: DateInterval) throws -> Int

    /// Returns the summed delta per period for the last `count` periods, ordered oldest to newest.
    func historyByPeriod(for counterID: UUID, interval: ResetInterval, last count: Int) throws -> [(DateInterval, Int)]
}

/// GRDB-backed implementation of `CountEntryRepositoryProtocol`.
public struct CountEntryRepository: CountEntryRepositoryProtocol {
    private let db: AppDatabase

    public init(db: AppDatabase) {
        self.db = db
    }

    // MARK: - CountEntryRepositoryProtocol

    /// Inserts a new count entry.
    public func insert(_ entry: CountEntry) throws {
        try db.dbWriter.write { db in
            try entry.insert(db)
        }
    }

    /// Returns all entries for `counterID` whose timestamp falls within `period`.
    public func fetchEntries(for counterID: UUID, in period: DateInterval) throws -> [CountEntry] {
        try db.dbWriter.read { db in
            try CountEntry
                .filter(CountEntry.Columns.counterID == counterID)
                .filter(CountEntry.Columns.timestamp >= period.start)
                .filter(CountEntry.Columns.timestamp < period.end)
                .order(CountEntry.Columns.timestamp.asc)
                .fetchAll(db)
        }
    }

    /// Returns the sum of `delta` values for `counterID` within `period`.
    public func sumDelta(for counterID: UUID, in period: DateInterval) throws -> Int {
        try db.dbWriter.read { db in
            let sum = try CountEntry
                .filter(CountEntry.Columns.counterID == counterID)
                .filter(CountEntry.Columns.timestamp >= period.start)
                .filter(CountEntry.Columns.timestamp < period.end)
                .select(sum(CountEntry.Columns.delta), as: Int.self)
                .fetchOne(db)
            return sum ?? 0
        }
    }

    /// Returns the summed delta per period for the last `count` periods, ordered oldest to newest.
    public func historyByPeriod(for counterID: UUID, interval: ResetInterval, last count: Int) throws -> [(
        DateInterval,
        Int
    )] {
        let periods = PeriodCalculator.previousPeriods(for: interval, last: count)
        return try periods.map { period in
            let total = try sumDelta(for: counterID, in: period)
            return (period, total)
        }
    }
}
