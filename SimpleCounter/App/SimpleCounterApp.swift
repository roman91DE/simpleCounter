import SimpleCounterCore
import SwiftUI

@main
struct SimpleCounterApp: App {
    @State private var appDatabase: AppDatabase = {
        do {
            return try AppDatabase.makeLive()
        } catch {
            fatalError("Failed to open database: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            CounterListView(
                viewModel: CounterListViewModel(
                    counterRepository: CounterRepository(db: appDatabase),
                    entryRepository: CountEntryRepository(db: appDatabase)
                )
            )
        }
    }
}
