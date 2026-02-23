import Foundation
import GRDB

/// Defines the read/write API for `Counter` records.
public protocol CounterRepositoryProtocol {
    /// Returns all counters, ordered by creation date ascending.
    func fetchAll() throws -> [Counter]

    /// Inserts a new counter record.
    func insert(_ counter: Counter) throws

    /// Saves updated fields on an existing counter record.
    func update(_ counter: Counter) throws

    /// Deletes a counter and all associated `CountEntry` records (via cascade).
    func delete(_ counter: Counter) throws

    /// Returns an async stream that emits the full counter list whenever it changes.
    func observeAll() -> AsyncThrowingStream<[Counter], Error>
}

/// GRDB-backed implementation of `CounterRepositoryProtocol`.
public struct CounterRepository: CounterRepositoryProtocol {
    let db: AppDatabase

    public init(db: AppDatabase) {
        self.db = db
    }

    // MARK: - CounterRepositoryProtocol

    /// Returns all counters, ordered by creation date ascending.
    public func fetchAll() throws -> [Counter] {
        try db.dbWriter.read { db in
            try Counter.order(Counter.Columns.createdAt.asc).fetchAll(db)
        }
    }

    /// Inserts a new counter record.
    public func insert(_ counter: Counter) throws {
        try db.dbWriter.write { db in
            try counter.insert(db)
        }
    }

    /// Saves updated fields on an existing counter record.
    public func update(_ counter: Counter) throws {
        try db.dbWriter.write { db in
            try counter.update(db)
        }
    }

    /// Deletes a counter and all associated `CountEntry` records (via cascade).
    public func delete(_ counter: Counter) throws {
        try db.dbWriter.write { db in
            _ = try counter.delete(db)
        }
    }

    /// Returns an async stream that emits the full counter list whenever it changes.
    public func observeAll() -> AsyncThrowingStream<[Counter], Error> {
        let observation = ValueObservation.tracking { db in
            try Counter.order(Counter.Columns.createdAt.asc).fetchAll(db)
        }
        return AsyncThrowingStream { continuation in
            let cancellable = observation.start(
                in: db.dbWriter,
                onError: { continuation.finish(throwing: $0) },
                onChange: { continuation.yield($0) }
            )
            continuation.onTermination = { _ in cancellable.cancel() }
        }
    }
}
