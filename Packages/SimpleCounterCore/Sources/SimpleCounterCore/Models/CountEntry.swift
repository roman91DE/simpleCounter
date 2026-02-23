import Foundation
import GRDB

/// A single increment or decrement event for a counter.
///
/// Counts for a period are derived by summing `delta` values within the period window.
/// There is no separate periods table.
public struct CountEntry: Identifiable, Hashable, Codable, FetchableRecord, PersistableRecord {
    public var id: UUID
    public var counterID: UUID
    /// Positive for increment, negative for decrement.
    public var delta: Int
    public var timestamp: Date

    public init(
        id: UUID = UUID(),
        counterID: UUID,
        delta: Int,
        timestamp: Date = .now
    ) {
        self.id = id
        self.counterID = counterID
        self.delta = delta
        self.timestamp = timestamp
    }

    // MARK: - GRDB

    public static let databaseTableName = "count_entry"

    public enum Columns {
        static let id = Column(CodingKeys.id)
        static let counterID = Column(CodingKeys.counterID)
        static let delta = Column(CodingKeys.delta)
        static let timestamp = Column(CodingKeys.timestamp)
    }
}
