# Simple Counter — Development Guidelines

These rules apply to everyone working on this codebase: human developers and AI agents alike.

---

## Tooling

### SwiftLint — linter

Enforces style rules and catches common mistakes. Configuration lives in `.swiftlint.yml` at the project root.

```bash
# Install
brew install swiftlint

# Run manually
swiftlint lint

# Auto-fix safe violations
swiftlint --fix
```

SwiftLint runs as an **Xcode build phase** so violations appear as warnings and errors inline during development. The build does not fail on warnings — only on errors.

Key rules enforced (see `.swiftlint.yml` for full config):

| Rule | Level |
|---|---|
| `force_cast` | error |
| `force_try` | error |
| `force_unwrapping` | error |
| `line_length` (120 chars) | warning |
| `function_body_length` | warning |
| `cyclomatic_complexity` | warning |
| `trailing_whitespace` | warning |

### SwiftFormat — formatter

Automatically reformats code to a consistent style. Configuration lives in `.swiftformat` at the project root.

```bash
# Install
brew install swiftformat

# Format all Swift files
swiftformat .

# Check without modifying (for CI)
swiftformat --lint .
```

SwiftFormat runs as a **git pre-commit hook** so code is always formatted before it enters the repository. Never manually fix formatting — let the tool do it.

Key options (see `.swiftformat` for full config):

```
--indent 4
--maxwidth 120
--wraparguments before-first
--importgrouping testable-last
--semicolons never
--trailingCommas always
```

### Running both before committing

```bash
swiftformat . && swiftlint lint
```

If either reports errors, fix them before committing.

---

## Naming

Follow Swift API Design Guidelines. When in doubt, read them: https://swift.org/documentation/api-design-guidelines/

- **Types, protocols, enums**: `UpperCamelCase` — `Counter`, `ResetInterval`, `CounterRepository`
- **Functions, variables, constants**: `lowerCamelCase` — `fetchAll()`, `counterID`, `resetInterval`
- **No abbreviations** except universally accepted ones: `ID`, `URL`, `UI`
- **Boolean properties** read as assertions: `isEmpty`, `isGoalMet`, `hasGoal`
- **Functions that perform actions** use verbs: `insert(_:)`, `delete(_:)`, `reload()`
- **Functions that return values** use nouns or noun phrases: `currentPeriod()`, `history(last:)`

---

## Code Style

### Prefer `let` over `var`

Declare everything as `let` unless mutation is explicitly needed. Immutability is the default.

### Prefer value types

Use `struct` over `class` for models and data. Use `class` only when reference semantics are required (e.g. `@Observable` ViewModels).

### Use `guard` for early exits

```swift
// Preferred
guard let goal else { return }

// Avoid
if goal != nil {
    // deeply nested logic
}
```

### Keep functions small

A function should do one thing. If you need to scroll to see the whole function body, it's too long. Extract sub-steps into named private helpers.

### No magic numbers or strings

Name your constants.

```swift
// Bad
if count > 10 { ... }

// Good
if count > counter.goal { ... }
```

---

## Functional vs Imperative Style

We prefer functional style — it is more readable, composable, and testable. Use `map`, `filter`, `compactMap`, `reduce`, and `flatMap` over manual loops when the intent is clear.

```swift
// Preferred
let totals = entries.map(\.delta).reduce(0, +)

// Also fine — equally clear
var total = 0
for entry in entries { total += entry.delta }
```

**Use imperative code when:**
- A functional expression would be harder to read than a loop
- Performance matters and the loop is measurably faster (profile first)
- You are building up mutable state across multiple conditions

**When you write imperative code for performance reasons, document it:**

```swift
// Using a manual loop here instead of reduce(_:_:) because this runs
// on every widget refresh and profiling showed a measurable difference
// at >1000 entries. Revisit if the data model changes.
var total = 0
for entry in entries { total += entry.delta }
```

The comment must explain *why*, not *what* — the code already shows what.

---

## Documentation

### When to write a doc comment

Write a `///` doc comment on every `public` or `internal` function in `SimpleCounterCore`. This package is used by multiple targets; its API should be self-documenting.

```swift
/// Returns the start and end of the current period for the given interval and reference date.
/// - Parameters:
///   - interval: The counter's configured reset interval.
///   - date: The date to compute the period for. Defaults to now.
/// - Returns: A `DateInterval` covering the full current period.
func currentPeriod(for interval: ResetInterval, at date: Date = .now) -> DateInterval
```

### When NOT to write a doc comment

- Private implementation details — if the function name and types are clear, a comment adds noise
- SwiftUI views — use Xcode Previews to document appearance, not prose
- One-line wrappers that are obviously named

### Inline comments

Use inline comments sparingly. If you need a comment to explain what the code does, consider whether the code could be renamed or restructured to be self-explanatory instead. Comments that explain *why* a non-obvious decision was made are always welcome.

---

## Error Handling

- **No `try!`** — always handle or propagate errors explicitly
- **No `as!` force casts** — use `as?` with a `guard` or handle the nil case
- **No `!` force unwraps** on optionals — use `guard let`, `if let`, or provide a default
- In repositories, errors from GRDB propagate as `throws` — do not swallow them
- In ViewModels, catch thrown errors and expose them as state for the view to display
- Never silently ignore an error with an empty `catch {}`

---

## Testing

### What must be tested

Every function in `SimpleCounterCore` must have at least one test. This includes:
- All repository CRUD operations
- All query functions (`sumDelta`, `historyByPeriod`, etc.)
- All `PeriodCalculator` boundary conditions (start of day, week, month, year; leap years; DST transitions)

ViewModels and SwiftUI views are not unit tested. Trust Xcode Previews for visual verification and the single UI test for the critical end-to-end flow.

### Test structure

Use the **Arrange / Act / Assert** pattern with a blank line separating each phase:

```swift
func test_sumDelta_returnsCorrectTotalForCurrentPeriod() throws {
    let db = try AppDatabase.makeInMemory()
    let repo = CountEntryRepository(db: db)
    let counterID = UUID()
    let period = DateInterval(start: .now.startOfDay, duration: 86400)

    try repo.insert(CountEntry(counterID: counterID, delta: 1, timestamp: .now))
    try repo.insert(CountEntry(counterID: counterID, delta: 1, timestamp: .now))
    try repo.insert(CountEntry(counterID: counterID, delta: -1, timestamp: .now))

    let total = try repo.sumDelta(for: counterID, in: period)

    XCTAssertEqual(total, 1)
}
```

### Test naming

```
test_functionName_condition_expectedResult
```

Be specific enough that a failing test name tells you exactly what broke.

### Test isolation

Every test creates its own in-memory database. Tests must not share state. No `setUp` / `tearDown` database lifecycle — construct everything inside the test function.

---

## SwiftUI Conventions

### Keep views small

If a view body exceeds roughly 50 lines, extract sub-views into named `private` computed properties or separate `private` types within the same file. Only move a sub-view to its own file when it is reused in more than one place.

### Previews are required for every view

Every SwiftUI view file must include a `#Preview`. Previews serve as lightweight visual tests and living documentation.

```swift
#Preview {
    CounterCardView(counter: .preview)
}
```

Add a static `.preview` factory to model types for use in previews:

```swift
extension Counter {
    static let preview = Counter(name: "Nicotine Gum", emoji: "🍬", resetInterval: .daily, goal: 10)
}
```

### `@State` for transient, local form state only

`@State` is appropriate for things like text field content while the user is typing. It is not appropriate for data that comes from or needs to be saved to the database — that belongs in a ViewModel backed by a Repository.

---

## Agent-Specific Rules

These rules apply when an AI agent is working on this codebase:

1. **Read before editing.** Always read a file in full before modifying it.
2. **Stay in scope.** Only change what the task requires. Do not refactor, rename, or "improve" surrounding code that was not part of the task.
3. **No new external dependencies** without updating `architecture.md` and getting explicit approval.
4. **No new files** outside the directory tree defined in `architecture.md` without updating it first.
5. **Run SwiftFormat and SwiftLint** after every code change. Do not consider a task complete if either reports errors.
6. **Document imperative code** with a comment explaining why it was chosen over a functional approach.
7. **Write the test first** when adding a new repository function, then the implementation.
8. **Do not add doc comments** to code you did not write or change.
9. **Do not guess at intent.** If a requirement is unclear, ask before implementing.
