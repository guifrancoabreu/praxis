import XCTest
@testable import ReaderCore

final class ReadingStatsTests: XCTestCase {
    func testTodayKeyUsesTheGivenCalendar() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        XCTAssertEqual(ReadingStats.todayKey(now: Date(timeIntervalSince1970: 0), calendar: calendar), "1970-01-01")
    }

    func testMergeDeduplicatesSortsNewestFirstAndIncludesToday() {
        let merged = ReadingStats.mergeReadingDays(
            existing: ["2024-01-02", "2024-01-01", "2024-01-02"],
            today: "2024-01-03"
        )
        XCTAssertEqual(merged, ["2024-01-03", "2024-01-02", "2024-01-01"])
    }

    func testMergeKeepsAnAlreadyStampedTodayOnce() {
        let merged = ReadingStats.mergeReadingDays(existing: ["2024-01-03", "2024-01-01"], today: "2024-01-03")
        XCTAssertEqual(merged, ["2024-01-03", "2024-01-01"])
    }

    func testMergeRetainsMoreThanFourHundredDays() {
        let existing = (0..<450).map { ReadingStats.shift("2024-06-01", by: -$0) }
        let merged = ReadingStats.mergeReadingDays(existing: existing, today: "2024-06-02")
        XCTAssertEqual(merged.count, 451)
        XCTAssertEqual(merged.first, "2024-06-02")
        XCTAssertEqual(merged, merged.sorted(by: >), "Days must stay newest first.")
    }

    func testStreakCountsConsecutiveDaysWhenTodayIsRead() {
        let days: Set<String> = ["2024-03-10", "2024-03-09", "2024-03-08"]
        XCTAssertEqual(ReadingStats.currentStreak(days: days, today: "2024-03-10"), 3)
    }

    func testStreakSurvivesATodayThatHasNotBeenReadYet() {
        let days: Set<String> = ["2024-03-09", "2024-03-08", "2024-03-07"]
        XCTAssertEqual(ReadingStats.currentStreak(days: days, today: "2024-03-10"), 3)
    }

    func testStreakBreaksAtAGap() {
        let days: Set<String> = ["2024-03-10", "2024-03-08", "2024-03-07"]
        XCTAssertEqual(ReadingStats.currentStreak(days: days, today: "2024-03-10"), 1)
    }

    func testStreakIsZeroAfterTwoMissedDays() {
        let days: Set<String> = ["2024-03-08", "2024-03-07"]
        XCTAssertEqual(ReadingStats.currentStreak(days: days, today: "2024-03-10"), 0)
    }

    func testStreakIsZeroForAnEmptySet() {
        XCTAssertEqual(ReadingStats.currentStreak(days: [], today: "2024-03-10"), 0)
    }

    func testStreakCrossesMonthAndYearBoundaries() {
        let days: Set<String> = ["2024-03-01", "2024-02-29", "2024-02-28"]
        XCTAssertEqual(ReadingStats.currentStreak(days: days, today: "2024-03-01"), 3)
        XCTAssertEqual(ReadingStats.currentStreak(days: ["2023-12-31", "2024-01-01"], today: "2024-01-01"), 2)
    }

    func testWeekBucketsComeOldestFirstAndSplitByWindow() {
        let days: Set<String> = [
            "2024-03-10", // last bucket
            "2024-03-06", // last bucket
            "2024-03-04", // last bucket, first day of the window
            "2024-03-03" // previous bucket
        ]
        let buckets = ReadingStats.weekBucketCounts(days: days, today: "2024-03-10")
        XCTAssertEqual(buckets.count, 12)
        XCTAssertEqual(buckets.last, 3)
        XCTAssertEqual(buckets[buckets.count - 2], 1)
        XCTAssertEqual(buckets.reduce(0, +), 4)
    }

    func testOldestWeekBucketHoldsTheFirstWindow() {
        let oldestDay = ReadingStats.shift("2024-03-10", by: -83)
        let buckets = ReadingStats.weekBucketCounts(days: [oldestDay], today: "2024-03-10")
        XCTAssertEqual(buckets.count, 12)
        XCTAssertEqual(buckets.first, 1)
        XCTAssertEqual(buckets.reduce(0, +), 1)
        XCTAssertEqual(ReadingStats.weekBucketCounts(days: [oldestDay], today: "2024-03-10").count, 12)
    }

    func testEmptyDaysGiveTwelveZeroBuckets() {
        let buckets = ReadingStats.weekBucketCounts(days: [], today: "2024-03-10")
        XCTAssertEqual(buckets, Array(repeating: 0, count: 12))
    }
}
