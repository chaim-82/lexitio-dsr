import XCTest
@testable import AskLexi

final class DepositDeadlineTests: XCTestCase {

    private var calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    func testNewYorkHasFourteenDayWindow() {
        let deadline = DepositDeadlineCalculator.compute(
            stateCode: "NY",
            moveOutDate: date(2026, 6, 1),
            asOf: date(2026, 6, 1),
            calendar: calendar)
        XCTAssertEqual(deadline.returnDays, 14)
        XCTAssertEqual(deadline.deadlineDate, date(2026, 6, 15))
        XCTAssertTrue(deadline.citation.contains("7-108"))
    }

    func testDaysElapsedAndRemaining() {
        let deadline = DepositDeadlineCalculator.compute(
            stateCode: "NY",
            moveOutDate: date(2026, 6, 1),
            asOf: date(2026, 6, 6),   // 5 days later
            calendar: calendar)
        XCTAssertEqual(deadline.daysElapsed, 5)
        XCTAssertEqual(deadline.daysRemaining, 9)
        XCTAssertFalse(deadline.isOverdue)
    }

    func testOverdueWhenPastWindow() {
        let deadline = DepositDeadlineCalculator.compute(
            stateCode: "NY",
            moveOutDate: date(2026, 6, 1),
            asOf: date(2026, 6, 21),  // 20 days later, past 14
            calendar: calendar)
        XCTAssertEqual(deadline.daysRemaining, -6)
        XCTAssertTrue(deadline.isOverdue)
    }

    func testUnknownStateUsesFallbackThirtyDays() {
        let deadline = DepositDeadlineCalculator.compute(
            stateCode: "ZZ",
            moveOutDate: date(2026, 1, 1),
            asOf: date(2026, 1, 1),
            calendar: calendar)
        XCTAssertEqual(deadline.returnDays, DepositRules.fallback.returnDays)
        XCTAssertEqual(deadline.deadlineDate, date(2026, 1, 31))
    }

    func testCaliforniaTwentyOneDays() {
        let rule = DepositRules.rule(for: "ca")   // case-insensitive
        XCTAssertEqual(rule.returnDays, 21)
        XCTAssertEqual(rule.stateCode, "CA")
    }

    func testElapsedNeverNegative() {
        // "now" before move-out shouldn't yield negative elapsed.
        let deadline = DepositDeadlineCalculator.compute(
            stateCode: "NY",
            moveOutDate: date(2026, 6, 10),
            asOf: date(2026, 6, 1),
            calendar: calendar)
        XCTAssertEqual(deadline.daysElapsed, 0)
    }
}
