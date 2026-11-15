import XCTest

final class LibraryFilterScrollTests: XCTestCase {
    func testTappingTrailingFilterKeepsSelectedChipVisible() {
        let app = XCUIApplication()
        app.launchArguments = ["-language", "en", "-savedWorkPaths", "[]", "-recentReadings", "[]"]
        app.launch()

        let filterBar = app.scrollViews["filterBar"]
        XCTAssertTrue(filterBar.waitForExistence(timeout: 15), app.debugDescription)

        // People is no longer offered as a filter chip.
        XCTAssertFalse(app.buttons["filter.figures"].exists, "People must not appear in the filter bar.")

        // The last chip in the English catalog is History. It starts off-screen.
        let history = app.buttons["filter.history"]
        XCTAssertTrue(history.waitForExistence(timeout: 5), app.debugDescription)

        for _ in 0..<8 {
            if filterBar.frame.contains(history.frame) { break }
            filterBar.swipeLeft()
        }
        XCTAssertTrue(filterBar.frame.contains(history.frame), "Could not scroll the History chip into view.")

        let frameBeforeTap = history.frame
        history.tap()

        XCTAssertTrue(history.isSelected, "The tapped chip must remain the selected filter.")
        XCTAssertTrue(
            filterBar.frame.contains(history.frame),
            "Tapping a filter must not reset the filter bar and hide the selected chip."
        )
        XCTAssertEqual(history.frame.minX, frameBeforeTap.minX, accuracy: 1.5,
                       "Tapping a filter must not move the filter bar.")
    }

    func testProgrammaticSelectionRevealsSelectedChip() {
        let app = XCUIApplication()
        app.launchArguments = ["-language", "en", "-savedWorkPaths", "[]", "-recentReadings", "[]"]
        app.launch()

        let filterBar = app.scrollViews["filterBar"]
        XCTAssertTrue(filterBar.waitForExistence(timeout: 15), app.debugDescription)

        let writers = app.buttons["filter.writers"]
        XCTAssertTrue(writers.waitForExistence(timeout: 5), app.debugDescription)

        let seeAll = app.buttons.matching(NSPredicate(format: "label == 'See all'")).firstMatch
        XCTAssertTrue(seeAll.waitForExistence(timeout: 5), app.debugDescription)
        seeAll.tap()

        XCTAssertTrue(writers.isSelected, "See all must select the Writers filter.")

        let centeredOnSelectedChip = XCTNSPredicateExpectation(
            predicate: NSPredicate { object, _ in
                guard let chip = object as? XCUIElement else { return false }
                return abs(chip.frame.midX - filterBar.frame.midX) < 12
            },
            object: writers
        )
        XCTAssertEqual(
            XCTWaiter().wait(for: [centeredOnSelectedChip], timeout: 2),
            .completed,
            "A selection made outside the bar must reveal its chip without resetting the bar."
        )
    }
}
extension LibraryFilterScrollTests {
    func testStoreShots() {
        let app = XCUIApplication()
        app.launchArguments = ["-language", "pt", "-analyticsPromptAnswered", "YES"]
        app.launch()
        XCTAssertTrue(app.buttons["filter.writers"].waitForExistence(timeout: 25))
        func shot(_ name: String) {
            let image = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            image.name = name
            image.lifetime = .keepAlways
            add(image)
        }
        shot("home")
        app.buttons["filter.writers"].tap()
        let marx = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Karl Marx'")).firstMatch
        XCTAssertTrue(marx.waitForExistence(timeout: 10))
        marx.tap()
        let work = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Teses sobre Feuerbach'")).firstMatch
        XCTAssertTrue(work.waitForExistence(timeout: 10))
        shot("autor")
        work.tap()
        _ = app.buttons.matching(identifier: "BackButton").firstMatch.waitForExistence(timeout: 15)
        shot("leitor")
    }
}
