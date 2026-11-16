import XCTest
import JavaScriptCore
@testable import ReaderCore

final class ReaderLinkTests: XCTestCase {
    func testArchiveAndExternalLinksAreClassified() throws {
        let chapter = try XCTUnwrap(URL(string: "http://marxists.org/portugues/marx/obra/cap.htm#fim"))
        XCTAssertEqual(ReaderLink.destination(for: chapter), .archive(try XCTUnwrap(URL(string: "https://www.marxists.org/portugues/marx/obra/cap.htm#fim"))))
        let external = try XCTUnwrap(URL(string: "https://example.org/book"))
        XCTAssertEqual(ReaderLink.destination(for: external), .external(external))
        XCTAssertEqual(ReaderLink.destination(for: try XCTUnwrap(URL(string: "javascript:alert(1)"))), .unsupported)
        let image = try XCTUnwrap(URL(string: "https://www.marxists.org/image.jpg"))
        XCTAssertEqual(ReaderLink.destination(for: image), .external(image))
    }
    func testAnchorAndChapterClicks() throws {
        let context = try XCTUnwrap(JSContext())
        context.evaluateScript("""
        let listener, messages = [], scrolled = '', prevented = 0;
        const sourceURL = 'https://www.marxists.org/portugues/book/index.htm';
        const URL = function(href, base) { let url = href.startsWith('http') ? href : href.startsWith('#') ? base + href : base.replace(/[^/]*$/, '') + href; let parts = url.match(/^(https?:\\/\\/[^/]+)([^?#]*)(\\?[^#]*)?(#.*)?$/); this.origin=parts[1]; this.pathname=parts[2]; this.search=parts[3] || ''; this.hash=parts[4] || ''; this.href=url; };
        const document = { addEventListener: (_, fn) => listener = fn, getElementById: id => id === 'chapter' ? {scrollIntoView: () => scrolled = id} : null, getElementsByName: () => [] };
        const window = { scrollTo: () => scrolled = 'top', __praxisHost: { link: (url, title) => messages.push({url, title}) } };
        const click = href => listener({ target: {closest: () => ({getAttribute: () => href, textContent: ' Chapter '})}, preventDefault: () => prevented++ });
        """)
        context.evaluateScript(ReaderLink.javascript)
        context.evaluateScript("click('#chapter');")
        XCTAssertEqual(context.evaluateScript("scrolled")?.toString(), "chapter")
        XCTAssertEqual(context.evaluateScript("messages.length")?.toInt32(), 0)
        context.evaluateScript("click('chapter.htm#part');")
        XCTAssertEqual(context.evaluateScript("messages[0].url")?.toString(), "https://www.marxists.org/portugues/book/chapter.htm#part")
        XCTAssertEqual(context.evaluateScript("messages[0].title")?.toString(), "Chapter")
        XCTAssertEqual(context.evaluateScript("prevented")?.toInt32(), 2)
        XCTAssertNil(context.exception)
    }
}
