import AppIntents
import SimpleCounterCore

/// Represents a single Counter as a selectable AppEntity for the widget configuration picker.
struct CounterEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Counter"
    static var defaultQuery = CounterEntityQuery()

    /// Stored as a UUID string so it satisfies EntityIdentifier requirements.
    let id: String
    let name: String
    let emoji: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(emoji) \(name)")
    }
}

struct CounterEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [CounterEntity] {
        let db = try AppDatabase.makeLive()
        let repo = CounterRepository(db: db)
        return try repo.fetchAll()
            .filter { identifiers.contains($0.id.uuidString) }
            .map { CounterEntity(id: $0.id.uuidString, name: $0.name, emoji: $0.emoji) }
    }

    func suggestedEntities() async throws -> [CounterEntity] {
        let db = try AppDatabase.makeLive()
        let repo = CounterRepository(db: db)
        return try repo.fetchAll()
            .map { CounterEntity(id: $0.id.uuidString, name: $0.name, emoji: $0.emoji) }
    }
}
