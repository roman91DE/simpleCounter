import Foundation
import GRDB

/// The reset cadence for a counter.
public enum ResetInterval: String, Codable, CaseIterable, DatabaseValueConvertible {
    case daily
    case weekly
    case monthly
    case yearly

    /// Human-readable label for display in UI.
    public var displayName: String {
        switch self {
        case .daily: "daily"
        case .weekly: "weekly"
        case .monthly: "monthly"
        case .yearly: "yearly"
        }
    }
}

/// A single counter tracking a recurring habit.
public struct Counter: Identifiable, Hashable, Codable, FetchableRecord, PersistableRecord {
    public var id: UUID
    public var name: String
    public var emoji: String
    public var resetInterval: ResetInterval
    /// Optional upper bound the user is aiming to stay within (or reach).
    public var goal: Int?
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        emoji: String,
        resetInterval: ResetInterval,
        goal: Int? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.resetInterval = resetInterval
        self.goal = goal
        self.createdAt = createdAt
    }

    // MARK: - GRDB

    public static let databaseTableName = "counter"

    public enum Columns {
        static let id = Column(CodingKeys.id)
        static let name = Column(CodingKeys.name)
        static let emoji = Column(CodingKeys.emoji)
        static let resetInterval = Column(CodingKeys.resetInterval)
        static let goal = Column(CodingKeys.goal)
        static let createdAt = Column(CodingKeys.createdAt)
    }
}

// MARK: - Preview support

public extension Counter {
    static let preview = Counter(
        name: "Nicotine Gum",
        emoji: "🍬",
        resetInterval: .daily,
        goal: 10
    )
}
