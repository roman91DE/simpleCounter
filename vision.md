# Simple Counter — Vision

## Concept

Simple Counter is a minimalist iOS app for tracking recurring countable habits and behaviors. Whether you're monitoring nicotine gum consumption, glasses of water, cigarettes, medications, or any other repeated daily action, Simple Counter gives you a frictionless way to log and review your counts — with automatic resets on a schedule you define.

---

## Core Problem

Habit trackers are often complex, gamified, or opinionated. Sometimes you just need to know: *how many times did I do that thing today?* Simple Counter does exactly that — nothing more, nothing less.

---

## Target Audience

- People monitoring consumption habits (nicotine, caffeine, alcohol, food)
- Anyone tracking repetitive daily/weekly tasks
- People in health programs that require logging quantities
- Minimalism-minded users who want a distraction-free tool

---

## Features

### Counters
- Create multiple independent counters, each with:
  - A name (e.g. "Nicotine Gum")
  - An optional icon or emoji
  - An optional daily/period goal (e.g. "max 10 per day")
  - A reset interval: **daily**, **weekly**, **monthly**, or **yearly**
- Increment and decrement with large, tap-friendly buttons
- Counts are timestamped individually so history is preserved across resets

### Home Screen Widget
- Small widget: shows current count + increment/decrement buttons for a single counter
- Widget refreshes after each interaction

### Dashboard (per counter)
- Current period count vs. goal (if set)
- Simple bar chart showing count history per period (last 7 days / 4 weeks / 12 months)
- All-time total

### Resets
- Reset interval is per-counter and user-configurable
- On reset, the count for the new period starts at 0
- Historical data from previous periods is preserved in the database
- Resets happen automatically at midnight (local time) for daily counters, on Monday for weekly, on the 1st for monthly, on January 1st for yearly

---

## Technical Stack

| Concern           | Choice                          |
|-------------------|---------------------------------|
| Language          | Swift                           |
| UI Framework      | SwiftUI                         |
| Database          | SQLite via GRDB.swift           |
| Widgets           | WidgetKit + App Groups (shared SQLite DB) |
| Minimum iOS       | iOS 17                          |
| Distribution      | Apple App Store                 |

---

## UI / UX Principles

- **One tap to count.** The increment button is the largest element on screen.
- **No accounts, no cloud, no subscriptions.** All data stays on device.
- **Dark and light mode** support from day one.
- **Accessible.** Large touch targets, Dynamic Type support, VoiceOver labels.
- **Opinionated simplicity.** No categories, folders, tags, notes, or social features.

---

## App Structure (Screens)

```
NavigationStack
└── Counter List (root)
    ├── Counter card (tap) → Counter Detail
    │   ├── +/− buttons
    │   ├── Current period stats
    │   └── History chart
    └── "+" button → Add Counter sheet
        ├── Name field
        ├── Emoji picker
        ├── Reset interval selector
        └── Goal field (optional)

Long-press counter card → Edit / Delete
```

---

## Widget Design

```
┌────────────────────┐
│  Nicotine Gum  🍬  │
│                    │
│    [−]  7  [+]     │
│    daily · goal 10 │
└────────────────────┘
```

Widgets use `AppIntents` (iOS 17+) to allow interactive increment/decrement directly from the home screen without opening the app.

---

## Business Model

Simple Counter is **free forever**. No ads, no paywalls, no subscriptions, no freemium tiers. The app is sustained solely by voluntary donations from users who find it valuable. This is a deliberate choice — not a temporary stance.

---

## Out of Scope for v1

The following are intentionally deferred, not forgotten:

**Planned for v2:**
- Cloud sync / iCloud backup
- Apple Watch app
- Sharing and export (CSV, image)
- Medium home screen widget (3 counters)
- Streak tracking (consecutive periods meeting goal)

**Not planned:**
- Notifications / reminders
- Custom reset times (midnight is always the reset boundary)
- Undo history beyond simple decrement

---

## Success Criteria

- App launches in < 1 second
- Incrementing a counter takes a single tap (widget or in-app)
- Data is never lost across app restarts or resets
- Available on the App Store with a 4+ star rating
