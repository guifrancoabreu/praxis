import XCTest
import JavaScriptCore
@testable import ReaderCore

/// Exercises the composed document script — sanitizing, stylesheet injection, appearance, progress
/// reporting and link routing — against a minimal DOM mock. This is the contract shared with the
/// Android reader, so it is worth testing end to end instead of piece by piece.
final class ReaderScriptTests: XCTestCase {
    private func context() throws -> JSContext {
        let context = try XCTUnwrap(JSContext())
        context.evaluateScript("""
        let appended = [], removals = 0, timers = [], listeners = {}, progressValues = [], links = [];
        const makeElement = (tag) => ({
            tagName: String(tag).toUpperCase(),
            style: { props: {}, setProperty(name, value) { this.props[name] = value; } },
            attributes: [],
            setAttribute() {}, getAttribute() { return null; }, removeAttribute() {},
            remove() { removals++; }, before() {},
            appendChild(child) { appended.push(child); }
        });
        const window = {
            scrollY: 600, innerHeight: 800,
            scrollTo(x, y) { window.scrollY = typeof y === 'number' ? y : 0; },
            addEventListener(name, handler) { listeners[name] = handler; }
        };
        const document = {
            documentElement: { scrollHeight: 2000 },
            body: makeElement('body'),
            head: makeElement('head'),
            createElement(tag) { return makeElement(tag); },
            querySelectorAll(selector) {
                if (selector === 'nav') return [{ querySelectorAll: () => [], before() {} }];
                if (selector === '*') return [];
                if (selector === 'img') return [];
                if (selector.indexOf('p.title') >= 0) return [{ remove() { removals++; } }];
                return [];
            },
            getElementById() { return null; },
            getElementsByName() { return []; },
            addEventListener(name, handler) { listeners['document:' + name] = handler; }
        };
        const setTimeout = (fn) => { timers.push(fn); return timers.length; };
        const clearTimeout = () => {};
        const fireTimers = () => { const pending = timers.splice(0); pending.forEach(fn => fn()); };
        const URL = function(href, base) {
            let url = href.startsWith('http') ? href : base.replace(/[^/]*$/, '') + href;
            let parts = url.match(/^(https?:\\/\\/[^/]+)([^?#]*)(\\?[^#]*)?(#.*)?$/);
            this.origin = parts[1]; this.pathname = parts[2];
            this.search = parts[3] || ''; this.hash = parts[4] || ''; this.href = url;
        };
        window.__praxisHost = {
            progress(value) { progressValues.push(value); },
            link(url, title) { links.push({ url, title }); }
        };
        """)
        return context
    }

    func testDocumentScriptWiresStylesheetAppearanceProgressAndLinks() throws {
        let source = try XCTUnwrap(URL(string: "https://www.marxists.org/portugues/marx/1845/teses/index.htm"))
        let appearance = ReaderAppearance()
        let context = try context()
        context.evaluateScript(ReaderAssets.documentScript(source: source, appearance: appearance, initialProgress: 0.5))

        XCTAssertNil(context.exception)

        // The archive's own chrome is removed and the shared stylesheet is injected.
        XCTAssertGreaterThan(context.evaluateScript("removals")!.toInt32(), 0)
        let stylesheet = try XCTUnwrap(context.evaluateScript("appended[0] && appended[0].textContent")?.toString())
        XCTAssertTrue(stylesheet.contains("--reader-bg"))
        XCTAssertTrue(stylesheet.contains("max-width: 40rem"))

        // The initial appearance and progress are applied, then the report reaches the host.
        XCTAssertEqual(context.evaluateScript("document.body.style.props['--reader-bg']")?.toString(), "#fbfaf7")
        context.evaluateScript("fireTimers();")
        XCTAssertNil(context.exception)
        XCTAssertEqual(context.evaluateScript("progressValues.length")?.toInt32(), 1)
        XCTAssertEqual(context.evaluateScript("progressValues[0]")?.toDouble() ?? 0, 0.5, accuracy: 0.0001)

        // Appearance changes from the app update the same custom properties.
        context.evaluateScript("window.setReaderAppearance({background:'#f4ecd8', foreground:'#3b2f22', link:'#9c2a12', size:22, lineSpacing:1.8, margin:24, alignment:'justified', font:'book'});")
        XCTAssertEqual(context.evaluateScript("document.body.style.props['--reader-bg']")?.toString(), "#f4ecd8")
        XCTAssertEqual(context.evaluateScript("document.body.style.props['--reader-align']")?.toString(), "justify")
        XCTAssertEqual(context.evaluateScript("document.body.style.props['--reader-font']")?.toString(), "Palatino, serif")

        // A cross-document click is routed to the host instead of navigating the web view.
        context.evaluateScript("""
        listeners['document:click']({
            target: { closest: () => ({ getAttribute: () => 'outra.htm', textContent: ' Outro texto ' }) },
            preventDefault() {}
        });
        """)
        XCTAssertNil(context.exception)
        XCTAssertEqual(context.evaluateScript("links.length")?.toInt32(), 1)
        XCTAssertEqual(context.evaluateScript("links[0].url")?.toString(),
                       "https://www.marxists.org/portugues/marx/1845/teses/outra.htm")
        XCTAssertEqual(context.evaluateScript("links[0].title")?.toString(), "Outro texto")
    }

    func testEverySharedAssetIsPresent() {
        for file in [ReaderAssets.File.stylesheet, .document, .link, .progress, .images] {
            let text = ReaderAssets.text(file)
            XCTAssertFalse(text.isEmpty, "missing shared reader asset \(file.rawValue)")
        }
        XCTAssertTrue(ReaderAssets.text(.document).contains("__READER_CSS__"))
        XCTAssertFalse(ReaderAssets.text(.document).contains("window.webkit"), "the document script must stay platform-neutral")
    }
}
