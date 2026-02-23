import Foundation

/// Computes the current period window given a `ResetInterval` and a reference date.
///
/// This type has no database dependency — it is a pure date-math utility.
public enum PeriodCalculator {
    /// Returns the `DateInterval` covering the full current period for `interval` at `date`.
    ///
    /// - Parameters:
    ///   - interval: The counter's configured reset interval.
    ///   - date: The reference date. Defaults to now.
    /// - Returns: A `DateInterval` from the start of the current period to the start of the next period.
    public static func currentPeriod(for interval: ResetInterval, at date: Date = .now) -> DateInterval {
        let calendar = Calendar.current
        switch interval {
        case .daily:
            let start = calendar.startOfDay(for: date)
            let end = calendar.adding(.day, value: 1, to: start)
            return DateInterval(start: start, end: end)

        case .weekly:
            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
            let start = calendar.date(from: components) ?? calendar.startOfDay(for: date)
            let end = calendar.adding(.weekOfYear, value: 1, to: start)
            return DateInterval(start: start, end: end)

        case .monthly:
            let components = calendar.dateComponents([.year, .month], from: date)
            let start = calendar.date(from: components) ?? calendar.startOfDay(for: date)
            let end = calendar.adding(.month, value: 1, to: start)
            return DateInterval(start: start, end: end)

        case .yearly:
            let components = calendar.dateComponents([.year], from: date)
            let start = calendar.date(from: components) ?? calendar.startOfDay(for: date)
            let end = calendar.adding(.year, value: 1, to: start)
            return DateInterval(start: start, end: end)
        }
    }

    /// Returns the `count` most recent complete-period intervals ending before `date`,
    /// ordered from oldest to newest.
    ///
    /// - Parameters:
    ///   - interval: The counter's configured reset interval.
    ///   - count: The number of past periods to include.
    ///   - date: The reference date. Defaults to now.
    public static func previousPeriods(
        for interval: ResetInterval,
        last count: Int,
        before date: Date = .now
    ) -> [DateInterval] {
        var periods: [DateInterval] = []
        var cursor = date

        for _ in 0 ..< count {
            let period = currentPeriod(for: interval, at: cursor)
            // Step back one unit before the current period's start to land in the previous period
            let step: Calendar.Component = switch interval {
            case .daily: .day
            case .weekly: .weekOfYear
            case .monthly: .month
            case .yearly: .year
            }
            let previousDate = Calendar.current.adding(step, value: -1, to: period.start)
            periods.insert(currentPeriod(for: interval, at: previousDate), at: 0)
            cursor = previousDate
        }

        return periods
    }
}

// MARK: - Calendar helper

private extension Calendar {
    /// Adds `value` of `component` to `date`.
    ///
    /// `Calendar.date(byAdding:)` returns nil only for invalid inputs, which cannot occur here.
    /// `startOfDay(for:)` is used as a fallback to satisfy the compiler without crashing.
    func adding(_ component: Component, value: Int, to date: Date) -> Date {
        self.date(byAdding: component, value: value, to: date) ?? startOfDay(for: date)
    }
}
