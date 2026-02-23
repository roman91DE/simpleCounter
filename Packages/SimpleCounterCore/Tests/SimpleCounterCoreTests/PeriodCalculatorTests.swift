import XCTest
@testable import SimpleCounterCore

final class PeriodCalculatorTests: XCTestCase {
    // MARK: - Daily

    func test_currentPeriod_daily_startIsStartOfDay() {
        let input = makeDate(year: 2024, month: 6, day: 15, hour: 14, minute: 30)

        let period = PeriodCalculator.currentPeriod(for: .daily, at: input)

        let expected = makeDate(year: 2024, month: 6, day: 15, hour: 0, minute: 0)
        XCTAssertEqual(period.start, expected)
    }

    func test_currentPeriod_daily_endIsStartOfNextDay() {
        let input = makeDate(year: 2024, month: 6, day: 15, hour: 14, minute: 30)

        let period = PeriodCalculator.currentPeriod(for: .daily, at: input)

        let expected = makeDate(year: 2024, month: 6, day: 16, hour: 0, minute: 0)
        XCTAssertEqual(period.end, expected)
    }

    func test_currentPeriod_daily_leapYearFeb28() {
        let input = makeDate(year: 2024, month: 2, day: 28, hour: 12, minute: 0)

        let period = PeriodCalculator.currentPeriod(for: .daily, at: input)

        let expectedEnd = makeDate(year: 2024, month: 2, day: 29, hour: 0, minute: 0)
        XCTAssertEqual(period.end, expectedEnd)
    }

    func test_currentPeriod_daily_leapYearFeb29() {
        let input = makeDate(year: 2024, month: 2, day: 29, hour: 12, minute: 0)

        let period = PeriodCalculator.currentPeriod(for: .daily, at: input)

        let expectedStart = makeDate(year: 2024, month: 2, day: 29, hour: 0, minute: 0)
        let expectedEnd = makeDate(year: 2024, month: 3, day: 1, hour: 0, minute: 0)
        XCTAssertEqual(period.start, expectedStart)
        XCTAssertEqual(period.end, expectedEnd)
    }

    // MARK: - Weekly

    func test_currentPeriod_weekly_startIsMondayOfCurrentWeek() {
        // A Wednesday
        let input = makeDate(year: 2024, month: 6, day: 12, hour: 15, minute: 0)

        let period = PeriodCalculator.currentPeriod(for: .weekly, at: input)

        // Monday of the same week
        let monday = makeDate(year: 2024, month: 6, day: 10, hour: 0, minute: 0)
        let nextMonday = makeDate(year: 2024, month: 6, day: 17, hour: 0, minute: 0)
        XCTAssertEqual(period.start, monday)
        XCTAssertEqual(period.end, nextMonday)
    }

    // MARK: - Monthly

    func test_currentPeriod_monthly_startIsFirstOfMonth() {
        let input = makeDate(year: 2024, month: 6, day: 20, hour: 10, minute: 0)

        let period = PeriodCalculator.currentPeriod(for: .monthly, at: input)

        let expectedStart = makeDate(year: 2024, month: 6, day: 1, hour: 0, minute: 0)
        let expectedEnd = makeDate(year: 2024, month: 7, day: 1, hour: 0, minute: 0)
        XCTAssertEqual(period.start, expectedStart)
        XCTAssertEqual(period.end, expectedEnd)
    }

    func test_currentPeriod_monthly_december() {
        let input = makeDate(year: 2024, month: 12, day: 15, hour: 10, minute: 0)

        let period = PeriodCalculator.currentPeriod(for: .monthly, at: input)

        let expectedEnd = makeDate(year: 2025, month: 1, day: 1, hour: 0, minute: 0)
        XCTAssertEqual(period.end, expectedEnd)
    }

    // MARK: - Yearly

    func test_currentPeriod_yearly_startIsJan1() {
        let input = makeDate(year: 2024, month: 8, day: 20, hour: 10, minute: 0)

        let period = PeriodCalculator.currentPeriod(for: .yearly, at: input)

        let expectedStart = makeDate(year: 2024, month: 1, day: 1, hour: 0, minute: 0)
        let expectedEnd = makeDate(year: 2025, month: 1, day: 1, hour: 0, minute: 0)
        XCTAssertEqual(period.start, expectedStart)
        XCTAssertEqual(period.end, expectedEnd)
    }

    // MARK: - previousPeriods

    func test_previousPeriods_daily_returnsCorrectCount() {
        let input = makeDate(year: 2024, month: 6, day: 15, hour: 12, minute: 0)

        let periods = PeriodCalculator.previousPeriods(for: .daily, last: 7, before: input)

        XCTAssertEqual(periods.count, 7)
    }

    func test_previousPeriods_daily_orderedOldestFirst() {
        let input = makeDate(year: 2024, month: 6, day: 15, hour: 12, minute: 0)

        let periods = PeriodCalculator.previousPeriods(for: .daily, last: 3, before: input)

        XCTAssertLessThan(periods[0].start, periods[1].start)
        XCTAssertLessThan(periods[1].start, periods[2].start)
    }

    func test_previousPeriods_daily_mostRecentIsYesterday() {
        let today = makeDate(year: 2024, month: 6, day: 15, hour: 12, minute: 0)

        let periods = PeriodCalculator.previousPeriods(for: .daily, last: 1, before: today)

        let expectedStart = makeDate(year: 2024, month: 6, day: 14, hour: 0, minute: 0)
        XCTAssertEqual(periods[0].start, expectedStart)
    }

    // MARK: - Helpers

    private func makeDate(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        guard let date = Calendar.current.date(from: components) else {
            XCTFail("Could not construct date from components: \(components)")
            return .now
        }
        return date
    }
}
