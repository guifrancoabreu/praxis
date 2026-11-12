import XCTest
@testable import ReaderCore

final class FilterBarSelectionTests: XCTestCase {
    func testTappingVisibleChipDoesNotRequestScroll() {
        var selection = FilterBarSelection("all")
        selection.selectFromBar("countries")

        XCTAssertEqual(selection.selected, "countries")
        XCTAssertFalse(selection.consumeRevealRequest(for: "countries"),
                       "A chip the user tapped is already visible; the bar must keep its offset.")
    }

    func testProgrammaticSelectionRequestsScrollToSelectedChip() {
        var selection = FilterBarSelection("all")
        selection.selectProgrammatically("countries")

        XCTAssertEqual(selection.selected, "countries")
        XCTAssertTrue(selection.consumeRevealRequest(for: "countries"))
    }

    func testSelectingFromBarClearsStaleRevealRequest() {
        var selection = FilterBarSelection("all")
        selection.selectProgrammatically("countries")
        selection.selectFromBar("all")

        XCTAssertFalse(selection.consumeRevealRequest(for: "all"))
        XCTAssertFalse(selection.consumeRevealRequest(for: "countries"))
    }

    func testRevealRequestIsConsumedOnceAndOnlyForTheSelectedChip() {
        var selection = FilterBarSelection("all")
        selection.selectProgrammatically("countries")

        XCTAssertFalse(selection.consumeRevealRequest(for: "writers"))
        XCTAssertTrue(selection.consumeRevealRequest(for: "countries"))
        XCTAssertFalse(selection.consumeRevealRequest(for: "countries"))
    }
}
