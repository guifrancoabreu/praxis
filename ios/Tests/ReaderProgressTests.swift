import XCTest
import JavaScriptCore
@testable import ReaderCore

final class ReaderProgressTests: XCTestCase {
    func testScrollReportsAreThrottledAndFinalPositionIsFlushed() throws {
        let context = try XCTUnwrap(JSContext())
        context.evaluateScript("""
        let handlers = {}, timers = {}, nextTimer = 0, reports = 0;
        const window = { addEventListener: (name, handler) => { handlers[name] = handler; } };
        const setTimeout = (fn, delay) => { timers[++nextTimer] = fn; return nextTimer; };
        const clearTimeout = (id) => { delete timers[id]; };
        const report = () => { reports++; };
        const fireTimers = () => { const pending = Object.values(timers); timers = {}; pending.forEach(fn => fn()); };
        """)
        context.evaluateScript(ReaderProgress.javascript)
        XCTAssertNil(context.exception)
        context.evaluateScript("for (let i = 0; i < 100; i++) handlers.scroll();")
        XCTAssertEqual(context.evaluateScript("reports")?.toInt32(), 0)
        context.evaluateScript("fireTimers();")
        XCTAssertEqual(context.evaluateScript("reports")?.toInt32(), 1)
        context.evaluateScript("handlers.scroll(); handlers.scroll(); handlers.scrollend(); fireTimers();")
        XCTAssertEqual(context.evaluateScript("reports")?.toInt32(), 2)
        context.evaluateScript("handlers.scroll(); handlers.pagehide(); fireTimers();")
        XCTAssertEqual(context.evaluateScript("reports")?.toInt32(), 3)
        XCTAssertNil(context.exception)
    }
    func testImagesOutsideFirstTwoAreMarkedForLazyLoading() throws {
        let context = try XCTUnwrap(JSContext())
        context.evaluateScript("let images = [{}, {}, {}, {}]; const document = { querySelectorAll: () => images };")
        context.evaluateScript(ReaderHTML.imageLoadingScript)
        XCTAssertNil(context.exception)
        XCTAssertTrue(context.evaluateScript("images[0].loading === undefined && images[1].loading === undefined")!.toBool())
        XCTAssertTrue(context.evaluateScript("images[2].loading === 'lazy' && images[3].loading === 'lazy'")!.toBool())
        XCTAssertTrue(context.evaluateScript("images.every(image => image.decoding === 'async')")!.toBool())
    }
}
