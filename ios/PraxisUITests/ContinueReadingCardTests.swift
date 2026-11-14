import XCTest

final class ContinueReadingCardTests: XCTestCase {
    private let shortTitle = "A Short Work"
    private let longTitle = String(repeating: "The long history of a working-class movement ", count: 6)
    private let veryLongTitle = String(repeating: "The long history of a working-class movement ", count: 20)

    func testContinueReadingCardsCapTitlesAtThreeLines() throws {
        let entries: [[String: Any]] = [
            ["path": "https://example.com/short", "title": shortTitle, "author": "", "progress": 0.35],
            ["path": "https://example.com/long", "title": longTitle, "author": "", "progress": 0.5],
            ["path": "https://example.com/very-long", "title": veryLongTitle, "author": "", "progress": 0.7],
        ]
        let readings = String(decoding: try JSONSerialization.data(withJSONObject: entries), as: UTF8.self)
        // UserDefaults parses launch-argument values as property lists, so a
        // bare JSON array becomes an array and is invisible to @AppStorage.
        // Quoting the value keeps it a string, with the JSON quotes escaped.
        let quotedReadings = "\"" + readings.replacingOccurrences(of: "\"", with: "\\\"") + "\""

        let app = XCUIApplication()
        app.launchArguments = ["-language", "en", "-savedWorkPaths", "[]", "-recentReadings", quotedReadings]
        app.launch()

        let cards = app.buttons.matching(identifier: "continueReading.card")
        XCTAssertTrue(cards.firstMatch.waitForExistence(timeout: 15), app.debugDescription)
        XCTAssertEqual(cards.count, 3, app.debugDescription)

        let shortCard = cards.element(boundBy: 0)
        let longCard = cards.element(boundBy: 1)
        let veryLongCard = cards.element(boundBy: 2)

        XCTAssertEqual(
            longCard.frame.height, veryLongCard.frame.height, accuracy: 1,
            "Titles longer than three lines must stop growing at the same height."
        )
        XCTAssertLessThan(
            longCard.frame.height, 140,
            "The card should fit a three-line title and no more."
        )
        XCTAssertTrue(
            shortCard.label.contains(shortTitle),
            "A short title must keep its full accessible label."
        )
        XCTAssertTrue(
            longCard.label.contains(longTitle),
            "Truncating the visible title must not shorten the accessible label."
        )
        XCTAssertTrue(
            veryLongCard.label.contains(veryLongTitle),
            "Truncating the visible title must not shorten the accessible label."
        )
    }
}
