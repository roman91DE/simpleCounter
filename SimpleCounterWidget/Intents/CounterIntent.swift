import AppIntents
import SimpleCounterCore
import WidgetKit

/// Interactive widget action that increments or decrements the chosen counter.
struct CounterIntent: AppIntent {
    static let title: LocalizedStringResource = "Adjust Counter"

    @Parameter(title: "Counter ID")
    var counterIDString: String

    @Parameter(title: "Delta")
    var delta: Int

    init() {
        counterIDString = ""
        delta = 1
    }

    init(counterID: UUID, delta: Int) {
        counterIDString = counterID.uuidString
        self.delta = delta
    }

    func perform() async throws -> some IntentResult {
        guard let counterID = UUID(uuidString: counterIDString) else {
            return .result()
        }
        let db = try AppDatabase.makeLive()
        let repo = CountEntryRepository(db: db)
        let entry = CountEntry(counterID: counterID, delta: delta)
        try repo.insert(entry)
        WidgetCenter.shared.reloadTimelines(ofKind: "CounterWidget")
        return .result()
    }
}
