import Foundation
import GRDB

/// Errors thrown by `AppDatabase`.
public enum AppDatabaseError: Error {
    case appGroupUnavailable(String)
}

/// Shared database accessor. Owns the GRDB connection pool and applies all migrations.
///
/// Create one instance at app startup and pass it into repositories via dependency injection.
/// Both the main app and the widget extension use the same App Group container path.
public final class AppDatabase {
    private static let appGroupID = "group.com.romanhorvath.simplecounter"

    public let dbWriter: DatabaseWriter

    // MARK: - Factory

    /// Opens (or creates) the production SQLite database in the App Group container.
    public static func makeLive() throws -> AppDatabase {
        guard let containerURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
        else {
            throw AppDatabaseError.appGroupUnavailable(appGroupID)
        }
        let dbURL = containerURL.appendingPathComponent("db.sqlite")
        let dbPool = try DatabasePool(path: dbURL.path)
        return try AppDatabase(dbWriter: dbPool)
    }

    /// Creates a transient in-memory database for unit tests.
    public static func makeInMemory() throws -> AppDatabase {
        let dbQueue = try DatabaseQueue()
        return try AppDatabase(dbWriter: dbQueue)
    }

    /// Returns a transient in-memory database for use in SwiftUI previews only.
    public static func makePreview() -> AppDatabase {
        // swiftlint:disable:next force_try
        try! makeInMemory()
    }

    // MARK: - Init

    init(dbWriter: DatabaseWriter) throws {
        self.dbWriter = dbWriter
        try migrate(dbWriter)
    }

    // MARK: - Migrations

    private func migrate(_ writer: DatabaseWriter) throws {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1_initial_schema") { database in
            try database.create(table: "counter") { table in
                table.column("id", .blob).primaryKey()
                table.column("name", .text).notNull()
                table.column("emoji", .text).notNull()
                table.column("resetInterval", .text).notNull()
                table.column("goal", .integer)
                table.column("createdAt", .datetime).notNull()
            }

            try database.create(table: "count_entry") { table in
                table.column("id", .blob).primaryKey()
                table.column("counterID", .blob).notNull()
                    .indexed()
                    .references("counter", onDelete: .cascade)
                table.column("delta", .integer).notNull()
                table.column("timestamp", .datetime).notNull().indexed()
            }
        }

        try migrator.migrate(writer)
    }
}
