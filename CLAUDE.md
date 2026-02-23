# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Simple Counter is a minimalist iOS app (iOS 17+) for tracking recurring countable habits with automatic period resets. Free forever, no ads, sustained by voluntary donations. Full context in `vision.md`.

## Commands

```bash
# Format all Swift files (always run before committing)
swiftformat .

# Lint
swiftlint lint

# Auto-fix safe lint violations
swiftlint --fix

# Run Core package tests (primary test target)
xcodebuild test \
  -scheme SimpleCounterCore \
  -destination 'platform=iOS Simulator,name=iPhone 16'

# Build the app
xcodebuild build \
  -scheme SimpleCounter \
  -destination 'platform=iOS Simulator,name=iPhone 16'

# Run the single UI test
xcodebuild test \
  -scheme SimpleCounter \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing SimpleCounterUITests
```

Both `swiftformat .` and `swiftlint lint` must pass cleanly before any task is considered done.

## Architecture

The codebase has three distinct targets that must never cross-import each other:

- **`SimpleCounterCore`** — local Swift Package at `Packages/SimpleCounterCore/`. Contains models, repositories, database setup, and `PeriodCalculator`. Shared by the app and widget. This is where all logic lives.
- **`SimpleCounter`** — main app target. SwiftUI views and `@Observable` ViewModels only. Imports `SimpleCounterCore`.
- **`SimpleCounterWidget`** — widget extension. WidgetKit views and `CounterIntent` (AppIntent). Imports `SimpleCounterCore`. Never imports from the app target.

**Data flow:** `View → ViewModel (@Observable) → Repository (protocol) → GRDB → SQLite`

The SQLite file lives in the **App Group container** (`group.com.yourname.simplecounter/db.sqlite`) so both the app and widget can access the same database. The App Group ID is defined once in `AppDatabase.swift`.

**Current period counts** are computed by summing `delta` on `CountEntry` rows within the current period window — there is no separate periods table. `PeriodCalculator` owns the logic for deriving period boundaries from a `ResetInterval` and a date.

**Reactive updates:** ViewModels observe the database via GRDB's `ValueObservation`. When the widget writes a `CountEntry`, the app's ViewModel updates automatically.

## Testing

All tests live in `SimpleCounterCore` and run against an **in-memory GRDB database**. Every repository function and every `PeriodCalculator` boundary condition must have a test. ViewModels and views are not unit tested.

Test naming: `test_functionName_condition_expectedResult`
Test structure: Arrange / Act / Assert, blank line between phases, everything constructed inside the test function (no shared state via `setUp`).

## Key Conventions

**No force unwraps, force casts, or `try!`** — SwiftLint enforces these as errors.

**Functional style preferred** (`map`, `filter`, `reduce`). Imperative loops are acceptable when genuinely clearer or faster, but must have a comment explaining why.

**`///` doc comments are required** on all `public` and `internal` functions in `SimpleCounterCore`. Not required on views, ViewModels, or private code.

**Every SwiftUI view must have a `#Preview`**. Add a static `.preview` factory to model types to support this.

**`@State` is for transient form state only** (text fields while typing). Anything backed by the database belongs in a ViewModel.

**Migrations** are defined inline in `AppDatabase.swift` via GRDB's `DatabaseMigrator`. Do not create a separate migrations folder unless there are enough migrations to justify it.

## Agent Rules

- No new external dependencies without updating `architecture.md` and getting explicit approval.
- No new files outside the directory tree in `architecture.md` without updating it first.
- Write the test before the implementation when adding a new repository function.
- Do not add doc comments to code you did not write or change.
- If a requirement is unclear, ask before implementing.
