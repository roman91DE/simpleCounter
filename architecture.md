# Simple Counter — Architecture

## Overview

Simple Counter is structured around three concerns that must stay cleanly separated:

1. **Core** — data models, database access, and business logic. Shared between the main app and the widget extension.
2. **App** — SwiftUI views and view models for the main iOS application.
3. **Widget** — WidgetKit views and AppIntent handlers for the home screen widget.

The architecture pattern is **MVVM** with an explicit **Repository layer**. Views know only about ViewModels. ViewModels know only about Repositories. Repositories know only about the database.

---

## Directory Tree

```
simpleCounter/
├── SimpleCounter.xcodeproj
│
├── Packages/
│   └── SimpleCounterCore/              # Local Swift Package — shared by app + widget
│       ├── Package.swift
│       ├── Sources/
│       │   └── SimpleCounterCore/
│       │       ├── Models/
│       │       │   ├── Counter.swift           # Counter struct + ResetInterval enum
│       │       │   └── CountEntry.swift        # CountEntry struct
│       │       ├── Database/
│       │       │   └── AppDatabase.swift       # GRDB setup, shared DB location, migrations
│       │       ├── Repositories/
│       │       │   ├── CounterRepository.swift      # CRUD for Counter
│       │       │   └── CountEntryRepository.swift   # CRUD for CountEntry, period queries
│       │       └── PeriodCalculator.swift           # Computes period start/end from ResetInterval
│       └── Tests/
│           └── SimpleCounterCoreTests/
│               ├── CounterRepositoryTests.swift
│               ├── CountEntryRepositoryTests.swift
│               └── PeriodCalculatorTests.swift
│
├── SimpleCounter/                      # Main app target
│   ├── App/
│   │   └── SimpleCounterApp.swift      # @main, app entry point, injects environment
│   ├── Features/
│   │   ├── CounterList/
│   │   │   ├── CounterListView.swift       # Root screen — list of counter cards
│   │   │   ├── CounterCardView.swift       # Single card component
│   │   │   └── CounterListViewModel.swift
│   │   ├── CounterDetail/
│   │   │   ├── CounterDetailView.swift     # +/− buttons, stats, chart
│   │   │   ├── HistoryChartView.swift      # Bar chart (Swift Charts)
│   │   │   └── CounterDetailViewModel.swift
│   │   └── AddEditCounter/
│   │       └── AddEditCounterView.swift    # Sheet for creating/editing — state via @State
│   └── Resources/
│       ├── Assets.xcassets
│       └── Info.plist
│
├── SimpleCounterWidget/               # Widget extension target
│   ├── SimpleCounterWidgetBundle.swift     # Widget bundle entry point
│   ├── CounterWidget.swift                 # Small interactive widget
│   ├── CounterWidgetEntry.swift            # TimelineEntry model
│   ├── CounterWidgetProvider.swift         # Timeline provider
│   ├── Intents/
│   │   └── CounterIntent.swift             # AppIntent for +/− with direction parameter
│   └── Info.plist
│
└── SimpleCounterUITests/              # One end-to-end UI flow test
    └── CounterFlowUITests.swift
```

---

## Local Swift Package: SimpleCounterCore

All logic that must be shared between the main app and the widget lives in a **local Swift Package** at `Packages/SimpleCounterCore/`. Both the app target and the widget extension declare it as a dependency in Xcode.

This boundary is enforced structurally — not by convention. If a type is needed by the widget, it belongs in the Core package.

### What lives in Core

| Module | Responsibility |
|---|---|
| `Models/` | Plain Swift structs. No SwiftUI, no GRDB imports at the call site. |
| `Database/` | GRDB setup, App Group container path, schema migrations. |
| `Repositories/` | All database reads and writes. Returns model types, not raw rows. |
| `PeriodCalculator` | Given a `ResetInterval` and a date, returns the current period's start and end. No database dependency. |

### What does NOT live in Core

- SwiftUI views
- ViewModels
- AppIntents
- WidgetKit types

---

## Dependency Graph

```
SimpleCounter (app)
  └── SimpleCounterCore (local package)
        └── GRDB.swift (via SPM)

SimpleCounterWidget (extension)
  └── SimpleCounterCore (local package)
        └── GRDB.swift (via SPM)

SimpleCounterCoreTests (package-internal)
  └── GRDB.swift (in-memory, for testing)
```

No circular dependencies. The widget never imports anything from the app target.

---

## Dependencies

All dependencies are managed via **Swift Package Manager**. No CocoaPods, no Carthage.

| Package | Source | Purpose |
|---|---|---|
| [GRDB.swift](https://github.com/groue/GRDB.swift) | GitHub | SQLite access — query builder, migrations, observation |

**System frameworks used (no additional packages required):**

| Framework | Purpose |
|---|---|
| SwiftUI | All UI in the main app |
| WidgetKit | Widget rendering and timeline management |
| AppIntents | Interactive widget button actions (iOS 17+) |
| Swift Charts | History bar charts in counter detail view |
| Foundation | Date math, UUID, Codable |

The dependency footprint is deliberately small. One external package (GRDB.swift) is the target — nothing else.

---

## Data Layer

### Database location

The SQLite file lives in the **App Group container** so both the main app and the widget extension can access it:

```
group.com.yourname.simplecounter/
  └── db.sqlite
```

The App Group ID is defined once in `AppDatabase.swift` and used by both targets.

### Migrations

Schema changes are versioned migrations defined directly in `AppDatabase.swift`. GRDB's `DatabaseMigrator` runs pending migrations on startup and is safe to call repeatedly. A separate migrations file or folder is not needed until there are enough migrations to justify it.

### Repositories

Repositories are the only layer allowed to touch GRDB. They expose typed Swift functions:

```
CounterRepository
  func fetchAll() -> [Counter]
  func insert(_ counter: Counter)
  func update(_ counter: Counter)
  func delete(_ counter: Counter)

CountEntryRepository
  func insert(_ entry: CountEntry)
  func fetchEntries(for counterID: UUID, in period: DateInterval) -> [CountEntry]
  func sumDelta(for counterID: UUID, in period: DateInterval) -> Int
  func historyByPeriod(for counterID: UUID, last n: Int) -> [(DateInterval, Int)]
```

Repositories are injected into ViewModels as protocol types, making them swappable in tests.

---

## MVVM Pattern

```
View  →  ViewModel  →  Repository  →  Database
         (observed)     (protocol)
```

- **Views** are passive. They render state from the ViewModel and forward user actions to it. Simple form sheets (Add/Edit counter) manage their own transient state with `@State` — no ViewModel needed.
- **ViewModels** are `@Observable` classes (Swift 5.9 Observation framework, iOS 17+). They own no database references directly.
- **Repositories** are injected at construction time. In production, real GRDB-backed repositories are used. In tests, in-memory implementations are injected.

ViewModels use GRDB's `ValueObservation` (via the repository) to reactively update when the database changes — including changes made by the widget.

---

## Widget Architecture

The widget reads data from the shared SQLite database using `SimpleCounterCore` repositories — the same code path as the main app.

Interactive buttons use a single `CounterIntent` with a `direction` parameter (`+1` or `−1`). The intent:
1. Opens the shared database
2. Inserts a `CountEntry` with the given delta
3. Calls `WidgetCenter.shared.reloadTimelines(ofKind:)` to trigger a UI refresh

The widget never writes to any state outside of the shared database.

---

## Testing Strategy

### Core package tests (`SimpleCounterCoreTests`)

The main testing effort lives here. Run against an **in-memory GRDB database** — no file system, fast, isolated.

- Every repository function has a corresponding test.
- `PeriodCalculator` is pure — tested with fixed dates and expected period boundaries.

### UI tests (`SimpleCounterUITests`)

One end-to-end flow covering the critical path:
- Create a counter
- Increment it
- Verify the count persists after backgrounding and returning

That's it. The Core tests carry the coverage burden. ViewModel-level mock tests are not written — if the repository layer is correct and the view is straightforward, there is nothing left to isolate and test in between.

---

## Separation of Concerns Summary

| Layer | Knows about | Does NOT know about |
|---|---|---|
| Models | Swift value types only | Database, UI, business logic |
| Repositories | Models + GRDB | UI, ViewModels, period logic |
| PeriodCalculator | `ResetInterval` + `Date` | Database, UI |
| ViewModels | Repositories + Models | GRDB, SwiftUI internals |
| Views | ViewModels (+ `@State` for transient form state) | Repositories, database, models (directly) |
| Widgets | Core package only | App target code |
| CounterIntent | Core package only | App target code |

---

## Modularity Principles

- **Feature folders** group all files for a screen (view, view model) together — not by type (all views in one folder, all view models in another). This makes features self-contained and easy to locate.
- **Core as a hard boundary** — the local package enforces that shared code is explicitly declared as such, not accidentally shared by file membership in both targets.
- **Protocol-backed repositories** — swapping the database implementation (e.g. for tests or a future CloudKit backend) requires no changes to ViewModels or Views.
- **No singletons** — `AppDatabase` and repositories are constructed at app startup in `SimpleCounterApp.swift` and passed down via SwiftUI's environment. Nothing reaches for a global.
